import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import 'onboarding_state.dart';

class BigFiveSection extends StatefulWidget {
  final VoidCallback onNext;

  const BigFiveSection({super.key, required this.onNext});

  @override
  State<BigFiveSection> createState() => _BigFiveSectionState();
}

class _BigFiveSectionState extends State<BigFiveSection> {
  int _pageIndex = 0;

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

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardingState>();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            ...previousChildren,
            currentChild!,
          ],
        );
      },
      child: _pageIndex == 0
          ? _buildIntroPage(context, state)
          : _buildQuestionPage(context, state, _pageIndex - 1),
    );
  }

  Widget _buildIntroPage(BuildContext context, OnboardingState state) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final loc = AppLocalizations.tr;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppTheme.darkGradientBackground : AppTheme.lightGradientBackground,
      ),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Info Card
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.3),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.psychology_outlined,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            loc('bigfive_what_is'),
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      loc('bigfive_what_is_desc'),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.95),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Dimension card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : AppTheme.surface(context).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ],
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.7),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc('bigfive_5dimensions'),
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.textP(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDimensionCard(context, '🎨', 'Openness', loc('bigfive_dim_o'), loc('bigfive_dim_o_desc')),
                    const SizedBox(height: 10),
                    _buildDimensionCard(context, '📋', 'Conscientiousness', loc('bigfive_dim_c'), loc('bigfive_dim_c_desc')),
                    const SizedBox(height: 10),
                    _buildDimensionCard(context, '⚡', 'Extraversion', loc('bigfive_dim_e'), loc('bigfive_dim_e_desc')),
                    const SizedBox(height: 10),
                    _buildDimensionCard(context, '🤝', 'Agreeableness', loc('bigfive_dim_a'), loc('bigfive_dim_a_desc')),
                    const SizedBox(height: 10),
                    _buildDimensionCard(context, '🌊', 'Neuroticism', loc('bigfive_dim_n'), loc('bigfive_dim_n_desc')),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              Text(
                loc('bigfive_ready'),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textP(context),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(22),
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
                    onTap: _nextPage,
                    borderRadius: BorderRadius.circular(22),
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
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionPage(
      BuildContext context, OnboardingState state, int qIndex) {
    if (state.bigFiveQuestions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final q = state.bigFiveQuestions[qIndex];
    final selected = state.bigFiveAnswers[qIndex];
    final questionNum = qIndex + 1;
    final totalQuestions = state.bigFiveQuestions.length;
    final currentLocale = AppLocalizations.locale;
    final progress = questionNum / totalQuestions;

    final dimColors = {
      'O': const Color(0xFF8B5CF6),
      'C': const Color(0xFF3B82F6),
      'E': const Color(0xFFF59E0B),
      'A': const Color(0xFF10B981),
      'N': const Color(0xFFEF4444),
    };
    final dimColor = dimColors[q.dimension] ?? AppTheme.primaryColor;

    final dimEmojis = {
      'O': '🎨',
      'C': '📋',
      'E': '⚡',
      'A': '🤝',
      'N': '🌊',
    };
    final dimEmoji = dimEmojis[q.dimension] ?? '🧠';

    final dimLabels = {
      'O': currentLocale == 'id' ? 'Keterbukaan' : 'Openness',
      'C': currentLocale == 'id' ? 'Kehati-hatian' : 'Conscientiousness',
      'E': currentLocale == 'id' ? 'Ekstraversi' : 'Extraversion',
      'A': currentLocale == 'id' ? 'Keramahan' : 'Agreeableness',
      'N': currentLocale == 'id' ? 'Neurotisisme' : 'Neuroticism',
    };
    final dimLabel = dimLabels[q.dimension] ?? q.dimension;

    final scaleLabels = currentLocale == 'id'
        ? ['Sangat Tidak', 'Tidak Sesuai', 'Netral', 'Sesuai', 'Sangat Sesuai']
        : ['Very Inaccurate', 'Inaccurate', 'Neutral', 'Accurate', 'Very Accurate'];

    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.lightGradientBackground,
      ),
      child: SingleChildScrollView(
        key: ValueKey(qIndex),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // Navigation + Progress
              Row(
                children: [
                  _buildGradientIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: qIndex > 0 ? _prevPage : null,
                  ),
                  Expanded(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: dimColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: dimColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(dimEmoji, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              '$dimLabel ($questionNum / $totalQuestions)',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: dimColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildGradientIconButton(
                    icon: Icons.home_rounded,
                    onTap: () {
                      setState(() {
                        _pageIndex = 0;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    Container(
                      height: 10,
                      width: double.infinity,
                      color: AppTheme.surfVar(context),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      height: 10,
                      width: (MediaQuery.of(context).size.width - 48) * progress,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [dimColor, dimColor.withValues(alpha: 0.6)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Statement card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [dimColor, dimColor.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: dimColor.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      dimEmoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      q.question,
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Likert Scale — vertical radio-style
              ...List.generate(5, (i) {
                final value = i + 1;
                final isSelected = selected == value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () {
                      state.setBigFiveAnswer(qIndex, value);
                      if (qIndex < totalQuestions - 1) {
                        Future.delayed(const Duration(milliseconds: 300), _nextPage);
                      } else {
                        state.calculateBigFiveResult();
                        widget.onNext();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? dimColor.withValues(alpha: 0.12) : AppTheme.surfVar(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? dimColor : AppTheme.surfVar(context),
                          width: isSelected ? 2 : 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? dimColor : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? dimColor : AppTheme.textS(context),
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 18)
                                : Center(
                                    child: Text(
                                      '$value',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textS(context),
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              scaleLabels[i],
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? dimColor : AppTheme.textP(context),
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded, color: dimColor, size: 22),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientIconButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: isDisabled ? null : AppTheme.primaryGradient,
            color: isDisabled ? AppTheme.surfVar(context) : null,
            shape: BoxShape.circle,
            boxShadow: isDisabled ? null : [
              BoxShadow(
                color: AppTheme.secondaryColor.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 22,
            color: isDisabled ? AppTheme.textS(context) : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildDimensionCard(BuildContext context, String emoji, String code, String title, String description) {
    final isDark = context.watch<ThemeProvider>().isDark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceVar.withValues(alpha: 0.5) : AppTheme.surface(context).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.surfVar(context).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        code,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.textP(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.textS(context),
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
}
