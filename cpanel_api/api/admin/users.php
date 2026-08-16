<?php
// ============================================================
// Fem-Psych Monitor — Endpoint Admin: Daftar Pengguna
//   GET /api/admin/users.php → { users: [...], emotion_distribution: {...} }
//   (X-Uid harus berstatus admin)
// ============================================================
require_once __DIR__ . '/../db.php';

require_api_key();
$uid = uid_from_request();
if (!is_admin_uid($uid)) {
    fail('Forbidden', 403);
}

$db = db();

$usersRows = $db->query(
    'SELECT u.*,
            (SELECT COUNT(*) FROM recordings r WHERE r.uid = u.uid) AS recording_count
     FROM users u
     WHERE u.is_admin = 0
     ORDER BY u.created_at DESC'
)->fetchAll();

$users = array_map(function (array $row) {
    $u = format_user($row);
    $u['recording_count'] = (int)$row['recording_count'];
    return $u;
}, $usersRows);

$dist = $db->query(
    'SELECT dominant_emotion, COUNT(*) AS c FROM recordings GROUP BY dominant_emotion'
)->fetchAll();

$emotionDistribution = [];
foreach ($dist as $d) {
    $emotionDistribution[$d['dominant_emotion']] = (int)$d['c'];
}

json_response([
    'ok' => true,
    'users' => $users,
    'emotion_distribution' => $emotionDistribution,
]);
