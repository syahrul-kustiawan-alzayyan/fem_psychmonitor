import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import 'onboarding_state.dart';

class MbtiSection extends StatefulWidget {
  final VoidCallback onNext;

  const MbtiSection({super.key, required this.onNext});

  @override
  State<MbtiSection> createState() => _MbtiSectionState();
}

class _MbtiSectionState extends State<MbtiSection> {
  int _pageIndex = 0; // 0 = Intro, >0 = Question Index

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
            children: [
              const SizedBox(height: 20),
              // Enhanced Info Container (Blue-Pink Gradient)
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
                            loc('mbti_what_is'),
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
                      loc('mbti_what_is_desc'),
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
              // Dimensi Utama Container
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
                      loc('mbti_4dimensions'),
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.textP(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDimensionCard(context, '⚡', 'E vs I', loc('mbti_dimension_ei'), loc('mbti_dimension_ei_desc')),
                    const SizedBox(height: 10),
                    _buildDimensionCard(context, '🔍', 'S vs N', loc('mbti_dimension_sn'), loc('mbti_dimension_sn_desc')),
                    const SizedBox(height: 10),
                    _buildDimensionCard(context, '💭', 'T vs F', loc('mbti_dimension_tf'), loc('mbti_dimension_tf_desc')),
                    const SizedBox(height: 10),
                    _buildDimensionCard(context, '📋', 'J vs P', loc('mbti_dimension_jp'), loc('mbti_dimension_jp_desc')),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              Text(
                loc('mbti_know_question'),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textP(context),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              // Modern Selection Buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : AppTheme.surface(context).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: AppTheme.cardShadow,
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.7),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    _buildModernSelectionCard(
                      context: context,
                      title: loc('mbti_not_know'),
                      subtitle: loc('mbti_not_know_desc'),
                      icon: Icons.psychology_rounded,
                      iconColor: AppTheme.primaryColor,
                      isSelected: !state.showManualMbti,
                      onTap: () {
                        state.doNotSkipMbti();
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildModernSelectionCard(
                      context: context,
                      title: loc('mbti_already_know'),
                      subtitle: loc('mbti_already_know_desc'),
                      icon: Icons.edit_note_rounded,
                      iconColor: AppTheme.secondaryColor,
                      isSelected: state.showManualMbti,
                      onTap: () {
                        state.skipMbti();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (!state.showManualMbti)
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
              if (state.showManualMbti) ...[                
                _buildManualInput(context, state),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: state.mbtiType.isNotEmpty ? AppTheme.primaryGradient : null,
                    color: state.mbtiType.isNotEmpty ? null : AppTheme.surfVar(context),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: state.mbtiType.isNotEmpty
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha: 0.4),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ]
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: state.mbtiType.isNotEmpty
                          ? () {
                              state.calculateMbtiResult();
                              widget.onNext();
                            }
                          : null,
                      borderRadius: BorderRadius.circular(22),
                      splashColor: state.mbtiType.isNotEmpty ? Colors.white.withValues(alpha: 0.2) : null,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppLocalizations.tr('confirm_continue'),
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: state.mbtiType.isNotEmpty ? Colors.white : AppTheme.textS(context),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: state.mbtiType.isNotEmpty ? Colors.white.withValues(alpha: 0.25) : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: state.mbtiType.isNotEmpty ? Colors.white : AppTheme.textS(context),
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionPage(
      BuildContext context, OnboardingState state, int qIndex) {
    if (state.mbtiQuestions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final q = state.mbtiQuestions[qIndex];
    final selected = state.mbtiAnswers[qIndex];
    final questionNum = qIndex + 1;
    final totalQuestions = state.mbtiQuestions.length;
    final currentLocale = AppLocalizations.locale;

    final dimensionLabels = {
      'E_I': ('⚡', currentLocale == 'id' ? 'Energi' : 'Energy'),
      'S_N': ('🔍', currentLocale == 'id' ? 'Informasi' : 'Information'),
      'T_F': ('💭', currentLocale == 'id' ? 'Keputusan' : 'Decisions'),
      'J_P': ('📋', currentLocale == 'id' ? 'Gaya Hidup' : 'Lifestyle'),
    };
    final dimInfo = dimensionLabels[q.dimension] ?? ('💧', currentLocale == 'id' ? 'Umum' : 'General');
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
                        color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.secondaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(dimInfo.$1, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            '${dimInfo.$2} ($questionNum / $totalQuestions)',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.secondaryColor,
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
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.secondaryColor.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Text(
                q.question,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            _buildOptionCard(
              context: context,
              label: 'A',
              text: q.optionAText,
              isSelected: selected == 0,
              color: AppTheme.primaryColor,
              onTap: () {
                state.setMbtiAnswer(qIndex, 0);
                if (qIndex < totalQuestions - 1) {
                  Future.delayed(const Duration(milliseconds: 300), _nextPage);
                } else {
                  state.calculateMbtiResult();
                  widget.onNext();
                }
              },
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              context: context,
              label: 'B',
              text: q.optionBText,
              isSelected: selected == 1,
              color: AppTheme.secondaryColor,
              onTap: () {
                state.setMbtiAnswer(qIndex, 1);
                if (qIndex < totalQuestions - 1) {
                  Future.delayed(const Duration(milliseconds: 300), _nextPage);
                } else {
                  state.calculateMbtiResult();
                  widget.onNext();
                }
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildManualInput(BuildContext context, OnboardingState state) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final loc = AppLocalizations.tr;
    final mbtiTypes = [
      'INTJ', 'INTP', 'ENTJ', 'ENTP',
      'INFJ', 'INFP', 'ENFJ', 'ENFP',
      'ISTJ', 'ISFJ', 'ESTJ', 'ESFJ',
      'ISTP', 'ISFP', 'ESTP', 'ESFP',
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: mbtiTypes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final type = mbtiTypes[index];
        final isSelected = state.mbtiType == type;

        return GestureDetector(
          onTap: () {
            state.setManualMbtiType(type);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : AppTheme.surface(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.surfVar(context),
              ),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Text(
              type,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textP(context),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required String label,
    required String text,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = context.watch<ThemeProvider>().isDark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected ? color : (isDark ? AppTheme.darkSurfaceVar : AppTheme.surfVar(context)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : (isDark ? AppTheme.darkTextPrimary : AppTheme.textP(context)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textP(context),
                  height: 1.4,
                ),
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 16),
              ),
          ],
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

  Widget _buildModernSelectionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = context.watch<ThemeProvider>().isDark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: isSelected ? LinearGradient(
              colors: [
                iconColor.withValues(alpha: 0.12),
                iconColor.withValues(alpha: 0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ) : null,
            color: isSelected ? null : (isDark ? AppTheme.darkCard : AppTheme.surface(context)),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? iconColor.withValues(alpha: 0.4) : (isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.surfVar(context)),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? iconColor.withValues(alpha: 0.15) : (isDark ? AppTheme.darkSurfaceVar : AppTheme.surfVar(context)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isSelected ? iconColor : (isDark ? AppTheme.darkTextSecondary : AppTheme.textS(context)),
                ),
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
                        color: isSelected ? iconColor : (isDark ? AppTheme.darkTextPrimary : AppTheme.textP(context)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.textS(context),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
