<?php
// ============================================================
// Fem-Psych Monitor — Endpoint Upload Audio
//   POST /api/upload.php (multipart/form-data, field: audio)
//   Header: X-Api-Key, X-Uid
//   Balas:  { ok: true, url: "https://domain/api/uploads/{uid}/{file}.wav" }
// ============================================================
require_once __DIR__ . '/db.php';

require_api_key();
$uid = uid_from_request();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    fail('Method not allowed', 405);
}

if (!isset($_FILES['audio']) || $_FILES['audio']['error'] !== UPLOAD_ERR_OK) {
    fail('No audio file uploaded', 400);
}

$file = $_FILES['audio'];

if ($file['size'] > MAX_UPLOAD_BYTES) {
    fail('Audio terlalu besar (maks 50 MB)', 413);
}

$ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
if ($ext !== 'wav') {
    fail('Hanya file .wav yang diizinkan', 415);
}

// Hanya simpan jika benar-benar WAV (RIFF header)
$fp = fopen($file['tmp_name'], 'rb');
$header = fread($fp, 12);
fclose($fp);
if (strlen($header) < 12 || substr($header, 0, 4) !== 'RIFF' || substr($header, 8, 4) !== 'WAVE') {
    fail('File bukan WAV yang valid', 415);
}

$userDir = rtrim(UPLOAD_DIR, '/') . '/' . preg_replace('/[^A-Za-z0-9_\-]/', '', $uid);
if (!is_dir($userDir) && !mkdir($userDir, 0755, true)) {
    fail('Gagal membuat direktori upload', 500);
}

$filename = date('Ymd_His') . '_' . bin2hex(random_bytes(4)) . '.wav';
$destination = $userDir . '/' . $filename;

if (!move_uploaded_file($file['tmp_name'], $destination)) {
    fail('Gagal menyimpan file', 500);
}

$url = rtrim(BASE_URL, '/') . '/api/uploads/' . basename($userDir) . '/' . $filename;

json_response(['ok' => true, 'url' => $url], 201);
