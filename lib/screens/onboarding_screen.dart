import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

/// Onboarding Screen untuk pengguna baru.
/// Flow: Selamat datang → Input nama → Skip MBTI question → (Manual MBTI input | 20 pertanyaan MBTI) → 10 Pertanyaan Psikologis → Hasil MBTI → Hasil Psikologis
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
  final TextEditingController _manualMbtiController = TextEditingController();
  final List<int?> _answers = List.filled(20, null); // 0=opsi A, 1=opsi B
  final List<int?> _psyAnswers = List.filled(10, null); // 0-3 scale

  // Flow state
  bool _mbtiSkipped = false; // true = user sudah tahu MBTI-nya
  bool _showManualMbti = false; // true = user pilih manual input
  String _manualMbtiError = '';

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
    // 0=welcome, 1=nama, 2=skip MBTI question
    int pages = 3;
    if (_mbtiSkipped) {
      if (_showManualMbti) pages += 1; // manual MBTI input
    } else {
      pages += 20; // 20 MBTI questions
    }
    pages += 10; // 10 psychological questions
    pages += 2; // MBTI result + psychological result
    return pages;
  }

  int get _mbtiStartPage => 3;
  int get _mbtiEndPage {
    if (_mbtiSkipped) {
      return _showManualMbti ? 4 : 3;
    }
    return 3 + 20;
  }

  int get _psyStartPage => _mbtiEndPage;
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
    // Validasi nama
    if (_currentPage == 1 && _nameController.text.trim().length < 2) {
      _showSnack('Masukkan namamu terlebih dahulu ya! 😊');
      return;
    }

    // Halaman skip MBTI (page 2)
    if (_currentPage == 2) {
      // _mbtiSkipped sudah di-set oleh tombol YES/NO
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
    if (_mbtiSkipped && _showManualMbti && _currentPage == 3) {
      final input = _manualMbtiController.text.trim().toUpperCase();
      final validTypes = [
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
      if (validTypes.contains(input)) {
        _mbtiType = input;
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
        // Parse the type into scores
        if (input.startsWith('E'))
          _mbtiScores['E'] = 5;
        else
          _mbtiScores['I'] = 5;
        if (input[1] == 'S')
          _mbtiScores['S'] = 5;
        else
          _mbtiScores['N'] = 5;
        if (input[2] == 'T')
          _mbtiScores['T'] = 5;
        else
          _mbtiScores['F'] = 5;
        if (input[3] == 'J')
          _mbtiScores['J'] = 5;
        else
          _mbtiScores['P'] = 5;
        setState(() {
          _manualMbtiError = '';
          _currentPage++;
        });
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      } else {
        setState(
          () => _manualMbtiError =
              'Tipe MBTI tidak valid. Contoh: INTJ, ENFP, dll.',
        );
        _showSnack(
          'Tipe MBTI tidak valid. Gunakan format seperti INTJ, ENFP, dll.',
        );
      }
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
      if (_mbtiSkipped && _showManualMbti && _currentPage == 4) {
        setState(() => _manualMbtiError = '');
      }
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
                children: _buildPages(),
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
  // Dynamic page builder
  // ─────────────────────────────────────────────────────────────
  List<Widget> _buildPages() {
    final pages = <Widget>[
      _buildWelcomePage(),
      _buildNamePage(),
      _buildMbtiSkipPage(),
    ];

    if (_mbtiSkipped) {
      if (_showManualMbti) {
        pages.add(_buildManualMbtiPage());
      }
    } else {
      for (int i = 0; i < 20; i++) {
        pages.add(_buildMBTIQuestionPage(i));
      }
    }

    for (int i = 0; i < 10; i++) {
      pages.add(_buildPsyQuestionPage(i));
    }

    pages.add(_buildMbtiResultPage());
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
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.psychology_rounded,
              size: 36,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Apakah Anda sudah mengetahui tipe MBTI Anda?',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textP(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Jika sudah, Anda bisa langsung mengetikkannya. Jika belum, kami akan membantu Anda mengetahuinya melalui 20 pertanyaan.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.textS(context),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          // YES button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _mbtiSkipped = true;
                  _showManualMbti = true;
                });
                // Rebuild pages
                setState(() {});
                // Navigate to manual input page
                Future.delayed(const Duration(milliseconds: 100), () {
                  setState(() => _currentPage++);
                  _pageController.animateToPage(
                    _currentPage,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                  );
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.check_circle_rounded),
              label: Text(
                'Ya, Saya Sudah Tahu',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // NO button
          SizedBox(
            width: double.infinity,
            height: 54,
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
                foregroundColor: AppTheme.secondaryColor,
                side: const BorderSide(
                  color: AppTheme.secondaryColor,
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(
                'Belum, Saya Ingin Tes',
                style: GoogleFonts.poppins(
                  fontSize: 15,
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
  // Page: Manual MBTI Input
  // ─────────────────────────────────────────────────────────────
  Widget _buildManualMbtiPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.edit_rounded,
              size: 36,
              color: AppTheme.secondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Masukkan Tipe MBTI Anda',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textP(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ketik tipe MBTI yang sudah Anda ketahui',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.textS(context),
            ),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _manualMbtiController,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
              color: AppTheme.textP(context),
            ),
            decoration: InputDecoration(
              hintText: 'INTJ, ENFP, dll.',
              hintStyle: GoogleFonts.poppins(
                fontSize: 16,
                color: AppTheme.textH(context),
              ),
              filled: true,
              fillColor: AppTheme.surfVar(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: _manualMbtiError.isNotEmpty
                      ? Colors.red
                      : Colors.transparent,
                  width: 2,
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
                horizontal: 24,
                vertical: 18,
              ),
              errorText: _manualMbtiError.isNotEmpty ? _manualMbtiError : null,
            ),
          ),
          const SizedBox(height: 12),
          // Valid types hint
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
              ),
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children:
                  [
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
                  ].map((type) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        type,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 32),
          _buildNextButton('Lanjut'),
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
              color: AppTheme.secondaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.favorite_rounded,
                  size: 14,
                  color: AppTheme.secondaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Kesehatan Mental · Pertanyaan $questionNum/10',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.secondaryColor,
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
              color: AppTheme.textP(context),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            q.subtitle,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.textS(context),
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
        padding: const EdgeInsets.all(16),
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
            // Value badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? color : color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Description
            Expanded(
              child: Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: AppTheme.textP(context),
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
          // Header
          Text('🧠', style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Hasil Analisis Kesehatan Mental',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textP(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Berdasarkan 10 pertanyaan yang Anda jawab',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.textS(context),
            ),
          ),
          const SizedBox(height: 24),

          // Score card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: cardColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Icon(categoryIcon, size: 48, color: cardColor),
                const SizedBox(height: 12),
                Text(
                  'Skor Anda: $_psyScore / 30',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: cardColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  category,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textP(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

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
