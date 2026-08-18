import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../providers/auth_provider.dart';
import '../providers/premium_provider.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../services/subscription_service.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/onboarding_screen.dart';
import '../theme/app_theme.dart';
import '../theme/resonance_colors.dart';

enum _AuthMode { login, register }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _confirm = TextEditingController();

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  _AuthMode _mode = _AuthMode.login;
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _acceptedPrivacy = false;

  bool get _isRegister => _mode == _AuthMode.register;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.15, 0.6, curve: Curves.elasticOut),
      ),
    );
    _logoOpacity = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.1, 0.5, curve: Curves.easeOut),
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    if (!mounted) return;

    final result = await context.read<AuthProvider>().loginOrRegister(
          email: _email.text.trim(),
          password: _password.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    await _handleAuthResult(result);
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    if (!mounted) return;

    final result = await context.read<AuthProvider>().loginOrRegister(
          email: _email.text.trim(),
          password: _password.text,
          name: _name.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    await _handleAuthResult(result);
  }

  Future<void> _handleAuthResult(String result) async {
    switch (result) {
      case 'success':
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await SubscriptionService()
              .identifyUser(uid, context.read<PremiumProvider>());
        }
        await StorageService.setOnboardingComplete('');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(AppLocalizations.tr('login_successful')),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppRouter()),
        );
        break;

      case 'admin':
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                const Text('Admin login successful'),
              ],
            ),
            backgroundColor: const Color(0xFF8B5CF6),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
        break;

      case 'new_user':
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await SubscriptionService()
              .identifyUser(uid, context.read<PremiumProvider>());
        }
        if (!mounted) return;
        _showOnboardingRequiredDialog();
        break;

      case 'verification_sent':
        _showVerificationSentDialog();
        break;

      case 'email_not_verified':
        _showEmailNotVerifiedDialog();
        break;

      case 'email_already_in_use':
        _showEmailExistsDialog();
        break;

      case 'google_account':
        _showGoogleAccountDialog();
        break;

      default:
        _showErrorDialog(result);
    }
  }

  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return AppLocalizations.tr('auth_email_required');
    if (!v.contains('@') || !v.contains('.')) {
      return AppLocalizations.tr('auth_email_invalid_format');
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return AppLocalizations.tr('auth_pass_required');
    if (v.length < 6) return AppLocalizations.tr('auth_pass_min_length');
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) {
      return AppLocalizations.tr('auth_confirm_required');
    }
    if (v != _password.text) return AppLocalizations.tr('auth_pass_mismatch');
    return null;
  }

  Future<void> _handleForgotPassword() async {
    final email = _email.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(''),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      );
      return;
    }
    final sent = await context.read<AuthProvider>().resetPassword(email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sent
              ? AppLocalizations.tr('auth_reset_sent')
              : AppLocalizations.tr('auth_reset_failed'),
        ),
        backgroundColor:
            sent ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    if (!mounted) return;

    final result =
        await context.read<AuthProvider>().signInWithGoogle(isLogin: true);

    if (!mounted) return;
    setState(() => _isLoading = false);

    switch (result) {
      case 'success':
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await SubscriptionService()
              .identifyUser(uid, context.read<PremiumProvider>());
        }
        await StorageService.setOnboardingComplete('');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(AppLocalizations.tr('login_successful')),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppRouter()),
        );
        break;

      case 'new_user':
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await SubscriptionService()
              .identifyUser(uid, context.read<PremiumProvider>());
        }
        if (!mounted) return;
        _showOnboardingRequiredDialog();
        break;

      case 'needs_password':
        _showSetPasswordDialog();
        break;

      case 'has_password':
        _showHasPasswordDialog();
        break;

      case 'cancelled':
        break;

      default:
        _showErrorDialog(result);
    }
  }

  Future<void> _showVerificationSentDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _VerificationDialog(
        email: _email.text.trim(),
        password: _password.text,
        onLogin: _handleLogin,
      ),
    );
  }

  void _showEmailNotVerifiedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface(ctx),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    const Color(0xFFD97706).withValues(alpha: 0.08),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.email_outlined,
                color: Color(0xFFF59E0B),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.tr('email_not_verified'),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textP(ctx),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.tr('email_not_verified_desc'),
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textS(ctx),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  final sent = await context
                      .read<AuthProvider>()
                      .resendVerificationEmail(
                        email: _email.text.trim(),
                        password: _password.text,
                      );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        sent
                            ? AppLocalizations.tr('verification_resent')
                            : AppLocalizations.tr('resend_failed'),
                      ),
                      backgroundColor:
                          sent ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  AppLocalizations.tr('resend_verification'),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _handleLogin();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text(
                AppLocalizations.tr('auth_already_verified'),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                AppLocalizations.tr('close'),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.textS(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmailExistsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface(ctx),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    const Color(0xFFD97706).withValues(alpha: 0.08),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mail_lock_rounded,
                color: Color(0xFFF59E0B),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.tr('auth_email_exists_title'),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textP(ctx),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.tr('auth_email_exists_desc').replaceAll(
                '{email}',
                _email.text.trim(),
              ),
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textS(ctx),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  final sent = await context
                      .read<AuthProvider>()
                      .resetPassword(_email.text.trim());
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        sent
                            ? AppLocalizations.tr('auth_reset_sent')
                            : AppLocalizations.tr('auth_reset_failed'),
                      ),
                      backgroundColor: sent
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.lock_reset_rounded, size: 18),
                label: Text(
                  AppLocalizations.tr('auth_reset_button'),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textP(ctx),
                  side: BorderSide(
                    color: AppTheme.surfVar(context),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  AppLocalizations.tr('try_again'),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGoogleAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface(ctx),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.15),
                    AppTheme.primaryDark.withValues(alpha: 0.08),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.login_rounded,
                color: Color(0xFFC77E8C),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.tr('auth_google_account_title'),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textP(ctx),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.tr('auth_google_account_desc'),
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textS(ctx),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  AppLocalizations.tr('close'),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String result) {
    final (title, message) = switch (result) {
      'email-already-in-use' => (
        AppLocalizations.tr('auth_email_exists_title'),
        AppLocalizations.tr('auth_err_email_in_use')
      ),
      'wrong-password' => (
        AppLocalizations.tr('auth_err_wrong_password_title'),
        AppLocalizations.tr('auth_err_wrong_password')
      ),
      'invalid-email' => (
        AppLocalizations.tr('auth_err_invalid_email_title'),
        AppLocalizations.tr('auth_err_invalid_email')
      ),
      'too-many-requests' => (
        AppLocalizations.tr('auth_err_too_many_title'),
        AppLocalizations.tr('auth_err_too_many')
      ),
      'network-request-failed' => (
        AppLocalizations.tr('auth_err_network_title'),
        AppLocalizations.tr('auth_err_network')
      ),
      'invalid-credential' => (
        AppLocalizations.tr('auth_err_invalid_credential_title'),
        AppLocalizations.tr('auth_err_invalid_credential')
      ),
      _ => (
        AppLocalizations.tr('auth_err_generic_title'),
        AppLocalizations.tr('auth_err_generic')
      ),
    };

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface(ctx),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFEF4444).withValues(alpha: 0.15),
                    const Color(0xFFDC2626).withValues(alpha: 0.08),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFEF4444),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textP(ctx),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textS(ctx),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  AppLocalizations.tr('close'),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOnboardingRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface(ctx),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.15),
                    AppTheme.primaryDark.withValues(alpha: 0.08),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_rounded,
                color: Color(0xFFC77E8C),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.tr('auth_onboarding_title'),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textP(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.tr('auth_onboarding_desc'),
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textS(context),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _navigateToOnboarding();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  AppLocalizations.tr('auth_onboarding_start'),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSetPasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _SetPasswordDialog(),
    );
  }

  void _showHasPasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface(ctx),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.15),
                    AppTheme.primaryDark.withValues(alpha: 0.08),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.email_rounded,
                color: Color(0xFFC77E8C),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.tr('auth_email_exists_title'),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textP(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.tr('auth_has_password_desc'),
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textS(context),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  AppLocalizations.tr('auth_login_with_password'),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (routeContext) => OnboardingScreen(
          onCompleted: () {
            Navigator.of(routeContext).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainNavigation()),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = ResonanceColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHero(c),
                  const SizedBox(height: 6),
                  _buildBrandName(c),
                  const SizedBox(height: 16),
                  _buildEyebrow(c),
                  const SizedBox(height: 10),
                  _buildTitle(c),
                  const SizedBox(height: 6),
                  _buildSubtitle(c),
                  const SizedBox(height: 16),
                  _buildWaveform(c),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Form(
                      key: _formKey,
                      child: _buildFormCard(c),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildFooter(c),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(ResonanceColors c) {
    return SizedBox(
      height: 130,
      child: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: ScaleTransition(
                scale: _logoScale,
                child: FadeTransition(
                  opacity: _logoOpacity,
                  child: Image.asset(
                    'assets/logo.png',
                    height: 132,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 24,
            top: 10,
            child: FloatingChip(
              label: _isRegister ? 'emotion: joy 91%' : 'emotion: calm 84%',
              color: c,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandName(ResonanceColors c) {
    return Center(
      child: Text(
        'Fem-PsychMonitor',
        style: GoogleFonts.spaceGrotesk(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: c.primary,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildEyebrow(ResonanceColors c) {
    final index = _isRegister ? '02' : '01';
    final label = _isRegister
        ? AppLocalizations.tr('register').toUpperCase()
        : AppLocalizations.tr('login').toUpperCase();
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            index,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: c.primary,
              letterSpacing: 1.5,
            ),
          ),
          Text(
            ' / $label',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: c.onSurfaceVariant,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(ResonanceColors c) {
    return Text(
      _isRegister
          ? AppLocalizations.tr('register_title')
          : AppLocalizations.tr('login_title'),
      textAlign: TextAlign.center,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: c.onSurface,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildSubtitle(ResonanceColors c) {
    return Text(
      _isRegister
          ? AppLocalizations.tr('register_subtitle')
          : AppLocalizations.tr('login_subtitle'),
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        fontSize: 15,
        color: c.onSurfaceVariant,
        height: 1.4,
      ),
    );
  }

  Widget _buildWaveform(ResonanceColors c) {
    const heights = [
      12.0, 20.0, 28.0, 16.0, 24.0, 14.0, 26.0, 18.0, 22.0, 12.0,
      20.0, 28.0, 16.0, 24.0, 14.0, 26.0, 18.0, 22.0,
    ];
    const active = [1, 3, 5, 7, 9, 11, 13, 15, 17];
    return SizedBox(
      height: 34,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(heights.length, (i) {
          final isActive = active.contains(i);
          return Container(
            width: isActive ? 3 : 2,
            height: heights[i],
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: isActive ? c.primary : c.outlineVariant,
              borderRadius: BorderRadius.circular(999),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFormCard(ResonanceColors c) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 4,
          bottom: -4,
          child: Container(
            decoration: BoxDecoration(
              color: c.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: c.surfaceLowest,
            border: Border.all(color: c.outlineVariant),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildModeToggle(c),
              const SizedBox(height: 20),
              if (_isRegister) ...[
                _buildField(
                  controller: _name,
                  label: AppLocalizations.tr('username_hint'),
                  icon: Icons.person_outline_rounded,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 14),
              ],
              _buildField(
                controller: _email,
                label: AppLocalizations.tr('auth_email_label'),
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _password,
                label: AppLocalizations.tr('password_label'),
                icon: Icons.lock_outlined,
                obscure: _obscure,
                suffix: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: c.onSurfaceVariant,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                validator: _validatePassword,
              ),
              const SizedBox(height: 14),
              if (_isRegister) ...[
                _buildField(
                  controller: _confirm,
                  label: AppLocalizations.tr('confirm_password'),
                  icon: Icons.lock_outlined,
                  obscure: _obscureConfirm,
                  suffix: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: c.onSurfaceVariant,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: _validateConfirm,
                ),
                const SizedBox(height: 20),
              ] else ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _handleForgotPassword,
                    child: Text(
                      AppLocalizations.tr('forgot_password'),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _buildPrimaryButton(
                c: c,
                key: _isRegister
                    ? const ValueKey('registerButton')
                    : const ValueKey('loginButton'),
                label: _isRegister
                    ? AppLocalizations.tr('register')
                    : AppLocalizations.tr('login'),
                onTap: () {
                  if (!_acceptedPrivacy) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                AppLocalizations.tr('auth_privacy_required'),
                                style: GoogleFonts.inter(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: c.primary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  if (_isRegister) {
                    _handleRegister();
                  } else {
                    _handleLogin();
                  }
                },
              ),
              if (_isRegister) ...[
                const SizedBox(height: 14),
                Text(
                  AppLocalizations.tr('auth_email_verif_note'),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: c.onSurfaceVariant,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 22),
              _buildDivider(c),
              const SizedBox(height: 20),
              _buildGoogleButton(c),
              const SizedBox(height: 20),
              _buildPrivacyCheckbox(c),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModeToggle(ResonanceColors c) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _buildModeTab(c, _AuthMode.login),
          const SizedBox(width: 4),
          _buildModeTab(c, _AuthMode.register),
        ],
      ),
    );
  }

  Widget _buildModeTab(ResonanceColors c, _AuthMode mode) {
    final selected = _mode == mode;
    final label = mode == _AuthMode.login
        ? AppLocalizations.tr('login')
        : AppLocalizations.tr('register');
    return Expanded(
      child: SizedBox(
        height: 44,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: selected ? c.surfaceLowest : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: selected ? Border.all(color: c.outlineVariant) : null,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF24161C).withValues(alpha: 0.12),
                      offset: const Offset(2, 2),
                    ),
                  ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: mode == _AuthMode.login
                  ? const ValueKey('authModeTabLogin')
                  : const ValueKey('authModeTabRegister'),
              onTap: () => setState(() => _mode = mode),
              borderRadius: BorderRadius.circular(999),
              child: Center(
                child: Text(
                  label,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected ? c.onSurface : c.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    final c = ResonanceColors.of(context);
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      style: GoogleFonts.inter(
        fontSize: 15,
        color: c.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.spaceGrotesk(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: c.onSurfaceVariant,
        ),
        floatingLabelStyle: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: c.primary,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Icon(icon, color: c.outline, size: 20),
        ),
        suffixIcon: suffix,
        filled: true,
        fillColor: c.surfaceLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1.4),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required ResonanceColors c,
    Key? key,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDisabled = _isLoading;
    return SizedBox(
      key: key,
      width: double.infinity,
      height: 56,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDisabled ? c.surfaceVariant : c.primary,
          borderRadius: BorderRadius.circular(999),
          boxShadow: isDisabled
              ? []
              : const [
                  BoxShadow(
                    color: Color(0x4024161C),
                    offset: Offset(4, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled ? null : onTap,
            borderRadius: BorderRadius.circular(999),
            splashColor: Colors.white.withValues(alpha: 0.15),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      label,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDisabled ? c.onSurfaceVariant : Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(ResonanceColors c) {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: c.outlineVariant),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            AppLocalizations.tr('or_continue_with'),
            style: GoogleFonts.inter(
              fontSize: 13,
              color: c.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: c.outlineVariant),
        ),
      ],
    );
  }

  Widget _buildPrivacyCheckbox(ResonanceColors c) {
    return GestureDetector(
      onTap: () => setState(() => _acceptedPrivacy = !_acceptedPrivacy),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: _acceptedPrivacy
                  ? c.primary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _acceptedPrivacy
                    ? c.primary
                    : c.outline,
                width: 1.4,
              ),
            ),
            child: _acceptedPrivacy
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: c.onSurfaceVariant,
                  height: 1.3,
                ),
                children: [
                  TextSpan(text: AppLocalizations.tr('privacy_agree_prefix')),
                  TextSpan(
                    text: AppLocalizations.tr('privacy_link'),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.primary,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = _openPrivacyPolicy,
                  ),
                  TextSpan(text: AppLocalizations.tr('privacy_agree_connector')),
                  TextSpan(
                    text: AppLocalizations.tr('terms_services'),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.primary,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = _openTermsOfService,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleButton(ResonanceColors c) {
    final isDisabled = _isLoading;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: isDisabled
            ? null
            : () {
                if (!_acceptedPrivacy) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              AppLocalizations.tr('auth_privacy_required'),
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF4285F4),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                _handleGoogleSignIn();
              },
        style: OutlinedButton.styleFrom(
          foregroundColor: isDisabled
              ? c.onSurfaceVariant
              : c.onSurface,
          side: BorderSide(
            color: isDisabled ? c.surfaceVariant : c.outlineVariant,
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          backgroundColor: isDisabled
              ? c.surfaceVariant.withValues(alpha: 0.4)
              : c.surfaceLowest,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/google.png',
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 14),
            Text(
              AppLocalizations.tr('google_signin'),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(ResonanceColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(
          'FEM-PSYCHMONITOR · VOICE-EMOTION AI',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
            color: c.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
void _openPrivacyPolicy() {
    launchUrl(
      Uri.parse('https://psychmonitor.com/privacy-policy.html'),
      mode: LaunchMode.externalApplication,
    );
  }

  void _openTermsOfService() {
    launchUrl(
      Uri.parse('https://psychmonitor.com/terms-of-services.html'),
      mode: LaunchMode.externalApplication,
    );
  }
}

/// ─────────────────────────────────────────────────────────────
/// _VerificationDialog - Dialog verifikasi email 3-tahap
/// ─────────────────────────────────────────────────────────────
class _VerificationDialog extends StatefulWidget {
  final String email;
  final String password;
  final VoidCallback onLogin;

  const _VerificationDialog({
    required this.email,
    required this.password,
    required this.onLogin,
  });

  @override
  State<_VerificationDialog> createState() => _VerificationDialogState();
}

class _VerificationDialogState extends State<_VerificationDialog>
    with WidgetsBindingObserver {
  Timer? _pollTimer;
  Timer? _cooldownTimer;
  int _pollCount = 0;
  int _cooldown = 0;
  String _step = 'waiting'; // waiting → verified → loading

  String get _emailSuggestion {
    final domain = widget.email.split('@').last.toLowerCase();
    if (domain.contains('gmail')) return AppLocalizations.tr('verif_gmail_hint');
    if (domain.contains('yahoo')) return AppLocalizations.tr('verif_yahoo_hint');
    if (domain.contains('outlook') || domain.contains('hotmail')) {
      return AppLocalizations.tr('verif_outlook_hint');
    }
    return AppLocalizations.tr('verif_other_hint');
  }

  void _startCooldown() {
    _cooldown = 30;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) { _cooldownTimer?.cancel(); return; }
      setState(() => _cooldown--);
      if (_cooldown <= 0) _cooldownTimer?.cancel();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _step == 'waiting') {
      _checkNow();
    }
  }

  Future<void> _checkNow() async {
    if (!mounted || _step != 'waiting') return;
    _pollTimer?.cancel();
    final verified = await context.read<AuthProvider>().checkEmailVerified(
      widget.email,
      widget.password,
    );
    if (verified && mounted) {
      setState(() => _step = 'verified');
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() => _step = 'loading');
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              Navigator.of(context).pop();
              widget.onLogin();
            }
          });
        }
      });
    } else {
      _startPolling();
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_step != 'waiting') return;
      _pollCount++;
      if (_pollCount > 20) {
        _pollTimer?.cancel();
        return;
      }
      if (!mounted) return;
      final verified = await context.read<AuthProvider>().checkEmailVerified(
        widget.email,
        widget.password,
      );
      if (verified && mounted) {
        _pollTimer?.cancel();
        setState(() => _step = 'verified');
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() => _step = 'loading');
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                Navigator.of(context).pop();
                widget.onLogin();
              }
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      content: switch (_step) {
        'verified' => _buildVerified(),
        'loading' => _buildLoading(),
        _ => _buildWaiting(),
      },
    );
  }

  Widget _buildStepIndicator({int current = 2}) {
    final active = const Color(0xFFC77E8C);
    final inactive = AppTheme.textH(context);

    Widget step(int number, String label, {bool completed = false, bool isCurrent = false}) {
      final color = completed || isCurrent ? active : inactive;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: completed ? active : Colors.transparent,
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: completed
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
                  : Text('$number',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      )),
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                color: color,
              )),
        ],
      );
    }

    Widget line(bool completed) {
      return Container(
        width: 28,
        height: 2,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: completed ? active : inactive.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(1),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          step(1, AppLocalizations.tr('register'), completed: current > 1),
          line(current > 1),
          step(2, AppLocalizations.tr('verification_step'), completed: current > 2, isCurrent: current == 2),
          line(current > 2),
          step(3, AppLocalizations.tr('login'), isCurrent: current == 3),
        ],
      ),
    );
  }

  Widget _buildWaiting() {
    final isCooldown = _cooldown > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 4),
        _buildStepIndicator(),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFC77E8C), Color(0xFFB76E79)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_add_alt_1_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.tr('verif_account_created'),
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textP(context),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.tr('verif_email_sent_to'),
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            color: AppTheme.textS(context),
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
            ),
          ),
          child: Text(
            widget.email,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline_rounded, size: 11, color: const Color(0xFFF59E0B).withValues(alpha: 0.8)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  _emailSuggestion,
                  style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFFB45309), height: 1.3),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          AppLocalizations.tr('verif_click_link'),
          style: GoogleFonts.poppins(
            fontSize: 10.5,
            color: AppTheme.textH(context),
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            onPressed: isCooldown
                ? null
                : () async {
                    _startCooldown();
                    await context.read<AuthProvider>().resendVerificationEmail(
                      email: widget.email,
                      password: widget.password,
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.tr('verif_resend_sent'),
                        ),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
            icon: Icon(
              isCooldown ? Icons.hourglass_bottom_rounded : Icons.email_rounded,
              size: 18,
            ),
            label: Text(
              isCooldown
                  ? AppLocalizations.tr('verif_resend_countdown')
                      .replaceAll('{count}', '$_cooldown')
                  : AppLocalizations.tr('verif_resend_button'),
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isCooldown ? AppTheme.textH(context) : AppTheme.primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppTheme.textH(context),
              disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: TextButton(
            onPressed: () {
              _pollTimer?.cancel();
              _cooldownTimer?.cancel();
              Navigator.of(context).pop();
              widget.onLogin();
            },
            child: Text(
              AppLocalizations.tr('auth_already_verified'),
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerified() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 4),
        _buildStepIndicator(current: 3),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF10B981),
            size: 44,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.tr('verif_success_title'),
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textP(context),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.tr('verif_success_desc'),
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppTheme.textS(context),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLoading() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        const SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: Color(0xFFC77E8C),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          AppLocalizations.tr('verif_processing'),
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textS(context),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// ─────────────────────────────────────────────────────────────
/// _SetPasswordDialog - Dialog untuk membuat password bagi akun Google
/// ─────────────────────────────────────────────────────────────
class _SetPasswordDialog extends StatefulWidget {
  const _SetPasswordDialog();

  @override
  State<_SetPasswordDialog> createState() => _SetPasswordDialogState();
}

class _SetPasswordDialogState extends State<_SetPasswordDialog> {
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.15),
                  AppTheme.primaryDark.withValues(alpha: 0.08),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFFC77E8C),
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.tr('setpass_title'),
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textP(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.tr('setpass_desc'),
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.textS(context),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscure,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textP(context),
            ),
            decoration: InputDecoration(
              hintText: AppLocalizations.tr('auth_pass_min_length'),
              hintStyle: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textH(context),
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 8),
                child: Icon(
                  Icons.lock_outlined,
                  color: AppTheme.textH(context),
                  size: 20,
                ),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: AppTheme.textH(context),
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              filled: true,
              fillColor: AppTheme.surfVar(context).withValues(alpha: 0.7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _confirmCtrl,
            obscureText: _obscureConfirm,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textP(context),
            ),
            decoration: InputDecoration(
              hintText: AppLocalizations.tr('confirm_password'),
              hintStyle: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textH(context),
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 8),
                child: Icon(
                  Icons.lock_outlined,
                  color: AppTheme.textH(context),
                  size: 20,
                ),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: AppTheme.textH(context),
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              filled: true,
              fillColor: AppTheme.surfVar(context).withValues(alpha: 0.7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      final pass = _passCtrl.text.trim();
                      final confirm = _confirmCtrl.text.trim();

                      if (pass.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.tr('auth_pass_min_length'),
                            ),
                            backgroundColor: const Color(0xFFEF4444),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                        return;
                      }
                      if (pass != confirm) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.tr('auth_pass_mismatch'),
                            ),
                            backgroundColor: const Color(0xFFEF4444),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                        return;
                      }

                      setState(() => _isLoading = true);
                      final ok = await context
                          .read<AuthProvider>()
                          .linkPassword(pass);

                      if (!context.mounted) return;

                      if (ok) {
                        Navigator.of(context).pop();
                        final appUser = await DatabaseService.getUser();
                        if (!context.mounted) return;
                        if (appUser == null ||
                            appUser.bigFiveScores.isEmpty) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (ctx) => OnboardingScreen(
                                onCompleted: () {
                                  Navigator.of(ctx).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => const MainNavigation(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        } else {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const AppRouter(),
                            ),
                          );
                        }
                      } else {
                        setState(() => _isLoading = false);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.tr('setpass_failed'),
                            ),
                            backgroundColor: const Color(0xFFEF4444),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      AppLocalizations.tr('setpass_button'),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
