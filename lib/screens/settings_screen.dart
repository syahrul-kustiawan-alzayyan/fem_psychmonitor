import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../models/emotion_model.dart';
import '../models/user_model.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/premium_provider.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'premium_screen.dart';
import 'profile_screen.dart';

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
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          leadingWidth: 0,
          title: Row(
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppTheme.primaryGradient.createShader(bounds),
                child: const Icon(
                  Icons.settings_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppTheme.primaryGradient.createShader(
                      Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                    ),
                child: Text(
                  AppLocalizations.tr('settings_title'),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          iconTheme: IconThemeData(color: AppTheme.textP(context)),
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
              // ── Section: Profil ─────────────────────────────
              _buildSectionLabel(context, AppLocalizations.tr('profile_menu')),
              const SizedBox(height: 10),

              _buildSettingsCard(
                context,
                children: [
                  // Profile
                  _buildSettingsTile(
                    context,
                    icon: Icons.person_outline_rounded,
                    iconColor: const Color.fromARGB(255, 251, 115, 142),
                    title: AppLocalizations.tr('profile_menu'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Consumer<PremiumProvider>(
                builder: (context, premium, _) {
                  if (premium.isPremium) {
                    return _buildSettingsCard(
                      context,
                      children: [_buildPremiumActiveTile(context, premium)],
                    );
                  }
                  return _buildSettingsCard(
                    context,
                    children: [_buildPremiumUpgradeTile(context)],
                  );
                },
              ),

              const SizedBox(height: 24),

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
                    iconColor: AppTheme.primaryColor,
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
                    iconColor: AppTheme.primaryColor,
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
                    iconColor: AppTheme.primaryColor,
                    title: AppLocalizations.tr('terms_services'),
                    subtitle: AppLocalizations.tr('terms_desc'),
                    onTap: () => _showTerms(context),
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
                  // Backup Data
                  _buildSettingsTile(
                    context,
                    icon: Icons.cloud_upload_rounded,
                    iconColor: AppTheme.primaryColor,
                    title: AppLocalizations.tr('backup_data'),
                    subtitle: AppLocalizations.tr('backup_data_desc'),
                    onTap: () => _handleBackupData(context),
                  ),
                  _buildDivider(context),
                  // Restore Data
                  _buildSettingsTile(
                    context,
                    icon: Icons.cloud_download_rounded,
                    iconColor: AppTheme.primaryColor,
                    title: AppLocalizations.tr('restore_data'),
                    subtitle: AppLocalizations.tr('restore_data_desc'),
                    onTap: () => _handleRestoreData(context),
                  ),
                  _buildDivider(context),
                  // Delete Account
                  _buildSettingsTile(
                    context,
                    icon: Icons.delete_forever_rounded,
                    iconColor: const Color(0xFFEF4444),
                    title: AppLocalizations.tr('delete_account_data'),
                    subtitle: AppLocalizations.tr('delete_account_desc'),
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
    return ShaderMask(
      shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 1.2,
        ),
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
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.08),
        ),
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
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
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
                  color: isSelected ? Colors.white : AppTheme.primaryDark,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPremiumActiveTile(
    BuildContext context,
    PremiumProvider premium,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PremiumScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.verified_rounded,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.locale.startsWith('en')
                        ? 'Premium Active'
                        : 'Premium Aktif',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    premium.expiryDate != null
                        ? _formatRemainingTime(premium.expiryDate!)
                        : (AppLocalizations.locale.startsWith('en')
                            ? 'Lifetime'
                            : 'Seumur Hidup'),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textS(context),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'ACTIVE',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumUpgradeTile(BuildContext context) {
    return _buildSettingsTile(
      context,
      icon: Icons.star_border_rounded,
      iconColor: AppTheme.primaryColor,
      title: AppLocalizations.locale.startsWith('en')
          ? 'Upgrade to Premium'
          : 'Upgrade ke Premium',
      subtitle: AppLocalizations.locale.startsWith('en')
          ? 'Remove ads & unlock features'
          : 'Hilangkan iklan & buka fitur',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PremiumScreen()),
        );
      },
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
        color: AppTheme.secondaryColor,
      ),
      (
        icon: Icons.bar_chart_rounded,
        title: AppLocalizations.tr('guide_step3_title'),
        desc: AppLocalizations.tr('guide_step3_desc'),
        color: AppTheme.primaryDark,
      ),
      (
        icon: Icons.tips_and_updates_rounded,
        title: AppLocalizations.tr('guide_step4_title'),
        desc: AppLocalizations.tr('guide_step4_desc'),
        color: AppTheme.primaryColor,
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

  Future<void> _handleBackupData(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      final user = await DatabaseService.getUser();
      final recordings = await DatabaseService.getRecordings();

      final backupData = {
        'app': 'Fem-Psych Monitor',
        'backup_date': DateTime.now().toIso8601String(),
        'user': user != null
            ? {
                'name': user.name,
                'mbti_type': user.mbtiType,
                'mbti_scores': user.mbtiScores,
                'psychological_score': user.psychologicalScore,
                'created_at': user.createdAt.toIso8601String(),
              }
            : {},
        'recordings': recordings
            .map(
              (r) => {
                'date': r.date.toIso8601String(),
                'dominant_emotion': r.dominantEmotion.name,
                'confidence': r.confidence,
                'suggestion': r.suggestion,
                'audio_emotions': r.audioEmotions.map(
                  (k, v) => MapEntry(k.name, v),
                ),
                'transcript_emotions': r.transcriptEmotions.map(
                  (k, v) => MapEntry(k.name, v),
                ),
                'transcript_text': r.transcriptText,
                'duration_seconds': r.durationSeconds,
              },
            )
            .toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      if (!context.mounted) return;
      Navigator.of(context).pop(); // tutup loading

      final outputFile = await FilePicker.platform.saveFile(
        dialogTitle: AppLocalizations.tr('save_backup'),
        fileName: 'fem_psych_backup.json',
        bytes: utf8.encode(jsonString),
      );

      if (outputFile == null) return; // user cancelled

      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surface(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_done_rounded,
                  color: AppTheme.primaryColor,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.tr('backup_success'),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textP(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${recordings.length} rekaman dibackup',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.textS(context),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                  child: Text(AppLocalizations.tr('close')),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backup gagal: $e')));
    }
  }

  Future<void> _handleRestoreData(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: AppLocalizations.tr('select_backup_file'),
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.single.path;
      if (filePath == null) return;

      final file = File(filePath);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surface(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          title: Text(
            AppLocalizations.tr('restore_confirm'),
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppTheme.textP(context),
            ),
          ),
          content: Text(
            AppLocalizations.tr('restore_confirm_desc'),
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.textS(context),
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
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
                backgroundColor: AppTheme.primaryColor,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                AppLocalizations.tr('restore'),
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      // Restore user data
      final userData = data['user'] as Map<String, dynamic>?;
      if (userData != null && userData.isNotEmpty) {
        final appUser = AppUser(
          name: userData['name'] as String? ?? '',
          mbtiType: userData['mbti_type'] as String? ?? '',
          mbtiScores:
              (userData['mbti_scores'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(k, (v as num).toInt()),
              ) ??
              {},
          psychologicalScore: userData['psychological_score'] as int?,
          createdAt:
              DateTime.tryParse(userData['created_at'] as String? ?? '') ??
              DateTime.now(),
        );
        await DatabaseService.insertUser(appUser);
      }

      // Restore recordings
      final recordingsList = data['recordings'] as List<dynamic>? ?? [];
      for (final r in recordingsList) {
        final rec = r as Map<String, dynamic>;
        final audioMap =
            (rec['audio_emotions'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(
                EmotionType.values.firstWhere(
                  (e) => e.name == k,
                  orElse: () => EmotionType.neutral,
                ),
                (v as num).toDouble(),
              ),
            ) ??
            {};
        final textMap =
            (rec['transcript_emotions'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(
                EmotionType.values.firstWhere(
                  (e) => e.name == k,
                  orElse: () => EmotionType.neutral,
                ),
                (v as num).toDouble(),
              ),
            ) ??
            {};

        final recordingData = RecordingData(
          userId: 0,
          date:
              DateTime.tryParse(rec['date'] as String? ?? '') ?? DateTime.now(),
          dominantEmotion: EmotionType.values.firstWhere(
            (e) => e.name == rec['dominant_emotion'],
            orElse: () => EmotionType.neutral,
          ),
          confidence: (rec['confidence'] as num?)?.toDouble() ?? 0.0,
          suggestion: rec['suggestion'] as String? ?? '',
          audioEmotions: audioMap,
          transcriptEmotions: textMap,
          transcriptText: rec['transcript_text'] as String? ?? '',
          durationSeconds: (rec['duration_seconds'] as num?)?.toInt() ?? 0,
        );
        await DatabaseService.insertRecording(recordingData);
      }

      if (!context.mounted) return;
      Navigator.of(context).pop(); // tutup loading

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Restore selesai: ${recordingsList.length} rekaman dipulihkan',
          ),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Restore gagal: $e')));
    }
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
          AppLocalizations.tr('delete_account_title'),
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppTheme.textP(context),
          ),
        ),
        content: Text(
          AppLocalizations.tr('delete_account_message'),
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

              // Hapus akun di Firebase dan bersihkan lokal (logout)
              if (ctx.mounted) {
                await ctx.read<AuthProvider>().deleteAccount();
              }

              // Reset status onboarding
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
              AppLocalizations.tr('yes_delete'),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRemainingTime(DateTime expiry) {
    final now = DateTime.now();
    final diff = expiry.difference(now);

    if (diff.isNegative) {
      return AppLocalizations.locale.startsWith('en')
          ? 'Expired'
          : 'Kedaluwarsa';
    }

    if (diff.inDays > 0) {
      return AppLocalizations.locale.startsWith('en')
          ? '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} remaining'
          : 'Sisa ${diff.inDays} hari';
    } else if (diff.inHours > 0) {
      return AppLocalizations.locale.startsWith('en')
          ? '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} remaining'
          : 'Sisa ${diff.inHours} jam';
    } else if (diff.inMinutes > 0) {
      return AppLocalizations.locale.startsWith('en')
          ? '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} remaining'
          : 'Sisa ${diff.inMinutes} menit';
    } else {
      return AppLocalizations.locale.startsWith('en')
          ? 'Expired'
          : 'Kedaluwarsa';
    }
  }
}
