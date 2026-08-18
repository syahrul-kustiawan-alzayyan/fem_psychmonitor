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

  const ResultSection({
    super.key,
    required this.onComplete,
    required this.userName,
  });

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
            _buildHeader(
              c,
              loc('result_title'),
              user.name,
              loc('user'),
              loc('result_subtitle'),
            ),
            const SizedBox(height: 24),

            _buildPsyHero(c, state.psyScore, loc),

            if (state.bigFiveScores.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildBigFiveCard(context, state),
            ],

            const SizedBox(height: 24),
            _buildRecommendationsCard(context, state.psyScore, loc),

            const SizedBox(height: 30),
            ResonancePillButton(
              c: c,
              label: loc('completed'),
              loading: state.isSaving,
              onTap: state.isSaving ? null : onComplete,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    ResonanceColors c,
    String title,
    String name,
    String userLabel,
    String subtitle,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - t)),
          child: child,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.primaryContainer.withValues(alpha: 0.35),
              shape: BoxShape.circle,
              border: Border.all(color: c.primary.withValues(alpha: 0.4)),
              boxShadow: const [
                BoxShadow(color: Color(0x1424161C), offset: Offset(2, 2)),
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
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 25,
              fontWeight: FontWeight.w700,
              color: c.onSurface,
              height: 1.2,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Halo ${name.isEmpty ? userLabel : name}$subtitle',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: c.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPsyHero(
    ResonanceColors c,
    int psyScore,
    String Function(String) loc,
  ) {
    final displayScore100 = ((60 - psyScore) / 60 * 100).round().clamp(0, 100);

    final (
      category,
      advice,
      cardColor,
      categoryIcon,
    ) = switch (displayScore100) {
      >= 76 => (
        loc('psych_excellent'),
        loc('overall_exc_1'),
        const Color(0xFF22C55E),
        PhosphorIconsRegular.checkCircle,
      ),
      >= 51 => (
        loc('psych_good'),
        loc('overall_good_2'),
        const Color(0xFF84CC16),
        PhosphorIconsRegular.info,
      ),
      >= 26 => (
        loc('psych_fair'),
        loc('overall_fair_2'),
        const Color(0xFFF59E0B),
        PhosphorIconsRegular.warning,
      ),
      _ => (
        loc('psych_needs_attention'),
        loc('overall_attn_2'),
        const Color(0xFFEF4444),
        PhosphorIconsRegular.warningCircle,
      ),
    };

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - t)),
          child: child,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
        decoration: BoxDecoration(
          color: c.surfaceLowest,
          border: Border.all(color: c.outlineVariant),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Color(0x1424161C), offset: Offset(2, 2)),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  PhosphorIconsRegular.heart,
                  size: 15,
                  color: c.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  loc('result_mental_health').toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: c.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildScoreRing(c, displayScore100, cardColor),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: cardColor.withValues(alpha: 0.1),
                border: Border.all(color: cardColor.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(categoryIcon, size: 15, color: cardColor),
                  const SizedBox(width: 7),
                  Text(
                    category,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: cardColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              advice,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: c.onSurface,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreRing(ResonanceColors c, int score, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final shown = value.round();
        return Container(
          width: 168,
          height: 168,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.surfaceLowest,
            shape: BoxShape.circle,
            border: Border.all(color: c.outlineVariant),
            boxShadow: const [
              BoxShadow(color: Color(0x1424161C), offset: Offset(2, 2)),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: (value / 100).clamp(0.0, 1.0),
                  strokeWidth: 11,
                  strokeCap: StrokeCap.round,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$shown',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: c.onSurface,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '/ 100',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBigFiveCard(BuildContext context, OnboardingState state) {
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
      (a, b) => (state.bigFiveScores[a] ?? 0) >= (state.bigFiveScores[b] ?? 0)
          ? a
          : b,
    );
    final topInfo = dimLabels[highestDim]!;
    final topScore = state.bigFiveScores[highestDim] ?? 0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - t)),
          child: child,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.surfaceLowest,
          border: Border.all(color: c.outlineVariant),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Color(0x1424161C), offset: Offset(2, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: c.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    PhosphorIconsRegular.fingerprint,
                    size: 17,
                    color: c.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  AppLocalizations.tr('result_bigfive'),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  'OCEAN',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: c.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: topInfo.$2.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: topInfo.$2.withValues(alpha: 0.28)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: topInfo.$2,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Center(
                      child: Text(
                        highestDim,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.tr('bigfive_dominant'),
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: c.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          topInfo.$1,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: c.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    topScore.toStringAsFixed(1),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: topInfo.$2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ...dimensions.map((d) {
              final info = dimLabels[d]!;
              final color = info.$2;
              final score = state.bigFiveScores[d] ?? 0;
              final ratio = ((score - 1) / 4).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              d,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: color,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            info.$1,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: c.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          score.toStringAsFixed(1),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 6,
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
      ),
    );
  }

  Widget _buildRecommendationsCard(
    BuildContext context,
    int psyScore,
    String Function(String) loc,
  ) {
    final c = ResonanceColors.of(context);

    final (cardColor, recommendations) = switch (((60 - psyScore) / 60 * 100)
        .round()
        .clamp(0, 100)) {
      >= 76 => (
        const Color(0xFF22C55E),
        [loc('result_rec_1'), loc('result_rec_2'), loc('result_rec_3')],
      ),
      >= 51 => (
        const Color(0xFF84CC16),
        [loc('result_rec_4'), loc('result_rec_5'), loc('result_rec_6')],
      ),
      >= 26 => (
        const Color(0xFFF59E0B),
        [loc('result_rec_7'), loc('result_rec_8'), loc('result_rec_9')],
      ),
      _ => (
        const Color(0xFFEF4444),
        [loc('result_rec_10'), loc('result_rec_11'), loc('result_rec_12')],
      ),
    };

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - t)),
          child: child,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.surfaceLowest,
          border: Border.all(color: c.outlineVariant),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Color(0x1424161C), offset: Offset(2, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: cardColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    PhosphorIconsRegular.lightbulb,
                    size: 17,
                    color: cardColor,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  loc('result_recommendations'),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recommendations.map(
              (rec) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: cardColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        PhosphorIconsRegular.check,
                        size: 12,
                        color: cardColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          rec,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            color: c.onSurface,
                            height: 1.5,
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
      ),
    );
  }
}
