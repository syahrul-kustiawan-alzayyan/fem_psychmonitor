<?php
// ============================================================
// Fem-Psych Monitor — Endpoint Recording
//   GET  /api/recording.php                → semua recording (X-Uid)
//   GET  /api/recording.php?id=123         → satu recording (X-Uid)
//   POST /api/recording.php                → buat recording, balas {id}
//   PUT  /api/recording.php?action=trigger&id=123   → set trigger_tag
//   PUT  /api/recording.php?action=audio_url&id=123 → set audio_url
// ============================================================
require_once __DIR__ . '/db.php';

require_api_key();
$uid = uid_from_request();
$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? '';

switch ($method) {
    case 'GET':
        $id = $_GET['id'] ?? null;
        if ($id !== null) {
            $st = db()->prepare('SELECT * FROM recordings WHERE id = ? AND uid = ?');
            $st->execute([(int)$id, $uid]);
            $row = $st->fetch();
            json_response(['ok' => true, 'data' => $row ? format_recording($row) : null]);
        } else {
            $st = db()->prepare('SELECT * FROM recordings WHERE uid = ? ORDER BY date DESC');
            $st->execute([$uid]);
            $rows = array_map('format_recording', $st->fetchAll());
            json_response(['ok' => true, 'data' => $rows]);
        }
        break;

    case 'POST':
        $body = json_body();
        if (empty($body['dominant_emotion'])) {
            fail('dominant_emotion required');
        }
        $st = db()->prepare(
            'INSERT INTO recordings
               (uid, date, dominant_emotion, confidence, suggestion, audio_emotions,
                transcript_emotions, transcript_text, duration_seconds, trigger_tag, audio_url)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
        );
        $st->execute([
            $uid,
            date('Y-m-d H:i:s', strtotime($body['date'] ?? 'now')),
            $body['dominant_emotion'],
            isset($body['confidence']) ? (float)$body['confidence'] : 0.0,
            $body['suggestion'] ?? '',
            isset($body['audio_emotions']) && is_array($body['audio_emotions'])
                ? json_encode($body['audio_emotions'], JSON_UNESCAPED_UNICODE)
                : '{}',
            isset($body['transcript_emotions']) && is_array($body['transcript_emotions'])
                ? json_encode($body['transcript_emotions'], JSON_UNESCAPED_UNICODE)
                : '{}',
            $body['transcript_text'] ?? '',
            isset($body['duration_seconds']) ? (int)$body['duration_seconds'] : 0,
            $body['trigger_tag'] ?? '',
            $body['audio_url'] ?? '',
        ]);
        json_response(['ok' => true, 'id' => (int)db()->lastInsertId()], 201);
        break;

    case 'PUT':
        $id = (int)($_GET['id'] ?? 0);
        if ($id <= 0) fail('Recording id required');
        $body = json_body();

        if ($action === 'trigger') {
            $st = db()->prepare('UPDATE recordings SET trigger_tag = ? WHERE id = ? AND uid = ?');
            $st->execute([$body['trigger_tag'] ?? '', $id, $uid]);
            json_response(['ok' => true]);
        } elseif ($action === 'audio_url') {
            $st = db()->prepare('UPDATE recordings SET audio_url = ? WHERE id = ? AND uid = ?');
            $st->execute([$body['audio_url'] ?? '', $id, $uid]);
            json_response(['ok' => true]);
        }
        fail('Unknown action', 400);
        break;

    default:
        fail('Method not allowed', 405);
}
