import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

/// Onboarding Screen untuk pengguna baru.
/// Flow: Selamat datang → Input nama → 20 pertanyaan MBTI → Hasil MBTI
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onCompleted;

  const OnboardingScreen({super.key, required this.onCompleted});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();

  // Halaman: 0=welcome, 1=nama, 2-21=pertanyaan MBTI, 22=hasil
  int _currentPage = 0;
  final int _totalPages = 23; // 1 welcome + 1 nama + 20 pertanyaan + 1 hasil

  // Data yang dikumpulkan
  final TextEditingController _nameController = TextEditingController();
  final List<int?> _answers = List.filled(20, null); // 0=opsi A, 1=opsi B
  bool _isSaving = false;

  // Animasi
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Hasil MBTI
  String _mbtiType = '';
  Map<String, int> _mbtiScores = {};

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  double get _progress => _currentPage / (_totalPages - 1);

  void _nextPage() {
    // Validasi nama
    if (_currentPage == 1 && _nameController.text.trim().length < 2) {
      _showSnack('Masukkan namamu terlebih dahulu ya! 😊');
      return;
    }
    // Validasi jawaban MBTI
    final qIndex = _currentPage - 2;
    if (_currentPage >= 2 && _currentPage <= 21 && _answers[qIndex] == null) {
      _showSnack('Pilih salah satu jawaban dulu ya! ✨');
      return;
    }

    // Hitung MBTI saat semua pertanyaan selesai
    if (_currentPage == 21) {
      final result = calculateMBTI(_answers.map((e) => e ?? 0).toList());
      _mbtiType = result.type;
      _mbtiScores = result.scores;
    }

    if (_currentPage < _totalPages - 1) {
      setState(() => _currentPage++);
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final user = AppUser(
      name: _nameController.text.trim(),
      mbtiType: _mbtiType,
      mbtiScores: _mbtiScores,
      createdAt: DateTime.now(),
    );

    await DatabaseService.insertUser(user);
    await StorageService.setOnboardingComplete(user.name);

    if (mounted) widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress bar + Back button ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  if (_currentPage > 0 && _currentPage < _totalPages - 1)
                    GestureDetector(
                      onTap: _prevPage,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppTheme.surfVar(context),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: AppTheme.textP(context),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 6,
                        backgroundColor: AppTheme.surfVar(context),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Page counter
                  Text(
                    '${_currentPage + 1}/$_totalPages',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textS(context),
                    ),
                  ),
                ],
              ),
            ),

            // ── Page Content ──
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildWelcomePage(),
                  _buildNamePage(),
                  ...List.generate(20, (i) => _buildMBTIQuestionPage(i)),
                  _buildResultPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Page: Welcome
  // ─────────────────────────────────────────────────────────────
  Widget _buildWelcomePage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo dengan gradient border
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
                boxShadow: AppTheme.primaryShadow,
              ),
              padding: const EdgeInsets.all(4),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: ClipOval(
                  child: Image.asset('lib/src/logo.jpeg', fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Selamat Datang! 👋',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppTheme.textP(context),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Fem-PhysicsMonitor akan membantu kamu memahami emosi melalui analisis suara dan kepribadian.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textS(context),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.quiz_rounded,
                    color: AppTheme.primaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '20 pertanyaan MBTI (~5 menit)',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildNextButton('Mulai Sekarang'),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Page: Input Nama
  // ─────────────────────────────────────────────────────────────
  Widget _buildNamePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_rounded,
              size: 36,
              color: AppTheme.secondaryColor, // Pink
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Siapa namamu? 😊',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textP(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kami ingin mengenalmu lebih dekat',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.textS(context),
            ),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textP(context),
            ),
            decoration: InputDecoration(
              hintText: 'Ketik namamu di sini...',
              hintStyle: GoogleFonts.poppins(
                fontSize: 16,
                color: AppTheme.textH(context),
              ),
              filled: true,
              fillColor: AppTheme.surfVar(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 18,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildNextButton('Lanjut'),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Page: MBTI Question (A vs B choice)
  // ─────────────────────────────────────────────────────────────
  Widget _buildMBTIQuestionPage(int index) {
    final q = mbtiQuestions[index];
    final selected = _answers[index];

    // Dimensi label & emoji
    final dimensionLabels = {
      'EI': ('🔋', 'Energi', 'Energy'),
      'SN': ('🔍', 'Informasi', 'Information'),
      'TF': ('💭', 'Keputusan', 'Decisions'),
      'JP': ('📋', 'Gaya Hidup', 'Lifestyle'),
    };
    final dimInfo = dimensionLabels[q.dimension]!;
    final questionNum = index + 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Dimension badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${dimInfo.$1} ${dimInfo.$2} · Pertanyaan $questionNum/20',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Question text
          Text(
            q.question,
            style: GoogleFonts.poppins(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppTheme.textP(context),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          // Option A
          _buildOptionCard(
            label: 'A',
            text: q.optionAText,
            isSelected: selected == 0,
            color: const Color(0xFF3B82F6), // Blue
            onTap: () {
              setState(() => _answers[index] = 0);
              Future.delayed(const Duration(milliseconds: 300), _nextPage);
            },
          ),
          const SizedBox(height: 14),
          // VS divider
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.surfVar(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'ATAU',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textH(context),
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Option B
          _buildOptionCard(
            label: 'B',
            text: q.optionBText,
            isSelected: selected == 1,
            color: const Color(0xFFEC4899), // Pink
            onTap: () {
              setState(() => _answers[index] = 1);
              Future.delayed(const Duration(milliseconds: 300), _nextPage);
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
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
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.12)
              : AppTheme.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppTheme.surfVar(context),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            // Label badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected ? color : color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: AppTheme.textP(context),
                  height: 1.5,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 22),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Page: MBTI Result
  // ─────────────────────────────────────────────────────────────
  Widget _buildResultPage() {
    if (_mbtiType.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final user = AppUser(
      name: _nameController.text.trim(),
      mbtiType: _mbtiType,
      mbtiScores: _mbtiScores,
      createdAt: DateTime.now(),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Confetti-like header
          Text('🎉', style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Hasil MBTI-mu!',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textP(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Halo ${user.name}, ini kepribadianmu:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textS(context),
            ),
          ),
          const SizedBox(height: 24),

          // MBTI Type Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.primaryShadow,
            ),
            child: Column(
              children: [
                // Type letters
                Text(
                  _mbtiType,
                  style: GoogleFonts.poppins(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.mbtiNickname,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Description card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: AppTheme.secondaryColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tentang Kepribadianmu',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textP(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  user.mbtiDescription,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.textS(context),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Strengths
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: AppTheme.secondaryColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Kekuatan Utama',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textP(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: user.mbtiStrengths.map((s) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '✨ $s',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Dimension scores
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bar_chart_rounded,
                      color: AppTheme.secondaryColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Skor Dimensi',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textP(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDimensionBar(
                  'E',
                  'Extravert',
                  'I',
                  'Introvert',
                  _mbtiScores['E'] ?? 0,
                  _mbtiScores['I'] ?? 0,
                ),
                const SizedBox(height: 12),
                _buildDimensionBar(
                  'S',
                  'Sensing',
                  'N',
                  'Intuition',
                  _mbtiScores['S'] ?? 0,
                  _mbtiScores['N'] ?? 0,
                ),
                const SizedBox(height: 12),
                _buildDimensionBar(
                  'T',
                  'Thinking',
                  'F',
                  'Feeling',
                  _mbtiScores['T'] ?? 0,
                  _mbtiScores['F'] ?? 0,
                ),
                const SizedBox(height: 12),
                _buildDimensionBar(
                  'J',
                  'Judging',
                  'P',
                  'Perceiving',
                  _mbtiScores['J'] ?? 0,
                  _mbtiScores['P'] ?? 0,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Complete button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _completeOnboarding,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      'Mulai Gunakan Aplikasi 🚀',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDimensionBar(
    String labelA,
    String nameA,
    String labelB,
    String nameB,
    int scoreA,
    int scoreB,
  ) {
    final total = scoreA + scoreB;
    final pctA = total > 0 ? scoreA / total : 0.5;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$labelA · $nameA',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: pctA >= 0.5 ? FontWeight.w700 : FontWeight.w500,
                color: pctA >= 0.5
                    ? AppTheme.primaryColor
                    : AppTheme.textS(context),
              ),
            ),
            Text(
              '$labelB · $nameB',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: pctA < 0.5 ? FontWeight.w700 : FontWeight.w500,
                color: pctA < 0.5
                    ? AppTheme.secondaryColor
                    : AppTheme.textS(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                Expanded(
                  flex: (pctA * 100).round().clamp(5, 95),
                  child: Container(color: AppTheme.primaryColor),
                ),
                Expanded(
                  flex: ((1 - pctA) * 100).round().clamp(5, 95),
                  child: Container(color: AppTheme.secondaryColor),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(pctA * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.textH(context),
              ),
            ),
            Text(
              '${((1 - pctA) * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.textH(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Shared: Next Button
  // ─────────────────────────────────────────────────────────────
  Widget _buildNextButton(String label) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _nextPage,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
