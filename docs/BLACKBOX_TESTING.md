# Dokumentasi Blackbox Testing — Fem-Psych Monitor

**Aplikasi:** Fem-Psych Monitor v2.1.5+8
**Platform:** Flutter (Android / iOS / Web)
**Metode:** Blackbox Testing (pengujian kotak hitam / fungsional) oleh tester manusia
**Status:** **Template** — kolom *Hasil Aktual*, *Status*, *Nama Tester*, *Tanggal Pengujian*, *Bukti/Lampiran*, dan *Catatan/Kendala* dikosongkan dan siap diisi oleh tester.

---

## 1. Pendahuluan

Dokumen ini berisi rencana dan format pelaksanaan **blackbox testing** (pengujian fungsional) untuk aplikasi Fem-Psych Monitor. Blackbox testing memperlakukan aplikasi sebagai kotak hitam — pengujian dilakukan melalui antarmuka pengguna secara langsung oleh tester manusia, tanpa perlu melihat bagaimana kode di dalamnya bekerja.

Secara garis besar, tujuan pengujian ini adalah:

1. Memastikan setiap fitur aplikasi berperilaku sesuai yang diharapkan dari sudut pandang pengguna akhir.
2. Menguji seluruh modul inti: autentikasi, onboarding, dashboard, deteksi emosi (rekam & real-time), riwayat, detail rekaman, profil, pengaturan, premium, notifikasi, dan dashboard admin.
3. Memverifikasi integrasi dengan layanan eksternal: **Firebase Authentication** (autentikasi), **Backend cPanel PHP+MySQL** (penyimpanan data), **Google In-App Purchase** (langganan), **Google Mobile Ads** (iklan), **Whisper** (transkripsi suara), serta perangkat keras seperti **mikrofon** dan **galeri/kamera**.
4. Menyediakan template kasus uji lengkap beserta format pelaporan bug dan rekapitulasi hasil.

## 2. Ruang Lingkup

Modul yang diuji (14 modul, 113 kasus uji):

| No | Kode Modul | Modul / Fitur | Ruang Lingkup |
|---|---|---|---|
| 1 | AUTH | Autentikasi | Login/registrasi email & password, Google Sign-In, verifikasi email, reset password, kebijakan privasi |
| 2 | ONB | Onboarding | Welcome, kuesioner Big Five (MiniIPIP20), kuesioner psikis, halaman hasil, pengulangan asesmen |
| 3 | HOME | Dashboard | Sapaan, kartu status psikis, statistik cepat, CTA rekam, rekomendasi, riwayat terbaru |
| 4 | DET | Deteksi Emosi (Rekam) | Perekaman suara, transkripsi Whisper, analisis emosi via TFLite, kuota harian, upload audio |
| 5 | LIVE | Deteksi Emosi (Real-time) | Deteksi emosi real-time melalui mikrofon dengan snapshot berkala |
| 6 | RS | Halaman Hasil | Skor emosi gabungan (audio 60% : teks 40%), saran, trigger tag |
| 7 | HST | Riwayat & Statistik | Daftar log, filter waktu & emosi, grafik tren mingguan, pencarian |
| 8 | RCD | Detail Rekaman | Rincian satu rekaman, transkrip, grafik perbandingan skor audio vs teks |
| 9 | PRF | Profil | Tampilan profil, edit nama, foto profil, pengulangan Big Five |
| 10 | STG | Pengaturan | Bahasa, tema, pengingat harian, panduan, terms, privasi, backup/restore, hapus akun, logout |
| 11 | PRM | Premium | Paket langganan, pembelian via Google IAP, restore, status premium |
| 12 | ADM | Dashboard Admin | Statistik, distribusi emosi, status kesehatan mental, pencarian user, detail user, ekspor PDF |
| 13 | NTI | Notifikasi | Pengingat harian, izin notifikasi, penjadwalan, pengaturan waktu |
| 14 | SYS | Sistem & Perangkat | Peluncuran pertama, orientasi layar, konektivitas, persistensi, izin perangkat, unduhan model |

## 3. Lingkungan Pengujian

### 3.1 Perangkat Uji (diisi oleh tester)

| Parameter | Spesifikasi |
|---|---|
| Perangkat | *(isi, misal: Samsung Galaxy A54, iPhone 13, Android Emulator Pixel 7)* |
| Sistem Operasi | *(isi, misal: Android 14 / iOS 17)* |
| Versi Aplikasi | v2.1.5+8 (build 8) |
| Koneksi | Wi-Fi / Data seluler (internet aktif untuk backend, langganan, dan unduhan model) |
| Akun Uji | *(isi: email & password akun tester)* |

### 3.2 Ketergantungan Layanan

| Layanan | Kebutuhan | Catatan |
|---|---|---|
| Firebase Authentication | Koneksi internet | Login via email/password atau Google Sign-In; UID menjadi kunci identitas |
| Backend cPanel (PHP + MySQL) | Koneksi internet, API server aktif | Penyimpanan data user, rekaman, snapshot emosi; API key harus cocok antara `.env` dan `config.php` |
| Google In-App Purchase | Produk terkonfigurasi di Google Play Console | Langganan mingguan/bulanan/tahunan; verifikasi server-side via Google Play Developer API |
| Google Mobile Ads | ID unit iklan aktif di AdMob | Banner, interstitial, rewarded, app-open; premium bebas iklan |
| Whisper (model Base & Tiny) | Unduhan pertama kali (internet), pemrosesan lokal | Transkripsi suara offline setelah model diunduh |
| TFLite (model emosi) | File `final_female_model.tflite` di bundle | Klasifikasi emosi audio secara real-time |
| Mikrofon | Izin perangkat | Perekaman suara untuk deteksi emosi |
| Galeri / Kamera | Izin perangkat | Pengambilan foto profil |

## 4. Prosedur Pelaksanaan

### 4.1 Peran dan Tanggung Jawab

- **Tester** mengisi kolom *Hasil Aktual*, *Status* (PASS/FAIL/BLOCKED), *Nama Tester*, *Tanggal Pengujian*, *Bukti/Lampiran*, dan *Catatan/Kendala*.
- **Developer** memperbaiki cacat yang dilaporkan sesuai format pada Bab 7.
- **QA Lead / Supervisor** merekap hasil pada Bab 6 dan menandatangani Lembar Pengesahan (Bab 8).

### 4.2 Teknik Desain Kasus Uji

| Kode | Teknik | Penerapan pada Aplikasi |
|---|---|---|
| EP | Equivalence Partitioning | Mengelompokkan data uji valid/invalid: format email, panjang password, pilihan jawaban kuesioner, filter waktu riwayat |
| BVA | Boundary Value Analysis | Nilai batas: panjang password (5/6 karakter), kuota deteksi harian (0/5), batas kategori skor (25/26, 50/51, 75/76, 100) |
| DT | Decision Table | Kombinasi kondisi-aksi login (akun baru/lama, terverifikasi/belum, Google/password) dan status premium |
| EG | Error Guessing | Kondisi abnormal: offline, izin ditolak, pembayaran dibatalkan, data kosong, model gagal dimuat |
| ST | State Transition | Alur status: rekam → proses → hasil; onboarding → dashboard; non-premium → premium → reset |

### 4.3 Konvensi Penulisan Kasus Uji

- **ID Kasus Uji** mengikuti pola `KODE_MODUL-NO` (contoh: `AUTH-01`, `DET-07`).
- Kolom **Langkah Pengujian** ditulis per langkah (1) 2) 3) ...) sesuai urutan eksekusi.
- Kolom **Data Uji** berisi nilai konkret yang perlu dimasukkan tester.
- Kolom **Bukti/Lampiran** diisi nama berkas bukti (screenshot/rekaman layar), konvensi: `docs/bukti/<ID_KASUS>.png` (contoh: `docs/bukti/AUTH-01.png`).

### 4.4 Aturan Pengisian Kolom Hasil

- **Hasil Aktual**: tuliskan apa yang benar-benar diamati tester saat menjalankan kasus uji.
- **Status**: `PASS` (sesuai harapan), `FAIL` (tidak sesuai), atau `BLOCKED` (tidak bisa dieksekusi karena kendala lingkungan).
- **Catatan/Kendala**: kendala teknis, lingkungan, atau prasyarat yang memengaruhi hasil.
- Seluruh penilaian dilakukan oleh tester manusia — tidak ada status yang diisi otomatis.

---

## 5. Rincian Kasus Uji per Modul

### 5.1 Modul AUTH — Autentikasi

| ID | Fitur | Teknik | Skenario | Prekondisi | Data Uji | Langkah Pengujian | Hasil yang Diharapkan | Hasil Aktual | Status | Tester | Tanggal | Bukti | Catatan |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| AUTH-01 | Login email & password | EP | Login dengan email & password akun terdaftar | Akun uji terdaftar & email terverifikasi | `tester@example.com` / `Test1234` | 1) Buka aplikasi; 2) Centang kebijakan privasi; 3) Isi email & password; 4) Tekan "Masuk" | SnackBar "Login berhasil", navigasi ke dashboard | | | | | | |
| AUTH-02 | Password salah | DT | Login dengan password salah | Akun terdaftar dengan password `Test1234` | `tester@example.com` / `Salah123` | 1) Centang privasi; 2) Isi email benar & password salah; 3) Tekan "Masuk" | Dialog "Email/Password Salah", tidak masuk aplikasi | | | | | | |
| AUTH-03 | Registrasi otomatis | EP | Email baru belum terdaftar | Belum ada akun dengan email uji | `baru@example.com` / `Test1234` | 1) Centang privasi; 2) Isi email baru & password; 3) Tekan "Masuk" | Akun baru dibuat, dialog verifikasi email muncul, atau langsung ke onboarding | | | | | | |
| AUTH-04 | Email kosong | EP | Submit tanpa mengisi email | Form login tampil | email kosong | 1) Centang privasi; 2) Biarkan email kosong; 3) Tekan "Masuk" | Pesan "Email wajib diisi", tidak ada permintaan jaringan | | | | | | |
| AUTH-05 | Password kosong | EP | Submit tanpa mengisi password | Form login tampil | password kosong | 1) Centang privasi; 2) Isi email valid; 3) Tekan "Masuk" | Pesan "Password wajib diisi" | | | | | | |
| AUTH-06 | Format email tidak valid | EP | Email tanpa `@` atau tanpa titik | Form login tampil | `email.salah` | 1) Isi email `email.salah`; 2) Isi password; 3) Tekan "Masuk" | Pesan "Format email tidak valid" | | | | | | |
| AUTH-07 | Batas panjang password | BVA | Password 5 vs 6 karakter | Form login tampil | `abc12` dan `abc123` | 1) Isi password `abc12`, tekan "Masuk"; 2) Ganti `abc123`, tekan "Masuk" | Password 5 karakter ditolak; password 6 karakter lolos validasi | | | | | | |
| AUTH-08 | Wajib centang privasi | EG | Menekan Masuk/Google tanpa centang kebijakan | Form login, checkbox belum dicentang | tanpa centang | 1) Jangan centang kebijakan; 2) Tekan "Masuk"; 3) Tekan "Lanjutkan dengan Google" | SnackBar "Centang kebijakan privasi terlebih dahulu" pada kedua tombol | | | | | | |
| AUTH-09 | Google Sign-In | EP | Login dengan akun Google | Akun Google tersedia di perangkat | akun Google uji | 1) Centang privasi; 2) Tekan "Lanjutkan dengan Google"; 3) Pilih akun Google; 4) Konfirmasi | Login sukses → dashboard (akun lama) atau onboarding (akun baru) | | | | | | |
| AUTH-10 | Verifikasi email | ST | Email belum diverifikasi lalu diverifikasi | Email uji baru, belum diverifikasi | `baru@example.com` | 1) Registrasi email baru; 2) Buka email & klik tautan verifikasi; 3) Kembali ke aplikasi | Setelah verifikasi, aplikasi otomatis masuk & lanjut onboarding/dashboard | | | | | | |
| AUTH-11 | Email terdaftar via Google | DT | Login password untuk email yang terdaftar via Google | Email pernah daftar via Google | `google@example.com` | 1) Isi email tsb + password apa pun; 2) Tekan "Masuk" | Dialog "Akun Terdaftar dengan Google" dengan arahan masuk via Google | | | | | | |
| AUTH-12 | Reset password | DT | Email terdaftar via password, password salah | Akun terdaftar via password | `tester@example.com` / password salah | 1) Isi email terdaftar + password salah; 2) Tekan "Masuk"; 3) Pada dialog tekan "Kirim Reset Password" | SnackBar "Email reset password terkirim!" | | | | | | |
| AUTH-13 | Koneksi gagal | EG | Login saat offline | Mode pesawat/offline aktif | `tester@example.com` / `Test1234` | 1) Aktifkan mode pesawat; 2) Login seperti biasa | Dialog "Koneksi Gagal — Tidak dapat terhubung ke server" | | | | | | |
| AUTH-14 | Terlalu banyak percobaan | EG | Percobaan login salah berulang | Lebih dari batas percobaan login | password salah × 10 | 1) Login salah berulang kali | Dialog "Terlalu Banyak Percobaan" dan aplikasi memblokir sementara | | | | | | |
| AUTH-15 | Toggle tampil password | EP | Menampilkan & menyembunyikan password | Form login tampil | `Test1234` | 1) Isi password; 2) Tekan ikon mata; 3) Tekan lagi | Teks password tampil saat "visibility", tersembunyi saat "visibility_off" | | | | | | |

### 5.2 Modul ONB — Onboarding

| ID | Fitur | Teknik | Skenario | Prekondisi | Data Uji | Langkah Pengujian | Hasil yang Diharapkan | Hasil Aktual | Status | Tester | Tanggal | Bukti | Catatan |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| ONB-01 | Halaman welcome | EP | Akun baru membuka onboarding | Login akun baru sukses | nama `Sari` | 1) Buka aplikasi akun baru; 2) Amati halaman awal | Tampil halaman selamat datang dengan animasi hero, kartu fitur, dan tombol "Mulai Sekarang" | | | | | | |
| ONB-02 | Switch bahasa di welcome | EP | Beralih bahasa ID ↔ EN pada halaman welcome | Halaman welcome tampil | EN lalu ID | 1) Tekan tombol bahasa "EN"; 2) Amati teks; 3) Kembali ke "ID" | Seluruh teks halaman welcome berubah sesuai bahasa | | | | | | |
| ONB-03 | Kuesioner Big Five | EP | Kuesioner MiniIPIP20 (20 soal) | Welcome selesai | 20 pertanyaan | 1) Lanjut ke kuesioner Big Five; 2) Amati jumlah soal & pilihan jawaban | Tampil 20 pertanyaan dengan pilihan skala 1–5 dan progres bar; navigasi mundur/maju berfungsi | | | | | | |
| ONB-04 | Big Five wajib lengkap | EG | Lanjut sebelum semua soal terjawab | Kuesioner Big Five aktif | 1 soal belum dijawab | 1) Jawab 19 soal; 2) Tekan lanjut/selesai | Tombol lanjut nonaktif atau muncul peringatan soal belum dijawab | | | | | | |
| ONB-05 | Reverse scoring Big Five | EG | Soal dengan `keyed == '-'` membalik skor | Kuesioner Big Five aktif | tidak ada | 1) Perhatikan soal berlabel negatif; 2) Bandingkan skor mentah vs skor akhir | Skor soal negatif dihitung dengan rumus `6 - rawScore` | | | | | | |
| ONB-06 | Kuesioner psikis | EP | Kuesioner psikis 20 soal, opsi skor 0–3 | Big Five selesai | 20 pertanyaan | 1) Lanjut ke kuesioner psikis; 2) Amati jumlah soal & opsi jawaban | Tampil 20 pertanyaan; tiap soal punya 4 opsi bernilai skor 0–3 | | | | | | |
| ONB-07 | Psikis wajib lengkap | EG | Lanjut dengan soal belum dijawab | Kuesioner psikis aktif | 1 soal belum dijawab | 1) Jawab 19 soal; 2) Tekan lanjut/selesai | Tidak dapat lanjut sampai seluruh soal terjawab | | | | | | |
| ONB-08 | Skor psikis → kategori | BVA | Konversi skor mentah ke skor tampil (0–100) & kategori | Kuesioner psikis selesai | skor mentah 0, 15, 30, 45, 60 | 1) Selesaikan kuesioner; 2) Amati skor & kategori | `displayScore = ((60 - raw) / 60 × 100).clamp(0,100)`. Kategori: ≥76 Sehat Optimal, 51–75 Cukup, 26–50 Rentan, <26 Butuh Perhatian Klinis | | | | | | |
| ONB-09 | Halaman hasil onboarding | EP | Ringkasan skor, Big Five, & saran | Seluruh kuesioner selesai | tidak ada | 1) Selesaikan semua kuesioner; 2) Amati halaman hasil | Ringkasan skor psikis (0–100), bar chart Big Five dengan dimensi dominan, & rekomendasi personal tampil | | | | | | |
| ONB-10 | Pengulangan Big Five | ST | Ulang kuesioner Big Five dari profil | Akun sudah onboarding | jawaban berbeda | 1) Buka profil → pengulangan Big Five; 2) Isi ulang 20 soal; 3) Simpan | Skor Big Five baru tersimpan & backend terupdate | | | | | | |

### 5.3 Modul HOME — Dashboard

| ID | Fitur | Teknik | Skenario | Prekondisi | Data Uji | Langkah Pengujian | Hasil yang Diharapkan | Hasil Aktual | Status | Tester | Tanggal | Bukti | Catatan |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| HOME-01 | Sapaan dashboard | EP | Dashboard menampilkan nama pengguna | Akun login & onboarding selesai | nama `Sari` | 1) Masuk aplikasi; 2) Amati header | Sapaan dengan nama pengguna tampil dengan benar | | | | | | |
| HOME-02 | Kartu status psikis | BVA | Warna & kategori sesuai rentang skor | Skor psikis tersimpan | skor 100, 76, 51, 26, 0 | 1) Uji user dengan berbagai skor; 2) Amati kartu | 76–100 hijau "Sehat Optimal"; 51–75 kuning "Cukup"; 26–50 oranye "Rentan"; 0–25 merah "Butuh Perhatian" | | | | | | |
| HOME-03 | Statistik cepat | EP | Kartu statistik menampilkan angka benar | Ada data rekaman | 5 rekaman | 1) Buka dashboard; 2) Amati kartu statistik (bento grid) | Jumlah deteksi, emosi dominan, dan skor rata-rata sesuai data | | | | | | |
| HOME-04 | CTA rekam | EP | Tombol rekam membuka layar deteksi | Dashboard tampil | tidak ada | 1) Tekan tombol/tile "Mulai Rekam"; 2) Amati navigasi | Layar Deteksi Emosi terbuka dan perekaman dimulai otomatis | | | | | | |
| HOME-05 | Rekomendasi | EP | Saran tampil sesuai emosi terakhir & Big Five | Ada minimal 1 rekaman | emosi terakhir `sad` | 1) Buka dashboard; 2) Amati bagian rekomendasi | Saran relevan dengan emosi terakhir & profil Big Five pengguna | | | | | | |
| HOME-06 | Riwayat terbaru | EP | Log deteksi terbaru tampil | Ada ≥ 1 rekaman | 3 rekaman | 1) Buka dashboard; 2) Amati daftar riwayat terbaru | Log terbaru tampil dengan emosi, waktu & confidence | | | | | | |
| HOME-07 | Callout keselamatan | EG | Skor rendah menampilkan banner bantuan | Skor psikis < 26 | skor 20 | 1) Login dengan user berskor < 26; 2) Amati dashboard | Banner/rujukan keselamatan dengan aksi (hotline/kontak darurat) tampil | | | | | | |

### 5.4 Modul DET — Deteksi Emosi (Rekam)

| ID | Fitur | Teknik | Skenario | Prekondisi | Data Uji | Langkah Pengujian | Hasil yang Diharapkan | Hasil Aktual | Status | Tester | Tanggal | Bukti | Catatan |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| DET-01 | Perekaman otomatis | ST | Layar deteksi mulai merekam langsung | Kuota tersedia, izin mikrofon aktif | rekaman suara 10 detik | 1) Dari dashboard tekan rekam; 2) Amati indikator "Listening" & timer | Perekaman berjalan otomatis, timer berjalan, indikator merah "Listening..." tampil | | | | | | |
| DET-02 | Animasi waveform | EP | Waveform bergerak saat merekam | Sedang merekam | tidak ada | 1) Amati baris waveform selama perekaman | Batang waveform beranimasi mengikuti amplitudo suara | | | | | | |
| DET-03 | Emosi real-time | EP | Skor emosi diperbarui berkala (~3 detik) | Sedang merekam | berbicara sedih lalu gembira | 1) Bicara dengan intonasi berbeda; 2) Amati skor & emosi tampil | Emosi & persentase skor berubah setiap ~3 detik; total skor = 100% | | | | | | |
| DET-04 | Tombol stop | ST | Menghentikan perekaman & masuk proses | Sedang merekam | rekaman ≥ 5 detik | 1) Tekan tombol stop (lingkaran merah); 2) Amati layar | Panel "Memproses..." dengan progress message (transkripsi → analisis) muncul | | | | | | |
| DET-05 | Transkripsi Whisper | ST | Transkrip model Base → fallback Tiny | Model tersedia / internet untuk unduh | ucapkan "Saya merasa sedih hari ini" | 1) Rekam & berhenti; 2) Amati informasi transkripsi | Model yang dipakai (Base/Tiny) ditampilkan, atau "Transkrip tidak tersedia" jika gagal | | | | | | |
| DET-06 | Analisis gabungan | ST | Skor akhir = audio 60% + teks 40% | Transkripsi berhasil | rekaman suara dengan emosi | 1) Selesaikan deteksi; 2) Amati hasil akhir | Hasil dihitung dengan bobot audio 60% dan teks 40%, lalu menuju halaman Hasil | | | | | | |
| DET-07 | Izin mikrofon ditolak | EG | Deteksi saat izin mikrofon ditolak | Izin mikrofon dimatikan di pengaturan sistem | tidak ada | 1) Buka layar deteksi dengan izin mikrofon ditolak | SnackBar error "gagal memulai rekaman", kembali ke dashboard tanpa crash | | | | | | |
| DET-08 | Chip kuota tersisa | BVA | Chip menampilkan sisa kuota | Kuota hari ini = 5 | 0–5 deteksi terpakai | 1) Buka layar deteksi; 2) Amati chip kuota | Chip menampilkan `x/5`; saat sisa ≤ 2 berwarna merah; premium menampilkan "Unlimited" | | | | | | |
| DET-09 | Kuota habis → iklan reward | BVA | Deteksi ke-6 memicu dialog iklan reward | 5 deteksi gratis habis hari ini | sisa 0 | 1) Lakukan deteksi ke-6; 2) Tekan "Tonton Iklan"; 3) Tonton iklan selesai; 4) Tekan "Mulai Rekam" | Setelah iklan selesai muncul dialog reward "…satu deteksi"; perekaman berjalan | | | | | | |
| DET-10 | Kuota habis → batal | BVA | Membatalkan iklan reward | 5 deteksi gratis habis | sisa 0 | 1) Lakukan deteksi ke-6; 2) Tekan "Batal" pada dialog | Dialog tertutup, aplikasi kembali ke dashboard tanpa merekam | | | | | | |
| DET-11 | Kuota premium | DT | Pengguna premium tidak terbatas | Akun premium aktif | lebih dari 5 deteksi | 1) Dengan akun premium lakukan > 5 deteksi berturut-turut | Deteksi terus berjalan tanpa dialog kuota; chip menampilkan "Unlimited" | | | | | | |
| DET-12 | Aplikasi dibawa ke latar | EG | Meminimalkan app saat merekam | Sedang merekam | tidak ada | 1) Rekam; 2) Tekan home (background); 3) Kembali ke aplikasi | Aplikasi tidak crash; kondisi rekaman ditangani dengan aman | | | | | | |
| DET-13 | Simpan & upload ke server | EG | Data rekaman tersimpan ke backend cPanel | Deteksi selesai | 1 rekaman | 1) Selesaikan deteksi; 2) Periksa riwayat; 3) Periksa database MySQL di cPanel | Record tersimpan di tabel `recordings`, audio WAV ter-upload ke `uploads/` dengan URL tersimpan | | | | | | |
| DET-14 | Snapshot emosi tersimpan | EG | Snapshot 3 detik tercatat | Sedang merekam ≥ 6 detik | tidak ada | 1) Rekam ≥ 6 detik; 2) Periksa tabel `emotion_snapshots` di MySQL | Minimal 2 snapshot tersimpan dengan emotion, confidence, source ('audio'), dan timestamp | | | | | | |
| DET-15 | Trigger tag | EP | User memilih tag pemicu emosi setelah deteksi | Deteksi selesai | tidak ada | 1) Selesaikan deteksi; 2) Pada halaman hasil, pilih trigger tag | Tag tersimpan bersama rekaman (work, romance, finance, health, family, social, other) | | | | | | |

### 5.5 Modul LIVE — Deteksi Emosi (Real-time)

| ID | Fitur | Teknik | Skenario | Prekondisi | Data Uji | Langkah Pengujian | Hasil yang Diharapkan | Hasil Aktual | Status | Tester | Tanggal | Bukti | Catatan |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| LIVE-01 | Deteksi real-time | EP | Emosi terdeteksi dari suara langsung | Izin mikrofon aktif | ucapkan kalimat gembira | 1) Buka layar Live Detection; 2) Bicara; 3) Amati hasil | Emosi terdeteksi diperbarui real-time sesuai intonasi suara | | | | | | |
| LIVE-02 | Tanpa suara | EG | Diam / lingkungan hening | Live detection aktif | lingkungan hening | 1) Buka Live Detection; 2) Jangan berbicara; 3) Amati | Tidak ada emosi dominan (netral), tidak ada crash | | | | | | |
| LIVE-03 | Toggle mulai/henti | ST | Menghentikan dan memulai ulang deteksi | Live detection aktif | tidak ada | 1) Tekan tombol hentikan; 2) Tekan mulai lagi | Deteksi berhenti bersih lalu dapat dimulai ulang tanpa error | | | | | | |
| LIVE-04 | Snapshot berkala | EP | Snapshot emosi tersimpan tiap 3 detik | Live detection aktif, ≥ 6 detik | tidak ada | 1) Jalankan live detection ≥ 6 detik; 2) Periksa backend | Snapshot tersimpan di `emotion_snapshots` dengan interval ~3 detik | | | | | | |
| LIVE-05 | Sumber snapshot | EP | Snapshot mencatat sumber (audio/transcript/combined) | Live detection aktif | tidak ada | 1) Jalankan live detection; 2) Periksa kolom `source` di snapshot | Setiap snapshot memiliki source yang benar ('audio', 'transcript', atau 'combined') | | | | | | |

### 5.6 Modul RS — Halaman Hasil

| ID | Fitur | Teknik | Skenario | Prekondisi | Data Uji | Langkah Pengujian | Hasil yang Diharapkan | Hasil Aktual | Status | Tester | Tanggal | Bukti | Catatan |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RS-01 | Emosi dominan | EP | Hasil menampilkan emosi dominan & confidence | Deteksi selesai | emosi `sad` confidence 0.70 | 1) Selesaikan deteksi; 2) Amati halaman hasil | Emosi dominan & persentase confidence ditampilkan dengan benar | | | | | | |
| RS-02 | Skor gabungan | BVA | Bar skor audio vs teks tampil | Deteksi selesai | audio 0.6, teks 0.4 | 1) Selesaikan deteksi; 2) Amati bagian skor | Skor audio dan teks ditampilkan; total konsisten (≤ 100%) | | | | | | |
| RS-03 | Saran | EP | Rekomendasi sesuai emosi & Big Five | Profil Big Five tersedia | emosi `angry` | 1) Selesaikan deteksi; 2) Amati saran | Saran relevan dengan emosi dominan & skor Big Five pengguna; termasuk layer safety jika ada indikator krisis | | | | | | |
| RS-04 | Trigger tag | EP | Tag pemicu emosi tampil & dapat dipilih | Deteksi selesai | transkrip mengandung kata pemicu | 1) Selesaikan deteksi; 2) Pilih trigger tag | Tag pemicu (work, romance, finance, dll.) tersimpan bersama rekaman | | | | | | |
| RS-05 | Navigasi keluar | EP | Kembali ke dashboard/riwayat | Halaman hasil tampil | tidak ada | 1) Tekan tombol kembali/dashboard | Kembali ke dashboard tanpa error; hasil tersimpan di riwayat | | | | | | |
| RS-06 | Safety/crisis referral | EG | Emosi sangat negatif memicu rujukan keselamatan | Deteksi menunjukkan indikator krisis | emosi `sad` dengan confidence sangat tinggi | 1) Rekam dengan emosi sangat negatif; 2) Amati saran | Layer safety aktif: menampilkan hotline/rujukan darurat alih-alih saran normal | | | | | | |

### 5.7 Modul HST — Riwayat & Statistik

| ID | Fitur | Teknik | Skenario | Prekondisi | Data Uji | Langkah Pengujian | Hasil yang Diharapkan | Hasil Aktual | Status | Tester | Tanggal | Bukti | Catatan |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| HST-01 | Daftar log | EP | Log deteksi tampil terurut | Ada beberapa rekaman | 5 rekaman | 1) Buka menu Riwayat; 2) Amati daftar | Log tampil terurut (terbaru di atas) dengan emosi & waktu | | | | | | |
| HST-02 | Statistik ringkasan | EP | Kartu statistik di bagian atas menampilkan data benar | Ada data rekaman | 5 rekaman | 1) Buka Riwayat; 2) Amati kartu statistik atas | Total rekaman, emosi dominan, dan rata-rata confidence sesuai data | | | | | | |
| HST-03 | Filter "Semua Waktu" | EP | Menampilkan seluruh data | Data lintas tanggal | 3 hari ini, 2 minggu lalu | 1) Buka Riwayat; 2) Pilih filter "Semua Waktu" | Seluruh 5 rekaman ditampilkan | | | | | | |
| HST-04 | Filter "Hari Ini" | EP | Hanya data hari ini | Data hari ini & kemarin | 3 hari ini, 2 kemarin | 1) Pilih filter "Hari Ini" | Hanya 3 rekaman hari ini tampil | | | | | | |
| HST-05 | Filter "7 Hari" | EP | Hanya data 7 hari terakhir | Data 10 hari lalu | 4 data ≤ 7 hari, 1 data 10 hari lalu | 1) Pilih filter "7 Hari" | Hanya 4 rekaman tampil | | | | | | |
| HST-06 | Filter "30 Hari" | EP | Hanya data 30 hari terakhir | Data 40 hari lalu | 1 data 40 hari lalu | 1) Pilih filter "30 Hari" | Rekaman > 30 hari tidak ditampilkan | | | | | | |
| HST-07 | Filter custom | EG | Rentang tanggal kustom | Ada data di luar rentang | 1–5 Juni, data 10 Juni | 1) Pilih "Kustom"; 2) Pilih rentang 1–5 Juni | Hanya data dalam rentang tampil; label chip menampilkan rentang | | | | | | |
| HST-08 | Filter emosi | EP | Chip emosi menyaring log | Data berbagai emosi | 3 happy, 2 sad | 1) Tekan chip "Sedih"; 2) Amati daftar | Hanya log emosi "Sedih" tampil | | | | | | |
| HST-09 | Grafik tren mingguan | EP | Line chart tren emosi tampil | Data ≥ 7 hari | 7 data | 1) Buka Riwayat; 2) Amati grafik | Grafik garis mingguan (fl_chart) dengan data benar & tooltip berfungsi | | | | | | |
| HST-10 | Data kosong | EG | Riwayat tanpa data | Akun baru tanpa rekaman | tidak ada | 1) Buka Riwayat akun baru | Empty state "Belum ada rekaman" tanpa error | | | | | | |
| HST-11 | Pencarian log | EP | Cari berdasarkan teks/emosi | Banyak log | ketik `sad` | 1) Buka log lengkap; 2) Ketik kata kunci di kolom cari | Log yang cocok ditampilkan; tombol clear mengosongkan pencarian | | | | | | |

### 5.8 Modul RCD — Detail Rekaman

| ID | Fitur | Teknik | Skenario | Prekondisi | Data Uji | Langkah Pengujian | Hasil yang Diharapkan | Hasil Aktual | Status | Tester | Tanggal | Bukti | Catatan |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RCD-01 | Detail rekaman | EP | Semua informasi rekaman tampil | Minimal 1 rekaman | 1 rekaman | 1) Buka Riwayat; 2) Ketuk salah satu log | Detail tampil: emosi, confidence, tanggal, durasi, saran, trigger tag | | | | | | |
| RCD-02 | Transkrip & fallback | DT | Transkrip tampil; jika kosong tampil fallback | Rekaman dengan & tanpa transkrip | rekaman tanpa transkrip | 1) Buka detail rekaman tanpa transkrip; 2) Amati bagian transkrip | Jika transkrip ada, teks ditampilkan. Jika kosong, muncul info "tidak ada transkrip" tanpa error | | | | | | |
| RCD-03 | Grafik distribusi emosi | EP | Bar chart emosi tampil | Rekaman memiliki skor | 1 rekaman | 1) Buka detail; 2) Amati grafik | Bar chart distribusi emosi (audio) ditampilkan dengan benar | | | | | | |
| RCD-04 | Perbandingan audio vs teks | EP | Perbandingan skor dua sumber | Rekaman dengan transkrip | 1 rekaman | 1) Buka detail; 2) Amati bagian perbandingan | Skor audio (mikrofon) dan teks (transkrip) ditampilkan berdampingan | | | | | | |
| RCD-05 | Grafik radar | EP | Radar chart tampil (jika tersedia) | Rekaman memiliki skor | 1 rekaman | 1) Buka detail; 2) Amati radar chart | Radar chart proporsi emosi ditampilkan | | | | | | |

### 5.9 Modul PRF — Profil

| ID | Fitur | Teknik | Skenario | Prekondisi | Data Uji | Langkah Pengujian | Hasil yang Diharapkan | Hasil Aktual | Status | Tester | Tanggal | Bukti | Catatan |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| PRF-01 | Tampil profil | EP | Profil menampilkan data pengguna | Akun login | nama `Sari` | 1) Buka Pengaturan → Profil | Nama, email & foto profil tampil benar | | | | | | |
| PRF-02 | Skor Big Five | EP | Lima dimensi OCEAN tampil | Profil dengan Big Five tersimpan | tidak ada | 1) Buka profil; 2) Amati bagian Big Five | Lima dimensi (Openness, Conscientiousness, Extraversion, Agreeableness, Neuroticism) dengan skor 1.0–5.0 tampil | | | | | | |
| PRF-03 | Skor psikis | EP | Skor & kategori psikis tampil | Profil dengan skor psikis tersimpan | tidak ada | 1) Buka profil; 2) Amati bagian skor psikis | Skor 0–100 & kategori (Sehat Optimal/Cukup/Rentan/Butuh Perhatian) tampil | | | | | | |
| PRF-04 | Edit nama (validasi) | BVA | Nama kosong ditolak; nama valid diterima | Halaman profil tampil | nama kosong; `Sari` | 1) Edit nama → kosongkan → simpan; 2) Isi `Sari` → simpan | Nama kosong menampilkan pesan validasi; nama valid tersimpan & SnackBar sukses | | | | | | |
| PRF-05 | Ganti foto profil | EP | Foto diambil dari galeri | Izin galeri aktif | gambar 1 MB | 1) Ketuk avatar; 2) Pilih galeri; 3) Pilih foto; 4) Simpan | Foto profil berubah sesuai gambar terpilih | | | | | | |
| PRF-06 | Hapus foto profil | EG | Menghapus foto kembali ke default | Ada foto profil | tidak ada | 1) Ketuk avatar; 2) Pilih "Hapus Foto" | Foto terhapus & kembali ke avatar default | | | | | | |
| PRF-07 | Navigasi ke retake Big Five | ST | Tautan pengulangan Big Five dari profil | Profil tampil | tidak ada | 1) Ketuk tautan "Ulangi Big Five"; 2) Amati navigasi | Layar BigFiveRetakeScreen terbuka | | | | | | |
| PRF-08 | Persistensi | ST | Perubahan profil bertahan setelah restart | Profil diedit | nama baru | 1) Ubah nama/foto; 2) Tutup & buka aplikasi lagi | Perubahan profil tetap tersimpan | | | | | | |

### 5.10 Modul STG — Pengaturan

| ID | Fitur | Teknik | Skenario | Prekondisi | Data Uji | Langkah Pengujian | Hasil yang Diharapkan | Hasil Aktual | Status | Tester | Tanggal | Bukti | Catatan |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| STG-01 | Bahasa | ST | Beralih ID ↔ EN dan kembali | Pengaturan tampil | `en` lalu `id` | 1) Pilih "EN"; 2) Amati seluruh teks UI; 3) Kembali ke "ID" | Seluruh teks UI berubah ke bahasa Inggris; kembali ke Indonesia sesuai pilihan (persisten) | | | | | | |
| STG-02 | Tema | ST | Beralih Light ↔ Dark | Pengaturan tampil | tema dark lalu light | 1) Pilih "Gelap"; 2) Amati seluruh layar; 3) Kembali "Terang" | Seluruh layar berubah tema gelap/terang konsisten & persisten | | | | | | |
| STG-03 | Pengingat harian | ST | Aktifkan & atur waktu pengingat | Pengaturan tampil | pukul 19:00 | 1) Aktifkan toggle pengingat; 2) Atur waktu; 3) Amati SnackBar | Notifikasi dijadwalkan sesuai waktu; SnackBar konfirmasi tampil | | | | | | |
| STG-04 | Matikan pengingat | ST | Nonaktifkan pengingat harian | Pengingat aktif | tidak ada | 1) Matikan toggle pengingat | Notifikasi dibatalkan; toggle kembali nonaktif | | | | | | |
| STG-05 | Panduan aplikasi | EP | Bottom sheet panduan tampil | Pengaturan tampil | tidak ada | 1) Ketuk "Panduan Aplikasi" | Bottom sheet dengan 4 langkah panduan tampil (rekam, analisis, lihat hasil, dapatkan saran) | | | | | | |
| STG-06 | Terms of Service | EP | Bottom sheet syarat & ketentuan | Pengaturan tampil | tidak ada | 1) Ketuk "Syarat & Ketentuan" | Bottom sheet dengan konten terms tampil tanpa error | | | | | | |
| STG-07 | Privacy Policy | EP | Bottom sheet kebijakan privasi | Pengaturan tampil | tidak ada | 1) Ketuk "Kebijakan Privasi" | Bottom sheet dengan konten privasi tampil | | | | | | |
| STG-08 | Backup data | EP | Ekspor data ke berkas JSON | Ada data rekaman | 2 rekaman | 1) Ketuk "Backup Data"; 2) Pilih lokasi penyimpanan; 3) Konfirmasi | Berkas JSON berhasil dibuat berisi data user & rekaman; dialog sukses tampil | | | | | | |
| STG-09 | Restore data | EG | Mengembalikan data dari berkas backup | Berkas backup tersedia | berkas `fem_psych_backup.json` | 1) Ketuk "Pulihkan Data"; 2) Pilih berkas backup; 3) Konfirmasi | Data dipulihkan; riwayat muncul setelah restart | | | | | | |
| STG-10 | Hapus akun | EG | Hapus akun dengan konfirmasi | Akun login | tidak ada | 1) Ketuk "Hapus Akun"; 2) Konfirmasi di dialog | Dialog konfirmasi tampil; setelah konfirmasi akun terhapus & kembali ke layar login | | | | | | |
| STG-11 | Logout | ST | Keluar dari aplikasi | Akun login | tidak ada | 1) Ketuk "Keluar"; 2) Konfirmasi | Kembali ke layar login | | | | | | |
| STG-12 | Tile premium | DT | Tile upgrade/premium sesuai status | Akun non-premium & premium | 2 akun | 1) Non-premium: amati tile; 2) Premium: amati tile | Non-premium: "Upgrade ke Premium"; premium: status aktif dengan sisa waktu | | | | | | |

### 5.11 Modul PRM — Premium

| ID | Fitur | Teknik | Skenario | Prekondisi | Data Uji | Langkah Pengujian | Hasil yang Diharapkan | Hasil Aktual | Status | Tester | Tanggal | Bukti | Catatan |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| PRM-01 | Daftar paket | EP | Tiga paket tampil dengan harga dari Play Store | Akun non-premium | tidak ada | 1) Buka layar Premium; 2) Amati paket | Paket Mingguan, Bulanan, Tahunan tampil dengan harga dari Google Play (dynamis) | | | | | | |
| PRM-02 | Pilih paket | EP | Pemilihan paket menyorot kartu | Layar premium tampil | pilih Tahunan | 1) Ketuk kartu Tahunan | Kartu terpilih tersorot (border/glow berbeda); tag "Populer" pada paket tahunan | | | | | | |
| PRM-03 | Harga efektif | EP | Tahunan menampilkan harga efektif per bulan | Paket tahunan & bulanan tersedia | tidak ada | 1) Amati paket Tahunan; 2) Amati baris harga efektif | Harga efektif per bulan (tahunan ÷ 12) ditampilkan; badge "Hemat X%" tampil | | | | | | |
| PRM-04 | Langganan berhasil | ST | Pembelian via Google IAP berhasil | Sandbox purchase aktif | paket tersedia | 1) Pilih paket; 2) Tekan "Langganan Sekarang"; 3) Selesaikan pembayaran sandbox | Dialog "Berhasil" & status premium aktif (verifikasi server-side via Google Play Developer API) | | | | | | |
| PRM-05 | Pembelian dibatalkan | EG | Membatalkan dialog pembayaran | Sheet pembayaran tampil | Batal | 1) Tekan "Langganan Sekarang"; 2) Batalkan pembayaran | SnackBar "Pembelian dibatalkan"; status premium tidak berubah | | | | | | |
| PRM-06 | Restore pembelian | ST | Mengembalikan langganan yang sudah dibeli | Langganan aktif di akun Google | tidak ada | 1) Tekan ikon restore (panah melingkar); 2) Selesaikan konfirmasi | Dialog "Pembelian dipulihkan" tampil & status premium aktif | | | | | | |
| PRM-07 | Countdown premium | DT | Hitung mundur hingga berakhir tampil | Premium aktif dengan expiry | expiry besok | 1) Buka layar premium dengan status aktif | Blok "Aktif", hitung mundur Hari/Jam/Menit/Detik & tanggal berakhir | | | | | | |
| PRM-08 | Manfaat premium | EP | Daftar manfaat tampil | Premium tampil | tidak ada | 1) Amati bagian manfaat | Manfaat (deteksi tanpa batas & bebas iklan) ditampilkan | | | | | | |

### 5.12 Modul ADM — Dashboard Admin

| ID | Fitur | Teknik | Skenario | Prekondisi | Data Uji | Langkah Pengujian | Hasil yang Diharapkan | Hasil Aktual | Status | Tester | Tanggal | Bukti | Catatan |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| ADM-01 | Login admin | DT | Login akun admin menuju dashboard admin | Akun admin (`is_admin=1` di MySQL) | `admin@example.com` | 1) Login dengan akun admin; 2) Amati navigasi | SnackBar "Admin login successful" & dashboard Admin terbuka | | | | | | |
| ADM-02 | Statistik admin | EP | Kartu statistik menampilkan angka benar | Ada data user & rekaman | 3 user, 10 rekaman | 1) Buka dashboard admin; 2) Amati kartu | Total Pengguna, Rata-rata Skor, Total Rekaman sesuai data MySQL | | | | | | |
| ADM-03 | Distribusi emosi | EP | Grafik distribusi emosi tampil | Ada rekaman berbagai emosi | 4 happy, 3 sad | 1) Amati bagian "Distribusi Emosi" | Bar chart distribusi emosi dengan jumlah & persentase benar | | | | | | |
| ADM-04 | Status kesehatan mental | BVA | Kategori status sesuai rentang skor | User dengan skor bervariasi | skor 80, 60, 30, 10 | 1) Amati kartu "Status Kesehatan Mental" | Kategori: 76–100 Sehat Optimal, 51–75 Cukup, 26–50 Rentan, 0–25 Butuh Perhatian | | | | | | |
| ADM-05 | Pencarian user | EP | Pencarian berdasarkan nama | Banyak user terdaftar | ketik `Sari` | 1) Ketik nama di kolom cari; 2) Amati daftar; 3) Tekan ikon clear | Hanya user yang cocok tampil; clear mengembalikan seluruh daftar | | | | | | |
| ADM-06 | Detail user | EP | Membuka detail user, rekaman, & PDF | User memiliki rekaman | 1 user, 1 rekaman | 1) Ketuk item user; 2) Amati detail; 3) Tekan ikon PDF | Detail user (skor, Big Five, rekaman) tampil; PDF laporan dihasilkan | | | | | | |
| ADM-07 | Export PDF | EG | Ekspor laporan seluruh pengguna | Ada ≥ 1 user | tidak ada | 1) Tekan ikon PDF pada header; 2) Bagikan/simpan | Berkas PDF dihasilkan & siap dibagikan; tanpa data: SnackBar "Tidak ada data untuk di-export" | | | | | | |
| ADM-08 | Logout admin | ST | Keluar dari mode admin | Dashboard admin tampil | tidak ada | 1) Tekan ikon logout; 2) Konfirmasi dialog | Kembali ke layar login dengan benar | | | | | | |

### 5.13 Modul NTI — Notifikasi

| ID | Fitur | Teknik | Skenario | Prekondisi | Data Uji | Langkah Pengujian | Hasil yang Diharapkan | Hasil Aktual | Status | Tester | Tanggal | Bukti | Catatan |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| NTI-01 | Aktifkan pengingat | ST | Toggle pengingat menyala & izin diminta | Pengaturan tampil, izin belum diberikan | tidak ada | 1) Aktifkan toggle pengingat; 2) Berikan izin notifikasi | Dialog izin notifikasi muncul; setelah izin, pengingat aktif & SnackBar konfirmasi | | | | | | |
| NTI-02 | Izin ditolak | EG | Izin notifikasi ditolak | Pengaturan tampil | tidak ada | 1) Aktifkan toggle; 2) Tolak izin | SnackBar "Izin notifikasi ditolak"; toggle tetap nonaktif | | | | | | |
| NTI-03 | Atur waktu pengingat | ST | Mengatur waktu pengingat | Pengingat aktif | pukul 08:00 | 1) Ketuk tile waktu; 2) Pilih 08:00; 3) Konfirmasi | Waktu berubah ke 08:00; notifikasi dijadwalkan ulang sesuai waktu baru | | | | | | |
| NTI-04 | Matikan pengingat | ST | Nonaktifkan pengingat | Pengingat aktif | tidak ada | 1) Matikan toggle pengingat | Semua notifikasi terjadwal dibatalkan; toggle nonaktif | | | | | | |
| NTI-05 | Notifikasi masuk tepat waktu | EG | Notifikasi muncul sesuai waktu yang diatur | Pengingat aktif, waktu 2 menit lagi | pukul sekarang + 2 menit | 1) Atur waktu pengingat 2 menit dari sekarang; 2) Tunggu | Notifikasi muncul tepat waktu dengan pesan pengingat | | | | | | |
| NTI-06 | Persistensi pengingat | ST | Pengaturan pengingat bertahan setelah restart | Pengingat diaktifkan pada pukul 19:00 | tidak ada | 1) Aktifkan & atur waktu 19:00; 2) Tutup & buka aplikasi; 3) Buka Pengaturan | Toggle tetap aktif & waktu tetap 19:00 | | | | | | |

### 5.14 Modul SYS — Sistem & Perangkat

| ID | Fitur | Teknik | Skenario | Prekondisi | Data Uji | Langkah Pengujian | Hasil yang Diharapkan | Hasil Aktual | Status | Tester | Tanggal | Bukti | Catatan |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| SYS-01 | Peluncuran pertama | ST | Onboarding muncul saat pertama kali | Aplikasi baru diinstall | tidak ada | 1) Install & buka aplikasi pertama kali; 2) Tutup; 3) Buka kembali | Onboarding tampil pada peluncuran pertama; tidak muncul lagi setelah selesai | | | | | | |
| SYS-02 | Orientasi layar | EG | Rotasi perangkat tidak mengacaukan UI | Aplikasi terbuka | tidak ada | 1) Buka beberapa layar; 2) Putar perangkat 90°/180° | Layar tetap portrait, layout tidak berantakan saat rotasi | | | | | | |
| SYS-03 | Tanpa internet | EG | Membuka aplikasi saat offline | Mode pesawat aktif | tidak ada | 1) Aktifkan mode pesawat; 2) Buka aplikasi; 3) Buka riwayat/deteksi | Aplikasi tidak crash; pesan koneksi ditampilkan saat membutuhkan backend | | | | | | |
| SYS-04 | Persistensi data | ST | Data tetap ada setelah restart | Ada data onboarding & rekaman | 2 rekaman | 1) Tutup aplikasi; 2) Buka kembali; 3) Periksa dashboard & riwayat | Data (skor, riwayat, pengaturan) tetap tersimpan | | | | | | |
| SYS-05 | Unduhan model Whisper | EG | Model diunduh saat deteksi pertama | Internet aktif, model belum ada | tidak ada | 1) Buka deteksi pertama kali; 2) Amati progress unduhan | Model diunduh dengan progress; tanpa internet: pesan "Internet diperlukan untuk mengunduh model suara" | | | | | | |
| SYS-06 | Izin aplikasi | EG | Dialog izin perangkat muncul benar | Aplikasi baru diinstall | mikrofon & galeri | 1) Buka deteksi → izin mikrofon; 2) Ubah foto profil → izin galeri | Dialog izin sistem muncul sesuai fitur; penolakan ditangani tanpa crash | | | | | | |
| SYS-07 | Config dari .env | EG | Aplikasi membaca konfigurasi dari .env | File `.env` tersedia | tidak ada | 1) Jalankan aplikasi; 2) Gunakan fitur yang membutuhkan API (login, rekam, premium) | API base URL, API key, product ID IAP, dan AdMob ID dimuat dari `.env` tanpa error | | | | | | |
| SYS-08 | Admin seed otomatis | DT | Admin pertama di-seed dari .env saat startup | Tidak ada admin di database | `ADMIN_EMAIL` & `ADMIN_PASSWORD` di `.env` | 1) Jalankan aplikasi untuk pertama kali dengan `.env` berisi kredensial admin; 2) Login sebagai admin | Admin pertama otomatis dibuat di backend; login berhasil & dashboard admin tampil | | | | | | |

---

## 6. Rekapitulasi Hasil Pengujian

Tabel berikut diisi oleh QA Lead setelah seluruh kasus uji dieksekusi. Saat ini seluruh nilai **0** (template belum dieksekusi).

| No | Modul | Jumlah Kasus Uji | PASS | FAIL | BLOCKED |
|---|---|---|---|---|---|
| 1 | AUTH — Autentikasi | 15 | 0 | 0 | 0 |
| 2 | ONB — Onboarding | 10 | 0 | 0 | 0 |
| 3 | HOME — Dashboard | 7 | 0 | 0 | 0 |
| 4 | DET — Deteksi Emosi (Rekam) | 15 | 0 | 0 | 0 |
| 5 | LIVE — Deteksi Real-time | 5 | 0 | 0 | 0 |
| 6 | RS — Halaman Hasil | 6 | 0 | 0 | 0 |
| 7 | HST — Riwayat & Statistik | 11 | 0 | 0 | 0 |
| 8 | RCD — Detail Rekaman | 5 | 0 | 0 | 0 |
| 9 | PRF — Profil | 8 | 0 | 0 | 0 |
| 10 | STG — Pengaturan | 12 | 0 | 0 | 0 |
| 11 | PRM — Premium | 8 | 0 | 0 | 0 |
| 12 | ADM — Dashboard Admin | 8 | 0 | 0 | 0 |
| 13 | NTI — Notifikasi | 6 | 0 | 0 | 0 |
| 14 | SYS — Sistem & Perangkat | 8 | 0 | 0 | 0 |
| | **Total** | **113** | **0** | **0** | **0** |

## 7. Format Pelaporan Bug

Setiap cacat yang ditemukan wajib dilaporkan menggunakan format berikut:

| Kolom | Keterangan |
|---|---|
| ID Bug | `BUG-<nomor>` (contoh: `BUG-001`) |
| ID Kasus Uji Terkait | Contoh: `DET-07` |
| Modul | Nama modul tempat cacat ditemukan |
| Judul Bug | Ringkasan singkat satu kalimat |
| Langkah Reproduksi | 1) ... 2) ... 3) ... |
| Hasil Aktual | Perilaku yang diamati |
| Hasil yang Diharapkan | Perilaku yang seharusnya |
| Prioritas / Severity | Critical / High / Medium / Low |
| Bukti | Lampiran screenshot/rekaman (`docs/bukti/BUG-001.png`) |
| Status | New / In Progress / Fixed / Verified / Closed |
| Ditemukan Oleh / Tanggal | Nama tester & tanggal |

## 8. Lembar Pengesahan

Dokumen ini dinyatakan sah dan disetujui setelah seluruh kasus uji (113 kasus) dieksekusi dan direkap pada Bab 6.

| | Nama | Jabatan | Tanda Tangan | Tanggal |
|---|---|---|---|---|
| Disiapkan oleh | | Tester | | |
| Direview oleh | | QA Lead / Supervisor | | |
| Disetujui oleh | | Project Manager / Dosen Pembimbing | | |

---

*Dokumen ini merupakan template pengujian blackbox manual. Seluruh kolom hasil (Hasil Aktual, Status, Nama Tester, Tanggal Pengujian, Bukti/Lampiran, Catatan/Kendala) sengaja dikosongkan dan diisi oleh tester manusia saat pelaksanaan pengujian.*
