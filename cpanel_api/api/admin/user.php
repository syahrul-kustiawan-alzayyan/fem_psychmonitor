<?php
// ============================================================
// Fem-Psych Monitor — Endpoint Admin: Detail Satu Pengguna
//   GET /api/admin/user.php?uid=XXX → { user: {...}, recordings: [...] }
//   (X-Uid harus berstatus admin)
// ============================================================
require_once __DIR__ . '/../db.php';

require_api_key();
$adminUid = uid_from_request();
if (!is_admin_uid($adminUid)) {
    fail('Forbidden', 403);
}

$targetUid = $_GET['uid'] ?? '';
if ($targetUid === '' || strlen($targetUid) > 128) {
    fail('uid required', 400);
}

$db = db();

$st = db()->prepare('SELECT * FROM users WHERE uid = ?');
$st->execute([$targetUid]);
$row = $st->fetch();
if (!$row) {
    fail('Data pengguna tidak ditemukan', 404);
}

$recSt = db()->prepare(
    'SELECT * FROM recordings WHERE uid = ? ORDER BY date DESC'
);
$recSt->execute([$targetUid]);
$recordings = array_map('format_recording', $recSt->fetchAll());

json_response([
    'ok' => true,
    'user' => format_user($row),
    'recordings' => $recordings,
]);
