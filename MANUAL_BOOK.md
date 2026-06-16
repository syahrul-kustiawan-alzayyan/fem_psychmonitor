# Fem-Psych Monitor — Panduan Pengguna

**Versi 1.0.1** · 16 Juni 2026

---

## Daftar Isi

1. [Sekilas Aplikasi](#1-sekilas-aplikasi)
2. [Memulai](#2-memulai)
3. [Beranda](#3-beranda)
4. [Rekaman & Deteksi Emosi](#4-rekaman--deteksi-emosi)
5. [Hasil Rekaman](#5-hasil-rekaman)
6. [Riwayat](#6-riwayat)
7. [Profil](#7-profil)
8. [Pengaturan](#8-pengaturan)
9. [Premium](#9-premium)
10. [Detail Rekaman](#10-detail-rekaman)
11. [Akun & Data](#11-akun--data)
12. [Troubleshooting](#12-troubleshooting)

---

## 1. Sekilas Aplikasi

Fem-Psych Monitor adalah aplikasi kesehatan mental untuk perempuan Indonesia. Tiga fungsi utama:

- **Rekam suara** — aplikasi membaca emosi dari nada bicara dan kata-kata yang diucapkan
- **Asesmen psikologi** — tes MBTI dan kuesioner kesehatan mental
- **Pemantauan tren** — grafik yang menunjukkan perubahan kondisi emosi dari waktu ke waktu

Bahasa yang didukung: Indonesia dan Inggris.

---

## 2. Memulai

### 2.1 Instalasi

Salin file `.apk` ke ponsel, buka, lalu tap Install. Jika muncul peringatan keamanan, izinkan instalasi dari sumber tidak dikenal (bisa dimatikan kembali setelah selesai).

### 2.2 Pertama Kali Buka

Aplikasi akan memandu kamu melewati 4 langkah sebelum bisa masuk ke halaman utama.

**Langkah 1: Selamat Datang**
Tap tombol Mulai untuk melanjutkan.

**Langkah 2: Tes MBTI**
20 pertanyaan dengan dua pilihan jawaban masing-masing. Pilih yang paling mewakili dirimu. Hasilnya akan menentukan salah satu dari 16 tipe kepribadian MBTI.

**Langkah 3: Kuesioner Psikologi**
30 pertanyaan dengan skala 1–5 (Tidak Pernah sampai Sangat Sering). Jawab dengan jujur — tidak ada jawaban benar atau salah. Skor akhir dikategorikan sebagai:

| Skor | Kategori |
|------|----------|
| 0–15 | Sehat Optimal |
| 16–30 | Cukup Sehat |
| 31–45 | Rentan |
| 46+ | Butuh Perhatian Klinis |

**Langkah 4: Hasil**
Ringkasan tipe MBTI dan skor psikologi ditampilkan. Tap tombol **Lanjut ke Login** untuk menuju halaman masuk.

### 2.3 Membuat Akun

1. Buka tab **Daftar**
2. Isi nama, email, dan password (minimal 6 karakter)
3. Centang persetujuan kebijakan privasi
4. Tap **Daftar**
5. Buka email masuk (cek juga folder Spam) dan klik link verifikasi
6. Kembali ke aplikasi, login dengan email dan password

### 2.4 Login

Masukkan email dan password yang sudah terdaftar, centang persetujuan privasi, lalu tap **Masuk**.

**Lupa password?** Tap tautan **Lupa Password** di halaman login, masukkan email, dan ikuti instruksi yang dikirim ke emailmu.

### 2.5 Masuk dengan Google

Tap tombol **Google**, pilih akun yang ingin digunakan. Jika alamat email belum terdaftar, akun Firebase baru akan dibuat secara otomatis.

> Google Sign-In membutuhkan koneksi internet dan Google Play Services yang aktif.

---

## 3. Beranda

### 3.1 Tata Letak

Beranda adalah halaman pertama setelah login. Terdiri dari lima blok yang tersusun vertikal:

**Header** — menampilkan sapaan (pagi/siang/sore/malam) dan inisial atau foto profil.

**Status Psikis** — kartu gradien yang menunjukkan emosi dominan terkini, label kondisi, dan skor numerik.

**Tiga Kartu Statistik** — emosi yang paling sering muncul dalam seminggu terakhir, total rekaman, dan mood hari ini.

**Tombol Mulai Rekam** — tombol bundar dengan efek pulse. Fungsi yang sama bisa diakses dari tab **Rekam** di navigasi bawah.

**Saran Hari Ini** — rekomendasi berdasarkan hasil MBTI, skor psikologi, dan emosi terkini. Bisa ditutup dengan tap.

**Riwayat Terbaru** — tiga rekaman terakhir. Tap salah satu untuk melihat detail. Tap **Lihat Semua** untuk membuka halaman riwayat lengkap.

---

## 4. Rekaman & Deteksi Emosi

### 4.1 Cara Kerja

Saat merekam suara, dua proses berjalan paralel:

- Nada suara dianalisis menggunakan model kecerdasan buatan (60% dari skor akhir)
- Kata-kata yang diucapkan ditranskripsi dan dianalisis menggunakan pencocokan kata kunci (40% dari skor akhir)

Keduanya digabungkan menjadi skor akhir untuk masing-masing enam emosi: Happy, Sad, Angry, Disgust, Neutral, dan Fear.

### 4.2 Layar Deteksi Langsung

Sebelum merekam, layar ini menampilkan animasi pulsa dan emosi terdeteksi secara real-time. Fungsinya sebagai pratinjau — data tidak disimpan sampai rekaman dimulai.

### 4.3 Melakukan Rekaman

1. Tap tombol rekam (lingkaran besar)
2. Indikator merah dan teks **Mendengarkan...** akan muncul
3. Bicaralah secara alami. Minimal 10–15 detik untuk hasil optimal
4. Selama merekam, enam bar emosi akan bergerak menunjukkan skor real-time
5. Tap tombol **Stop** (■) untuk mengakhiri
6. Tunggu proses analisis (1–5 detik), hasil akan muncul otomatis

**Tips:**

- Pilih tempat yang tenang
- Bicara dengan volume dan kecepatan normal
- Hindari suara latar seperti televisi atau kipas angin

### 4.4 Enam Bar Emosi

Setiap emosi diwakili oleh bar horizontal dengan panjang proporsional terhadap skornya, diurutkan dari tertinggi ke terendah. Warna bar berbeda per emosi: kuning untuk Happy, biru untuk Sad, merah untuk Angry, hijau untuk Disgust, abu-abu untuk Neutral, dan ungu untuk Fear.

---

## 5. Hasil Rekaman

### 5.1 Komponen Halaman Hasil

**Emosi Dominan** — emosi dengan skor tertinggi ditampilkan besar di bagian atas, lengkap dengan persentase keyakinan dan skor numerik.

**Grafik Perbandingan** — grafik batang berpasangan yang membandingkan skor dari analisis audio vs analisis teks. Berguna untuk melihat apakah nada suara selaras dengan kata-kata yang diucapkan.

**Skor Tren** — hasil perkalian antara nilai dasar emosi dan keyakinan sistem. Nilai dasar berkisar dari -8 (Angry) hingga +10 (Happy). Semakin tinggi skor, semakin kuat emosi tersebut terdeteksi.

### 5.2 Pemicu Emosi

Sebelum menyimpan, kamu **wajib** memilih satu pemicu. Tujuh opsi tersedia:

- Pekerjaan
- Percintaan
- Keuangan
- Kesehatan
- Keluarga
- Sosial
- Lainnya

Tap pemicu yang sesuai, lalu tombol **Simpan** akan aktif.

### 5.3 Saran Personal

Berdasarkan emosi dominan yang terdeteksi, aplikasi menampilkan 3–4 saran. Contoh: jika Sad terdeteksi, saran akan mencakup opsi untuk curhat dengan orang terdekat atau melakukan kegiatan yang disukai.

### 5.4 Menyimpan

Tap **Simpan** setelah memilih pemicu. Data akan tersimpan ke akun Firestore dan kamu akan kembali ke Beranda atau Riwayat.

---

## 6. Riwayat

### 6.1 Halaman Riwayat

Menampilkan seluruh rekaman yang pernah dibuat. Dilengkapi filter waktu: Semua, Hari Ini, 7 Hari, 30 Hari, dan Kustom.

### 6.2 Grafik

Garis yang menunjukkan perubahan skor emosi dari waktu ke waktu. Sumbu vertikal berkisar dari -10 hingga +11. Naik berarti positif, turun berarti negatif.

### 6.3 Daftar Log

Setiap rekaman ditampilkan sebagai kartu yang berisi emoji, nama emosi, skor, pemicu, dan waktu relatif. Tap kartu untuk membuka detail lengkap.

### 6.4 Ekspor Data

Riwayat bisa diekspor dalam format CSV (bisa dibuka di Excel) atau JSON. Masuk ke **Pengaturan** → pilih **Ekspor Data (CSV)** atau **Ekspor Data (JSON)**.

---

## 7. Profil

### 7.1 Informasi yang Ditampilkan

- Foto profil (bisa diganti dari galeri atau kamera)
- Nama dan email
- Tipe MBTI lengkap dengan deskripsi dan kekuatan
- Skor psikologi dan kategori

### 7.2 Edit Profil

Tap nama atau foto untuk mengubahnya. Perubahan akan langsung tersimpan di Firestore.

---

## 8. Pengaturan

| Menu | Fungsi |
|------|--------|
| Bahasa | Beralih antara Indonesia dan Inggris |
| Tema | Beralih antara tema terang dan gelap |
| Panduan | Membuka panduan pengguna |
| Kebijakan Privasi | Membuka halaman kebijakan privasi |
| Lisensi | Informasi lisensi perangkat lunak |
| Ekspor CSV | Mengunduh riwayat sebagai file CSV |
| Ekspor JSON | Mengunduh riwayat sebagai file JSON |
| Keluar | Logout dari aplikasi |

**Logout** akan mengembalikan kamu ke halaman login. Semua data tetap aman di cloud dan bisa diakses kembali setelah login.

---

## 9. Premium

### 9.1 Manfaat

Premium adalah langganan berbayar yang menghilangkan semua iklan dari aplikasi (banner, interstitial, dan app open). Tiga paket tersedia:

| Paket | Harga | Keterangan |
|-------|-------|------------|
| Mingguan | Rp 7.000 | Per minggu |
| Bulanan | Rp 20.000 | Hemat 20% |
| Tahunan | Rp 99.000 | Hemat 50% |

### 9.2 Berlangganan

Buka halaman Premium, pilih paket, tap **Langganan Sekarang**, lalu ikuti instruksi pembayaran dari Google Play.

### 9.3 Memulihkan Pembelian

Jika sudah pernah berlangganan sebelumnya (misalnya setelah ganti perangkat), buka halaman Premium dan tap **Pulihkan Pembelian**.

---

## 10. Detail Rekaman

Setiap rekaman bisa dilihat detailnya dengan tap pada kartu di halaman Riwayat.

Halaman detail menampilkan:

- Emosi dominan, skor, dan waktu rekaman
- Transkrip suara (jika ada)
- Grafik perbandingan audio vs teks
- Skor tren
- Pemicu yang dipilih
- Saran yang diberikan saat itu
- Tombol **Hapus Rekaman** untuk menghapus data tersebut

---

## 11. Akun & Data

### 11.1 Data yang Tersimpan

- Profil (nama, email, foto)
- Hasil MBTI dan skor psikologi
- Rekaman suara, transkrip, skor emosi, dan pemicu
- Preferensi aplikasi (tema, bahasa) — disimpan di perangkat

### 11.2 Hapus Akun

Masuk ke **Profil**, gulir ke bawah, tap **Hapus Akun**. Baca peringatan, lalu tap **Hapus** untuk konfirmasi. Kamu akan diminta login ulang untuk verifikasi.

Data yang akan dihapus: profil, riwayat rekaman, hasil MBTI dan psikologi, status premium.
Data yang tidak bisa dihapus: log anonim (tidak dapat dikaitkan ke individu) dan data pembayaran di Google Play / RevenueCat.

Proses penghapusan berlangsung dalam dua tahap:

- Database aktif: ±1 menit setelah konfirmasi
- Seluruh backup dan cache: maksimal 7 hari

Jika berubah pikiran, login kembali dalam 7 hari untuk membatalkan. Setelah 7 hari, data tidak bisa dipulihkan.

**Kontak**: syahrulkustiawanalzayyan@gmail.com

---

## 12. Troubleshooting

### Login

| Masalah | Solusi |
|---------|--------|
| Email tidak terdaftar | Daftar akun baru dengan email tersebut |
| Password salah | Gunakan fitur Lupa Password |
| Email belum diverifikasi | Cek inbox dan folder Spam untuk link verifikasi |
| Google Sign-In gagal | Pastikan Google Play Services terinstal, restart ponsel |

### Rekaman

| Masalah | Solusi |
|---------|--------|
| Mikrofon tidak berfungsi | Periksa izin mikrofon di pengaturan ponsel |
| Transkrip kosong | Bicara lebih jelas, hindari tempat bising |
| Proses terlalu lama | Wajar 1–5 detik. Jika lebih, restart aplikasi |
| Suara tidak terdeteksi | Pastikan tidak ada aplikasi lain yang menggunakan mikrofon |

### Lainnya

| Masalah | Solusi |
|---------|--------|
| Model gagal diunduh | Pastikan koneksi stabil (ukuran file ~142 MB) |
| Premium tidak aktif | Buka Premium → Pulihkan Pembelian |
| Aplikasi terasa lambat | Tutup aplikasi lain, restart ponsel |
| Tampilan tidak normal | Restart aplikasi atau ganti tema |

Jika masalah berlanjut, hubungi syahrulkustiawanalzayyan@gmail.com. Respons 1×24 jam pada hari kerja.

---

© 2026 Fem-Psych Monitor
