# Progres CamPah

Pembaruan: **3 November 2026 (Asia/Jakarta)**. Repository: https://github.com/MhmmdIchsan/CamPah. Perubahan fitur/perbaikan dicatat dengan Conventional Commits dan file terkait.

## Pembaruan tampilan 3 November

- Logo vektor kamera dan daun, palet hijau-lime, serta tipografi Plus Jakarta Sans diterapkan pada web, Flutter, dan ikon Android. Berkas logo dan lisensi font dijelaskan di `docs/BRAND.md`.
- Dashboard web menampilkan progres, kategori, dan laporan terbaru dari API. Kartu status membuka laporan dengan filter yang sesuai; formulir menampilkan pratinjau foto dan login menyediakan kontrol visibilitas kata sandi.
- Android memiliki tampilan dan navigasi baru, filter riwayat berdasarkan status, detail laporan, dan tampilan foto/lokasi yang lebih jelas.
- Verifikasi lokal: build web berhasil; **4 pengujian browser** lulus termasuk layar 320 piksel; `flutter analyze` bersih dan **3 pengujian Flutter** lulus termasuk layar sempit dengan teks diperbesar.
- [Build APK untuk perubahan visual](https://github.com/MhmmdIchsan/CamPah/actions/runs/41574493778) berhasil melalui workflow Android. Artifact `campah-apk` berisi APK debug dengan tampilan terbaru.

## Implementasi tersedia

- API: registrasi/login JWT, akses Admin/User, CRUD laporan dengan soft delete, pencarian/filter/pagination, status history, dashboard, manajemen pengguna, prediksi, serta migrasi Alembic.
- Web: dashboard responsif, autentikasi dan penanganan sesi, laporan dengan foto/GPS, ubah/hapus sesuai izin, filter, pagination, serta manajemen nama/role/status pengguna.
- Android: source Flutter dan platform Android dengan nama/ikon CamPah, kamera/galeri, GPS, hasil AI beserta confidence, dashboard, riwayat dengan pagination, dan penanganan sesi kedaluwarsa.
- ML: pengunduh RealWaste yang dapat dilanjutkan dengan revisi sumber tetap, training MobileNetV2, checkpoint, evaluasi, contoh foto, dan atribusi.
- Dokumentasi: PRD, instalasi, API/OpenAPI, arsitektur/ERD, deployment Render, model card, dan skenario video demo.

## Hasil verifikasi

| Pemeriksaan | Hasil |
| --- | --- |
| API dan migrasi SQLite | **9 passed**, termasuk akses lintas pengguna, status, soft delete, input, foto kamera, dan model asli |
| Browser Playwright | **4 passed**: alur User/Admin, filter status, pratinjau foto, sesi, dan layout ponsel |
| Build web | Berhasil dengan Vite 8; audit dependensi **0 vulnerabilities** |
| Flutter analyze | **No issues found** |
| Flutter test | **3 passed**: formulir registrasi, sesi API, serta filter/detail pada layar sempit |
| GitHub Checks | **Success** untuk commit `9b9a6b0`; mencakup PostgreSQL 16, model, API, dan web |
| Android APK | Build debug terbaru berhasil pada [run 41574493778](https://github.com/MhmmdIchsan/CamPah/actions/runs/41574493778); artifact `campah-apk` |
| Paket pengumpulan lokal | Arsip dataset berisi 600 foto terverifikasi; arsip model berisi checkpoint, source training, evaluasi, dan atribusi; integritas ZIP diperiksa |

Model dilatih pada 600 foto, masing-masing 200 per kategori, dengan split 420 train / 90 validation / 90 test. Checkpoint terbaik dipilih berdasarkan validation set; akurasi test **96,67% (87/90)**. Hasil lengkap ada di `ml/artifacts/`. Dataset awal Mendeley diganti karena kelas Plastic hanya menyediakan dua file; lihat `ml/DATASET.md`.

Sebagian pengujian API memakai SQLite dan prediksi pengganti untuk menguji aturan bisnis. Satu pengujian integrasi memuat checkpoint asli dan memeriksa `/predict`, laporan, serta dashboard. Migrasi PostgreSQL diperiksa terpisah di GitHub Actions.

## Artefak dan pengumpulan

`python scripts/package_submission.py` membuat `artifacts/campah-dataset.zip`, `artifacts/campah-ml.zip`, dan `SHA256SUMS.txt`. APK dari GitHub Actions dapat diunduh melalui artifact `campah-apk`. Folder `artifacts/` diabaikan Git; bobot model dan evaluasi tetap disimpan di repository.

APK debug menggunakan `http://10.0.2.2:8000` untuk API pada host emulator. APK yang menunjuk layanan publik perlu dibuild ulang setelah URL HTTPS API tersedia. Build release assessment masih memakai signing debug.

## Belum selesai / membutuhkan layanan atau perangkat

1. Akun Cloudinary dan Render belum disiapkan, sehingga demo web/API publik serta persistensi foto pada layanan nyata belum diverifikasi. Konfigurasi dan panduan deployment sudah tersedia.
2. Kamera, galeri, GPS, dan API pada perangkat Android nyata belum diuji. Build dan widget test tidak menggantikan pengujian ini.
3. Video dengan penjelasan kandidat maksimal 10 menit belum direkam; skenario tersedia di `docs/DEMO_SCRIPT.md`.
4. URL demo, URL API, tautan distribusi APK publik, serta video perlu dilengkapi sebelum pengumpulan akhir.

Tanggal/jam deadline resmi tetap perlu dicocokkan dengan email asli. Target internal perencanaan adalah 5 November 2026 pukul 23.59 WIB.
