import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../providers/auth_provider.dart';
import '../providers/premium_provider.dart';
import '../services/subscription_service.dart';
import '../screens/onboarding_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';

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

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  bool _obscure = true;
  bool _isLoading = false;
  bool _acceptedPrivacy = false;

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
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _email.dispose();
    _password.dispose();
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

    switch (result) {
      case 'success':
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await SubscriptionService()
              .identifyUser(uid, context.read<PremiumProvider>());
        }
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
                'Sudah Verifikasi? Masuk',
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
                'Tutup',
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
              'Email Sudah Terdaftar',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textP(ctx),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Email ${_email.text.trim()} sudah memiliki akun. '
              'Password yang Anda masukkan tidak cocok.',
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
                            ? 'Email reset password terkirim!'
                            : 'Gagal mengirim email reset password',
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
                  'Kirim Reset Password',
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
                  'Coba Lagi',
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
                color: Color(0xFFE8728A),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Akun Terdaftar dengan Google',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textP(ctx),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Email ini sudah terdaftar menggunakan Google. Silakan masuk dengan tombol Google di bawah.',
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
                  'Tutup',
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
        'Email Sudah Terdaftar',
        'Email ini sudah memiliki akun. Silakan masuk dengan password yang benar.'
      ),
      'wrong-password' => (
        'Password Salah',
        'Password yang Anda masukkan salah. Silakan coba lagi.'
      ),
      'invalid-email' => (
        'Email Tidak Valid',
        'Format email yang Anda masukkan tidak valid.'
      ),
      'too-many-requests' => (
        'Terlalu Banyak Percobaan',
        'Terlalu banyak percobaan login. Silakan tunggu beberapa saat.'
      ),
      'network-request-failed' => (
        'Koneksi Gagal',
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.'
      ),
      'invalid-credential' => (
        'Email/Password Salah',
        'Email atau password yang Anda masukkan salah. Silakan coba lagi.'
      ),
      _ => (
        'Masuk Gagal',
        'Terjadi kesalahan. Silakan coba lagi nanti.'
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
                  'Tutup',
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
                color: Color(0xFFE8728A),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Lengkapi Data Diri',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textP(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Sebelum menggunakan aplikasi, Anda perlu mengisi kuesioner psikis terlebih dahulu. Data ini akan membantu kami memberikan rekomendasi yang sesuai dengan kondisi Anda.',
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
                  'Mulai Sekarang',
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        useOverlay: true,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),

                        // ── Logo ────────────────────────
                        Image.asset(
                          'assets/logo.png',
                          width: 88,
                          height: 88,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 14),

                        // ── App title ────────────────────────────
                        Text(
                          'Fem-Psych Monitor',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textP(context),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.tr('app_subtitle'),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppTheme.textS(context),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── Premium Card ────────────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppTheme.spaceXl),
                          decoration: BoxDecoration(
                            color: AppTheme.surface(context),
                            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                            border: Border.all(
                              color: AppTheme.primaryColor.withValues(alpha: 0.12),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withValues(alpha: 0.12),
                                blurRadius: 30,
                                spreadRadius: 0,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: AppTheme.primaryColor.withValues(alpha: 0.06),
                                blurRadius: 60,
                                spreadRadius: 0,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ── Decorative accent ──────────
                                  Container(
                                    width: 32,
                                    height: 3.5,
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.primaryGradient,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // ── Card header ────────────────
                                  Text(
                                    'Masuk',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textP(context),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Masukkan email dan password untuk melanjutkan',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.5,
                                      color: AppTheme.textS(context),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // ── Email field ────────────────
                                  _buildField(
                                    controller: _email,
                                    label: 'Email',
                                    hint: 'contoh@email.com',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Email wajib diisi';
                                      if (!v.contains('@') || !v.contains('.')) {
                                        return 'Format email tidak valid';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 18),

                                  // ── Password field ─────────────
                                  _buildField(
                                    controller: _password,
                                    label: 'Password',
                                    hint: 'Minimal 6 karakter',
                                    icon: Icons.lock_outlined,
                                    obscure: _obscure,
                                    suffix: IconButton(
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                        color: AppTheme.textH(context),
                                        size: 20,
                                      ),
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Password wajib diisi';
                                      if (v.length < 6) return 'Minimal 6 karakter';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  // ── Privacy checkbox ──────────
                                  _buildPrivacyCheckbox(),
                                  const SizedBox(height: 18),

                                  // ── Login button ──────────────
                                  _buildPrimaryButton(
                                    label: 'Masuk',
                                    onTap: _handleLogin,
                                    disabled: !_acceptedPrivacy,
                                  ),
                                  const SizedBox(height: 22),

                                  // ── Divider ───────────────────
                                  _buildDivider(),
                                  const SizedBox(height: 18),

                                  // ── Google button ─────────────
                                  _buildGoogleButton(),
                                  const SizedBox(height: 12),

                                  // ── Footnote ──────────────────
                                  Text(
                                    'Email baru akan otomatis terdaftar. Cek email untuk verifikasi.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 9.5,
                                      color: AppTheme.textH(context),
                                      height: 1.3,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                          ),
                        const SizedBox(height: 28),
                      ],
                    ),
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
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppTheme.textP(context),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.textP(context),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.textH(context),
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 8),
              child: Icon(icon, color: AppTheme.textH(context), size: 20),
            ),
            suffixIcon: suffix != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: suffix,
                  )
                : null,
            filled: true,
            fillColor: AppTheme.surfVar(context).withValues(alpha: 0.7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppTheme.primaryColor.withValues(alpha: 0.7),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFF87171),
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFF87171),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onTap,
    bool disabled = false,
  }) {
    final isDisabled = _isLoading || disabled;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: isDisabled ? null : AppTheme.primaryGradient,
            color: isDisabled ? AppTheme.textH(context) : null,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: isDisabled
                ? []
                : AppTheme.primaryShadow,
          ),
          child: InkWell(
            onTap: isDisabled ? null : onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDisabled
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: AppTheme.surfVar(context)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'atau',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: AppTheme.textH(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: AppTheme.surfVar(context)),
        ),
      ],
    );
  }

  Widget _buildPrivacyCheckbox() {
    return GestureDetector(
      onTap: () => setState(() => _acceptedPrivacy = !_acceptedPrivacy),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _acceptedPrivacy
                  ? AppTheme.primaryColor
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _acceptedPrivacy
                    ? AppTheme.primaryColor
                    : AppTheme.textH(context),
                width: 1.8,
              ),
            ),
            child: _acceptedPrivacy
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => _openPrivacyPolicy(),
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: AppTheme.textS(context),
                    height: 1.3,
                  ),
                  children: [
                    TextSpan(text: 'Saya menyetujui '),
                    TextSpan(
                      text: 'Kebijakan Privasi',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPrivacyPolicy() {
    // ignore: deprecated_member_use
    launch('https://fem-psychmonitor.web.app');
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed:
            (_isLoading || !_acceptedPrivacy) ? null : _handleGoogleSignIn,
        icon: Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          child: Text(
            'G',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF4285F4),
            ),
          ),
        ),
        label: Text(
          'Lanjutkan dengan Google',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 13.5,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textP(context),
          side: BorderSide(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      ),
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
    if (domain.contains('gmail')) return 'Cek inbox atau folder Promosi / Sosial';
    if (domain.contains('yahoo')) return 'Cek inbox atau folder Bulk / Spam';
    if (domain.contains('outlook') || domain.contains('hotmail')) {
      return 'Cek inbox atau folder Junk Email';
    }
    return 'Cek inbox dan folder spam';
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
    final active = const Color(0xFFE8728A);
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
          step(1, 'Daftar', completed: current > 1),
          line(current > 1),
          step(2, 'Verifikasi', completed: current > 2, isCurrent: current == 2),
          line(current > 2),
          step(3, 'Masuk', isCurrent: current == 3),
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
              colors: [Color(0xFFE8728A), Color(0xFFD45674)],
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
          'Akun Baru Berhasil Dibuat!',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textP(context),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Email verifikasi telah dikirim ke:',
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
          'Klik link di email untuk verifikasi, lalu kembali ke aplikasi.',
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
                        content: const Text('Email verifikasi terkirim'),
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
              isCooldown ? 'Kirim Ulang ($_cooldown)' : 'Kirim Email Verifikasi',
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
              'Sudah Verifikasi? Masuk',
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
          'Verifikasi Berhasil!',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textP(context),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Email Anda telah terverifikasi. Mengalihkan...',
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
            color: Color(0xFFE8728A),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Memproses masuk...',
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
