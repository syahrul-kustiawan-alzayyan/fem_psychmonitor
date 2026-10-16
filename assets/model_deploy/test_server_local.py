# -*- coding: utf-8 -*-
"""Uji penerimaan server_ssl.py (lokal). Sesuai AGENTS.md:
- GET /health harus ok + taksonomi 6 emosi
- 1 file wav valid per emosi-slot (sintetis, hanya untuk uji kontrak I/O,
  BUKAN klaim akurasi) harus 200 + class_probs lengkap
- 1 file sampah harus 400, payload >10MB harus 400
Jalankan: python test_server_local.py [--base http://127.0.0.1:8001]
"""
from __future__ import annotations
import io
import sys
import wave

import numpy as np

BASE = sys.argv[sys.argv.index("--base") + 1] if "--base" in sys.argv else "http://127.0.0.1:8001"

EMO6 = ["happy", "sad", "angry", "fearful", "disgust", "neutral"]


def make_wav(seconds=2.0, freq=220.0, sr=16000):
    t = np.arange(int(sr * seconds)) / sr
    wav = (0.5 * np.sin(2 * np.pi * freq * t)).astype(np.float32)
    buf = io.BytesIO()
    with wave.open(buf, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes((wav * 32767).astype(np.int16).tobytes())
    buf.seek(0)
    return buf.read()


def main():
    import urllib.request
    import urllib.error
    import json

    fails = []

    def check(name, cond, extra=""):
        print(("PASS " if cond else "FAIL ") + name + (" " + extra if extra else ""))
        if not cond:
            fails.append(name)

    # 1. /health
    try:
        with urllib.request.urlopen(BASE + "/health", timeout=10) as r:
            h = json.load(r)
        check("health status ok", h.get("status") == "ok", str(h.get("model")))
        check("health taksonomi 6", h.get("emotions") == EMO6, str(h.get("emotions")))
        check("health sr 16000", h.get("sample_rate") == 16000)
    except Exception as e:
        check("health reachable", False, str(e)[:150])
        print("KEGAGALAN: server tidak hidup. Jalankan: python server_ssl.py")
        sys.exit(1)

    # 2. wav valid (sintetis) -> 200 + kontrak output
    import http.client
    import mimetypes

    def post_wav(data: bytes, filename="uji.wav", endpoint="/predict-ssl", timeout=120):
        boundary = "BOUNDARY123"
        body = (
            f'--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="{filename}"\r\n'
            f"Content-Type: audio/wav\r\n\r\n"
        ).encode() + data + f"\r\n--{boundary}--\r\n".encode()
        conn = http.client.HTTPConnection("127.0.0.1", 8001, timeout=timeout)
        conn.request("POST", endpoint, body, {"Content-Type": f"multipart/form-data; boundary={boundary}"})
        resp = conn.getresponse()
        payload = resp.read().decode()
        conn.close()
        return resp.status, payload

    for i, emo in enumerate(EMO6):
        status, payload = post_wav(make_wav(seconds=2.0, freq=180.0 + i * 60.0), f"uji_{emo}.wav")
        ok = status == 200
        check(f"predict wav[{emo}] HTTP 200", ok, f"status={status}")
        if ok:
            try:
                j = json.loads(payload)
                probs = j.get("class_probs", {})
                check(f"predict wav[{emo}] 6 probs", sorted(probs.keys()) == sorted(EMO6), str(sorted(probs.keys())))
                total = sum(float(v) for v in probs.values())
                check(f"predict wav[{emo}] total~1", abs(total - 1.0) < 0.05, f"total={total:.3f}")
            except Exception as e:
                check(f"predict wav[{emo}] json valid", False, str(e)[:120])

    # 3. file sampah -> 400
    status, payload = post_wav(b"bukan audio sama sekali", "sampah.wav")
    check("file sampah -> 400", status == 400, f"status={status} {payload[:100]}")

    # 4. ekstensi salah -> 400
    status, payload = post_wav(make_wav(seconds=0.5), "uji.txt")
    check("ekstensi .txt -> 400", status == 400, f"status={status} {payload[:100]}")

    # 5. payload >10MB -> 400 (wav valid tapi kebesaran: 350 dtk ≈ 11MB)
    big = make_wav(seconds=350.0)
    status, payload = post_wav(big, "besar.wav")
    check("payload >10MB -> 400", status == 400, f"status={status} {payload[:100]}")

    # 6. /transcribe wav valid -> 200 + ada key 'text' (nada sine boleh kosong)
    status, payload = post_wav(make_wav(seconds=3.0, freq=440.0), "trans.wav",
                               endpoint="/transcribe", timeout=300)
    check("transcribe wav -> 200", status == 200, f"status={status} {payload[:120]}")
    if status == 200:
        try:
            j = json.loads(payload)
            check("transcribe ada key text", "text" in j and "transcribe_s" in j,
                  f"keys={sorted(j.keys())}")
        except Exception as e:
            check("transcribe json valid", False, str(e)[:120])

    # 7. /transcribe file sampah -> 400 (fail-closed)
    status, payload = post_wav(b"bukan audio sama sekali", "sampah.wav",
                               endpoint="/transcribe")
    check("transcribe sampah -> 400", status == 400, f"status={status} {payload[:100]}")

    print()
    if fails:
        print(f"HASIL: {len(fails)} GAGAL: {fails}")
        sys.exit(1)
    print("HASIL: semua uji kontrak lolos (bukan klaim akurasi).")


if __name__ == "__main__":
    main()
