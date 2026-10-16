# -*- coding: utf-8 -*-
"""Uji kecepatan inferensi server_ssl.py (lokal, CPU).

Mengirim N request POST /predict-ssl dengan durasi audio bervariasi
(2/5/10 detik), mencatat latensi end-to-end (client-side) + infer_s
(server-side), lalu melaporkan p50/p95/median per kelompok.

Ini MENGUKUR kecepatan, BUKAN akurasi.
Jalankan: python test_latency.py [--n 20] [--base http://127.0.0.1:8001]
"""
from __future__ import annotations
import io
import sys
import time
import wave
import json
import http.client

import numpy as np

args = sys.argv[1:]
N = int(args[args.index("--n") + 1]) if "--n" in args else 20
BASE = args[args.index("--base") + 1] if "--base" in args else "http://127.0.0.1:8001"
HOST, _, PORT = BASE.replace("https://", "").replace("http://", "").partition(":")
USE_HTTPS = BASE.startswith("https://")
PORT = int(PORT or ("443" if USE_HTTPS else "80"))


def make_wav(seconds: float, freq: float = 220.0, sr: int = 16000) -> bytes:
    rng = np.random.RandomState(42)
    t = np.arange(int(sr * seconds)) / sr
    # nada + sedikit noise agar mirip ucapan (tetap sintetis)
    wav = (0.4 * np.sin(2 * np.pi * freq * t) + 0.05 * rng.randn(len(t))).astype(np.float32)
    wav = wav / max(1e-6, np.abs(wav).max()) * 0.8
    buf = io.BytesIO()
    with wave.open(buf, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes((wav * 32767).astype(np.int16).tobytes())
    buf.seek(0)
    return buf.read()


def post_wav(data: bytes, filename: str = "uji.wav"):
    boundary = "BOUNDARY123"
    body = (
        f'--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="{filename}"\r\n'
        f"Content-Type: audio/wav\r\n\r\n"
    ).encode() + data + f"\r\n--{boundary}--\r\n".encode()
    conn_cls = http.client.HTTPSConnection if USE_HTTPS else http.client.HTTPConnection
    conn = conn_cls(HOST, PORT, timeout=300)
    t0 = time.perf_counter()
    conn.request("POST", "/predict-ssl", body, {"Content-Type": f"multipart/form-data; boundary={boundary}"})
    resp = conn.getresponse()
    payload = resp.read().decode()
    dt = time.perf_counter() - t0
    conn.close()
    return resp.status, payload, dt


def pct(data, p):
    if not data:
        return 0.0
    s = sorted(data)
    k = (len(s) - 1) * p / 100.0
    f, c = int(k), min(int(k) + 1, len(s) - 1)
    return s[f] + (s[c] - s[f]) * (k - f)


def main():
    durations = [2.0, 5.0, 10.0]
    per_group = max(1, N // len(durations))
    print(f"server: {BASE} | CPU lokal | {per_group}x{len(durations)} request")
    print("-" * 64)

    all_e2e, all_srv = [], []
    for dur in durations:
        e2e, srv, labels = [], [], []
        data = make_wav(seconds=dur)
        print(f"durasi {dur:.0f} dtk ({len(data)/1024:.0f} KB): ", end="", flush=True)
        for i in range(per_group):
            status, payload, dt = post_wav(data, f"lat_{dur:.0f}s_{i}.wav")
            if status != 200:
                print(f"\n  request {i} GAGAL status={status}: {payload[:120]}")
                continue
            try:
                infer_s = float(json.loads(payload).get("infer_s", 0))
            except Exception:
                infer_s = 0.0
            e2e.append(dt)
            srv.append(infer_s)
            print(f"{dt:.1f}s ", end="", flush=True)
        print()
        all_e2e += e2e
        all_srv += srv
        if e2e:
            print(f"  -> end-to-end: min {min(e2e):.2f}s  p50 {pct(e2e,50):.2f}s  p95 {pct(e2e,95):.2f}s  "
                  f"| server infer_s: p50 {pct(srv,50):.2f}s  p95 {pct(srv,95):.2f}s")

    print("-" * 64)
    if all_e2e:
        print(f"TOTAL end-to-end : n={len(all_e2e)}  p50 {pct(all_e2e,50):.2f}s  p95 {pct(all_e2e,95):.2f}s")
        print(f"TOTAL server     : n={len(all_srv)}  p50 {pct(all_srv,50):.2f}s  p95 {pct(all_srv,95):.2f}s")
        thr = len([x for x in all_e2e if x <= 5.0])
        print(f"request <=5 dtk  : {thr}/{len(all_e2e)}")
    else:
        print("Tidak ada request berhasil.")
        sys.exit(1)


if __name__ == "__main__":
    main()
