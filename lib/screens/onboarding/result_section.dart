import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/theme_provider.dart';
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
    final isDark = context.watch<ThemeProvider>().isDark;
    final loc = AppLocalizations.tr;

    final user = AppUser(
      name: userName,
      bigFiveScores: state.bigFiveScores,
      psychologicalScore: state.psyScore,
      createdAt: DateTime.now(),
    );

    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppTheme.darkGradientBackground : AppTheme.lightGradientBackground,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 20),
              // HEADER
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : null,
                  gradient: isDark ? null : AppTheme.lightGradientBackground,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 12),
                    Text(
                      loc('result_title'),
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.textP(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Halo ${user.name.isEmpty ? loc('user') : user.name}${loc('result_subtitle')}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.textS(context),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // BIG FIVE RESULT CARD
              if (state.bigFiveScores.isNotEmpty) ...[
                _buildBigFiveResultCard(context, state),
                const SizedBox(height: 24),
              ],

              // PSYCHOLOGICAL RESULT
              _buildEnhancedPsyResultCard(context, state.psyScore),

              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: state.isSaving ? null : onComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    elevation: 4,
                    shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                  ),
                  child: state.isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              loc('completed'),
                              style: GoogleFonts.poppins(
                                fontSize: 17,
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
      ),
    );
  }

  Widget _buildBigFiveResultCard(BuildContext context, OnboardingState state) {
    final dimLabels = {
      'O': ('🎨', AppLocalizations.tr('bigfive_dim_o'), const Color(0xFF8B5CF6)),
      'C': ('📋', AppLocalizations.tr('bigfive_dim_c'), const Color(0xFF3B82F6)),
      'E': ('⚡', AppLocalizations.tr('bigfive_dim_e'), const Color(0xFFF59E0B)),
      'A': ('🤝', AppLocalizations.tr('bigfive_dim_a'), const Color(0xFF10B981)),
      'N': ('🌊', AppLocalizations.tr('bigfive_dim_n'), const Color(0xFFEF4444)),
    };

    final dimensions = ['O', 'C', 'E', 'A', 'N'];
    final highestDim = dimensions.reduce(
      (a, b) => (state.bigFiveScores[a] ?? 0) >= (state.bigFiveScores[b] ?? 0) ? a : b,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology_rounded, size: 32, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.tr('result_bigfive'),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '${dimLabels[highestDim]!.$1} ${dimLabels[highestDim]!.$2}',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.3),
            margin: const EdgeInsets.symmetric(horizontal: 20),
          ),
          const SizedBox(height: 20),
          ...dimensions.map((d) {
            final info = dimLabels[d]!;
            final score = state.bigFiveScores[d] ?? 0;
            final level = score >= 3.5
                ? AppLocalizations.tr('bigfive_high')
                : (score <= 2.5
                    ? AppLocalizations.tr('bigfive_low')
                    : AppLocalizations.tr('bigfive_moderate'));
            final ratio = (score - 1) / 4;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${info.$1} ${info.$2}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      Text(
                        '$score • $level',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ratio.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEnhancedPsyResultCard(BuildContext context, int psyScore) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final loc = AppLocalizations.tr;
    String category;
    String advice;
    Color cardColor;
    IconData categoryIcon;
    List<String> recommendations;

    final displayScore100 = ((60 - psyScore) / 60 * 100).round();

    if (displayScore100 >= 76) {
      category = AppLocalizations.tr('psych_excellent');
      advice = AppLocalizations.tr('overall_exc_1');
      cardColor = const Color(0xFF22C55E);
      categoryIcon = Icons.check_circle_rounded;
      recommendations = [
        AppLocalizations.tr('result_rec_1'),
        AppLocalizations.tr('result_rec_2'),
        AppLocalizations.tr('result_rec_3'),
      ];
    } else if (displayScore100 >= 51) {
      category = AppLocalizations.tr('psych_good');
      advice = AppLocalizations.tr('overall_good_2');
      cardColor = const Color(0xFF84CC16);
      categoryIcon = Icons.info_outline_rounded;
      recommendations = [
        AppLocalizations.tr('result_rec_4'),
        AppLocalizations.tr('result_rec_5'),
        AppLocalizations.tr('result_rec_6'),
      ];
    } else if (displayScore100 >= 26) {
      category = AppLocalizations.tr('psych_fair');
      advice = AppLocalizations.tr('overall_fair_2');
      cardColor = const Color(0xFFF59E0B);
      categoryIcon = Icons.warning_amber_rounded;
      recommendations = [
        AppLocalizations.tr('result_rec_7'),
        AppLocalizations.tr('result_rec_8'),
        AppLocalizations.tr('result_rec_9'),
      ];
    } else {
      category = AppLocalizations.tr('psych_needs_attention');
      advice = AppLocalizations.tr('overall_attn_2');
      cardColor = const Color(0xFFEF4444);
      categoryIcon = Icons.error_rounded;
      recommendations = [
        AppLocalizations.tr('result_rec_10'),
        AppLocalizations.tr('result_rec_11'),
        AppLocalizations.tr('result_rec_12'),
      ];
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.surface(context),
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: cardColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(categoryIcon, size: 32, color: cardColor),
              ),
              const SizedBox(width: 12),
              Text(
                loc('result_mental_health'),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textP(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: displayScore100 / 100,
                  strokeWidth: 12,
                  backgroundColor: cardColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(cardColor),
                ),
              ),
              Column(
                children: [
                  Text(
                    '$displayScore100',
                    style: GoogleFonts.poppins(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: cardColor,
                    ),
                  ),
                  Text(
                    '/ 100',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textS(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              category,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cardColor,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            advice,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              color: AppTheme.textP(context),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 1.5,
            color: AppTheme.surfVar(context).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 20),
          Text(
            loc('result_recommendations'),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textP(context),
            ),
          ),
          const SizedBox(height: 12),
          ...recommendations.map(
            (rec) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: cardColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rec,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppTheme.textP(context),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
