# Skenario video demo CamPah

Target durasi 8–9 menit, maksimal 10 menit sesuai instruksi assessment. Kandidat menjelaskan implementasi yang benar-benar dijalankan. Siapkan API, web, emulator/perangkat Android, contoh foto sampah, serta akun User dan Admin sebelum merekam. Gunakan akun demo dan jangan menampilkan environment atau token asli.

| Waktu | Tampilan dan penjelasan |
| --- | --- |
| 00:00–00:40 | Perkenalkan CamPah: pelaporan sampah dengan foto/GPS, tindak lanjut Admin, dan klasifikasi AI. Jelaskan komponen React, Flutter, FastAPI, PostgreSQL, Cloudinary, dan model. |
| 00:40–02:10 | Android: registrasi/login, pilih foto kamera/galeri, ambil GPS, isi deskripsi, kirim. Perlihatkan kategori dan confidence AI serta status Pending. |
| 02:10–03:20 | Web Admin: dashboard, cari laporan Android, filter Pending, ubah ke In Progress/Completed. Tunjukkan angka dashboard yang berubah. |
| 03:20–04:00 | Android User: refresh riwayat dan perlihatkan status baru. Jelaskan bahwa kedua aplikasi menggunakan API yang sama. |
| 04:00–05:00 | Web User: buat/ubah/hapus laporan Pending. Tunjukkan bahwa laporan Completed tidak bisa diubah pengguna. Web Admin: tambah atau nonaktifkan akun demo. |
| 05:00–06:20 | ML: sumber RealWaste dan pemetaan tiga kelas, 600 gambar, split 420/90/90, training MobileNetV2, checkpoint berdasar validation set, akurasi test 87/90, confusion matrix, dan classification report. Jelaskan keterbatasan pada foto campuran atau kategori lain. |
| 06:20–07:20 | Swagger UI dan ERD: JSON login, multipart foto, JWT/role, relasi pengguna-laporan-riwayat status. Jelaskan bahwa kegagalan AI tetap menyimpan laporan. |
| 07:20–08:30 | Tunjukkan README, hasil pengujian/CI, repository dan link demo/APK. Jelaskan cara instalasi singkat serta bagian yang belum tersedia bila ada. |

## Pengumpulan

Sertakan URL repository, web dan API docs yang aktif, APK atau link distribusi, dokumentasi ERD, sumber dataset dan arsip hasil olahan, kode/bobot model, hasil evaluasi, README, serta video. Arsip dataset/model/checksum dibuat dengan `python scripts/package_submission.py`. Video yang direkam harus dapat diputar oleh reviewer tanpa meminta akses tambahan yang belum disediakan.

Jangan mencantumkan URL demo yang belum dipasang atau mengklaim bahwa widget test menggantikan pengujian kamera/GPS pada perangkat nyata.
