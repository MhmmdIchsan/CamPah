# CamPah

[![Checks](https://github.com/MhmmdIchsan/CamPah/actions/workflows/checks.yml/badge.svg)](https://github.com/MhmmdIchsan/CamPah/actions/workflows/checks.yml)
[![Android APK](https://github.com/MhmmdIchsan/CamPah/actions/workflows/android.yml/badge.svg)](https://github.com/MhmmdIchsan/CamPah/actions/workflows/android.yml)

CamPah membantu pengguna melaporkan sampah dengan foto dan lokasi, memantau penanganan, serta mengenali kategori sampah melalui AI. Admin mengelola laporan, status, dan pengguna melalui web.

**Stack:** React/Vite, Flutter Android, FastAPI, PostgreSQL, Cloudinary, dan PyTorch MobileNetV2. Akurasi model pada test set RealWaste yang disiapkan: **96,67% (87/90 gambar)**. Lihat [model card](ml/MODEL_CARD.md) untuk metode dan batas hasil tersebut.

## Dokumentasi

- [PRD dan kriteria penerimaan](docs/PRD.md)
- [Arsitektur dan ERD](docs/ARCHITECTURE.md)
- [Identitas visual dan logo](docs/BRAND.md)
- [Dokumentasi API](docs/API.md) dan [kontrak OpenAPI](docs/openapi.json)
- [Panduan deployment](docs/DEPLOYMENT.md)
- [Android: instalasi, pengujian, dan APK](mobile/README.md)
- [Dataset dan atribusi](ml/DATASET.md), [hasil evaluasi](ml/artifacts/metrics.json), [confusion matrix](ml/artifacts/confusion_matrix.png)
- [Skenario video demo](docs/DEMO_SCRIPT.md) dan [progres implementasi](docs/PROGRESS.md)

## Menjalankan API dan database

Prasyarat: Python 3.11, Node.js 22.18+, dan PostgreSQL 16. PostgreSQL dapat dijalankan melalui Docker Compose jika Docker tersedia. Perintah berikut memakai PowerShell dari root repository; di Linux/macOS gunakan `source .venv/bin/activate` untuk aktivasi virtual environment.

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu
python -m pip install -r api/requirements.txt
Copy-Item api/.env.example api/.env
# Sesuaikan api/.env, termasuk JWT_SECRET, ADMIN_EMAIL, dan ADMIN_PASSWORD.
docker compose up -d db
python api/start.py
```

`api/.env.example` sudah memakai database lokal dari `compose.yaml`. Jika PostgreSQL dijalankan tanpa Docker, buat database `smart_waste` dan sesuaikan `DATABASE_URL`. `api/start.py` memuat `.env`, menerapkan migrasi Alembic, membuat Admin awal bila belum ada, lalu menjalankan API pada http://localhost:8000. Dokumentasi interaktif tersedia di http://localhost:8000/docs.

Untuk mencoba antarmuka tanpa PostgreSQL, gunakan `DATABASE_URL=sqlite:///./smart_waste.db` pada konfigurasi pengembangan. SQLite digunakan untuk pengujian lokal; konfigurasi deployment memakai PostgreSQL. Jangan memakai database yang sudah dibuat melalui `create_all` untuk pengujian migrasi baru tanpa memeriksa versi skemanya.

Tanpa Cloudinary, foto pengembangan disimpan pada `api/uploads/`. Lingkungan produksi mewajibkan Cloudinary agar foto tetap tersedia setelah restart. Model terlatih sudah disertakan di `ml/artifacts/best_model.pt`; API tidak perlu training saat startup.

## Menjalankan web

Buka terminal lain dari root:

```powershell
cd web
npm ci
Copy-Item .env.example .env
npm run dev
```

Buka http://localhost:5173. Registrasi selalu membuat role User. Login Admin memakai akun yang dibuat dari konfigurasi API. User hanya mengelola laporannya sendiri selama Pending; Admin dapat mengelola seluruh laporan dan status. Token berlaku 24 jam dan akun nonaktif ditolak API.

## Android

Source dan platform Android ada di `mobile/`. Gunakan Flutter stable dan Android SDK untuk menjalankan aplikasi:

```powershell
cd mobile
flutter pub get
flutter run --dart-define=API_URL=http://10.0.2.2:8000
```

`10.0.2.2` menunjuk ke komputer host dari emulator Android. Perangkat fisik perlu URL API yang dapat dijangkaunya. Workflow **Android APK** menghasilkan artifact `campah-apk`; tanpa URL publik, build debug ditujukan untuk emulator. Lihat [panduan Android](mobile/README.md) untuk build dengan API HTTPS dan pengujian izin GPS/kamera.

## Training ulang

```powershell
python -m pip install -r ml/requirements.txt
python ml/download_dataset.py
python ml/train.py
```

Script mengunduh 600 gambar dari revisi RealWaste yang tercatat, memeriksa checksum, lalu membagi data menjadi 420 train, 90 validation, dan 90 test. Checkpoint dipilih berdasarkan validation set. Test set dipakai untuk evaluasi akhir. Sumber awal Mendeley diganti karena kelas Plastic tidak menyediakan cukup gambar; alasan dan lisensi ada di [DATASET.md](ml/DATASET.md).

## Pengujian

```powershell
python -m pytest api/tests -q
cd web
npm ci
npx playwright install chromium
npm run build
npm run test:e2e
cd ../mobile
flutter analyze
flutter test
```

Pengujian browser menjalankan API dan web terisolasi secara otomatis pada port 8001 dan 5174. PostgreSQL, build web, dan integrasi model juga diperiksa di GitHub Actions. Pengujian API tanpa PyTorch melewati satu pengujian model; job model memasang PyTorch untuk memverifikasi checkpoint asli.

## Paket pengumpulan

Setelah dataset diunduh, jalankan dari root:

```powershell
python scripts/export_openapi.py
python scripts/package_submission.py
```

Folder lokal `artifacts/` berisi `campah-dataset.zip`, `campah-ml.zip`, dan checksum. APK ikut disalin bila sudah dibuild lokal. Raw dataset, `.env`, unggahan, SDK lokal, dan hasil build diabaikan Git; source, checkpoint, serta hasil evaluasi tercatat di repository.

Demo publik belum dipasang karena akun layanan belum disiapkan. Video dengan penjelasan kandidat dan uji perangkat Android tetap perlu diselesaikan sebelum pengumpulan; [progres](docs/PROGRESS.md) mencatat status verifikasi yang sebenarnya.

## Kontribusi dan progres

Gunakan Conventional Commits per fitur/perbaikan, misalnya `feat(reports): add status history` atau `fix(auth): reject disabled accounts`. Sertakan file terkait dan hasil pemeriksaan pada tahap tersebut. `git log --oneline` menampilkan riwayat pekerjaan; `git status --short` menampilkan perubahan yang belum di-commit.
