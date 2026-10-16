"""Head ringan di atas frozen WavLM-base-plus (per-layer mean+std cache).
Arsitektur SUPERB-style: softmax-weighted-sum 13 layer -> MLP(1536-512-nc).
Split & protokol IDENTIK trial MFCC (speaker-disjoint, apel-ke-apel).
Jalankan dari D:\\model ser: python train_ssl.py --dataset TESS [--epochs 100] [--seeds 7]
  atau: python train_ssl.py --pooled
Output: outputs/retrain_ssl/{single_TESS|pooled}/
"""
from __future__ import annotations
import argparse, gc, json, random, re, sys
from datetime import datetime, timezone
from pathlib import Path

import numpy as np
import pandas as pd
import torch
import torch.nn as nn

BASE = Path(r"D:/model ser")
SSL = BASE / "outputs" / "ssl" / "wavlm-base-plus"
SEED, EPOCHS, BATCH = 7, 100, 256
LR, WD, LABEL_SMOOTH = 1e-3, 1e-4, 0.05
DROP, EARLY_PATIENCE = 0.4, 15
EMO6 = ["happy", "sad", "angry", "fearful", "disgust", "neutral"]
EMO4 = ["happy", "sad", "angry", "neutral"]
REMAP = {0: 0, 1: 1, 2: 2, 5: 3}
DSS = ["TESS", "CREMA-D", "RAVDESS", "E-SERAVD", "IndoWaveSentiment"]


class SSLHead(nn.Module):
    def __init__(self, n_classes, hid=512, drop=DROP, layer_init="uniform"):
        super().__init__()
        if layer_init == "mid":
            w0 = torch.tensor([0., 0., 0., 0., 1., 1., 1., 1., 1., 1., 1., 0., 0.])
        else:
            w0 = torch.zeros(13)
        self.w = nn.Parameter(w0)  # softmax -> bobot layer
        self.fc1 = nn.Linear(1536, hid)
        self.drop = nn.Dropout(drop)
        self.fc2 = nn.Linear(hid, n_classes)

    def forward(self, x):  # x: (B,13,1536)
        a = torch.softmax(self.w, dim=0).view(1, -1, 1)
        h = (x * a).sum(dim=1)  # (B,1536)
        return self.fc2(self.drop(torch.relu(self.fc1(h))))


def normkey(p):
    return str(p).lower().replace(chr(92), "/")


def load_all():
    Xs, Ms = [], []
    for ds in DSS:
        d = np.load(SSL / f"{ds}_ssl.npz")
        m = pd.read_csv(SSL / f"{ds}_ssl_order.csv")
        assert len(d["stats"]) == len(m), ds
        Xs.append(d["stats"]); Ms.append(m)
    X = np.concatenate(Xs, axis=0).astype(np.float32)
    M = pd.concat(Ms, ignore_index=True)
    return X, M


def spk_of(ds, fp):
    if ds == "TESS":
        m = re.search(r"(OAF|YAF)[^/\\\\]*", fp)
        return "TESS_" + (m.group(1) if m else "UNK")
    if ds == "CREMA-D":
        return "CREMA_" + fp.split("\\")[-1].split("_")[0]
    if ds == "RAVDESS":
        m = re.search(r"Actor_\d+", fp)
        return "RAVDESS_" + (m.group(0) if m else "UNK")
    if ds == "E-SERAVD":
        return "ESERAVD_" + fp.split("\\")[-1].split("-")[2]
    if ds == "IndoWaveSentiment":
        m = re.search(r"Actor_\d+", fp)
        return "IW_" + (m.group(0) if m else "UNK")
    return fp


def single_parts(md, ds, seed=SEED):
    md = md.copy()
    md["spk"] = [spk_of(ds, r["filepath"]) for _, r in md.iterrows()]
    speakers = sorted(md["spk"].unique().tolist())
    print(f"speakers ({len(speakers)}): {speakers[:12]}", flush=True)
    rs = np.random.RandomState(seed)
    sp = speakers.copy(); rs.shuffle(sp)
    pos = np.arange(len(md))
    if len(sp) == 2:
        tr_pos = pos[md["spk"].to_numpy() == sp[0]]
        te_pos = pos[md["spk"].to_numpy() == sp[1]]
        rs2 = np.random.RandomState(seed)
        va_pos = rs2.choice(tr_pos, size=max(1, int(len(tr_pos) * 0.15)), replace=False)
        tr_pos = np.array([i for i in tr_pos if i not in set(va_pos.tolist())])
        return {"train": tr_pos, "val": va_pos, "test": te_pos}
    n_te = max(1, int(round(len(sp) * 0.2)))
    n_va = max(1, int(round((len(sp) - n_te) * 0.18)))
    te_s, va_s, tr_s = sp[:n_te], sp[n_te:n_te + n_va], sp[n_te + n_va:] or sp[n_te + n_va - 1:]
    if not tr_s:
        tr_s, va_s = va_s, []
    spk = md["spk"].to_numpy()
    return {"train": pos[np.isin(spk, tr_s)],
            "val": pos[np.isin(spk, va_s)] if va_s else np.zeros(0, int),
            "test": pos[np.isin(spk, te_s)]}


def train_eval(X, y, M, emos, tag, epochs, seeds, hid=512, layer_init="uniform",
               fixed_epochs=0, wd=WD, lr=LR, unorm=False, sampler="class",
               per_combo=180):
    outdir = BASE / "outputs" / "retrain_ssl" / tag
    outdir.mkdir(parents=True, exist_ok=True)
    nc = len(emos)
    # scaler dari train (fixed, per-layer)
    Xs = {k: X[v] for k, v in parts.items()}
    ys = {k: y[v] for k, v in parts.items()}
    Ms = {k: M.iloc[v].reset_index(drop=True) for k, v in parts.items()}
    mean = Xs["train"].mean(axis=0, keepdims=True)
    std = Xs["train"].std(axis=0, keepdims=True) + 1e-8
    np.savez_compressed(outdir / "scaler.npz", mean=mean, std=std)
    for k in Xs:
        Xs[k] = ((Xs[k] - mean) / std).astype(np.float32)
        if unorm:
            mu = Xs[k].mean(axis=(1, 2), keepdims=True)
            sd = Xs[k].std(axis=(1, 2), keepdims=True) + 1e-8
            Xs[k] = ((Xs[k] - mu) / sd).astype(np.float32)
    uniq, cnt = np.unique(ys["train"], return_counts=True)
    tgt = cnt.max()
    ds_tr = Ms["train"]["dataset"].to_numpy() if "dataset" in Ms["train"].columns else np.array(["all"] * len(ys["train"]))
    cbal_groups = None
    if sampler == "cbal":
        from collections import defaultdict
        cbal_groups = defaultdict(list)
        for i, (dd, lb) in enumerate(zip(ds_tr, ys["train"])):
            cbal_groups[(dd, int(lb))].append(i)
        print(f"cbal: {len(cbal_groups)} grup (ds,kelas), per_combo={per_combo}", flush=True)
    for sd in seeds:
        random.seed(sd); np.random.seed(sd); torch.manual_seed(sd)
        rsb = np.random.RandomState(sd)
        if cbal_groups is None:
            order = []
            for lb in uniq:
                ii = np.where(ys["train"] == lb)[0]
                ex = rsb.choice(ii, size=int(tgt - len(ii)), replace=True).tolist() if len(ii) < tgt else []
                order += list(ii) + ex
            order = np.array(order)
        else:
            keys = sorted(cbal_groups.keys())
            order = np.array([rsb.choice(cbal_groups[k]) for _ in range(per_combo) for k in keys])
        print(f"basis: {len(order)} (target/kelas {tgt})", flush=True)
        net = SSLHead(nc, hid=hid, layer_init=layer_init)
        opt = torch.optim.Adam(net.parameters(), lr=lr, weight_decay=wd)
        crit = nn.CrossEntropyLoss(label_smoothing=LABEL_SMOOTH)
        sched = torch.optim.lr_scheduler.ReduceLROnPlateau(opt, factor=0.5, patience=5)
        Xvt = torch.from_numpy(Xs["val"]); yvt = torch.from_numpy(ys["val"])
        Xtt = torch.from_numpy(Xs["test"]); ytt = torch.from_numpy(ys["test"])
        nb = int(np.ceil(len(order) / BATCH))
        best, bad = -1.0, 0
        for ep in range(epochs):
            re_ = np.random.RandomState(sd * 1000 + ep)
            perm = order.copy(); re_.shuffle(perm)
            net.train(); tl, tc, tn = 0.0, 0, 0
            for i in range(nb):
                bi = perm[i * BATCH:(i + 1) * BATCH]
                r = np.random.RandomState((sd * 31 + ep * 101 + i) % (2 ** 31 - 1))
                xb = Xs["train"][bi].copy()
                xb += r.normal(0, 0.02, xb.shape).astype(np.float32)  # noise ruang-embedding
                mk = r.random(xb.shape) < 0.05  # feature mask 5%
                xb[mk] = 0.0
                xb_t = torch.from_numpy(xb); yb_t = torch.from_numpy(ys["train"][bi])
                opt.zero_grad()
                out = net(xb_t); loss = crit(out, yb_t)
                loss.backward(); opt.step()
                tl += float(loss.detach()) * len(bi); tc += int((out.argmax(1) == yb_t).sum()); tn += len(bi)
            net.eval()
            with torch.no_grad():
                pv = net(Xvt)
                lv = float(nn.functional.cross_entropy(pv, yvt))
                acc = float((pv.argmax(1) == yvt).float().mean())
            sched.step(lv)
            if (ep + 1) % 10 == 0 or ep == 0:
                print(f"ep{ep + 1}: acc={tc / tn:.4f} val={acc:.4f}", flush=True)
            if acc > best:
                best, bad = acc, 0
                torch.save(net.state_dict(), outdir / f"best_seed{sd}.pt")
            else:
                bad += 1
                if bad >= EARLY_PATIENCE and not fixed_epochs:
                    print(f"early stopping (best={best:.4f})", flush=True)
                    break
        if fixed_epochs:
            torch.save(net.state_dict(), outdir / f"best_seed{sd}.pt")
            print(f"fixed-epoch: pakai epoch terakhir (best_val={best:.4f})", flush=True)
        net.load_state_dict(torch.load(outdir / f"best_seed{sd}.pt", map_location="cpu", weights_only=True))
        net.eval()
        with torch.no_grad():
            Pt = torch.softmax(net(Xtt), dim=1).numpy()
        print("bobot layer:", torch.softmax(net.w, dim=0).detach().numpy().round(3).tolist(), flush=True)
        pred = Pt.argmax(1); yt = ys["test"]
        cm = np.zeros((nc, nc), dtype=int)
        for t, p in zip(yt, pred):
            cm[int(t), int(p)] += 1
        tp = np.diag(cm).astype(float); fp, fn = cm.sum(0) - tp, cm.sum(1) - tp
        prec = np.divide(tp, tp + fp, out=np.zeros(nc), where=(tp + fp) > 0)
        rec = np.divide(tp, tp + fn, out=np.zeros(nc), where=(tp + fn) > 0)
        f1 = np.divide(2 * prec * rec, prec + rec, out=np.zeros(nc), where=(prec + rec) > 0)
        rs = np.random.RandomState(sd); S = rs.randint(0, len(yt), size=(1000, len(yt)))
        boots = ((pred == yt).astype(float))[S].mean(1)
        met = {"tag": tag, "seed": sd, "n_test": len(yt), "accuracy": float((pred == yt).mean()),
               "acc_95ci": [float(np.percentile(boots, 2.5)), float(np.percentile(boots, 97.5))],
               "macro_f1": float(f1.mean()), "uar": float(rec.mean()),
               "per_class": {e: {"p": float(prec[i]), "r": float(rec[i]), "f1": float(f1[i])} for i, e in enumerate(emos)},
               "confusion_matrix": cm.tolist(),
               "layer_weights": torch.softmax(net.w, dim=0).detach().numpy().tolist(),
               "generated_at": datetime.now(timezone.utc).isoformat()}
        (outdir / f"metrics_seed{sd}.json").write_text(json.dumps(met, indent=1), encoding="utf-8")
        ap_df = pd.DataFrame({"filepath": Ms["test"]["filepath"].to_numpy()})
        for i, e in enumerate(emos):
            ap_df[f"prob_{e}"] = Pt[:, i]
        ap_df.to_csv(outdir / f"audio_probs_test_seed{sd}.csv", index=False)
        print(f"TEST {tag} s{sd}: acc={met['accuracy']:.4f} macroF1={met['macro_f1']:.4f} ci={met['acc_95ci']}", flush=True)
    print("SELESAI:", outdir, flush=True)


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--dataset", default="")
    ap.add_argument("--pooled", action="store_true")
    ap.add_argument("--epochs", type=int, default=EPOCHS)
    ap.add_argument("--seeds", type=int, nargs="+", default=[SEED])
    ap.add_argument("--hid", type=int, default=512)
    ap.add_argument("--layer-init", default="uniform", choices=["uniform", "mid"])
    ap.add_argument("--fixed-epochs", type=int, default=0)
    ap.add_argument("--wd", type=float, default=WD)
    ap.add_argument("--lr", type=float, default=LR)
    ap.add_argument("--rand", action="store_true",
                    help="split acak berstrata (speaker-dependent ceiling, TIDAK untuk klaim)")
    ap.add_argument("--aux", default="",
                    help="dataset tambahan untuk train multi-speaker, koma-pisah")
    ap.add_argument("--unorm", action="store_true",
                    help="normalisasi per-utterance (z-norm 1536-dim) setelah scaler global")
    ap.add_argument("--emo4", action="store_true",
                    help="pooled 4-emosi (happy/sad/angry/neutral), buang fearful/disgust")
    ap.add_argument("--sampler", default="class", choices=["class", "cbal"])
    ap.add_argument("--per-combo", type=int, default=180)
    ap.add_argument("--exclude", default="", help="dataset yang dibuang dari pooled, koma-pisah")
    a = ap.parse_args()
    X, M = load_all()
    y = M["label"].to_numpy(int)
    excl = [s for s in a.exclude.split(",") if s]
    if excl:
        keep0 = ~M["dataset"].isin(excl).to_numpy()
        X, M, y = X[keep0], M[keep0].reset_index(drop=True), y[keep0]
        print(f"exclude dari pooled: {excl} (sisa {len(M)})", flush=True)
    if a.pooled:
        sdir = BASE / "outputs" / "splits"
        splits = {}
        for n in ["train", "val", "test"]:
            splits[n] = set(pd.read_csv(sdir / f"{n}.csv")["filepath"].map(normkey))
        keys = M["filepath"].map(normkey).to_numpy()
        parts = {n: np.where(np.array([k in splits[n] for k in keys]))[0] for n in splits}
        for k, v in parts.items():
            print(f"{k}: {len(v)} baris", flush=True)
        emos, tag = EMO6, "pooled"
        if a.emo4:
            remap = {0: 0, 1: 1, 2: 2, 5: 3}
            keep = np.array([v in remap for v in y])
            X, M, y = X[keep], M[keep].reset_index(drop=True), y[keep]
            keys = M["filepath"].map(normkey).to_numpy()
            parts = {n: np.where(np.array([k in splits[n] for k in keys]))[0] for n in splits}
            y = np.vectorize(remap.get, otypes=[int])(y)
            emos, tag = EMO4, "pooled_emo4"
            if excl:
                tag += "_no" + "+".join(excl)
            if a.sampler == "cbal":
                tag += "_cbal"
            if a.hid != 256:
                tag += f"_h{a.hid}"
            for k, v in parts.items():
                print(f"emo4 {k}: {len(v)} baris", flush=True)
        train_eval(X, y, M, emos, tag, a.epochs, a.seeds, hid=a.hid,
                   layer_init=a.layer_init, fixed_epochs=a.fixed_epochs, wd=a.wd, lr=a.lr,
                   unorm=a.unorm, sampler=a.sampler, per_combo=a.per_combo)
    else:
        ds = a.dataset
        aux = [s for s in a.aux.split(",") if s]
        mi = np.where((M["dataset"] == ds).to_numpy())[0]
        Xd, Md, yd = X[mi], M.iloc[mi].reset_index(drop=True), y[mi]
        sub = single_parts(Md, ds)
        if a.rand:
            rs = np.random.RandomState(SEED)
            pall = np.concatenate([sub["train"], sub["val"], sub["test"]])
            rs.shuffle(pall)
            n_te = len(sub["test"])
            n_va = len(sub["val"])
            parts = {"train": pall[:len(pall) - n_te - n_va],
                     "val": pall[len(pall) - n_te - n_va:len(pall) - n_te],
                     "test": pall[len(pall) - n_te:]}
            print("RAND-SPLIT (speaker-dependent, bukan klaim):", {k: len(v) for k, v in parts.items()}, flush=True)
        else:
            parts = sub
        if aux:
            xa, ma, ya = [], [], []
            for ad in aux:
                mj = np.where((M["dataset"] == ad).to_numpy())[0]
                xa.append(X[mj]); ma.append(M.iloc[mj]); ya.append(y[mj])
            Xa = np.concatenate(xa, axis=0)
            # gabung ke train (val/test tetap milik ds target)
            parts = {"train": np.concatenate([parts["train"],
                        np.arange(len(Xd), len(Xd) + len(Xa))]),
                     "val": parts["val"], "test": parts["test"]}
            Xd = np.concatenate([Xd, Xa], axis=0)
            Md = pd.concat([Md] + ma, ignore_index=True)
            yd = np.concatenate([yd] + ya, axis=0)
            print(f"AUX train += {len(Xa)} baris dari {aux}", flush=True)
        for k, v in parts.items():
            print(f"{k}: {len(v)} baris", flush=True)
        assert all(len(v) > 0 for v in parts.values()), "split kosong!"
        cfg = f"{a.layer_init}_h{a.hid}" + (f"_fx{a.fixed_epochs}" if a.fixed_epochs else "")
        cfg += ("_rand" if a.rand else "") + ("_aux" + "+".join(aux) if aux else "")
        cfg += ("_unorm" if a.unorm else "")
        train_eval(Xd, yd, Md, EMO6, f"single_{ds}_{cfg}", a.epochs, a.seeds, hid=a.hid,
                   layer_init=a.layer_init, fixed_epochs=a.fixed_epochs, wd=a.wd, lr=a.lr,
                   unorm=a.unorm, sampler=a.sampler, per_combo=a.per_combo)
