import 'package:flutter/material.dart';
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
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress bar & tombol back ──────────────
            _buildTopBar(),

            // ── PageView konten utama ───────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // navigasi manual
                children: [
                  _buildWelcomePage(),
                  _buildNamePage(),
                  ...List.generate(
                    10,
                    (i) => _buildQuestionPage(i),
                  ),
                  _buildResultPage(),
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
  Widget _buildTopBar() {
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
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Nomor halaman
              Text(
                _currentPage == 0 ? '' : '$_currentPage/${_totalPages - 1}',
                style: TextStyle(
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
  Widget _buildWelcomePage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ilustrasi
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 72),
            ),
            const SizedBox(height: 32),
            const Text(
              'Fem-PhysicsMonitor',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Monitor kondisi psikismu melalui suara.\nKami di sini untuk menemanimu.',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // Fitur singkat
            ...[
              ('🎤', 'Deteksi emosi dari suaramu'),
              ('📊', 'Pantau perkembangan psikis'),
              ('💡', 'Dapatkan saran yang personal'),
            ].map(
              (f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Text(f.$1, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Text(
                      f.$2,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),
            _buildNextButton('Mulai Sekarang 🚀', _nextPage),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // Page 1: Input nama
  // ─────────────────────────────────────────────────────
  Widget _buildNamePage() {
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
          const Text(
            'Hei! Siapa namamu?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kami akan memanggilmu dengan namamu agar lebih personal.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 36),
          // TextField nama
          TextField(
            controller: _nameController,
            autofocus: false,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Masukkan namamu...',
              hintStyle: TextStyle(
                color: AppTheme.textSecondary.withValues(alpha: 0.6),
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Icon(Icons.badge_rounded, color: AppTheme.primaryColor),
              filled: true,
              fillColor: AppTheme.surfaceColor,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
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
                vertical: 16,
              ),
            ),
          ),
          const Spacer(),
          _buildNextButton('Lanjut →', _nextPage),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Selanjutnya: 10 pertanyaan singkat tentang kondisimu',
              style: TextStyle(
                color: AppTheme.textSecondary,
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
  Widget _buildQuestionPage(int questionIndex) {
    final q = onboardingQuestions[questionIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Label kategori
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              q.category,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Teks pertanyaan
          Text(
            q.question,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          // 4 pilihan jawaban
          ...List.generate(q.options.length, (optIdx) {
            final isSelected = _answers[questionIndex] == optIdx;
            return GestureDetector(
              onTap: () {
                setState(() => _answers[questionIndex] = optIdx);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor.withValues(alpha: 0.12)
                      : AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.primaryColor.withValues(alpha: 0.2),
                    width: isSelected ? 2 : 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    // Radio indicator
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.textSecondary.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 14)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        q.options[optIdx],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const Spacer(),
          _buildNextButton(
            questionIndex == 9 ? 'Lihat Hasilku 🌟' : 'Lanjut →',
            _nextPage,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // Page 12: Hasil assessment
  // ─────────────────────────────────────────────────────
  Widget _buildResultPage() {
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
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(level.emoji, style: const TextStyle(fontSize: 52)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Hai, $name! 👋',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Berdasarkan jawabanmu, kondisi psikismu:',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Badge level
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.accentColor],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                '${level.emoji} ${level.label}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Skor bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Skor Psikismu',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '$score / $maxScore',
                        style: const TextStyle(
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.secondaryColor.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          color: AppTheme.primaryColor, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Saran Awal Untukmu',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
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
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
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
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // Helper: tombol aksi utama
  // ─────────────────────────────────────────────────────
  Widget _buildNextButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
