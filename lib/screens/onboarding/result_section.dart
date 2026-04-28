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

    // Mock an AppUser just to use its getters (nickname, advice, description)
    final user = AppUser(
      name: userName,
      mbtiType: state.mbtiType,
      mbtiScores: state.mbtiScores,
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
            
            // MBTI RESULT CARD
            Container(
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
                        loc('result_mbti'),
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
                    state.mbtiType,
                    style: GoogleFonts.poppins(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 10,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                  const SizedBox(height: 20),
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.3),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    user.mbtiDescription,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      color: Colors.white.withValues(alpha: 0.95),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // MBTI SCORES BREAKDOWN
            if (state.mbtiScores.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : AppTheme.surface(context),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc('result_mbti_detail'),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.textP(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMbtiScoreBar(context, 'E', 'I', state.mbtiScores['E'] ?? 0, state.mbtiScores['I'] ?? 0, AppTheme.primaryColor),
                    const SizedBox(height: 12),
                    _buildMbtiScoreBar(context, 'S', 'N', state.mbtiScores['S'] ?? 0, state.mbtiScores['N'] ?? 0, AppTheme.secondaryColor),
                    const SizedBox(height: 12),
                    _buildMbtiScoreBar(context, 'T', 'F', state.mbtiScores['T'] ?? 0, state.mbtiScores['F'] ?? 0, Colors.orange),
                    const SizedBox(height: 12),
                    _buildMbtiScoreBar(context, 'J', 'P', state.mbtiScores['J'] ?? 0, state.mbtiScores['P'] ?? 0, Colors.purple),
                  ],
                ),
              ),
            const SizedBox(height: 32),

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
])),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMbtiScoreBar(BuildContext context, String leftLabel, String rightLabel, int leftScore, int rightScore, Color color) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final total = leftScore + rightScore;
    final leftRatio = total > 0 ? leftScore / total : 0.5;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              leftLabel,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: leftRatio >= 0.5 ? color : AppTheme.textS(context),
              ),
            ),
            Text(
              '$leftScore : $rightScore',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textS(context),
              ),
            ),
            Text(
              rightLabel,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: leftRatio < 0.5 ? color : AppTheme.textS(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppTheme.surfVar(context),
          ),
          child: Row(
            children: [
              Expanded(
                flex: (leftRatio * 100).round(),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: ((1 - leftRatio) * 100).round(),
                child: Container(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.3),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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

    if (displayScore100 >= 75) {
      category = AppLocalizations.tr('psych_excellent');
      advice = AppLocalizations.tr('overall_exc_1');
      cardColor = const Color(0xFF22C55E);
      categoryIcon = Icons.check_circle_rounded;
      recommendations = [
        AppLocalizations.tr('result_rec_1'),
        AppLocalizations.tr('result_rec_2'),
        AppLocalizations.tr('result_rec_3'),
      ];
    } else if (displayScore100 >= 50) {
      category = AppLocalizations.tr('psych_good');
      advice = AppLocalizations.tr('overall_good_2');
      cardColor = const Color(0xFF84CC16);
      categoryIcon = Icons.info_outline_rounded;
      recommendations = [
        AppLocalizations.tr('result_rec_4'),
        AppLocalizations.tr('result_rec_5'),
        AppLocalizations.tr('result_rec_6'),
      ];
    } else if (displayScore100 >= 25) {
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
          // Score display with circular indicator
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
