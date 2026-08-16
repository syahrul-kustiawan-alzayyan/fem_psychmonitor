<?php
// ============================================================
// Fem-Psych Monitor — Endpoint Snapshot (per 3 detik)
//   POST /api/snapshot.php             → insert batch
//        body: { recording_id, snapshots: [{emotion, confidence, source, timestamp}] }
//   GET  /api/snapshot.php?recording_id=123 → list snapshots
// ============================================================
require_once __DIR__ . '/db.php';

require_api_key();
$uid = uid_from_request();
$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    case 'GET':
        $recordingId = (int)($_GET['recording_id'] ?? 0);
        if ($recordingId <= 0) fail('recording_id required');

        // Pastikan recording milik user ini
        $own = db()->prepare('SELECT id FROM recordings WHERE id = ? AND uid = ?');
        $own->execute([$recordingId, $uid]);
        if (!$own->fetch()) fail('Recording not found', 404);

        $st = db()->prepare(
            'SELECT * FROM emotion_snapshots WHERE recording_id = ? ORDER BY timestamp ASC'
        );
        $st->execute([$recordingId]);
        $rows = array_map(function (array $r) {
            return [
                'id' => (int)$r['id'],
                'recording_id' => (int)$r['recording_id'],
                'emotion' => $r['emotion'],
                'confidence' => (float)$r['confidence'],
                'source' => $r['source'],
                'timestamp' => iso($r['timestamp']),
            ];
        }, $st->fetchAll());
        json_response(['ok' => true, 'data' => $rows]);
        break;

    case 'POST':
        $body = json_body();
        $recordingId = (int)($body['recording_id'] ?? 0);
        $snapshots = $body['snapshots'] ?? [];
        if ($recordingId <= 0 || !is_array($snapshots) || count($snapshots) === 0) {
            fail('recording_id and snapshots required');
        }

        $own = db()->prepare('SELECT id FROM recordings WHERE id = ? AND uid = ?');
        $own->execute([$recordingId, $uid]);
        if (!$own->fetch()) fail('Recording not found', 404);

        $st = db()->prepare(
            'INSERT INTO emotion_snapshots (recording_id, emotion, confidence, source, timestamp)
             VALUES (?, ?, ?, ?, ?)'
        );
        foreach ($snapshots as $snap) {
            $st->execute([
                $recordingId,
                $snap['emotion'] ?? 'neutral',
                isset($snap['confidence']) ? (float)$snap['confidence'] : 0.0,
                $snap['source'] ?? 'combined',
                date('Y-m-d H:i:s', strtotime($snap['timestamp'] ?? 'now')),
            ]);
        }
        json_response(['ok' => true, 'inserted' => count($snapshots)]);
        break;

    default:
        fail('Method not allowed', 405);
}
