# PRD CamPah

## Tujuan dan pengguna

CamPah adalah sistem laporan sampah untuk technical assessment Fullstack Developer Bilcode. User mengirim foto, koordinat GPS, dan deskripsi, kemudian memantau penanganan. Admin mengelola laporan, status, dan akun melalui web. Klasifikasi AI memberikan satu kategori Organic Waste, Plastic Waste, atau Paper Waste untuk foto laporan.

## Kebutuhan dan penerimaan

| ID | Kebutuhan | Penerimaan |
| --- | --- | --- |
| AUTH-01 | Registrasi dan login | Registrasi selalu menghasilkan User; login memberikan JWT; akun nonaktif ditolak |
| AUTH-02 | Role dan kepemilikan | User tidak dapat membaca/mengubah laporan pengguna lain atau memakai endpoint Admin |
| WEB-01 | Dashboard responsif | Jumlah total, status, dan kategori sesuai laporan aktif; User hanya melihat datanya |
| WEB-02 | CRUD laporan | Foto, deskripsi, koordinat, waktu, pembuat, hasil AI, dan status tersimpan; penghapusan bersifat soft delete |
| WEB-03 | Filter dan pencarian | Pencarian deskripsi/kategori, filter status, dan pagination dapat digabung |
| WEB-04 | Status | Admin dapat memilih Pending, In Progress, Completed, Rejected; perubahan tercatat pada status history |
| WEB-05 | Pengguna | Admin dapat menambah akun, mengubah nama/role, dan mengaktifkan atau menonaktifkan akun |
| MOB-01 | Android | Registrasi/login, dashboard, kamera/galeri, GPS, kirim laporan, hasil AI, dan riwayat tersedia |
| MOB-02 | Integrasi | Laporan Android tersimpan melalui API yang sama dan menampilkan status terbaru setelah refresh |
| ML-01 | Klasifikasi | Minimal tiga kelas dan 150 gambar valid; training/testing memakai Python dan PyTorch |
| ML-02 | Evaluasi | Accuracy, confusion matrix, classification report, model, kode, dan sumber dataset tersedia; target test accuracy minimal 80% |
| OPS-01 | Pengumpulan | Repository, demo web, APK/link mobile, API docs, ERD, dataset, model, hasil evaluasi, README, dan video maksimal 10 menit |

## Perilaku dan batas MVP

Laporan baru berstatus Pending. User dapat mengubah deskripsi/koordinat atau menghapus laporannya selama Pending. Admin dapat mengelola seluruh laporan. Status yang berubah dicatat bersama Admin pelaksana. Dashboard tidak menghitung laporan yang dihapus. Admin tidak dapat menghapus akses Admin miliknya sendiri melalui pengaturan role/status akun.

Foto wajib valid JPEG/PNG/WEBP, maksimal 8 MB dan 20 juta piksel. Deskripsi berisi 10–2000 karakter; koordinat berada dalam rentang latitude/longitude yang sah. Prediksi tidak menghalangi penyimpanan laporan ketika model gagal; aplikasi menampilkan bahwa kategori belum tersedia. Tidak ada push notification, mode offline, peta interaktif, atau deteksi bounding box dalam MVP.

## Implementasi yang dipilih

React/Vite untuk web, Flutter untuk Android, FastAPI untuk bisnis dan inferensi, PostgreSQL untuk produksi, serta Cloudinary untuk foto. Training memakai MobileNetV2 dan RealWaste. Dataset awal Mendeley diganti setelah pemeriksaan menunjukkan hanya dua file Plastic; alasan, atribusi, pemetaan kelas, dan lisensi dicatat di `ml/DATASET.md`.

## Jadwal dan penyelesaian

Email diterima 1 November 2026. Target internal konservatif adalah 5 November 2026 pukul 23.59 WIB; jam resmi pengumpulan perlu dicocokkan dengan email asli. Urutan implementasi: data/API, ML, web/Android, lalu pengujian, deployment, dokumentasi, dan video. Status pengerjaan serta hasil pengujian aktual dicatat di [PROGRESS.md](PROGRESS.md).
