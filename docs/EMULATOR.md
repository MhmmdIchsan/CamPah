# Emulator Android CamPah

Komputer pengembangan memiliki dua perangkat virtual terpisah:

- `Android_Test`: Android 11 (API 30), data pengujian lama tetap disimpan. Tombol navigasi layar diaktifkan melalui `hw.mainKeys=no`.
- `CamPah_Android15`: Android 15 (API 35), image standar x86_64, profil Pixel 5, 720 × 1600 pada 320 dpi, dua core dan RAM 1536 MB. Image ini tidak menyertakan Play Store atau Google Play Services.

Jalankan emulator baru melalui PowerShell:

```powershell
& 'D:\Android\Sdk\emulator\emulator.exe' -avd CamPah_Android15 -memory 1536 -cores 2 -gpu swiftshader_indirect -no-audio -no-boot-anim -no-metrics
```

Gunakan satu emulator pada satu waktu jika RAM komputer sedang terbatas. Start pertama dan perenderan software dapat lebih lambat; untuk emulator yang lebih berat, sesuaikan RAM setelah melihat ketersediaan memori komputer. Pengaturan `hw.mainKeys=no` menampilkan tombol navigasi sistem pada emulator ini.

## Koneksi API dan APK

Emulator mengakses API lokal komputer melalui `http://10.0.2.2:8000`; alamat ini hanya untuk emulator Android. Jalankan API di komputer terlebih dahulu. APK debug dari workflow Android dikonfigurasi menggunakan alamat tersebut, dan artifact `campah-apk` tersedia pada run GitHub Actions yang berhasil. Gunakan `adb devices` untuk melihat serial, lalu `adb -s <serial> install -r <path-ke-apk>` untuk memasang APK yang ditandatangani dengan kunci yang sama.

APK debug dari build yang berbeda dapat memakai kunci penandatanganan berbeda. Jika Android menolak pembaruan karena tanda tangan, jangan langsung uninstall jika aplikasi lama menyimpan draf/data penting; gunakan AVD baru atau amankan datanya terlebih dahulu.

Untuk simulasi lokasi, perintah contoh `adb -s <serial> emu geo fix 95.3215 5.5483` menggunakan urutan longitude lalu latitude. Berikan izin lokasi pada aplikasi. Pengujian kamera memakai kamera virtual emulator dan tidak menggantikan pengujian kamera pada perangkat fisik.
