import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../providers/auth_provider.dart';
import '../providers/premium_provider.dart';
import '../services/ad_service.dart';
import '../services/subscription_service.dart';
import '../screens/onboarding_screen.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AuthScreen — Login / Register UI
//
// Mengikuti tema utama aplikasi (light/dark mode aware)
// ─────────────────────────────────────────────────────────────────────────────
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  // Login fields
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();

  // Register fields
  final _regUsername = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPassword = TextEditingController();
  final _regConfirmPwd = TextEditingController();

  bool _obscureLogin = true;
  bool _obscureReg = true;
  bool _obscureRegConfirm = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _loginEmail.dispose();
    _loginPassword.dispose();
    _regUsername.dispose();
    _regEmail.dispose();
    _regPassword.dispose();
    _regConfirmPwd.dispose();
    super.dispose();
  }

  Future<void> _showInterstitialBeforeNavigation(VoidCallback navigate) async {
    final premium = context.read<PremiumProvider>();
    if (!premium.isPremium) {
      await AdService().showInterstitialAd();
    }
    if (!mounted) return;
    navigate();
  }

  // ── Login Handler ──
  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    if (!mounted) return;

    final result = await context.read<AuthProvider>().login(
      email: _loginEmail.text.trim(),
      password: _loginPassword.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    switch (result) {
      case 'success':
        await SubscriptionService().refresh(context.read<PremiumProvider>());
        _showInterstitialBeforeNavigation(() {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AppRouter()),
          );
        });
        break;
      case 'new_user':
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
        break;
      case 'email_not_verified':
        _showEmailNotVerifiedDialog();
        break;
      case 'user-not-found':
      case 'invalid-credential':
      case 'wrong-password':
        _showErrorDialog(
          'Login Gagal',
          'Email/Password salah, atau akun ini didaftarkan via Google. Silakan periksa kembali atau gunakan tombol Google Sign-In.',
        );
        break;
      default:
        _showErrorDialog(
          'Login Gagal',
          'Gagal masuk: $result',
        );
    }
  }

  // ── Register Handler ──
  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    if (!mounted) return;

    final result = await context.read<AuthProvider>().register(
      email: _regEmail.text.trim(),
      password: _regPassword.text,
      username: _regUsername.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    switch (result) {
      case 'success':
        _showEmailVerificationSentDialog();
        break;
      case 'email_exists':
      case 'email-already-in-use':
        _showErrorDialog(
          'Pendaftaran Gagal',
          'Email sudah terdaftar. Silakan login, atau gunakan tombol Google Sign-In.',
        );
        break;
      default:
        _showErrorDialog(
          'Pendaftaran Gagal',
          'Pendaftaran gagal: $result',
        );
    }
  }

  // ── Google Sign-In Handler ──
  Future<void> _handleGoogleSignIn(bool isLogin) async {
    setState(() => _isLoading = true);

    if (!mounted) return;

    final result = await context.read<AuthProvider>().signInWithGoogle(isLogin: isLogin);

    if (!mounted) return;
    setState(() => _isLoading = false);

    switch (result) {
      case 'success':
        await SubscriptionService().refresh(context.read<PremiumProvider>());
        _showInterstitialBeforeNavigation(() {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AppRouter()),
          );
        });
        break;
      case 'new_user':
        // User baru via Google → langsung ke onboarding
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
        break;
      case 'cancelled':
        // User membatalkan, tidak perlu notifikasi
        break;
      case 'unregistered_google':
        _showErrorDialog(
          'Akun Tidak Ditemukan',
          AppLocalizations.tr('unregistered_google') == 'unregistered_google' 
              ? 'Email belum terdaftar. Silakan daftar terlebih dahulu di tab Register.' 
              : AppLocalizations.tr('unregistered_google'),
        );
        break;
      default:
        _showErrorDialog(
          'Login Google Gagal',
          AppLocalizations.tr('google_signin_failed'),
        );
    }
  }

  // ── Dialog: Error ──
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface(ctx),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
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
            const SizedBox(height: 12),
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
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  AppLocalizations.tr('close') == 'close' ? 'Tutup' : AppLocalizations.tr('close'),
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

  // ── Dialog: Email Verifikasi Terkirim ──
  void _showEmailVerificationSentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface(ctx),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_read_rounded,
                color: Color(0xFF10B981),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.tr('email_verification_sent'),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textP(ctx),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.tr('email_verification_desc'),
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textS(ctx),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Text(
                _regEmail.text.trim(),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  // Pindah ke tab Login
                  _tabCtrl.animateTo(0);
                  _loginEmail.text = _regEmail.text.trim();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  AppLocalizations.tr('check_email'),
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

  // ── Dialog: Email Belum Diverifikasi ──
  void _showEmailNotVerifiedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface(ctx),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
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
            const SizedBox(height: 12),
            Text(
              AppLocalizations.tr('email_not_verified_desc'),
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textS(ctx),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Tombol Kirim Ulang
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  final sent = await context.read<AuthProvider>().resendVerificationEmail(
                    email: _loginEmail.text.trim(),
                    password: _loginPassword.text,
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        sent
                            ? AppLocalizations.tr('verification_resent')
                            : AppLocalizations.tr('resend_failed'),
                      ),
                      backgroundColor: sent ? const Color(0xFF10B981) : AppTheme.secondaryColor,
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
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Tombol Tutup
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXl),
                child: Column(
                  children: [
                    const SizedBox(height: 48),

                    // ── Logo ────────────────────────────────────────
                    Image.asset(
                      'assets/logo.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Fem-Psych Monitor',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textP(context),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppLocalizations.tr('app_subtitle'),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppTheme.textS(context),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Tab Bar ─────────────────────────────────────
                    PreferredSize(
                      preferredSize: const Size.fromHeight(48),
                      child: TabBar(
                        controller: _tabCtrl,
                        indicatorColor: AppTheme.primaryColor,
                        indicatorWeight: 3,
                        unselectedLabelColor: AppTheme.textH(context),
                        labelColor: AppTheme.primaryColor,
                        labelStyle: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        unselectedLabelStyle: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        tabs: [
                          Tab(text: AppLocalizations.tr('login')),
                          Tab(text: AppLocalizations.tr('register')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Tab Content ─────────────────────────────────
                    SizedBox(
                      height: 500,
                      child: TabBarView(
                        controller: _tabCtrl,
                        children: [_buildLoginTab(), _buildRegisterTab()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────
  // Tab: Login
  // ───────────────────────────────────────────────────────────────
  Widget _buildLoginTab() {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.tr('login_title'),
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textP(context),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.tr('login_subtitle'),
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.textS(context),
            ),
          ),
          const SizedBox(height: 24),

          // Email
          _buildTextField(
            controller: _loginEmail,
            label: AppLocalizations.tr('email'),
            hint: AppLocalizations.tr('email_hint'),
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return AppLocalizations.tr('email_required');
              if (!v.contains('@')) return AppLocalizations.tr('email_invalid');
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password
          _buildTextField(
            controller: _loginPassword,
            label: AppLocalizations.tr('password_hint'),
            hint: '••••••••',
            icon: Icons.lock_outlined,
            obscure: _obscureLogin,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureLogin
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: AppTheme.textH(context),
                size: 20,
              ),
              onPressed: () => setState(() => _obscureLogin = !_obscureLogin),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return AppLocalizations.tr('password_required');
              if (v.length < 6) return AppLocalizations.tr('password_min_length');
              return null;
            },
          ),

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: Text(
                AppLocalizations.tr('forgot_password'),
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Login button
          _buildPrimaryButton(
            label: AppLocalizations.tr('login'),
            onTap: _handleLogin,
          ),

          const SizedBox(height: 20),

          // Divider
          _buildDividerWithText(AppLocalizations.tr('or_continue_with')),

          const SizedBox(height: 16),

          // Google sign-in
          _buildGoogleButton(isLogin: true),

          const SizedBox(height: 16),

          // Link to register
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.tr('no_account'),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.textS(context),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _tabCtrl.animateTo(1),
                child: Text(
                  AppLocalizations.tr('register'),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────
  // Tab: Register
  // ───────────────────────────────────────────────────────────────
  Widget _buildRegisterTab() {
    return Form(
      key: _registerFormKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.tr('register_title'),
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textP(context),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.tr('register_subtitle'),
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textS(context),
              ),
            ),
            const SizedBox(height: 24),

            // Username
            _buildTextField(
              controller: _regUsername,
              label: AppLocalizations.tr('username'),
              hint: AppLocalizations.tr('username_hint'),
              icon: Icons.person_outlined,
              validator: (v) {
                if (v == null || v.isEmpty) return AppLocalizations.tr('name_required');
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email
            _buildTextField(
              controller: _regEmail,
              label: AppLocalizations.tr('email'),
              hint: AppLocalizations.tr('email_hint'),
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return AppLocalizations.tr('email_required');
                if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(v)) {
                  return AppLocalizations.tr('email_invalid');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password
            _buildTextField(
              controller: _regPassword,
              label: AppLocalizations.tr('password_hint'),
              hint: '••••••••',
              icon: Icons.lock_outlined,
              obscure: _obscureReg,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureReg
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: AppTheme.textH(context),
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureReg = !_obscureReg),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return AppLocalizations.tr('password_required');
                if (v.length < 6) return AppLocalizations.tr('password_min_length');
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Confirm password
            _buildTextField(
              controller: _regConfirmPwd,
              label: AppLocalizations.tr('confirm_password'),
              hint: '••••••••',
              icon: Icons.lock_outlined,
              obscure: _obscureRegConfirm,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureRegConfirm
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: AppTheme.textH(context),
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscureRegConfirm = !_obscureRegConfirm),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return AppLocalizations.tr('confirm_password');
                if (v != _regPassword.text) return AppLocalizations.tr('password_mismatch');
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Register button
            _buildPrimaryButton(
              label: AppLocalizations.tr('register'),
              onTap: _handleRegister,
            ),

            const SizedBox(height: 20),

            // Divider
            _buildDividerWithText(AppLocalizations.tr('or_continue_with')),

            const SizedBox(height: 16),

            // Google sign-in on register tab too
            _buildGoogleButton(isLogin: false),

            const SizedBox(height: 16),

            // Link to login
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.tr('has_account'),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.textS(context),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _tabCtrl.animateTo(0),
                  child: Text(
                    AppLocalizations.tr('login'),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────
  // Reusable Widgets
  // ───────────────────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
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
              fontSize: 13.5,
              color: AppTheme.textH(context),
            ),
            prefixIcon: Icon(icon, color: AppTheme.textH(context), size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppTheme.surfVar(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: const BorderSide(
                color: AppTheme.primaryColor,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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
                label,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildDividerWithText(String text) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: AppTheme.surfVar(context))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textH(context),
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: AppTheme.surfVar(context))),
      ],
    );
  }

  Widget _buildGoogleButton({required bool isLogin}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : () => _handleGoogleSignIn(isLogin),
        icon: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: const Icon(
            Icons.g_mobiledata_rounded,
            size: 24,
            color: Color(0xFF4285F4),
          ),
        ),
        label: Text(
          AppLocalizations.tr('google_signin'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textP(context),
          side: BorderSide(color: AppTheme.surfVar(context), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      ),
    );
  }
}
