<?php
// ============================================================
// Fem-Psych Monitor — Konfigurasi Backend
// Sesuaikan dengan kredensial MySQL dari cPanel Anda.
// ============================================================

// Kredensial MySQL (cPanel > MySQL Databases)
define('DB_HOST', 'localhost');
define('DB_NAME', 'ganti_nama_database');
define('DB_USER', 'ganti_user_database');
define('DB_PASS', 'ganti_password_database');

// Shared secret — WAJIB sama persis dengan API_KEY di file .env aplikasi Flutter
define('API_KEY', 'ganti_dengan_secret_acak_panjang');

// Base URL domain aplikasi (tanpa trailing slash).
// Contoh: https://psikmonitorku.com  atau  https://localhost/fem_psych
define('BASE_URL', 'https://ganti-domain-anda.com');

// Lokasi penyimpanan file audio (relatif terhadap folder api/)
define('UPLOAD_DIR', __DIR__ . '/uploads');

// Batas maksimum ukuran audio upload (50 MB)
define('MAX_UPLOAD_BYTES', 50 * 1024 * 1024);
