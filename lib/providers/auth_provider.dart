import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// Mock login — simpan state ke SharedPreferences
  Future<void> login({
    required String email,
    required String username,
  }) async {
    _isLoggedIn = true;
    _email = email;
    _username = username;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyUsername, username);
    notifyListeners();
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
