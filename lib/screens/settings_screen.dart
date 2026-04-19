import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../main.dart'; // For MainNavigation & AppRouter
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'onboarding_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SettingsScreen — Halaman Pengaturan
//
// Fitur:
//   • Bahasa (ID / EN)
//   • Tema Tampilan (Light / Dark)
//   • Panduan Aplikasi
//   • Terms & Services
//   • License
//   • Logout
// ─────────────────────────────────────────────────────────────────────────────
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final theme = context.watch<ThemeProvider>();
    final isDark = theme.isDark;

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
                Icons.settings_rounded,
                color: AppTheme.primaryColor,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(AppLocalizations.tr('settings_title')),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceLg,
            vertical: AppTheme.spaceMd,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Section: Umum ──────────────────────────────
              _buildSectionLabel(context, AppLocalizations.tr('general')),
              const SizedBox(height: 10),

              _buildSettingsCard(
                context,
                children: [
                  // Bahasa
                  _buildSettingsTile(
                    context,
                    icon: Icons.language_rounded,
                    iconColor: const Color(0xFF60A5FA),
                    title: AppLocalizations.tr('language'),
                    trailing: _buildSegmentedControl(
                      context,
                      options: ['ID', 'EN'],
                      selected: locale.locale == 'id' ? 0 : 1,
                      onTap: (i) {
                        locale.setLocale(i == 0 ? 'id' : 'en');
                      },
                    ),
                  ),
                  _buildDivider(context),
                  // Tema
                  _buildSettingsTile(
                    context,
                    icon: isDark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    iconColor: isDark
                        ? AppTheme
                              .secondaryColor // Pink
                        : const Color(0xFFF59E0B),
                    title: AppLocalizations.tr('theme_mode'),
                    trailing: _buildSegmentedControl(
                      context,
                      options: [
                        AppLocalizations.tr('theme_light'),
                        AppLocalizations.tr('theme_dark'),
                      ],
                      selected: isDark ? 1 : 0,
                      onTap: (i) {
                        theme.setThemeMode(
                          i == 0 ? ThemeMode.light : ThemeMode.dark,
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Section: Tentang ───────────────────────────
              _buildSectionLabel(context, AppLocalizations.tr('about')),
              const SizedBox(height: 10),

              _buildSettingsCard(
                context,
                children: [
                  // Panduan
                  _buildSettingsTile(
                    context,
                    icon: Icons.menu_book_rounded,
                    iconColor: AppTheme.primaryColor,
                    title: AppLocalizations.tr('app_guide'),
                    subtitle: AppLocalizations.tr('app_guide_desc'),
                    onTap: () => _showGuide(context),
                  ),
                  _buildDivider(context),
                  // Terms
                  _buildSettingsTile(
                    context,
                    icon: Icons.description_outlined,
                    iconColor: const Color(0xFFF59E0B),
                    title: AppLocalizations.tr('terms_services'),
                    subtitle: AppLocalizations.tr('terms_desc'),
                    onTap: () => _showTerms(context),
                  ),
                  _buildDivider(context),
                  // License
                  _buildSettingsTile(
                    context,
                    icon: Icons.policy_rounded,
                    iconColor: const Color(0xFF34D399),
                    title: AppLocalizations.tr('license'),
                    subtitle: AppLocalizations.tr('license_desc'),
                    onTap: () {
                      showLicensePage(
                        context: context,
                        applicationName: 'Fem-Psych Monitor',
                        applicationVersion: '1.0.0',
                        applicationIcon: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Image.asset(
                              'assets/logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Section: Akun ──────────────────────────────
              _buildSectionLabel(context, AppLocalizations.tr('account')),
              const SizedBox(height: 10),

              _buildSettingsCard(
                context,
                children: [
                  // Reset Onboarding
                  _buildSettingsTile(
                    context,
                    icon: Icons.restart_alt_rounded,
                    iconColor: const Color(0xFF60A5FA),
                    title: 'Tampilkan Onboarding Lagi',
                    subtitle: 'Lihat splash screen & pertanyaan MBTI',
                    onTap: () => _handleResetOnboarding(context),
                  ),
                  _buildDivider(context),
                  _buildSettingsTile(
                    context,
                    icon: Icons.logout_rounded,
                    iconColor: const Color(0xFFF87171),
                    title: AppLocalizations.tr('logout'),
                    titleColor: const Color(0xFFF87171),
                    onTap: () => _handleLogout(context),
                  ),
                  _buildDivider(context),
                  // Delete Account
                  _buildSettingsTile(
                    context,
                    icon: Icons.delete_forever_rounded,
                    iconColor: const Color(0xFFEF4444),
                    title: 'Hapus Akun & Data',
                    subtitle: 'Menghapus data rekaman & profil secara permanen',
                    titleColor: const Color(0xFFEF4444),
                    onTap: () => _handleDeleteAccount(context),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Footer: versi app
              Center(
                child: Text(
                  'Fem-Psych Monitor v1.0.0',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppTheme.textH(context),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helper Widgets ────────────────────────────────────────────

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppTheme.textH(context),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Color? titleColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? AppTheme.textP(context),
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: AppTheme.textS(context),
                      ),
                    ),
                ],
              ),
            ),
            ?trailing,
            if (onTap != null && trailing == null)
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textH(context),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: AppTheme.surfVar(context)),
    );
  }

  Widget _buildSegmentedControl(
    BuildContext context, {
    required List<String> options,
    required int selected,
    required ValueChanged<int> onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfVar(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(options.length, (i) {
          final isSelected = i == selected;
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                options[i],
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.textS(context),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Actions ───────────────────────────────────────────────────

  void _showGuide(BuildContext context) {
    final steps = [
      (
        icon: Icons.mic_rounded,
        title: AppLocalizations.tr('guide_step1_title'),
        desc: AppLocalizations.tr('guide_step1_desc'),
        color: AppTheme.primaryColor,
      ),
      (
        icon: Icons.psychology_rounded,
        title: AppLocalizations.tr('guide_step2_title'),
        desc: AppLocalizations.tr('guide_step2_desc'),
        color: AppTheme.secondaryColor, // Pink
      ),
      (
        icon: Icons.bar_chart_rounded,
        title: AppLocalizations.tr('guide_step3_title'),
        desc: AppLocalizations.tr('guide_step3_desc'),
        color: const Color(0xFF60A5FA),
      ),
      (
        icon: Icons.tips_and_updates_rounded,
        title: AppLocalizations.tr('guide_step4_title'),
        desc: AppLocalizations.tr('guide_step4_desc'),
        color: const Color(0xFFF59E0B),
      ),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollCtrl) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.surfVar(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.tr('guide_title'),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textP(context),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  controller: scrollCtrl,
                  itemCount: steps.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (ctx, i) {
                    final s = steps[i];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: s.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: s.color.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: s.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(s.icon, color: s.color, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textP(context),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  s.desc,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    color: AppTheme.textS(context),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTerms(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollCtrl) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.surfVar(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.tr('terms_title'),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textP(context),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  child: Text(
                    AppLocalizations.tr('terms_content'),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppTheme.textS(context),
                      height: 1.7,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleResetOnboarding(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Text(
          'Tampilkan Onboarding Lagi?',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppTheme.textP(context),
          ),
        ),
        content: Text(
          'Aplikasi akan menampilkan splash screen dan pertanyaan MBTI kembali. Data Anda tidak akan dihapus.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppTheme.textS(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: AppTheme.textS(context),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            onPressed: () async {
              // Reset status onboarding di SharedPreferences
              await StorageService.resetOnboarding();

              if (ctx.mounted) {
                Navigator.pop(ctx); // tutup dialog

                // Navigasi ke onboarding dengan MaterialPageRoute
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => OnboardingScreen(
                      onCompleted: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const MainNavigation(),
                          ),
                        );
                      },
                    ),
                  ),
                  (route) => false, // Hapus semua route sebelumnya
                );
              }
            },
            child: Text(
              'Ya, Tampilkan',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Text(
          AppLocalizations.tr('logout_confirm'),
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppTheme.textP(context),
          ),
        ),
        content: Text(
          AppLocalizations.tr('logout_confirm_desc'),
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppTheme.textS(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppLocalizations.tr('cancel'),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: AppTheme.textS(context),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF87171),
            ),
            onPressed: () async {
              // Reset database singleton to clear cached data
              DatabaseService.resetInstance();

              // Logout user
              await ctx.read<AuthProvider>().logout();

              if (ctx.mounted) {
                Navigator.pop(ctx); // tutup dialog

                // Gunakan MaterialPageRoute untuk menghindari animasi curve issues
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AppRouter()),
                  (route) => false,
                );
              }
            },
            child: Text(
              AppLocalizations.tr('logout'),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _handleDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Text(
          'Hapus Akun & Data?',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppTheme.textP(context),
          ),
        ),
        content: Text(
          'Seluruh data Anda termasuk profil, hasil MBTI, dan rekaman emosi akan dihapus secara permanen dari perangkat ini. Lanjutkan?',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppTheme.textS(context),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppLocalizations.tr('cancel'),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: AppTheme.textS(context),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () async {
              // Hapus database lokal
              await DatabaseService.deleteDatabase();

              // Bersihkan token auth & shared prefs (misal status onboarding pertama)
              if (ctx.mounted) {
                await ctx.read<AuthProvider>().logout();
              }
              await StorageService.resetOnboarding();

              if (ctx.mounted) {
                Navigator.pop(ctx); // tutup dialog

                // Kembali ke start
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AppRouter()),
                  (route) => false,
                );
              }
            },
            child: Text(
              'Ya, Hapus',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
