<?php
// ============================================================
// Fem-Psych Monitor — Endpoint User
//   GET    /api/user.php              → data user (X-Uid) atau {data: null}
//   GET    /api/user.php?action=admin_exists → {exists: bool}
//   POST   /api/user.php              → upsert data user (X-Uid)
//   DELETE /api/user.php              → hapus user + recording + snapshots
// ============================================================
require_once __DIR__ . '/db.php';

require_api_key();
$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? '';

switch ($method) {
    case 'GET':
        if ($action === 'admin_exists') {
            $exists = (bool)db()
                ->query('SELECT COUNT(*) FROM users WHERE is_admin = 1')
                ->fetchColumn();
            json_response(['ok' => true, 'exists' => $exists]);
        }

        $uid = uid_from_request();
        $st = db()->prepare('SELECT * FROM users WHERE uid = ?');
        $st->execute([$uid]);
        $row = $st->fetch();
        json_response(['ok' => true, 'data' => $row ? format_user($row) : null]);
        break;

    case 'POST':
        $uid = uid_from_request();
        $body = json_body();

        $st = db()->prepare(
            'INSERT INTO users
               (uid, name, email, bigfive_scores, psych_score, is_admin, created_at, updated_at)
             VALUES (?, ?, ?, ?, ?, ?, NOW(), NOW())
             ON DUPLICATE KEY UPDATE
               name = VALUES(name),
               email = VALUES(email),
               bigfive_scores = VALUES(bigfive_scores),
               psych_score = VALUES(psych_score),
               is_admin = IF(VALUES(is_admin) = 1, 1, is_admin),
               updated_at = NOW()'
        );
        $st->execute([
            $uid,
            $body['name'] ?? 'User',
            $body['email'] ?? '',
            isset($body['bigfive_scores']) && is_array($body['bigfive_scores'])
                ? json_encode($body['bigfive_scores'], JSON_UNESCAPED_UNICODE)
                : '{}',
            isset($body['psych_score']) ? (int)$body['psych_score'] : null,
            !empty($body['is_admin']) ? 1 : 0,
        ]);
        json_response(['ok' => true, 'id' => $uid]);
        break;

    case 'DELETE':
        $uid = uid_from_request();
        $db = db();
        $db->prepare('DELETE FROM users WHERE uid = ?')->execute([$uid]);
        json_response(['ok' => true]);
        break;

    default:
        fail('Method not allowed', 405);
}
