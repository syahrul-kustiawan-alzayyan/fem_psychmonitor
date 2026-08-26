Blueprint Dokumen
# FemPsychMonitor
Aplikasi Deteksi Emosi Suara Non-Invasif untuk Mendukung Pemantauan Kesehatan Mental Perempuan

Dokumen Spesifikasi & Perancangan Aplikasi
Versi 2.0 (disesuaikan dengan hasil publikasi jurnal terbaru)

Dipersiapkan oleh:
Dede Kurniadi | Asri Mulyani | Wiyoga Baswardono | Syahrul Al Zayyan
Ahmad Sahid | Yoga Agustiansyah | Agisni Hafitri

Riwayat Dokumen

| Versi | Tanggal | Deskripsi Perubahan | Penulis |
|---|---|---|---|
| 1.0 | 2024 | Draf awal blueprint (model CNN-LSTM unimodal, TKT 3) | Tim |
| 2.0 | Agustus 2026 | Pembaruan menyeluruh mengacu pada hasil publikasi jurnal "FemPsychMonitor: Non-Invasive Female Emotional State Detection on Android via Hybrid Deep Learning Architectures" (IJIES) — perubahan arsitektur model menjadi CNN-BiLSTM-Transformer, penambahan modalitas teks (Whisper STT), fusi multimodal asimetris 60:40, integrasi Big Five (OCEAN), skrining psikologis wanita, rekomendasi coping deterministik, serta pembaruan seluruh metrik evaluasi dan arsitektur privasi | Tim |

---

## KATA PENGANTAR

Puji dan syukur kami panjatkan atas rahmat dan karunia-Nya, sehingga dokumen blueprint aplikasi FemPsychMonitor — Aplikasi Deteksi Emosi Suara Non-Invasif untuk Mendukung Pemantauan Kesehatan Mental Perempuan — ini dapat diselesaikan dengan baik.

Aplikasi ini dikembangkan sebagai bagian dari inovasi teknologi kesehatan mental (mHealth) yang bertujuan menjawab bias gender pada sistem Speech Emotion Recognition (SER) konvensional, sekaligus menghadirkan solusi pemantauan psikologis perempuan yang berjalan sepenuhnya on-device demi menjaga privasi pengguna. Dokumen ini merupakan pembaruan dari blueprint versi sebelumnya, disesuaikan dengan hasil riset dan evaluasi yang telah dipublikasikan pada jurnal internasional (International Journal of Intelligent Engineering and Systems).

Aplikasi ini dilengkapi dengan fitur deteksi emosi berbasis suara dan teks (multimodal), kuesioner kepribadian Big Five (OCEAN), skrining psikologis khusus perempuan, riwayat skor kesehatan mental (Emotion Trend Score), serta rekomendasi coping mechanism yang dipersonalisasi secara deterministik. Kami berharap FemPsychMonitor dapat menjadi alat bantu digital yang bermanfaat bagi perempuan Indonesia dalam memantau dan menjaga kesejahteraan psikologisnya secara mandiri, aman, dan privat.

Kami menyadari dokumen ini masih dapat disempurnakan; kritik dan saran yang membangun sangat kami harapkan.

Garut, Agustus 2026
Tim Pengembang

---

## DAFTAR ISI

1. Pendahuluan
2. Tujuan Utama
3. Fitur Aplikasi
4. Requirement System
5. Use Case System
6. Arsitektur Sistem
7. Spesifikasi Model Kecerdasan Buatan
8. Desain UI/UX
9. Rencana Pengembangan
10. Keamanan Data dan Privasi
11. Business Model Canvas (BMC)
12. Strategi Peluncuran dan Pemasaran
13. Pengembangan Fitur di Masa Depan
14. Rencana Pengembangan Jangka Panjang Berdasarkan TKT
Daftar Pustaka

---

## 1. PENDAHULUAN

Kondisi emosional memegang peran penting dalam membentuk pola kognitif, pengambilan keputusan, dan interaksi sosial seseorang. Dalam komunikasi verbal, atribut akustik seperti pitch, kecepatan bicara, dan intonasi kerap menyampaikan kondisi psikologis yang melampaui makna literal ucapan. Meski sistem Speech Emotion Recognition (SER) berbasis kecerdasan buatan berkembang pesat, bias gender masih menjadi tantangan mendasar: arsitektur ekstraksi fitur yang ada umumnya tidak dirancang untuk menangkap karakteristik vokal perempuan yang secara fisiologis memiliki pita suara lebih pendek, sehingga akurasi deteksi emosi pada suara perempuan cenderung lebih rendah dibanding laki-laki.

Riset sebelumnya telah merumuskan model hybrid CNN-BiLSTM-Transformer yang dirancang khusus untuk analisis suara perempuan dan mencapai akurasi 88,52%. Namun, menerjemahkan arsitektur hybrid yang berat secara komputasi tersebut ke ekosistem mobile nyata merupakan gap operasional tersendiri. Pada aplikasi kesehatan mental, migrasi dari pemrosesan berbasis cloud ke paradigma edge computing menjadi keharusan agar inferensi dapat berjalan real-time sekaligus menjaga privasi data pengguna secara ketat — mengingat rekaman suara termasuk data biometrik yang sangat sensitif.

Selain itu, mengandalkan fitur akustik semata (unimodal) memiliki keterbatasan, terutama meningkatnya risiko kesalahan klasifikasi pada emosi dengan tingkat arousal yang mirip (misalnya marah dan takut). Pendekatan Multimodal Emotion Recognition (MER) — memadukan sinyal suara dan teks — terbukti memberikan asesmen afektif yang lebih dalam dan margin kesalahan yang lebih rendah. Di sisi lain, platform kesehatan mental digital saat ini masih sangat bergantung pada kuesioner self-report konvensional, yang rentan terhadap bias pelaporan diri karena pengguna dapat secara sadar maupun tidak sadar menyembunyikan kondisi psikologis sebenarnya.

Untuk menjawab kesenjangan tersebut, dikembangkan FemPsychMonitor, sebuah aplikasi mHealth berbasis Android yang menerjemahkan kemampuan klasifikasi model CNN-BiLSTM-Transformer ke dalam arsitektur mobile, dengan inferensi on-device melalui optimasi TensorFlow Lite. Berbeda dari riset sebelumnya yang hanya mengandalkan korpus internasional, model pada aplikasi ini dikalibrasi ulang menggunakan kombinasi dataset SER internasional (RAVDESS, CREMA-D, TESS) dan korpus suara Indonesia (E-SERAVD, IndoWaveSentiment), sehingga mampu menangkap nuansa afektif lokal secara lebih presisi. Secara fungsional, aplikasi memadukan klasifikasi akustik real-time dengan ekstraksi fitur semantik dari transkripsi Whisper Speech-to-Text, melalui protokol fusi asimetris on-device yang mengalokasikan bobot 60% untuk probabilitas akustik dan 40% untuk kecocokan kata kunci berbasis teks. Hasil asesmen emosi multimodal ini kemudian disandingkan dengan skrining stres pengguna dan profil kepribadian Big Five (OCEAN) untuk menghasilkan rekomendasi coping mechanism yang dipersonalisasi secara deterministik — bukan generatif — guna menghindari risiko halusinasi informasi. Rekaman suara diproses sepenuhnya di perangkat dan tidak pernah dikirim ke server; hanya metadata hasil analisis yang disimpan untuk keperluan riwayat dan sinkronisasi, sehingga privasi pengguna terjaga secara maksimal.

---

## 2. TUJUAN UTAMA

Aplikasi FemPsychMonitor bertujuan menjadi alat bantu digital yang non-invasif dan berbasis privasi bagi perempuan dalam memantau kondisi emosional dan kesehatan mentalnya secara mandiri, real-time, dan tanpa bias gender. Secara lebih spesifik, tujuan utama aplikasi ini meliputi:

1. **Menyediakan Deteksi Emosi yang Adil secara Gender (Gender-Aware AI)**
   FemPsychMonitor menggunakan model yang dikalibrasi khusus untuk karakteristik vokal perempuan, dilatih dan diverifikasi lintas dataset internasional dan lokal (Indonesia), untuk meminimalkan bias klasifikasi yang umum terjadi pada sistem SER konvensional.

2. **Menghadirkan Asesmen Emosi Multimodal yang Lebih Akurat**
   Dengan menggabungkan probabilitas akustik (60%) dan analisis semantik dari transkripsi ucapan (40%), aplikasi mampu mendeteksi ketidaksesuaian antara nada suara dan kata-kata yang diucapkan, sehingga mengurangi risiko self-reporting bias.

3. **Menjamin Privasi Penuh melalui Pemrosesan On-Device**
   Seluruh proses inferensi suara — mulai dari ekstraksi fitur akustik, transkripsi, hingga klasifikasi emosi — berjalan sepenuhnya pada perangkat pengguna (edge computing) menggunakan TensorFlow Lite. Rekaman suara tidak pernah meninggalkan perangkat; hanya metadata non-biometrik yang disinkronkan ke server.

4. **Mendukung Personalisasi Intervensi Berbasis Kepribadian**
   Melalui kuesioner Big Five (Mini-IPIP/OCEAN), aplikasi menyesuaikan gaya bahasa dan penekanan afektif dari rekomendasi coping mechanism sesuai profil kepribadian pengguna, tanpa memberi label diagnosis klinis yang kaku.

5. **Menyediakan Skrining Awal Psikologis Khusus Perempuan**
   Instrumen skrining 20 pertanyaan dirancang untuk mengidentifikasi pemicu distres spesifik perempuan seperti beban peran ganda, fluktuasi emosi hormonal, citra tubuh, batasan personal, kecemasan sosial, dan kelelahan emosional (burnout), dengan hasil yang berfungsi sebagai indikator skrining awal, bukan diagnosis klinis definitif.

6. **Mendukung Pengambilan Keputusan Berbasis Data (Emotion Trend Score)**
   Aplikasi mencatat riwayat emosi dan skor kesehatan mental dari waktu ke waktu, memungkinkan pengguna dan (bila relevan) tenaga profesional melihat tren psikologis secara longitudinal.

7. **Menghindari Risiko Halusinasi Informasi**
   Berbeda dari pendekatan generative AI, rekomendasi intervensi dihasilkan melalui matriks keputusan deterministik (cross-tabulasi emosi × kepribadian), sehingga setiap saran yang diberikan dapat ditelusuri dan dipertanggungjawabkan.

---

## 3. FITUR APLIKASI

Fitur-fitur FemPsychMonitor dikembangkan berdasarkan hasil riset yang telah dievaluasi secara empiris pada 1.749 sampel uji independen, dengan akurasi 89,59% dan rata-rata latensi inferensi 96,12 ms.

1) **Deteksi Emosi Multimodal (Live & Unggah Berkas)**
   a. Analisis emosi dari rekaman suara secara real-time maupun dari berkas audio yang diunggah (mono, 16 kHz).
   b. Model CNN-BiLSTM-Transformer (TensorFlow Lite) mengklasifikasikan 6 kelas emosi universal: senang, sedih, marah, takut, jijik, dan netral.
   c. Ditampilkan dalam bentuk confidence score dan visualisasi distribusi probabilitas emosi.

2) **Fusi Multimodal Asimetris (60:40)**
   a. Pipeline akustik (bobot 60%) memproses sinyal suara langsung melalui model TFLite.
   b. Pipeline semantik (bobot 40%) mentranskripsi ucapan menggunakan Whisper offline, lalu mencocokkannya dengan leksikon afektif dwibahasa (381 kata Inggris, 424 kata Indonesia termasuk variasi slang lokal).
   c. Kedua probabilitas digabung secara matematis untuk menghasilkan label emosi final dan skor kepercayaan.

3) **Onboarding Psikometri**
   a. Kuesioner Big Five (Mini-IPIP, 20 item, skala Likert 1–5) yang memetakan lima dimensi kepribadian: Openness, Conscientiousness, Extraversion, Agreeableness, Neuroticism.
   b. Kuesioner skrining psikologis khusus perempuan (20 item, skala 0–3) yang mencakup beban peran ganda, fluktuasi emosi hormonal, citra tubuh, batasan personal, kecemasan sosial, dan burnout emosional.

4) **Emotion Trend Score & Mental Baseline**
   a. Skor kesehatan mental awal dari hasil skrining (dinormalisasi ke skala 0–100) dikategorikan ke dalam 4 stratifikasi klinis: Optimal Health, Moderately Healthy, Vulnerable, dan Requires Clinical Attention.
   b. Skor ini bersifat dinamis dan terus diperbarui secara real-time berdasarkan hasil deteksi emosi (rentang penyesuaian hingga ±17 poin), menggunakan bobot valensi psikologis tiap kelas emosi.

5) **Rekomendasi Coping Mechanism Deterministik**
   a. Sistem mencocokkan 6 kelas emosi × 5 dimensi kepribadian × 2 level (tinggi/rendah) × 5 opsi, menghasilkan basis data 300 konfigurasi rekomendasi.
   b. Setiap sesi menampilkan 10 rekomendasi (2 dari setiap dimensi kepribadian) yang dipilih secara acak agar tidak membebani pengguna secara kognitif.
   c. Pendekatan deterministik dipilih secara sengaja untuk menghindari risiko halusinasi informasi yang umum pada model generatif.

6) **Riwayat (History)**
   Arsip lokal terenkripsi yang mencatat perkembangan emosi pengguna secara kronologis; hanya metadata (bukan rekaman audio) yang disinkronkan ke server untuk mendukung akses lintas perangkat.

7) **Profil Pengguna**
   Menampilkan profil kepribadian (Big Five), skor kesehatan mental terkini, dan riwayat pemantauan emosi.

8) **Edukasi & Informasi**
   Materi edukasi terkait kesehatan mental, gender bias pada AI, dan cara kerja aplikasi.

9) **Tentang Aplikasi**
   Informasi sumber data, metodologi model, tim pengembang, serta batasan penggunaan aplikasi (bukan alat diagnosis klinis).

---

## 4. REQUIREMENT SYSTEM

### 1) Kebutuhan Fungsional
a. Sistem menyediakan fitur agar pengguna dapat mendaftar dan masuk (login) ke dalam sistem.
b. Sistem dapat merekam suara secara live maupun menerima unggahan berkas audio (WAV/MP3, mono, 16 kHz).
c. Sistem dapat melakukan preprocessing audio (pre-emphasis filter, framing, windowing) dan ekstraksi fitur akustik (MFCC, Delta, Delta-Delta, ZCR).
d. Sistem dapat menjalankan inferensi model CNN-BiLSTM-Transformer (TFLite) secara on-device untuk menghasilkan probabilitas 6 kelas emosi.
e. Sistem dapat mentranskripsi ucapan pengguna secara offline menggunakan Whisper STT.
f. Sistem dapat mencocokkan hasil transkripsi dengan leksikon afektif dwibahasa untuk menghasilkan probabilitas emosi berbasis teks.
g. Sistem dapat menggabungkan probabilitas akustik dan teks dengan bobot asimetris 60:40 untuk menghasilkan label emosi final dan confidence score.
h. Sistem menyediakan kuesioner Big Five (OCEAN) dan kuesioner skrining psikologis khusus perempuan pada tahap onboarding.
i. Sistem dapat menghitung dan memperbarui Emotion Trend Score/mental baseline secara real-time.
j. Sistem dapat menghasilkan rekomendasi coping mechanism secara deterministik berdasarkan kombinasi emosi terdeteksi dan profil kepribadian.
k. Sistem menyediakan riwayat (History) hasil deteksi emosi secara kronologis.
l. Sistem memungkinkan admin mengelola konten edukasi dan basis data rekomendasi.

### 2) Kebutuhan Non-Fungsional
a. Sistem menjamin seluruh pemrosesan audio (rekaman, fitur, transkripsi, inferensi) berjalan on-device dan tidak mengirimkan berkas audio ke server.
b. Sistem memiliki rata-rata latensi inferensi ≤ 100 ms untuk pengalaman real-time (hasil evaluasi: 96,12 ms rata-rata, P99 104,39 ms).
c. Ukuran model TFLite terkompresi dijaga tetap ringan (hasil evaluasi: 685,52 KB) agar tidak membebani perangkat kelas menengah-bawah.
d. Sistem dapat menangani beban inferensi batch dengan throughput yang skalabel (10,3–421,1 sampel/detik pada batch size 1–64).
e. Sistem menjamin keamanan dan enkripsi data pribadi serta metadata pengguna.
f. Sistem dapat berjalan pada platform mobile Android dan terkoneksi jaringan internet hanya untuk sinkronisasi metadata (bukan audio).
g. Sistem dirancang modular agar mudah diperbarui, termasuk pembaruan rasio fusi multimodal dan basis data rekomendasi di masa depan.

---

## 5. USE CASE SYSTEM

**Aktor Utama:**
- **Pengguna**: individu (khususnya perempuan) yang ingin memantau kondisi emosional dan kesehatan mentalnya.
- **Admin**: mengelola konten edukasi, basis data rekomendasi coping mechanism, dan pengguna dari sisi backend.

**Use Case Pengguna:**
- Daftar / Login / Ganti Kata Sandi / Lupa Kata Sandi
- Mengisi Kuesioner Onboarding (Big Five & Skrining Psikologis Perempuan)
- Merekam Suara secara Live
- Mengunggah Berkas Audio
- Melihat Hasil Deteksi Emosi (label, confidence score, distribusi probabilitas)
- Melihat Transkripsi Ucapan (opsional)
- Melihat Emotion Trend Score / Mental Baseline
- Melihat Rekomendasi Coping Mechanism yang Dipersonalisasi
- Melihat Riwayat Pemantauan Emosi
- Melihat Profil dan Hasil Big Five
- Melihat Konten Edukasi

**Use Case Admin:**
- Kelola Pengguna
- Kelola Basis Data Rekomendasi (300 konfigurasi coping mechanism)
- Kelola Leksikon Afektif Dwibahasa
- Kelola Konten Edukasi
- Memantau Metadata Agregat (bukan audio) untuk keperluan riset lanjutan

Setelah login, sistem melakukan verifikasi token untuk memastikan hanya pengguna sah yang dapat mengakses profil, riwayat, dan data psikologisnya sendiri.

---

## 6. ARSITEKTUR SISTEM

Arsitektur FemPsychMonitor menerapkan pendekatan **privacy-by-design / on-device processing**, di mana seluruh beban komputasi inferensi suara — akustik maupun semantik — dijalankan sepenuhnya di perangkat pengguna (edge device), sementara server hanya berperan sebagai penyedia layanan autentikasi, konten edukasi, dan penyimpanan metadata non-biometrik.

**Komponen Utama:**

a. **Frontend (Aplikasi Mobile Android)**
   - Antarmuka perekaman suara, kuesioner onboarding, dashboard skor kesehatan mental, dan halaman rekomendasi.
   - Menjalankan seluruh pipeline inferensi secara lokal (TFLite Runtime + FlexDelegate/Select_TF_Ops untuk mendukung layer BiLSTM).

b. **On-Device AI Pipeline**
   - **Pipeline Akustik**: Preprocessing → Ekstraksi Fitur (MFCC + Delta + Delta-Delta + ZCR, matriks 128×121) → Model CNN-BiLSTM-Transformer (TFLite) → Probabilitas 6 kelas emosi (bobot 60%).
   - **Pipeline Semantik**: Whisper STT offline → Pencocokan Leksikon Afektif Dwibahasa → Probabilitas 6 kelas emosi (bobot 40%).
   - **Fusion Engine**: Menggabungkan kedua probabilitas secara matematis (Algoritma Fusi Probabilitas Asimetris) → Emosi final + confidence score.
   - **Recommendation Engine**: Cross-tabulasi emosi × Big Five → basis data 300 konfigurasi coping mechanism → 10 rekomendasi per sesi.

c. **API (Backend)**
   - Menangani autentikasi (token/JWT), sinkronisasi metadata riwayat, pengelolaan konten edukasi, dan basis data rekomendasi.
   - Tidak pernah menerima atau menyimpan berkas audio pengguna.

d. **Database**
   - Menyimpan profil pengguna, hasil kuesioner Big Five & skrining, metadata hasil deteksi emosi (label, skor, waktu), dan konten edukasi.

e. **Admin Dashboard**
   - Digunakan admin untuk mengelola konten edukasi, basis data rekomendasi, dan leksikon afektif.

**Alur Data Utama:**
1. Pengguna merekam/mengunggah audio → diproses sepenuhnya di perangkat (preprocessing, ekstraksi fitur, inferensi akustik, transkripsi, pencocokan leksikon).
2. Fusion Engine menghasilkan label emosi final + confidence score di perangkat.
3. Emotion Trend Score diperbarui secara lokal berdasarkan valensi emosi dan confidence score.
4. Recommendation Engine menghasilkan 10 rekomendasi coping mechanism di perangkat.
5. Hanya metadata (label emosi, skor, waktu, tanpa audio) yang dikirim ke server untuk sinkronisasi riwayat lintas perangkat.

---

## 7. SPESIFIKASI MODEL KECERDASAN BUATAN (AI)

Inti dari aplikasi ini adalah model deep learning hybrid yang telah dievaluasi dan dipublikasikan secara ilmiah.

- **Arsitektur:** CNN (ekstraksi pola spasial/spektral) → BiLSTM (pemodelan konteks temporal dua arah, 128 unit) → Transformer Encoder (Multi-Head Attention, 4 head, key_dim=64, untuk meningkatkan akurasi pada emosi yang ambigu, mis. marah vs takut).
- **Fitur Input:** Matriks 128×121 (40 MFCC + 40 Delta + 40 Delta-Delta + 1 ZCR), hasil preprocessing sinyal 16 kHz dengan pre-emphasis filter dan Hamming window.
- **Dataset Pelatihan:** RAVDESS, CREMA-D, TESS (internasional) + E-SERAVD, IndoWaveSentiment (Indonesia) — total 6 kelas emosi (senang, sedih, marah, takut, jijik, netral) dengan penanganan class imbalance melalui bobot kelas (Scikit-Learn 'balanced').
- **Fusi Multimodal:** Asimetris 60% (akustik/TFLite) : 40% (semantik/Whisper + leksikon dwibahasa).
- **Format Deployment:** TensorFlow Lite (.tflite), dikonversi dengan FlexDelegate & Select_TF_Ops untuk mendukung operasi BiLSTM.
- **Ukuran Model:** 685,52 KB (sangat ringan untuk perangkat Android kelas menengah-bawah).
- **Akurasi Uji (1.749 sampel independen):** 89,59% (naik dari baseline unimodal 88,52%).
- **Latensi Inferensi:** rata-rata 96,12 ms, median 96,21 ms, P99 104,39 ms.
- **Throughput (batch scalability):** 10,3 sampel/detik (batch 1) hingga 421,1 sampel/detik (batch 64).
- **AUC-ROC:** mendekati sempurna di seluruh 6 kelas emosi, menunjukkan kapabilitas diskriminatif tinggi meski model telah dikompresi untuk edge deployment.

> Catatan penting (transparansi riset): rasio fusi 60:40 saat ini didasarkan pada argumentasi teoretis psikologi klinis dan belum melalui uji ablasi empiris terhadap rasio alternatif (mis. 50:50 atau 70:30). Instrumen skrining psikologis perempuan juga belum melalui uji validitas/reliabilitas formal (mis. Cronbach's alpha, validasi konstruk terhadap DASS-21/PHQ-9), sehingga skornya berfungsi sebagai indikator awal, bukan diagnosis klinis.

---

## 8. DESAIN UI/UX

Desain antarmuka FemPsychMonitor mengusung pendekatan *Clean & Minimalist* untuk memberikan rasa tenang dan aman kepada pengguna yang mungkin sedang dalam kondisi rentan secara emosional, dengan prinsip aksesibilitas psikologis (meminimalkan beban kognitif).

**Struktur Navigasi:**
- **Onboarding**: Kuesioner Big Five & Skrining Psikologis Perempuan.
- **Home**: Ringkasan skor kesehatan mental harian (Emotion Trend Score), akses cepat ke perekaman suara.
- **Record**: Perekaman suara live / unggah berkas audio (One-Tap Action).
- **Detection Detail**: Hasil deteksi emosi dominan, distribusi probabilitas 6 kelas emosi, confidence score, transkripsi (opsional).
- **Suggestion / Rekomendasi**: 10 rekomendasi coping mechanism yang dipersonalisasi berdasarkan emosi + Big Five.
- **History**: Riwayat kronologis hasil deteksi emosi dan skor kesehatan mental.
- **Profil**: Data profil, hasil Big Five, pengaturan akun, dan informasi privasi.

**Identitas Visual (usulan arah desain, mengikuti prinsip BIMA/StuntShield):**
- Palet warna tenang (soft blue/lavender/teal) untuk membangun rasa aman dan mengurangi stigma seputar kesehatan mental — berbeda dari warna hijau tegas pada aplikasi gizi.
- Ikonografi lembut (bukan tajam/agresif) untuk merepresentasikan empati dan perlindungan psikologis.
- Tipografi dengan keterbacaan tinggi dan kesan hangat, konsisten di seluruh layar.

---

## 9. RENCANA PENGEMBANGAN

Mengikuti tahapan standar rekayasa perangkat lunak: **Analisis → Desain → Implementasi → Verifikasi (Pengujian) → Maintenance**, dengan penyesuaian berikut berdasarkan hasil riset terbaru:

1) **Analisis** — Riset gender bias pada SER, kebutuhan multimodal fusion, serta studi literatur psikometri (Big Five, instrumen skrining perempuan).
2) **Desain** — Perancangan arsitektur on-device (client-first), UI/UX onboarding psikometri, dan skema fusi 60:40.
3) **Implementasi** — Pelatihan & fine-tuning model CNN-BiLSTM-Transformer, konversi TFLite, integrasi Whisper offline, pengembangan Recommendation Engine (300 konfigurasi), coding aplikasi Android.
4) **Verifikasi (Pengujian)** — Confusion Matrix & AUC-ROC pada 1.749 sampel uji, uji latensi & batch scalability, Penetration Testing, serta uji stabilitas dual-modalitas (SER TFLite + Whisper ~142 MB) berjalan bersamaan tanpa crash/thermal throttling.
5) **Maintenance** — Pembaruan berkelanjutan: ablasi rasio fusi, validasi psikometrik instrumen skrining, ekspansi korpus dialek lokal, dan uji lapangan longitudinal.

---

## 10. KEAMANAN DATA DAN PRIVASI

Mengingat sensitivitas data suara dan psikologis, keamanan dan privasi menjadi prioritas utama:

1) **Pemrosesan Audio 100% On-Device** — Rekaman suara tidak pernah ditransmisikan ke server; seluruh ekstraksi fitur, transkripsi, dan inferensi emosi berjalan lokal di perangkat.
2) **Metadata-Only Server Storage** — Hanya hasil analisis (label emosi, skor, waktu) yang disinkronkan ke server untuk keperluan riwayat, tanpa audio maupun transkrip mentah.
3) **Enkripsi Data** — Data profil, hasil kuesioner, dan metadata dienkripsi (AES-256) baik saat tersimpan (at rest) maupun dalam transmisi (SSL/TLS).
4) **Autentikasi Aman** — Menggunakan token/JWT untuk memastikan hanya pengguna sah yang dapat mengakses data psikologisnya sendiri.
5) **Transparansi Batasan Klinis** — Aplikasi secara eksplisit menyatakan bahwa hasil skrining dan deteksi emosi bersifat indikatif/pendukung, bukan pengganti diagnosis oleh tenaga profesional kesehatan mental.
6) **Kepatuhan Regulasi** — Dirancang selaras dengan prinsip Undang-Undang Perlindungan Data Pribadi di Indonesia, khususnya terkait data kesehatan yang tergolong data pribadi spesifik.

---

## 11. BUSINESS MODEL CANVAS (BMC)

| Key Partners | Key Activities | Value Propositions | Customer Relationships | Customer Segments |
|---|---|---|---|---|
| Institusi/lembaga kesehatan mental; Kemenkes/lembaga terkait women's health; NGO kesehatan mental perempuan; Perusahaan CSR bidang kesehatan mental | Pengembangan & pemeliharaan model AI; riset ablasi fusi multimodal; validasi psikometrik instrumen; kampanye edukasi anti-stigma | Deteksi emosi non-invasif & bebas bias gender; privasi penuh (on-device); rekomendasi coping personal berbasis kepribadian; skrining awal khusus perempuan | Edukasi interaktif; laporan tren emosi personal; umpan balik pengguna untuk penyempurnaan rekomendasi | Perempuan dewasa (mahasiswi, pekerja, ibu rumah tangga) yang ingin memantau kesehatan mental mandiri; komunitas/lembaga layanan kesehatan mental; peneliti psikologi klinis |
| **Key Resources** | | | **Channels** | |
| Tim riset AI & psikologi klinis; dataset SER internasional & lokal; infrastruktur cloud untuk metadata & konten edukasi | | | Google Play Store; media sosial & kampanye kesadaran kesehatan mental; kolaborasi dengan layanan konseling/psikolog | |

| Cost Structure | Revenue Streams |
|---|---|
| Riset & pengembangan model lanjutan (ablasi, validasi psikometrik); hosting metadata & konten edukasi; kampanye edukasi anti-stigma kesehatan mental | Kerja sama riset dengan institusi akademik/kesehatan; hibah riset pemerintah/organisasi internasional; kemitraan dengan layanan konseling profesional (referral non-otomatis) |

---

## 12. STRATEGI PELUNCURAN DAN PEMASARAN

1) **Pre-launch Campaign** — Edukasi publik tentang gender bias pada AI dan pentingnya deteksi emosi yang adil gender; kolaborasi dengan komunitas kesehatan mental perempuan.
2) **Peluncuran Resmi** — Rilis di Google Play Store dengan penekanan pada nilai privasi (on-device processing) sebagai diferensiator utama; kerja sama dengan psikolog/influencer kesehatan mental untuk edukasi penggunaan yang bertanggung jawab.
3) **Pasca Peluncuran** — Pemantauan umpan balik pengguna untuk penyempurnaan Recommendation Engine, serta uji lapangan longitudinal untuk memvalidasi dampak coping mechanism terhadap kesejahteraan psikologis pengguna.

---

## 13. PENGEMBANGAN FITUR DI MASA DEPAN

1) **Ablasi Rasio Fusi Multimodal** — Eksperimen empiris rasio 50:50, 70:30, dsb. untuk menggantikan asumsi teoretis 60:40 saat ini.
2) **Validasi Psikometrik Instrumen Skrining** — Uji Cronbach's alpha, validitas konstruk, dan benchmarking terhadap DASS-21/PHQ-9 bersama pakar psikologi klinis.
3) **Ekspansi Korpus Dialek Regional** — Menambah representasi suara dari berbagai dialek daerah di Indonesia.
4) **Mekanisme Deteksi Krisis Otomatis** — Sistem rujukan otomatis ke bantuan profesional saat pemantauan berkelanjutan menunjukkan indikasi distres klinis yang persisten.
5) **Uji Lapangan Longitudinal** — Studi dampak jangka panjang penggunaan aplikasi terhadap kesejahteraan psikologis pengguna nyata.

---

## 14. RENCANA PENGEMBANGAN JANGKA PANJANG BERDASARKAN TKT

**Tahun 1: TKT 3–4 (Bukti Konsep & Verifikasi Komponen)**
Riset gender bias SER, pengembangan model CNN-BiLSTM-Transformer awal, uji akurasi 88,52% (baseline unimodal) di laboratorium — *tahap ini telah tercapai dan dipublikasikan*.

**Tahun 2: TKT 5–6 (Validasi Prototipe)**
Ekspansi ke multimodal (audio+teks), fine-tuning dengan korpus Indonesia, konversi TFLite, integrasi Whisper, evaluasi pada 1.749 sampel uji independen mencapai akurasi 89,59% dengan latensi 96,12 ms — *tahap ini telah tercapai dan dipublikasikan pada jurnal terbaru*.

**Tahun 3: TKT 7–8 (Demonstrasi Operasional & Kesiapan Sistem)**
Integrasi penuh ke aplikasi Android (onboarding psikometri, Recommendation Engine 300 konfigurasi), uji beban & stabilitas dual-modalitas, User Acceptance Testing, persiapan peluncuran di Google Play Store.

**Tahun 4: TKT 9 (Operasional Penuh & Peningkatan Berkelanjutan)**
Ablasi rasio fusi, validasi psikometrik formal, ekspansi korpus dialek, mekanisme deteksi krisis, dan studi longitudinal dampak psikologis di lapangan.

---

## DAFTAR PUSTAKA

Mengacu pada daftar referensi lengkap jurnal "FemPsychMonitor: Non-Invasive Female Emotional State Detection on Android via Hybrid Deep Learning Architectures" (International Journal of Intelligent Engineering and Systems), termasuk rujukan pada: Kurniadi et al. (2025) untuk model dasar CNN-BiLSTM-Transformer; RAVDESS (Luna-Jiménez et al., 2021); CREMA-D (Cao et al., 2014); TESS; E-SERAVD (Santoso et al., 2026); IndoWaveSentiment (Bustamin et al., 2024); serta literatur pendukung gender bias SER (Gorrostieta et al., 2019; Lin et al., 2024), multimodal emotion recognition (Zhang et al., 2023/2024), dan edge computing untuk mHealth (Fiaz et al., 2026; Mohammadi et al., 2023). Daftar pustaka lengkap dengan format sitasi akan disusun mengikuti gaya IEEE pada dokumen final.