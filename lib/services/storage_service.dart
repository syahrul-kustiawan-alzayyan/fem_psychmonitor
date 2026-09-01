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

  // ── Daily Detection Limit (per-akun) ──────────────────────────
  /// Batas deteksi gratis per hari.
  static const int maxFreeDetections = 5;
  static String _detectDateKey(String uid) => 'detection_date_$uid';
  static String _detectCountKey(String uid) => 'detection_count_$uid';

  /// Sisa deteksi gratis hari ini (per-akun)
  static Future<int> getRemainingDetections(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();
    final savedDate = prefs.getString(_detectDateKey(uid)) ?? '';
    if (savedDate != today) return maxFreeDetections;
    final count = prefs.getInt(_detectCountKey(uid)) ?? 0;
    return (maxFreeDetections - count).clamp(0, maxFreeDetections);
  }

  /// Tambah 1 hitungan deteksi hari ini (per-akun)
  static Future<void> incrementDetectionCount(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();
    final savedDate = prefs.getString(_detectDateKey(uid)) ?? '';
    if (savedDate != today) {
      await prefs.setString(_detectDateKey(uid), today);
      await prefs.setInt(_detectCountKey(uid), 1);
    } else {
      final count = (prefs.getInt(_detectCountKey(uid)) ?? 0) + 1;
      await prefs.setInt(_detectCountKey(uid), count);
    }
  }

  static String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
