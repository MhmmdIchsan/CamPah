# Progres implementasi

Tanggal pencatatan awal: **2 November 2026 (Asia/Jakarta)**.

Nama aplikasi ditetapkan sebagai **CamPah**.

## Sudah dibuat

- Source API untuk registrasi/login JWT, akses Admin/User, CRUD laporan dengan soft delete, pencarian/filter/pagination, status laporan, dashboard, manajemen pengguna, dan endpoint prediksi.
- Source web untuk autentikasi, dashboard, formulir dan pengelolaan laporan, serta manajemen pengguna.
- Source Flutter untuk autentikasi, dashboard, kamera/galeri, GPS, pembuatan laporan, dan riwayat.
- Pengunduh dataset Mendeley dan pipeline training/evaluasi MobileNetV2.
- Migrasi awal Alembic, konfigurasi PostgreSQL lokal, dan blueprint Render.

## Verifikasi yang telah dilakukan

- `python -m pytest api/tests -q`: **4 passed** pada pengujian sebelum perubahan migrasi dan penguatan konfigurasi produksi terakhir. Pengujian perlu dijalankan lagi setelah perubahan tersebut.
- `npm run build` di `web/`: **berhasil**.
- Pemeriksaan sintaks Python pada API, prediktor, dan training: **berhasil** sebelum perubahan terakhir.
- Dependensi dasar API, Alembic, PyTorch CPU, dan torchvision sudah dipasang pada lingkungan pengerjaan.

Pengujian API menggunakan SQLite sementara dan prediksi pengganti. Hasil tersebut belum membuktikan koneksi PostgreSQL, Cloudinary, atau inferensi model terlatih.

## Masih dikerjakan / belum diverifikasi

- Unduhan dataset dan penyiapan Flutter SDK telah dimulai; kelengkapannya belum diperiksa setelah interupsi.
- Training model, evaluasi test set, bobot model, confusion matrix, dan classification report belum tersedia.
- Migrasi database, PostgreSQL, Cloudinary, dan konfigurasi produksi belum diuji end to end.
- Android belum dianalisis/dibuild; APK dan pengujian perangkat belum tersedia.
- Pemeriksaan UI di browser, dokumentasi instalasi/API/ERD lengkap, dan video demo belum selesai.
- Repository GitHub: https://github.com/MhmmdIchsan/CamPah. Remote `origin` disiapkan untuk sinkronisasi progres; layanan Render belum dibuat.

## Tahap berikutnya

1. Jalankan ulang pengujian API dan uji migrasi; perbaiki temuan integrasi.
2. Selesaikan unduhan dan training dataset, kemudian verifikasi inferensi model.
3. Periksa web dan aplikasi Flutter; hasilkan APK jika toolchain tersedia.
4. Lengkapi dokumentasi dan paket pengumpulan, lalu deploy setelah repository serta akun layanan tersedia.

Catatan ini menjelaskan kondisi implementasi sebenarnya, bukan klaim bahwa seluruh persyaratan assessment telah selesai.
