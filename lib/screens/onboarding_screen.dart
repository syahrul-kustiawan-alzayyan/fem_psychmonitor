import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';
import '../services/database_service.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_screen.dart';

/// Onboarding Screen untuk pengguna baru.
/// Flow: Selamat datang → Skip MBTI question → (Manual MBTI input | 20 pertanyaan MBTI) → 10 Pertanyaan Psikologis → Hasil MBTI → Hasil Psikologis
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onCompleted;

  const OnboardingScreen({super.key, required this.onCompleted});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();

  // Halaman dinamis
  int _currentPage = 0;

  // Data yang dikumpulkan
  final TextEditingController _nameController = TextEditingController();
  final List<int?> _answers = List.filled(20, null); // 0=opsi A, 1=opsi B
  final List<int?> _psyAnswers = List.filled(10, null); // 0-3 scale

  // Flow state
  bool _mbtiSkipped = false; // true = user sudah tahu MBTI-nya
  bool _showManualMbti = false; // true = user pilih manual input

  // Psychological scoring
  int _psyScore = 0;

  bool _isSaving = false;

  // Animasi
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Hasil MBTI
  String _mbtiType = '';
  Map<String, int> _mbtiScores = {};

  int get _totalPages {
    int pages = 2; // welcome, skip MBTI question
    if (_mbtiSkipped) {
      if (_showManualMbti) pages += 1; // manual MBTI input
    } else {
      pages += 21; // 20 MBTI questions + 1 result
    }
    pages += 1; // info page
    pages += 10; // 10 psychological questions
    pages += 1; // psychological result
    return pages;
  }

  int get _mbtiStartPage => 2;
  int get _mbtiEndPage {
    if (_mbtiSkipped) {
      // Manual MBTI: page 2 saja
      return 3;
    } else {
      // 20 questions (2-21) + result (22)
      return 23;
    }
  }

  int get _psyStartPage {
    // Setelah info page
    return _mbtiSkipped ? 4 : 24;
  }

  int get _psyEndPage => _psyStartPage + 10;

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
    // Halaman skip MBTI (page 1)
    if (_currentPage == 1) {
      if (_mbtiSkipped && !_showManualMbti) {
        // User sudah tahu MBTI tapi pilih manual input → sudah handled
      }
      if (!_mbtiSkipped) {
        // User belum tahu MBTI → lanjut ke MBTI questions (sudah handled oleh state)
      }
      setState(() => _currentPage++);
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      return;
    }

    // Halaman manual MBTI input
    if (_mbtiSkipped && _showManualMbti && _currentPage == 2) {
      if (_mbtiType.isEmpty) {
        _showSnack('Pilih tipe MBTI Anda terlebih dahulu!');
        return;
      }
      setState(() {
        _currentPage++;
      });
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      return;
    }

    // Validasi jawaban MBTI
    if (!_mbtiSkipped) {
      final qIndex = _currentPage - _mbtiStartPage;
      if (_currentPage >= _mbtiStartPage &&
          _currentPage < _mbtiEndPage &&
          _answers[qIndex] == null) {
        _showSnack('Pilih salah satu jawaban dulu ya! ✨');
        return;
      }

      // Hitung MBTI saat semua pertanyaan selesai
      if (_currentPage == _mbtiEndPage - 1) {
        final result = calculateMBTI(_answers.map((e) => e ?? 0).toList());
        _mbtiType = result.type;
        _mbtiScores = result.scores;
      }
    }

    // Validasi jawaban psikologis
    if (_currentPage >= _psyStartPage && _currentPage < _psyEndPage) {
      final psyIndex = _currentPage - _psyStartPage;
      if (_psyAnswers[psyIndex] == null) {
        _showSnack('Pilih salah satu jawaban dulu ya! ✨');
        return;
      }

      // Hitung skor psikologis saat semua pertanyaan selesai
      if (_currentPage == _psyEndPage - 1) {
        _psyScore = _psyAnswers.fold<int>(0, (sum, val) => sum + (val ?? 0));
        // Set MBTI type if skipped (manual input already set it)
        if (_mbtiSkipped && _mbtiType.isEmpty) {
          _mbtiType = 'XXXX';
          _mbtiScores = {
            'E': 0,
            'I': 0,
            'S': 0,
            'N': 0,
            'T': 0,
            'F': 0,
            'J': 0,
            'P': 0,
          };
        }
      }
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
      // If going back from manual MBTI page, clear error
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

    final provider = context.read<AuthProvider>();
    final userName = provider.username.isNotEmpty
        ? provider.username
        : 'Pengguna';

    final user = AppUser(
      name: userName,
      mbtiType: _mbtiType,
      mbtiScores: _mbtiScores,
      psychologicalScore: _psyScore,
      createdAt: DateTime.now(),
    );

    final int insertedId = await DatabaseService.insertUser(user);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pending_onboarding_user_id', insertedId);

    await StorageService.setOnboardingComplete(user.name);

    if (mounted) widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    // Force light theme agar tampilan onboarding konsisten
    // dengan splash screen, tidak terpengaruh tema aplikasi
    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFFEC4899), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Animated background circles (sama seperti splash)
                ...List.generate(3, (index) {
                  return Positioned.fill(
                    child: CustomPaint(
                      painter: _OnboardingCirclePainter(
                        index: index,
                        animation: _fadeController.value,
                      ),
                    ),
                  );
                }),
                Column(
                  children: [
                    // ── Progress bar + Back button ──
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          if (_currentPage > 0 &&
                              _currentPage < _totalPages - 1)
                            GestureDetector(
                              onTap: _prevPage,
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 16,
                                  color: Colors.white,
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
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.2,
                                ),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
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
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Page Content ──
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _totalPages,
                        itemBuilder: (context, index) {
                          final pages = _buildPages();
                          return index < pages.length
                              ? pages[index]
                              : const SizedBox.shrink();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
            // Logo dengan glassmorphism effect
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Image.asset(
                          'lib/src/logo.jpeg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 36),
            Text(
              'Selamat Datang! 👋',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    offset: const Offset(0, 2),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Text(
                'Fem-PhysicsMonitor akan membantu kamu memahami emosi melalui analisis suara dan kepribadian.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  color: Colors.white.withValues(alpha: 0.95),
                  height: 1.7,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Info badge with glassmorphism
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.quiz_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '20 pertanyaan MBTI (~5 menit)',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            _buildNextButton('Mulai Sekarang'),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                );
              },
              child: Text(
                'Sudah punya akun? Masuk',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Dynamic page builder
  // ─────────────────────────────────────────────────────────────
  List<Widget> _buildPages() {
    final pages = <Widget>[_buildWelcomePage(), _buildMbtiSkipPage()];

    // MBTI Section
    if (_mbtiSkipped) {
      if (_showManualMbti) {
        pages.add(_buildManualMbtiPage());
      }
    } else {
      for (int i = 0; i < 20; i++) {
        pages.add(_buildMBTIQuestionPage(i));
      }
      pages.add(_buildMbtiResultPage());
    }

    // Info Page (setelah MBTI section selesai)
    pages.add(_buildInfoPage());

    // Psychological Questionnaire
    for (int i = 0; i < 10; i++) {
      pages.add(_buildPsyQuestionPage(i));
    }

    pages.add(_buildPsyResultPage());

    return pages;
  }

  // ─────────────────────────────────────────────────────────────
  // Page: MBTI Skip Question
  // ─────────────────────────────────────────────────────────────
  Widget _buildMbtiSkipPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with glassmorphism
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: const Icon(
                Icons.psychology_rounded,
                size: 44,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Apakah Anda sudah mengetahui tipe MBTI Anda?',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Text(
              'Jika sudah, Anda bisa langsung mengetikkannya. Jika belum, kami akan membantu Anda mengetahuinya melalui 20 pertanyaan.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 36),
          // YES button with modern design
          Container(
            width: double.infinity,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _mbtiSkipped = true;
                  _showManualMbti = true;
                });
                // Navigate to manual input page
                Future.delayed(const Duration(milliseconds: 200), () {
                  if (mounted) {
                    setState(() => _currentPage++);
                    _pageController.jumpToPage(_currentPage);
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.check_circle_rounded, size: 22),
              label: Text(
                'Ya, Saya Sudah Tahu',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          // NO button with glassmorphism
          SizedBox(
            width: double.infinity,
            height: 58,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _mbtiSkipped = false;
                  _showManualMbti = false;
                });
                // Rebuild pages
                setState(() {});
                // Navigate to first MBTI question
                Future.delayed(const Duration(milliseconds: 100), () {
                  setState(() => _currentPage++);
                  _pageController.animateToPage(
                    _currentPage,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                  );
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                backgroundColor: Colors.white.withValues(alpha: 0.08),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 20),
              label: Text(
                'Belum, Saya Ingin Tes',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Page: Info - Penjelasan MBTI vs Kesehatan Mental
  // ─────────────────────────────────────────────────────────────
  Widget _buildInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.white, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Memahami Perbedaan',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'MBTI vs Kesehatan Mental',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // MBTI Section
          _buildInfoCard(
            icon: Icons.psychology_rounded,
            iconColor: const Color(0xFF3B82F6),
            title: 'Apa itu MBTI?',
            description:
                'MBTI (Myers-Briggs Type Indicator) adalah kuesioner kepribadian yang membantu Anda memahami tipe kepribadian dasar Anda.',
            points: const [
              '✨ Mengidentifikasi 16 tipe kepribadian berbeda',
              '🎯 Berfokus pada preferensi alami Anda',
              '📊 Bukan alat diagnosis medis',
              '💡 Membantu memahami kekuatan & kelemahan diri',
            ],
          ),
          const SizedBox(height: 20),

          // Mental Health Section
          _buildInfoCard(
            icon: Icons.favorite_rounded,
            iconColor: const Color(0xFFEC4899),
            title: 'Kuesioner Kesehatan Mental',
            description:
                'Kuesioner ini dirancang untuk membantu Anda memahami tingkat stres, beban mental, dan kesejahteraan emosional sehari-hari.',
            points: const [
              '🧠 10 pertanyaan refleksi diri',
              '⚠️ BUKAN alat diagnosis medis',
              '📈 Memberikan gambaran kondisi mental Anda',
              '💚 Disertai saran yang sesuai dengan skor Anda',
            ],
          ),
          const SizedBox(height: 24),

          // Important Notice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF59E0B), width: 2),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFF59E0B),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Catatan Penting',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Kedua kuesioner ini adalah alat bantu pemetaan mandiri (self-assessment) dan BUKAN pengganti diagnosis profesional. Jika Anda merasa kewalahan secara terus-menerus, sangat disarankan untuk berkonsultasi dengan psikolog atau psikiater.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textS(context),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Continue button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(
                'Lanjut ke Pertanyaan',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Helper widget untuk info card
  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required List<String> points,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
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
                  color: iconColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      point.substring(0, 2),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      point.substring(2),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
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

  // ─────────────────────────────────────────────────────────────
  // Page: Manual MBTI Input
  // ─────────────────────────────────────────────────────────────
  Widget _buildManualMbtiPage() {
    // Daftar 16 tipe MBTI
    final mbtiTypes = [
      'INTJ',
      'INTP',
      'ENTJ',
      'ENTP',
      'INFJ',
      'INFP',
      'ENFJ',
      'ENFP',
      'ISTJ',
      'ISFJ',
      'ESTJ',
      'ESFJ',
      'ISTP',
      'ISFP',
      'ESTP',
      'ESFP',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // Icon
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.psychology_rounded,
              size: 36,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          // Title
          Text(
            'Pilih Tipe MBTI',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pilih salah satu tipe MBTI di bawah ini:',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),

          // Grid of MBTI Buttons
          GridView.builder(
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
              final isSelected = _mbtiType == type;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _mbtiType = type;
                    _mbtiScores = {
                      'E': type[0] == 'E' ? 5 : 0,
                      'I': type[0] == 'I' ? 5 : 0,
                      'S': type[1] == 'S' ? 5 : 0,
                      'N': type[1] == 'N' ? 5 : 0,
                      'T': type[2] == 'T' ? 5 : 0,
                      'F': type[2] == 'F' ? 5 : 0,
                      'J': type[3] == 'J' ? 5 : 0,
                      'P': type[3] == 'P' ? 5 : 0,
                    };
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    type,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: isSelected ? AppTheme.primaryColor : Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 36),
          _buildNextButton('Konfirmasi & Lanjut'),
          const SizedBox(height: 40),
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
          // Dimension badge with glassmorphism
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(dimInfo.$1, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  '${dimInfo.$2} · Pertanyaan $questionNum/20',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Question text with better spacing
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Text(
              q.question,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.5,
              ),
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
          const SizedBox(height: 16),
          // VS divider with modern design
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: Text(
                'ATAU',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.8),
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.2),
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Label badge with glassmorphism
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Text
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.9),
                  height: 1.5,
                ),
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Page: Psychological Questionnaire
  // ─────────────────────────────────────────────────────────────
  Widget _buildPsyQuestionPage(int index) {
    final q = psyQuestions[index];
    final selected = _psyAnswers[index];
    final questionNum = index + 1;

    final scaleLabels = [
      ('0', 'Tidak pernah', const Color(0xFF22C55E)),
      ('1', 'Jarang', const Color(0xFF84CC16)),
      ('2', 'Sering', const Color(0xFFF59E0B)),
      ('3', 'Hampir setiap hari', const Color(0xFFEF4444)),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Question badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  'Kesehatan Mental · Pertanyaan $questionNum/10',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Question title
          Text(
            q.title,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            q.subtitle,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          // Scale options
          ...List.generate(4, (i) {
            final opt = scaleLabels[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildPsyOptionCard(
                value: i,
                label: opt.$1,
                description: opt.$2,
                color: opt.$3,
                isSelected: selected == i,
                onTap: () {
                  setState(() => _psyAnswers[index] = i);
                  Future.delayed(const Duration(milliseconds: 300), _nextPage);
                },
              ),
            );
          }),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPsyOptionCard({
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
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.2),
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Value badge with glassmorphism
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Description
            Expanded(
              child: Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Page: MBTI Result
  // ─────────────────────────────────────────────────────────────
  Widget _buildMbtiResultPage() {
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
          // Confetti-like header with glassmorphism
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Text('🎉', style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 8),
                Text(
                  'Hasil MBTI-mu!',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Halo ${user.name}, ini kepribadianmu:',
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // MBTI Type Card with enhanced design
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 0,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.psychology_rounded,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                // Type letters
                Text(
                  _mbtiType,
                  style: GoogleFonts.poppins(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 10,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        offset: const Offset(0, 4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.mbtiNickname,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Description card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Tentang Kepribadianmu',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  user.mbtiDescription,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Strengths with glassmorphism
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Kekuatan Utama',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: user.mbtiStrengths.map((s) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        '✨ $s',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Dimension scores
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.bar_chart_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Skor Dimensi',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
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

  // ─────────────────────────────────────────────────────────────
  // Page: Psychological Result
  // ─────────────────────────────────────────────────────────────
  Widget _buildPsyResultPage() {
    String category;
    String advice;
    Color cardColor;
    IconData categoryIcon;

    if (_psyScore <= 10) {
      category = 'Baik (Kondisi Mental Stabil)';
      advice =
          'Kondisi mental Anda saat ini dalam keadaan baik. Anda mampu mengelola stres dengan efektif dan memiliki ketahanan emosional yang kuat. Pertahankan kebiasaan positif Anda, tetap jaga keseimbangan hidup, dan jangan ragu untuk terus merawat kesejahteraan mental Anda.';
      cardColor = const Color(0xFF22C55E); // Green
      categoryIcon = Icons.check_circle_rounded;
    } else if (_psyScore <= 20) {
      category = 'Cukup (Rentan Stres / Butuh Istirahat)';
      advice =
          'Anda menunjukkan beberapa tanda tekanan emosional. Mungkin Anda sedang menghadapi tantangan yang cukup berat. Disarankan untuk lebih memperhatikan self-care, mengatur waktu istirahat yang cukup, berolahraga secara rutin, dan berbicara dengan orang terdekat tentang apa yang Anda rasakan. Jika diperlukan, pertimbangkan untuk berkonsultasi dengan profesional.';
      cardColor = const Color(0xFFF59E0B); // Yellow/Amber
      categoryIcon = Icons.warning_amber_rounded;
    } else {
      category = 'Butuh Perhatian (Distres Signifikan)';
      advice =
          'Skor Anda menunjukkan adanya tekanan emosional yang signifikan. Anda mungkin sedang mengalami beban psikologis yang cukup berat. Kami sangat menyarankan Anda untuk segera berkonsultasi dengan psikolog atau profesional kesehatan mental. Ingat, mencari bantuan adalah tanda kekuatan, bukan kelemahan. Anda tidak sendirian.';
      cardColor = const Color(0xFFEF4444); // Red
      categoryIcon = Icons.error_rounded;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Header with glassmorphism
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Text('🧠', style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 12),
                Text(
                  'Hasil Analisis Kesehatan Mental',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Berdasarkan 10 pertanyaan yang Anda jawab',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Score card with modern design
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: cardColor.withValues(alpha: 0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: cardColor.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 0,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(categoryIcon, size: 56, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  'Skor Anda: $_psyScore / 30',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        offset: const Offset(0, 4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    category,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Advice card
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
                    Icon(Icons.lightbulb_rounded, color: cardColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Saran & Rekomendasi',
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
                  advice,
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

          // Scale interpretation
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
                      'Interpretasi Skor',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textP(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildScoreIndicator(
                  0,
                  10,
                  'Baik',
                  'Kondisi Mental Stabil',
                  const Color(0xFF22C55E),
                  _psyScore,
                ),
                const SizedBox(height: 12),
                _buildScoreIndicator(
                  11,
                  20,
                  'Cukup',
                  'Rentan Stres / Butuh Istirahat',
                  const Color(0xFFF59E0B),
                  _psyScore,
                ),
                const SizedBox(height: 12),
                _buildScoreIndicator(
                  21,
                  30,
                  'Perlu Perhatian',
                  'Distres Signifikan',
                  const Color(0xFFEF4444),
                  _psyScore,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Disclaimer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfVar(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.surfVar(context)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppTheme.textS(context),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '⚠️ Disclaimer: Hasil ini BUKAN merupakan diagnosa medis atau klinis. Ini hanyalah alat bantu awal untuk membantu Anda memahami kondisi mental Anda. Untuk diagnosa yang akurat, silakan konsultasikan dengan profesional kesehatan mental.',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: AppTheme.textS(context),
                      height: 1.5,
                    ),
                  ),
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

  Widget _buildScoreIndicator(
    int min,
    int max,
    String label,
    String desc,
    Color color,
    int currentScore,
  ) {
    final isActive = currentScore >= min && currentScore <= max;
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isActive ? color : color.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$min-$max: $label',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? color : AppTheme.textS(context),
            ),
          ),
        ),
        Text(
          desc,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? color : AppTheme.textH(context),
          ),
        ),
        if (isActive) ...[
          const SizedBox(width: 8),
          Icon(Icons.arrow_right_rounded, color: color, size: 20),
        ],
      ],
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
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.primaryColor,
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

// ─────────────────────────────────────────────────────────────
// Animated Circle Painter for Onboarding (sama seperti Splash)
// ─────────────────────────────────────────────────────────────
class _OnboardingCirclePainter extends CustomPainter {
  final int index;
  final double animation;

  _OnboardingCirclePainter({required this.index, required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05 + (index * 0.03))
      ..style = PaintingStyle.fill;

    final radius = 100 + (index * 80) + (animation * 30);
    final offset = Offset(
      size.width * (0.3 + (index * 0.2)),
      size.height * (0.2 + (index * 0.15)),
    );

    canvas.drawCircle(offset, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _OnboardingCirclePainter oldDelegate) => true;
}

// ─────────────────────────────────────────────────────────────
// Psychological Questionnaire Data
// ─────────────────────────────────────────────────────────────
class PsyQuestion {
  final String title;
  final String subtitle;

  const PsyQuestion({required this.title, required this.subtitle});
}

const List<PsyQuestion> psyQuestions = [
  PsyQuestion(
    title: 'Kelelahan Fisik & Mental',
    subtitle:
        'Seberapa sering Anda merasa kelelahan, kehabisan energi, atau "kosong", meskipun sudah tidur atau beristirahat?',
  ),
  PsyQuestion(
    title: 'Tingkat Kecemasan',
    subtitle:
        'Apakah Anda sering merasa cemas, gelisah, atau khawatir berlebihan terhadap hal-hal yang belum tentu terjadi?',
  ),
  PsyQuestion(
    title: 'Kualitas Tidur',
    subtitle:
        'Seberapa sering Anda mengalami gangguan tidur, seperti sulit mulai tidur, sering terbangun di tengah malam, atau justru tidur terlalu banyak?',
  ),
  PsyQuestion(
    title: 'Beban Peran (Overwhelmed)',
    subtitle:
        'Seberapa sering Anda merasa sangat kewalahan dengan berbagai peran dan tuntutan sehari-hari?',
  ),
  PsyQuestion(
    title: 'Stabilitas Suasana Hati',
    subtitle:
        'Apakah Anda merasa sedih, murung, atau ingin menangis tanpa alasan yang benar-benar jelas?',
  ),
  PsyQuestion(
    title: 'Kehilangan Minat',
    subtitle:
        'Seberapa sering Anda merasa malas atau kehilangan kebahagiaan saat melakukan aktivitas yang biasanya Anda sukai?',
  ),
  PsyQuestion(
    title: 'Toleransi Emosi',
    subtitle:
        'Apakah Anda menyadari bahwa Anda menjadi lebih mudah tersinggung, cepat marah, atau kehilangan kesabaran?',
  ),
  PsyQuestion(
    title: 'Fokus & Konsentrasi',
    subtitle:
        'Seberapa sering Anda merasa otak seperti "berkabut" (brain fog), sulit berkonsentrasi, atau sulit mengambil keputusan?',
  ),
  PsyQuestion(
    title: 'Dukungan Sosial',
    subtitle:
        'Apakah Anda merasa sendirian, terisolasi, atau merasa tidak ada orang yang benar-benar memahami beban perasaan Anda?',
  ),
  PsyQuestion(
    title: 'Kritik Diri Sendiri',
    subtitle:
        'Seberapa sering Anda mengkritik diri sendiri secara tajam, merasa bersalah terus-menerus, atau merasa kurang berharga?',
  ),
];
