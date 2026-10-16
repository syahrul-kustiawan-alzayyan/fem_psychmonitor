<div align="center">

![Header](assets/banner.png)

# 🧠 Fem-Psych Monitor
### *Empowering Women through Emotional Intelligence and AI*

[![Flutter](https://img.shields.io/badge/Flutter-v3.11+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-Emotion_Server-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![PyTorch](https://img.shields.io/badge/PyTorch-WavLM_SSL-EE4C2C?style=for-the-badge&logo=pytorch&logoColor=white)](https://pytorch.org)
[![MySQL](https://img.shields.io/badge/PHP_MySQL_API-SharedPreferences-4479A1?style=for-the-badge&logo=mysql&logoColor=white)](https://www.mysql.com)

</div>

---

## 🌟 Tentang Proyek
**Fem-Psych Monitor** adalah aplikasi pemantauan kesehatan mental yang dirancang khusus untuk perempuan. Menggabungkan psikometri **Big Five (OCEAN)** dengan **Voice Emotion Intelligence** — inferensi emosi suara (WavLM + MLP ensemble) dan transkripsi (faster-whisper) yang berjalan di server lokal — aplikasi ini membantu pengguna memahami dinamika emosionalnya dan mendapatkan saran coping yang dipersonalisasi secara deterministik (bukan generatif).

> ⚠️ **Bukan alat diagnosis klinis.** Skor dan rekomendasi bersifat skrining awal/pendukung. Kode berperilaku *fail-closed*: kegagalan server ditampilkan sebagai error yang jelas, tidak pernah diganti skor palsu.

## 🚀 Fitur Unggulan

### 1. 📋 Onboarding Psikometri
Membangun profil dasar pengguna sebelum memakai fitur utama:
- **Big Five Mini-IPIP** (20 item, skala Likert 1–5): Openness, Conscientiousness, Extraversion, Agreeableness, Neuroticism.
- **Skrining psikologis khusus perempuan** (20 item): beban peran ganda, fluktuasi hormonal, citra tubuh, batasan personal, kecemasan sosial, burnout.
- **Stratifikasi skor**: *Sehat Optimal* (≥76), *Cukup* (≥51), *Rentan* (≥26), *Butuh Perhatian Klinis* (<26).

### 2. 🎙️ Deteksi Emosi Multimodal (Server)
Alur rekam → hasil di `EmotionDetectionScreen`:
- **Rekam suara** (WAV 16 kHz mono) dengan pratinjau live dan panduan pertanyaan cerita.
- **Jalur suara (bobot 60%)**: `POST /predict-ssl` — WavLM-base-plus frozen + MLP ensemble 3 seed → 6 emosi (`happy, sad, angry, fearful, disgust, neutral`) + confidence.
- **Jalur teks (bobot 40%)**: `POST /transcribe` (faster-whisper, Bahasa Indonesia) → pencocokan leksikon afektif dwibahasa → skor emosi teks. Transkrip kosong → skor teks default netral.
- **Fusi + penyimpanan**: skor gabungan → emosi dominan → saran pertama → simpan ke backend (metadata + transkrip, audio opsional) → skor psikologis diperbarui (`computeMentalHealthAdjustment`, netral = tidak berubah).

### 3. 📊 Dashboard & Riwayat
- **Home**: sapaan, kartu status psikis, mini-statistik, riwayat terbaru, saran personal.
- **History**: filter waktu, grafik tren emosi (`fl_chart`), detail per rekaman (transkrip, skor audio vs teks, trigger tag), ekspor PDF.
- **Trigger tag** wajib tiap rekaman: kerja, asmara, keuangan, kesehatan, keluarga, sosial, lainnya.

### 4. 💡 Rekomendasi Deterministik
`SuggestionService` (basis `saran_bigfive_v2.json`): 6 emosi × 5 trait × tinggi/rendah → tampil 10 saran per sesi (2 per trait non-netral) + lapisan rujukan keselamatan. Tanpa LLM generatif — setiap saran dapat ditelusuri.

### 5. 🔐 Auth, Premium & Admin
- Firebase Auth (email + Google, verifikasi email) — UID Firebase = identitas di database.
- Premium (Google Play Billing, server = sumber kebenaran), AdMob, notifikasi pengingat harian, id/en dua bahasa, mode terang/gelap.
- Dashboard admin: daftar user, distribusi emosi, detail + PDF per user.

## 🛠️ Stack Teknologi
- **Framework**: [Flutter](https://flutter.dev) · **State**: [Provider](https://pub.dev/packages/provider)
- **Auth**: Firebase Auth (Google Sign-In) — *tetap dipakai*
- **Backend metadata**: PHP + MySQL (cPanel) via `http` REST API (`cpanel_api/`)
- **Server emosi + transkripsi**: FastAPI + PyTorch CPU (`ser_server/`) — WavLM-base-plus + MLP ensemble, faster-whisper small int8
- **Lokal HP**: SharedPreferences, `record` (audio), `fl_chart` — seluruh inferensi ML berjalan di server

## 📦 Struktur Project
```text
lib/                 # Aplikasi Flutter
├── l10n/            # Lokalisasi id/en
├── models/          # AppUser, EmotionRecord, BigFive/PsyQuestion
├── providers/       # Auth, locale, theme, premium, admin
├── screens/         # Auth, onboarding/*, home, deteksi, hasil, history, admin
├── services/        # ApiService, DatabaseService, SerService, saran, teks-emosi, dsb.
├── theme/           # AppTheme + ResonanceColors
├── utils/           # Helper animasi
└── widgets/         # Komponen UI reusable
ser_server/          # Server inferensi emosi + transkripsi (Python/FastAPI)
├── server_ssl.py    # Entrypoint: GET /health, POST /predict-ssl, POST /transcribe
├── train_ssl.py     # Definisi arsitektur SSLHead (terikat checkpoint — jangan diubah)
├── models/ssl/      # Checkpoint ensemble 3 seed + scaler.npz (fit-di-train, wajib dipakai)
├── requirements.txt # torch>=2.6, transformers, faster-whisper, hf_transfer
└── test_*.py        # Uji kontrak + benchmark latensi
cpanel_api/          # Backend PHP + MySQL (metadata & audio upload, bukan inferensi)
├── api/             # Endpoint (salin ke public_html/api/)
└── schema.sql       # Skema database
docs/                # Blueprint, manual, diagram alir, jurnal teknis, laporan uji
test/                # Unit/widget test Flutter (cermin struktur lib/)
```

## ⚙️ Cara Menjalankan

### Prasyarat
- Flutter SDK v3.11+, Android Studio / VS Code + plugin Flutter.
- Server cPanel PHP 8+ & MySQL (metadata) — atau lewati untuk mode lokal.
- Python 3.10–3.12 (server SER). Lihat `ser_server/README.md` + `ser_server/AGENTS.md` untuk kontrak yang tidak boleh dilanggar.

### 1. Backend metadata (cPanel)
Salin `cpanel_api/api/` → `public_html/api/`, buat database, import `cpanel_api/schema.sql`, isi `api/config.php` (lihat `cpanel_api/README.md`).

### 2. Server emosi + transkripsi
```bash
pip install -r ser_server/requirements.txt
python -u ser_server/server_ssl.py   # http://127.0.0.1:8001
curl http://127.0.0.1:8001/health
```

### 3. Aplikasi Flutter
```bash
cp .env.example .env   # lalu isi (lihat tabel di bawah)
flutter pub get
flutter run
```

| Variabel `.env` | Contoh | Keterangan |
|---|---|---|
| `API_BASE_URL` | `https://domain.com/api` | Backend cPanel; `API_KEY` wajib sama dengan `config.php` |
| `SER_BASE_URL` | `http://127.0.0.1:8001` | Desktop. Emulator: `http://10.0.2.2:8001`. HP fisik: IP LAN laptop atau URL tunnel |
| `ADMIN_EMAIL` / `ADMIN_PASSWORD` | — | Akun admin dibuat otomatis saat run pertama |

> Firebase Auth tetap dipakai (UID = kunci user di MySQL). Firestore/Storage lama sudah tidak dipakai.

## 🧪 Pengujian
```bash
# Kontrak server (emosi + transkripsi + kasus 400) — butuh server hidup
python ser_server/test_server_local.py
# Benchmark latensi (p50/p95 per durasi audio)
python ser_server/test_latency.py --n 18
# Tes Flutter (SerService butuh server lokal, sisanya mandiri)
flutter test test/services/
dart analyze lib/
```

## 🔒 Privasi (ringkas)
Audio dikirim ke server SER **hanya untuk inferensi** (emosi + transkripsi) dan tidak disimpan di sana; yang tersimpan (cPanel) hanya metadata hasil + transkrip. Detail ancaman/batasan ada di `docs/blueprint.md` bag. Keamanan Data dan Privasi.

## 📂 Data & Aset Utama (`assets/`)
- `BigFive_MiniIPIP20*.json` — bank soal Big Five (id/en)
- `psych*.json` — kuesioner skrining perempuan (id/en)
- `saran_bigfive*.json` — basis rekomendasi deterministik (v2 = aktif)
- `emotion*.json` — leksikon afektif dwibahasa untuk skor teks

---
<div align="center">
  Dibuat dengan ❤️ untuk Kesehatan Mental Perempuan
</div>
