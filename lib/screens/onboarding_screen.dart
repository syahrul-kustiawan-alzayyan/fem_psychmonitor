import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'onboarding/mbti_section.dart';
import 'onboarding/onboarding_state.dart';
import 'onboarding/psy_section.dart';
import 'onboarding/result_section.dart';
import 'onboarding/welcome_section.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatelessWidget {
  final VoidCallback onCompleted;

  const OnboardingScreen({super.key, required this.onCompleted});

  /// Dipanggil setelah user berhasil login/register untuk menyimpan
  /// data onboarding ke Firestore
  static Future<void> savePendingOnboardingToFirestore() async {
    final prefs = await SharedPreferences.getInstance();
    final hasPending = prefs.getBool('pending_onboarding_data') ?? false;
    if (!hasPending) return;

    try {
      final mbtiType = prefs.getString('pending_mbti_type') ?? '';
      final mbtiScoresJson = prefs.getString('pending_mbti_scores') ?? '{}';
      final psychScore = prefs.getInt('pending_psych_score');

      final mbtiScores = Map<String, int>.from(
        jsonDecode(mbtiScoresJson) as Map,
      );

      final user = AppUser(
        name: prefs.getString('auth_username') ?? '',
        mbtiType: mbtiType,
        mbtiScores: mbtiScores,
        psychologicalScore: psychScore == 0 ? null : psychScore,
        createdAt: DateTime.now(),
      );

      await DatabaseService.insertUser(user);

      // Hapus data pending
      await prefs.remove('pending_mbti_type');
      await prefs.remove('pending_mbti_scores');
      await prefs.remove('pending_psych_score');
      await prefs.remove('pending_onboarding_data');
    } catch (e) {
      debugPrint('Error saving pending onboarding: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingState()..loadQuestions(),
      child: _OnboardingScreenView(onCompleted: onCompleted),
    );
  }
}

class _OnboardingScreenView extends StatefulWidget {
  final VoidCallback onCompleted;
  const _OnboardingScreenView({required this.onCompleted});

  @override
  State<_OnboardingScreenView> createState() => _OnboardingScreenViewState();
}

class _OnboardingScreenViewState extends State<_OnboardingScreenView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _currentLocale = 'id';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = context.watch<LocaleProvider>().locale;
    if (locale != _currentLocale) {
      _currentLocale = locale;
      // Reload questions when locale changes
      Future.microtask(() {
        if (mounted) {
          context.read<OnboardingState>().loadQuestions();
        }
      });
    }
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding(BuildContext context) async {
    final state = context.read<OnboardingState>();
    state.setSaving(true);
    
    try {
      // Simpan data onboarding ke SharedPreferences dulu (sementara)
      // Data akan ditulis ke Firestore setelah user register/login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_mbti_type', state.mbtiType);
      await prefs.setString('pending_mbti_scores', jsonEncode(state.mbtiScores));
      await prefs.setInt('pending_psych_score', state.psyScore ?? 0);
      await prefs.setBool('pending_onboarding_data', true);

      await StorageService.setOnboardingComplete('');
      
      // Jika user sudah login, langsung simpan data onboarding ke database.
      // Jika belum, data ini akan disimpan saat mereka login nanti.
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isLoggedIn) {
        await OnboardingScreen.savePendingOnboardingToFirestore();
      }
      
      if (!context.mounted) return;
      widget.onCompleted();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      state.setSaving(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Prevent manual swipe
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: [
          WelcomeSection(onNext: _nextPage),
          MbtiSection(onNext: _nextPage),
          PsySection(onNext: _nextPage),
          ResultSection(
            onComplete: () => _completeOnboarding(context),
            userName: '',
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
