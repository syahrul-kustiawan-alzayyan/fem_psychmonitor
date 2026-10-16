<?php
// ============================================================
// Fem-Psych Monitor — Contoh Konfigurasi Backend
//
// CARA PAKAI:
//   1. Salin file ini menjadi `config.php` (di folder yang sama).
//   2. Isi semua nilai di bawah dengan kredensial asli.
//   3. JANGAN PERNAH commit `config.php` ke repo
//      (sudah masuk .gitignore). Hanya file contoh ini yang di-commit.
//
//   API_KEY di sini WAJIB sama persis dengan API_KEY di file
//   `.env` aplikasi Flutter.
// ============================================================

// Kredensial MySQL (cPanel > MySQL Databases)
define('DB_HOST', 'localhost');
define('DB_NAME', 'NAMA_DATABASE_ANDA');
define('DB_USER', 'USER_DATABASE_ANDA');
define('DB_PASS', 'PASSWORD_DATABASE_ANDA');

// Shared secret — buat string acak panjang, mis. via:
//   openssl rand -hex 32
define('API_KEY', 'GANTI_DENGAN_SECRET_ACAK_PANJANG');

// Base URL domain aplikasi (tanpa trailing slash).
// Contoh: https://psikmonitorku.com
define('BASE_URL', 'https://DOMAIN_ANDA.COM');

// Lokasi penyimpanan file audio (relatif terhadap folder api/)
define('UPLOAD_DIR', __DIR__ . '/uploads');

// Batas maksimum ukuran audio upload (50 MB)
define('MAX_UPLOAD_BYTES', 50 * 1024 * 1024);

// Google Play Billing — verifikasi purchase token
// package name app di Play Console
define('GOOGLE_PLAY_PACKAGE', 'com.fempsychmonitor');

// Path file kredensial service account (JSON) DI SERVER.
// Buat di Google Cloud Console (Play Developer API + role
// "Play Console App Admin"), download JSON-nya, upload KE LUAR
// webroot (mis. /home/user/private/play-service-account.json).
// JANGAN PERNAH commit file ini ke repository.
define('GOOGLE_SERVICE_ACCOUNT_FILE', __DIR__ . '/../private/play-service-account.json');
