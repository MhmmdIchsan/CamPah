# CamPah Android

Source Flutter dan platform Android tersedia dalam repository. Gunakan Flutter stable, JDK 17, serta Android SDK untuk build lokal:

```sh
cd mobile
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=API_URL=http://10.0.2.2:8000
flutter build apk --debug --dart-define=API_URL=http://10.0.2.2:8000
flutter build apk --release --dart-define=API_URL=https://YOUR-ACTUAL-API.onrender.com
```

Izin INTERNET, ACCESS_FINE_LOCATION, dan ACCESS_COARSE_LOCATION sudah dikonfigurasi. Foto dapat diambil dari kamera atau galeri. Akses HTTP tersedia pada build debug untuk pengembangan; gunakan HTTPS untuk build release. APK keluar di `build/app/outputs/flutter-apk/`. Build release saat ini memakai signing debug untuk assessment, sehingga belum ditujukan untuk publikasi Play Store.

Aplikasi menyediakan registrasi/login, dashboard, kamera/galeri, GPS, pengiriman laporan dengan kategori dan confidence AI, serta riwayat dengan pagination. Token yang ditolak API mengembalikan pengguna ke login. Kesalahan jaringan ditampilkan agar dapat dicoba kembali.

`10.0.2.2` adalah alamat komputer host dari emulator Android. Untuk perangkat fisik, tentukan URL API yang dapat dijangkau perangkat tersebut. Lokasi harus diaktifkan dan izinnya diberikan; emulator juga perlu diberi koordinat melalui pengaturan lokasinya.

Workflow **Android APK** di GitHub Actions menjalankan analisis, pengujian, dan build. Tanpa konfigurasi URL publik, workflow menghasilkan APK debug untuk emulator. Setelah API publik tersedia, isi repository variable `CAMPAH_API_URL` atau jalankan workflow secara manual dengan input `api_url` HTTPS untuk menghasilkan APK release. Unduh hasilnya dari artifact `campah-apk` pada run yang berhasil.

Jika platform Android perlu dibuat ulang, jalankan `flutter create --platforms=android --org=id.campah --project-name=campah_mobile --no-pub mobile` dari root, lalu `python scripts/configure_android.py` untuk menerapkan label, ikon, dan permission CamPah kembali.
