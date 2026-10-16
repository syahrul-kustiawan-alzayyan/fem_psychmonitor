# ser_server — Server inferensi SSL Fem-PsychMonitor

Pengganti drop-in untuk backend TF yang mismatch (lihat `PERBAIKAN_APP.md`).
Model: WavLM-base-plus frozen + MLP ensemble (seed 7/42/123), akurasi pooled
75.2% speaker-disjoint; TESS lintas-speaker 92.6-94.1%.

## Isi folder

- `server_ssl.py` — FastAPI: `GET /health`, `POST /predict-ssl` (.wav/.flac)
- `train_ssl.py` — definisi `SSLHead` (diimpor server, jangan dihapus)
- `models/ssl/best_seed{7,42,123}.pt` — checkpoint head ensemble
- `models/ssl/scaler.npz` — normalisasi (wajib dipakai, fit-di-train)
- `requirements.txt`, `PERBAIKAN_APP.md`, `AGENTS.md`

Encoder WavLM (~360 MB) diunduh otomatis dari HuggingFace saat start pertama.

## Cara menjalankan

```bash
pip install -r requirements.txt   # Python 3.10-3.11/3.14, CPU cukup
python server_ssl.py              # http://127.0.0.1:8001
curl http://127.0.0.1:8001/health
```

## Kontrak (jangan dilanggar)

- Input: WAV/FLAC, diresample ke 16 kHz mono di server, maks 10 MB.
- Output: 6 emosi `[happy, sad, angry, fearful, disgust, neutral]` + confidence.
- Fail-closed: artefak hilang/korup → server menolak start; audio invalid →
  HTTP 400; error inferensi → HTTP 500. Tidak ada prediksi palsu 200.
