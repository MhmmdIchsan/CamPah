# Evaluasi foto lapangan CamPah

Kumpulkan foto baru yang tidak berasal dari dataset pelatihan atau contoh yang disertakan. Gunakan kamera, lokasi, dan pencahayaan beragam; tentukan label secara manual. Jangan menyimpan foto pribadi atau membagikan koordinat tanpa izin. Pisahkan pengambilan atau lokasi yang saling berhubungan antara validation dan test untuk mengurangi kebocoran.

Buat CSV `path,label,split`; `path` relatif terhadap lokasi CSV. Label yang diterima: `Organic Waste`, `Plastic Waste`, `Paper Waste`, `Other` (bukan salah satu kelas), dan `Mixed` (sampah campuran). Split harus `validation` atau `test`. Contoh:

```csv
path,label,split
photos/validation-1.jpg,Plastic Waste,validation
photos/validation-2.jpg,Other,validation
photos/test-1.jpg,Paper Waste,test
photos/test-2.jpg,Mixed,test
```

Jalankan `python ml/evaluate_field.py path/to/manifest.csv --output path/to/field-results.json`. Gunakan validation untuk merancang ambang atau metode penolakan, dan test yang terpisah hanya untuk evaluasi akhir. Script memeriksa duplikat byte, tetapi tidak mendeteksi foto yang sangat mirip; pemeriksaan manual per lokasi dan sesi tetap diperlukan.

Output melaporkan jumlah dan akurasi tiga kelas serta jumlah dan rata-rata confidence foto Other/Mixed. Model saat ini selalu memilih salah satu dari tiga kelas, sehingga hasil Other/Mixed menunjukkan perilaku pada data di luar cakupan, bukan deteksi out-of-distribution yang sudah teruji. Jangan mengartikan confidence sebagai peluang kebenaran yang terkalibrasi atau mengaktifkan ambang secara otomatis sebelum validasi memadai. File gambar dan hasil evaluasi harus disimpan sesuai izin pemilik data.
