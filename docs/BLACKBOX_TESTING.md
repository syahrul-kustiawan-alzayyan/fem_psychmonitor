# Dokumentasi Blackbox Testing — Fem-Psych Monitor

**Aplikasi:** Fem-Psych Monitor (fem_physicsmonitor) v2.1.0+7
**Platform:** Flutter (Android / iOS / Web / Desktop)
**Metode:** Blackbox Testing (pengujian fungsional berdasarkan spesifikasi & perilaku tampilan, tanpa melihat implementasi internal)
**Status:** **PASS** — 101/101 kasus uji otomatis lulus (lingkup Big Five OCEAN)

---

## 1. Pendahuluan

Dokumen ini berisi rencana dan hasil pengujian **blackbox testing** untuk aplikasi Fem-Psych Monitor. Pengujian dilakukan pada level **fungsional** dengan memperlakukan aplikasi sebagai "kotak hitam": setiap kasus uji mendefinisikan **skenario**, **langkah**, **data masukan**, dan **hasil yang diharapkan**, lalu dibandingkan dengan perilaku nyata aplikasi.

Pengujian dijalankan secara **otomatis** menggunakan Flutter Widget Test (`flutter test`). Setiap `test`/`testWidgets` dalam kode uji dipetakan ke satu kasus uji blackbox berikut.

## 2. Ruang Lingkup

Modul yang diuji:

| Modul | File Uji | Jumlah Kasus |
|---|---|---|
| Splash & Routing Awal | `test/widget_test.dart` | 2 |
| Onboarding — Welcome & Bahasa | `test/widgets/welcome_section_test.dart` | 3 |
| Onboarding — State & Perhitungan Skor | `test/onboarding/onboarding_state_test.dart` | 9 |
| Autentikasi | `test/widgets/auth_screen_test.dart` | 6 |
| Pengaturan (Settings) | `test/widgets/settings_screen_test.dart` | 5 |
| Lokalisasi (ID/EN) | `test/l10n/app_localizations_test.dart` | 7 |
| Model Emosi | `test/models/emotion_model_test.dart` | 21 |
| Model User (Big Five OCEAN, Psy) | `test/models/user_model_test.dart` | 11 |
| Deteksi Emosi dari Teks | `test/services/text_emotion_service_test.dart` | 8 |
| Saran & Rujukan Keselamatan | `test/services/suggestion_service_test.dart` | 9 |
| Penyimpanan Lokal & Limit Harian | `test/services/storage_service_test.dart` | 8 |
| Ekspor Laporan PDF | `test/services/pdf_export_service_test.dart` | 2 |
| State Management (Provider) | `test/providers/providers_test.dart` | 10 |
| **Total** | | **101** |

## 3. Lingkungan & Cara Menjalankan

### 3.1 Lingkungan
- Flutter SDK: 3.41.7 (stable)
- Dart: 3.11.5
- Sistem operasi uji: Windows
- Kerangka uji: `package:flutter_test` (Widget Test)

### 3.2 Cara Menjalankan
```bash
# Jalankan seluruh suite uji
flutter test

# Jalankan uji per modul
flutter test test/models/user_model_test.dart
flutter test test/widgets/auth_screen_test.dart

# Jalankan satu kasus uji (filter nama)
flutter test --plain-name "password terlalu pendek -> error minimal 6 karakter"
```

### 3.3 Hasil Terakhir
```
00:39 +101: All tests passed!
```
> *Catatan: hasil eksekusi `flutter test` penuh (lingkup Big Five OCEAN).*

Seluruh **101 kasus uji lulus** (0 gagal, 0 error).

---

## 4. Rincian Kasus Uji

### 4.1 Splash & Routing Awal (`test/widget_test.dart`)

| ID | Skenario | Prekondisi | Langkah | Hasil yang Diharapkan | Status |
|---|---|---|---|---|---|
| R-01 | Splash tampil lebih dulu, lalu masuk Onboarding saat first launch | Belum pernah menyelesaikan onboarding (`first_launch = true`) | 1. Buka aplikasi<br>2. Amati frame awal<br>3. Tunggu proses inisialisasi selesai | 1. Frame pertama menampilkan **splash** dengan nama "Fem-Psych Monitor"<br>2. Setelah selesai, aplikasi mengarah ke halaman **Onboarding** (tombol "Mulai Sekarang" terlihat) | **PASS** |
| R-02 | First launch selesai → langsung menuju halaman Login (AuthScreen) | Onboarding sudah pernah diselesaikan (`first_launch = false`) | 1. Buka aplikasi<br>2. Tunggu proses inisialisasi selesai | Aplikasi langsung menampilkan halaman **Login** (teks "Masuk" muncul, sebagai judul & tombol) | **PASS** |

### 4.2 Onboarding — Welcome & Bahasa (`test/widgets/welcome_section_test.dart`)

| ID | Skenario | Prekondisi | Langkah | Hasil yang Diharapkan | Status |
|---|---|---|---|---|---|
| W-01 | Halaman selamat datang menampilkan tombol mulai | Berada di langkah pertama onboarding | 1. Buka halaman Welcome | Tombol **"Mulai Sekarang"** tampil | **PASS** |
| W-02 | Menekan tombol mulai menjalankan lanjut ke langkah berikutnya | Berada di halaman Welcome | 1. Tekan tombol "Mulai Sekarang" | Sistem berpindah ke langkah onboarding berikutnya (callback `onNext` terpanggil) | **PASS** |
| W-03 | Toggle bahasa ID ↔ EN mengganti teks | Berada di halaman Welcome | 1. Tekan segmen "EN"<br>2. Tekan segmen "ID" | 1. Setelah tekan "EN", teks deskripsi berubah ke bahasa Inggris (`locale = en`)<br>2. Setelah tekan "ID", kembali ke bahasa Indonesia (`locale = id`) | **PASS** |

### 4.3 Onboarding — State & Perhitungan Skor (`test/onboarding/onboarding_state_test.dart`)

| ID | Skenario | Prekondisi | Langkah | Hasil yang Diharapkan | Status |
|---|---|---|---|---|---|
| O-01 | Memuat soal dari aset | Buka onboarding | 1. Sistem memuat soal | 20 soal Big Five + 20 soal psy dimuat; jawaban awal 20 slot kosong; status tidak loading | **PASS** |
| O-02 | Semua jawaban masih kosong | Soal sudah dimuat | 1. Periksa status kelengkapan | Kelengkapan Big Five **false**, kelengkapan Psy **false** | **PASS** |
| O-03 | Soal Big Five memuat dua arah skoring | Soal sudah dimuat | 1. Periksa atribut `keyed` tiap soal | Terdapat soal ber-`keyed '+'` dan `keyed '-'` | **PASS** |
| O-04 | Soal psy memiliki opsi berskor | Soal sudah dimuat | 1. Periksa opsi soal psy pertama | Opsi tidak kosong; skor opsi berada di rentang **0–3** | **PASS** |
| O-05 | Mengisi semua Big Five → hasil 5 dimensi | Soal dimuat | 1. Jawab semua 20 soal (pola 1–5)<br>2. Hitung hasil | Kelengkapan menjadi **true**; hasil memuat dimensi **O, C, E, A, N** dengan skor masing-masing **1.0–5.0** | **PASS** |
| O-06 | Semua jawaban psy memilih skor maksimum | Soal dimuat | 1. Pilih opsi skor 3 untuk semua 20 soal<br>2. Hitung hasil | `psyScore = 60`; skor tampilan **0** (kondisi terburuk) | **PASS** |
| O-07 | Semua jawaban psy memilih skor 0 | Soal dimuat | 1. Pilih opsi skor 0 untuk semua soal<br>2. Hitung hasil | `psyScore = 0`; skor tampilan **100** (kondisi terbaik) | **PASS** |
| O-08 | Konversi skor psy → kategori kesehatan mental | Skor psy tersedia | 1. Bandingkan skor tampilan dengan ambang batas | `100`→Sehat Optimal; `85`→Sehat Optimal; `67`→Cukup; `42`→Rentan; `20`→Butuh Perhatian Klinis; `0`→Butuh Perhatian | **PASS** |
| O-09 | Flag menyimpan (saving) dapat dikontrol | — | 1. Aktifkan `saving = true`<br>2. Matikan `saving = false` | Status `isSaving` berubah mengikuti nilai | **PASS** |

### 4.4 Autentikasi (`test/widgets/auth_screen_test.dart`)

| ID | Skenario | Prekondisi | Langkah | Hasil yang Diharapkan | Status |
|---|---|---|---|---|---|
| A-01 | Halaman login menampilkan seluruh elemen form | Buka halaman Login | 1. Amati halaman | Muncul judul "Fem-Psych Monitor", heading+tombol "Masuk" (2 teks), tombol "Lanjutkan dengan Google", field "Email" & "Password" | **PASS** |
| A-02 | Submit tanpa centang kebijakan privasi | Form login tampil, privacy belum dicentang | 1. Tekan tombol "Masuk" | Muncul peringatan **"Centang kebijakan privasi terlebih dahulu"** (snackbar) | **PASS** |
| A-03 | Centang privasi + submit dengan form kosong | Privacy dicentang | 1. Centang checkbox privasi<br>2. Tekan "Masuk" | Muncul error validasi **"Email wajib diisi"** dan **"Password wajib diisi"** | **PASS** |
| A-04 | Input email tidak valid | Privacy dicentang | 1. Isi Email: `bukanemail`<br>2. Isi Password: `rahasia123`<br>3. Tekan "Masuk" | Muncul error **"Format email tidak valid"** | **PASS** |
| A-05 | Password terlalu pendek | Privacy dicentang | 1. Isi Email: `user@example.com`<br>2. Isi Password: `123`<br>3. Tekan "Masuk" | Muncul error **"Minimal 6 karakter"** | **PASS** |
| A-06 | Toggle visibilitas password | Field password tampil | 1. Periksa field password (tersembunyi)<br>2. Tekan ikon mata (visibility_off)<br>3. Periksa ulang | 1. Awal: password **tersembunyi** (`obscureText = true`)<br>2. Setelah toggle: password **terlihat** (`obscureText = false`) | **PASS** |

### 4.5 Pengaturan / Settings (`test/widgets/settings_screen_test.dart`)

| ID | Skenario | Prekondisi | Langkah | Hasil yang Diharapkan | Status |
|---|---|---|---|---|---|
| S-01 | Halaman pengaturan menampilkan semua section | Buka halaman Settings | 1. Amati halaman | Muncul judul Pengaturan, Bahasa, Mode Tema, Menu Profil, Panduan Aplikasi, Syarat & Ketentuan, Cadangkan Data, Hapus Data Akun, dan versi aplikasi **v2.1.0** | **PASS** |
| S-02 | Switch bahasa ID → EN mengubah label | Halaman Settings tampil | 1. Tekan segmen "EN" | Label berubah ke bahasa Inggris (mis. "Bahasa" → **"Language"**); `locale = en` | **PASS** |
| S-03 | Switch tema Light → Dark mengubah ikon | Halaman Settings tampil (tema Light) | 1. Tekan pilihan "Dark" | Ikon tema berubah dari `light_mode` → **`dark_mode`** | **PASS** |
| S-04 | Tile "Upgrade ke Premium" muncul saat non-premium | Akun non-premium | 1. Amati halaman Settings | Muncul tile **"Upgrade ke Premium"** dengan ikon bintang (`star_border`) | **PASS** |
| S-05 | Menekan "Panduan Aplikasi" membuka bottom sheet | Halaman Settings tampil | 1. Gulir ke tile Panduan<br>2. Tekan tile | Muncul **bottom sheet** panduan dengan judul "Panduan" (judul tile + judul sheet) | **PASS** |

### 4.6 Lokalisasi (`test/l10n/app_localizations_test.dart`)

| ID | Skenario | Prekondisi | Langkah | Hasil yang Diharapkan | Status |
|---|---|---|---|---|---|
| L-01 | Terjemahan bahasa Indonesia untuk key navigasi | Locale = `id` | 1. Ambil `nav_home`, `nav_record`, `nav_history` | Bernilai **"Beranda"**, **"Rekam"**, **"Riwayat"** | **PASS** |
| L-02 | Terjemahan bahasa Inggris setelah `setLocale("en")` | Locale = `en` | 1. Ambil `nav_home` | Nilai **berbeda dari bahasa Indonesia** dan tidak kosong | **PASS** |
| L-03 | Fallback ke bahasa Indonesia bila key tidak ada di EN | Locale = `en` | 1. Ambil key yang tidak ada di map EN | Nilai tetap terisi (fallback ke ID, tidak kosong) | **PASS** |
| L-04 | Key tidak ditemukan di semua map | Locale = `id` | 1. Ambil `key_tidak_ada_123` | Mengembalikan **key itu sendiri** sebagai nilai | **PASS** |
| L-05 | Setter & getter locale | — | 1. Set `en` → baca<br>2. Set `id` → baca | `locale`/`currentLocale` mengikuti nilai yang diset | **PASS** |
| L-06 | Key penting onboarding & hasil tersedia | — | 1. Cek 17 key penting (dimensi Big Five, kategori hasil, limit harian, login, emosi, saran, pemicu) | Semua key memiliki terjemahan **tidak kosong** | **PASS** |
| L-07 | Terjemahan ID dan EN tidak identik | — | 1. Ambil `splash_subtitle` dalam ID<br>2. Ambil dalam EN | Nilai ID ≠ nilai EN | **PASS** |

### 4.7 Model Emosi (`test/models/emotion_model_test.dart`)

| ID | Skenario | Prekondisi | Langkah | Hasil yang Diharapkan | Status |
|---|---|---|---|---|---|
| E-01 | Set locale deterministik | — | 1. Set locale `id` | Getter locale = `id` | **PASS** |
| E-02 | Tersedia 6 jenis emosi | — | 1. Periksa daftar emosi | Lengkap: happy, sad, angry, disgust, neutral, fear | **PASS** |
| E-03 | Nama tampilan emosi mengikuti bahasa | Locale = `id` | 1. Bandingkan `displayName` dengan terjemahan | `happy.displayName` = terjemahan `emotion_happy`; `sad` = `emotion_sad` | **PASS** |
| E-04 | Setiap emosi punya emoji | — | 1. Periksa `emoji` tiap emosi | happy😊, sad😢, angry😠, disgust🤢, neutral😐, fear😨 | **PASS** |
| E-05 | Path aset ikon emosi benar | — | 1. Periksa `assetIconPath` | `happy.png`, `anger.png`, `fear.png` berada di folder `assets/icon/emosi/` | **PASS** |
| E-06 | Ikon Material tersedia untuk tiap emosi | — | 1. Periksa `icon` tiap emosi | Seluruh emosi memiliki ikon valid | **PASS** |
| E-07 | Nilai emosi (positif/negatif/netral) | — | 1. Periksa `emotionValue` | happy **positif**; neutral **0**; sad/angry/fear/disgust **negatif** | **PASS** |
| E-08 | Label nilai memakai tanda +/- | — | 1. Periksa `valueLabel` | happy bertanda `+`; sad tidak bertanda (negatif) | **PASS** |
| E-09 | Pesan psikologis mengikuti bahasa | Locale = `id` | 1. Bandingkan `psychMessage` | `fear.psychMessage` = terjemahan `msg_fear` | **PASS** |
| E-10 | Status psikologis non-kosong untuk semua emosi | — | 1. Periksa `psychStatus` tiap emosi | Semua terisi | **PASS** |
| E-11 | Saran perekaman tersedia untuk semua emosi | — | 1. Periksa `recordingSuggestions` | Setiap emosi memiliki minimal satu saran | **PASS** |
| E-12 | Semua tag pemicu punya nama & emoji | — | 1. Periksa tiap `TriggerTag` | `displayName` & `emoji` terisi | **PASS** |
| E-13 | Tag pemicu "Pekerjaan" mengikuti bahasa | Locale = `id` | 1. Bandingkan `work.displayName` | Sama dengan terjemahan `trigger_work` | **PASS** |
| E-14 | Format waktu rekaman | — | 1. Buat rekaman 5 Mar 2024 09:30 | Format tampilan = **"5 Mar, 09:30"** | **PASS** |
| E-15 | Konversi confidence ke persen | Confidence = 0.872 | 1. Periksa `confidencePercent` | = **"87%"** (pembulatan) | **PASS** |
| E-16 | Skor emosi = nilai emosi × confidence | Happy, confidence 0.5 | 1. Hitung `emotionScore` | happy = **+5.0**; sad = nilai sad × 0.5 (negatif) | **PASS** |
| E-17 | Label skor emosi 1 desimal dengan tanda | Happy & sad, confidence 0.5 | 1. Periksa `emotionScoreLabel` | happy = **"+5.0"**; sad = **"-3.0"** | **PASS** |
| E-18 | Data emosi terbaru valid | — | 1. Periksa `latestEmotion` | Confidence di rentang **0.0–1.0** | **PASS** |
| E-19 | Riwayat emosi berisi 10 rekaman | — | 1. Periksa `emotionHistory` | Panjang = **10** | **PASS** |
| E-20 | Frekuensi emosi menjumlah 6 emosi | — | 1. Periksa `emotionFrequency` | Total = **12**, 6 jenis | **PASS** |
| E-21 | Skor deteksi ternormalisasi | — | 1. Jumlahkan `detectionScores` | Total ≈ **1.0** | **PASS** |

### 4.8 Model User — Big Five OCEAN, Psy (`test/models/user_model_test.dart`)

| ID | Skenario | Prekondisi | Langkah | Hasil yang Diharapkan | Status |
|---|---|---|---|---|---|
| U-01 | Konstruksi user & salin dengan perubahan | Data user tersedia | 1. Buat user<br>2. `copyWith` nama & skor | Field yang diubah ter-update; field asli tidak berubah | **PASS** |
| U-02 | Kategori kesehatan mental mengikuti ambang batas | Skor psy tersedia | 1. Uji skor 100/76/60/51/30/26/10/null | `null`→"Belum Dinilai"; `≥76`→Sehat Optimal; `51–75`→Cukup; `26–50`→Rentan; `<26`→Butuh Perhatian Klinis | **PASS** |
| U-03 | Deskripsi & saran tersedia di semua level | — | 1. Uji skor null/100/60/30/10 | Deskripsi & saran selalu **tidak kosong** | **PASS** |
| U-04 | Deteksi kelengkapan Big Five & ringkasan | User ber/atau tanpa Big Five | 1. Periksa `hasBigFive` & `bigFiveSummary` | User dengan skor → `hasBigFive=true`, ringkasan memuat "Openness"; tanpa skor → `false`, ringkasan kosong | **PASS** |
| U-05 | Kekuatan (strengths) mencerminkan skor | Skor Big Five ada, N rendah (2.4) | 1. Periksa `bigFiveStrengths` | Berisi **"Stabil Emosi"** (N < 2.5) | **PASS** |
| U-06 | Deskripsi Big Five tersedia bilingual | — | 1. Cek dalam ID & EN | Memuat "Big Five" di kedua bahasa | **PASS** |
| U-07 | Perhitungan rata-rata per dimensi Big Five | 4 soal per dimensi (2 keyed +, 2 keyed −) | 1. Jawab soal O: 4,4,5,1 | Skor **O = 3.5** (reverse scoring diterapkan) | **PASS** |
| U-08 | Reverse scoring soal ber-keyed − benar | Soal keyed − | 1. Jawab 1 pada soal keyed + dan keyed − | Skor O = **3.0** (jawaban 1 pada keyed − diubah menjadi 5) | **PASS** |
| U-09 | Hasil memuat 5 dimensi | — | 1. Jawab semua netral (3) | Skor memuat **O, C, E, A, N** | **PASS** |
| U-10 | Parsing soal Big Five dari JSON | Data JSON soal | 1. Parse `{id, dimension, dimension_name, keyed, statement}` | `question`, `dimension`, `keyed` terbaca benar | **PASS** |
| U-11 | Parsing soal psy dari JSON beserta opsi | Data JSON soal | 1. Parse `{id, category, question, options}` | 2 opsi terbaca; skor opsi 0 & 3 sesuai | **PASS** |

### 4.9 Deteksi Emosi dari Teks (`test/services/text_emotion_service_test.dart`)

| ID | Skenario | Prekondisi | Langkah | Hasil yang Diharapkan | Status |
|---|---|---|---|---|---|
| T-01 | Teks kosong mengembalikan profil default | Kamus emosi dimuat | 1. Analisis teks `""` | Neutral = 0.5, Happy = 0.1 (profil default) | **PASS** |
| T-02 | Teks bahagia terdeteksi dominan happy | Kamus dimuat | 1. Analisis "Hari ini aku sangat bahagia, senang dan puas sekali!" | Emosi dominan = **happy**, skor happy > 0.5 | **PASS** |
| T-03 | Teks sedih terdeteksi dominan sad | Kamus dimuat | 1. Analisis "Aku merasa sedih dan kecewa, hatiku pilu" | Emosi dominan = **sad** | **PASS** |
| T-04 | Teks marah terdeteksi dominan angry | Kamus dimuat | 1. Analisis "Aku marah sekali, kesal dan benci" | Emosi dominan = **angry** | **PASS** |
| T-05 | Teks takut terdeteksi dominan fear | Kamus dimuat | 1. Analisis "Aku takut, khawatir dan cemas berlebihan" | Emosi dominan = **fear** | **PASS** |
| T-06 | Kata majemuk (2 kata) dihitung lebih dari satu | Kamus dimuat | 1. Analisis "terima kasih banyak" | Skor happy meningkat (> 0.1) karena kata majemuk | **PASS** |
| T-07 | Hasil selalu ternormalisasi total 1.0 | Kamus dimuat | 1. Analisis teks campuran 6 emosi | Total seluruh probabilitas ≈ **1.0** | **PASS** |
| T-08 | Mendukung keyword bahasa Inggris | Kamus dimuat | 1. Analisis "I am so happy and excited today" | Emosi dominan = **happy** | **PASS** |

### 4.10 Saran & Rujukan Keselamatan (`test/services/suggestion_service_test.dart`)

| ID | Skenario | Prekondisi | Langkah | Hasil yang Diharapkan | Status |
|---|---|---|---|---|---|
| SU-01 | Profil Big Five netral → saran default | Skor netral (3.0 semua) | 1. Minta saran untuk emosi sad | 1 saran trait "-" (Profil Seimbang); bukan rujukan keselamatan | **PASS** |
| SU-02 | Trait ekstrem menghasilkan saran per trait | O = 4.5 | 1. Minta saran untuk emosi happy | Saran memuat trait **O** | **PASS** |
| SU-03 | Trait rendah diklasifikasikan "Rendah" | N = 2.2 | 1. Minta saran untuk emosi fear | Saran trait **N** level **"Rendah"** | **PASS** |
| SU-04 | Saran tiap trait dibatasi maksimal 2 | Semua trait ekstrem | 1. Minta saran untuk emosi angry | Setiap trait maksimal 2 saran | **PASS** |
| SU-05 | Konsistensi daftar saran lengkap vs pertama | O=4.5, N=2.0 | 1. Bandingkan `allSuggestions` & `firstSuggestion` | Saran pertama = elemen pertama daftar lengkap | **PASS** |
| SU-06 | Kompatibilitas API lama (flat list) | — | 1. Panggil `getSuggestions` | Mengembalikan daftar string | **PASS** |
| SU-07 | Judul saran menyebutkan emosi | Emosi sad | 1. Bangun judul saran | Judul memuat nama emosi "Sedih" | **PASS** |
| SU-08 | Dimensi dominan = nilai tertinggi | O = 4.5 | 1. Cari dimensi dominan | = **"O"**; untuk data kosong = string kosong | **PASS** |
| SU-09 | Data rujukan keselamatan tersedia | — | 1. Minta data keselamatan | `isSafetyReferral=true`; pesan & daftar aksi keselamatan terisi | **PASS** |

### 4.11 Penyimpanan Lokal & Limit Harian (`test/services/storage_service_test.dart`)

| ID | Skenario | Prekondisi | Langkah | Hasil yang Diharapkan | Status |
|---|---|---|---|---|---|
| ST-01 | First launch default true | Penyimpanan kosong | 1. Cek `isFirstLaunch` | = **true** | **PASS** |
| ST-02 | Menyelesaikan onboarding menandai selesai & menyimpan nama | Penyimpanan kosong | 1. Panggil `setOnboardingComplete('Budi')` | `isFirstLaunch=false`; nama = **"Budi"** | **PASS** |
| ST-03 | Nama default "User" | Penyimpanan kosong | 1. Cek `getUserName` | = **"User"** | **PASS** |
| ST-04 | Reset onboarding mengembalikan first launch | Onboarding selesai | 1. Panggil `resetOnboarding` | `isFirstLaunch=true` kembali | **PASS** |
| ST-05 | Sisa deteksi harian awal = 5 | Penyimpanan kosong | 1. Cek `getRemainingDetections(uid)` | = **5** | **PASS** |
| ST-06 | Setiap deteksi mengurangi sisa | Sisa awal 5 | 1. Deteksi 3× | Sisa = **2** | **PASS** |
| ST-07 | Limit tidak pernah negatif | Sisa 0 | 1. Deteksi 10× | Sisa = **0** (bukan negatif) | **PASS** |
| ST-08 | Hitungan terpisah per akun (uid) | — | 1. Deteksi 2× pada uid A<br>2. Cek uid B & uid A | uid B sisa **5**; uid A sisa **3** | **PASS** |

### 4.12 Ekspor Laporan PDF (`test/services/pdf_export_service_test.dart`)

| ID | Skenario | Prekondisi | Langkah | Hasil yang Diharapkan | Status |
|---|---|---|---|---|---|
| P-01 | Ekspor laporan pengguna menghasilkan PDF valid | Data user & rekaman tersedia | 1. Panggil `generateUserReport` | Hasil berupa bytes PDF; header **%PDF**; data tidak kosong | **PASS** |
| P-02 | Ekspor laporan semua pengguna menghasilkan PDF valid | Daftar user (dengan & tanpa skor) | 1. Panggil `generateAllUsersReport` | Bytes PDF valid (header **%PDF**); tidak kosong; menangani skor `null` | **PASS** |

### 4.13 State Management — Provider (`test/providers/providers_test.dart`)

| ID | Skenario | Prekondisi | Langkah | Hasil yang Diharapkan | Status |
|---|---|---|---|---|---|
| PV-01 | Locale default = id | Penyimpanan kosong | 1. Inisialisasi LocaleProvider | `locale = id` | **PASS** |
| PV-02 | Locale tersimpan dimuat ulang | Prefs berisi `app_locale=en` | 1. Inisialisasi LocaleProvider | `locale = en` | **PASS** |
| PV-03 | Set & toggle locale tersimpan | — | 1. Set `en` → toggle | `locale=en` lalu `id`; nilai tersimpan ke prefs | **PASS** |
| PV-04 | Set locale sama tidak memicu notifikasi | `locale=id` | 1. Set `id` lagi | Listener **tidak** dipanggil | **PASS** |
| PV-05 | Tema default light | Penyimpanan kosong | 1. Inisialisasi ThemeProvider | `themeMode=light`, `isDark=false` | **PASS** |
| PV-06 | Tema tersimpan dimuat ulang | Prefs berisi `app_theme_mode=dark` | 1. Inisialisasi ThemeProvider | `isDark=true` | **PASS** |
| PV-07 | Set & toggle tema tersimpan | — | 1. Set dark → toggle | `dark` lalu `light`; nilai tersimpan ke prefs | **PASS** |
| PV-08 | Status premium default non-premium | — | 1. Inisialisasi PremiumProvider | `isPremium=false`, tanpa tanggal kedaluwarsa | **PASS** |
| PV-09 | Set & hapus premium | — | 1. Set premium 30 hari → set premium kedaluwarsa → hapus | `isPremium=true` → `isExpired=true` (bila lewat) → `isPremium=false` | **PASS** |
| PV-10 | Notifikasi perubahan state premium | — | 1. Pasang listener<br>2. Set premium | Listener terpanggil (1×) | **PASS** |

---

## 5. Matriks Cakupan

| Area Fungsional | Jumlah Kasus | Hasil |
|---|---|---|
| Splash & Routing | 2 | 2 PASS |
| Onboarding | 12 | 12 PASS |
| Autentikasi | 6 | 6 PASS |
| Pengaturan | 5 | 5 PASS |
| Lokalisasi | 7 | 7 PASS |
| Emosi (model) | 21 | 21 PASS |
| Profil Psikologi (Big Five OCEAN/Psy) | 11 | 11 PASS |
| Deteksi Emosi Teks | 8 | 8 PASS |
| Saran & Keselamatan | 9 | 9 PASS |
| Penyimpanan & Limit Harian | 8 | 8 PASS |
| Ekspor PDF | 2 | 2 PASS |
| Provider/State | 10 | 10 PASS |
| **Total** | **101** | **101 PASS (100%)** |

## 6. Catatan Teknis Pengujian

1. **Pemisahan Firebase di lingkungan uji**: modul autentikasi Firebase (`AuthProvider`) tidak diuji otomatis karena membutuhkan emulator/backend Firebase. Kasus uji fokus pada validasi form, toggle visibilitas, dan prasyarat privasi.
2. **I/O nyata pada router awal**: proses warm-up (unduh model Whisper, path provider) disimulasikan di test sehingga routing tidak menggantung. Kegagalan unduh model secara *graceful* (HTTP 400) terbukti tidak mengganggu navigasi.
3. **Font**: seluruh varian berat Poppins (Light–Black) dibundel sebagai aset agar tampilan konsisten tanpa unduhan runtime saat pengujian.
4. **Limit harian deteksi**: disimulasikan dengan penyimpanan lokal; alur server (Firestore) diuji terpisah.

## 7. Saran Pengujian Lanjutan (Manual / Belum Otomatis)

Kasus berikut disarankan diuji secara manual karena memerlukan backend asli, perangkat keras, atau jaringan nyata:

| Area | Skenario yang Disarankan |
|---|---|
| Autentikasi | Login sukses dengan email/password; login Google; lupa password; logout |
| Backend | Simpan/hapus data ke Firestore; sinkronisasi riwayat antar perangkat |
| Rekam Audio | Rekaman suara, transkripsi, deteksi emosi dari audio dengan model Whisper nyata |
| Premium | Alur pembayaran, restorasi pembelian, aktivasi fitur premium |
| Notifikasi | Notifikasi harian/pengingat |
| Perangkat | Izin mikrofon, kamera, penyimpanan; rotasi layar; mode gelap sistem |

## 8. Kesimpulan

Berdasarkan pelaksanaan blackbox testing otomatis terhadap **101 kasus uji** yang mencakup seluruh modul fungsional utama aplikasi Fem-Psych Monitor:

> **Hasil: 101/101 PASS (tingkat keberhasilan 100%). Tidak ditemukan cacat fungsional (defect) pada lingkup yang diuji.**

Aplikasi dinyatakan **siap melanjutkan ke pengujian integrasi dan pengujian manual** untuk skenario yang membutuhkan backend/device nyata.
