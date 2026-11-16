# Hasil audit integrasi API

Backend: `http://127.0.0.1:8000/api`.
Backend Laravel yang sedang berjalan: `C:/Users/Lenovo/Downloads/DONGIV/TUBES-PABW-new - Salin`.

## Perbaikan

- Form Start Campaign mengirim POST /api/v1/campaigns dengan Bearer token, tanggal berakhir, kategori yang diterima backend, dan unggahan gambar multipart.
- Riwayat kampanye menggunakan GET /api/v1/campaigns?my=1, sesuai implementasi controller Laravel. Rute /api/v1/my-campaigns tidak tersedia.
- Registrasi mengirim role=user sesuai validasi backend.
- Profil hanya dinyatakan berhasil setelah server menyimpan data. Kegagalan tidak ditutupi oleh penyimpanan lokal.
- Riwayat profil menggunakan /api/v1/profile/donations; detail transaksi menggunakan /api/v1/donations/{order_id}.
- Notifikasi menggunakan PUT /notifications/{id}/mark-read dan POST /notifications/mark-all-read. Jumlah belum dibaca dibaca dari unread_count pada respons.
- Navigasi notifikasi donasi dipulihkan; notifikasi relawan membuka daftar kegiatan tanpa mengirim integer ke rute yang membutuhkan objek kampanye.
- Request API memiliki batas waktu 30 detik. Query pencarian kampanye di-encode.
- Respons login berisi token tidak lagi dicetak frontend.
- Logout Laravel hanya mengakses sesi web apabila sesi tersedia.
- Respons notifikasi Laravel menyertakan payload data (termasuk order_id) dan mengikuti page/per_page agar daftar tidak menduplikasi seluruh data.

## Verifikasi

- GET /api/v1/campaigns: HTTP 200.
- GET /api/v1/volunteer-campaigns: HTTP 200.
- Header CORS untuk Origin website: Access-Control-Allow-Origin: *.
- Endpoint profil, notifikasi, sertifikat: menolak akses tanpa token dengan HTTP 401, sesuai proteksi.
- 13 pengujian login/logout, navigasi notifikasi, formulir donasi, dan detail transaksi lulus.
- 3 pengujian kontrak API tambahan lulus: penolakan update profil, endpoint notifikasi, dan unggahan kampanye multipart.
- Flutter build web berhasil; hasil ada di build/web.
- Flutter analyze masih melaporkan peringatan/lint proyek; tidak ada error kompilasi pada pemeriksaan setelah perbaikan navigasi.
- Suite akhir dijalankan berurutan: 21 tes lulus, 4 gagal. Dua tes model notifikasi mengharapkan kategori Inggris sedangkan implementasi menggunakan kategori Indonesia; dua tes halaman notifikasi tidak sesuai keadaan/tampilan saat ini. Seluruh suite belum dinyatakan lulus.
- PHP syntax check untuk AuthController.php dan NotificationController.php berhasil.

## Belum didukung backend yang berjalan

- API chatbot (/api/v1/chatbot/message) belum tersedia. Fitur ulasan telah ditambahkan pada pembaruan di bawah.
- Rute device-tokens untuk push tidak tersedia; layanan push saat ini berupa stub pada kode proyek sebelum audit.
- Kolom alamat pengguna tidak ditemukan pada model/migrasi backend yang diperiksa; update alamat belum dapat dijamin tersimpan.
- Pembayaran tetap menggunakan POST /api/v1/donations sesuai rute backend saat ini. Audit tidak membuat transaksi pembayaran nyata.
- Pengiriman kampanye dan unggah gambar diverifikasi melalui mock HTTP; audit tidak menambahkan kampanye ke database pengguna.

## Menjalankan website

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

Server Laravel harus tetap aktif. Alamat 127.0.0.1 digunakan untuk browser pada komputer yang sama.

## Pembaruan fitur ulasan

- Kategori sesuai pilihan pengguna: **Semua Ulasan, Donasi, Relawan**.
- Website Laravel memiliki halaman `http://127.0.0.1:8000/ulasan` dan bagian ulasan dinamis di beranda, menggantikan testimoni statis.
- Website dan Flutter menggunakan tabel `reviews` dan controller yang sama. Endpoint daftar, kelayakan, tambah, ubah, hapus tersedia di `/api/v1/reviews`.
- Donasi harus berstatus VERIFIED; relawan harus memiliki lamaran approved dan kegiatan selesai. Referensi diverifikasi milik pengguna yang login. Satu ulasan per pengguna per kegiatan.
- Rating 1–5, ulasan 5–2000 karakter, opsi anonim, ringkasan rating, filter kategori, dan pagination.
- Identitas anonim disembunyikan dari pengguna lain; hanya pemilik dapat mengubah atau menghapus.
- Kegagalan API ditampilkan sebagai kegagalan, bukan sebagai daftar kosong atau kelayakan palsu.
- Sumber backend tersimpan di `backend_reviews/` dan telah dipasang ke proyek Laravel yang berjalan. Migrasi hanya menambahkan tabel baru, tanpa menjalankan ulang migrasi lain.
- Pengujian backend: 9 tes, 49 assertions, lulus pada SQLite sementara. Pengujian Flutter untuk ulasan: 5 tes lulus.
- Endpoint API semua kategori, halaman `/ulasan`, dan beranda merespons HTTP 200. Daftar nyata masih kosong sampai pengguna yang memenuhi syarat menulis ulasan; tidak ditambahkan ulasan contoh ke database.
