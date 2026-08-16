<?php
// ============================================================
// Fem-Psych Monitor — Helper Backend (PDO + response helpers)
// ============================================================
require_once __DIR__ . '/config.php';

// CORS — dibutuhkan oleh build web Flutter
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, X-Api-Key, X-Uid');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

function db(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        $pdo = new PDO(
            'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=utf8mb4',
            DB_USER,
            DB_PASS,
            [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
            ]
        );
    }
    return $pdo;
}

/** Kirim respons JSON dan hentikan eksekusi. */
function json_response($data, int $status = 200): void {
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

/** Kirim respons error. */
function fail(string $message, int $status = 400): void {
    json_response(['ok' => false, 'error' => $message], $status);
}

/** Validasi shared secret API key dari header (atau ?api_key= untuk tes browser). */
function require_api_key(): void {
    $key = $_SERVER['HTTP_X_API_KEY'] ?? ($_GET['api_key'] ?? '');
    if ($key === '' || !hash_equals(API_KEY, $key)) {
        fail('Unauthorized', 401);
    }
}

/** Ambil UID dari header X-Uid (atau query ?uid= untuk admin). */
function uid_from_request(): string {
    $uid = $_SERVER['HTTP_X_UID'] ?? ($_GET['uid'] ?? '');
    $uid = trim($uid);
    if ($uid === '' || strlen($uid) > 128) {
        fail('Missing X-Uid header', 401);
    }
    return $uid;
}

/** Parse JSON body dari request. */
function json_body(): array {
    $raw = file_get_contents('php://input');
    if ($raw === '') return [];
    $data = json_decode($raw, true);
    if (!is_array($data)) fail('Invalid JSON body', 400);
    return $data;
}

/** Format datetime DB menjadi ISO 8601 untuk aplikasi Flutter. */
function iso(?string $value): ?string {
    if ($value === null || $value === '') return null;
    $ts = is_numeric($value) ? (int)$value : strtotime($value);
    return $ts ? date('c', $ts) : null;
}

/** Format satu baris users menjadi JSON. */
function format_user(array $row): array {
    return [
        'uid' => $row['uid'],
        'name' => $row['name'],
        'email' => $row['email'],
        'bigfive_scores' => json_decode($row['bigfive_scores'] ?? '{}', true) ?: [],
        'psych_score' => $row['psych_score'] !== null ? (int)$row['psych_score'] : null,
        'is_premium' => (bool)$row['is_premium'],
        'premium_expiry' => iso($row['premium_expiry']),
        'is_admin' => (bool)$row['is_admin'],
        'created_at' => iso($row['created_at']),
        'updated_at' => iso($row['updated_at']),
    ];
}

/** Format satu baris recordings menjadi JSON. */
function format_recording(array $row): array {
    return [
        'id' => (int)$row['id'],
        'date' => iso($row['date']),
        'dominant_emotion' => $row['dominant_emotion'],
        'confidence' => (float)$row['confidence'],
        'suggestion' => $row['suggestion'],
        'audio_emotions' => json_decode($row['audio_emotions'] ?? '{}', true) ?: [],
        'transcript_emotions' => json_decode($row['transcript_emotions'] ?? '{}', true) ?: [],
        'transcript_text' => $row['transcript_text'],
        'duration_seconds' => (int)$row['duration_seconds'],
        'trigger_tag' => $row['trigger_tag'],
        'audio_url' => $row['audio_url'],
    ];
}

/** Cek apakah sebuah UID adalah admin. */
function is_admin_uid(string $uid): bool {
    $st = db()->prepare('SELECT is_admin FROM users WHERE uid = ?');
    $st->execute([$uid]);
    return (bool)$st->fetchColumn();
}
