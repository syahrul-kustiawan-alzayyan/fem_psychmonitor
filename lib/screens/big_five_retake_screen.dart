import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import '../widgets/gradient_background.dart';
import 'onboarding/onboarding_state.dart';
import 'onboarding/bigfive_section.dart';

class BigFiveRetakeScreen extends StatefulWidget {
  const BigFiveRetakeScreen({super.key});

  @override
  State<BigFiveRetakeScreen> createState() => _BigFiveRetakeScreenState();
}

class _BigFiveRetakeScreenState extends State<BigFiveRetakeScreen> {
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OnboardingState>().loadQuestions();
    });
  }

  void _nextPage() {
    if (_pageIndex < 1) {
      setState(() => _pageIndex++);
    }
  }

  void _handleComplete() async {
    final state = context.read<OnboardingState>();
    state.calculateBigFiveResult();

    final user = await DatabaseService.getUser();
    if (user != null && mounted) {
      await DatabaseService.updateUser(
        user.copyWith(bigFiveScores: state.bigFiveScores),
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.tr('big_five_saved')),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: ShaderMask(
          shaderCallback: (bounds) =>
              AppTheme.primaryGradient.createShader(bounds),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Big Five',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
      body: GradientBackground(
        useOverlay: true,
        child: SafeArea(
          child: _pageIndex == 0
              ? _buildIntro()
              : Consumer<OnboardingState>(
                  builder: (context, obState, _) {
                    if (obState.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return BigFiveSection(
                      onNext: _handleComplete,
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 28),
          Text(
            AppLocalizations.tr('big_five_retake_title'),
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textP(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.tr('big_five_retake_desc'),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppTheme.textS(context),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _nextPage,
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: Text(
                      AppLocalizations.tr('start_now'),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
