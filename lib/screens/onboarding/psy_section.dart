import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../theme/resonance_colors.dart';
import 'onboarding_state.dart';

class PsySection extends StatefulWidget {
  final VoidCallback onNext;

  const PsySection({super.key, required this.onNext});

  @override
  State<PsySection> createState() => _PsySectionState();
}

class _PsySectionState extends State<PsySection> {
  int _pageIndex = 0; // 0 = Intro, >0 = Question

  static const _scaleColors = [
    Color(0xFF22C55E),
    Color(0xFF84CC16),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
  ];

  void _nextPage() {
    setState(() {
      _pageIndex++;
    });
  }

  void _prevPage() {
    setState(() {
      _pageIndex--;
    });
  }

  /// Buang emoji di awal string i18n (mis. '💼 Beban Peran & Stres: ...')
  String _stripEmoji(String s) {
    return s.replaceFirst(
      RegExp(
        r'^[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}\u{2B00}-\u{2BFF}]+\s?',
        unicode: true,
      ),
      '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardingState>();
    final c = ResonanceColors.of(context);

    return Container(
      color: c.background,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
          return Stack(
            alignment: Alignment.topCenter,
            children: <Widget>[...previousChildren, currentChild!],
          );
        },
        child: _pageIndex == 0
            ? _buildIntroPage(context, state)
            : _buildQuestionPage(context, state, _pageIndex - 1),
      ),
    );
  }

  Widget _buildIntroPage(BuildContext context, OnboardingState state) {
    final c = ResonanceColors.of(context);
    final loc = AppLocalizations.tr;
    final isEn = context.watch<LocaleProvider>().locale == 'en';
    final points = [
      loc('psy_point_1'),
      loc('psy_point_2'),
      loc('psy_point_3'),
      loc('psy_point_4'),
    ];

    return SingleChildScrollView(
      key: const ValueKey('psy-intro'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          ResonanceEyebrow(
            c: c,
            label: isEn ? '03 / ASSESSMENT' : '03 / ASESMEN',
          ),
          const SizedBox(height: 16),
          ResonanceCard(
            c: c,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
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
                    PhosphorIconsRegular.heartbeat,
                    color: c.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  loc('psy_intro_title'),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    color: c.onSurface,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  loc('psy_intro_desc'),
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
            padding: const EdgeInsets.all(24),
            layered: false,
            softShadow: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: c.primaryContainer,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.outlineVariant),
                      ),
                      child: Icon(
                        PhosphorIconsRegular.info,
                        color: c.primary,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        loc('psy_about_title'),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: c.onSurface,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  loc('psy_about_desc'),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: c.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 18),
                Container(height: 1, color: c.outlineVariant),
                const SizedBox(height: 18),
                ...List.generate(points.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 7),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: c.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              _stripEmoji(points[i]),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: c.onSurface,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: c.surfaceLowest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.outlineVariant),
              boxShadow: const [
                BoxShadow(color: Color(0x1424161C), offset: Offset(2, 2)),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  PhosphorIconsRegular.lightbulb,
                  color: const Color(0xFFB45309),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc('psy_note_title'),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: c.onSurface,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        loc('psy_note_desc'),
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: c.onSurfaceVariant,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          ResonancePillButton(
            c: c,
            label: loc('start_assessment'),
            trailingIcon: PhosphorIconsRegular.arrowRight,
            onTap: _nextPage,
          ),
          const SizedBox(height: 26),
        ],
      ),
    );
  }

  Widget _buildQuestionPage(
    BuildContext context,
    OnboardingState state,
    int qIndex,
  ) {
    if (state.psyQuestions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final c = ResonanceColors.of(context);
    final q = state.psyQuestions[qIndex];
    final selected = state.psyAnswers[qIndex];
    final questionNum = qIndex + 1;
    final totalQuestions = state.psyQuestions.length;
    final progress = questionNum / totalQuestions;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        key: ValueKey('psy-question-$qIndex'),
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
                        label: '$questionNum/$totalQuestions',
                        icon: PhosphorIconsRegular.heart,
                      ),
                    ),
                  ),
                  ResonanceIconButton(
                    c: c,
                    icon: PhosphorIconsRegular.house,
                    onTap: () {
                      setState(() {
                        _pageIndex = 0;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ResonanceProgressBar(c: c, progress: progress),
              const SizedBox(height: 24),
              ResonanceCard(
                c: c,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    ResonanceChip(
                      c: c,
                      label: q.category,
                      icon: PhosphorIconsRegular.heart,
                      textColor: c.primary,
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
              ...List.generate(q.options.length, (i) {
                final opt = q.options[i];
                final color = _scaleColors[i % _scaleColors.length];
                final isSelected = selected == opt.score;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () {
                      state.setPsyAnswer(qIndex, opt.score);
                      if (qIndex < totalQuestions - 1) {
                        Future.delayed(
                          const Duration(milliseconds: 300),
                          _nextPage,
                        );
                      } else {
                        state.calculatePsyResult();
                        widget.onNext();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.06)
                            : c.surfaceLowest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? color : c.outlineVariant,
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
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected ? color : c.surfaceVariant,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                '${opt.score}',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected
                                      ? Colors.white
                                      : c.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              opt.answer,
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected ? color : c.onSurface,
                                height: 1.45,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              PhosphorIconsRegular.checkCircle,
                              color: color,
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
