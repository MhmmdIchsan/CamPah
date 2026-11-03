# Rencana alur tindak lanjut laporan

## Tujuan

Memberi admin ruang untuk memeriksa dan mencatat tindakan atas laporan, serta memberi pelapor informasi yang jelas tentang perkembangannya. Alur awal, catatan publik, dan riwayat lintas aplikasi telah diimplementasikan; fitur lanjutan tetap di luar cakupan awal.

## Alur yang diusulkan

1. **Laporan masuk — Pending.** Admin membuka antrean dan memilih laporan untuk melihat foto, deskripsi, koordinat, waktu, pelapor, hasil AI, dan riwayat. Hasil AI diperlakukan sebagai bantuan, bukan keputusan otomatis.
2. **Mulai penanganan — In Progress.** Admin meninjau laporan dan mencatat tindakan awal yang dapat dilihat pelapor, misalnya bahwa laporan telah diteruskan ke petugas kebersihan.
3. **Selesaikan — Completed.** Admin mencatat hasil penanganan sebelum menyelesaikan laporan, misalnya bahwa sampah telah dibersihkan. Foto bukti penyelesaian dapat ditambahkan pada tahap berikutnya.
4. **Tolak — Rejected.** Admin wajib memberi alasan yang jelas dan dapat dilihat pelapor, misalnya foto tidak berkaitan atau lokasi tidak dapat ditentukan. Penolakan tidak menghapus laporan.
5. **Koreksi.** Jika terjadi salah status, admin menggunakan tindakan koreksi dengan alasan wajib. Catatan sebelumnya tetap tersimpan sehingga perubahan dapat ditelusuri.

## Antarmuka

- Web admin: antrean dengan pencarian dan filter; halaman atau panel detail laporan; tombol tindakan sesuai status; formulir catatan; serta linimasa status, waktu, admin, dan catatan.
- Web dan Android pelapor: detail laporan dengan status terkini dan linimasa catatan yang ditujukan kepada pelapor. Data diperbarui saat halaman dimuat ulang atau melalui tombol segarkan.
- Gunakan bahasa tindakan yang jelas seperti “Mulai tangani”, “Selesaikan”, dan “Tolak”, bukan hanya daftar pilihan status.

## Aturan dan data

- Status yang ada tetap dipakai agar sesuai kebutuhan awal. Usulan alur normal: Pending → In Progress → Completed, atau Pending/In Progress → Rejected. Koreksi status membutuhkan alasan dan harus dirancang eksplisit di API.
- Catatan bersifat terlihat oleh pelapor; jangan memasukkan informasi pribadi pihak ketiga. Jika catatan internal diperlukan, buat jenis dan kontrol akses terpisah pada fase berikutnya.
- Tabel `report_status_history` sudah menyimpan perubahan status dan admin, tetapi saat ini belum menyediakan catatan tindak lanjut atau linimasa di antarmuka. Tambahkan kolom/entitas yang diperlukan melalui migrasi; pertahankan data riwayat lama meski belum memiliki catatan.
- API memvalidasi hak admin, transisi, dan isi wajib pada server, serta menyimpan status dan riwayat dalam satu transaksi. Pelapor hanya dapat membaca riwayat laporannya sendiri. Hindari catatan ganda ketika status tidak berubah.
- Tidak menjanjikan adanya petugas lapangan atau integrasi pengiriman otomatis: admin mencatat tindakan yang benar-benar dilakukan.

## Urutan pengerjaan dan penerimaan

1. Finalisasi aturan transisi dan format catatan, lalu buat migrasi serta endpoint detail/riwayat dan tindakan admin. Uji otorisasi, alasan wajib, koreksi, data lama, dan konsistensi transaksi.
2. Buat antrean dan detail admin di web, termasuk formulir tindakan dan linimasa. Uji desktop dan layar kecil.
3. Tampilkan linimasa pada web dan Android untuk pemilik laporan. Uji bahwa pengguna lain tidak dapat melihatnya dan pembaruan muncul setelah dimuat ulang.
4. Uji alur lengkap: laporan dibuat → ditinjau → ditangani → diselesaikan; laporan lain ditolak dengan alasan; koreksi menyimpan jejak audit.

Di luar tahap awal: penugasan petugas tertentu, notifikasi otomatis, peta interaktif, dan foto bukti penyelesaian. Fitur-fitur tersebut memerlukan kebutuhan dan rancangan tersendiri.
