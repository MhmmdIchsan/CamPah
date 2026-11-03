# API CamPah

Base URL pengembangan: `http://localhost:8000`. Swagger UI: `/docs`; OpenAPI runtime: `/openapi.json`; kontrak yang disimpan: [openapi.json](openapi.json). Jalankan `python scripts/export_openapi.py` setelah mengubah kontrak API.

## Autentikasi

`POST /auth/register` menerima JSON `name`, `email`, `password` dan selalu membuat role User. Nama minimal dua karakter, password minimal delapan karakter dan maksimal 72 byte UTF-8. `POST /auth/login` menerima JSON `email`, `password`.

Respons autentikasi berisi `access_token`, `token_type: bearer`, serta `user` dengan id, name, email, role, dan is_active. Kirim `Authorization: Bearer TOKEN` pada endpoint yang membutuhkan autentikasi. Token berlaku 24 jam; respons 401 mengharuskan login kembali. `/health`, `/docs`, dan kontrak OpenAPI tersedia untuk operasional/dokumentasi tanpa login.

## Endpoint

| Metode | Path | Isi/parameter | Akses |
| --- | --- | --- | --- |
| GET | `/auth/me` | Akun saat ini | Login |
| GET | `/reports` | `q`, `status`, `page` (mulai 1), `page_size` (1–100) | User: sendiri; Admin: semua |
| POST | `/reports` | Multipart `image`, `description`, `latitude`, `longitude` | Login |
| GET | `/reports/{id}` | Detail laporan | Pemilik/Admin |
| PATCH | `/reports/{id}` | JSON opsional `description`, `latitude`, `longitude` | Pemilik saat Pending/Admin |
| DELETE | `/reports/{id}` | Soft delete; respons 204 | Pemilik saat Pending/Admin |
| PATCH | `/reports/{id}/status` | JSON `status`, `expected_status`, `note`, `is_correction` | Admin |
| GET | `/reports/{id}/history` | Riwayat status dan catatan publik | Pemilik/Admin |
| POST | `/reports/{id}/completion-photo` | Multipart `image`, sekali pada laporan Completed | Admin |
| GET | `/notifications` | Maksimal 100 notifikasi terbaru milik akun | Login |
| PATCH | `/notifications/{id}/read` | Tandai notifikasi sebagai dibaca | Pemilik |
| GET | `/dashboard` | `total`, `by_status`, `by_category` | Login; sesuai cakupan role |
| GET | `/users` | Daftar akun tanpa password hash | Admin |
| POST | `/users` | JSON `name`, `email`, `password`, `role` | Admin |
| PATCH | `/users/{id}` | JSON opsional `name`, `role`, `is_active` | Admin |
| POST | `/predict` | Multipart `image` | Login |
| GET | `/health` | Status proses | Publik |

Contoh status: `{"status":"In Progress","expected_status":"Pending","note":"Laporan diteruskan kepada petugas.","is_correction":false}`. Catatan wajib 3–1000 karakter dan dapat dibaca pelapor. Transisi biasa: Pending → In Progress atau Rejected; In Progress → Completed atau Rejected. Perubahan lain memerlukan `is_correction: true` dan alasan. Status yang sudah berubah sejak dibuka menghasilkan 409. Riwayat lama tetap tersedia dengan catatan null. Kategori AI: Organic Waste, Plastic Waste, Paper Waste. Confidence berada pada rentang 0–1.

## Contoh request

```sh
curl -X POST http://localhost:8000/auth/register -H "Content-Type: application/json" -d '{"name":"Demo User","email":"demo@example.com","password":"ReplaceWithYourOwnPassword"}'
curl -X POST http://localhost:8000/reports -H "Authorization: Bearer TOKEN" -F "image=@ml/examples/plastic.jpg" -F "description=Sampah plastik di tepi jalan" -F "latitude=-5.55" -F "longitude=95.32"
curl "http://localhost:8000/reports?status=Pending&page=1&page_size=10" -H "Authorization: Bearer TOKEN"
curl -X POST http://localhost:8000/predict -H "Authorization: Bearer TOKEN" -F "image=@ml/examples/organic.jpg"
```

Contoh curl memakai shell Bash; di PowerShell gunakan `curl.exe` dan sesuaikan escaping JSON atau gunakan Swagger UI.

Daftar laporan memberikan `{items, total, page, page_size}`. Setiap item mencakup id, user_id, owner_name, description, latitude, longitude, image_url, status, ai_category, ai_confidence, created_at, updated_at. `ai_category`/`ai_confidence` dapat null ketika inferensi gagal. URL foto pengembangan berbentuk `/uploads/...`; tambahkan base URL API ketika menampilkannya.

## Respons kegagalan

401: token salah/kedaluwarsa atau akun nonaktif. 403: operasi tidak diizinkan. 404: laporan tidak ditemukan atau berada di luar cakupan pengguna. 409: email sudah terdaftar. 422: isian atau foto tidak valid. 502: penyimpanan Cloudinary gagal. `/predict` memberikan 503 bila model belum tersedia. Kegagalan model ketika membuat laporan tetap menghasilkan 201 dengan kolom AI null.
