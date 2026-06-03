import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../auth_screen.dart';

class WelcomeSection extends StatelessWidget {
  final VoidCallback onNext;

  const WelcomeSection({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final loc = AppLocalizations.tr;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? AppTheme.darkGradientBackground
            : AppTheme.lightGradientBackground,
      ),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Consumer<LocaleProvider>(
                    builder: (context, locale, _) {
                      final isEn = locale.locale == 'en';
                      return GestureDetector(
                        onTap: () => locale.toggleLocale(),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: AppTheme.surface(context),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _langOption(context, 'ID', !isEn, () => locale.setLocale('id')),
                              const SizedBox(width: 2),
                              _langOption(context, 'EN', isEn, () => locale.setLocale('en')),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Hero Illustration / Logo Section
              Stack(
                alignment: Alignment.center,
                children: [
                  // Animated decorative rings
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.0),
                    duration: const Duration(seconds: 2),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppTheme.primaryColor.withValues(alpha: 0.08),
                                AppTheme.secondaryColor.withValues(alpha: 0.04),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Main logo container
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Modern Welcome Typography
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppTheme.primaryGradient.createShader(bounds),
                child: Text(
                  'Fem-Psych',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Monitor',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.textP(context),
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  loc('welcome_desc'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.textS(context),
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: 32),
              // Value Proposition Cards - Enhanced Glassmorphism style
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surface(context).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    _buildWelcomeFeatureItem(
                      context: context,
                      icon: Icons.graphic_eq_rounded,
                      color: AppTheme.primaryColor,
                      title: loc('feature_voice_title'),
                      description: loc('feature_voice_desc'),
                      iconBg: AppTheme.primaryColor.withValues(alpha: 0.12),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 1,
                      color: AppTheme.surfVar(context).withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 20),
                    _buildWelcomeFeatureItem(
                      context: context,
                      icon: Icons.psychology_rounded,
                      color: AppTheme.secondaryColor,
                      title: loc('feature_self_title'),
                      description: loc('feature_self_desc'),
                      iconBg: AppTheme.secondaryColor.withValues(alpha: 0.12),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 1,
                      color: AppTheme.surfVar(context).withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 20),
                    _buildWelcomeFeatureItem(
                      context: context,
                      icon: Icons.self_improvement_rounded,
                      color: Colors.green.shade600,
                      title: loc('feature_growth_title'),
                      description: loc('feature_growth_desc'),
                      iconBg: Colors.green.shade600.withValues(alpha: 0.12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Modern Action Button with enhanced design
              Container(
                width: double.infinity,
                height: 64,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onNext,
                    borderRadius: BorderRadius.circular(24),
                    splashColor: Colors.white.withValues(alpha: 0.2),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.tr('start_now'),
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    loc('has_account'),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textS(context),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () async {
                      await StorageService.setOnboardingComplete('');
                      if (!context.mounted) return;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const AuthScreen(),
                        ),
                      );
                    },
                    child: Text(
                      loc('login'),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langOption(BuildContext context, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : AppTheme.textS(context),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeFeatureItem({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required Color iconBg,
  }) {
    final isDark = context.watch<ThemeProvider>().isDark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.textP(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.textS(context),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
