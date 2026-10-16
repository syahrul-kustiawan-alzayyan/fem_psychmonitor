# AGENTS.md — Instruksi untuk AI yang mengerjakan folder ini

> Berlaku untuk `ser_server/` dan integrasinya ke aplikasi Fem-PsychMonitor.
> Bahasa kerja: Indonesia kecuali artefak berbahasa Inggris.

## Konteks singkat

Server inferensi SER female (FastAPI + PyTorch CPU): encoder WavLM-base-plus
frozen + head MLP ensemble 3 seed. Menggantikan backend TensorFlow lama yang
terbukti mismatch (fitur 64 vs input 14 → fallback neutral diam-diam).
Riset pendukung: `../outputs/synthesis_ssl.md`, audit: `../outputs/app_audit.md`.

## Kontrak yang TIDAK BOLEH dilanggar

1. Taksonomi emosi TETAP `[happy, sad, angry, fearful, disgust, neutral]`.
   Jangan menambah/menghapus/mengubah urutan tanpa persetujuan eksplisit user.
2. Fail-closed SELALU: tidak ada MockModel, tidak ada fallback random/neutral
   diam-diam, tidak ada HTTP 200 palsu. Gagal = 4xx/5xx + log jelas.
3. Scaler `models/ssl/scaler.npz` WAJIB dipakai (fit-di-train). Jangan
   mengganti dengan normalisasi lain tanpa validasi akurasi ulang.
4. Jangan mengubah arsitektur `SSLHead` di `train_ssl.py` — checkpoint
   terikat pada bentuknya. Model baru = file baru + evaluasi penuh.
5. Jangan mengklaim angka akurasi baru tanpa menjalankan evaluasi
   speaker-disjoint (lihat `../run_single_dataset.py` / `../train_ssl.py`).

## Cara kerja yang diharapkan

- Baca `README.md` + `PERBAIKAN_APP.md` dulu sebelum menyentuh kode.
- Setiap perubahan perilaku: uji `/health` + minimal 1 file per emosi +
  1 file sampah (harus 400) sebelum selesai.
- Server diuji dengan menjalankannya (job/background), BUKAN sekadar
  import. Matikan server setelah selesai menguji.
- Dependensi baru: tambahkan ke `requirements.txt` + uji instalasi bersih.
- Python yang didukung: 3.10-3.14, CPU-only (tanpa CUDA).

## Peta file

- `server_ssl.py` — satu-satunya entrypoint; RDIR relatif ke folder ini.
- `train_ssl.py` — sumber `SSLHead`; perubahan di sini merusak checkpoint.
- `models/ssl/` — artefak biner; jangan commit ulang tanpa kebutuhan.
- Uji manual: skrip di `C:\Users\USER\AppData\Local\Temp\opencode\test_server.py`
  (adaptasi path bila perlu).

## Batasan jujur (jangan dijanjikan ke user)

- Belum ada auth, rate-limit, HTTPS — prototipe riset, bukan production.
- Whisper/transkripsi BUKAN bagian server ini (dijalankan terpisah).
- Akurasi deployment = akurasi pooled 75.2% (bukan 93% TESS) kecuali
  dievaluasi ulang pada domain target.
