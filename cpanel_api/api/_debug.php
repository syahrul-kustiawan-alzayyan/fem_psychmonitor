<?php
// ============================================================
// DIAGNOSTIK SEMENTARA — HAPUS FILE INI SETELAH DIPAKAI!
// Buka: https://domain.com/api/_debug.php
// ============================================================
error_reporting(E_ALL);
ini_set('display_errors', '1');

require_once __DIR__ . '/config.php';

echo '<pre>';
echo "PHP version  : ", PHP_VERSION, "\n";
echo "Placeholders? : ", (strpos(DB_NAME, 'ganti_') !== false || strpos(DB_USER, 'ganti_') !== false ? 'YA - config.php BELUM diisi' : 'TIDAK - sudah diisi'), "\n";

try {
    $pdo = new PDO(
        'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=utf8mb4',
        DB_USER,
        DB_PASS,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
    echo "DB koneksi   : OK\n";

    // Cek tabel users
    $tables = $pdo->query('SHOW TABLES')->fetchAll(PDO::FETCH_COLUMN);
    echo "Tabel        : ", implode(', ', $tables), "\n";

    // Cek schema users (ada kolom is_admin, uid?)
    $cols = $pdo->query('SHOW COLUMNS FROM users')->fetchAll(PDO::FETCH_COLUMN);
    echo "Kolom users  : ", implode(', ', $cols), "\n";
} catch (PDOException $e) {
    echo "DB koneksi   : GAGAL\n";
    echo "Error        : ", htmlspecialchars($e->getMessage()), "\n";
}
echo '</pre>';
