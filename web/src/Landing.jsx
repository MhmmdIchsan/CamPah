import {
  ArrowDown,
  ArrowRight,
  ArrowUpRight,
  Camera,
  Check,
  CheckCircle2,
  ClipboardCheck,
  Leaf,
  MapPin,
  ScanLine,
  Sparkles,
} from "lucide-react";
import brandMark from "./assets/campah-mark.svg";
import "./landing.css";

function Scene() {
  return (
    <svg
      className="lp-scene"
      viewBox="0 0 340 270"
      role="img"
      aria-label="Ilustrasi lingkungan hijau dan botol plastik"
    >
      <rect width="340" height="270" fill="#d9e8c5" />
      <circle cx="265" cy="55" r="30" fill="#f0c789" />
      <path d="M0 175 Q65 92 142 163 Q240 78 340 155 V270 H0Z" fill="#a7c998" />
      <path
        d="M0 206 Q100 150 190 206 Q270 153 340 193 V270 H0Z"
        fill="#779f76"
      />
      <path d="M0 240 Q110 203 187 243 T340 235 V270 H0Z" fill="#446f58" />
      <path
        d="M71 205 Q77 157 58 133 M75 187 Q95 166 103 157 M74 189 Q52 171 45 166"
        stroke="#315e48"
        strokeWidth="5"
        strokeLinecap="round"
        fill="none"
      />
      <path
        d="M58 137 Q30 129 38 105 Q61 108 58 137 M101 158 Q102 131 124 133 Q126 152 101 158 M48 168 Q24 169 21 148 Q38 141 48 168"
        fill="#507f5a"
      />
      <g transform="translate(198 134) rotate(14)">
        <path
          d="M14 20 V9 H32 V20 L39 32 V95 Q39 104 30 104 H15 Q6 104 6 95 V32Z"
          fill="#d4e6d9"
          stroke="#456d58"
          strokeWidth="3"
        />
        <path
          d="M14 9 V3 H32 V9"
          fill="#b3d474"
          stroke="#456d58"
          strokeWidth="3"
        />
        <path d="M7 49 H38 V75 H7Z" fill="#a5c4b2" />
        <path
          d="M16 60 H30 M16 66 H27"
          stroke="#6d9a82"
          strokeWidth="2"
          strokeLinecap="round"
        />
      </g>
      <path
        d="M148 229 q19 -18 37 0 M248 226 q14 -12 26 0"
        stroke="#95bd88"
        strokeWidth="3"
        fill="none"
        strokeLinecap="round"
      />
    </svg>
  );
}

export default function Landing({ onLogin, onRegister, themeToggle }) {
  return (
    <div className="lp" id="beranda">
      <header className="lp-header">
        <a href="#beranda" className="lp-brand">
          <img src={brandMark} alt="" />
          <span>
            <b>CamPah</b>
            <small>LEBIH PEDULI BUMI</small>
          </span>
        </a>
        <nav className="lp-nav" aria-label="Navigasi landing page">
          <a href="#cara-kerja">Cara kerja</a>
          <a href="#fitur">Kenapa CamPah?</a>
        </nav>
        <div className="lp-head-actions">
          {themeToggle}
          <button className="lp-login" onClick={onLogin}>
            Masuk
          </button>
          <button className="lp-nav-cta" onClick={onRegister}>
            Mulai sekarang <ArrowUpRight size={15} />
          </button>
        </div>
      </header>
      <main>
        <section className="lp-hero">
          <div className="lp-hero-copy">
            <span className="lp-kicker">
              <span /> UNTUK LINGKUNGAN YANG LEBIH BAIK
            </span>
            <h1>
              Peduli dimulai
              <br />
              dari{" "}
              <em>
                satu foto<span>.</span>
              </em>
            </h1>
            <p>
              Melihat sampah di sekitar? Foto, laporkan, dan pantau
              penanganannya. Langkah kecilmu bisa ikut menjaga tempat yang kita
              sebut rumah.
            </p>
            <div className="lp-hero-actions">
              <button className="lp-btn-primary" onClick={onRegister}>
                Mulai laporkan <ArrowUpRight size={18} />
              </button>
              <a className="lp-btn-quiet" href="#cara-kerja">
                <span>
                  <ArrowDown size={16} />
                </span>{" "}
                Lihat cara kerjanya
              </a>
            </div>
            <div className="lp-hero-note">
              <div className="lp-mini-icons">
                <span>
                  <Camera size={15} />
                </span>
                <span>
                  <MapPin size={15} />
                </span>
                <span>
                  <Check size={15} />
                </span>
              </div>
              <span>
                Dari temuan kecil
                <br />
                <b>menuju perubahan nyata.</b>
              </span>
            </div>
          </div>
          <div className="lp-visual" aria-label="Ilustrasi cara kerja CamPah">
            <div className="lp-orbit lp-orbit-one" />
            <div className="lp-orbit lp-orbit-two" />
            <div className="lp-visual-label">
              A LITTLE CARE
              <br />
              <strong>GOES A LONG WAY</strong>
            </div>
            <span className="lp-star lp-star-one">✳</span>
            <span className="lp-star lp-star-two">✦</span>
            <div className="lp-phone">
              <div className="lp-phone-top">
                <span>9:41</span>
                <div className="lp-phone-island" />
                <span>● ▰</span>
              </div>
              <div className="lp-phone-brand">
                <img src={brandMark} alt="" />
                <b>CamPah</b>
                <span>•••</span>
              </div>
              <div className="lp-phone-intro">
                <small>LAPORAN BARU</small>
                <strong>
                  Setiap foto
                  <br />
                  punya cerita.
                </strong>
              </div>
              <div className="lp-photo">
                <Scene />
                <div className="lp-scan-frame" />
                <span className="lp-photo-chip">
                  <ScanLine size={12} /> FOTO LAPORAN
                </span>
              </div>
              <div className="lp-phone-location">
                <span>
                  <MapPin size={15} />
                </span>
                <div>
                  <b>Lokasi ditandai</b>
                  <small>Siap untuk dilaporkan</small>
                </div>
                <CheckCircle2 size={16} />
              </div>
              <div className="lp-phone-button">
                Kirim laporan <ArrowUpRight size={13} />
              </div>
              <div className="lp-phone-bottom" />
            </div>
            <div className="lp-floating lp-floating-top">
              <div className="lp-floating-icon">
                <Sparkles size={18} />
              </div>
              <div>
                <small>BANTUAN AI</small>
                <b>Kenali kategori</b>
              </div>
            </div>
            <div className="lp-floating lp-floating-bottom">
              <div className="lp-floating-icon lp-floating-green">
                <Check size={18} />
              </div>
              <div>
                <small>STATUS LAPORAN</small>
                <b>Mudah dipantau</b>
              </div>
            </div>
            <span className="lp-visual-caption">
              ILUSTRASI PENGGUNAAN / CAMPAH
            </span>
          </div>
        </section>
        <div className="lp-ribbon">
          <span>FOTO TEMUANMU</span>
          <span>✳</span>
          <span>TANDAI LOKASI</span>
          <span>✳</span>
          <span>PANTAU PROGRESNYA</span>
          <span>✳</span>
          <span>JAGA LINGKUNGAN</span>
        </div>
        <section className="lp-process lp-section" id="cara-kerja">
          <div className="lp-section-heading">
            <div>
              <span className="lp-overline">01 / CARA KERJA</span>
              <h2>
                Tiga langkah kecil.
                <br />
                <em>Satu dampak berarti.</em>
              </h2>
            </div>
            <p>
              Tidak perlu bingung harus mulai dari mana. CamPah membantu
              laporanmu sampai ke proses penanganan.
            </p>
          </div>
          <div className="lp-steps">
            <article>
              <div className="lp-step-top">
                <span>01</span>
                <Camera size={23} />
              </div>
              <h3>Ambil foto</h3>
              <p>
                Temukan sampah di sekitarmu, lalu ambil foto yang jelas atau
                pilih dari galeri.
              </p>
              <span className="lp-step-arrow">
                <ArrowUpRight size={18} />
              </span>
            </article>
            <article>
              <div className="lp-step-top">
                <span>02</span>
                <MapPin size={23} />
              </div>
              <h3>Tandai &amp; kirim</h3>
              <p>
                Tambahkan deskripsi dan lokasi agar laporan lebih mudah dipahami
                dan ditindaklanjuti.
              </p>
              <span className="lp-step-arrow">
                <ArrowUpRight size={18} />
              </span>
            </article>
            <article>
              <div className="lp-step-top">
                <span>03</span>
                <ClipboardCheck size={23} />
              </div>
              <h3>Pantau progres</h3>
              <p>
                Ikuti perubahan status dan lihat catatan penanganan dari admin
                melalui riwayat laporan.
              </p>
              <span className="lp-step-arrow">
                <ArrowUpRight size={18} />
              </span>
            </article>
          </div>
        </section>
        <section className="lp-feature lp-section" id="fitur">
          <div className="lp-feature-visual">
            <div className="lp-feature-grid" />
            <div className="lp-feature-circle">
              <Leaf size={62} strokeWidth={1.15} />
            </div>
            <div className="lp-feature-tag">
              <span>✳</span> TEKNOLOGI UNTUK BUMI
            </div>
            <div className="lp-feature-caption">
              01 — PEDULI
              <br />
              02 — LAPORKAN
              <br />
              03 — PANTAU
            </div>
          </div>
          <div className="lp-feature-copy">
            <span className="lp-overline">02 / DIBUAT UNTUK PEDULI</span>
            <h2>
              Sederhana untukmu.
              <br />
              <em>Berarti untuk sekitar.</em>
            </h2>
            <p>
              CamPah menghubungkan laporan warga dan tindak lanjut admin dalam
              satu alur yang mudah dipahami.
            </p>
            <div className="lp-feature-list">
              <div>
                <span>
                  <ScanLine size={20} />
                </span>
                <div>
                  <h3>Dibantu pengenalan AI</h3>
                  <p>
                    Foto dapat diidentifikasi sebagai sampah organik, plastik,
                    atau kertas. Hasilnya tetap perlu diperiksa.
                  </p>
                </div>
              </div>
              <div>
                <span>
                  <ClipboardCheck size={20} />
                </span>
                <div>
                  <h3>Progres lebih transparan</h3>
                  <p>
                    Lihat status, catatan, dan bukti penyelesaian ketika
                    tersedia.
                  </p>
                </div>
              </div>
              <div>
                <span>
                  <Camera size={20} />
                </span>
                <div>
                  <h3>Nyaman di web &amp; Android</h3>
                  <p>
                    Buat dan pantau laporan dari perangkat yang paling mudah
                    kamu gunakan.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </section>
        <section className="lp-cta lp-section">
          <div className="lp-cta-decoration">✳</div>
          <span className="lp-overline">MULAI DARI SEKITARMU</span>
          <h2>
            Lingkungan lebih bersih
            <br />
            <em>dimulai dari kita.</em>
          </h2>
          <p>
            Satu foto hari ini bisa menjadi awal dari lingkungan yang lebih
            terjaga.
          </p>
          <button className="lp-btn-light" onClick={onRegister}>
            Buat akun CamPah <ArrowUpRight size={18} />
          </button>
          <span className="lp-cta-foot">LANGKAH KECIL, DAMPAK BESAR ↗</span>
        </section>
      </main>
      <footer className="lp-footer">
        <a href="#beranda" className="lp-brand">
          <img src={brandMark} alt="" />
          <span>
            <b>CamPah</b>
            <small>LEBIH PEDULI BUMI</small>
          </span>
        </a>
        <p>Lebih peduli, dimulai dari sini.</p>
        <a href="#beranda">
          Kembali ke atas <ArrowUpRight size={15} />
        </a>
      </footer>
    </div>
  );
}
