import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._();
  factory ConfigService() => _instance;
  ConfigService._();

  static Future<void> load() => dotenv.load();

  // RevenueCat
  static String get revenueCatApiKey => _get('REVENUECAT_API_KEY');

  // AdMob Production IDs
  static String get admobBannerTop => _get('ADMOB_BANNER_TOP');
  static String get admobBannerBottom => _get('ADMOB_BANNER_BOTTOM');
  static String get admobInterstitial => _get('ADMOB_INTERSTITIAL');
  static String get admobAppOpen => _get('ADMOB_OPENAPP');
  static String get admobRewarded => _get('ADMOB_REWARDED');
  static String get admobAppId => _get('ADMOB_APP_ID');

  // Google Sign-In
  static String get googleServerClientId => _get('GOOGLE_SERVER_CLIENT_ID');

  // Gemini AI
  static String get geminiApiKey => _get('GEMINI_API_KEY');

  // Firebase
  static String get firebaseApiKey => _get('FIREBASE_API_KEY');
  static String get firebaseProjectId => _get('FIREBASE_PROJECT_ID');

  // Admin
  static String get adminEmail => _get('ADMIN_EMAIL');
  static String get adminPassword => _get('ADMIN_PASSWORD');

  static String _get(String key) {
    return dotenv.env[key] ?? '';
  }
}
