<?php
// ============================================================
// Fem-Psych Monitor — Endpoint Premium
//   GET  /api/premium.php → { is_premium, premium_expiry } untuk X-Uid
//   POST /api/premium.php → simpan status premium (X-Uid)
// ============================================================
require_once __DIR__ . '/db.php';

require_api_key();
$uid = uid_from_request();
$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    case 'GET':
        $st = db()->prepare('SELECT is_premium, premium_expiry FROM users WHERE uid = ?');
        $st->execute([$uid]);
        $row = $st->fetch();
        if (!$row) {
            json_response(['ok' => true, 'data' => ['is_premium' => false, 'premium_expiry' => null]]);
        }
        json_response([
            'ok' => true,
            'data' => [
                'is_premium' => (bool)$row['is_premium'],
                'premium_expiry' => iso($row['premium_expiry']),
            ],
        ]);
        break;

    case 'POST':
        $body = json_body();
        $st = db()->prepare(
            'INSERT INTO users (uid, is_premium, premium_expiry, created_at, updated_at)
             VALUES (?, ?, ?, NOW(), NOW())
             ON DUPLICATE KEY UPDATE
               is_premium = VALUES(is_premium),
               premium_expiry = VALUES(premium_expiry),
               updated_at = NOW()'
        );
        $st->execute([
            $uid,
            !empty($body['is_premium']) ? 1 : 0,
            !empty($body['premium_expiry'])
                ? date('Y-m-d H:i:s', strtotime($body['premium_expiry']))
                : null,
        ]);
        json_response(['ok' => true]);
        break;

    default:
        fail('Method not allowed', 405);
}
