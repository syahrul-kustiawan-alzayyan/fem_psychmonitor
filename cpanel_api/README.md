# Backend cPanel — Fem-Psych Monitor

Backend pengganti **Cloud Firestore + Firebase Storage** berbasis **PHP + MySQL**,
dirancang untuk shared hosting cPanel.

> Firebase Auth **tetap** dipakai untuk login. UID Firebase menjadi kunci identitas
> di MySQL (`users.uid`), dikirim lewat header `X-Uid`.

## Struktur

```
public_html/
└── api/                    # salin isi folder api/ ini ke sini
    ├── config.php          # kredensial DB + API key + BASE_URL
    ├── db.php              # helper PDO (proteksi via .htaccess)
    ├── user.php            # GET/POST/DELETE user
    ├── recording.php       # CRUD recording
    ├── snapshot.php        # snapshot emosi per 3 detik
    ├── premium.php         # status premium (sinkron dari RevenueCat)
    ├── upload.php          # upload audio .wav
    ├── admin/
    │   ├── users.php       # daftar user + distribusi emosi (admin)
    │   └── user.php        # detail user + recordings (admin)
    ├── .htaccess
    └── uploads/            # file audio (wajib ada + .htaccess)
```

## Cara Setup di cPanel

1. **Buat database**: cPanel → MySQL Databases → buat database + user, beri
   **ALL PRIVILEGES**. Catat nama DB, user, password.
2. **Import skema**: cPanel → phpMyAdmin → pilih database → Import →
   pilih `schema.sql` di repo ini.
3. **Upload file**: salin isi folder `api/` ke `public_html/api/` di File Manager.
   Pastikan folder `public_html/api/uploads/` bisa ditulis (set permission 755
   atau 775).
4. **Edit `config.php`**:
   - `DB_HOST` / `DB_NAME` / `DB_USER` / `DB_PASS` dari langkah 1.
   - `API_KEY`: buat string acak panjang (misal via `openssl rand -hex 32`).
   - `BASE_URL`: domain app, misal `https://psikmonitorku.com`.
5. **Naikkan batas upload**: cPanel → **MultiPHP INI Editor** → pilih domain →
   set `upload_max_filesize = 50M`, `post_max_size = 55M`, `max_execution_time = 120`.

## Endpoint

Semua request wajib header:

```
X-Api-Key: <API_KEY yang sama dengan .env Flutter>
X-Uid:     <Firebase UID user>
```

| Method & Path | Fungsi |
|---|---|
| `GET /api/user.php` | Ambil data user saat ini |
| `GET /api/user.php?action=admin_exists` | Cek akun admin sudah ada |
| `POST /api/user.php` | Upsert user (name, email, bigfive_scores, psych_score, is_admin) |
| `DELETE /api/user.php` | Hapus user + recording + snapshots |
| `GET /api/recording.php` | List recording user |
| `GET /api/recording.php?id=1` | Satu recording |
| `POST /api/recording.php` | Buat recording → balas `id` |
| `PUT /api/recording.php?action=trigger&id=1` | Set `trigger_tag` |
| `PUT /api/recording.php?action=audio_url&id=1` | Set `audio_url` |
| `POST /api/snapshot.php` | Insert batch snapshot |
| `GET /api/snapshot.php?recording_id=1` | List snapshot |
| `GET /api/premium.php` | Status premium user |
| `POST /api/premium.php` | Simpan status premium |
| `GET /api/admin/users.php` | (admin) daftar user + distribusi emosi |
| `GET /api/admin/user.php?uid=XXX` | (admin) detail user + recordings |
| `POST /api/upload.php` | Upload audio `.wav` → balas `url` |

## Test cepat dengan curl

```bash
curl -X POST http://localhost/fem_psych/api/user.php \
  -H "X-Api-Key: YOUR_KEY" -H "X-Uid: test_uid_123" \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@mail.com","bigfive_scores":{"O":3.5,"C":4}}'

curl http://localhost/fem_psych/api/user.php \
  -H "X-Api-Key: YOUR_KEY" -H "X-Uid: test_uid_123"
```

## Catatan keamanan

- `config.php` dan `db.php` diblokir `.htaccess` agar tidak bisa diakses langsung.
- `uploads/` hanya menerima file `.wav` (validasi RIFF header) dan eksekusi PHP
  dimatikan di folder tersebut. Nama file dibuat acak.
- Untuk penyimpanan audio yang benar-benar privat, sebaiknya pindahkan `uploads/`
  ke luar `public_html/` (misal `/home/user/uploads`) lalu layani lewat endpoint
  download dengan verifikasi `X-Uid`. Opsional, di luar cakupan migrasi ini.
- `API_KEY` adalah shared secret sederhana. Untuk proteksi penuh, verifikasi
  Firebase ID token di server (library `firebase/php-jwt`) — langkah hardening opsional.
