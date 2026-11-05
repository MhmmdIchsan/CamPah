# Arsitektur dan ERD CamPah

Dokumen ini menggambarkan implementasi CamPah: web React, Android Flutter, API FastAPI, PostgreSQL, penyimpanan foto Cloudinary, dan model klasifikasi gambar MobileNetV2.

## Arsitektur sistem

```mermaid
flowchart LR
    User["User / pelapor"] --> Web["Web React / Vite"]
    User --> Mobile["Android Flutter"]
    Admin["Admin"] --> Web
    Officer["Petugas"] --> Web
    Officer --> Mobile
    Web -->|"HTTPS / REST + JWT"| API["FastAPI di Render"]
    Mobile -->|"HTTPS / REST + JWT"| API
    API -->|"akun, laporan, riwayat, notifikasi"| DB[("PostgreSQL di Render")]
    API -->|"unggah foto dan baca URL"| Storage["Cloudinary"]
    API -->|"inferensi pada server API"| Model["MobileNetV2 / PyTorch"]
    Dataset["Dataset RealWaste"] -->|"train / validation / test"| Train["Training PyTorch"]
    Train -->|"bobot terbaik berdasarkan validation"| Weights["best_model.pt"]
    Weights --> Model
```

Web diterbitkan sebagai Render Static Site; API berjalan sebagai Render Web Service. Android menggunakan URL API publik yang sama. Model dan kode inferensi berjalan di proses API, sehingga model bukan layanan terpisah. Cloudinary menyimpan foto; PostgreSQL menyimpan URL foto dan data aplikasi. Untuk pengembangan lokal, proyek juga mendukung SQLite dan folder unggahan lokal.

- Web: https://campah-web.onrender.com
- Dokumentasi API interaktif: https://campah-api.onrender.com/docs
- Kode dan model: https://github.com/MhmmdIchsan/CamPah

## Alur laporan dan tindak lanjut

```mermaid
sequenceDiagram
    actor W as User
    participant A as Android / Web
    participant API as FastAPI
    participant C as Cloudinary
    participant DB as PostgreSQL
    participant ML as MobileNetV2
    actor Admin
    actor P as Petugas
    W->>A: Pilih foto, isi deskripsi dan koordinat
    A->>API: POST /reports (foto, deskripsi, GPS, JWT)
    API->>API: Validasi dan normalisasi foto
    API->>C: Simpan foto
    C-->>API: URL foto
    API->>DB: Simpan laporan Pending
    API->>ML: Prediksi kategori gambar
    ML-->>API: Kategori dan confidence, jika tersedia
    API->>DB: Simpan hasil prediksi
    API-->>A: Laporan dan hasil AI
    Admin->>API: Tugaskan laporan ke akun petugas aktif
    API->>DB: Simpan penugasan dan notifikasi petugas
    P->>API: Buka tugas dan ubah status dengan catatan
    API->>DB: Simpan status, riwayat, dan notifikasi pelapor
    W->>A: Muat ulang riwayat dan notifikasi
    A->>API: Ambil data laporan terbaru
```

Laporan disimpan sebelum inferensi. Jika prediksi gagal, laporan tetap tersedia dengan hasil AI kosong. Alur normal status adalah **Pending → In Progress → Completed**; Pending atau In Progress juga dapat berubah ke Rejected. Admin dapat membuat koreksi status dengan alasan. API memakai `expected_status` untuk menolak perubahan ketika status sudah berubah sejak laporan dibuka.

## ERD

```mermaid
erDiagram
    users ||--o{ reports : "membuat (user_id)"
    users o|--o{ reports : "ditugaskan (assigned_user_id)"
    users ||--o{ report_status_history : "mengubah status (admin_id)"
    reports ||--o{ report_status_history : "memiliki riwayat"
    users ||--o{ notifications : "menerima"
    reports ||--o{ notifications : "terkait"

    users {
        int id PK
        string name
        string email UK
        string password_hash
        string role
        boolean is_active
        datetime created_at
    }
    reports {
        int id PK
        int user_id FK
        int assigned_user_id FK "nullable"
        string assigned_name "nullable; nama penugasan"
        text description
        float latitude
        float longitude
        text image_url
        string image_public_id "nullable"
        text completion_image_url "nullable"
        string status
        string ai_category "nullable"
        float ai_confidence "nullable"
        string corrected_category "nullable"
        text category_note "nullable"
        int category_reviewer_id "nullable; bukan FK"
        datetime category_reviewed_at "nullable"
        datetime created_at
        datetime updated_at
        datetime deleted_at "nullable; soft delete"
    }
    report_status_history {
        int id PK
        int report_id FK
        int admin_id FK "akun pelaksana: admin atau petugas"
        string old_status
        string new_status
        text note "nullable"
        boolean is_correction
        datetime changed_at
    }
    notifications {
        int id PK
        int user_id FK
        int report_id FK
        text message
        boolean is_read
        datetime created_at
    }
```

`reports.user_id` menunjuk pembuat laporan; `reports.assigned_user_id` menunjuk akun petugas yang ditugaskan dan boleh kosong. `assigned_name` menyimpan nama untuk tampilan dan mempertahankan data penugasan lama. Kolom `category_reviewer_id` menyimpan ID peninjau tanpa constraint foreign key; fitur tinjau kategori saat ini tidak ditampilkan pada web. Walaupun kolom pelaksana riwayat bernama `admin_id`, nilainya dapat merujuk akun Admin atau Petugas.

Email memiliki unique index. API memeriksa role, kepemilikan, penugasan, dan status pengguna pada akses data; role dan status bukan database enum. Penghapusan laporan memakai `deleted_at`, sedangkan pengguna dapat dinonaktifkan dengan `is_active`. Penonaktifan akun membuat token yang sudah diterbitkan tidak dapat digunakan. Timestamp disimpan dalam UTC dan ditampilkan sesuai format aplikasi.

## Hak akses yang dipakai antarmuka

| Operasi | User | Petugas | Admin |
| --- | --- | --- | --- |
| Dashboard dan detail laporan | Laporan milik sendiri | Laporan yang ditugaskan | Semua laporan |
| Membuat laporan melalui antarmuka | Ya | Tidak tersedia | Ya, melalui web |
| Ubah/hapus isi laporan | Milik sendiri saat Pending | Tidak | Semua |
| Ubah status dengan catatan | Tidak | Laporan yang ditugaskan | Semua |
| Koreksi status | Tidak | Tidak | Ya |
| Tugaskan petugas dan kelola pengguna | Tidak | Tidak | Ya |
| Lihat notifikasi | Milik sendiri | Milik sendiri | Milik sendiri |

API `POST /reports` dan `/predict` menerima akun yang telah login; tabel di atas membedakan ketersediaan menu antarmuka. Akses data dan penugasan tetap diperiksa di server. Riwayat migrasi berada di `api/migrations/versions/`; `python api/start.py` menerapkannya sebelum API dimulai. GitHub Actions memeriksa migrasi PostgreSQL dan pengujian API.

## Model dan batas hasil

Model memakai tiga kelas: Organic Waste, Plastic Waste, dan Paper Waste. Data RealWaste yang dipilih berjumlah 600 gambar: 420 training, 90 validation, dan 90 test. Checkpoint dipilih memakai validation; hasil test terpisah adalah 87 benar dari 90 gambar atau **96,67%**. Angka tersebut berlaku untuk split tersebut dan belum membuktikan ketepatan pada semua kondisi lapangan. Rincian sumber dan batas lisensi ada di [DATASET.md](../ml/DATASET.md), sedangkan metode dan metrik ada di [MODEL_CARD.md](../ml/MODEL_CARD.md).
