# CamPah

**CamPah** adalah aplikasi laporan sampah dengan web React, Android Flutter, FastAPI, PostgreSQL, dan klasifikasi gambar menggunakan PyTorch MobileNetV2.

Repository: https://github.com/MhmmdIchsan/CamPah

Implementasi masih berjalan. Lihat [catatan progres](docs/PROGRESS.md) untuk hasil verifikasi dan pekerjaan yang belum selesai.

## Struktur repository

| Direktori / berkas | Isi |
| --- | --- |
| `api/` | Autentikasi, otorisasi, laporan, dashboard, pengguna, prediksi, migrasi, dan pengujian API |
| `web/` | Dashboard dan pengelolaan laporan berbasis React/Vite |
| `mobile/` | Source Flutter; platform Android dan APK belum dibuat |
| `ml/` | Pengunduh dataset, training, inferensi, dan atribusi dataset |
| `render.yaml` | Konfigurasi awal deployment Render, belum dideploy |
| `compose.yaml` | PostgreSQL untuk pengembangan lokal |
| `instruction.txt` | Persyaratan technical assessment |

## Pemeriksaan pengembangan

Jalankan dari root repository setelah dependensi terpasang:

```sh
python -m pytest api/tests -q
```

Untuk web:

```sh
cd web
npm ci
npm run build
```

Contoh konfigurasi tersedia di `api/.env.example` dan `web/.env.example`. Berkas `.env`, dataset unduhan, cache, unggahan lokal, dan SDK lokal tidak dimasukkan ke Git. Panduan instalasi lengkap serta hasil ML akan dilengkapi setelah integrasi selesai.

## Pencatatan progres

Setiap tahap yang telah diverifikasi dicatat melalui commit dan pembaruan `docs/PROGRESS.md`. Gunakan `git log --oneline` untuk melihat riwayat dan `git status --short` untuk melihat perubahan yang belum di-commit. Jangan memasukkan kredensial ke commit.
