import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'onboarding/bigfive_section.dart';
import 'onboarding/onboarding_state.dart';
import 'onboarding/psy_section.dart';
import 'onboarding/result_section.dart';
import 'onboarding/welcome_section.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/premium_provider.dart';
import '../services/ad_service.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatelessWidget {
  final VoidCallback onCompleted;

  const OnboardingScreen({super.key, required this.onCompleted});

  static Future<void> savePendingOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final hasPending = prefs.getBool('pending_onboarding_data') ?? false;
    if (!hasPending) return;

    try {
      final psychScore = prefs.getInt('pending_psych_score');
      final bigFiveJson = prefs.getString('pending_bigfive_scores') ?? '{}';

      final bigFiveScores = Map<String, double>.from(
        (jsonDecode(bigFiveJson) as Map).map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
      );

      final user = AppUser(
        name: prefs.getString('auth_username') ?? '',
        bigFiveScores: bigFiveScores,
        psychologicalScore: psychScore != null
            ? ((60 - psychScore) / 60 * 100).round()
            : null,
        createdAt: DateTime.now(),
      );

      await DatabaseService.insertUser(user);

      await prefs.remove('pending_psych_score');
      await prefs.remove('pending_bigfive_scores');
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_bigfive_scores', jsonEncode(state.bigFiveScores));
      await prefs.setInt('pending_psych_score', state.psyScore);
      await prefs.setBool('pending_onboarding_data', true);

      await StorageService.setOnboardingComplete('');

      final authProvider = context.read<AuthProvider>();
      if (authProvider.isLoggedIn) {
        await OnboardingScreen.savePendingOnboarding();
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
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                WelcomeSection(onNext: _nextPage),
                BigFiveSection(onNext: _nextPage),
                PsySection(onNext: _nextPage),
                ResultSection(
                  onComplete: () => _completeOnboarding(context),
                  userName: '',
                ),
              ],
            ),
          ),
          Consumer<PremiumProvider>(
            builder: (context, premium, _) {
              if (premium.isPremium) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surface(context).withValues(alpha: 0.6),
                  border: Border(
                    top: BorderSide(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                child: Center(
                  child: AdService().buildBannerWidget(height: 50, isTop: true),
                ),
              );
            },
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
