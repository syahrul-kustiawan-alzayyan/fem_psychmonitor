import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../main.dart'; // For MainNavigation
import '../providers/auth_provider.dart';
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

  // Mock login
  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // Simulasi delay jaringan
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    final success = await context.read<AuthProvider>().login(
      email: _loginEmail.text.trim(),
      password: _loginPassword.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.tr('email_not_registered')),
          backgroundColor: AppTheme.secondaryColor,
        ),
      );
    }
  }

  // Mock register
  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    final success = await context.read<AuthProvider>().register(
      email: _regEmail.text.trim(),
      password: _regPassword.text,
      username: _regUsername.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.tr('email_already_registered')),
          backgroundColor: AppTheme.secondaryColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXl),
          child: Column(
            children: [
              const SizedBox(height: 48),

              // ── Logo ────────────────────────────────────────
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: AppTheme.primaryShadow,
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.contain,
                ),
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

              const SizedBox(height: 36),

              // ── Tab Bar ─────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfVar(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: TabBar(
                  controller: _tabCtrl,
                  indicator: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppTheme.textS(context),
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
                height: 540,
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [_buildLoginTab(), _buildRegisterTab()],
                ),
              ),
            ],
          ),
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
          _buildGoogleButton(),

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
                if (!v.contains('@')) return AppLocalizations.tr('email_invalid');
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

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () {
          // Firebase Google Sign-In akan diimplementasikan nanti
        },
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
