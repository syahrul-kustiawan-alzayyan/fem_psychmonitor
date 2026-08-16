import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../providers/locale_provider.dart';
import '../../theme/resonance_colors.dart';
import 'onboarding_state.dart';

class ResultSection extends StatelessWidget {
  final VoidCallback onComplete;
  final String userName;

  const ResultSection({super.key, required this.onComplete, required this.userName});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardingState>();
    final c = ResonanceColors.of(context);
    final loc = AppLocalizations.tr;
    final isEn = context.watch<LocaleProvider>().locale == 'en';

    final user = AppUser(
      name: userName,
      bigFiveScores: state.bigFiveScores,
      psychologicalScore: state.psyScore,
      createdAt: DateTime.now(),
    );

    return Container(
      color: c.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            ResonanceEyebrow(c: c, label: isEn ? '04 / RESULT' : '04 / HASIL'),
            const SizedBox(height: 16),
            // HEADER
            ResonanceCard(
              c: c,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: c.primaryContainer,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.outlineVariant),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1424161C),
                          offset: Offset(1.5, 1.5),
                        ),
                      ],
                    ),
                    child: Icon(
                      PhosphorIconsRegular.sparkle,
                      color: c.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    loc('result_title'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      color: c.onSurface,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Halo ${user.name.isEmpty ? loc('user') : user.name}${loc('result_subtitle')}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      color: c.onSurfaceVariant,
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
            _buildPsyResultCard(context, state.psyScore),

            const SizedBox(height: 30),
            ResonancePillButton(
              c: c,
              label: loc('completed'),
              trailingIcon: PhosphorIconsRegular.check,
              loading: state.isSaving,
              onTap: state.isSaving ? null : onComplete,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBigFiveResultCard(BuildContext context, OnboardingState state) {
    final c = ResonanceColors.of(context);
    final dimLabels = {
      'O': (AppLocalizations.tr('bigfive_dim_o'), const Color(0xFF8B5CF6)),
      'C': (AppLocalizations.tr('bigfive_dim_c'), const Color(0xFF3B82F6)),
      'E': (AppLocalizations.tr('bigfive_dim_e'), const Color(0xFFF59E0B)),
      'A': (AppLocalizations.tr('bigfive_dim_a'), const Color(0xFF10B981)),
      'N': (AppLocalizations.tr('bigfive_dim_n'), const Color(0xFFEF4444)),
    };

    final dimensions = ['O', 'C', 'E', 'A', 'N'];
    final highestDim = dimensions.reduce(
      (a, b) => (state.bigFiveScores[a] ?? 0) >= (state.bigFiveScores[b] ?? 0) ? a : b,
    );

    return ResonanceCard(
      c: c,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.primaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.outlineVariant),
                ),
                child: Icon(
                  PhosphorIconsRegular.fingerprint,
                  size: 20,
                  color: c.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.tr('result_bigfive'),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: c.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dimLabels[highestDim]!.$2,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                dimLabels[highestDim]!.$1,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: c.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: c.outlineVariant),
          const SizedBox(height: 18),
          ...dimensions.map((d) {
            final info = dimLabels[d]!;
            final color = info.$2;
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
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            info.$1,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: c.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$score $level',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ratio.clamp(0.0, 1.0),
                      minHeight: 7,
                      backgroundColor: color.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
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

  Widget _buildPsyResultCard(BuildContext context, int psyScore) {
    final c = ResonanceColors.of(context);
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
      categoryIcon = PhosphorIconsRegular.checkCircle;
      recommendations = [
        AppLocalizations.tr('result_rec_1'),
        AppLocalizations.tr('result_rec_2'),
        AppLocalizations.tr('result_rec_3'),
      ];
    } else if (displayScore100 >= 51) {
      category = AppLocalizations.tr('psych_good');
      advice = AppLocalizations.tr('overall_good_2');
      cardColor = const Color(0xFF84CC16);
      categoryIcon = PhosphorIconsRegular.info;
      recommendations = [
        AppLocalizations.tr('result_rec_4'),
        AppLocalizations.tr('result_rec_5'),
        AppLocalizations.tr('result_rec_6'),
      ];
    } else if (displayScore100 >= 26) {
      category = AppLocalizations.tr('psych_fair');
      advice = AppLocalizations.tr('overall_fair_2');
      cardColor = const Color(0xFFF59E0B);
      categoryIcon = PhosphorIconsRegular.warning;
      recommendations = [
        AppLocalizations.tr('result_rec_7'),
        AppLocalizations.tr('result_rec_8'),
        AppLocalizations.tr('result_rec_9'),
      ];
    } else {
      category = AppLocalizations.tr('psych_needs_attention');
      advice = AppLocalizations.tr('overall_attn_2');
      cardColor = const Color(0xFFEF4444);
      categoryIcon = PhosphorIconsRegular.warningCircle;
      recommendations = [
        AppLocalizations.tr('result_rec_10'),
        AppLocalizations.tr('result_rec_11'),
        AppLocalizations.tr('result_rec_12'),
      ];
    }

    return ResonanceCard(
      c: c,
      padding: const EdgeInsets.all(24),
      accent: cardColor,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: cardColor.withValues(alpha: 0.25)),
                ),
                child: Icon(categoryIcon, size: 20, color: cardColor),
              ),
              const SizedBox(width: 12),
              Text(
                loc('result_mental_health'),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: c.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: displayScore100 / 100,
                  strokeWidth: 12,
                  backgroundColor: cardColor.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(cardColor),
                ),
              ),
              Column(
                children: [
                  Text(
                    '$displayScore100',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: cardColor,
                    ),
                  ),
                  Text(
                    '/ 100',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: c.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
            decoration: BoxDecoration(
              border: Border.all(color: cardColor.withValues(alpha: 0.35)),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              category,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: cardColor,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            advice,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: c.onSurface,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: c.outlineVariant),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              loc('result_recommendations'),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: c.onSurface,
              ),
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
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: c.onSurface,
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