<?php
// ============================================================
// Fem-Psych Monitor — Endpoint Premium
//   GET  /api/premium.php → { is_premium, premium_expiry } untuk X-Uid
//   POST /api/premium.php → verifikasi purchase token via Google Play
//                           Developer API, lalu simpan status (X-Uid)
//
// POST BODY: { product_id, purchase_token }
// Klien TIDAK PERNAH mengirim is_premium — server yang menentukan.
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
        $productId = trim((string)($body['product_id'] ?? ''));
        $purchaseToken = trim((string)($body['purchase_token'] ?? ''));

        if ($productId === '' || $purchaseToken === '') {
            fail('Missing product_id or purchase_token', 400);
        }

        $verified = google_play_verify_subscription($productId, $purchaseToken);

        if (!$verified['ok']) {
            // Token tidak valid / produk tidak cocok / API error
            fail($verified['error'] ?? 'Verification failed', 401);
        }

        $isPremium = $verified['is_premium'];
        $premiumExpiry = $verified['premium_expiry']; // 'Y-m-d H:i:s' | null

        // Simpan hanya hasil verifikasi server (bukan nilai dari klien)
        $st = db()->prepare(
            'INSERT INTO users (uid, is_premium, premium_expiry, created_at, updated_at)
             VALUES (?, ?, ?, NOW(), NOW())
             ON DUPLICATE KEY UPDATE
               is_premium = VALUES(is_premium),
               premium_expiry = VALUES(premium_expiry),
               updated_at = NOW()'
        );
        $st->execute([$uid, $isPremium ? 1 : 0, $premiumExpiry]);

        json_response([
            'ok' => true,
            'data' => [
                'is_premium' => $isPremium,
                'premium_expiry' => iso($premiumExpiry),
            ],
        ]);
        break;

    default:
        fail('Method not allowed', 405);
}

/**
 * Verifikasi purchase token subscription ke Google Play Developer API.
 *
 * Mengembalikan:
 *   ['ok' => true,  'is_premium' => bool, 'premium_expiry' => 'Y-m-d H:i:s'|null]
 *   ['ok' => false, 'error' => string]
 */
function google_play_verify_subscription(string $productId, string $purchaseToken): array
{
    $package = defined('GOOGLE_PLAY_PACKAGE') ? GOOGLE_PLAY_PACKAGE : '';
    $credFile = defined('GOOGLE_SERVICE_ACCOUNT_FILE') ? GOOGLE_SERVICE_ACCOUNT_FILE : '';
    if ($package === '' || $credFile === '' || !is_file($credFile)) {
        return ['ok' => false, 'error' => 'Server not configured for billing verification'];
    }

    $accessToken = google_service_account_token($credFile);
    if ($accessToken === null) {
        return ['ok' => false, 'error' => 'Failed to obtain Google access token'];
    }

    $url = 'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/'
        . rawurlencode($package)
        . '/purchases/subscriptionsv2/tokens/'
        . rawurlencode($purchaseToken);

    $res = google_http_get($url, $accessToken);
    $status = $res['status'] ?? 0;
    $json = json_decode($res['body'] ?? '', true);

    if ($status < 200 || $status >= 300) {
        return ['ok' => false, 'error' => 'Play API error ' . $status];
    }

    // subscriptionState: SUBSCRIBED, EXPIRED, CANCELED, ON_HOLD, IN_GRACE_PERIOD,
    // PAUSED, REVOKED, EXPIRED_BUT_CHARGED (v3 API)
    $state = $json['subscriptionState'] ?? '';
    if ($state !== 'SUBSCRIBED') {
        return ['ok' => false, 'error' => 'Subscription not active (' . $state . ')'];
    }

    // Pastikan token milik produk yang diminta
    $lineItem = $json['lineItems'][0] ?? [];
    $apiProductId = $lineItem['productId'] ?? '';
    if ($apiProductId !== '' && $apiProductId !== $productId) {
        return ['ok' => false, 'error' => 'Product mismatch'];
    }

    $expiryTs = isset($json['expiryTime'])
        ? strtotime($json['expiryTime'])
        : 0;

    return [
        'ok' => true,
        'is_premium' => true,
        'premium_expiry' => $expiryTs ? date('Y-m-d H:i:s', $expiryTs) : null,
    ];
}

/**
 * Ambil OAuth2 access token dari service account (JWT RS256, tanpa Composer).
 * Kredensial dibaca dari file JSON di server — JANGAN commit ke repo.
 */
function google_service_account_token(string $credFile): ?string
{
    $cred = json_decode(file_get_contents($credFile), true);
    if (!is_array($cred) || empty($cred['client_email']) || empty($cred['private_key'])) {
        return null;
    }

    $now = time();
    $header = base64url_encode(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
    $claims = base64url_encode(json_encode([
        'iss' => $cred['client_email'],
        'scope' => 'https://www.googleapis.com/auth/androidpublisher',
        'aud' => 'https://oauth2.googleapis.com/token',
        'iat' => $now,
        'exp' => $now + 3600,
    ]));

    $signature = '';
    $key = openssl_pkey_get_private($cred['private_key']);
    if ($key === false) return null;
    openssl_sign($header . '.' . $claims, $signature, $key, OPENSSL_ALGO_SHA256);
    $jwt = $header . '.' . $claims . '.' . base64url_encode($signature);

    $payload = 'grant_type=' . rawurlencode('urn:ietf:params:oauth:grant-type:jwt-bearer')
        . '&assertion=' . rawurlencode($jwt);

    $ctx = stream_context_create(['http' => [
        'method' => 'POST',
        'header' => "Content-Type: application/x-www-form-urlencoded\r\n",
        'content' => $payload,
        'ignore_errors' => true,
        'timeout' => 15,
    ]]);
    $body = file_get_contents('https://oauth2.googleapis.com/token', false, $ctx);
    $json = json_decode($body === false ? '' : $body, true);

    return $json['access_token'] ?? null;
}

function google_http_get(string $url, string $accessToken): array
{
    $ctx = stream_context_create(['http' => [
        'method' => 'GET',
        'header' => 'Authorization: Bearer ' . $accessToken . "\r\n"
            . "Accept: application/json\r\n",
        'ignore_errors' => true,
        'timeout' => 15,
    ]]);
    $body = file_get_contents($url, false, $ctx);
    $status = 0;
    if (isset($http_response_header[0]) && preg_match('/\s(\d{3})\s/', $http_response_header[0], $m)) {
        $status = (int)$m[1];
    }
    return ['status' => $status, 'body' => $body === false ? '' : $body];
}

function base64url_encode(string $data): string
{
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}
