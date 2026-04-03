import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// StorageService — SharedPreferences (hanya untuk flag onboarding)
//
// Data user dan recording sekarang disimpan di SQLite (DatabaseService).
// StorageService hanya menghandle flag sederhana.
// ─────────────────────────────────────────────────────────────────────────────
class StorageService {
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keyUserName = 'user_name';

  /// Cek apakah ini peluncuran pertama
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFirstLaunch) ?? true;
  }

  /// Tandai onboarding selesai
  static Future<void> setOnboardingComplete(String userName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstLaunch, false);
    await prefs.setString(_keyUserName, userName);
  }

  /// Ambil nama user (untuk keperluan cepat tanpa query DB)
  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName) ?? 'User';
  }

  /// Reset onboarding (untuk testing)
  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFirstLaunch);
    await prefs.remove(_keyUserName);
  }
}
