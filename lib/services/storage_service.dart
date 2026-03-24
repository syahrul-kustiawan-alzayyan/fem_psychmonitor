import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

/// Service untuk menyimpan & mengambil data pengguna menggunakan SharedPreferences.
/// Semua operasi bersifat async.
class StorageService {
  // Keys untuk SharedPreferences
  static const String _keyOnboardingDone = 'onboarding_done';
  static const String _keyUsername = 'username';
  static const String _keyPsychScore = 'psych_score';
  static const String _keyCreatedAt = 'created_at';

  /// Apakah user sudah melewati onboarding?
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_keyOnboardingDone) ?? false);
  }

  /// Simpan data user setelah onboarding selesai
  static Future<void> saveUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, user.name);
    await prefs.setInt(_keyPsychScore, user.psychScore);
    await prefs.setString(
      _keyCreatedAt,
      user.createdAt.toIso8601String(),
    );
    await prefs.setBool(_keyOnboardingDone, true);
  }

  /// Ambil data user yang tersimpan (null jika belum ada)
  static Future<AppUser?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyUsername);
    final score = prefs.getInt(_keyPsychScore);
    final createdStr = prefs.getString(_keyCreatedAt);

    if (name == null || score == null) return null;

    return AppUser(
      name: name,
      psychScore: score,
      createdAt: createdStr != null
          ? DateTime.parse(createdStr)
          : DateTime.now(),
    );
  }

  /// Hapus semua data (untuk keperluan reset / testing)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
