# Naskah video demo CamPah

**Target durasi:** 8–9 menit; batas assessment 10 menit. Naskah ini adalah panduan berbicara. Gunakan kata-katamu sendiri dan sesuaikan dengan hasil yang muncul di layar. Ganti `[nama]`, `[email demo]`, dan detail laporan dengan data yang benar-benar kamu gunakan.

## Persiapan sebelum merekam

- Buka [web CamPah](https://campah-web.onrender.com), [API docs](https://campah-api.onrender.com/docs), [repository GitHub](https://github.com/MhmmdIchsan/CamPah), [arsitektur dan ERD](ARCHITECTURE.md), [model card](../ml/MODEL_CARD.md), [confusion matrix](../ml/artifacts/confusion_matrix.png), dan [classification report](../ml/artifacts/classification_report.txt) dalam tab terpisah.
- Siapkan aplikasi Android terbaru, internet, izin kamera/galeri dan lokasi, serta satu foto sampah yang boleh digunakan untuk demo. Foto botol plastik memudahkan contoh; sebutkan hasil AI sesuai yang benar-benar tampil.
- Siapkan akun demo User, Admin, dan Petugas yang masih aktif. Admin perlu menambahkan akun Petugas dari halaman **Pengguna** sebelum perekaman, atau tunjukkan langkah pembuatannya secara singkat. Untuk berpindah akun, gunakan browser/perangkat terpisah atau potong bagian login saat menyunting.
- Siapkan satu laporan baru untuk alur User → Admin → Petugas. Siapkan laporan Pending kedua jika ingin menunjukkan edit/hapus tanpa mengganggu laporan utama.
- Buka web dan API beberapa saat sebelum merekam agar layanan siap. Periksa bahwa foto dan hasil AI tampil. Gunakan lokasi dan data demo yang nyaman diperlihatkan.
- Sembunyikan password, token, file `.env`, data pribadi, dan notifikasi perangkat. Rekam layar ponsel dengan screen recorder atau cerminkan layar ke komputer. Jika perlu, rekam beberapa bagian lalu gabungkan selama urutannya tetap jelas.

## 00:00–00:35 — Pembukaan dan tujuan

**Tunjukkan:** landing page CamPah, lalu sekilas dashboard.

**Ucapkan:**

> Halo, perkenalkan saya `[nama]`. Pada video ini saya akan mendemonstrasikan CamPah, aplikasi pelaporan sampah yang saya buat untuk technical assessment Fullstack Developer.
>
> Pengguna dapat mengirim foto, deskripsi, dan lokasi sampah melalui Android atau web. Admin mengelola laporan dan menugaskannya kepada petugas. Aplikasi juga menggunakan model machine learning untuk mengidentifikasi kategori sampah pada foto.

## 00:35–02:05 — Android: buat laporan

**Tunjukkan dan lakukan:**

1. Buka aplikasi Android. Tunjukkan splash screen, lalu login sebagai User. Tunjukkan halaman registrasi bila ingin memperlihatkan opsinya; kembali login agar waktu cukup.
2. Tunjukkan ringkasan dashboard, lalu tekan **Lapor**.
3. Pilih foto dari kamera atau galeri, tekan **Ambil lokasi GPS**, dan isi deskripsi. Contoh: `Terdapat botol plastik berserakan di dekat tempat sampah tepi jalan.`
4. Tekan **Kirim laporan**. Tunjukkan hasil kategori dan confidence jika tersedia, lalu buka riwayat dan catat nomor laporan serta status **Pending**.

**Ucapkan:**

> Saya masuk sebagai pengguna. Di dashboard, saya bisa melihat ringkasan laporan saya. Sekarang saya membuat laporan baru dengan foto, lokasi GPS, dan deskripsi kondisi di lokasi.
>
> Setelah dikirim, aplikasi menerima hasil klasifikasi dari API dan menampilkannya bersama confidence jika prediksi tersedia. Laporan baru berstatus Pending. Di riwayat, pengguna dapat membuka detail dan memantau perkembangan laporan ini.

**Jika prediksi tidak muncul:** katakan bahwa laporan tetap tersimpan dan hasil AI belum tersedia, lalu tunjukkan hasil AI dari laporan yang sudah tersedia atau endpoint prediksi. Jangan menyebut kategori yang berbeda dari tampilan.

## 02:05–03:20 — Web Admin: cari dan tugaskan laporan

**Tunjukkan dan lakukan:**

1. Buka web sebagai Admin. Tunjukkan statistik dan daftar laporan.
2. Buka halaman **Laporan**, cari deskripsi atau nomor laporan yang dibuat dari Android, dan pilih filter Pending.
3. Buka detail. Tunjukkan foto, deskripsi, koordinat, status, dan hasil AI jika ada.
4. Pada bagian penugasan, pilih akun Petugas yang sudah disiapkan, lalu tekan **Simpan penugasan**.
5. Tunjukkan halaman **Pengguna** dan role Petugas bila waktunya cukup; kembali ke laporan.

**Ucapkan:**

> Di web Admin, saya bisa melihat statistik semua laporan, mencari laporan tertentu, dan memfilter berdasarkan status. Ini adalah laporan yang baru saya kirim dari Android.
>
> Pada detail laporan, Admin dapat memeriksa foto dan koordinat, lalu memilih petugas dari akun Petugas yang aktif. Saya tugaskan laporan ini ke `[nama petugas]`. Admin juga dapat mengelola akun melalui halaman Pengguna.

## 03:20–04:30 — Petugas: tangani tugas

**Tunjukkan dan lakukan:**

1. Login sebagai Petugas di Android terbaru atau web. Tunjukkan dashboard dan daftar tugas; buka laporan yang baru ditugaskan.
2. Tunjukkan notifikasi penugasan bila terlihat. Di web, kamu juga dapat menunjukkan tombol **Tandai semua sudah dibaca**.
3. Tekan **Mulai tangani**, isi catatan `Petugas menuju lokasi`, lalu simpan.
4. Ubah status ke **Completed** melalui tombol **Selesaikan** atau **Selesaikan laporan**, dan isi catatan `Sampah telah dibersihkan`.

**Ucapkan:**

> Saya sekarang masuk sebagai Petugas. Dashboard dan daftar tugas menampilkan laporan yang ditugaskan kepada akun ini. Petugas tidak mengelola akun atau penugasan pengguna lain.
>
> Saya mulai menangani laporan dan mengisi catatan. Setelah penanganan selesai, saya ubah status menjadi Completed dan menyimpan catatan penyelesaian. Setiap perubahan status tercatat dalam riwayat.

**Catatan:** gunakan dua perubahan status tersebut hanya bila sesuai kondisi demo. Jika ingin menunjukkan penolakan, siapkan laporan terpisah dan pilih **Tolak**; jangan mengubah laporan yang sama setelah Completed tanpa menggunakan fungsi koreksi Admin.

## 04:30–05:05 — User: lihat pembaruan

**Tunjukkan dan lakukan:** kembali ke akun User di Android, buka atau muat ulang riwayat, lalu buka detail laporan. Tunjukkan status **Completed**, riwayat dan notifikasi yang tersedia. Jika menggunakan web User, perlihatkan tombol notifikasi.

**Ucapkan:**

> Saya kembali ke akun pelapor dan memuat ulang riwayat. Status laporan sekarang Completed, dan catatan penanganan dapat dilihat pada detail. Web dan Android memakai API serta database yang sama, sehingga perubahan dari Petugas dapat dibaca kembali oleh pelapor.

## 05:05–05:45 — Web: CRUD dan tampilan responsif

**Tunjukkan dan lakukan:**

1. Di web User, tunjukkan halaman laporan. Buka laporan **Pending** lain, ubah deskripsinya, dan simpan. Bila ingin memperlihatkan hapus, gunakan laporan Pending demo yang terpisah.
2. Tunjukkan bahwa kontrol edit/hapus untuk laporan Completed tidak ditampilkan bagi User. Sebagai Admin, tunjukkan bahwa laporan dapat dikelola dan status dapat dikoreksi.
3. Kecilkan lebar browser atau gunakan tampilan perangkat ponsel untuk memperlihatkan layout responsif.

**Ucapkan:**

> Untuk laporan yang masih Pending, pengguna dapat mengubah atau menghapus laporan miliknya. Penghapusan memakai soft delete, yaitu penanda hapus pada database. Admin memiliki cakupan pengelolaan seluruh laporan. Tampilan web juga menyesuaikan ukuran layar.

## 05:45–07:15 — Machine learning dan evaluasi

**Tunjukkan:** [model card](../ml/MODEL_CARD.md), [DATASET.md](../ml/DATASET.md), [confusion matrix](../ml/artifacts/confusion_matrix.png), dan [classification report](../ml/artifacts/classification_report.txt). Tunjuk angka yang disebut saat berbicara.

**Ucapkan:**

> Model yang saya gunakan adalah MobileNetV2 berbasis PyTorch dengan transfer learning. Model mengklasifikasikan gambar ke tiga kategori: Organic Waste, Plastic Waste, dan Paper Waste.
>
> Saya memakai 600 gambar pilihan dari dataset RealWaste, masing-masing 200 gambar per kategori. Saya membagi data menjadi 420 gambar training, 90 validation, dan 90 test secara stratified. Augmentasi diterapkan pada data training. Saya memilih checkpoint terbaik berdasarkan hasil validation, kemudian mengevaluasinya pada test set yang terpisah.
>
> Pada test set ini, model mengklasifikasikan 87 dari 90 gambar dengan benar, sehingga akurasinya 96,67 persen. Confusion matrix menunjukkan jumlah prediksi per kelas, sementara classification report memuat precision, recall, dan F1-score.
>
> Hasil tersebut berlaku untuk split RealWaste yang digunakan. Foto lapangan dengan pencahayaan berbeda, sampah campuran, atau objek di luar tiga kategori masih dapat menghasilkan prediksi yang keliru. Confidence menunjukkan skor model dan bukan jaminan hasilnya benar.

**Jika ditanya alasan dataset:** sumber dan atribusi dicatat dalam [DATASET.md](../ml/DATASET.md), termasuk perbedaan keterangan lisensi pada sumber. Dataset awal pada PRD diganti karena sampel Plastic yang tersedia saat diperiksa tidak mencukupi kebutuhan training.

## 07:15–08:25 — Arsitektur, ERD, dan API

**Tunjukkan dan lakukan:**

1. Buka [diagram arsitektur dan ERD](ARCHITECTURE.md). Ikuti arah panah dari Android/web menuju FastAPI, PostgreSQL, Cloudinary, dan model.
2. Tunjukkan tabel `users`, `reports`, `report_status_history`, dan `notifications`. Arahkan ke `reports.user_id` dan `reports.assigned_user_id`.
3. Buka [API docs](https://campah-api.onrender.com/docs). Tunjukkan deskripsi `POST /auth/login`, `POST /reports`, `PATCH /reports/{report_id}/assignment`, dan `POST /predict`. Jelaskan bentuk input tanpa menampilkan token atau password.

**Ucapkan:**

> Web dibuat dengan React dan Android dengan Flutter. Keduanya mengakses FastAPI melalui HTTPS. API memakai JWT untuk autentikasi dan memeriksa hak akses sesuai role pada setiap permintaan.
>
> PostgreSQL menyimpan akun, laporan, riwayat status, dan notifikasi. Foto disimpan di Cloudinary; URL-nya disimpan bersama data laporan. Model PyTorch berjalan di server API. Jika inferensi gagal setelah laporan tersimpan, laporan tetap dapat digunakan dan hasil AI akan kosong.
>
> Di ERD, satu User dapat membuat banyak laporan. Laporan dapat memiliki satu Petugas yang ditugaskan. Riwayat mencatat perubahan status dan akun pelaksananya, sedangkan notifikasi terhubung ke penerima dan laporan.
>
> Dokumentasi FastAPI menampilkan endpoint dan skema request. Pembuatan laporan dan prediksi menerima foto melalui multipart form data.

## 08:25–09:05 — Repository dan penutup

**Tunjukkan:** repository, folder `web`, `mobile`, `api`, `ml`, serta README atau halaman hasil GitHub Actions. Tampilkan tautan web/API dan tautan APK setelah disiapkan.

**Ucapkan:**

> Source code web, Android, API, dan machine learning tersedia di repository. Di sana juga ada panduan instalasi, ERD, sumber dataset, bobot model, dan hasil evaluasi. Pengujian mencakup API, migrasi, browser, dan Flutter; hasil workflow dapat dilihat di GitHub Actions.
>
> Tautan demo web, dokumentasi API, APK, dan repository saya sertakan dalam pengumpulan. Terima kasih atas waktu dan perhatiannya.

## Daftar periksa sebelum mengirim

- [ ] Durasi akhir tidak lebih dari 10 menit dan suara terdengar jelas.
- [ ] Aksi pada layar cocok dengan yang diucapkan; hasil AI dan angka tidak direkayasa.
- [ ] Password, JWT, data sensitif, dan notifikasi pribadi tidak terlihat.
- [ ] Video bisa diputar oleh penilai melalui tautan yang disertakan.
- [ ] Tautan repository, web, API docs, APK, dataset dan atribusi, ERD, hasil evaluasi, serta video dapat dibuka.
- [ ] Latih penjelasan arsitektur dan model dengan bahasamu sendiri untuk sesi interview.
