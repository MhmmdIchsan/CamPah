# Progres implementasi

Tanggal pencatatan awal: **2 November 2026 (Asia/Jakarta)**.

Nama aplikasi ditetapkan sebagai **CamPah**.

## Sudah dibuat

- Source API untuk registrasi/login JWT, akses Admin/User, CRUD laporan dengan soft delete, pencarian/filter/pagination, status laporan, dashboard, manajemen pengguna, dan endpoint prediksi.
- Source web untuk autentikasi, dashboard, formulir dan pengelolaan laporan, serta manajemen pengguna.
- Source Flutter dan platform Android untuk autentikasi, dashboard, kamera/galeri, GPS, pembuatan laporan, hasil AI, serta riwayat dengan pagination.
- Pengunduh dataset Mendeley dan pipeline training/evaluasi MobileNetV2.
- Migrasi awal Alembic, konfigurasi PostgreSQL lokal, dan blueprint Render.

## Verifikasi yang telah dilakukan

- `python -m pytest api/tests -q`: **9 passed**, mencakup akses laporan, input kosong, password Unicode, pagination, kegagalan prediksi, orientasi foto kamera, migrasi Alembic naik–turun pada SQLite, dan integrasi model terlatih.
- `npm run build` di `web/`: **berhasil**.
- `npm run test:e2e`: **3 passed**, memverifikasi pembuatan/perubahan laporan, status Admin, ubah nama pengguna, izin tombol laporan, sesi rusak/kedaluwarsa, dan layout ponsel. Audit dependensi web: **0 vulnerabilities** setelah pembaruan Vite.
- Pemeriksaan sintaks Python pada API, prediktor, dan training: **berhasil** sebelum perubahan terakhir.
- Dependensi dasar API, Alembic, PyTorch CPU, dan torchvision sudah dipasang pada lingkungan pengerjaan.
- `flutter analyze`: **No issues found**. `flutter test`: **2 passed**, mencakup formulir registrasi dan sesi API yang kedaluwarsa.
- Workflow Checks untuk commit model `fcd5f44`: **success** di GitHub Actions, termasuk pemeriksaan migrasi PostgreSQL dan model.

Sebagian pengujian API memakai SQLite sementara dan prediksi pengganti; satu pengujian integrasi memuat checkpoint asli dan memverifikasi `/predict`, hasil laporan, serta hitungan kategori dashboard. Koneksi PostgreSQL dan Cloudinary masih perlu diperiksa terpisah.

## Masih dikerjakan / belum diverifikasi

- Dataset awal tidak menyediakan cukup gambar Plastic; sumber diganti ke RealWaste. Sebanyak 600 gambar telah diunduh. Detail sumber dan lisensi ada di `ml/DATASET.md`.
- Training selesai: akurasi test **96,67% (87/90)**; checkpoint terbaik dipilih dari validation set. Bobot model, metrik, confusion matrix, classification report, dan manifest split tersedia di `ml/artifacts/`.
- Migrasi database, PostgreSQL, Cloudinary, dan konfigurasi produksi belum diuji end to end.
- Android telah dianalisis dan diuji sebagai widget; build APK melalui CI dan pengujian perangkat masih perlu diverifikasi. Android SDK belum tersedia secara lokal.
- Pemeriksaan UI di browser, dokumentasi instalasi/API/ERD lengkap, dan video demo belum selesai.
- Repository GitHub: https://github.com/MhmmdIchsan/CamPah. Remote `origin` disiapkan untuk sinkronisasi progres; layanan Render belum dibuat.

## Tahap berikutnya

1. Jalankan ulang pengujian API dan uji migrasi; perbaiki temuan integrasi.
2. Selesaikan unduhan dan training dataset, kemudian verifikasi inferensi model.
3. Periksa web dan aplikasi Flutter; hasilkan APK jika toolchain tersedia.
4. Lengkapi dokumentasi dan paket pengumpulan, lalu deploy setelah repository serta akun layanan tersedia.

Catatan ini menjelaskan kondisi implementasi sebenarnya, bukan klaim bahwa seluruh persyaratan assessment telah selesai.
