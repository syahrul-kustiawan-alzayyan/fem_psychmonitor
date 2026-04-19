import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

/// Onboarding Screen untuk pengguna baru.
/// Flow: Selamat datang → Skip MBTI question → (Manual MBTI input | 20 pertanyaan MBTI) → 10 Pertanyaan Psikologis → Hasil MBTI → Hasil Psikologis
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onCompleted;

  const OnboardingScreen({super.key, required this.onCompleted});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  int _currentPage = 0;
  final TextEditingController _nameController = TextEditingController();
  List<int?> _answers = [];
  List<int?> _psyAnswers = [];
  List<MBTIQuestion> _mbtiQuestions = [];
  List<PsyQuestion> _psyQuestions = [];
  bool _isLoading = true;

  bool _mbtiSkipped = false;
  bool _showManualMbti = false;
  int _psyScore = 0;
  bool _isSaving = false;

  String _mbtiType = '';
  Map<String, int> _mbtiScores = {};

  int get _totalPages {
    int pages = 2;
    if (_mbtiSkipped) {
      if (_showManualMbti) pages += 1;
    } else {
      pages += _mbtiQuestions.length + 1; // +1 for MBTI result
    }
    pages += 1; // info page
    pages += _psyQuestions.length; // psychological questions
    pages += 1; // psychological result
    return pages;
  }

  int get _mbtiStartPage => 2;
  int get _mbtiEndPage {
    if (_mbtiSkipped) {
      return 3;
    } else {
      return _mbtiStartPage + _mbtiQuestions.length; // until the last MBTI question
    }
  }

  int get _psyStartPage {
    return _mbtiSkipped ? 4 : _mbtiStartPage + _mbtiQuestions.length + 2; // info page is included
  }

  int get _psyEndPage => _psyStartPage + _psyQuestions.length;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final mbtiString = await rootBundle.loadString('assets/MBTI.json');
      final mbtiJson = jsonDecode(mbtiString);
      final mbtiList = (mbtiJson['mbti_questionnaire'] as List)
          .map((q) => MBTIQuestion.fromJson(q))
          .toList();

      final psyString = await rootBundle.loadString('assets/psych.json');
      final psyJson = jsonDecode(psyString);
      final psyList = (psyJson['womens_mental_health_assessment']['questions'] as List)
          .map((q) => PsyQuestion.fromJson(q))
          .toList();

      if (mounted) {
        setState(() {
          _mbtiQuestions = mbtiList;
          _psyQuestions = psyList;
          _answers = List.filled(_mbtiQuestions.length, null);
          _psyAnswers = List.filled(_psyQuestions.length, null);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading questions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  double get _progress => _totalPages > 1 ? _currentPage / (_totalPages - 1) : 0.0;

  void _nextPage() {
    if (_currentPage == 1) {
      setState(() => _currentPage++);
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      return;
    }

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

    if (!_mbtiSkipped) {
      final qIndex = _currentPage - _mbtiStartPage;
      if (_currentPage >= _mbtiStartPage &&
          _currentPage < _mbtiEndPage &&
          _answers[qIndex] == null) {
        _showSnack('Pilih salah satu jawaban dulu ya! ✨');
        return;
      }

      if (_currentPage == _mbtiEndPage - 1) {
        final result = calculateMBTI(_answers.map((e) => e ?? 0).toList(), _mbtiQuestions);
        _mbtiType = result.type;
        _mbtiScores = result.scores;
      }
    }

    if (_currentPage >= _psyStartPage && _currentPage < _psyEndPage) {
      final psyIndex = _currentPage - _psyStartPage;
      if (_psyAnswers[psyIndex] == null) {
        _showSnack('Pilih salah satu jawaban dulu ya! ✨');
        return;
      }

      if (_currentPage == _psyEndPage - 1) {
        _psyScore = _psyAnswers.fold<int>(0, (sum, val) => sum + (val ?? 0));
        if (_mbtiSkipped && _mbtiType.isEmpty) {
          _mbtiType = 'XXXX';
          _mbtiScores = {
            'E': 0, 'I': 0, 'S': 0, 'N': 0, 'T': 0, 'F': 0, 'J': 0, 'P': 0,
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
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
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
    final userName = provider.username.isNotEmpty ? provider.username : 'Pengguna';

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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.bg(context),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: SafeArea(
        child: Column(
          children: [
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
                          color: AppTheme.surface(context),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: AppTheme.cardShadow,
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
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _totalPages,
                itemBuilder: (context, index) {
                  final pages = _buildPages();
                  return index < pages.length ? pages[index] : const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPages() {
    final pages = <Widget>[_buildWelcomePage(), _buildMbtiSkipPage()];
    if (_mbtiSkipped) {
      if (_showManualMbti) pages.add(_buildManualMbtiPage());
    } else {
      for (int i = 0; i < _mbtiQuestions.length; i++) pages.add(_buildMBTIQuestionPage(i));
      pages.add(_buildMbtiResultPage());
    }
    pages.add(_buildInfoPage());
    for (int i = 0; i < _psyQuestions.length; i++) pages.add(_buildPsyQuestionPage(i));
    pages.add(_buildPsyResultPage());
    return pages;
  }

  // BUILD WELCOME PAGE
  Widget _buildWelcomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryColor, width: 2),
              boxShadow: AppTheme.cardShadow,
            ),
            child: ClipOval(
              child: Image.asset('assets/logo.png', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 36),
          Text(
            'Selamat Datang! 👋',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.textP(context),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Text(
              'Fem-Psych Monitor akan membantu kamu memahami emosi melalui analisis suara dan kepribadian.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14.5,
                color: AppTheme.textS(context),
                height: 1.7,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.secondaryColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_rounded, color: AppTheme.secondaryColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pahami dirimu, pantau kesehatan mentalmu, dan temukan ketenangan setiap hari.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textP(context),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          _buildNextButton('Mulai Sekarang'),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // BUILD SKIP PAGE
  Widget _buildMbtiSkipPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.psychology_rounded, size: 44, color: AppTheme.primaryColor),
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
              'Jika sudah, Anda bisa langsung mengetikkannya. Jika belum, kami akan membantu Anda mengetahuinya melalui ${_mbtiQuestions.length} pertanyaan.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: AppTheme.textS(context),
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _mbtiSkipped = true;
                  _showManualMbti = true;
                });
                Future.delayed(const Duration(milliseconds: 200), () {
                  if (mounted) {
                    setState(() => _currentPage++);
                    _pageController.jumpToPage(_currentPage);
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
              icon: const Icon(Icons.check_circle_rounded, size: 22),
              label: Text(
                'Ya, Saya Sudah Tahu',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _mbtiSkipped = false;
                  _showManualMbti = false;
                });
                setState(() {});
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
                foregroundColor: AppTheme.primaryColor,
                side: BorderSide(color: AppTheme.primaryColor, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 20),
              label: Text(
                'Belum, Saya Ingin Tes',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // BUILD MANUAL MBTI
  Widget _buildManualMbtiPage() {
    final mbtiTypes = [
      'INTJ', 'INTP', 'ENTJ', 'ENTP',
      'INFJ', 'INFP', 'ENFJ', 'ENFP',
      'ISTJ', 'ISFJ', 'ESTJ', 'ESFJ',
      'ISTP', 'ISFP', 'ESTP', 'ESFP',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology_rounded, size: 36, color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text(
            'Pilih Tipe MBTI',
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textP(context)),
          ),
          const SizedBox(height: 8),
          Text(
            'Pilih salah satu tipe MBTI di bawah ini:',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textS(context), height: 1.5),
          ),
          const SizedBox(height: 28),
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
                    color: isSelected ? AppTheme.primaryColor : AppTheme.surface(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : AppTheme.surfVar(context),
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
          ),
          const SizedBox(height: 36),
          _buildNextButton('Konfirmasi & Lanjut'),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // BUILD MBTI QUESTION
  Widget _buildMBTIQuestionPage(int index) {
    if (index >= _mbtiQuestions.length) return const SizedBox.shrink();
    final q = _mbtiQuestions[index];
    final selected = _answers[index];

    final dimensionLabels = {
      'E_I': ('🔋', 'Energi', 'Energy'),
      'S_N': ('🔍', 'Informasi', 'Information'),
      'T_F': ('💭', 'Keputusan', 'Decisions'),
      'J_P': ('📋', 'Gaya Hidup', 'Lifestyle'),
    };
    final dimInfo = dimensionLabels[q.dimension] ?? ('💡', 'Umum', 'General');
    final questionNum = index + 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  '${dimInfo.$2} · Pertanyaan $questionNum/${_mbtiQuestions.length}',
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Text(
              q.question,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textP(context),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 28),
          _buildOptionCard(
            label: 'A',
            text: q.optionAText,
            isSelected: selected == 0,
            color: AppTheme.primaryColor,
            onTap: () {
              setState(() => _answers[index] = 0);
              Future.delayed(const Duration(milliseconds: 300), _nextPage);
            },
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'ATAU',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textS(context),
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            label: 'B',
            text: q.optionBText,
            isSelected: selected == 1,
            color: AppTheme.secondaryColor,
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : AppTheme.surface(context),
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
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isSelected ? color : AppTheme.surfVar(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : AppTheme.textP(context),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: AppTheme.textP(context),
                  height: 1.5,
                ),
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  // BUILD INFO PAGE
  Widget _buildInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.white, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Memahami Perbedaan',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
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
          _buildInfoCard(
            icon: Icons.psychology_rounded,
            iconColor: AppTheme.primaryColor,
            title: 'Apa itu MBTI?',
            description: 'MBTI membantu Anda memahami tipe kepribadian dasar Anda.',
            points: const [
              '✨ Mengidentifikasi 16 tipe kepribadian berbeda',
              '🎯 Berfokus pada preferensi alami Anda',
              '📊 Bukan alat diagnosis medis',
              '💡 Membantu memahami kekuatan diri',
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoCard(
            icon: Icons.favorite_rounded,
            iconColor: AppTheme.secondaryColor,
            title: 'Kuesioner Kesehatan Mental',
            description: 'Dirancang untuk membantu Anda memahami kesejahteraan emosional sehari-hari.',
            points: [
              '🧠 ${_psyQuestions.length} pertanyaan refleksi diri',
              '⚠️ BUKAN alat diagnosis medis',
              '📈 Memberikan gambaran kondisi mental Anda',
              '💚 Disertai saran yang sesuai',
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 24),
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
                          color: Colors.orange.shade800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Kedua kuesioner ini BUKAN pengganti diagnosis profesional. Jika merasa kewalahan, sangat disarankan berkonsultasi dengan profesional.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.orange.shade900,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _buildNextButton('Lanjut ke Pertanyaan'),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

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
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textP(context),
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
              color: AppTheme.textS(context),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(point.substring(0, 2), style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      point.substring(3),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppTheme.textS(context),
                        height: 1.4,
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

  // BUILD PSYCHOLOGICAL QUESTION
  Widget _buildPsyQuestionPage(int index) {
    if (index >= _psyQuestions.length) return const SizedBox.shrink();
    final q = _psyQuestions[index];
    final selected = _psyAnswers[index];
    final questionNum = index + 1;

    final scaleColors = [
      const Color(0xFF22C55E),
      const Color(0xFF84CC16),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
                const Icon(Icons.favorite_rounded, size: 14, color: Colors.pink),
                const SizedBox(width: 6),
                Text(
                  'Kesehatan Mental · Pertanyaan $questionNum/${_psyQuestions.length}',
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
          const SizedBox(height: 4),
          Text(
            q.question,
            style: GoogleFonts.poppins(
              fontSize: 13,
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
                value: i,
                label: '${opt.score}',
                description: opt.answer,
                color: scaleColors[i % scaleColors.length],
                isSelected: selected == opt.score,
                onTap: () {
                  setState(() => _psyAnswers[index] = opt.score);
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.05) : AppTheme.surface(context),
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
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  // BUILD MBTI RESULT
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                const Text('🎉', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 8),
                Text(
                  'Hasil MBTI-mu!',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textP(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Halo ${user.name == '' ? 'Pengguna' : user.name}, ini kepribadianmu:',
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    color: AppTheme.textS(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.psychology_rounded, size: 36, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  _mbtiType,
                  style: GoogleFonts.poppins(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 10,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
          _buildNextButton('Selanjutnya'),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // BUILD PSYCHOLOGICAL RESULT
  Widget _buildPsyResultPage() {
    String category;
    String advice;
    Color cardColor;
    IconData categoryIcon;

    if (_psyScore <= 20) {
      category = AppLocalizations.tr('psych_excellent');
      advice = AppLocalizations.tr('overall_exc_1');
      cardColor = const Color(0xFF22C55E);
      categoryIcon = Icons.check_circle_rounded;
    } else if (_psyScore <= 40) {
      category = AppLocalizations.tr('psych_fair');
      advice = AppLocalizations.tr('overall_good_2');
      cardColor = const Color(0xFFF59E0B);
      categoryIcon = Icons.warning_amber_rounded;
    } else if (_psyScore <= 50) {
      category = AppLocalizations.tr('psych_fair');
      advice = AppLocalizations.tr('overall_fair_2');
      cardColor = const Color(0xFFF97316);
      categoryIcon = Icons.warning_rounded;
    } else {
      category = AppLocalizations.tr('psych_needs_attention');
      advice = AppLocalizations.tr('overall_attn_2');
      cardColor = const Color(0xFFEF4444);
      categoryIcon = Icons.error_rounded;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                const Text('🧠', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 12),
                Text(
                  'Kesehatan Mental',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textP(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cardColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Icon(categoryIcon, size: 56, color: cardColor),
                const SizedBox(height: 16),
                Text(
                  'Skor Anda: $_psyScore / 60 (${((_psyScore / 60) * 100).round()} / 100)',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: cardColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  category,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cardColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  advice,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.textP(context),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _completeOnboarding,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Selesai 🚀',
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildNextButton(String label) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _nextPage,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

class PsyQuestion {
  final int id;
  final String category;
  final String question;
  final List<PsyOption> options;

  const PsyQuestion({
    required this.id,
    required this.category,
    required this.question,
    required this.options,
  });

  factory PsyQuestion.fromJson(Map<String, dynamic> json) {
    return PsyQuestion(
      id: json['id'],
      category: json['category'],
      question: json['question'],
      options: (json['options'] as List).map((o) => PsyOption.fromJson(o)).toList(),
    );
  }
}

class PsyOption {
  final String answer;
  final int score;

  const PsyOption({required this.answer, required this.score});

  factory PsyOption.fromJson(Map<String, dynamic> json) {
    return PsyOption(
      answer: json['answer'],
      score: json['score'],
    );
  }
}
