import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';

/// Provider mock untuk autentikasi pengguna.
/// Saat ini menyimpan state login di SharedPreferences.
/// Akan diganti dengan Firebase Authentication di sesi berikutnya.
class AuthProvider extends ChangeNotifier {
  static const String _keyIsLoggedIn = 'auth_is_logged_in';
  static const String _keyEmail = 'auth_email';
  static const String _keyUsername = 'auth_username';

  bool _isLoggedIn = false;
  String _email = '';
  String _username = '';

  bool get isLoggedIn => _isLoggedIn;
  String get email => _email;
  String get username => _username;

  /// Inisialisasi — panggil sebelum runApp
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    _email = prefs.getString(_keyEmail) ?? '';
    _username = prefs.getString(_keyUsername) ?? '';
    
    // Sync missing username from onboarding info
    if (_username.isEmpty) {
      _username = prefs.getString('username') ?? '';
      if (_username.isNotEmpty) {
        await prefs.setString(_keyUsername, _username);
      }
    }
    notifyListeners();
  }

  /// Mock login — cek dan simpan state ke SharedPreferences
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Validasi apakah akun sudah terdaftar dan password benar
    final savedPassword = prefs.getString('mock_pwd_$email');
    if (savedPassword == null || savedPassword != password) {
      return false; // Email belum terdaftar atau password salah
    }

    final savedUsername = prefs.getString('mock_usr_$email') ?? email.split('@').first;

    _isLoggedIn = true;
    _email = email;
    _username = savedUsername;
    
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyUsername, savedUsername);
    
    // Link onboarding records safely
    int? pendingId = prefs.getInt('pending_onboarding_user_id');
    if (pendingId != null) {
      try {
        await DatabaseService.updateUserEmail(pendingId, email);
        await prefs.remove('pending_onboarding_user_id');
      } catch (_) {}
    }
    
    notifyListeners();
    return true;
  }

  /// Mock register — daftar dan simpan ke SharedPreferences
  Future<bool> register({
    required String email,
    required String password,
    required String username,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Cek apakah email sudah pernah didaftarkan
    if (prefs.containsKey('mock_pwd_$email')) {
      return false; // Email sudah terdaftar
    }

    await prefs.setString('mock_pwd_$email', password);
    await prefs.setString('mock_usr_$email', username);
    
    return await login(email: email, password: password);
  }

  /// Logout — hapus state login
  Future<void> logout() async {
    _isLoggedIn = false;
    _email = '';
    _username = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyUsername);
    notifyListeners();
  }

  /// Update profil
  Future<void> updateProfile({String? email, String? username}) async {
    if (email != null) _email = email;
    if (username != null) _username = username;
    final prefs = await SharedPreferences.getInstance();
    if (email != null) await prefs.setString(_keyEmail, email);
    if (username != null) await prefs.setString(_keyUsername, username);
    notifyListeners();
  }
}
