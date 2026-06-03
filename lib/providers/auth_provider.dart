import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
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

  /// Login menggunakan Firebase Auth.
  /// Returns:
  ///   'success' — login berhasil dan email sudah diverifikasi
  ///   'email_not_verified' — login berhasil tapi email belum diverifikasi
  ///   'error' — gagal login (credential salah, dll)
  Future<String> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Cek apakah email sudah diverifikasi
        // Reload user data untuk mendapat status terbaru
        await credential.user!.reload();
        final refreshedUser = _auth.currentUser;

        if (refreshedUser != null && !refreshedUser.emailVerified) {
          // Email belum diverifikasi — sign out dan kembalikan status
          await _auth.signOut();
          return 'email_not_verified';
        }

        _isLoggedIn = true;
        _email = credential.user!.email ?? email;

        // Ambil username dari Firestore jika ada
        final appUser = await DatabaseService.getUser();
        _username = appUser?.name ?? credential.user!.displayName ?? email.split('@').first;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyUsername, _username);
        await prefs.setString(_keyEmail, _email);

        // Link onboarding records safely
        final hasPending = prefs.getBool('pending_onboarding_data') ?? false;
        if (hasPending) {
          try {
            await OnboardingScreen.savePendingOnboardingToFirestore();
          } catch (_) {}
        }

        notifyListeners();

        if (appUser == null && !hasPending) {
          return 'new_user';
        }

        return 'success';
      }
      return 'error';
    } on FirebaseAuthException catch (e) {
      debugPrint('Login error: ${e.code} - ${e.message}');
      return e.code;
    } catch (e) {
      debugPrint('Login error: $e');
      return 'error';
    }
  }

  /// Register menggunakan Firebase Auth + kirim email verifikasi.
  /// Returns:
  ///   'success' — akun berhasil dibuat, email verifikasi terkirim
  ///   'email_exists' — email sudah terdaftar
  ///   'error' — gagal
  Future<String> register({
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

        // Kirim email verifikasi
        await credential.user!.sendEmailVerification();

        // Simpan username lokal
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyUsername, username);

        _username = username;

        // Sign out setelah register karena email belum diverifikasi
        await _auth.signOut();
        _isLoggedIn = false;

        notifyListeners();
        return 'success';
      }
      return 'error';
    } on FirebaseAuthException catch (e) {
      debugPrint('Register error: ${e.code} - ${e.message}');
      if (e.code == 'email-already-in-use') {
        return 'email_exists';
      }
      return e.code;
    } catch (e) {
      debugPrint('Register error: $e');
      return 'error';
    }
  }

  /// Kirim ulang email verifikasi
  Future<bool> resendVerificationEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Login sementara untuk kirim ulang email
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        await credential.user!.sendEmailVerification();
        await _auth.signOut();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Resend verification error: $e');
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
        serverClientId: '637727281592-5lk5ga4di62olc97u47g56ohfe1m44dh.apps.googleusercontent.com',
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

        if (isLogin && isNewUser) {
          // Jika login tapi email ini belum pernah terdaftar,
          // hapus akun Google yang baru saja dibuat di Firebase Auth
          await userCredential.user?.delete();
          await logout();
          return 'unregistered_google';
        }

        if (isNewUser) {
          // User baru via Google (hanya di tab register) — perlu onboarding
          notifyListeners();
          return 'new_user';
        }

        // User lama — cek dan sync pending onboarding data
        final hasPending = prefs.getBool('pending_onboarding_data') ?? false;
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
