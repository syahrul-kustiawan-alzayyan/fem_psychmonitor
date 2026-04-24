import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
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
      child: _pageIndex == 0
          ? _buildIntroPage(context, state)
          : _buildQuestionPage(context, state, _pageIndex - 1),
    );
  }

  Widget _buildIntroPage(BuildContext context, OnboardingState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildModernInfoSection(
              context: context,
              icon: Icons.psychology_alt_rounded,
              iconColor: AppTheme.primaryColor,
              title: 'Psikologi MBTI',
              description:
                  'Myers-Briggs Type Indicator (MBTI) disusun berdasarkan konsep psikolog Swiss Carl Jung yang mengidentifikasi preferensi psikologis.',
              points: [
                'Pemrosesan Informasi: Bagaimana Anda bereaksi terhadap data (Sensing/Intuition)',
                'Pengambilan Keputusan: Bagaimana Anda menilai situasi (Thinking/Feeling)',
                'Orientasi Energi: Kepada siapa atau apa energi disalurkan (Extrovert/Introvert)',
                'Gaya Hidup: Struktur hidup kesukaan (Judging/Perceiving)'
              ],
            ),
            const SizedBox(height: 48),
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.psychology_rounded,
                  size: 44, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 28),
            Text(
              'Apakah Anda sudah mengetahui tipe MBTI Anda?',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textP(context),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Text(
                'Jika sudah, Anda bisa langsung mengetikkannya. Jika belum, kami akan membantu Anda mengetahuinya melalui tes singkat.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: AppTheme.textS(context),
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 36),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => state.doNotSkipMbti(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !state.showManualMbti
                          ? AppTheme.primaryColor
                          : AppTheme.surface(context),
                      foregroundColor: !state.showManualMbti
                          ? Colors.white
                          : AppTheme.primaryColor,
                      elevation: !state.showManualMbti ? 2 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: !state.showManualMbti
                              ? Colors.transparent
                              : AppTheme.primaryColor,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('Tes MBTI',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => state.skipMbti(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: state.showManualMbti
                          ? AppTheme.primaryColor
                          : AppTheme.surface(context),
                      foregroundColor: state.showManualMbti
                          ? Colors.white
                          : AppTheme.primaryColor,
                      elevation: state.showManualMbti ? 2 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: state.showManualMbti
                              ? Colors.transparent
                              : AppTheme.primaryColor,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('Pilih Manual',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            if (state.showManualMbti)
              _buildManualInput(context, state)
            else
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 4,
                    shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Mulai Tes MBTI',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 40),
            if (state.showManualMbti)
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    if (state.isMbtiComplete()) {
                      state.calculateMbtiResult();
                      widget.onNext();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Pilih tipe MBTI terlebih dahulu!',
                              style: GoogleFonts.poppins(color: Colors.white)),
                          backgroundColor: AppTheme.primaryColor,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 4,
                    shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                  ),
                  child: Text(
                    'Lanjut ke Kesehatan Mental',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 30),
          ],
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

    final dimensionLabels = {
      'E_I': ('🔋', 'Energi', 'Energy'),
      'S_N': ('🔍', 'Informasi', 'Information'),
      'T_F': ('💭', 'Keputusan', 'Decisions'),
      'J_P': ('📋', 'Gaya Hidup', 'Lifestyle'),
    };
    final dimInfo = dimensionLabels[q.dimension] ?? ('💡', 'Umum', 'General');

    return SingleChildScrollView(
      key: ValueKey(qIndex),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(dimInfo.$1, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    '${dimInfo.$2} · Pertanyaan $questionNum/$totalQuestions',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textP(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Text(
                q.question,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textP(context),
                  height: 1.5,
                ),
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
                }
              },
            ),
            const SizedBox(height: 48),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _prevPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surface(context),
                      foregroundColor: AppTheme.textP(context),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Kembali',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (selected == -1) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Silakan pilih jawaban Anda',
                                style: GoogleFonts.poppins(color: Colors.white)),
                            backgroundColor: AppTheme.primaryColor,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      if (qIndex < totalQuestions - 1) {
                        _nextPage();
                      } else {
                        state.calculateMbtiResult();
                        widget.onNext();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      qIndex < totalQuestions - 1 ? 'Berikutnya' : 'Selesai MBTI',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildManualInput(BuildContext context, OnboardingState state) {
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : AppTheme.surface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppTheme.surfVar(context),
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
                color: isSelected ? color : AppTheme.surfVar(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : AppTheme.textP(context),
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
                  color: AppTheme.textP(context),
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

  Widget _buildModernInfoSection({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required List<String> points,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: AppTheme.surfVar(context),
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
                    color: AppTheme.textP(context),
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
              color: AppTheme.textS(context),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 1,
            color: AppTheme.surfVar(context),
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
