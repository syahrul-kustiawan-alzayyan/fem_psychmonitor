# Dokumentasi Blackbox Testing — Fem-Psych Monitor

**Aplikasi:** Fem-Psych Monitor v2.1.5+8
**Platform:** Flutter (Android / iOS)
**Metode:** Blackbox Testing (pengujian kotak hitam / fungsional) oleh tester manusia
**Status:** **Template** — kolom *Hasil Aktual*, *Status*, *Nama Tester*, *Tanggal Pengujian*, *Bukti/Lampiran*, dan *Catatan/Kendala* dikosongkan dan siap diisi oleh tester.

---

## 1. Pendahuluan

Dokumen ini berisi rencana dan format pelaksanaan **blackbox testing** (pengujian kotak hitam / fungsional) untuk aplikasi Fem-Psych Monitor. Berbeda dengan whitebox testing (lihat `docs/WHITEBOX_TESTING.md`) yang menganalisis struktur internal kode, blackbox testing memperlakukan aplikasi sebagai **kotak hitam**: pengujian dilakukan pada level fungsional melalui antarmuka pengguna (UI) oleh **tester manusia**, tanpa melihat implementasi kode.

Tujuan blackbox testing ini adalah:

1. Memverifikasi bahwa setiap fungsi aplikasi berperilaku sesuai **spesifikasi kebutuhan** dari sudut pandang pengguna akhir.
2. Menjamin kualitas fungsional seluruh modul: autentikasi, onboarding, dashboard, deteksi emosi (rekam & real-time), riwayat, detail rekaman, profil, pengaturan, premium, dan dashboard admin.
3. Menguji integrasi dengan layanan eksternal yang tidak dapat diuji secara otomatis: **Firebase Authentication**, **Cloud Firestore**, **Firebase Storage**, **Whisper (transkripsi lokal)**, **RevenueCat (langganan)**, **iklan reward (AdMob)**, serta perangkat keras (**mikrofon**, **galeri/kamera**).
4. Menyediakan template kasus uji lengkap beserta mekanisme pelaporan bug dan rekapitulasi hasil.

## 2. Ruang Lingkup

Modul yang diuji (13 modul, 102 kasus uji):

| No | Kode Modul | Modul / Fitur | Ruang Lingkup |
|---|---|---|---|
| 1 | AUTH | Autentikasi | Login/registrasi email & password, Google Sign-In, verifikasi email, reset password, kebijakan privasi |
| 2 | ONB | Onboarding | Welcome, kuesioner Big Five (MiniIPIP20), kuesioner psikis, halaman hasil, pengulangan asesmen |
| 3 | HOME | Dashboard | Sapaan, kartu status psikis, statistik cepat, CTA rekam, rekomendasi, riwayat terbaru |
| 4 | DET | Deteksi Emosi (Rekam) | Perekaman suara, transkripsi Whisper, analisis emosi, kuota harian, upload audio |
| 5 | LIVE | Deteksi Emosi (Real-time) | Deteksi emosi real-time melalui mikrofon |
| 6 | RS | Halaman Hasil | Skor emosi gabungan (audio 60% : teks 40%), saran, trigger tag |
| 7 | HST | Riwayat & Statistik | Daftar log, filter waktu & emosi, grafik tren mingguan, log lengkap |
| 8 | RCD | Detail Rekaman | Rincian satu rekaman, transkrip, perbandingan skor |
| 9 | PRF | Profil | Tampilan profil, edit nama, foto profil |
| 10 | STG | Pengaturan | Bahasa, tema, panduan, terms, backup/restore, hapus akun, logout |
| 11 | PRM | Premium | Paket langganan, pembelian (RevenueCat), restore, reset, status premium |
| 12 | ADM | Dashboard Admin | Login admin, statistik, distribusi emosi, pencarian, detail user, ekspor PDF |
| 13 | SYS | Sistem & Perangkat | Peluncuran pertama, orientasi layar, konektivitas, persistensi, izin perangkat |

## 3. Lingkungan Pengujian

### 3.1 Perangkat Uji (disarankan diisi tester)

| Parameter | Spesifikasi |
|---|---|
| Perangkat | *(isi, misal: Samsung Galaxy A54, iPhone 13, Android Emulator Pixel 7)* |
| Sistem Operasi | *(isi, misal: Android 14 / iOS 17)* |
| Versi Aplikasi | v2.1.5+8 (build 8) |
| Koneksi | Wi-Fi / Data seluler (internet aktif untuk Firebase, langganan, dan unduhan model) |
| Akun Uji | *(isi: email & password akun tester)* |

### 3.2 Ketergantungan Layanan

| Layanan | Kebutuhan | Dapat Diuji Otomatis? |
|---|---|---|
| Firebase Authentication | Koneksi internet | Tidak |
| Cloud Firestore | Koneksi internet | Tidak |
| Firebase Storage | Koneksi internet | Tidak |
| Whisper (model Base & Tiny) | Unduhan pertama kali (internet), pemrosesan lokal | Tidak |
| RevenueCat (langganan) | Produk terkonfigurasi di sandbox | Tidak |
| Iklan reward (AdMob) | ID unit iklan aktif | Tidak |
| Mikrofon | Izin perangkat | Tidak |
| Galeri / Kamera | Izin perangkat | Tidak |

## 4. Prosedur Pelaksanaan

### 4.1 Peran dan Tanggung Jawab

- **Tester** mengisi kolom *Hasil Aktual*, *Status* (PASS/FAIL/BLOCKED), *Nama Tester*, *Tanggal Pengujian*, *Bukti/Lampiran*, dan *Catatan/Kendala*.
- **Developer** memperbaiki cacat yang dilaporkan pada *Format Pelaporan Bug* (Bab 7).
- **QA Lead / Supervisor** merekap hasil pada Bab 6 dan menandatangani Lembar Pengesahan (Bab 8).

### 4.2 Teknik Desain Kasus Uji

| Kode | Teknik | Penerapan pada Aplikasi |
|---|---|---|
| EP | Equivalence Partitioning (Partisi Ekuivalensi) | Mengelompokkan data uji valid/invalid: format email, panjang password, pilihan jawaban kuesioner, filter waktu riwayat |
| BVA | Boundary Value Analysis (Analisis Nilai Batas) | Nilai batas: panjang password (5/6 karakter), kuota deteksi harian (0/5), batas kategori skor psikis (25/26, 50/51, 75/76, 100) |
| DT | Decision Table (Tabel Keputusan) | Kombinasi kondisi-aksi login (akun baru/lama, terverifikasi/belum, Google/password) dan status premium |
| EG | Error Guessing (Tebakan Kesalahan) | Kondisi abnormal: offline, izin ditolak, pembayaran dibatalkan, data kosong, pengunduhan model gagal |
| ST | State Transition (Transisi Status) | Alur status: rekam → proses → hasil; onboarding → dashboard; non-premium → premium → reset |

### 4.3 Konvensi Penulisan Kasus Uji

- **ID Kasus Uji** mengikuti pola `KODE_MODUL-NO` (contoh: `AUTH-01`, `DET-07`).
- Kolom **Langkah Pengujian** ditulis nomor demi nomor (1) 2) 3) ...) sesuai urutan eksekusi tester.
- Kolom **Data Uji** berisi nilai konkret yang wajib dimasukkan tester.
- Kolom **Bukti/Lampiran** diisi nama berkas bukti (screenshot/rekaman layar), konvensi: `docs/bukti/<ID_KASUS>.png` (contoh: `docs/bukti/AUTH-01.png`).

### 4.4 Aturan Pengisian Kolom Hasil

- **Hasil Aktual**: tuliskan apa yang benar-benar diamati tester saat menjalankan kasus uji.
- **Status**: `PASS` (sesuai hasil yang diharapkan), `FAIL` (tidak sesuai), atau `BLOCKED` (tidak dapat dieksekusi karena kendala lingkungan).
- **Catatan/Kendala**: tuliskan kendala teknis, lingkungan, atau prasyarat yang memengaruhi hasil.
- **Tidak ada status yang diisi otomatis**; seluruh penilaian dilakukan tester manusia.

---

## 5. Rincian Kasus Uji per Modul

### 5.1 Modul AUTH — Autentikasi

| ID Kasus Uji | Modul/Fitur | Teknik | Skenario | Prekondisi | Data Uji | Langkah Pengujian | Hasil yang Diharapkan | Hasil Aktual | Status | Nama Tester | Tanggal Pengujian | Bukti/Lampiran | Catatan/Kendala |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| AUTH-01 | Login sukses | EP | Login dengan email & password akun terdaftar | Akun uji terdaftar & email terverifikasi | `tester@example.com` / `Test1234` | 1) Buka aplikasi; 2) Centang kebijakan privasi; 3) Isi email & password; 4) Tekan "Masuk" | Tampil SnackBar "Login berhasil" lalu masuk ke dashboard (Halaman Utama) | | | | | | |
| AUTH-02 | Password salah | DT | Login dengan password salah pada akun terdaftar | Akun terdaftar dengan password `Test1234` | `tester@example.com` / `Salah123` | 1) Centang privasi; 2) Isi email benar & password salah; 3) Tekan "Masuk" | Muncul dialog "Email/Password Salah" dan tidak masuk aplikasi | | | | | | |
| AUTH-03 | Registrasi otomatis | EP | Email baru belum terdaftar | Belum ada akun dengan email uji | `baru@example.com` / `Test1234` | 1) Centang privasi; 2) Isi email baru; 3) Tekan "Masuk" | Muncul dialog verifikasi email (email dikirim) atau dialog "Lengkapi Data Diri" menuju onboarding | | | | | | |
| AUTH-04 | Validasi email kosong | EP | Submit tanpa mengisi email | Form login tampil | email kosong | 1) Centang privasi; 2) Biarkan email kosong; 3) Tekan "Masuk" | Muncul pesan "Email wajib diisi" dan tidak ada permintaan jaringan | | | | | | |
| AUTH-05 | Validasi password kosong | EP | Submit tanpa mengisi password | Form login tampil | password kosong | 1) Centang privasi; 2) Isi email valid; 3) Tekan "Masuk" | Muncul pesan "Password wajib diisi" | | | | | | |
| AUTH-06 | Format email tidak valid | EP | Email tanpa `@` atau tanpa titik | Form login tampil | `email.salah` | 1) Isi email `email.salah`; 2) Isi password; 3) Tekan "Masuk" | Muncul pesan "Format email tidak valid" | | | | | | |
| AUTH-07 | Batas panjang password | BVA | Password 5 karakter (batas bawah) | Form login tampil | `abc12` dan `abc123` | 1) Isi password `abc12`, tekan "Masuk" → harap muncul "Minimal 6 karakter"; 2) Ganti `abc123` lalu tekan "Masuk" → validasi terlewati | Password 5 karakter ditolak; password 6 karakter lolos validasi form | | | | | | |
| AUTH-08 | Wajib centang privasi | EG | Menekan Masuk/Google tanpa centang kebijakan | Form login tampil, checkbox belum dicentang | tanpa centang | 1) Jangan centang kebijakan; 2) Tekan "Masuk"; 3) Tekan "Lanjutkan dengan Google" | Muncul SnackBar "Centang kebijakan privasi terlebih dahulu" pada kedua tombol | | | | | | |
| AUTH-09 | Google Sign-In | EP | Login dengan akun Google | Akun Google tersedia di perangkat | akun Google uji | 1) Centang privasi; 2) Tekan "Lanjutkan dengan Google"; 3) Pilih akun Google; 4) Konfirmasi | Login sukses → dashboard (akun lama) atau onboarding (akun baru) | | | | | | |
| AUTH-10 | Verifikasi email (3 tahap) | ST | Akun baru: email belum diverifikasi lalu diverifikasi | Email uji baru, belum diverifikasi | `baru@example.com` | 1) Registrasi email baru; 2) Buka email & klik tautan verifikasi; 3) Kembali ke aplikasi; 4) Dialog verifikasi memeriksa ulang | Setelah verifikasi, aplikasi otomatis masuk & melanjutkan onboarding/dashboard | | | | | | |
| AUTH-11 | Email terdaftar via Google | DT | Login password untuk email yang terdaftar via Google | Email uji pernah daftar via Google | `google@example.com` | 1) Isi email tsb + password apa pun; 2) Tekan "Masuk" | Muncul dialog "Akun Terdaftar dengan Google" dengan arahan masuk via Google | | | | | | |
| AUTH-12 | Reset password | DT | Email terdaftar via password, password salah | Akun terdaftar via password | `tester@example.com` / password salah | 1) Isi email terdaftar + password salah; 2) Tekan "Masuk"; 3) Pada dialog "Email Sudah Terdaftar" tekan "Kirim Reset Password" | Muncul SnackBar "Email reset password terkirim!" dan email reset diterima | | | | | | |
| AUTH-13 | Koneksi gagal | EG | Login saat tanpa internet | Mode pesawat/offline aktif | `tester@example.com` / `Test1234` | 1) Aktifkan mode pesawat; 2) Login seperti biasa | Muncul dialog "Koneksi Gagal — Tidak dapat terhubung ke server" | | | | | | |
| AUTH-14 | Terlalu banyak percobaan | EG | Percobaan login salah berkali-kali | Lebih dari batas percobaan login | password salah × 10 | 1) Login salah berulang kali | Muncul dialog "Terlalu Banyak Percobaan" dan aplikasi memblokir sementara | | | | | | |
| AUTH-15 | Toggle tampil password | EP | Menampilkan & menyembunyikan password | Form login tampil | `Test1234` | 1) Isi password; 2) Tekan ikon mata; 3) Tekan lagi | Teks password tampil saat ikon "visibility", tersembunyi kembali saat ikon "visibility_off" | | | | | | |

### 5.2 Modul ONB — Onboarding

| ID Kasus Uji | Modul/Fitur | Teknik | Skenario | Prekondisi | Data Uji | Langkah Pengujian | Hasil yang Diharapkan | Hasil Aktual | Status | Nama Tester | Tanggal Pengujian | Bukti/Lampiran | Catatan/Kendala |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| ONB-01 | Halaman welcome | EP | Akun baru membuka onboarding | Login akun baru sukses | nama `Sari` | 1) Buka aplikasi akun baru; 2) Amati halaman awal onboarding | Tampil halaman selamat datang dengan tombol mulai | | | | | | |
| ONB-02 | Validasi nama | BVA | Nama kosong / 1 karakter | Halaman welcome tampil | nama kosong; nama `A` | 1) Biarkan nama kosong lalu lanjut; 2) Isi nama 1 huruf lalu lanjut | Nama kosong ditolak (pesan validasi); nama 1 karakter diterima | | | | | | |
| ONB-03 | Kuesioner Big Five | EP | Kuesioner MiniIPIP20 (20 soal) | Welcome selesai | 20 pertanyaan | 1) Lanjut ke kuesioner Big Five; 2) Amati jumlah pertanyaan & pilihan jawaban | Tampil 20 pertanyaan dengan pilihan skala (1–5) dan progres; dapat dinavigasi mundur/maju | | | | | | |
| ONB-04 | Big Five wajib lengkap | EG | Lanjut sebelum semua soal terjawab | Kuesioner Big Five aktif | 1 soal belum dijawab | 1) Jawab 19 soal; 2) Tekan lanjut/selesai | Tombol lanjut/selesai nonaktif atau muncul peringatan soal belum dijawab | | | | | | |
| ONB-05 | Kuesioner psikis | EP | Kuesioner psikis 20 soal, skor 0–3 | Big Five selesai | 20 pertanyaan | 1) Lanjut ke kuesioner psikis; 2) Amati jumlah soal & opsi jawaban | Tampil 20 pertanyaan; tiap soal memiliki 4 opsi bernilai skor 0–3 | | | | | | |
| ONB-06 | Psikis wajib lengkap | EG | Lanjut dengan soal belum dijawab | Kuesioner psikis aktif | 1 soal belum dijawab | 1) Jawab 19 soal; 2) Tekan lanjut/selesai | Tidak dapat lanjut sampai seluruh soal terjawab | | | | | | |
| ONB-07 | Hasil onboarding | EP | Halaman hasil menampilkan skor & kategori | Seluruh kuesioner selesai | skor maksimal (60/60) | 1) Selesaikan semua kuesioner; 2) Amati halaman hasil | Muncul ringkasan skor psikis (0–100), kategori (Sehat Optimal/Cukup/Rentan/Butuh Perhatian) & saran | | | | | | |
| ONB-08 | Pengulangan Big Five | ST | Ulang kuesioner Big Five dari pengaturan/profil | Akun sudah onboarding | jawaban berbeda | 1) Buka menu pengulangan Big Five; 2) Isi ulang 20 soal; 3) Simpan | Skor Big Five baru tersimpan & muncul SnackBar "Asesmen tersimpan" | | | | | | |

### 5.3 Modul HOME — Dashboard

| ID Kasus Uji | Modul/Fitur | Teknik | Skenario | Prekondisi | Data Uji | Langkah Pengujian | Hasil yang Diharapkan | Hasil Aktual | Status | Nama Tester | Tanggal Pengujian | Bukti/Lampiran | Catatan/Kendala |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| HOME-01 | Sapaan dashboard | EP | Dashboard menampilkan nama pengguna | Akun login & onboarding selesai | nama `Sari` | 1) Masuk aplikasi; 2) Amati header | Tampil sapaan dengan nama pengguna yang benar | | | | | | |
| HOME-02 | Kartu status psikis | BVA | Warna & kategori sesuai rentang skor | Skor psikis tersimpan | skor 100; 76; 51; 26; 0 | 1) Uji dengan user berskor 100, 76, 51, 26, 0 (atau ubah di database); 2) Amati kartu | 76–100 hijau "Sehat Optimal"; 51–75 kuning "Cukup"; 26–50 oranye "Rentan"; 0–25 merah "Butuh Perhatian" | | | | | | |
| HOME-03 | Statistik cepat | EP | Kartu statistik menampilkan angka benar | Ada data rekaman | 5 rekaman | 1) Buka dashboard; 2) Amati kartu statistik | Jumlah deteksi, emosi dominan, dan skor rata-rata tampil sesuai data | | | | | | |
| HOME-04 | CTA rekam | EP | Tombol rekam membuka layar deteksi | Dashboard tampil | tidak ada | 1) Tekan tombol/tile "Mulai Rekam"; 2) Amati navigasi | Terbuka layar Deteksi Emosi dan perekaman dimulai otomatis | | | | | | |
| HOME-05 | Rekomendasi | EP | Saran tampil sesuai emosi terakhir | Ada minimal 1 rekaman | emosi terakhir `sad` | 1) Buka dashboard; 2) Amati bagian rekomendasi | Saran relevan dengan emosi terakhir & profil Big Five pengguna | | | | | | |
| HOME-06 | Riwayat terbaru | EP | Tiga log deteksi terbaru tampil | Ada ≥ 3 rekaman | 3 rekaman | 1) Buka dashboard; 2) Amati daftar riwayat terbaru | Tampil 3 log terbaru dengan emosi, waktu & confidence | | | | | | |
| HOME-07 | Callout keselamatan | EG | Skor rendah menampilkan banner bantuan | Skor psikis < 26 | skor 20 | 1) Login dengan user berskor < 26; 2) Amati dashboard | Muncul banner/kartu rujukan keselamatan dengan aksi (hotline/kontak) | | | | | | |

### 5.4 Modul DET — Deteksi Emosi (Rekam)

| ID Kasus Uji | Modul/Fitur | Teknik | Skenario | Prekondisi | Data Uji | Langkah Pengujian | Hasil yang Diharapkan | Hasil Aktual | Status | Nama Tester | Tanggal Pengujian | Bukti/Lampiran | Catatan/Kendala |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| DET-01 | Perekaman otomatis | ST | Layar deteksi mulai merekam langsung | Kuota tersedia, izin mikrofon aktif | rekaman suara 10 detik | 1) Dari dashboard tekan rekam; 2) Amati indikator "Listening" & timer | Perekaman berjalan otomatis, timer berjalan, indikator merah "Listening..." tampil | | | | | | |
| DET-02 | Animasi waveform | EP | Waveform bergerak saat merekam | Sedang merekam | tidak ada | 1) Amati baris waveform selama perekaman | Batang waveform beranimasi mengikuti suara/menghasilkan pola dinamis | | | | | | |
| DET-03 | Pembaruan emosi real-time | EP | Skor emosi diperbarui berkala | Sedang merekam | berbicara sedih lalu gembira | 1) Bicara dengan intonasi berbeda; 2) Amati skor & emosi tampil | Emosi & persentase skor berubah setiap ~3 detik; total skor = 100% | | | | | | |
| DET-04 | Tombol stop | ST | Menghentikan perekaman & masuk proses | Sedang merekam | rekaman ≥ 5 detik | 1) Tekan tombol stop (lingkaran merah); 2) Amati layar | Muncul panel "Memproses..." dengan progress message (transkripsi → analisis) | | | | | | |
| DET-05 | Transkripsi Whisper | ST | Transkrip model Base → fallback Tiny | Model tersedia / internet untuk unduh | ucapkan "Saya merasa sedih hari ini" | 1) Rekam & berhenti; 2) Amati SnackBar info transkripsi | SnackBar menunjukkan model yang dipakai (Base/Tiny) atau "Transkrip tidak tersedia" jika gagal | | | | | | |
| DET-06 | Analisis gabungan | ST | Skor akhir = audio 60% + teks 40% | Transkripsi berhasil | rekaman suara dengan emosi | 1) Selesaikan deteksi; 2) Amati hasil akhir | Hasil dihitung dengan bobot audio 60% dan teks 40%, lalu menuju halaman Hasil | | | | | | |
| DET-07 | Izin mikrofon ditolak | EG | Deteksi saat izin mikrofon ditolak | Izin mikrofon dimatikan di pengaturan | tidak ada | 1) Buka layar deteksi dengan izin mikrofon ditolak | Muncul SnackBar error "gagal memulai rekaman" dan kembali ke dashboard (tanpa crash) | | | | | | |
| DET-08 | Chip kuota tersisa | BVA | Chip menampilkan sisa kuota | Kuota hari ini = 5 | 0–5 deteksi terpakai | 1) Buka layar deteksi; 2) Amati chip atas | Chip menampilkan `x/5`; saat sisa ≤ 2 berwarna merah; premium menampilkan "Unlimited" | | | | | | |
| DET-09 | Kuota habis → iklan | BVA | Deteksi ke-6 memicu dialog iklan reward | 5 deteksi gratis habis hari ini | sisa 0 | 1) Lakukan deteksi ke-6; 2) Pada dialog tekan "Tonton Iklan"; 3) Tonton iklan selesai; 4) Tekan "Mulai Rekam" | Setelah iklan selesai muncul dialog reward "…satu deteksi"; tekan mulai → perekaman berjalan | | | | | | |
| DET-10 | Kuota habis → batal | BVA | Membatalkan iklan reward | 5 deteksi gratis habis | sisa 0 | 1) Lakukan deteksi ke-6; 2) Tekan "Batal" pada dialog | Dialog tertutup dan aplikasi kembali ke dashboard tanpa merekam | | | | | | |
| DET-11 | Kuota premium | DT | Pengguna premium tidak terbatas | Akun premium aktif | lebih dari 5 deteksi | 1) Dengan akun premium lakukan > 5 deteksi berturut-turut | Deteksi terus berjalan tanpa dialog kuota; chip menampilkan "Unlimited" | | | | | | |
| DET-12 | Aplikasi dibawa ke latar | EG | Meminimalkan app saat merekam | Sedang merekam | tidak ada | 1) Rekam; 2) Tekan home (background); 3) Kembali ke aplikasi | Aplikasi tidak crash; kondisi rekaman ditangani dengan aman (berhenti/kembali ke dashboard) | | | | | | |
| DET-13 | Simpan & upload | EG | Data rekaman tersimpan & audio ter-upload | Deteksi selesai | 1 rekaman | 1) Selesaikan deteksi; 2) Periksa riwayat; 3) Periksa Firestore/Storage (Firebase Console) | Record tersimpan di `users/{uid}/recordings` & file WAV ter-upload ke Firebase Storage dengan URL tersimpan | | | | | | |

### 5.5 Modul LIVE — Deteksi Emosi (Real-time)

| ID Kasus Uji | Modul/Fitur | Teknik | Skenario | Prekondisi | Data Uji | Langkah Pengujian | Hasil yang Diharapkan | Hasil Aktual | Status | Nama Tester | Tanggal Pengujian | Bukti/Lampiran | Catatan/Kendala |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| LIVE-01 | Deteksi real-time | EP | Emosi terdeteksi dari suara langsung | Izin mikrofon aktif | ucapkan kalimat gembira | 1) Buka layar Live Detection; 2) Bicara; 3) Amati hasil | Emosi terdeteksi diperbarui real-time sesuai intonasi suara | | | | | | |
| LIVE-02 | Tanpa suara | EG | Diam / lingkungan hening | Live detection aktif | lingkungan hening | 1) Buka Live Detection; 2) Jangan berbicara; 3) Amati | Tidak ada emosi dominan (netral) dan tidak ada crash saat tidak ada suara | | | | | | |
| LIVE-03 | Toggle mulai/henti | ST | Menghentikan dan memulai ulang deteksi | Live detection aktif | tidak ada | 1) Tekan tombol hentikan; 2) Tekan mulai lagi | Deteksi berhenti bersih lalu dapat dimulai ulang tanpa error | | | | | | |

### 5.6 Modul RS — Halaman Hasil

| ID Kasus Uji | Modul/Fitur | Teknik | Skenario | Prekondisi | Data Uji | Langkah Pengujian | Hasil yang Diharapkan | Hasil Aktual | Status | Nama Tester | Tanggal Pengujian | Bukti/Lampiran | Catatan/Kendala |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RS-01 | Emosi dominan | EP | Hasil menampilkan emosi dominan & confidence | Deteksi selesai | emosi `sad` confidence 0.70 | 1) Selesaikan deteksi; 2) Amati halaman hasil | Emosi dominan & persentase confidence ditampilkan dengan benar | | | | | | |
| RS-02 | Skor gabungan | BVA | Bar skor audio vs teks tampil | Deteksi selesai | audio 0.6, teks 0.4 | 1) Selesaikan deteksi; 2) Amati bagian skor | Skor audio dan teks ditampilkan; total skor tiap emosi konsisten (≤ 100%) | | | | | | |
| RS-03 | Saran | EP | Rekomendasi sesuai emosi & Big Five | Profil Big Five tersedia | emosi `angry` | 1) Selesaikan deteksi; 2) Amati saran | Saran relevan dengan emosi dominan & skor Big Five pengguna | | | | | | |
| RS-04 | Trigger tag | EP | Tag pemicu emosi tampil | Deteksi selesai | transkrip mengandung kata pemicu | 1) Selesaikan deteksi; 2) Amati tag | Tag pemicu (misal: pekerjaan, hubungan) tampil sesuai isi transkrip | | | | | | |
| RS-05 | Navigasi keluar | EP | Kembali ke dashboard/riwayat | Halaman hasil tampil | tidak ada | 1) Tekan tombol kembali/dashboard | Kembali ke dashboard tanpa error dan hasil tersimpan di riwayat | | | | | | |

### 5.7 Modul HST — Riwayat & Statistik

| ID Kasus Uji | Modul/Fitur | Teknik | Skenario | Prekondisi | Data Uji | Langkah Pengujian | Hasil yang Diharapkan | Hasil Aktual | Status | Nama Tester | Tanggal Pengujian | Bukti/Lampiran | Catatan/Kendala |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| HST-01 | Daftar log | EP | Log deteksi tampil terurut | Ada beberapa rekaman | 5 rekaman | 1) Buka menu Riwayat; 2) Amati daftar | Log tampil terurut (terbaru di atas) dengan emosi & waktu | | | | | | |
| HST-02 | Filter "Semua Waktu" | EP | Menampilkan seluruh data | Data lintas tanggal | 3 data hari ini, 2 data minggu lalu | 1) Buka Riwayat; 2) Pilih filter "Semua Waktu" | Seluruh rekaman ditampilkan (5 log) | | | | | | |
| HST-03 | Filter "Hari Ini" | EP | Hanya data hari ini | Data hari ini & kemarin | 3 hari ini, 2 kemarin | 1) Pilih filter "Hari Ini" | Hanya 3 rekaman hari ini yang tampil | | | | | | |
| HST-04 | Filter "7 Hari" | EP | Hanya data 7 hari terakhir | Data 10 hari lalu | 4 data ≤ 7 hari, 1 data 10 hari lalu | 1) Pilih filter "7 Hari" | Hanya 4 rekaman yang tampil | | | | | | |
| HST-05 | Filter "30 Hari" | EP | Hanya data 30 hari terakhir | Data 40 hari lalu | 1 data 40 hari lalu | 1) Pilih filter "30 Hari" | Rekaman > 30 hari tidak ditampilkan | | | | | | |
| HST-06 | Filter custom | EG | Rentang tanggal kustom | Ada data di luar rentang | 1–5 Juni, data 10 Juni | 1) Pilih "Kustom"; 2) Pilih rentang 1–5 Juni | Hanya data dalam rentang tampil; label chip menampilkan rentang terpilih | | | | | | |
| HST-07 | Filter emosi | EP | Chip emosi menyaring log | Data berbagai emosi | 3 happy, 2 sad | 1) Tekan chip "Sedih"; 2) Amati daftar | Hanya log emosi "Sedih" yang tampil, jumlah log sesuai label chip | | | | | | |
| HST-08 | Grafik tren mingguan | EP | Line chart tren emosi | Data ≥ 7 hari | 7 data | 1) Buka Riwayat; 2) Amati grafik | Grafik garis mingguan tampil (fl_chart) dengan data benar & tooltip bekerja | | | | | | |
| HST-09 | Data kosong | EG | Riwayat tanpa data | Akun baru tanpa rekaman | tidak ada | 1) Buka Riwayat akun tanpa data | Tampil empty state ("Belum ada rekaman") tanpa error | | | | | | |
| HST-10 | Pencarian log | EP | Cari berdasarkan teks/emosi | Banyak log | ketik `sad` | 1) Buka log lengkap; 2) Ketik kata kunci di kolom cari | Log yang cocok ditampilkan; tombol clear mengosongkan pencarian | | | | | | |

### 5.8 Modul RCD — Detail Rekaman

| ID Kasus Uji | Modul/Fitur | Teknik | Skenario | Prekondisi | Data Uji | Langkah Pengujian | Hasil yang Diharapkan | Hasil Aktual | Status | Nama Tester | Tanggal Pengujian | Bukti/Lampiran | Catatan/Kendala |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RCD-01 | Detail rekaman | EP | Semua informasi rekaman tampil | Minimal 1 rekaman | 1 rekaman | 1) Buka Riwayat; 2) Ketuk salah satu log | Detail tampil: emosi, confidence, tanggal, durasi, saran | | | | | | |
| RCD-02 | Transkrip & fallback | DT | Transkrip tampil; jika kosong tampil fallback | Rekaman dengan & tanpa transkrip | rekaman tanpa transkrip | 1) Buka detail rekaman tanpa transkrip; 2) Amati bagian transkrip | Bagian transkrip menampilkan teks; jika kosong muncul ikon/info "tidak ada transkrip" (tanpa error) | | | | | | |
| RCD-03 | Grafik audio & radar | EP | Bar chart audio + radar chart tampil | Rekaman memiliki skor | 1 rekaman | 1) Buka detail; 2) Amati grafik | Bar chart distribusi emosi & radar chart ditampilkan benar | | | | | | |
| RCD-04 | Perbandingan audio vs teks | EP | Perbandingan skor dua sumber tampil | Rekaman dengan transkrip | 1 rekaman | 1) Buka detail; 2) Amati bagian perbandingan | Skor audio (mikrofon) dan teks (transkrip) ditampilkan berdampingan | | | | | | |

### 5.9 Modul PRF — Profil

| ID Kasus Uji | Modul/Fitur | Teknik | Skenario | Prekondisi | Data Uji | Langkah Pengujian | Hasil yang Diharapkan | Hasil Aktual | Status | Nama Tester | Tanggal Pengujian | Bukti/Lampiran | Catatan/Kendala |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| PRF-01 | Tampil profil | EP | Profil menampilkan data pengguna | Akun login | nama `Sari` | 1) Buka Pengaturan → Profil | Nama, email & foto profil pengguna ditampilkan benar | | | | | | |
| PRF-02 | Edit nama (validasi) | BVA | Nama kosong ditolak; nama valid diterima | Halaman profil tampil | nama kosong; `Sari` | 1) Edit nama → kosongkan → simpan; 2) Isi `Sari` → simpan | Nama kosong menampilkan pesan validasi; nama valid tersimpan & muncul SnackBar sukses | | | | | | |
| PRF-03 | Ganti foto profil | EP | Foto diambil dari galeri/kamera | Izin galeri/kamera aktif | gambar 1 MB | 1) Ketuk avatar; 2) Pilih galeri; 3) Pilih foto; 4) Simpan | Foto profil berubah sesuai gambar terpilih | | | | | | |
| PRF-04 | Hapus foto profil | EG | Menghapus foto kembali ke default | Ada foto profil | tidak ada | 1) Ketuk avatar; 2) Pilih "Hapus Foto" | Foto profil terhapus & kembali ke avatar default | | | | | | |
| PRF-05 | Persistensi | ST | Perubahan profil bertahan setelah restart | Profil diedit | nama baru | 1) Ubah nama/foto; 2) Tutup & buka aplikasi lagi | Perubahan profil tetap tersimpan | | | | | | |

### 5.10 Modul STG — Pengaturan

| ID Kasus Uji | Modul/Fitur | Teknik | Skenario | Prekondisi | Data Uji | Langkah Pengujian | Hasil yang Diharapkan | Hasil Aktual | Status | Nama Tester | Tanggal Pengujian | Bukti/Lampiran | Catatan/Kendala |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| STG-01 | Bahasa | ST | Beralih ID ↔ EN dan kembali | Pengaturan tampil | `en` lalu `id` | 1) Pilih "EN"; 2) Amati seluruh teks; 3) Kembali ke "ID" | Seluruh teks UI berubah ke bahasa Inggris; kembali ke Indonesia sesuai pilihan (persisten) | | | | | | |
| STG-02 | Tema | ST | Beralih Light ↔ Dark | Pengaturan tampil | tema dark lalu light | 1) Pilih "Gelap"; 2) Amati seluruh layar; 3) Kembali "Terang" | Seluruh layar berubah tema gelap/terang konsisten & persisten | | | | | | |
| STG-03 | Panduan aplikasi | EP | Dialog/bagian panduan tampil | Pengaturan tampil | tidak ada | 1) Ketuk "Panduan" | Panduan penggunaan aplikasi tampil (dialog/halaman) | | | | | | |
| STG-04 | Terms of Service | EP | Membuka halaman syarat & ketentuan | Pengaturan tampil | tidak ada | 1) Ketuk "Syarat & Ketentuan" | Terms dibuka (in-app atau browser) tanpa error | | | | | | |
| STG-05 | License | EP | Membuka lisensi perangkat lunak | Pengaturan tampil | tidak ada | 1) Ketuk "Lisensi" | Daftar lisensi (showLicensePage) tampil | | | | | | |
| STG-06 | Backup data | EP | Ekspor data ke berkas JSON | Ada data rekaman | 2 rekaman | 1) Ketuk "Backup Data"; 2) Pilih lokasi penyimpanan | Berkas backup (JSON) berhasil dibuat & berisi data user/rekaman | | | | | | |
| STG-07 | Restore data | EG | Mengembalikan data dari berkas backup | Berkas backup tersedia | berkas `backup.json` | 1) Ketuk "Pulihkan Data"; 2) Pilih berkas backup | Data berhasil dipulihkan; riwayat muncul kembali setelah restart | | | | | | |
| STG-08 | Hapus akun | EG | Hapus akun dengan konfirmasi | Akun login | tidak ada | 1) Ketuk "Hapus Akun"; 2) Konfirmasi di dialog; 3) Cek Firebase | Dialog konfirmasi tampil; setelah konfirmasi akun terhapus & kembali ke layar login | | | | | | |
| STG-09 | Logout | ST | Keluar dari aplikasi | Akun login | tidak ada | 1) Ketuk "Keluar"; 2) Konfirmasi | Kembali ke layar login; data premium di-reset (RevenueCat logout) | | | | | | |
| STG-10 | Tile premium | DT | Tile upgrade/premium sesuai status | Akun non-premium & premium | 2 akun | 1) Non-premium: amati tile; 2) Premium: amati tile | Non-premium menampilkan "Upgrade Premium"; premium menampilkan status premium aktif | | | | | | |

### 5.11 Modul PRM — Premium

| ID Kasus Uji | Modul/Fitur | Teknik | Skenario | Prekondisi | Data Uji | Langkah Pengujian | Hasil yang Diharapkan | Hasil Aktual | Status | Nama Tester | Tanggal Pengujian | Bukti/Lampiran | Catatan/Kendala |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| PRM-01 | Daftar paket | EP | Tiga paket tampil dengan harga benar | Akun non-premium | tidak ada | 1) Buka layar Premium; 2) Amati paket | Paket Mingguan Rp 7.000, Bulanan Rp 20.000, Tahunan Rp 99.000 (label "Hemat 59%") tampil | | | | | | |
| PRM-02 | Pilih paket | EP | Pemilihan paket menyorot kartu | Layar premium tampil | pilih Tahunan | 1) Ketuk kartu Tahunan | Kartu terpilih tersorot (border/warna berbeda) | | | | | | |
| PRM-03 | Langganan berhasil | ST | Pembelian via RevenueCat berhasil | Sandbox purchase aktif | paket Bulanan | 1) Pilih paket; 2) Tekan "Langganan Sekarang"; 3) Selesaikan pembayaran sandbox | Muncul dialog "Berhasil" & status premium aktif (tanpa batas deteksi, bebas iklan) | | | | | | |
| PRM-04 | Pembelian dibatalkan | EG | Membatalkan dialog pembayaran | Sheet pembayaran tampil | Batal | 1) Tekan "Langganan Sekarang"; 2) Batalkan pembayaran | Muncul dialog "Pembelian gagal/dibatalkan"; status premium tidak berubah | | | | | | |
| PRM-05 | Restore pembelian | ST | Mengembalikan langganan yang sudah dibeli | Langganan aktif di akun Google/Apple | tidak ada | 1) Tekan ikon restore; 2) Selesaikan konfirmasi | Dialog "Pembelian dipulihkan" tampil & status premium aktif | | | | | | |
| PRM-06 | Reset premium | EG | Menghapus status premium (mode uji) | Status premium aktif | tidak ada | 1) Tekan ikon power; 2) Konfirmasi reset | Status premium dibersihkan & RevenueCat logout; kembali dari layar premium | | | | | | |
| PRM-07 | Countdown premium | DT | Hitung mundur hingga berakhir tampil | Premium aktif dengan expiry | expiry besok | 1) Buka layar premium dengan status aktif | Tampil blok "Aktif", hitung mundur Hari/Jam/Menit/Detik & tanggal berakhir | | | | | | |
| PRM-08 | Manfaat premium | EP | Daftar manfaat premium tampil | Premium aktif | tidak ada | 1) Amati bagian "Manfaat Premium Anda" | Manfaat (deteksi tanpa batas & bebas iklan) ditampilkan | | | | | | |

### 5.12 Modul ADM — Dashboard Admin

| ID Kasus Uji | Modul/Fitur | Teknik | Skenario | Prekondisi | Data Uji | Langkah Pengujian | Hasil yang Diharapkan | Hasil Aktual | Status | Nama Tester | Tanggal Pengujian | Bukti/Lampiran | Catatan/Kendala |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| ADM-01 | Login admin | DT | Login akun admin menuju dashboard admin | Akun admin (`isAdmin=true`) di Firestore | `admin@example.com` | 1) Login dengan akun admin; 2) Amati navigasi | SnackBar "Admin login successful" & dashboard Admin terbuka (bukan dashboard biasa) | | | | | | |
| ADM-02 | Statistik admin | EP | Kartu statistik menampilkan angka benar | Ada data user & rekaman | 3 user, 10 rekaman | 1) Buka dashboard admin; 2) Amati kartu | Total Pengguna, Rata-rata Skor, Total Rekaman sesuai data Firestore | | | | | | |
| ADM-03 | Distribusi emosi | EP | Grafik distribusi emosi tampil | Ada rekaman berbagai emosi | 4 happy, 3 sad | 1) Amati bagian "Distribusi Emosi" | Bar chart distribusi emosi dengan jumlah & persentase benar; akun admin tidak ikut terhitung | | | | | | |
| ADM-04 | Status kesehatan mental | BVA | Kategori status sesuai rentang skor | User dengan skor bervariasi | skor 80; 60; 30; 10 | 1) Amati kartu "Status Kesehatan Mental" | Kategori Sehat Optimal/Cukup/Rentan/Butuh Perhatian terhitung sesuai rentang skor (76-100/51-75/26-50/0-25) | | | | | | |
| ADM-05 | Pencarian user | EP | Pencarian berdasarkan nama | Banyak user terdaftar | ketik `Sari` | 1) Ketik nama di kolom cari; 2) Amati daftar; 3) Tekan ikon clear | Hanya user yang cocok tampil; clear mengembalikan seluruh daftar | | | | | | |
| ADM-06 | Detail user | EP | Membuka detail user, PDF & download audio | User memiliki rekaman | 1 user, 1 rekaman | 1) Ketuk item user; 2) Amati detail; 3) Tekan ikon PDF; 4) Tekan download audio | Detail user (skor, Big Five, rekaman) tampil; PDF laporan user dihasilkan; audio dapat diunduh | | | | | | |
| ADM-07 | Export PDF | EG | Ekspor laporan seluruh pengguna | Ada ≥ 1 user | tidak ada | 1) Tekan ikon PDF pada header; 2) Bagikan/simpan | Berkas `laporan_pengguna.pdf` dihasilkan & dibuka untuk dibagikan; jika tanpa data muncul SnackBar "Tidak ada data untuk di-export" | | | | | | |
| ADM-08 | Logout admin | ST | Keluar dari mode admin | Dashboard admin tampil | tidak ada | 1) Tekan ikon logout; 2) Konfirmasi dialog | Kembali ke layar login dengan benar (bukan mode admin) | | | | | | |

### 5.13 Modul SYS — Sistem & Perangkat

| ID Kasus Uji | Modul/Fitur | Teknik | Skenario | Prekondisi | Data Uji | Langkah Pengujian | Hasil yang Diharapkan | Hasil Aktual | Status | Nama Tester | Tanggal Pengujian | Bukti/Lampiran | Catatan/Kendala |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| SYS-01 | Peluncuran pertama | ST | Onboarding muncul saat pertama kali | Aplikasi baru diinstall | tidak ada | 1) Install & buka aplikasi pertama kali; 2) Tutup; 3) Buka kembali | Onboarding tampil pada peluncuran pertama; tidak muncul lagi setelah selesai | | | | | | |
| SYS-02 | Orientasi layar | EG | Rotasi perangkat tidak mengacaukan UI | Aplikasi terbuka | tidak ada | 1) Buka beberapa layar; 2) Putar perangkat 90°/180° | Layar tetap portrait (layout tidak berantakan saat rotasi) | | | | | | |
| SYS-03 | Tanpa internet | EG | Membuka aplikasi saat offline | Mode pesawat aktif | tidak ada | 1) Aktifkan mode pesawat; 2) Buka aplikasi; 3) Buka riwayat/deteksi | Aplikasi tidak crash; pesan koneksi ditampilkan saat membutuhkan Firebase | | | | | | |
| SYS-04 | Persistensi data | ST | Data tetap ada setelah restart | Ada data onboarding & rekaman | 2 rekaman | 1) Tutup aplikasi; 2) Buka kembali; 3) Periksa dashboard & riwayat | Data (skor, riwayat, pengaturan) tetap tersimpan & ditampilkan | | | | | | |
| SYS-05 | Unduhan model Whisper | EG | Model diunduh saat deteksi pertama | Internet aktif, model belum ada | tidak ada | 1) Buka deteksi pertama kali; 2) Amati progress unduhan model Base & Tiny | Model diunduh dengan progress ditampilkan; tanpa internet muncul pesan "Internet diperlukan untuk mengunduh model suara" | | | | | | |
| SYS-06 | Izin aplikasi | EG | Dialog izin perangkat muncul benar | Aplikasi baru diinstall | mikrofon & galeri | 1) Buka deteksi → izin mikrofon; 2) Ubah foto profil → izin galeri | Dialog izin sistem muncul sesuai fitur; penolakan ditangani tanpa crash | | | | | | |

---

## 6. Rekapitulasi Hasil Pengujian

Tabel berikut diisi oleh QA Lead setelah seluruh kasus uji dieksekusi. Saat ini seluruh nilai **0** (template belum dieksekusi).

| No | Modul | Jumlah Kasus Uji | PASS | FAIL | BLOCKED |
|---|---|---|---|---|---|
| 1 | AUTH — Autentikasi | 15 | 0 | 0 | 0 |
| 2 | ONB — Onboarding | 8 | 0 | 0 | 0 |
| 3 | HOME — Dashboard | 7 | 0 | 0 | 0 |
| 4 | DET — Deteksi Emosi (Rekam) | 13 | 0 | 0 | 0 |
| 5 | LIVE — Deteksi Real-time | 3 | 0 | 0 | 0 |
| 6 | RS — Halaman Hasil | 5 | 0 | 0 | 0 |
| 7 | HST — Riwayat & Statistik | 10 | 0 | 0 | 0 |
| 8 | RCD — Detail Rekaman | 4 | 0 | 0 | 0 |
| 9 | PRF — Profil | 5 | 0 | 0 | 0 |
| 10 | STG — Pengaturan | 10 | 0 | 0 | 0 |
| 11 | PRM — Premium | 8 | 0 | 0 | 0 |
| 12 | ADM — Dashboard Admin | 8 | 0 | 0 | 0 |
| 13 | SYS — Sistem & Perangkat | 6 | 0 | 0 | 0 |
| | **Total** | **102** | **0** | **0** | **0** |

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

Dokumen ini dinyatakan sah dan disetujui setelah seluruh kasus uji (102 kasus) dieksekusi dan direkap pada Bab 6.

| | Nama | Jabatan | Tanda Tangan | Tanggal |
|---|---|---|---|---|
| Disiapkan oleh | | Tester | | |
| Direview oleh | | QA Lead / Supervisor | | |
| Disetujui oleh | | Project Manager / Dosen Pembimbing | | |

---

*Dokumen ini merupakan template pengujian blackbox manual. Seluruh kolom hasil (Hasil Aktual, Status, Nama Tester, Tanggal Pengujian, Bukti/Lampiran, Catatan/Kendala) sengaja dikosongkan dan diisi oleh tester manusia saat pelaksanaan pengujian.*
