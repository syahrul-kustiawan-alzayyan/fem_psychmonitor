#!/usr/bin/env node
// ============================================================
// Migrasi data Firestore → API cPanel (MySQL) — Fem-Psych Monitor
//
// Membaca semua users/{uid} (beserta sub-koleksi recordings
// dan snapshots) dari Cloud Firestore, lalu menuliskannya
// ulang melalui endpoint API di cpanel_api/api/.
//
// Prasyarat:
//   1. npm install                      (memasang firebase-admin)
//   2. Service account dari Firebase Console:
//      Project settings > Service accounts > Generate new private key
//   3. URL API + shared API_KEY yang sama dengan
//      cpanel_api/api/config.php
//
// Penggunaan:
//   node migrate.js --service-account firebase-key.json \
//       --api-url https://psychmonitor.com/api --api-key <API_KEY> \
//       --dry-run
//   node migrate.js --service-account firebase-key.json \
//       --api-url https://psychmonitor.com/api --api-key <API_KEY>
//
// Opsi:
//   --service-account <path>  File JSON kredensial Firebase
//                             (atau env GOOGLE_APPLICATION_CREDENTIALS)
//   --api-url <url>           Base URL API (atau env API_BASE_URL)
//   --api-key <key>           Shared secret (atau env API_KEY)
//   --dry-run                 Hanya baca Firestore + laporan, tanpa menulis
//   --limit <n>               Proses hanya n user (untuk uji coba)
//   --admin-uid <uid>         Paksa is_admin = 1 untuk uid ini
//   --force                   Ulangi user/recording yang sudah dimigrasi
//   --migrate-audio           Unduh .wav lama dari Firebase Storage lalu
//                             upload ulang ke upload.php (default: URL lama
//                             tetap dipakai apa adanya)
//   --state <path>            File state idempotensi (default: migration_state.json)
//
// State: migration_state.json menyimpan uid/recording yang sudah diproses
// sehingga script aman dijalankan ulang (user.php & premium.php memang
// upsert; recording/snapshot dilewati jika sudah tercatat).
// ============================================================

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const args = parseArgs(process.argv.slice(2));
const SERVICE_ACCOUNT =
  args['service-account'] || process.env.GOOGLE_APPLICATION_CREDENTIALS;
const API_URL = args['api-url'] || process.env.API_BASE_URL;
const API_KEY = args['api-key'] || process.env.API_KEY;
const DRY_RUN = !!args['dry-run'];
const LIMIT = args['limit'] ? parseInt(args['limit'], 10) : Infinity;
const FORCE = !!args['force'];
const ADMIN_UID = args['admin-uid'] || null;
const MIGRATE_AUDIO = !!args['migrate-audio'];
const STATE_FILE = args['state'] || path.join(__dirname, 'migration_state.json');
const REPORT_FILE = path.join(__dirname, 'migration_report.json');

if (!SERVICE_ACCOUNT || !API_URL || !API_KEY) {
  console.error(
    'Usage: node migrate.js --service-account <key.json> --api-url <url> --api-key <key> [--dry-run] [--limit N] [--migrate-audio]'
  );
  process.exit(2);
}

let state = { users: {}, recordings: {} };
if (!FORCE && fs.existsSync(STATE_FILE)) {
  state = JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
}

const report = { started_at: new Date().toISOString(), users: [], failures: 0 };

function parseArgs(argv) {
  const out = {};
  for (let i = 0; i < argv.length; i++) {
    if (argv[i].startsWith('--')) {
      const key = argv[i].slice(2);
      const next = argv[i + 1];
      if (next && !next.startsWith('--')) {
        out[key] = next;
        i++;
      } else {
        out[key] = true;
      }
    }
  }
  return out;
}

// ------------------------------------------------------------------
// Helper Firestore → bentuk yang diterima API
// ------------------------------------------------------------------
function toIso(value) {
  if (value == null) return null;
  if (typeof value.toDate === 'function') {
    try { return value.toDate().toISOString(); } catch { return null; }
  }
  if (value instanceof Date) return value.toISOString();
  if (typeof value === 'string') return value;
  if (typeof value === 'number') return new Date(value).toISOString();
  return null;
}

function toMap(value) {
  if (value == null) return {};
  if (typeof value === 'string') {
    try { return JSON.parse(value); } catch { return {}; }
  }
  if (value && typeof value === 'object' && typeof value.toDate === 'function') return {};
  return value;
}

function isoToApi(v) { return toIso(v); }

// ------------------------------------------------------------------
// Klien API
// ------------------------------------------------------------------
async function api(pathname, { method = 'GET', body, uid, query = {} } = {}) {
  const qs = new URLSearchParams(query).toString();
  const url = `${API_URL}/${pathname}${qs ? '?' + qs : ''}`;
  const headers = { 'X-Api-Key': API_KEY, Accept: 'application/json' };
  if (uid) headers['X-Uid'] = uid;
  let payload;
  if (body !== undefined) {
    headers['Content-Type'] = 'application/json';
    payload = JSON.stringify(body);
  }
  const res = await fetch(url, { method, headers, body: payload });
  const text = await res.text();
  let data;
  try { data = JSON.parse(text); } catch { data = { ok: false, error: text }; }
  if (!res.ok || data.ok !== true) {
    throw new Error(`${res.status} ${data.error || JSON.stringify(data)}`);
  }
  return data;
}

// ------------------------------------------------------------------
// Migrasi satu user (dan semua datanya)
// ------------------------------------------------------------------
async function migrateUser(firestore, uid, doc) {
  const data = doc.data() || {};
  const u = { uid };

  const isAdmin =
    ADMIN_UID === uid ||
    data.isAdmin === true ||
    data.is_admin === true ||
    data.isAdmin === 'true';

  if (!DRY_RUN) {
    await api('user.php', {
      method: 'POST',
      uid,
      body: {
        name: data.name || 'User',
        email: data.email || '',
        bigfive_scores: toMap(data.bigfive_scores),
        psych_score: data.psych_score != null ? Number(data.psych_score) : null,
        is_admin: isAdmin ? 1 : 0,
      },
    });

    if (data.is_premium === true || data.is_premium === 1 || data.premium_expiry) {
      await api('premium.php', {
        method: 'POST',
        uid,
        body: {
          is_premium: data.is_premium === true || data.is_premium === 1,
          premium_expiry: toIso(data.premium_expiry),
        },
      });
    }
  }

  const recCount = { recordings: 0, snapshots: 0, audio: 0 };
  const failures = [];

  const recSnap = await firestore
    .collection('users').doc(uid)
    .collection('recordings').get();

  for (const recDoc of recSnap.docs) {
    const key = `${uid}/${recDoc.id}`;
    if (!FORCE && state.recordings[key]) continue;

    const r = recDoc.data() || {};
    const recBody = {
      date: toIso(r.date) || new Date().toISOString(),
      dominant_emotion: r.dominant_emotion || 'neutral',
      confidence: r.confidence != null ? Number(r.confidence) : 0.0,
      suggestion: r.suggestion || '',
      audio_emotions: toMap(r.audio_emotions),
      transcript_emotions: toMap(r.transcript_emotions),
      transcript_text: r.transcript_text || '',
      duration_seconds: r.duration_seconds != null ? Number(r.duration_seconds) : 0,
      trigger_tag: r.trigger_tag || '',
      audio_url: r.audio_url || '',
    };

    try {
      let newRecId = null;
      if (!DRY_RUN) {
        const created = await api('recording.php', { method: 'POST', uid, body: recBody });
        newRecId = created.id;
        state.recordings[key] = newRecId;

        const snapSnap = await firestore
          .collection('users').doc(uid)
          .collection('recordings').doc(recDoc.id)
          .collection('snapshots').get();

        const snapshots = snapSnap.docs.map((s) => {
          const sd = s.data() || {};
          return {
            emotion: sd.emotion || 'neutral',
            confidence: sd.confidence != null ? Number(sd.confidence) : 0.0,
            source: sd.source || 'combined',
            timestamp: toIso(sd.timestamp) || new Date().toISOString(),
          };
        });
        if (snapshots.length > 0) {
          for (let i = 0; i < snapshots.length; i += 500) {
            await api('snapshot.php', {
              method: 'POST',
              uid,
              body: {
                recording_id: newRecId,
                snapshots: snapshots.slice(i, i + 500),
              },
            });
          }
        }
        recCount.snapshots += snapshots.length;

        if (MIGRATE_AUDIO && recBody.audio_url) {
          const newUrl = await reuploadAudio(uid, recBody.audio_url);
          if (newUrl) {
            await api(`recording.php?action=audio_url&id=${newRecId}`, {
              method: 'PUT',
              uid,
              body: { audio_url: newUrl },
            });
            recCount.audio++;
          }
        }
      } else {
        const snapSnap = await firestore
          .collection('users').doc(uid)
          .collection('recordings').doc(recDoc.id)
          .collection('snapshots').get();
        recCount.snapshots += snapSnap.size;
      }
      recCount.recordings++;
    } catch (e) {
      failures.push({ recording: recDoc.id, error: e.message });
    }
  }

  if (!DRY_RUN) {
    state.users[uid] = true;
  }
  return { ...u, is_admin: isAdmin, ...recCount, failures };
}

async function reuploadAudio(uid, oldUrl) {
  if (!oldUrl.startsWith('http')) return null;
  try {
    const dl = await fetch(oldUrl, { signal: AbortSignal.timeout(60000) });
    if (!dl.ok) return null;
    const buf = Buffer.from(await dl.arrayBuffer());
    if (buf.length === 0) return null;

    const fd = new FormData();
    fd.append('audio', new Blob([buf], { type: 'audio/wav' }), `migrated-${Date.now()}.wav`);
    const res = await fetch(`${API_URL}/upload.php`, {
      method: 'POST',
      headers: { 'X-Api-Key': API_KEY, 'X-Uid': uid },
      body: fd,
      signal: AbortSignal.timeout(120000),
    });
    const data = await res.json();
    if (!res.ok || data.ok !== true) return null;
    return data.url;
  } catch {
    return null;
  }
}

// ------------------------------------------------------------------
// Main
// ------------------------------------------------------------------
async function main() {
  admin.initializeApp({
    credential: admin.credential.cert(require(path.resolve(SERVICE_ACCOUNT))),
  });
  const firestore = admin.firestore();

  const usersSnap = await firestore.collection('users').get();
  const total = usersSnap.size;
  console.log(
    `[migrate] ${DRY_RUN ? 'DRY-RUN (tanpa menulis)' : 'Migrasi'} — ${total} user ditemukan di Firestore`
  );
  if (DRY_RUN) console.log('[migrate] mode kering: tidak ada data yang ditulis');

  let done = 0;
  for (const doc of usersSnap.docs) {
    if (done >= LIMIT) break;
    const uid = doc.id;
    if (!FORCE && state.users[uid]) {
      console.log(`[skip]  ${uid} (sudah dimigrasi)`);
      continue;
    }

    const r = await migrateUser(firestore, uid, doc);
    done++;
    console.log(
      `[ok]    ${uid} — recording: ${r.recordings}, snapshots: ${r.snapshots}, audio: ${r.audio}${r.failures.length ? `, gagal: ${r.failures.length}` : ''}`
    );
    report.users.push({ uid, ...r });
    report.failures += r.failures.length;
    for (const f of r.failures) {
      console.error(`[error] ${uid}/${f.recording}: ${f.error}`);
    }
  }

  if (!DRY_RUN) {
    fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
  }
  fs.writeFileSync(REPORT_FILE, JSON.stringify(report, null, 2));

  console.log(
    `[done]  ${done} user diproses, ${report.failures} kesalahan → laporan: ${REPORT_FILE}`
  );
  process.exit(report.failures > 0 ? 1 : 0);
}

main().catch((e) => {
  console.error('[fatal]', e.message);
  process.exit(1);
});