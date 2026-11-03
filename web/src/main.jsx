import React, { useCallback, useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import {
  ArrowRight,
  ArrowUpRight,
  Bell,
  Camera,
  CheckCircle2,
  ClipboardList,
  Eye,
  EyeOff,
  ImagePlus,
  LayoutDashboard,
  Leaf,
  LogOut,
  MapPin,
  Moon,
  Navigation,
  Plus,
  Search,
  Sun,
  Users as UsersIcon,
  X,
} from "lucide-react";
import brandMark from "./assets/campah-mark.svg";
import Dashboard from "./Dashboard.jsx";
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
  const [theme, setTheme] = useState(() => {
    const saved = localStorage.getItem("campah-theme");
    return saved === "dark" || saved === "light"
      ? saved
      : window.matchMedia("(prefers-color-scheme: dark)").matches
        ? "dark"
        : "light";
  });
  useEffect(() => {
    document.documentElement.dataset.theme = theme;
    localStorage.setItem("campah-theme", theme);
  }, [theme]);
  const toggleTheme = () =>
    setTheme((current) => (current === "dark" ? "light" : "dark"));
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
  const [categoryFilter, setCategoryFilter] = useState("");
  const [dateFrom, setDateFrom] = useState("");
  const [dateTo, setDateTo] = useState("");
  const [page, setPage] = useState(1);
  const [editing, setEditing] = useState(null);
  const [detail, setDetail] = useState(null);
  const [showProfile, setShowProfile] = useState(false);
  const [notices, setNotices] = useState([]);
  const [showNotices, setShowNotices] = useState(false);
  const [loadingReports, setLoadingReports] = useState(false);
  const [recentReports, setRecentReports] = useState(null);
  const [recentError, setRecentError] = useState(false);

  const token = session?.access_token;
  const isAdmin = session?.user?.role === "admin";
  const logout = useCallback(() => {
    localStorage.removeItem("campah-session");
    setSession(null);
    setView("dashboard");
    setEditing(null);
    setDetail(null);
    setShowProfile(false);
    setNotices([]);
    setShowNotices(false);
    setStats(null);
    setRecentReports(null);
    setUsers([]);
    setReports({ items: [], total: 0, page: 1, page_size: 10 });
    setQuery("");
    setFilter("");
    setCategoryFilter("");
    setDateFrom("");
    setDateTo("");
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
    const controller = new AbortController();
    request("/notifications", { token, signal: controller.signal })
      .then(setNotices)
      .catch(() => {});
    return () => controller.abort();
  }, [token, refresh]);
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
    if (categoryFilter) params.set("category", categoryFilter);
    if (dateFrom) params.set("date_from", dateFrom);
    if (dateTo) params.set("date_to", dateTo);
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
  }, [
    token,
    view,
    query,
    filter,
    categoryFilter,
    dateFrom,
    dateTo,
    page,
    refresh,
  ]);
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

  useEffect(() => {
    if (!token || view !== "dashboard") return;
    const controller = new AbortController();
    setRecentError(false);
    request("/reports?page=1&page_size=3", { token, signal: controller.signal })
      .then((data) => setRecentReports(data.items))
      .catch(() => {
        if (!controller.signal.aborted) setRecentError(true);
      });
    return () => controller.abort();
  }, [token, view, refresh]);

  if (!session)
    return (
      <Auth
        theme={theme}
        toggleTheme={toggleTheme}
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
          <img className="brand-mark" src={brandMark} alt="" />
          <div>
            <strong>CamPah</strong>
            <small>LEBIH PEDULI BUMI</small>
          </div>
        </div>
        <nav aria-label="Navigasi utama">
          <button
            aria-label="Dashboard"
            aria-current={view === "dashboard" ? "page" : undefined}
            className={view === "dashboard" ? "active" : ""}
            onClick={() => switchView("dashboard")}
          >
            <LayoutDashboard size={19} aria-hidden="true" />{" "}
            <span>Dashboard</span>
          </button>
          <button
            aria-label="Laporan"
            aria-current={view === "reports" ? "page" : undefined}
            className={view === "reports" ? "active" : ""}
            onClick={() => switchView("reports")}
          >
            <ClipboardList size={19} aria-hidden="true" /> <span>Laporan</span>
          </button>
          <button
            aria-label="Buat laporan"
            aria-current={view === "new" ? "page" : undefined}
            className={view === "new" ? "active" : ""}
            onClick={() => switchView("new")}
          >
            <Camera size={19} aria-hidden="true" /> <span>Buat laporan</span>
          </button>
          {isAdmin && (
            <button
              aria-label="Pengguna"
              aria-current={view === "users" ? "page" : undefined}
              className={view === "users" ? "active" : ""}
              onClick={() => switchView("users")}
            >
              <UsersIcon size={19} aria-hidden="true" /> <span>Pengguna</span>
            </button>
          )}
        </nav>
        <div className="sidebar-bottom">
          <div className="sidebar-note">
            <Leaf size={17} aria-hidden="true" />
            <span>
              Langkah kecil,
              <br />
              dampak yang berarti.
            </span>
          </div>
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
            <span className="eyebrow">
              RUANG KERJA / {isAdmin ? "ADMIN" : "PENGGUNA"}
            </span>
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
          <div className="topbar-actions">
            <button
              className="text-button"
              onClick={() => setShowProfile(true)}
            >
              Profil
            </button>
            <button
              className="theme-toggle notification-button"
              aria-label="Notifikasi"
              title="Notifikasi"
              onClick={() => setShowNotices(true)}
            >
              <Bell size={19} />
              {notices.some((n) => !n.is_read) && (
                <span className="notification-dot" />
              )}
            </button>
            <ThemeToggle theme={theme} onToggle={toggleTheme} />
            <button className="text-button" onClick={logout}>
              <LogOut size={17} aria-hidden="true" /> Keluar
            </button>
          </div>
        </header>
        {error && (
          <div className="alert" role="alert">
            {error}
          </div>
        )}
        {view === "dashboard" && (
          <Dashboard
            stats={stats}
            name={session.user.name}
            isAdmin={isAdmin}
            recentReports={recentReports}
            recentError={recentError}
            imageSource={imageSource}
            onCreate={() => switchView("new")}
            onOpenReports={() => {
              setFilter("");
              setPage(1);
              switchView("reports");
            }}
            onSelectStatus={(status) => {
              setFilter(status);
              setPage(1);
              switchView("reports");
            }}
          />
        )}
        {view === "reports" && (
          <section className="card">
            <div className="section-head">
              <div>
                <h2>Daftar laporan</h2>
                <p>{reports.total} laporan ditemukan</p>
              </div>
              <button className="primary" onClick={() => switchView("new")}>
                <Plus size={17} aria-hidden="true" /> Buat laporan
              </button>
            </div>
            <div className="filters">
              <Search className="search-icon" size={18} aria-hidden="true" />
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
            {isAdmin && (
              <div className="filters admin-filters">
                <select
                  aria-label="Filter kategori"
                  value={categoryFilter}
                  onChange={(e) => {
                    setCategoryFilter(e.target.value);
                    setPage(1);
                  }}
                >
                  <option value="">Semua kategori</option>
                  <option>Organic Waste</option>
                  <option>Plastic Waste</option>
                  <option>Paper Waste</option>
                </select>
                <label>
                  Dari tanggal
                  <input
                    aria-label="Dari tanggal"
                    type="date"
                    value={dateFrom}
                    onChange={(e) => {
                      setDateFrom(e.target.value);
                      setPage(1);
                    }}
                  />
                </label>
                <label>
                  Sampai tanggal
                  <input
                    aria-label="Sampai tanggal"
                    type="date"
                    value={dateTo}
                    onChange={(e) => {
                      setDateTo(e.target.value);
                      setPage(1);
                    }}
                  />
                </label>
                <button
                  className="text-button"
                  onClick={async () => {
                    try {
                      const params = new URLSearchParams();
                      if (query) params.set("q", query);
                      if (filter) params.set("status", filter);
                      if (categoryFilter)
                        params.set("category", categoryFilter);
                      if (dateFrom) params.set("date_from", dateFrom);
                      if (dateTo) params.set("date_to", dateTo);
                      const response = await fetch(
                        `${API}/reports-export?${params}`,
                        { headers: { Authorization: `Bearer ${token}` } },
                      );
                      if (!response.ok)
                        throw new Error(
                          "Ekspor gagal. Periksa filter dan coba lagi.",
                        );
                      const url = URL.createObjectURL(await response.blob());
                      const a = document.createElement("a");
                      a.href = url;
                      a.download = "campah-laporan.csv";
                      a.click();
                      URL.revokeObjectURL(url);
                    } catch (e) {
                      setError(e.message);
                    }
                  }}
                >
                  Ekspor CSV
                </button>
              </div>
            )}
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
                      <MapPin size={13} aria-hidden="true" />{" "}
                      {report.latitude.toFixed(5)},{" "}
                      {report.longitude.toFixed(5)}{" "}
                      {isAdmin ? `· User #${report.user_id}` : ""}
                    </small>
                    <div className="actions">
                      <button onClick={() => setDetail(report)}>
                        Lihat detail
                      </button>
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
                <button
                  type="button"
                  className="icon-button"
                  aria-label="Tutup"
                  onClick={() => setEditing(null)}
                >
                  <X size={18} aria-hidden="true" />
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
        {detail && (
          <ReportDetail
            report={detail}
            token={token}
            isAdmin={isAdmin}
            imageSource={imageSource}
            onClose={() => setDetail(null)}
            onUpdated={() => setRefresh((n) => n + 1)}
          />
        )}
        {showProfile && (
          <div className="modal-backdrop">
            <form
              className="modal report-detail"
              role="dialog"
              aria-modal="true"
              aria-label="Profil"
              onSubmit={async (e) => {
                e.preventDefault();
                const form = new FormData(e.currentTarget);
                const payload = { name: form.get("name") };
                if (form.get("new_password")) {
                  payload.current_password = form.get("current_password");
                  payload.new_password = form.get("new_password");
                }
                await run(async () => {
                  const user = await request("/auth/me", {
                    token,
                    method: "PATCH",
                    body: payload,
                  });
                  const next = { ...session, user };
                  setSession(next);
                  localStorage.setItem("campah-session", JSON.stringify(next));
                  setShowProfile(false);
                });
              }}
            >
              <div className="section-head">
                <h2>Profil</h2>
                <button
                  type="button"
                  className="icon-button"
                  aria-label="Tutup profil"
                  onClick={() => setShowProfile(false)}
                >
                  <X size={18} />
                </button>
              </div>
              <label>
                Nama
                <input
                  name="name"
                  defaultValue={session.user.name}
                  minLength="2"
                  maxLength="120"
                  required
                />
              </label>
              <p>Untuk mengubah kata sandi, isi kedua kolom berikut.</p>
              <label>
                Kata sandi saat ini
                <input
                  name="current_password"
                  type="password"
                  autoComplete="current-password"
                />
              </label>
              <label>
                Kata sandi baru
                <input
                  name="new_password"
                  type="password"
                  minLength="8"
                  maxLength="72"
                  autoComplete="new-password"
                />
              </label>
              <button className="primary" disabled={busy}>
                Simpan profil
              </button>
              {error && <p role="alert">{error}</p>}
            </form>
          </div>
        )}
        {showNotices && (
          <div className="modal-backdrop">
            <section
              className="modal report-detail"
              role="dialog"
              aria-modal="true"
              aria-label="Notifikasi"
            >
              <div className="section-head">
                <h2>Notifikasi</h2>
                <button
                  className="icon-button"
                  aria-label="Tutup notifikasi"
                  onClick={() => setShowNotices(false)}
                >
                  <X size={18} />
                </button>
              </div>
              {notices.length === 0 ? (
                <p>Belum ada notifikasi.</p>
              ) : (
                notices.map((n) => (
                  <button
                    className="notice-item"
                    key={n.id}
                    onClick={async () => {
                      try {
                        const report = await request(
                          `/reports/${n.report_id}`,
                          { token },
                        );
                        await request(`/notifications/${n.id}/read`, {
                          token,
                          method: "PATCH",
                        });
                        setNotices((items) =>
                          items.map((item) =>
                            item.id === n.id
                              ? { ...item, is_read: true }
                              : item,
                          ),
                        );
                        setShowNotices(false);
                        setDetail(report);
                      } catch (e) {
                        setShowNotices(false);
                        setError(e.message);
                      }
                    }}
                  >
                    <strong>{n.is_read ? "Dibaca" : "Baru"}</strong>
                    <span>{n.message}</span>
                  </button>
                ))
              )}
            </section>
          </div>
        )}
      </main>
    </div>
  );
}

function ReportDetail({
  report: initial,
  token,
  isAdmin,
  imageSource,
  onClose,
  onUpdated,
}) {
  const [report, setReport] = useState(initial);
  const [history, setHistory] = useState(null);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const [action, setAction] = useState("");
  const [correction, setCorrection] = useState(false);
  const loadHistory = useCallback(async () => {
    const items = await request(`/reports/${initial.id}/history`, { token });
    setHistory(items);
  }, [initial.id, token]);
  useEffect(() => {
    loadHistory().catch((e) => setError(e.message));
  }, [loadHistory]);
  const actions =
    report.status === "Pending"
      ? [
          ["In Progress", "Mulai tangani"],
          ["Rejected", "Tolak laporan"],
        ]
      : report.status === "In Progress"
        ? [
            ["Completed", "Selesaikan laporan"],
            ["Rejected", "Tolak laporan"],
          ]
        : [];
  async function submit(e) {
    e.preventDefault();
    const form = e.currentTarget;
    const note = new FormData(form).get("note").trim();
    if (note.length < 3) {
      setError("Catatan minimal 3 karakter.");
      return;
    }
    setBusy(true);
    setError("");
    try {
      const updated = await request(`/reports/${report.id}/status`, {
        token,
        method: "PATCH",
        body: {
          status: action,
          expected_status: report.status,
          note,
          is_correction: correction,
        },
      });
      setReport(updated);
      setAction("");
      setCorrection(false);
      form.reset();
      onUpdated();
      await loadHistory();
    } catch (e) {
      setError(e.message);
    } finally {
      setBusy(false);
    }
  }
  async function reloadDetail() {
    setBusy(true);
    try {
      setReport(await request(`/reports/${report.id}`, { token }));
      await loadHistory();
      setAction("");
      setCorrection(false);
      setError("");
      onUpdated();
    } catch (e) {
      setError(e.message);
    } finally {
      setBusy(false);
    }
  }
  async function uploadEvidence(e) {
    e.preventDefault();
    setBusy(true);
    setError("");
    try {
      setReport(
        await request(`/reports/${report.id}/completion-photo`, {
          token,
          method: "POST",
          body: new FormData(e.currentTarget),
        }),
      );
      onUpdated();
    } catch (e) {
      setError(e.message);
    } finally {
      setBusy(false);
    }
  }
  async function reviewCategory(e) {
    e.preventDefault();
    const form = new FormData(e.currentTarget);
    setBusy(true);
    setError("");
    try {
      setReport(
        await request(`/reports/${report.id}/category-review`, {
          token,
          method: "PATCH",
          body: { category: form.get("category"), note: form.get("note") },
        }),
      );
      onUpdated();
    } catch (e) {
      setError(e.message);
    } finally {
      setBusy(false);
    }
  }
  return (
    <div className="modal-backdrop">
      <div
        className="modal report-detail"
        role="dialog"
        aria-modal="true"
        aria-label={`Detail laporan ${report.id}`}
      >
        <div className="section-head">
          <h2>Laporan #{report.id}</h2>
          <button
            type="button"
            className="icon-button"
            aria-label="Tutup detail"
            onClick={onClose}
          >
            <X size={18} />
          </button>
        </div>
        <img
          className="detail-photo"
          src={imageSource(report.image_url)}
          alt="Foto laporan sampah"
        />
        <div className="detail-status">
          <Status value={report.status} />
          <small>
            {new Date(report.created_at).toLocaleString("id-ID")}
            {isAdmin ? ` · ${report.owner_name} (#${report.user_id})` : ""}
          </small>
        </div>
        <p className="detail-description">{report.description}</p>
        {report.completion_image_url && (
          <div>
            <h3>Bukti penyelesaian</h3>
            <img
              className="detail-photo"
              src={imageSource(report.completion_image_url)}
              alt="Foto bukti penyelesaian"
            />
          </div>
        )}
        <p>
          Lokasi: {report.latitude.toFixed(5)}, {report.longitude.toFixed(5)}
          <br />
          AI: {report.ai_category || "Belum terdeteksi"}
          {report.ai_confidence != null
            ? ` (${Math.round(report.ai_confidence * 100)}%)`
            : ""}
        </p>
        {report.corrected_category && (
          <p>
            Kategori hasil tinjauan:{" "}
            <strong>{report.corrected_category}</strong>
            <br />
            Catatan: {report.category_note}
          </p>
        )}
        {error && (
          <div className="alert" role="alert">
            {error}
            <button
              type="button"
              className="text-button"
              disabled={busy}
              onClick={reloadDetail}
            >
              Muat ulang detail
            </button>
          </div>
        )}
        {isAdmin && (
          <div className="followup-actions">
            <h3>Tindak lanjut</h3>
            <details>
              <summary>Tinjau kategori AI</summary>
              <form onSubmit={reviewCategory} className="followup-form">
                <label>
                  Kategori hasil tinjauan
                  <select
                    name="category"
                    defaultValue={report.corrected_category || ""}
                    required
                  >
                    <option value="">Pilih kategori</option>
                    <option>Organic Waste</option>
                    <option>Plastic Waste</option>
                    <option>Paper Waste</option>
                  </select>
                </label>
                <label>
                  Alasan peninjauan
                  <textarea
                    name="note"
                    minLength="3"
                    maxLength="1000"
                    required
                    defaultValue={report.category_note || ""}
                  />
                </label>
                <button className="primary" disabled={busy}>
                  Simpan tinjauan
                </button>
              </form>
            </details>
            {report.status === "Completed" && !report.completion_image_url && (
              <form onSubmit={uploadEvidence} className="followup-form">
                <label>
                  Foto bukti penyelesaian
                  <input
                    type="file"
                    name="image"
                    accept="image/jpeg,image/png,image/webp"
                    required
                  />
                </label>
                <button className="primary" disabled={busy}>
                  {busy ? "Mengunggah..." : "Unggah bukti"}
                </button>
              </form>
            )}
            <div className="followup-buttons">
              {actions.map(([value, label]) => (
                <button
                  type="button"
                  className="primary"
                  key={value}
                  onClick={() => {
                    setAction(value);
                    setCorrection(false);
                    setError("");
                  }}
                >
                  {label}
                </button>
              ))}
              <button
                type="button"
                className="text-button"
                onClick={() => {
                  setCorrection(true);
                  setAction("");
                  setError("");
                }}
              >
                Koreksi status
              </button>
            </div>
            {(action || correction) && (
              <form onSubmit={submit} className="followup-form">
                {correction && (
                  <label>
                    Status koreksi
                    <select
                      aria-label="Status koreksi"
                      value={action}
                      required
                      onChange={(e) => setAction(e.target.value)}
                    >
                      <option value="">Pilih status</option>
                      {statuses
                        .filter((s) => s !== report.status)
                        .map((s) => (
                          <option key={s} value={s}>
                            {s}
                          </option>
                        ))}
                    </select>
                  </label>
                )}
                <label>
                  {correction
                    ? "Alasan koreksi"
                    : action === "Rejected"
                      ? "Alasan penolakan"
                      : "Catatan tindak lanjut"}
                  <textarea
                    name="note"
                    minLength="3"
                    maxLength="1000"
                    required
                    placeholder="Catatan ini dapat dilihat pelapor"
                  />
                </label>
                <button className="primary" disabled={busy || !action}>
                  {busy ? "Menyimpan..." : "Simpan tindak lanjut"}
                </button>
              </form>
            )}
          </div>
        )}
        <h3>Riwayat tindak lanjut</h3>
        {history === null ? (
          <p role="status">Memuat riwayat...</p>
        ) : history.length === 0 ? (
          <p>Belum ada tindak lanjut.</p>
        ) : (
          <ol className="timeline">
            {history.map((item) => (
              <li key={item.id}>
                <strong>
                  {item.is_correction ? "Koreksi: " : ""}
                  {item.old_status} → {item.new_status}
                </strong>
                <small>
                  {item.admin_name} ·{" "}
                  {new Date(item.changed_at).toLocaleString("id-ID")}
                </small>
                <p>
                  {item.note || "Tidak ada catatan untuk perubahan sebelumnya."}
                </p>
              </li>
            ))}
          </ol>
        )}
      </div>
    </div>
  );
}

function ThemeToggle({ theme, onToggle }) {
  const dark = theme === "dark";
  return (
    <button
      type="button"
      className="theme-toggle"
      onClick={onToggle}
      aria-label={dark ? "Aktifkan mode terang" : "Aktifkan mode gelap"}
      title={dark ? "Aktifkan mode terang" : "Aktifkan mode gelap"}
    >
      {dark ? (
        <Sun size={19} aria-hidden="true" />
      ) : (
        <Moon size={19} aria-hidden="true" />
      )}
    </button>
  );
}

function Auth({ onLogin, theme, toggleTheme }) {
  const [register, setRegister] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
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
        <div className="auth-brand">
          <img src={brandMark} alt="" />
          <div>
            <strong>CamPah</strong>
            <small>LEBIH PEDULI BUMI</small>
          </div>
        </div>
        <div className="auth-message">
          <span className="welcome-kicker">
            <span className="kicker-dot" /> BERSAMA UNTUK LINGKUNGAN
          </span>
          <h1>
            Langkah kecil.
            <br />
            <em>Dampak besar.</em>
          </h1>
          <p>
            Lingkungan yang lebih bersih dimulai dari kepedulian kita bersama.
          </p>
          <div className="auth-steps">
            <span>
              <Camera size={17} aria-hidden="true" /> Foto temuanmu
            </span>
            <i />
            <span>
              <MapPin size={17} aria-hidden="true" /> Tandai lokasinya
            </span>
            <i />
            <span>
              <CheckCircle2 size={17} aria-hidden="true" /> Pantau progresnya
            </span>
          </div>
        </div>
        <div className="auth-decoration" aria-hidden="true">
          <span />
          <span />
          <span />
        </div>
        <div className="auth-footer">
          <span>CAMPAH / SMART WASTE</span>
          <span>
            UNTUK BUMI YANG LEBIH BAIK <ArrowUpRight size={15} />
          </span>
        </div>
      </div>
      <form className="auth-form" onSubmit={submit}>
        <div className="auth-theme">
          <ThemeToggle theme={theme} onToggle={toggleTheme} />
        </div>
        <div className="auth-mobile-brand">
          <img src={brandMark} alt="" />
          <strong>CamPah</strong>
        </div>
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
        <div className="field">
          <label htmlFor="auth-password">Kata sandi</label>
          <div className="password-field">
            <input
              id="auth-password"
              type={showPassword ? "text" : "password"}
              name="password"
              minLength="8"
              autoComplete={register ? "new-password" : "current-password"}
              required
            />
            <button
              type="button"
              aria-label={
                showPassword ? "Sembunyikan kata sandi" : "Tampilkan kata sandi"
              }
              onClick={() => setShowPassword(!showPassword)}
            >
              {showPassword ? (
                <EyeOff size={18} aria-hidden="true" />
              ) : (
                <Eye size={18} aria-hidden="true" />
              )}
            </button>
          </div>
        </div>
        <button className="primary full" disabled={busy}>
          {busy ? "Memproses..." : register ? "Daftar" : "Masuk"}{" "}
          <ArrowRight size={17} aria-hidden="true" />
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
  const [preview, setPreview] = useState(null);
  const [photoName, setPhotoName] = useState("");
  useEffect(
    () => () => {
      if (preview) URL.revokeObjectURL(preview);
    },
    [preview],
  );
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
          <span className="eyebrow">LAPORAN BARU</span>
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
      <label className="upload-label">
        <span>Foto sampah</span>
        <span className={`upload-zone ${preview ? "has-preview" : ""}`}>
          {preview ? (
            <img src={preview} alt="Pratinjau foto laporan" />
          ) : (
            <span className="upload-icon">
              <ImagePlus size={23} aria-hidden="true" />
            </span>
          )}
          <span>
            <strong>{photoName || "Pilih foto sampah"}</strong>
            <small>JPEG, PNG, atau WEBP · maksimal 8 MB</small>
          </span>
        </span>
        <input
          className="file-input"
          aria-label="Foto sampah"
          name="image"
          type="file"
          accept="image/jpeg,image/png,image/webp"
          onChange={(event) => {
            const file = event.target.files?.[0];
            event.target.setCustomValidity(
              file && file.size > 8 * 1024 * 1024
                ? "Ukuran foto maksimal 8 MB."
                : "",
            );
            setPhotoName(file?.name || "");
            setPreview(file ? URL.createObjectURL(file) : null);
          }}
          required
        />
      </label>
      <div className="location-row">
        <strong>Lokasi GPS</strong>
        <button type="button" onClick={locate}>
          <Navigation size={15} aria-hidden="true" /> Gunakan lokasi saya
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
        {busy ? "Mengirim..." : "Kirim laporan"}{" "}
        <ArrowRight size={17} aria-hidden="true" />
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
createRoot(document.getElementById("root")).render(<App />);
