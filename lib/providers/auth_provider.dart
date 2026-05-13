import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../screens/onboarding_screen.dart';

/// Provider autentikasi menggunakan Firebase Authentication.
/// Menggantikan mock auth yang sebelumnya menyimpan di SharedPreferences.
class AuthProvider extends ChangeNotifier {
  static const String _keyUsername = 'auth_username';

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoggedIn = false;
  String _email = '';
  String _username = '';

  bool get isLoggedIn => _isLoggedIn;
  String get email => _email;
  String get username => _username;

  /// Inisialisasi — panggil sebelum runApp
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Cek apakah ada user yang sedang login di Firebase
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      _isLoggedIn = true;
      _email = currentUser.email ?? '';
      _username = prefs.getString(_keyUsername) ?? currentUser.displayName ?? currentUser.email?.split('@').first ?? 'User';
    } else {
      _isLoggedIn = false;
      _email = '';
      _username = '';
    }

    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _isLoggedIn = true;
        _email = user.email ?? '';
        if (_username.isEmpty) {
          _username = user.displayName ?? user.email?.split('@').first ?? 'User';
        }
      } else {
        _isLoggedIn = false;
        _email = '';
        _username = '';
      }
      notifyListeners();
    });

    notifyListeners();
  }

  /// Login menggunakan Firebase Auth
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        _isLoggedIn = true;
        _email = credential.user!.email ?? email;

        // Ambil username dari Firestore jika ada
        final appUser = await DatabaseService.getUser();
        _username = appUser?.name ?? credential.user!.displayName ?? email.split('@').first;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyUsername, _username);

        // Link onboarding records safely
        final hasPending = prefs.getBool('pending_onboarding_data') ?? false;
        if (hasPending) {
          try {
            await OnboardingScreen.savePendingOnboardingToFirestore();
          } catch (_) {}
        }

        notifyListeners();
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint('Login error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  /// Register menggunakan Firebase Auth
  Future<bool> register({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update display name di Firebase Auth
        await credential.user!.updateDisplayName(username);

        _isLoggedIn = true;
        _email = credential.user!.email ?? email;
        _username = username;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyUsername, username);

        // Simpan data onboarding ke Firestore jika ada pending
        final hasPending = prefs.getBool('pending_onboarding_data') ?? false;
        if (hasPending) {
          try {
            await OnboardingScreen.savePendingOnboardingToFirestore();
          } catch (_) {}
        }

        notifyListeners();
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint('Register error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Register error: $e');
      return false;
    }
  }

  /// Logout — sign out dari Firebase Auth
  Future<void> logout() async {
    await _auth.signOut();
    _isLoggedIn = false;
    _email = '';
    _username = '';

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsername);

    DatabaseService.resetInstance();
    notifyListeners();
  }

  /// Update profil
  Future<void> updateProfile({String? email, String? username}) async {
    if (email != null) _email = email;
    if (username != null) {
      _username = username;
      // Update display name di Firebase Auth juga
      await _auth.currentUser?.updateDisplayName(username);
    }
    final prefs = await SharedPreferences.getInstance();
    if (username != null) await prefs.setString(_keyUsername, username);
    notifyListeners();
  }
}
