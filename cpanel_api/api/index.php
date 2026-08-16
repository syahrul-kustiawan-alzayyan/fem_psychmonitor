<?php
// ============================================================
// Fem-Psych Monitor — Status API
// GET /api/ → { ok: true, service: "fem-psychmonitor-api", ... }
// ============================================================
require_once __DIR__ . '/db.php';

json_response([
    'ok' => true,
    'service' => 'fem-psychmonitor-api',
    'version' => '1.0',
    'time' => date(DATE_ATOM),
]);
