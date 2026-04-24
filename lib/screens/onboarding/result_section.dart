import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';
import 'onboarding_state.dart';

class ResultSection extends StatelessWidget {
  final VoidCallback onComplete;
  final String userName;

  const ResultSection({super.key, required this.onComplete, required this.userName});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardingState>();

    // Mock an AppUser just to use its getters (nickname, advice, description)
    final user = AppUser(
      name: userName,
      mbtiType: state.mbtiType,
      mbtiScores: state.mbtiScores,
      psychologicalScore: state.psyScore,
      createdAt: DateTime.now(),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // MBTI RESULT
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 8),
                  Text(
                    'Hasil MBTI-mu!',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textP(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Halo ${user.name.isEmpty ? AppLocalizations.tr('user') : user.name}, ${AppLocalizations.tr("mbti_result")}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      color: AppTheme.textS(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.psychology_rounded, size: 36, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.mbtiType,
                    style: GoogleFonts.poppins(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.mbtiNickname,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.mbtiDescription,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),

            // PSYCHOLOGICAL RESULT
            _buildPsyResultCard(context, state.psyScore),

            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: state.isSaving ? null : onComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 4,
                  shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                ),
                child: state.isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Selesai 🚀',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPsyResultCard(BuildContext context, int psyScore) {
    String category;
    String advice;
    Color cardColor;
    IconData categoryIcon;

    final displayScore100 = ((60 - psyScore) / 60 * 100).round();

    if (displayScore100 >= 75) {
      category = AppLocalizations.tr('psych_excellent');
      advice = AppLocalizations.tr('overall_exc_1');
      cardColor = const Color(0xFF22C55E);
      categoryIcon = Icons.check_circle_rounded;
    } else if (displayScore100 >= 50) {
      category = AppLocalizations.tr('psych_good');
      advice = AppLocalizations.tr('overall_good_2');
      cardColor = const Color(0xFF84CC16);
      categoryIcon = Icons.info_outline_rounded;
    } else if (displayScore100 >= 25) {
      category = AppLocalizations.tr('psych_fair');
      advice = AppLocalizations.tr('overall_fair_2');
      cardColor = const Color(0xFFF59E0B);
      categoryIcon = Icons.warning_amber_rounded;
    } else {
      category = AppLocalizations.tr('psych_needs_attention');
      advice = AppLocalizations.tr('overall_attn_2');
      cardColor = const Color(0xFFEF4444);
      categoryIcon = Icons.error_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(categoryIcon, size: 56, color: cardColor),
          const SizedBox(height: 16),
          Text(
            'Skor Anda: $displayScore100 / 100',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: cardColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            category,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: cardColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            advice,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.textP(context),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
