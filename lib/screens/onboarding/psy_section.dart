import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.explore_rounded,
                        color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Mengenal Potensi\n& Mental Anda',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Pahami diri dengan pendekatan saintifik secara menyeluruh.',
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
            const SizedBox(height: 32),
            _buildModernInfoSection(
              context: context,
              icon: Icons.spa_rounded,
              iconColor: AppTheme.secondaryColor,
              title: 'Pemantauan Kesehatan Mental',
              description:
                  'Tingkat stres dan batas ketahanan emosional berbeda-beda tiap waktu. Kuesioner ini dirancang untuk mendeteksi fluktuasi suasana hati Anda.',
              points: [
                'Identifikasi pemicu (trigger) emosi atau stres harian',
                'Analisis suara dipadukan evaluasi diri secara objektif',
                'Memberikan wawasan tentang kebutuhan self-care Anda saat ini',
                'Membantu Anda mengambil langkah sadar merawat kesejahteraan psikis',
              ],
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.bg(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.textH(context).withValues(alpha: 0.1),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfVar(context),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.shield_outlined,
                        color: AppTheme.textS(context), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Catatan Penting',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textP(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Aplikasi ini tidak menggantikan diagnosis klinis. Konsultasikan dengan tenaga ahli jika butuh bantuan medis.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.textS(context),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
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
                      'Mulai Evaluasi Mental',
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
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionPage(
      BuildContext context, OnboardingState state, int qIndex) {
    if (state.psyQuestions.isEmpty)
      return const Center(child: CircularProgressIndicator());

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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite_rounded,
                      size: 14, color: Colors.pink),
                  const SizedBox(width: 6),
                  Text(
                    '${AppLocalizations.tr("mental_health")} · Pertanyaan $questionNum/$totalQuestions',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textP(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              q.category,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textP(context),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              q.question,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: AppTheme.textS(context),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
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
                    }
                  },
                ),
              );
            }),
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
                                style:
                                    GoogleFonts.poppins(color: Colors.white)),
                            backgroundColor: AppTheme.primaryColor,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      if (qIndex < totalQuestions - 1) {
                        _nextPage();
                      } else {
                        state.calculatePsyResult();
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
                      qIndex < totalQuestions - 1
                          ? 'Berikutnya'
                          : 'Lihat Hasil',
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

  Widget _buildPsyOptionCard({
    required BuildContext context,
    required int value,
    required String label,
    required String description,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.05)
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
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected ? color : AppTheme.surfVar(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : AppTheme.textP(context),
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
                  color: AppTheme.textP(context),
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
