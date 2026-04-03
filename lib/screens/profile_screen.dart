import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ProfileScreen — Edit Profil User
//
// Fitur:
//   • Foto profil (placeholder — belum pakai ImagePicker)
//   • Edit username
//   • Edit email
// ─────────────────────────────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameCtrl;
  late TextEditingController _emailCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _usernameCtrl = TextEditingController(text: auth.username);
    _emailCtrl = TextEditingController(text: auth.email);
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    await context.read<AuthProvider>().updateProfile(
      username: _usernameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
    );

    // Juga update username ke DatabaseService (SQLite)
    final user = await DatabaseService.getUser();
    if (user != null) {
      await DatabaseService.updateUser(user.copyWith(
        name: _usernameCtrl.text.trim(),
      ));
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.tr('profile_saved'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final initial = auth.username.isNotEmpty
        ? auth.username[0].toUpperCase()
        : (auth.email.isNotEmpty ? auth.email[0].toUpperCase() : '?');

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.bg(context),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppTheme.primaryColor,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(AppLocalizations.tr('profile_title')),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── Header Banner ──────────────────────────────
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withValues(alpha: 0.7),
                          AppTheme.primaryColor,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -50,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Stack(
                        children: [
                      // Avatar
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.primaryGradient,
                          boxShadow: AppTheme.primaryShadow,
                        ),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.surface(context),
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: GoogleFonts.poppins(
                                fontSize: 40,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Camera badge
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            // Placeholder: ImagePicker akan ditambahkan
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Fitur foto profil akan segera hadir',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                backgroundColor: AppTheme.primaryColor,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusSm),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryColor,
                              border: Border.all(
                                color: AppTheme.surface(context),
                                width: 2.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
              
              const SizedBox(height: 56),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXl),
                child: Column(
                  children: [
                    Text(
                      AppLocalizations.tr('tap_to_change_photo'),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textS(context),
                      ),
                    ),

                    const SizedBox(height: 32),

                // ── Form Fields ────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(AppTheme.spaceLg),
                  decoration: BoxDecoration(
                    color: AppTheme.surface(context),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username
                      _buildFieldLabel(
                          context, AppLocalizations.tr('username')),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _usernameCtrl,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.textP(context),
                        ),
                        decoration: _inputDecoration(
                          context,
                          hint: AppLocalizations.tr('username_hint'),
                          icon: Icons.person_outlined,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Username wajib diisi';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // Email
                      _buildFieldLabel(
                          context, AppLocalizations.tr('email')),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.textP(context),
                        ),
                        decoration: _inputDecoration(
                          context,
                          hint: AppLocalizations.tr('email_hint'),
                          icon: Icons.email_outlined,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email wajib diisi';
                          }
                          if (!v.contains('@')) return 'Format email tidak valid';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Member since
                if (auth.isLoggedIn)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.verified_user_rounded,
                          color: AppTheme.primaryColor,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${AppLocalizations.tr('member_since')}: ${_formatDate(DateTime.now())}',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 28),

                // ── Tombol Simpan ──────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            AppLocalizations.tr('save_profile'),
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);
  }

  Widget _buildFieldLabel(BuildContext context, String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textP(context),
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        fontSize: 13.5,
        color: AppTheme.textH(context),
      ),
      prefixIcon: Icon(icon, color: AppTheme.textH(context), size: 20),
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
    );
  }

  String _formatDate(DateTime dt) {
    final months = AppLocalizations.currentLocale == 'id'
        ? [
            'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
            'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
          ]
        : [
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
          ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
