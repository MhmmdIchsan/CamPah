# Identitas visual CamPah

CamPah menggabungkan kamera dan kepedulian terhadap sampah. Logo menggunakan bentuk kamera sederhana dengan daun sebagai simbol lingkungan. Bentuknya dibuat sebagai vektor agar tetap tajam pada berbagai ukuran layar.

- Logo utama: `web/src/assets/campah-mark.svg`.
- Favicon web: `web/public/campah-mark.svg`.
- Logo Flutter: `mobile/assets/brand/campah-mark.svg`.
- Ikon Android: `mobile/android/app/src/main/res/drawable/campah_icon.xml`, dibuat ulang oleh `scripts/configure_android.py`.

Palet utama memakai hijau gelap `#103D31`, hijau muda `#D3F47D`, dan latar lembut `#F5F6F0`. Tipografi memakai **Plus Jakarta Sans** yang dibundel untuk web dan Android agar tersedia tanpa unduhan font saat aplikasi dibuka. Berkas lisensi SIL Open Font License tersedia di masing-masing folder font.

Saat memperbarui logo, samakan ketiga berkas SVG dan definisi ikon vektor Android di `scripts/configure_android.py`, lalu jalankan script tersebut. Uji kembali tampilan pada layar kecil dan pastikan label navigasi serta tombol tetap dapat diakses.
