import {
  ArrowDownRight,
  ArrowRight,
  ArrowUpRight,
  CheckCircle2,
  CircleMinus,
  Clock3,
  FileText,
  Leaf,
  Plus,
  Sparkles,
  Trash2,
} from "lucide-react";

const statusCards = [
  {
    name: "Pending",
    description: "Menunggu ditinjau",
    icon: Clock3,
    color: "amber",
  },
  {
    name: "In Progress",
    description: "Sedang ditangani",
    icon: ArrowUpRight,
    color: "blue",
  },
  {
    name: "Completed",
    description: "Sudah diselesaikan",
    icon: CheckCircle2,
    color: "green",
  },
  {
    name: "Rejected",
    description: "Tidak dapat diproses",
    icon: CircleMinus,
    color: "red",
  },
];

export default function Dashboard({
  stats,
  name,
  isAdmin,
  recentReports,
  recentError,
  onCreate,
  onOpenReports,
  onSelectStatus,
  imageSource,
}) {
  const total = stats?.total;
  const completed = stats?.by_status?.Completed ?? 0;
  const percent = total > 0 ? Math.round((completed / total) * 100) : 0;
  const categories = [
    { key: "Organic Waste", name: "Organik", icon: Leaf, color: "organic" },
    { key: "Plastic Waste", name: "Plastik", icon: Sparkles, color: "plastic" },
    { key: "Paper Waste", name: "Kertas", icon: FileText, color: "paper" },
  ];
  const classified = categories.reduce(
    (sum, item) => sum + (stats?.by_category?.[item.key] ?? 0),
    0,
  );

  return (
    <section className="dashboard" aria-label="Ringkasan dashboard">
      <div className="welcome-grid">
        <div className="welcome-card">
          <div className="welcome-content">
            <span className="welcome-kicker">
              <span className="kicker-dot" /> SATU LANGKAH LEBIH PEDULI
            </span>
            <h2>
              Halo, {name.split(" ")[0]}
              <span className="welcome-spark">✳</span>
              <br />
              Yuk, jaga lingkungan bersama.
            </h2>
            <p>
              {isAdmin
                ? "Pantau laporan dan bantu setiap aduan sampai ditangani."
                : "Temukan sampah di sekitarmu? Satu laporan bisa membawa perubahan."}
            </p>
            <button className="primary hero-button" onClick={onCreate}>
              <Plus size={18} aria-hidden="true" /> Buat laporan{" "}
              <ArrowUpRight size={16} aria-hidden="true" />
            </button>
          </div>
          <div className="welcome-art" aria-hidden="true">
            <div className="art-orbit orbit-one" />
            <div className="art-orbit orbit-two" />
            <div className="art-camera">
              <span className="art-lens" />
              <span className="art-leaf">
                <Leaf size={25} />
              </span>
            </div>
            <span className="art-star star-one">✳</span>
            <span className="art-star star-two">✦</span>
          </div>
          <div className="welcome-foot">
            <span>CAMPAH COMMUNITY</span>
            <span>01 / PEDULI LINGKUNGAN</span>
          </div>
        </div>
        <div className="overview-card">
          <div className="overview-head">
            <span>RINGKASAN LAPORAN</span>
            <ArrowUpRight size={17} aria-hidden="true" />
          </div>
          <div className="overview-main">
            <span className="overview-number">{total ?? "—"}</span>
            <div>
              <strong>Total laporan</strong>
              <small>
                {isAdmin ? "Seluruh pengguna" : "Laporan yang kamu buat"}
              </small>
            </div>
          </div>
          <div className="overview-divider" />
          <div className="completion">
            <div
              className="completion-ring"
              style={{ "--completion": `${percent}%` }}
              role="img"
              aria-label={`${percent}% laporan selesai`}
            >
              <span>{total == null ? "—" : `${percent}%`}</span>
            </div>
            <div>
              <strong>Sudah selesai</strong>
              <small>
                {total == null
                  ? "Memuat data..."
                  : `${completed} dari ${total} laporan`}
              </small>
            </div>
          </div>
        </div>
      </div>

      <div className="section-caption">
        <div>
          <span className="eyebrow">PANTAU PROGRES</span>
          <h2>Status laporan</h2>
        </div>
        <button className="link-button" onClick={onOpenReports}>
          Lihat semua <ArrowRight size={16} aria-hidden="true" />
        </button>
      </div>
      <div className="stat-grid">
        {statusCards.map(({ name: status, description, icon: Icon, color }) => (
          <button
            className={`stat ${color}`}
            key={status}
            onClick={() => onSelectStatus(status)}
            aria-label={`Lihat laporan ${status}`}
          >
            <span className="stat-top">
              <span className="stat-icon">
                <Icon size={19} aria-hidden="true" />
              </span>
              <ArrowUpRight
                size={16}
                className="stat-arrow"
                aria-hidden="true"
              />
            </span>
            <strong>{stats?.by_status?.[status] ?? "—"}</strong>
            <span className="stat-label">{status}</span>
            <small>{description}</small>
          </button>
        ))}
      </div>

      <div className="dashboard-bottom">
        <div className="card recent-card">
          <div className="section-head compact">
            <div>
              <span className="eyebrow">AKTIVITAS TERKINI</span>
              <h2>Laporan terbaru</h2>
            </div>
            <button
              className="icon-button"
              onClick={onOpenReports}
              aria-label="Lihat semua laporan"
            >
              <ArrowUpRight size={18} aria-hidden="true" />
            </button>
          </div>
          {recentError ? (
            <p className="dashboard-empty">
              Laporan terbaru belum dapat dimuat.
            </p>
          ) : recentReports == null ? (
            <p className="dashboard-empty" role="status">
              Memuat laporan...
            </p>
          ) : recentReports.length === 0 ? (
            <div className="recent-empty">
              <span className="empty-icon">
                <ClipboardEmpty />
              </span>
              <strong>Belum ada laporan</strong>
              <p>Laporan yang dibuat akan muncul di sini.</p>
              <button className="link-button" onClick={onCreate}>
                Mulai buat laporan <ArrowRight size={15} aria-hidden="true" />
              </button>
            </div>
          ) : (
            <div className="recent-list">
              {recentReports.map((report) => (
                <button
                  className="recent-item"
                  key={report.id}
                  onClick={onOpenReports}
                >
                  <img src={imageSource(report.image_url)} alt="" />
                  <span className="recent-copy">
                    <strong>{report.description}</strong>
                    <small>
                      #{report.id} <span>·</span>{" "}
                      {new Date(report.created_at).toLocaleDateString("id-ID", {
                        day: "numeric",
                        month: "short",
                        year: "numeric",
                      })}
                    </small>
                  </span>
                  <span
                    className={`badge ${report.status.toLowerCase().replaceAll(" ", "-")}`}
                  >
                    {report.status}
                  </span>
                </button>
              ))}
            </div>
          )}
        </div>
        <div className="card categories-card">
          <div className="section-head compact">
            <div>
              <span className="eyebrow">PENGENALAN GAMBAR</span>
              <h2>Kategori sampah</h2>
            </div>
            <span className="ai-tag">
              <Sparkles size={13} aria-hidden="true" /> AI
            </span>
          </div>
          <p className="category-intro">
            Hasil identifikasi dari foto laporan.
          </p>
          <div className="category-list">
            {categories.map(({ key, name: label, icon: Icon, color }) => {
              const count = stats?.by_category?.[key] ?? 0;
              const width = classified ? (count / classified) * 100 : 0;
              return (
                <div className="category-line" key={key}>
                  <span className={`category-icon ${color}`}>
                    <Icon size={18} aria-hidden="true" />
                  </span>
                  <div className="category-detail">
                    <div>
                      <strong>{label}</strong>
                      <span>{stats ? count : "—"}</span>
                    </div>
                    <div className="progress-track">
                      <span className={color} style={{ width: `${width}%` }} />
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
          <div className="category-foot">
            <span>
              {stats ? `${classified} foto teridentifikasi` : "Memuat data..."}
            </span>
            <ArrowDownRight size={16} aria-hidden="true" />
          </div>
        </div>
      </div>
    </section>
  );
}

function ClipboardEmpty() {
  return <Trash2 size={22} aria-hidden="true" />;
}
