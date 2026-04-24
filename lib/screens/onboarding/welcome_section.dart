import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class WelcomeSection extends StatelessWidget {
  final VoidCallback onNext;

  const WelcomeSection({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          // Hero Illustration / Logo Section
          Stack(
            alignment: Alignment.center,
            children: [
              // Subtle decorative background
              Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withValues(alpha: 0.05),
                ),
              ),
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          // Modern Welcome Typography
          Text(
            'Fem-Psych Monitor',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.textP(context),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Selamat Datang! 👋',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          // Value Proposition Cards
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius: BorderRadius.circular(28),
              boxShadow: AppTheme.cardShadow,
              border: Border.all(
                color: AppTheme.surfVar(context),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                _buildWelcomeFeatureItem(
                  context: context,
                  icon: Icons.graphic_eq_rounded,
                  color: AppTheme.primaryColor,
                  title: 'Analisis Suara & Emosi',
                  description: 'Deteksi emosi kamu secara real-time lewat AI.',
                ),
                const SizedBox(height: 20),
                _buildWelcomeFeatureItem(
                  context: context,
                  icon: Icons.psychology_rounded,
                  color: AppTheme.secondaryColor,
                  title: 'Pemahaman Epik',
                  description: 'Pantau kesehatan riwayat emosi dengan terstruktur.',
                ),
                const SizedBox(height: 20),
                _buildWelcomeFeatureItem(
                  context: context,
                  icon: Icons.self_improvement_rounded,
                  color: Colors.green.shade500,
                  title: 'Pengembangan Diri',
                  description: 'Saran tindakan khusus untuk setiap fase hidup.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Action Button
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 4,
                shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.tr('start_now'),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildWelcomeFeatureItem({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textP(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.textS(context),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
