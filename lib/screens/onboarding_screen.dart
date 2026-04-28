import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding/mbti_section.dart';
import 'onboarding/onboarding_state.dart';
import 'onboarding/psy_section.dart';
import 'onboarding/result_section.dart';
import 'onboarding/welcome_section.dart';

import '../models/user_model.dart';
import '../providers/locale_provider.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatelessWidget {
  final VoidCallback onCompleted;

  const OnboardingScreen({super.key, required this.onCompleted});

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
      final user = AppUser(
        name: '', // Ditanyakan di AuthScreen
        mbtiType: state.mbtiType,
        mbtiScores: state.mbtiScores,
        psychologicalScore: state.psyScore,
        createdAt: DateTime.now(),
      );
      
      final userId = await DatabaseService.insertUser(user);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('pending_onboarding_user_id', userId);
      await StorageService.setOnboardingComplete(user.name);
      
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
