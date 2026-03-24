import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

/// Onboarding Screen untuk pengguna baru.
/// Flow: Selamat datang → Input nama → 10 pertanyaan psikis → Ringkasan hasil
class OnboardingScreen extends StatefulWidget {
  /// Callback setelah onboarding selesai — navigasi ke MainNavigation
  final VoidCallback onCompleted;

  const OnboardingScreen({super.key, required this.onCompleted});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();

  // Halaman saat ini: 0=welcome, 1=nama, 2-11=pertanyaan, 12=hasil
  int _currentPage = 0;
  final int _totalPages = 13; // 1 welcome + 1 nama + 10 pertanyaan + 1 hasil

  // Data yang dikumpulkan
  final TextEditingController _nameController = TextEditingController();
  final List<int?> _answers = List.filled(10, null); // jawaban tiap soal
  bool _isSaving = false;

  // Animasi transisi
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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

  // ── Kalkulasi skor total dari jawaban ──────────────────
  int get _totalScore {
    int score = 0;
    for (int i = 0; i < onboardingQuestions.length; i++) {
      if (_answers[i] != null) {
        score += onboardingQuestions[i].scores[_answers[i]!];
      }
    }
    return score;
  }

  // ── Progres (0.0 – 1.0) untuk progress bar ──────────
  double get _progress => _currentPage / (_totalPages - 1);

  // ── Pindah ke halaman berikutnya ─────────────────────
  void _nextPage() {
    // Validasi nama minimal 2 karakter
    if (_currentPage == 1 && _nameController.text.trim().length < 2) {
      _showSnack('Masukkan namamu terlebih dahulu ya! 😊');
      return;
    }
    // Validasi jawaban pertanyaan
    final qIndex = _currentPage - 2;
    if (_currentPage >= 2 && _currentPage <= 11 && _answers[qIndex] == null) {
      _showSnack('Pilih salah satu jawaban dulu ya! ✨');
      return;
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

  // ── Kembali ke halaman sebelumnya ────────────────────
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
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Simpan dan selesai ────────────────────────────────
  Future<void> _finishOnboarding() async {
    setState(() => _isSaving = true);
    final user = AppUser(
      name: _nameController.text.trim(),
      psychScore: _totalScore,
      createdAt: DateTime.now(),
    );
    await StorageService.saveUser(user);
    setState(() => _isSaving = false);
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress bar & tombol back ──────────────
            _buildTopBar(context),

            // ── PageView konten utama ───────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // navigasi manual
                children: [
                  _buildWelcomePage(context),
                  _buildNamePage(context),
                  ...List.generate(
                    10,
                    (i) => _buildQuestionPage(context, i),
                  ),
                  _buildResultPage(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // Widget: Top bar (progress + back button)
  // ─────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    final showBack = _currentPage > 0 && _currentPage < _totalPages - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              // Tombol back
              if (showBack)
                GestureDetector(
                  onTap: _prevPage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                )
              else
                const SizedBox(width: 36),

              const SizedBox(width: 12),

              // Label halaman
              Expanded(
                child: Text(
                  _currentPage == 0
                      ? 'Selamat Datang!'
                      : _currentPage == 1
                          ? 'Langkah 1 dari 11'
                          : _currentPage <= 11
                              ? 'Pertanyaan ${_currentPage - 1} dari 10'
                              : 'Selesai! 🎉',
                  style: GoogleFonts.poppins(
                    color: AppTheme.textS(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Nomor halaman
              Text(
                _currentPage == 0 ? '' : '$_currentPage/${_totalPages - 1}',
                style: GoogleFonts.poppins(
                  color: AppTheme.primaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          if (_currentPage > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                minHeight: 6,
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // Page 0: Selamat datang
  // ─────────────────────────────────────────────────────
  Widget _buildWelcomePage(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            // Ilustrasi logo
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF6BAE8A), Color(0xFF5B9FD5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 66),
            ),
            const SizedBox(height: 32),
            Text(
              'Fem-PhysicsMonitor',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppTheme.textP(context),
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Monitor kondisi psikismu melalui suara.\nKami di sini untuk menemanimu.',
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: AppTheme.textS(context),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            // Fitur singkat — kartu premium
            ...['🎤|Deteksi emosi dari suaramu', '📊|Pantau perkembangan psikis', '💡|Dapatkan saran yang personal']
                .map((item) {
              final parts = item.split('|');
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surface(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  boxShadow: AppTheme.cardShadow,
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(parts[0], style: const TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        parts[1],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textP(context),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.primaryColor.withValues(alpha: 0.5),
                      size: 20,
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 32),
            _buildNextButton('Mulai Sekarang 🚀', _nextPage),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // Page 1: Input nama
  // ─────────────────────────────────────────────────────
  Widget _buildNamePage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.person_rounded, color: AppTheme.primaryColor, size: 36),
          ),
          const SizedBox(height: 24),
          Text(
            'Hei! Siapa namamu?',
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.textP(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kami akan memanggilmu dengan namamu agar lebih personal.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textS(context),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 36),
          // TextField nama
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _nameController,
              autofocus: false,
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppTheme.textP(context),
              ),
              decoration: InputDecoration(
                hintText: 'Masukkan namamu...',
                hintStyle: GoogleFonts.poppins(
                  color: AppTheme.textH(context),
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: const Icon(Icons.badge_rounded, color: AppTheme.primaryColor),
                filled: true,
                fillColor: AppTheme.surface(context),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
              ),
            ),
          ),
          const Spacer(),
          _buildNextButton('Lanjut →', _nextPage),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Selanjutnya: 10 pertanyaan singkat tentang kondisimu',
              style: GoogleFonts.poppins(
                color: AppTheme.textH(context),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // Page 2–11: Pertanyaan psikis
  // ─────────────────────────────────────────────────────
  Widget _buildQuestionPage(BuildContext context, int questionIndex) {
    final q = onboardingQuestions[questionIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Label kategori
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.15),
                  AppTheme.primaryColor.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Text(
              q.category,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 18),
          // Teks pertanyaan
          Text(
            q.question,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textP(context),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          // 4 pilihan jawaban
          Expanded(
            child: ListView.builder(
              itemCount: q.options.length,
              padding: EdgeInsets.zero,
              itemBuilder: (ctx, optIdx) {
                final isSelected = _answers[questionIndex] == optIdx;
                return GestureDetector(
                  onTap: () {
                    setState(() => _answers[questionIndex] = optIdx);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor.withValues(alpha: 0.08)
                          : AppTheme.surface(context),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryColor.withValues(alpha: 0.18),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : AppTheme.cardShadow,
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Radio indicator
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.surface(context),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : AppTheme.textH(context),
                              width: 2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white, size: 16)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            q.options[optIdx],
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : AppTheme.textP(context),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _buildNextButton(
            questionIndex == 9 ? 'Lihat Hasilku 🌟' : 'Lanjut →',
            _nextPage,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // Page 12: Hasil assessment
  // ─────────────────────────────────────────────────────
  Widget _buildResultPage(BuildContext context) {
    final name = _nameController.text.trim().isEmpty
        ? 'Kamu'
        : _nameController.text.trim();
    final score = _totalScore;
    final maxScore = 40;

    // Tentukan level psikis sementara untuk tampilan
    PsychLevel level;
    if (score >= 35) {
      level = PsychLevel.excellent;
    } else if (score >= 27) {
      level = PsychLevel.good;
    } else if (score >= 20) {
      level = PsychLevel.fair;
    } else {
      level = PsychLevel.needsAttention;
    }

    final progressValue = score / maxScore;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Ilustrasi hasil
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF6BAE8A), Color(0xFF5B9FD5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(level.emoji, style: const TextStyle(fontSize: 52)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Hai, $name! 👋',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.textP(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Berdasarkan jawabanmu, kondisi psikismu:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textS(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Badge level
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6BAE8A), Color(0xFF7DD3C0)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                '${level.emoji} ${level.label}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Skor bar
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Skor Psikismu',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textP(context),
                        ),
                      ),
                      Text(
                        '$score / $maxScore',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progressValue,
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      minHeight: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Saran awal (2 saran pertama)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded,
                          color: AppTheme.primaryColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Saran Awal Untukmu',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textP(context),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...level.overallSuggestions.take(2).map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('✨ ', style: TextStyle(fontSize: 14)),
                          Expanded(
                            child: Text(
                              s,
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
            ),
            const SizedBox(height: 24),
            // Tombol masuk
            _isSaving
                ? const CircularProgressIndicator(color: AppTheme.primaryColor)
                : _buildNextButton('Masuk ke Aplikasi 🚀', _finishOnboarding),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // Helper: tombol aksi utama
  // ─────────────────────────────────────────────────────
  Widget _buildNextButton(String label, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
