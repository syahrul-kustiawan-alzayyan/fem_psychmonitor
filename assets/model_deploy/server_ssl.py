# -*- coding: utf-8 -*-
"""Server inferensi SSL female-SER (pengganti prediction_service TF).
Fail-closed: gagal load apa pun -> server menolak start (tanpa mock/fallback diam).
Kontrak: wav 16 kHz mono, taksonomi 6-emosi riset [happy,sad,angry,fearful,disgust,neutral].
Model: outputs/retrain_ssl/pooled ensemble (seed 7/42/123) + scaler.npz.
Transkripsi: faster-whisper (model small, CPU int8, bahasa Indonesia) via
POST /transcribe — dimuat lazy saat pertama dipakai agar gangguan unduh
model STT tidak menghalangi layanan emosi utama.
Jalankan dari D:\\model ser:  python server_ssl.py   (http://127.0.0.1:8001)
"""
from __future__ import annotations
import io
import sys
import time
from pathlib import Path

import numpy as np
import soundfile as sf
import torch
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.responses import JSONResponse

BASE = Path(__file__).resolve().parent
sys.path.insert(0, str(BASE))
from train_ssl import SSLHead  # noqa

EMO6 = ["happy", "sad", "angry", "fearful", "disgust", "neutral"]
RDIR = BASE / "models" / "ssl"
SEEDS = [7, 42, 123]

app = FastAPI(title="Fem-PsychMonitor SSL inference", version="2.0.0")


def _load():
    from transformers import AutoFeatureExtractor, AutoModel
    fe = AutoFeatureExtractor.from_pretrained("microsoft/wavlm-base-plus")
    enc = AutoModel.from_pretrained("microsoft/wavlm-base-plus")
    enc.eval()
    nets = []
    for sd in SEEDS:
        ck = RDIR / ("best_seed%d.pt" % sd)
        if not ck.exists():
            raise RuntimeError("checkpoint hilang: %s" % ck)
        net = SSLHead(6, hid=256, layer_init="mid")
        net.load_state_dict(torch.load(ck, map_location="cpu", weights_only=True))
        net.eval()
        nets.append(net)
    sc = np.load(RDIR / "scaler.npz")
    assert sc["mean"].shape == (1, 13, 1536), sc["mean"].shape  # validasi kontrak
    return fe, enc, nets, sc


FE, ENC, NETS, SC = _load()  # gagal di sini = server tidak start (fail-closed)


def infer_wav(wav16: np.ndarray):
    t0 = time.time()
    inp = FE(wav16, sampling_rate=16000, return_tensors="pt", do_normalize=True)
    with torch.no_grad():
        out = ENC(**inp, output_hidden_states=True, return_dict=True)
        hs = torch.stack(list(out.hidden_states), dim=0)
        mf = hs.mean(dim=2, keepdim=True)
        var = ((hs - mf) ** 2).mean(dim=2, keepdim=True)
        feat = torch.cat([mf.squeeze(2), torch.sqrt(var + 1e-8).squeeze(2)], dim=-1
                         ).permute(1, 0, 2).numpy()
        feat = (feat - SC["mean"]) / SC["std"]
        Ps = [torch.softmax(n(torch.from_numpy(feat.astype(np.float32))), dim=1).numpy()[0]
              for n in NETS]
    P = np.mean(Ps, axis=0)
    dt = time.time() - t0
    i = int(P.argmax())
    return {"label": EMO6[i], "confidence": round(float(P[i]), 4),
            "class_probs": {e: round(float(P[j]), 4) for j, e in enumerate(EMO6)},
            "infer_s": round(dt, 3)}


@app.get("/health")
def health():
    return {"status": "ok", "model": "wavlm-base-plus frozen + MLP ensemble",
            "seeds": SEEDS, "sample_rate": 16000, "emotions": EMO6,
            "transcribe": {"model": "faster-whisper/" + WHISPER_MODEL, "language": "id"}}


def _read_upload_wav(raw: bytes, filename: str):
    """Validasi + decode upload audio -> (wav_mono_float32, sample_rate).
    Raises HTTPException 400 bila tidak valid. Dipakai /predict-ssl & /transcribe."""
    if not (filename or "").lower().endswith((".wav", ".flac")):
        raise HTTPException(400, "hanya .wav/.flac")
    if len(raw) > 10 * 1024 * 1024:
        raise HTTPException(400, "file >10MB")
    try:
        wav, sr = sf.read(io.BytesIO(raw), dtype="float32", always_2d=True)
    except Exception:
        raise HTTPException(400, "bukan file audio valid")
    wav = wav.mean(axis=1)
    if sr != 16000:
        from math import gcd
        from scipy.signal import resample_poly
        g = gcd(int(sr), 16000)
        wav = resample_poly(wav, 16000 // g, int(sr) // g).astype(np.float32)
    if wav.size == 0:
        raise HTTPException(400, "audio kosong")
    return wav, sr


# ── Transkripsi (faster-whisper, EAGER) ─────────────────────────────
# Model default "small" (lebih baik dari base on-device), CPU int8.
# Diunduh + dimuat saat STARTUP agar request tidak pernah tersangkut
# unduhan (kasus: worker tunggal macet → /predict-ssl ikut antre).
# Bisa diganti via env WHISPER_MODEL (tiny/base/small/medium), tapi
# medium ke atas lambat di CPU dan wajib uji latensi ulang.
# Gagal load = NON-FATAL untuk emosi: server tetap hidup, /transcribe
# menjawab 500 yang jelas (fail-closed), bukan teks kosong diam-diam.
import os as _os
WHISPER_MODEL = _os.environ.get("WHISPER_MODEL", "small")
_WM = None


def _load_whisper():
    global _WM
    from faster_whisper import WhisperModel
    print("memuat whisper %s (CPU int8)..." % WHISPER_MODEL, flush=True)
    _WM = WhisperModel(WHISPER_MODEL, device="cpu", compute_type="int8")
    print("whisper %s siap." % WHISPER_MODEL, flush=True)


try:
    _load_whisper()
except Exception as _e:
    print("PERINGATAN: whisper gagal dimuat, /transcribe nonaktif: %s" % str(_e)[:200],
          flush=True)
    _WM = None


def transcribe_wav(wav16: np.ndarray):
    t0 = time.time()
    if _WM is None:
        raise RuntimeError("model transkripsi tidak tersedia (gagal load saat startup)")
    segments, info = _WM.transcribe(wav16, language="id", beam_size=5)
    text = "".join(s.text for s in segments).strip()
    dt = time.time() - t0
    return {"text": text, "language": info.language if info else "id",
            "duration_s": round(float(wav16.size) / 16000, 2),
            "transcribe_s": round(dt, 3), "model": "faster-whisper/" + WHISPER_MODEL}


@app.post("/predict-ssl")
async def predict_ssl(file: UploadFile = File(...)):
    raw = await file.read()
    wav, _ = _read_upload_wav(raw, file.filename or "")
    try:
        return JSONResponse(infer_wav(wav))
    except Exception as e:
        raise HTTPException(500, "inferensi gagal: %s" % str(e)[:200])


@app.post("/transcribe")
async def transcribe(file: UploadFile = File(...)):
    raw = await file.read()
    wav, _ = _read_upload_wav(raw, file.filename or "")
    try:
        return JSONResponse(transcribe_wav(wav))
    except RuntimeError as e:
        raise HTTPException(500, "transkripsi gagal: %s" % str(e)[:200])
    except Exception as e:
        raise HTTPException(500, "transkripsi gagal: %s" % str(e)[:200])


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8001)
