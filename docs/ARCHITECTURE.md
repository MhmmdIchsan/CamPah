# Arsitektur dan ERD CamPah

```mermaid
flowchart LR
    Web[React / Vite] -->|HTTPS + JWT| API[FastAPI]
    Android[Flutter Android] -->|Foto + GPS + JWT| API
    API --> DB[(PostgreSQL)]
    API --> Images[Cloudinary]
    API --> ML[MobileNetV2 CPU]
    Dataset[RealWaste] --> Train[Training PyTorch]
    Train --> Checkpoint[best_model.pt]
    Checkpoint --> ML
```

Web dan Android menggunakan API yang sama. Dependency autentikasi memuat akun dari database pada setiap permintaan, sehingga penonaktifan akun langsung memblokir token yang sudah diterbitkan. Pemeriksaan kepemilikan berada di API. UI juga menyembunyikan operasi laporan yang tidak diizinkan.

Pembuatan laporan memvalidasi foto, mengoreksi orientasi kamera, menyimpan foto, lalu menyimpan laporan Pending di database. Inferensi dijalankan melalui thread pool dan hasilnya ditambahkan ke laporan. Kegagalan inferensi tidak membatalkan laporan yang telah disimpan. Pengembangan lokal dapat menggunakan SQLite dan folder uploads; deployment menggunakan PostgreSQL dan Cloudinary.

## ERD

```mermaid
erDiagram
    users ||--o{ reports : creates
    users ||--o{ report_status_history : changes
    reports ||--o{ report_status_history : records
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
        text description
        float latitude
        float longitude
        text image_url
        string image_public_id
        string status
        string ai_category
        float ai_confidence
        datetime created_at
        datetime updated_at
        datetime deleted_at
    }
    report_status_history {
        int id PK
        int report_id FK
        int admin_id FK
        string old_status
        string new_status
        datetime changed_at
    }
```

Email memiliki unique index. Laporan memiliki index pada pemilik dan status; riwayat status memiliki index report_id. Role/status divalidasi di API. Tanggal ditulis dalam UTC dan dapat diformat menurut zona waktu perangkat. Penghapusan laporan mengisi `deleted_at`; akun dinonaktifkan melalui `is_active` agar relasi laporan tetap utuh.

## Batas akses

| Operasi | User | Admin |
| --- | --- | --- |
| Lihat laporan dan dashboard | Milik sendiri | Semua |
| Buat laporan | Ya | Ya |
| Ubah/hapus laporan | Milik sendiri, Pending | Semua |
| Ubah status | Tidak | Ya |
| Kelola pengguna | Tidak | Ya |
| Prediksi gambar | Ya | Ya |

Migrasi awal ada di `api/migrations/versions/001_initial.py`; `python api/start.py` menerapkan migrasi sebelum menjalankan server. GitHub Actions memeriksa migrasi terhadap PostgreSQL 16 dan mencocokkan metadata ORM dengan skema hasil migrasi.
