import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import 'onboarding_state.dart';

class PsySection extends StatefulWidget {
  final VoidCallback onNext;

  const PsySection({super.key, required this.onNext});

  @override
  State<PsySection> createState() => _PsySectionState();
}

class _PsySectionState extends State<PsySection> {
  int _pageIndex = 0; // 0 = Intro, >0 = Question

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
            ?currentChild,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Hero with gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      loc('psy_intro_title'),
                      style: GoogleFonts.poppins(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      loc('psy_intro_desc'),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Enhanced Info Container
              _buildModernInfoSection(
                context: context,
                icon: Icons.info_outline_rounded,
                iconColor: AppTheme.primaryColor,
                title: loc('psy_about_title'),
                description: loc('psy_about_desc'),
                points: [
                  loc('psy_point_1'),
                  loc('psy_point_2'),
                  loc('psy_point_3'),
                  loc('psy_point_4'),
                ],
              ),
              const SizedBox(height: 24),
              // Enhanced Note card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.secondaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.tips_and_updates_rounded,
                      color: AppTheme.secondaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc('psy_note_title'),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.secondaryColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            loc('psy_note_desc'),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.textS(context),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Modern Start Button
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
                             loc('start_assessment'),
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionPage(
      BuildContext context, OnboardingState state, int qIndex) {
    final isDark = context.watch<ThemeProvider>().isDark;
    if (state.psyQuestions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final scaleColors = [
      const Color(0xFF22C55E),
      const Color(0xFF84CC16),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
    ];

    final q = state.psyQuestions[qIndex];
    final selected = state.psyAnswers[qIndex];
    final questionNum = qIndex + 1;
    final totalQuestions = state.psyQuestions.length;
final progress = questionNum / totalQuestions;

    return SingleChildScrollView(
      key: ValueKey(qIndex),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            // Progress Section with Navigation Buttons
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
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite_rounded, size: 14, color: Colors.pink),
                          const SizedBox(width: 6),
                          Text(
                            '$questionNum / $totalQuestions',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
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
                    color: isDark ? AppTheme.darkSurfaceVar : AppTheme.surfVar(context),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    height: 10,
                    width: (MediaQuery.of(context).size.width - 48) * progress,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A90E2), Color(0xFFFF6B9D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B9D).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite_rounded,
                            size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          q.category,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
            const SizedBox(height: 28),
            // Answer options
            ...List.generate(q.options.length, (i) {
              final opt = q.options[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildPsyOptionCard(
                  context: context,
                  value: opt.score,
                  label: '${opt.score}',
                  description: opt.answer,
                  color: scaleColors[i % scaleColors.length],
                  isSelected: selected == opt.score,
                  onTap: () {
                    state.setPsyAnswer(qIndex, opt.score);
                    if (qIndex < totalQuestions - 1) {
                      Future.delayed(
                          const Duration(milliseconds: 300), _nextPage);
                    } else {
                      state.calculatePsyResult();
                      widget.onNext();
                    }
                  },
                ),
              );
            }),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildPsyOptionCard({
    required BuildContext context,
    required int value,
    required String label,
    required String description,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = context.watch<ThemeProvider>().isDark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.05)
              : (isDark ? AppTheme.darkCard : AppTheme.surface(context)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : (isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.surfVar(context)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected ? color : (isDark ? AppTheme.darkSurfaceVar : AppTheme.surfVar(context)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : (isDark ? AppTheme.darkTextPrimary : AppTheme.textP(context)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textP(context),
                ),
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernInfoSection({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required List<String> points,
  }) {
    final isDark = context.watch<ThemeProvider>().isDark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.surface(context),
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.surfVar(context),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.textP(context),
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.textS(context),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 1,
            color: isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.surfVar(context),
            margin: const EdgeInsets.only(bottom: 20),
          ),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4.5),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: iconColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      point,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.textP(context),
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

  Widget _buildGradientIconButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final isDisabled = onTap == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: isDisabled ? null : const LinearGradient(
              colors: [Color(0xFF4A90E2), Color(0xFFFF6B9D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            color: isDisabled ? (isDark ? AppTheme.darkSurfaceVar : AppTheme.surfVar(context)) : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDisabled ? null : [
              BoxShadow(
                color: const Color(0xFFFF6B9D).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 24,
            color: isDisabled ? (isDark ? AppTheme.darkTextHint : AppTheme.textS(context)) : Colors.white,
          ),
        ),
      ),
    );
  }
}
