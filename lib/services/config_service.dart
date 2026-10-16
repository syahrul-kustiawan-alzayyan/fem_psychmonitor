import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._();
  factory ConfigService() => _instance;
  ConfigService._();

  static Future<void> load() => dotenv.load();

  // Google Play Billing - Subscription product IDs
  static String get billingProductWeekly => _get('BILLING_PRODUCT_WEEKLY');
  static String get billingProductMonthly => _get('BILLING_PRODUCT_MONTHLY');
  static String get billingProductYearly => _get('BILLING_PRODUCT_YEARLY');

  // AdMob Production IDs
  static String get admobBannerTop => _get('ADMOB_BANNER_TOP');
  static String get admobBannerBottom => _get('ADMOB_BANNER_BOTTOM');
  static String get admobInterstitial => _get('ADMOB_INTERSTITIAL');
  static String get admobAppOpen => _get('ADMOB_OPENAPP');
  static String get admobRewarded => _get('ADMOB_REWARDED');
  static String get admobAppId => _get('ADMOB_APP_ID');

  // Google Sign-In
  static String get googleServerClientId => _get('GOOGLE_SERVER_CLIENT_ID');

  // Backend cPanel (API PHP + MySQL)
  static String get apiBaseUrl => _get('API_BASE_URL');
  static String get apiKey => _get('API_KEY');

  // Server inferensi SER lokal (FastAPI, assets/model_deploy/server_ssl.py)
  // Lokal: http://127.0.0.1:8001 (desktop) atau http://10.0.2.2:8001 (emulator).
  // Perangkat fisik: ganti dengan IP LAN laptop, mis. http://192.168.1.5:8001.
  static String get serBaseUrl => _get('SER_BASE_URL');

  // App
  static String get appPackageName {
    final v = _get('APP_PACKAGE_NAME');
    return v.isNotEmpty ? v : 'com.fempsychmonitor';
  }

  // Admin
  static String get adminEmail => _get('ADMIN_EMAIL');
  static String get adminPassword => _get('ADMIN_PASSWORD');

  static String _get(String key) {
    return dotenv.env[key] ?? '';
  }
}
