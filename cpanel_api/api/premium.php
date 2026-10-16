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

// Jamin error apa pun (fatal/exception PDO) keluar sebagai JSON,
// bukan HTML — supaya klien selalu bisa membacanya.
set_exception_handler(function (Throwable $e) {
    error_log('premium.php exception: ' . $e->getMessage());
    http_response_code(500);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode(
        ['ok' => false, 'error' => 'Server error: ' . $e->getMessage()],
        JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES
    );
    exit;
});

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

    case 'DELETE':
        // Batalkan langganan langsung dari aplikasi.
        // Server memanggil Play Developer API subscriptions.cancel memakai
        // token yang disimpan saat verifikasi, lalu mencabut status premium.
        handle_cancel_subscription($uid);
        break;

    case 'POST':
        // Fallback untuk hosting yang memblokir method DELETE:
        // POST /premium.php?action=cancel berperilaku sama persis.
        if (($_GET['action'] ?? '') === 'cancel') {
            handle_cancel_subscription($uid);
            break;
        }
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

        $colsReady = ensure_premium_columns();

        // Simpan hanya hasil verifikasi server (bukan nilai dari klien).
        // Tidak boleh gagal karena kolom belum termigrasi → fallback ke INSERT
        // versi lama (tanpa token) sehingga pembelian tetap dianggap berhasil.
        if ($colsReady) {
            $st = db()->prepare(
                'INSERT INTO users (uid, is_premium, premium_expiry, subscription_token, subscription_product_id, created_at, updated_at)
                 VALUES (?, ?, ?, ?, ?, NOW(), NOW())
                 ON DUPLICATE KEY UPDATE
                   is_premium = VALUES(is_premium),
                   premium_expiry = VALUES(premium_expiry),
                   subscription_token = VALUES(subscription_token),
                   subscription_product_id = VALUES(subscription_product_id),
                   updated_at = NOW()'
            );
            $st->execute([$uid, $isPremium ? 1 : 0, $premiumExpiry, $purchaseToken, $productId]);
        } else {
            $st = db()->prepare(
                'INSERT INTO users (uid, is_premium, premium_expiry, created_at, updated_at)
                 VALUES (?, ?, ?, NOW(), NOW())
                 ON DUPLICATE KEY UPDATE
                   is_premium = VALUES(is_premium),
                   premium_expiry = VALUES(premium_expiry),
                   updated_at = NOW()'
            );
            $st->execute([$uid, $isPremium ? 1 : 0, $premiumExpiry]);
        }

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
 * Pastikan kolom subscription_* ada di tabel users (migrasi mandiri).
 * Aman dipanggil berulang: setiap kolom ditambah hanya jika belum ada.
 * Tidak melempar exception apa pun — kegagalan migrasi dicegat sehingga
 * request (verifikasi pembelian / pembatalan) TIDAK pernah berhenti.
 */
function ensure_premium_columns(): bool
{
    $colExists = static function (string $col): bool {
        try {
            $st = db()->prepare(
                "SELECT COUNT(*) FROM information_schema.COLUMNS
                 WHERE TABLE_SCHEMA = DATABASE()
                   AND TABLE_NAME = 'users'
                   AND COLUMN_NAME = ?"
            );
            $st->execute([$col]);
            return (int)$st->fetchColumn() > 0;
        } catch (Throwable $e) {
            error_log('premium.php column check failed: ' . $e->getMessage());
            return false;
        }
    };

    try {
        if (!$colExists('subscription_token')) {
            db()->exec('ALTER TABLE users ADD COLUMN subscription_token VARCHAR(512) NULL');
        }
    } catch (Throwable $e) {
        error_log('premium.php migrate subscription_token failed: ' . $e->getMessage());
    }

    try {
        if (!$colExists('subscription_product_id')) {
            db()->exec('ALTER TABLE users ADD COLUMN subscription_product_id VARCHAR(255) NULL');
        }
    } catch (Throwable $e) {
        error_log('premium.php migrate subscription_product_id failed: ' . $e->getMessage());
    }

    return $colExists('subscription_token') && $colExists('subscription_product_id');
}

/**
 * Jalankan pembatalan langganan untuk $uid lalu kirim respons JSON dan exit.
 *
 * Idempoten: bila tidak ada token tersimpan (sudah batal / pembelian
 * manual via Play Store / user belum pernah verifikasi), status premium
 * lokal tetap dicabut dan respons ok:true — agar klien tidak terjebak
 * dalam status premium yang tidak bisa dibatalkan.
 */
function handle_cancel_subscription(string $uid): void
{
    if (!ensure_premium_columns()) {
        fail('Subscription data not migrated yet', 400);
    }
    $st = db()->prepare(
        'SELECT subscription_token, subscription_product_id, premium_expiry FROM users WHERE uid = ?'
    );
    $st->execute([$uid]);
    $row = $st->fetch();
    if (!$row) {
        // User belum ada di DB — tidak ada yang perlu dibatalkan.
        json_response([
            'ok' => true,
            'data' => ['is_premium' => false, 'premium_expiry' => null],
        ]);
    }
    $token = trim((string)($row['subscription_token'] ?? ''));
    $productId = trim((string)($row['subscription_product_id'] ?? ''));
    $expiryRaw = (string)($row['premium_expiry'] ?? '');
    $expiryTs = $expiryRaw !== '' ? strtotime($expiryRaw) : 0;

    // Langganan sudah kedaluwarsa: tidak ada yang perlu dibatalkan ke Play
    // (Play akan menolak cancel untuk sub yang sudah expired) — cabut flag
    // lokal langsung tanpa memanggil Google sama sekali.
    if ($expiryTs > 0 && $expiryTs <= time()) {
        clear_premium_local($uid);
        json_response([
            'ok' => true,
            'data' => ['is_premium' => false, 'premium_expiry' => null],
        ]);
    }

    if ($token === '' || $productId === '') {
        // Tidak ada token Play yang bisa dibatalkan (mis. premium dari
        // fallback offline / pembelian langsung di Play Store).
        // Cabut flag lokal saja; instruksikan user kelola via Play Store.
        clear_premium_local($uid);
        json_response([
            'ok' => true,
            'data' => ['is_premium' => false, 'premium_expiry' => null],
        ]);
    }

    $cancelResult = google_play_cancel_subscription($productId, $token);
    if (!$cancelResult['ok']) {
        $err = $cancelResult['error'] ?? 'Cancel failed';
        // Bedakan mis-konfigurasi server (501) dari kegagalan Play API (502)
        // agar klien/log tidak menebak-nebak.
        // (strpos, bukan str_starts_with, agar kompatibel PHP 7.x juga.)
        if (strpos($err, 'Server not configured') === 0) {
            fail($err . ' — upload service account ke server (lihat config.php)', 501);
        }
        // Langganan sudah tidak ada/kedaluwarsa di sisi Play (user
        // membatalkan via Play Store / masa berlaku habis): anggap sukses
        // dan cabut flag lokal agar user tidak terjebak status premium.
        if (preg_match('/expir|already cancel|cancelled|not found|no longer|404|410/i', $err)) {
            clear_premium_local($uid);
            json_response([
                'ok' => true,
                'data' => ['is_premium' => false, 'premium_expiry' => null],
            ]);
        }
        fail($err, 502);
    }

    clear_premium_local($uid);

    json_response([
        'ok' => true,
        'data' => ['is_premium' => false, 'premium_expiry' => null],
    ]);
}

/** Cabut flag premium user tanpa menyentuh Play API. */
function clear_premium_local(string $uid): void
{
    $st = db()->prepare(
        'UPDATE users
         SET is_premium = 0, premium_expiry = NULL,
             subscription_token = NULL, subscription_product_id = NULL,
             updated_at = NOW()
         WHERE uid = ?'
    );
    $st->execute([$uid]);
}

/**
 * Batalkan langganan via Play Developer API (v3 subscriptions.cancel).
 * Mengembalikan ['ok' => true] atau ['ok' => false, 'error' => string].
 */
function google_play_cancel_subscription(string $productId, string $purchaseToken): array
{
    $package = defined('GOOGLE_PLAY_PACKAGE') ? GOOGLE_PLAY_PACKAGE : '';
    $credFile = defined('GOOGLE_SERVICE_ACCOUNT_FILE') ? GOOGLE_SERVICE_ACCOUNT_FILE : '';
    if ($package === '' || $credFile === '' || !is_file($credFile)) {
        return ['ok' => false, 'error' => 'Server not configured for billing'];
    }

    $accessToken = google_service_account_token($credFile);
    if ($accessToken === null) {
        return ['ok' => false, 'error' => 'Failed to obtain Google access token'];
    }

    // URL sesuai dokumentasi purchases.subscriptions.cancel:
    // POST .../applications/{packageName}/purchases/subscriptions/{subscriptionId}/tokens/{token}:cancel
    // Body USER_REQUESTED_STOP_RENEWALS agar berperilaku seperti user
    // membatalkan via Play Store (masih bisa restore/resubscribe).
    $url = 'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/'
        . rawurlencode($package)
        . '/purchases/subscriptions/'
        . rawurlencode($productId)
        . '/tokens/'
        . rawurlencode($purchaseToken)
        . ':cancel';

    [$status, $body] = curl_request_raw('POST', $url, [
        'Authorization: Bearer ' . $accessToken,
        'Accept: application/json',
        'Content-Type: application/json',
    ], '{"cancellationType":"USER_REQUESTED_STOP_RENEWALS"}', 10);

    if ($status < 200 || $status >= 300) {
        $detail = trim(preg_replace('/\s+/', ' ', $body));
        if (strlen($detail) > 200) $detail = substr($detail, 0, 200) . '…';
        $suffix = $detail !== '' ? ' ' . $detail : '';
        return ['ok' => false, 'error' => 'Play API error ' . $status . $suffix];
    }
    return ['ok' => true];
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

    // subscriptionState (v3 API): SUBSCRIPTION_STATE_ACTIVE = pembayaran diterima
    // dan langganan aktif. Nilai lama 'SUBSCRIBED' TIDAK dipakai API v3.
    $state = $json['subscriptionState'] ?? '';
    if ($state !== 'SUBSCRIPTION_STATE_ACTIVE') {
        return ['ok' => false, 'error' => 'Subscription not active (' . $state . ')'];
    }

    // Pastikan token milik produk yang diminta
    $lineItem = $json['lineItems'][0] ?? [];
    $apiProductId = $lineItem['productId'] ?? '';
    if ($apiProductId !== '' && $apiProductId !== $productId) {
        return ['ok' => false, 'error' => 'Product mismatch'];
    }

    // expiryTime ada di dalam lineItems[0], berupa epoch milidetik (int64 string)
    // atau ISO 8601 — tangani keduanya.
    $expiryRaw = $lineItem['expiryTime'] ?? '';
    $expiryTs = 0;
    if ($expiryRaw !== '') {
        $expiryTs = is_numeric($expiryRaw)
            ? (int)round((float)$expiryRaw / 1000)
            : (int)strtotime($expiryRaw);
    }
    if ($expiryTs <= 0) {
        return ['ok' => false, 'error' => 'Missing or invalid expiryTime'];
    }

    return [
        'ok' => true,
        'is_premium' => true,
        'premium_expiry' => date('Y-m-d H:i:s', $expiryTs),
    ];
}

/**
 * Ambil OAuth2 access token dari service account (JWT RS256, tanpa Composer).
 * Kredensial dibaca dari file JSON di server — JANGAN commit ke repo.
 * $error diisi pesan ringkas saat gagal (untuk diagnostik).
 */
function google_service_account_token(string $credFile, ?string &$error = null): ?string
{
    $raw = @file_get_contents($credFile);
    if ($raw === false) {
        $error = 'service account file tidak terbaca';
        return null;
    }
    $cred = json_decode($raw, true);
    if (!is_array($cred) || empty($cred['client_email']) || empty($cred['private_key'])) {
        $error = 'service account JSON tidak valid (client_email/private_key hilang)';
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
    if ($key === false) {
        $error = 'private_key service account tidak valid (openssl)';
        return null;
    }
    if (!openssl_sign($header . '.' . $claims, $signature, $key, OPENSSL_ALGO_SHA256)) {
        $error = 'openssl_sign gagal';
        return null;
    }
    $jwt = $header . '.' . $claims . '.' . base64url_encode($signature);

    $payload = 'grant_type=' . rawurlencode('urn:ietf:params:oauth:grant-type:jwt-bearer')
        . '&assertion=' . rawurlencode($jwt);

    $json = curl_post_json('https://oauth2.googleapis.com/token', $payload);
    if (empty($json['access_token'])) {
        $detail = substr(trim(preg_replace('/\s+/', ' ', json_encode($json))), 0, 160);
        $error = 'token exchange ditolak Google: ' . $detail;
        return null;
    }
    return $json['access_token'];
}

function google_http_get(string $url, string $accessToken): array
{
    [$status, $body] = curl_request_raw('GET', $url, [
        'Authorization: Bearer ' . $accessToken,
        'Accept: application/json',
    ]);
    return ['status' => $status, 'body' => $body];
}

/**
 * POST form-encoded pakai cURL (server ini allow_url_fopen=0, jadi
 * file_get_contents() tidak bisa untuk URL).
 */
function curl_post_json(string $url, string $body): array
{
    [$status, $raw] = curl_request_raw('POST', $url, [
        'Content-Type: application/x-www-form-urlencoded',
    ], $body);
    return json_decode($raw === '' ? '[]' : $raw, true) ?: [];
}

/** Request HTTP via cURL → [status, body]. */
function curl_request_raw(string $method, string $url, array $headers = [], string $body = '', int $timeout = 15): array
{
    if (!function_exists('curl_init')) {
        return [0, 'cURL not available'];
    }
    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_CUSTOMREQUEST => $method,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => $timeout,
        CURLOPT_SSL_VERIFYPEER => true,
        CURLOPT_SSL_VERIFYHOST => 2,
        CURLOPT_HTTPHEADER => $headers,
    ]);
    if ($body !== '') {
        curl_setopt($ch, CURLOPT_POSTFIELDS, $body);
    }
    $raw = curl_exec($ch);
    $errno = curl_errno($ch);
    $status = (int)curl_getinfo($ch, CURLINFO_RESPONSE_CODE);
    curl_close($ch);

    if ($raw === false) {
        return [$status, 'cURL error ' . $errno . ': ' . curl_strerror($errno)];
    }
    return [$status, $raw];
}

function base64url_encode(string $data): string
{
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}
