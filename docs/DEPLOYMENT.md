# Deployment CamPah

Repository: https://github.com/MhmmdIchsan/CamPah. Konfigurasi awal ada di `render.yaml`; service web/API dan database memakai nama CamPah. Akun Render dan Cloudinary perlu dibuat oleh pemilik proyek sebelum demo publik dapat dipasang.

## Persiapan

1. Buat akun Cloudinary. Simpan nilai `CLOUDINARY_URL` langsung pada environment Render; jangan menambahkannya ke Git atau percakapan.
2. Hubungkan GitHub repository ke Render dan buat Blueprint dari `render.yaml`.
3. Isi `ADMIN_EMAIL` dan `ADMIN_PASSWORD` untuk akun Admin awal. Gunakan password milik lingkungan demo yang baru.
4. `DATABASE_URL` berasal dari database Blueprint dan `JWT_SECRET` dibuat otomatis. Model sudah ada di repository.

## URL dan environment

| Service | Environment | Nilai |
| --- | --- | --- |
| API | `APP_ENV` | `production` |
| API | `DATABASE_URL` | Otomatis dari Render PostgreSQL |
| API | `CLOUDINARY_URL` | Dari Cloudinary, disimpan sebagai environment |
| API | `JWT_SECRET` | Nilai acak yang dibuat Render |
| API | `ADMIN_EMAIL`, `ADMIN_PASSWORD` | Akun awal yang dipilih pemilik |
| API | `CORS_ORIGINS` | URL web aktual, tanpa slash akhir |
| Web | `VITE_API_URL` | URL API aktual, tanpa slash akhir |

Render menentukan URL aktual setiap service; salin URL tersebut dari dashboard. Bila nama service diberi suffix karena sudah dipakai, sesuaikan `VITE_API_URL` dan `CORS_ORIGINS`, lalu deploy ulang kedua service. Environment Vite dibaca saat build sehingga perubahan URL API memerlukan build web ulang.

Build API memasang PyTorch CPU dan dependensi FastAPI. Start command menjalankan migrasi Alembic, lalu Uvicorn. Gunakan satu worker untuk demo agar model tidak dimuat berulang kali. Foto wajib memakai Cloudinary pada produksi, karena file lokal Render tidak bertahan pada semua restart/deploy. Lihat [dokumentasi penyimpanan Render](https://render.com/docs/disks).

## Verifikasi demo

- `/health` mengembalikan 200; `/docs` dapat dibuka.
- Registrasi melalui web, lalu buat laporan dengan foto dan koordinat.
- Login Admin, cari laporan, dan ubah statusnya.
- Login kembali sebagai User dan periksa perubahan status.
- Panggil `/predict` dengan `ml/examples/plastic.jpg` dan periksa kategori/confidence.
- Pastikan foto tetap dapat ditampilkan setelah API di-redeploy.

Pada [layanan gratis Render](https://render.com/docs/free), API dapat berhenti sementara saat tidak digunakan dan memerlukan waktu untuk aktif kembali; database gratis juga memiliki masa berlaku. Periksa masa aktifnya dan buka demo sebelum sesi review. README harus mencantumkan URL yang benar setelah deployment berhasil.

## APK untuk API publik

Setelah URL API HTTPS aktif, tambahkan repository variable GitHub `CAMPAH_API_URL`, atau buka workflow **Android APK** dan jalankan secara manual dengan input `api_url`. Workflow menjalankan analisis, pengujian, dan build dengan URL tersebut. Artifact `campah-apk` tersedia pada run yang berhasil.

Tanpa URL publik, workflow menghasilkan APK debug untuk emulator dengan `http://10.0.2.2:8000`. Build release assessment menggunakan debug signing; signing untuk distribusi Play Store perlu dikonfigurasi terpisah. Setelah APK diunduh lokal, jalankan kembali `python scripts/package_submission.py` untuk mengumpulkan artefak dan checksum.

## Pencatatan perubahan

Setiap fitur/perbaikan dicatat dengan Conventional Commit, lalu di-push ke `main`. Workflow Checks memeriksa API, migrasi PostgreSQL, model, build web, dan alur browser. Workflow Android APK memeriksa aplikasi dan menghasilkan APK. Jika deployment mengalami regresi, pilih commit yang sudah lulus pemeriksaan dari riwayat GitHub/Render dan deploy commit tersebut.
