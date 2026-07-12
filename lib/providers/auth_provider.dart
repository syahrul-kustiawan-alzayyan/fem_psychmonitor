import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/config_service.dart';
import '../screens/onboarding_screen.dart';

/// Provider autentikasi menggunakan Firebase Authentication.
/// Mendukung Email/Password (dengan verifikasi email) dan Google Sign-In.
class AuthProvider extends ChangeNotifier {
  static const String _keyUsername = 'auth_username';
  static const String _keyEmail = 'auth_email';

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
      await prefs.setString(_keyEmail, _email);
    } else {
      _isLoggedIn = false;
      _email = '';
      _username = '';
    }

    // Listen to auth state changes ONLY for sign out events.
    // Let login() and register() explicitly handle sign in.
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        _isLoggedIn = false;
        _email = '';
        _username = '';
        notifyListeners();
      }
    });

    notifyListeners();
  }

  /// Login atau auto-register jika email belum terdaftar.
  /// Returns:
  ///   'success' — login berhasil, email sudah diverifikasi
  ///   'new_user' — user baru (perlu onboarding), email sudah diverifikasi
  ///   'verification_sent' — akun baru dibuat, email verifikasi terkirim
  ///   'email_not_verified' — email sudah terdaftar tapi belum diverifikasi
  ///   'error' — gagal
  Future<String> loginOrRegister({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential;
      bool isNewUser = false;

      try {
        credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException {
        try {
          credential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          isNewUser = true;
        } on FirebaseAuthException catch (e2) {
          if (e2.code == 'email-already-in-use') {
            // ignore: deprecated_member_use
            final methods = await _auth.fetchSignInMethodsForEmail(email);
            if (methods.contains('google.com')) {
              return 'google_account';
            }
            return 'email_already_in_use';
          }
          rethrow;
        }
      }

      if (credential.user == null) return 'error';

      // Kirim email verifikasi untuk user baru
      if (isNewUser) {
        final username = email.split('@').first;
        await credential.user!.updateDisplayName(username);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyUsername, username);
        final actionCodeSettings = ActionCodeSettings(
          url: 'https://fem-psychmonitor.firebaseapp.com/__/auth/action',
          handleCodeInApp: true,
          iOSBundleId: 'com.fempsychmonitor',
          androidPackageName: 'com.fempsychmonitor',
          androidInstallApp: true,
          androidMinimumVersion: '1',
        );
        await credential.user!.sendEmailVerification(actionCodeSettings);
        await _auth.signOut();
        return 'verification_sent';
      }

      // User existing — cek verifikasi email
      await credential.user!.reload();
      final refreshedUser = _auth.currentUser;
      if (refreshedUser != null && !refreshedUser.emailVerified) {
        await _auth.signOut();
        return 'email_not_verified';
      }

      // Email sudah diverifikasi — login sukses
      _isLoggedIn = true;
      _email = credential.user!.email ?? email;
      final appUser = await DatabaseService.getUser();
      _username = appUser?.name ?? credential.user!.displayName ?? email.split('@').first;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUsername, _username);
      await prefs.setString(_keyEmail, _email);

      final hasPending = prefs.getBool('pending_onboarding_data') ?? false;

      if (appUser == null && !hasPending) {
        final minimalUser = AppUser(
          name: _username,
          mbtiType: '',
          mbtiScores: {},
          bigFiveScores: {},
          createdAt: DateTime.now(),
        );
        await DatabaseService.insertUser(minimalUser);
        notifyListeners();
        return 'new_user';
      }

      if (hasPending) {
        try {
          await OnboardingScreen.savePendingOnboardingToFirestore();
        } catch (_) {}
        notifyListeners();
        return 'success';
      }

      if (appUser!.bigFiveScores.isEmpty) {
        if (hasPending) {
          try {
            await OnboardingScreen.savePendingOnboardingToFirestore();
          } catch (_) {}
          notifyListeners();
          return 'success';
        }
        notifyListeners();
        return 'new_user';
      }

      notifyListeners();
      return 'success';
    } on FirebaseAuthException catch (e) {
      debugPrint('Login/Register error: ${e.code} - ${e.message}');
      return e.code;
    } catch (e) {
      debugPrint('Login/Register error: $e');
      return 'error';
    }
  }

  /// Kirim ulang email verifikasi
  Future<bool> resendVerificationEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        final actionCodeSettings = ActionCodeSettings(
          url: 'https://fem-psychmonitor.firebaseapp.com/__/auth/action',
          handleCodeInApp: true,
          iOSBundleId: 'com.fempsychmonitor',
          androidPackageName: 'com.fempsychmonitor',
          androidInstallApp: true,
          androidMinimumVersion: '1',
        );
        await credential.user!.sendEmailVerification(actionCodeSettings);
        await _auth.signOut();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Resend verification error: $e');
      return false;
    }
  }

  /// Cek apakah email sudah diverifikasi (tanpa register ulang)
  Future<bool> checkEmailVerified(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final verified = credential.user?.emailVerified ?? false;
      if (!verified) {
        await _auth.signOut();
      }
      return verified;
    } catch (e) {
      debugPrint('Check email verified error: $e');
      return false;
    }
  }

  /// Kirim email reset password
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      debugPrint('Reset password error: $e');
      return false;
    }
  }

  /// Sign in dengan Google (menggunakan google_sign_in v7+ API)
  /// Firebase otomatis membuat akun baru jika email belum terdaftar.
  /// Returns:
  ///   'success' — berhasil login (user lama)
  ///   'new_user' — user baru, perlu onboarding
  ///   'cancelled' — user membatalkan Google picker
  ///   'error' — gagal
  Future<String> signInWithGoogle({bool isLogin = false}) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: ConfigService.googleServerClientId,
      );
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      // User membatalkan proses
      if (googleUser == null) return 'cancelled';

      // Dapatkan idToken dari authentication
      final auth = await googleUser.authentication;
      final idToken = auth.idToken;

      // Buat credential untuk Firebase (hanya butuh idToken)
      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

      // Sign in ke Firebase dengan credential Google
      // Firebase otomatis membuat akun jika belum ada (register otomatis)
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        _isLoggedIn = true;
        _email = userCredential.user!.email ?? '';
        _username = userCredential.user!.displayName ?? _email.split('@').first;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyUsername, _username);
        await prefs.setString(_keyEmail, _email);

        // Cek apakah user baru (pertama kali login dengan Google)
        final isNewUser =
            userCredential.additionalUserInfo?.isNewUser ?? false;

        // Cek pending onboarding data (dari first-launch flow)
        final hasPending = prefs.getBool('pending_onboarding_data') ?? false;

        if (isNewUser) {
          if (hasPending) {
            // User sudah mengisi onboarding sebelum login — sync ke Firestore
            await OnboardingScreen.savePendingOnboardingToFirestore();
            notifyListeners();
            return 'success';
          }
          // User baru tanpa data pending — buat record minimal
          final minimalUser = AppUser(
            name: _username,
            mbtiType: '',
            mbtiScores: {},
            bigFiveScores: {},
            createdAt: DateTime.now(),
          );
          await DatabaseService.insertUser(minimalUser);
          notifyListeners();
          return 'new_user';
        }

        // User lama — cek apakah sudah punya data onboarding
        final existingUser = await DatabaseService.getUser();
        if (existingUser == null || existingUser.bigFiveScores.isEmpty) {
          if (hasPending) {
            // Ada data pending yang belum tersimpan — sync dulu
            await OnboardingScreen.savePendingOnboardingToFirestore();
            notifyListeners();
            return 'success';
          }
          return 'new_user';
        }

        // User lama dengan data lengkap — sync pending jika ada
        if (hasPending) {
          try {
            await OnboardingScreen.savePendingOnboardingToFirestore();
          } catch (_) {}
        }

        notifyListeners();
        return 'success';
      }
      return 'error';
    } on FirebaseAuthException catch (e) {
      debugPrint('Google Sign-In Firebase error: ${e.code} - ${e.message}');
      return 'error';
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return 'error';
    }
  }

  /// Logout — sign out dari Firebase Auth + Google
  Future<void> logout() async {
    // Sign out dari Google juga
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.disconnect();
    } catch (_) {}

    await _auth.signOut();
    _isLoggedIn = false;
    _email = '';
    _username = '';

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyEmail);

    DatabaseService.resetInstance();
    notifyListeners();
  }

  /// Hapus akun dari Firebase Auth
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      }
    } catch (e) {
      debugPrint('Delete account error: $e');
      // Bila gagal (misal butuh re-authenticate), kita tetap lanjutkan hapus lokal
    }
    await logout();
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
