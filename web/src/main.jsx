import React, { useCallback, useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import "./style.css";

const API = import.meta.env.VITE_API_URL || "http://localhost:8000";
const statuses = ["Pending", "In Progress", "Completed", "Rejected"];

async function request(path, { token, method = "GET", body, signal } = {}) {
  const response = await fetch(`${API}${path}`, {
    method,
    signal,
    headers: {
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(body && !(body instanceof FormData)
        ? { "Content-Type": "application/json" }
        : {}),
    },
    body:
      body instanceof FormData ? body : body ? JSON.stringify(body) : undefined,
  });
  if (response.status === 204) return null;
  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    if (response.status === 401 && token) {
      window.dispatchEvent(
        new CustomEvent("campah:unauthorized", { detail: { token } }),
      );
    }
    throw Object.assign(
      new Error(
        typeof data.detail === "string"
          ? data.detail
          : Array.isArray(data.detail)
            ? data.detail.map((item) => item.msg).join("; ")
            : `Request failed (${response.status})`,
      ),
      { status: response.status },
    );
  }
  return data;
}

function readSession() {
  try {
    const value = JSON.parse(localStorage.getItem("campah-session") || "null");
    return value?.access_token && value?.user?.name ? value : null;
  } catch {
    localStorage.removeItem("campah-session");
    return null;
  }
}

function App() {
  const [session, setSession] = useState(readSession);
  const [view, setView] = useState("dashboard");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const [refresh, setRefresh] = useState(0);
  const [stats, setStats] = useState(null);
  const [reports, setReports] = useState({
    items: [],
    total: 0,
    page: 1,
    page_size: 10,
  });
  const [users, setUsers] = useState([]);
  const [query, setQuery] = useState("");
  const [filter, setFilter] = useState("");
  const [page, setPage] = useState(1);
  const [editing, setEditing] = useState(null);
  const [loadingReports, setLoadingReports] = useState(false);

  const token = session?.access_token;
  const isAdmin = session?.user?.role === "admin";
  const logout = useCallback(() => {
    localStorage.removeItem("campah-session");
    setSession(null);
    setView("dashboard");
    setEditing(null);
    setStats(null);
    setUsers([]);
    setReports({ items: [], total: 0, page: 1, page_size: 10 });
    setQuery("");
    setFilter("");
    setPage(1);
    setError("");
  }, []);
  const run = async (action) => {
    setError("");
    setBusy(true);
    try {
      await action();
      setRefresh((n) => n + 1);
      return true;
    } catch (e) {
      setError(e.message);
      return false;
    } finally {
      setBusy(false);
    }
  };
  useEffect(() => {
    if (!token) return;
    const expired = (event) => {
      if (event.detail.token === token) logout();
    };
    window.addEventListener("campah:unauthorized", expired);
    return () => window.removeEventListener("campah:unauthorized", expired);
  }, [token, logout]);
  useEffect(() => {
    if (!token) return;
    const controller = new AbortController();
    request("/auth/me", { token, signal: controller.signal })
      .then((user) => {
        if (controller.signal.aborted) return;
        const next = { ...session, user };
        setSession(next);
        localStorage.setItem("campah-session", JSON.stringify(next));
      })
      .catch(() => {
        if (!controller.signal.aborted)
          setError("Tidak dapat memeriksa sesi. Periksa koneksi Anda.");
      });
    return () => controller.abort();
  }, [token]);
  useEffect(() => {
    if (!token) return;
    const controller = new AbortController();
    request("/dashboard", { token, signal: controller.signal })
      .then(setStats)
      .catch((e) => {
        if (!controller.signal.aborted) setError(e.message);
      });
    return () => controller.abort();
  }, [token, refresh]);
  useEffect(() => {
    if (!token || view !== "reports") return;
    const params = new URLSearchParams({
      q: query,
      page: String(page),
      page_size: "10",
    });
    if (filter) params.set("status", filter);
    const controller = new AbortController();
    setLoadingReports(true);
    request(`/reports?${params}`, { token, signal: controller.signal })
      .then((data) => {
        setReports(data);
        if (page > 1 && data.items.length === 0) setPage(page - 1);
      })
      .catch((e) => {
        if (!controller.signal.aborted) setError(e.message);
      })
      .finally(() => {
        if (!controller.signal.aborted) setLoadingReports(false);
      });
    return () => controller.abort();
  }, [token, view, query, filter, page, refresh]);
  useEffect(() => {
    if (!token || !isAdmin || view !== "users") return;
    const controller = new AbortController();
    request("/users", { token, signal: controller.signal })
      .then(setUsers)
      .catch((e) => {
        if (!controller.signal.aborted) setError(e.message);
      });
    return () => controller.abort();
  }, [token, isAdmin, view, refresh]);

  if (!session)
    return (
      <Auth
        onLogin={(value) => {
          localStorage.setItem("campah-session", JSON.stringify(value));
          setSession(value);
          setView("dashboard");
        }}
      />
    );
  const switchView = (value) => {
    setView(value);
    setEditing(null);
    setError("");
  };
  const imageSource = (url) => (url?.startsWith("/") ? `${API}${url}` : url);

  return (
    <div className="shell">
      <aside className="sidebar">
        <div className="brand">
          <span className="brand-icon">♻</span>
          <div>
            <strong>CamPah</strong>
            <small>Management System</small>
          </div>
        </div>
        <nav aria-label="Navigasi utama">
          <button
            aria-label="Dashboard"
            className={view === "dashboard" ? "active" : ""}
            onClick={() => switchView("dashboard")}
          >
            ◫ <span>Dashboard</span>
          </button>
          <button
            aria-label="Laporan"
            className={view === "reports" ? "active" : ""}
            onClick={() => switchView("reports")}
          >
            ▤ <span>Laporan</span>
          </button>
          <button
            aria-label="Buat laporan"
            className={view === "new" ? "active" : ""}
            onClick={() => switchView("new")}
          >
            ＋ <span>Buat laporan</span>
          </button>
          {isAdmin && (
            <button
              aria-label="Pengguna"
              className={view === "users" ? "active" : ""}
              onClick={() => switchView("users")}
            >
              ♙ <span>Pengguna</span>
            </button>
          )}
        </nav>
        <div className="sidebar-bottom">
          <div className="avatar">
            {session.user.name.slice(0, 1).toUpperCase()}
          </div>
          <div>
            <strong>{session.user.name}</strong>
            <small>{isAdmin ? "Administrator" : "Pengguna"}</small>
          </div>
        </div>
      </aside>
      <main>
        <header className="topbar">
          <div>
            <span className="eyebrow">CAMPAH / SMART WASTE</span>
            <h1>
              {view === "dashboard"
                ? "Dashboard"
                : view === "reports"
                  ? "Laporan sampah"
                  : view === "new"
                    ? "Buat laporan"
                    : "Manajemen pengguna"}
            </h1>
          </div>
          <button className="text-button" onClick={logout}>
            Keluar ↗
          </button>
        </header>
        {error && (
          <div className="alert" role="alert">
            {error}
          </div>
        )}
        {view === "dashboard" && (
          <section>
            <div className="intro">
              <div>
                <span className="eyebrow">RINGKASAN</span>
                <h2>Pantau lingkungan, tindak lanjuti laporan.</h2>
                <p>Setiap laporan membantu penanganan sampah lebih terarah.</p>
              </div>
              <button className="primary" onClick={() => switchView("new")}>
                ＋ Buat laporan
              </button>
            </div>
            <div className="stat-grid">
              <Stat
                title="Total laporan"
                number={stats?.total ?? "—"}
                tone="dark"
              />
              {statuses.map((status, i) => (
                <Stat
                  key={status}
                  title={status}
                  number={stats?.by_status?.[status] ?? "—"}
                  tone={["amber", "blue", "green", "red"][i]}
                />
              ))}
            </div>
            <div className="card">
              <h3>Kategori terdeteksi AI</h3>
              <div className="category-grid">
                {["Organic Waste", "Plastic Waste", "Paper Waste"].map(
                  (name, i) => (
                    <div className="category" key={name}>
                      <span className="category-icon">
                        {["◒", "♳", "▧"][i]}
                      </span>
                      <div>
                        <strong>{stats?.by_category?.[name] ?? "—"}</strong>
                        <small>{name}</small>
                      </div>
                    </div>
                  ),
                )}
              </div>
            </div>
          </section>
        )}
        {view === "reports" && (
          <section className="card">
            <div className="section-head">
              <div>
                <h2>Daftar laporan</h2>
                <p>{reports.total} laporan ditemukan</p>
              </div>
              <button className="primary" onClick={() => switchView("new")}>
                ＋ Buat laporan
              </button>
            </div>
            <div className="filters">
              <input
                aria-label="Cari laporan"
                placeholder="Cari deskripsi atau kategori..."
                value={query}
                onChange={(e) => {
                  setQuery(e.target.value);
                  setPage(1);
                }}
              />
              <select
                aria-label="Filter status"
                value={filter}
                onChange={(e) => {
                  setFilter(e.target.value);
                  setPage(1);
                }}
              >
                <option value="">Semua status</option>
                {statuses.map((s) => (
                  <option key={s}>{s}</option>
                ))}
              </select>
            </div>
            <div className="report-list">
              {reports.items.map((report) => (
                <article className="report-row" key={report.id}>
                  <img
                    src={imageSource(report.image_url)}
                    alt="Foto laporan sampah"
                  />
                  <div className="report-content">
                    <div className="report-title">
                      <strong>
                        #{report.id} · {report.description}
                      </strong>
                      <Status value={report.status} />
                    </div>
                    <p>
                      {report.ai_category || "Belum terdeteksi"}{" "}
                      {report.ai_confidence != null
                        ? `· ${Math.round(report.ai_confidence * 100)}%`
                        : ""}{" "}
                      ·{" "}
                      {new Date(report.created_at).toLocaleDateString("id-ID")}
                    </p>
                    <small>
                      📍 {report.latitude.toFixed(5)},{" "}
                      {report.longitude.toFixed(5)}{" "}
                      {isAdmin ? `· User #${report.user_id}` : ""}
                    </small>
                    <div className="actions">
                      {(isAdmin || report.status === "Pending") && (
                        <>
                          <button
                            disabled={busy}
                            onClick={() => setEditing(report)}
                          >
                            Ubah
                          </button>
                          <button
                            disabled={busy}
                            onClick={() =>
                              run(async () => {
                                if (confirm("Hapus laporan ini?"))
                                  await request(`/reports/${report.id}`, {
                                    token,
                                    method: "DELETE",
                                  });
                              })
                            }
                          >
                            Hapus
                          </button>
                        </>
                      )}
                      {isAdmin && (
                        <select
                          disabled={busy}
                          aria-label={`Status laporan ${report.id}`}
                          value={report.status}
                          onChange={(e) =>
                            run(() =>
                              request(`/reports/${report.id}/status`, {
                                token,
                                method: "PATCH",
                                body: { status: e.target.value },
                              }),
                            )
                          }
                        >
                          {statuses.map((s) => (
                            <option key={s}>{s}</option>
                          ))}
                        </select>
                      )}
                    </div>
                  </div>
                </article>
              ))}
              {loadingReports && <p role="status">Memuat laporan...</p>}
              {!loadingReports && reports.items.length === 0 && (
                <p className="empty">Belum ada laporan yang cocok.</p>
              )}
            </div>
            <div className="pager">
              <button disabled={page <= 1} onClick={() => setPage(page - 1)}>
                ← Sebelumnya
              </button>
              <span>Halaman {page}</span>
              <button
                disabled={page * 10 >= reports.total}
                onClick={() => setPage(page + 1)}
              >
                Berikutnya →
              </button>
            </div>
          </section>
        )}
        {view === "new" && (
          <ReportForm
            busy={busy}
            onSubmit={(form) =>
              run(async () => {
                await request("/reports", {
                  token,
                  method: "POST",
                  body: form,
                });
                switchView("reports");
              })
            }
          />
        )}
        {view === "users" && isAdmin && (
          <Users
            users={users}
            currentUserId={session.user.id}
            busy={busy}
            onCreate={(payload) =>
              run(() =>
                request("/users", { token, method: "POST", body: payload }),
              )
            }
            onUpdate={(id, payload) =>
              run(async () => {
                const user = await request(`/users/${id}`, {
                  token,
                  method: "PATCH",
                  body: payload,
                });
                if (id === session.user.id) {
                  const next = { ...session, user };
                  setSession(next);
                  localStorage.setItem("campah-session", JSON.stringify(next));
                }
              })
            }
          />
        )}
        {editing && (
          <div className="modal-backdrop">
            <form
              className="modal"
              onSubmit={(e) => {
                e.preventDefault();
                const form = new FormData(e.currentTarget);
                run(async () => {
                  await request(`/reports/${editing.id}`, {
                    token,
                    method: "PATCH",
                    body: {
                      description: form.get("description"),
                      latitude: Number(form.get("latitude")),
                      longitude: Number(form.get("longitude")),
                    },
                  });
                  setEditing(null);
                });
              }}
            >
              <div className="section-head">
                <h2>Ubah laporan #{editing.id}</h2>
                <button type="button" onClick={() => setEditing(null)}>
                  ✕
                </button>
              </div>
              <label>
                Deskripsi
                <textarea
                  name="description"
                  defaultValue={editing.description}
                  minLength="10"
                  required
                />
              </label>
              <div className="two-col">
                <label>
                  Latitude
                  <input
                    name="latitude"
                    type="number"
                    step="any"
                    min="-90"
                    max="90"
                    defaultValue={editing.latitude}
                    required
                  />
                </label>
                <label>
                  Longitude
                  <input
                    name="longitude"
                    type="number"
                    step="any"
                    min="-180"
                    max="180"
                    defaultValue={editing.longitude}
                    required
                  />
                </label>
              </div>
              <button className="primary" disabled={busy}>
                Simpan perubahan
              </button>
            </form>
          </div>
        )}
      </main>
    </div>
  );
}

function Auth({ onLogin }) {
  const [register, setRegister] = useState(false);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const submit = async (e) => {
    e.preventDefault();
    setBusy(true);
    setError("");
    const data = Object.fromEntries(new FormData(e.currentTarget));
    try {
      onLogin(
        await request(register ? "/auth/register" : "/auth/login", {
          method: "POST",
          body: data,
        }),
      );
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  };
  return (
    <div className="auth-page">
      <div className="auth-side">
        <span className="brand-icon">♻</span>
        <span className="eyebrow">CAMPAH ? SMART WASTE</span>
        <h1>Lingkungan bersih dimulai dari satu laporan.</h1>
        <p>Laporkan, pantau, dan bantu tindak lanjut sampah di sekitar Anda.</p>
        <div className="auth-art">♻</div>
      </div>
      <form className="auth-form" onSubmit={submit}>
        <span className="eyebrow">SELAMAT DATANG</span>
        <h2>{register ? "Buat akun baru" : "Masuk ke akun Anda"}</h2>
        <p>
          {register
            ? "Mulai buat laporan sampah dengan mudah."
            : "Akses dashboard dan pantau laporan Anda."}
        </p>
        {error && (
          <div className="alert" role="alert">
            {error}
          </div>
        )}
        {register && (
          <label>
            Nama lengkap
            <input name="name" minLength="2" required />
          </label>
        )}
        <label>
          Email
          <input type="email" name="email" required />
        </label>
        <label>
          Kata sandi
          <input type="password" name="password" minLength="8" required />
        </label>
        <button className="primary full" disabled={busy}>
          {busy ? "Memproses..." : register ? "Daftar" : "Masuk"}
        </button>
        <p className="switch">
          {register ? "Sudah punya akun?" : "Belum punya akun?"}{" "}
          <button
            type="button"
            onClick={() => {
              setRegister(!register);
              setError("");
            }}
          >
            {register ? "Masuk" : "Daftar sekarang"}
          </button>
        </p>
      </form>
    </div>
  );
}

function ReportForm({ onSubmit, busy }) {
  const [location, setLocation] = useState(null);
  const [locationError, setLocationError] = useState("");
  const locate = () => {
    if (!navigator.geolocation) {
      setLocationError("GPS tidak tersedia di browser ini.");
      return;
    }
    navigator.geolocation.getCurrentPosition(
      (p) => {
        setLocation({
          latitude: p.coords.latitude,
          longitude: p.coords.longitude,
        });
        setLocationError("");
      },
      () =>
        setLocationError("Izin lokasi ditolak. Isi koordinat secara manual."),
    );
  };
  const submit = (e) => {
    e.preventDefault();
    onSubmit(new FormData(e.currentTarget));
  };
  return (
    <form className="card form-card" onSubmit={submit}>
      <div className="section-head">
        <div>
          <h2>Detail laporan</h2>
          <p>Lengkapi informasi lokasi dan foto sampah.</p>
        </div>
      </div>
      <label>
        Deskripsi
        <textarea
          name="description"
          minLength="10"
          maxLength="2000"
          placeholder="Jelaskan kondisi dan lokasi sampah..."
          required
        />
      </label>
      <label>
        Foto sampah
        <input
          name="image"
          type="file"
          accept="image/jpeg,image/png,image/webp"
          required
        />
        <small>JPEG, PNG, atau WEBP; maksimal 8 MB.</small>
      </label>
      <div className="location-row">
        <strong>Lokasi GPS</strong>
        <button type="button" onClick={locate}>
          ◎ Gunakan lokasi saya
        </button>
      </div>
      {locationError && <p className="hint">{locationError}</p>}
      <div className="two-col">
        <label>
          Latitude
          <input
            name="latitude"
            type="number"
            step="any"
            min="-90"
            max="90"
            value={location?.latitude ?? ""}
            onChange={(e) =>
              setLocation({ ...location, latitude: e.target.value })
            }
            required
          />
        </label>
        <label>
          Longitude
          <input
            name="longitude"
            type="number"
            step="any"
            min="-180"
            max="180"
            value={location?.longitude ?? ""}
            onChange={(e) =>
              setLocation({ ...location, longitude: e.target.value })
            }
            required
          />
        </label>
      </div>
      <button className="primary" disabled={busy}>
        {busy ? "Mengirim..." : "Kirim laporan"}
      </button>
    </form>
  );
}

function Users({ users, currentUserId, busy, onCreate, onUpdate }) {
  const [editingUser, setEditingUser] = useState(null);
  const submit = async (e) => {
    e.preventDefault();
    const form = e.currentTarget;
    if (await onCreate(Object.fromEntries(new FormData(form)))) form.reset();
  };
  return (
    <div className="users-layout">
      <form className="card" onSubmit={submit}>
        <h2>Tambah pengguna</h2>
        <label>
          Nama
          <input name="name" minLength="2" required />
        </label>
        <label>
          Email
          <input name="email" type="email" required />
        </label>
        <label>
          Kata sandi
          <input name="password" type="password" minLength="8" required />
        </label>
        <label>
          Role
          <select name="role">
            <option value="user">User</option>
            <option value="admin">Admin</option>
          </select>
        </label>
        <button className="primary" disabled={busy}>
          Tambah pengguna
        </button>
      </form>
      <div className="card">
        <h2>Daftar pengguna</h2>
        {users.map((user) => (
          <div className="user-row" key={user.id}>
            <div className="avatar">{user.name[0]}</div>
            <div>
              <strong>{user.name}</strong>
              <small>{user.email}</small>
            </div>
            <select
              disabled={busy || user.id === currentUserId}
              aria-label={`Role ${user.name}`}
              value={user.role}
              onChange={(e) => onUpdate(user.id, { role: e.target.value })}
            >
              <option value="user">User</option>
              <option value="admin">Admin</option>
            </select>
            <button disabled={busy} onClick={() => setEditingUser(user)}>
              Ubah nama
            </button>
            <button
              disabled={busy || user.id === currentUserId}
              onClick={() => onUpdate(user.id, { is_active: !user.is_active })}
            >
              {user.is_active ? "Nonaktifkan" : "Aktifkan"}
            </button>
          </div>
        ))}
      </div>
      {editingUser && (
        <div className="modal-backdrop">
          <form
            className="modal"
            role="dialog"
            aria-modal="true"
            aria-label="Ubah nama pengguna"
            onSubmit={async (event) => {
              event.preventDefault();
              const name = new FormData(event.currentTarget).get("name");
              if (await onUpdate(editingUser.id, { name }))
                setEditingUser(null);
            }}
          >
            <h2>Ubah nama pengguna</h2>
            <label>
              Nama
              <input
                name="name"
                minLength="2"
                maxLength="120"
                defaultValue={editingUser.name}
                required
                autoFocus
              />
            </label>
            <div className="actions">
              <button type="button" onClick={() => setEditingUser(null)}>
                Batal
              </button>
              <button className="primary" disabled={busy}>
                Simpan nama
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
}

function Status({ value }) {
  return (
    <span className={`badge ${value.toLowerCase().replace(" ", "-")}`}>
      {value}
    </span>
  );
}
function Stat({ title, number, tone }) {
  return (
    <div className={`stat ${tone}`}>
      <small>{title}</small>
      <strong>{number}</strong>
      <span>laporan</span>
    </div>
  );
}

createRoot(document.getElementById("root")).render(<App />);
