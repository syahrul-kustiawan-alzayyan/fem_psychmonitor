import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../theme/resonance_colors.dart';
import 'onboarding_state.dart';

class BigFiveSection extends StatefulWidget {
  final VoidCallback onNext;

  const BigFiveSection({super.key, required this.onNext});

  @override
  State<BigFiveSection> createState() => _BigFiveSectionState();
}

class _BigFiveSectionState extends State<BigFiveSection> {
  int _pageIndex = 0;

  static const _dimColors = <String, Color>{
    'O': Color(0xFF8B5CF6),
    'C': Color(0xFF3B82F6),
    'E': Color(0xFFF59E0B),
    'A': Color(0xFF10B981),
    'N': Color(0xFFEF4444),
  };

  void _nextPage() {
    final state = context.read<OnboardingState>();
    final maxPage = state.bigFiveQuestions.length; // 0 = intro, 1..N = soal
    if (_pageIndex < maxPage) {
      setState(() => _pageIndex++);
    }
  }

  void _prevPage() => setState(() => _pageIndex--);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardingState>();
    final c = ResonanceColors.of(context);

    return Container(
      color: c.background,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: _pageIndex == 0
            ? _buildIntroPage(context, state)
            : _buildQuestionPage(context, state, _pageIndex - 1),
      ),
    );
  }

  // ── Halaman Intro ─────────────────────────────────────────────

  Widget _buildIntroPage(BuildContext context, OnboardingState state) {
    final c = ResonanceColors.of(context);
    final loc = AppLocalizations.tr;
    final isEn = context.watch<LocaleProvider>().locale == 'en';

    return SingleChildScrollView(
      key: const ValueKey('bigfive-intro'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          ResonanceEyebrow(
            c: c,
            label: isEn ? '02 / PERSONALITY' : '02 / KEPRIBADIAN',
          ),
          const SizedBox(height: 16),
          ResonanceCard(
            c: c,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
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
                        PhosphorIconsRegular.fingerprint,
                        color: c.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        loc('bigfive_what_is'),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: c.onSurface,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  loc('bigfive_what_is_desc'),
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    color: c.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ResonanceCard(
            c: c,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      loc('bigfive_5dimensions'),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: c.onSurface,
                      ),
                    ),
                    Text(
                      'OCEAN',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: c.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildDimensionRow(
                  context,
                  c,
                  'O',
                  loc('bigfive_dim_o'),
                  loc('bigfive_dim_o_desc'),
                ),
                _buildDimensionRow(
                  context,
                  c,
                  'C',
                  loc('bigfive_dim_c'),
                  loc('bigfive_dim_c_desc'),
                ),
                _buildDimensionRow(
                  context,
                  c,
                  'E',
                  loc('bigfive_dim_e'),
                  loc('bigfive_dim_e_desc'),
                ),
                _buildDimensionRow(
                  context,
                  c,
                  'A',
                  loc('bigfive_dim_a'),
                  loc('bigfive_dim_a_desc'),
                ),
                _buildDimensionRow(
                  context,
                  c,
                  'N',
                  loc('bigfive_dim_n'),
                  loc('bigfive_dim_n_desc'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Text(
            loc('bigfive_ready'),
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: c.onSurface,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          ResonancePillButton(
            c: c,
            label: loc('start_now'),
            trailingIcon: PhosphorIconsRegular.arrowRight,
            onTap: _nextPage,
          ),
          const SizedBox(height: 26),
        ],
      ),
    );
  }

  Widget _buildDimensionRow(
    BuildContext context,
    ResonanceColors c,
    String code,
    String title,
    String description,
  ) {
    final color = _dimColors[code]!;
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: c.surfaceLowest,
        border: Border.all(color: c.outlineVariant),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x1424161C), offset: Offset(2, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      code,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: c.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: c.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Halaman Pertanyaan ────────────────────────────────────────

  Widget _buildQuestionPage(
    BuildContext context,
    OnboardingState state,
    int qIndex,
  ) {
    if (state.bigFiveQuestions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (qIndex < 0 || qIndex >= state.bigFiveQuestions.length) {
      return const SizedBox.shrink();
    }

    final c = ResonanceColors.of(context);
    final q = state.bigFiveQuestions[qIndex];
    final selected = state.bigFiveAnswers[qIndex];
    final questionNum = qIndex + 1;
    final totalQuestions = state.bigFiveQuestions.length;
    final currentLocale = AppLocalizations.locale;
    final progress = questionNum / totalQuestions;
    final dimColor = _dimColors[q.dimension] ?? c.primary;
    final dimLabels = <String, String>{
      'O': currentLocale == 'id' ? 'Terbuka' : 'Openness',
      'C': currentLocale == 'id' ? 'Teliti' : 'Conscientiousness',
      'E': currentLocale == 'id' ? 'Ekstrover' : 'Extraversion',
      'A': currentLocale == 'id' ? 'Ramah' : 'Agreeableness',
      'N': currentLocale == 'id' ? 'Stabil' : 'Neuroticism',
    };
    final dimLabel = dimLabels[q.dimension] ?? q.dimension;
    final scaleLabels = <String>[
      '1 ${currentLocale == 'id' ? 'Sangat Tidak Setuju' : 'Strongly Disagree'}',
      '2 ${currentLocale == 'id' ? 'Tidak Setuju' : 'Disagree'}',
      '3 ${currentLocale == 'id' ? 'Netral' : 'Neutral'}',
      '4 ${currentLocale == 'id' ? 'Setuju' : 'Agree'}',
      '5 ${currentLocale == 'id' ? 'Sangat Setuju' : 'Strongly Agree'}',
    ];

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        key: ValueKey('bigfive-question-$qIndex'),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  ResonanceIconButton(
                    c: c,
                    icon: PhosphorIconsRegular.arrowLeft,
                    onTap: qIndex > 0 ? _prevPage : null,
                  ),
                  Expanded(
                    child: Center(
                      child: ResonanceChip(
                        c: c,
                        label: '$dimLabel $questionNum/$totalQuestions',
                        dotColor: dimColor,
                        textColor: dimColor,
                      ),
                    ),
                  ),
                  ResonanceIconButton(
                    c: c,
                    icon: PhosphorIconsRegular.house,
                    onTap: () => setState(() => _pageIndex = 0),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ResonanceProgressBar(c: c, progress: progress, color: dimColor),
              const SizedBox(height: 24),
              ResonanceCard(
                c: c,
                padding: const EdgeInsets.all(24),
                accent: dimColor,
                layered: false,
                softShadow: true,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: dimColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        q.dimension,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: dimColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      q.question,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w700,
                        color: c.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              ...List.generate(5, (i) {
                final value = i + 1;
                final isSelected = selected == value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () {
                      state.setBigFiveAnswer(qIndex, value);
                      if (qIndex < totalQuestions - 1) {
                        Future.delayed(
                          const Duration(milliseconds: 300),
                          _nextPage,
                        );
                      } else {
                        state.calculateBigFiveResult();
                        _pageIndex = 0;
                        widget.onNext();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? dimColor.withValues(alpha: 0.06)
                            : c.surfaceLowest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? dimColor : c.outlineVariant,
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1424161C),
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? dimColor : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? dimColor : c.outline,
                                width: 1.5,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    PhosphorIconsRegular.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : Center(
                                    child: Text(
                                      '$value',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: c.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              scaleLabels[i],
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected ? dimColor : c.onSurface,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              PhosphorIconsRegular.checkCircle,
                              color: dimColor,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 26),
            ],
          ),
        ),
      ),
    );
  }
}
