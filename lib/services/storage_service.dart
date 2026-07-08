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

  // ── Daily Detection Limit ─────────────────────────────────────
  static const String _keyDetectDate = 'detection_date';
  static const String _keyDetectCount = 'detection_count';

  /// Sisa deteksi gratis hari ini (max 5)
  static Future<int> getRemainingDetections() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();
    final savedDate = prefs.getString(_keyDetectDate) ?? '';
    if (savedDate != today) return 5;
    final count = prefs.getInt(_keyDetectCount) ?? 0;
    return (5 - count).clamp(0, 5);
  }

  /// Tambah 1 hitungan deteksi hari ini
  static Future<void> incrementDetectionCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();
    final savedDate = prefs.getString(_keyDetectDate) ?? '';
    if (savedDate != today) {
      await prefs.setString(_keyDetectDate, today);
      await prefs.setInt(_keyDetectCount, 1);
    } else {
      final count = (prefs.getInt(_keyDetectCount) ?? 0) + 1;
      await prefs.setInt(_keyDetectCount, count);
    }
  }

  static String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
