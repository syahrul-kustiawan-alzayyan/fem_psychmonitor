# Perintah Perbaikan Aplikasi (backend FastAPI)

## 1. File model final (penelitian ini)

| Artefak | Path | Fungsi |
|---|---|---|
| Head SSL seed 7/42/123 | `outputs/retrain_ssl/pooled/best_seed{7,42,123}.pt` | Klasifikasi (ensemble) |
| Scaler | `outputs/retrain_ssl/pooled/scaler.npz` | Normalisasi (wajib dipakai) |
| Encoder | `microsoft/wavlm-base-plus` (HF cache) | Frozen, ~360 MB |
| Server siap pakai | `D:\model ser\server_ssl.py` | Pengganti `prediction_service.py` |
| Logika arsitektur | `D:\model ser\train_ssl.py` → kelas `SSLHead` | Jangan tulis ulang, impor |
| Taksonomi | `[happy, sad, angry, fearful, disgust, neutral]`, 16 kHz mono | Kontrak input |

Model `.keras` lama (`model_klasifikasi_emosi_suara.keras`, 64-fitur vs input-14)
terbukti mismatch dan harus **dipensiunkan, bukan diperbaiki**.

## 2. Perintah perbaikan (di repo aplikasi)

```bash
# A. Bekukan backend lama sebagai arsip
git mv emotion-backend emotion-backend-legacy

# B. Salin server baru + dependensi model
cp "D:/model ser/server_ssl.py" emotion-backend/server_ssl.py
cp "D:/model ser/train_ssl.py" emotion-backend/ssl_head.py
# (opsional) salin checkpoint + scaler, atau unduh saat deploy:
cp "D:/model ser/outputs/retrain_ssl/pooled/best_seed*.pt" emotion-backend/models/ssl/
cp "D:/model ser/outputs/retrain_ssl/pooled/scaler.npz" emotion-backend/models/ssl/
# sesuaikan path RDIR/SEEDS di server_ssl.py dengan lokasi di atas

# C. Dependensi (Python 3.10-3.11; TF tidak lagi dibutuhkan)
pip install torch transformers soundfile scipy fastapi "uvicorn[standard]" python-multipart

# D. Jalankan
python emotion-backend/server_ssl.py
# uji:  curl http://127.0.0.1:8001/health
```

## 3. Perubahan kode wajib di repo lama (jika backend lama dipertahankan)

1. `config.py`: `EMOTION_LABELS` → `[happy, sad, angry, fearful, disgust, neutral]`;
   `SAMPLE_RATE` → `16000`; CORS `allow_origins` → domain frontend saja
   (hapus `"*"` bila `allow_credentials=True`).
2. `services/prediction_service.py`: HAPUS `MockModel`, `_convert_to_multiclass`,
   dan fallback `except` yang mengembalikan neutral-diam/random. Ganti dengan
   fail-closed: gagal load model/scaler/kontrak → `raise` saat startup, HTTP 500
   dengan pesan jelas saat inferensi (jangan pernah 200 palsu).
3. Tambahkan health check kontrak: verifikasi `model.input_shape` vs dimensi fitur
   aktual saat startup; tolak deploy bila mismatch (mencegah insiden 64-vs-14).
4. Frontend: petakan label baru (fearful/disgust) di `ResultCard.jsx` dan hapus
   opsi surprise bila tak didukung model.

## 4. Perintah uji penerimaan (wajib lolos sebelum klaim deployment)

```bash
# akurasi end-to-end via API pada 1200 file YAF berlabel (orakel = folder emosi)
python - <<'EOF'
# (adaptasi dari C:\Users\USER\AppData\Local\Temp\opencode\test_server.py)
# target: laporkan akurasi + latency p50/p95 ke outputs/app_test.json
EOF
# latency: ukur POST /predict-ssl 20 file bervariasi, catat p50/p95
# failure: model hilang -> 500 (bukan 200); file korup -> 400; payload >10MB -> 400
```

## 5. Yang TIDAK boleh dilakukan

- Jangan mengklaim angka 89.6%/88.52% untuk aplikasi tanpa uji ulang via API.
- Jangan menambah endpoint sebelum kontrak fitur dikunci dan diuji.
- Jangan menyimpan audio user tanpa persetujuan + kebijakan retensi tertulis.
