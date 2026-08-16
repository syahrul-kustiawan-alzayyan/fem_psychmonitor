import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../theme/resonance_colors.dart';
import '../auth_screen.dart';

class WelcomeSection extends StatefulWidget {
  final VoidCallback onNext;

  const WelcomeSection({super.key, required this.onNext});

  @override
  State<WelcomeSection> createState() => _WelcomeSectionState();
}

class _WelcomeSectionState extends State<WelcomeSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.15, 0.6, curve: Curves.elasticOut),
      ),
    );
    _logoOpacity = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.1, 0.5, curve: Curves.easeOut),
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ResonanceColors.of(context);
    final loc = AppLocalizations.tr;
    final isEn = context.watch<LocaleProvider>().locale == 'en';

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _buildLangSwitcher(context, c),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildHero(c),
                  const SizedBox(height: 6),
                  _buildBrandName(c),
                  const SizedBox(height: 16),
                  _buildEyebrow(c, isEn),
                  const SizedBox(height: 10),
                  _buildSubtitle(c, loc),
                  const SizedBox(height: 16),
                  WaveformBars(c: c),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildFeatureCard(context, c, loc),
                  ),
                  const SizedBox(height: 28),
                  _buildPrimaryCta(context, c),
                  const SizedBox(height: 20),
                  _buildLoginRow(c, loc),
                  const SizedBox(height: 24),
                  _buildFooter(c),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(ResonanceColors c) {
    return SizedBox(
      height: 150,
      child: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: ScaleTransition(
                scale: _logoScale,
                child: FadeTransition(
                  opacity: _logoOpacity,
                  child: Image.asset(
                    'assets/logo.png',
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 24,
            top: 10,
            child: FloatingChip(label: 'emotion: calm 84%', color: c),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandName(ResonanceColors c) {
    return Center(
      child: Text(
        'Fem-PsychMonitor',
        style: GoogleFonts.spaceGrotesk(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: c.primary,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildEyebrow(ResonanceColors c, bool isEn) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '01',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: c.primary,
              letterSpacing: 1.5,
            ),
          ),
          Text(
            isEn ? ' / START' : ' / MULAI',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: c.onSurfaceVariant,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle(ResonanceColors c, String Function(String) loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Text(
        loc('welcome_desc'),
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 15,
          color: c.onSurfaceVariant,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    ResonanceColors c,
    String Function(String) loc,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 4,
          bottom: -4,
          child: Container(
            decoration: BoxDecoration(
              color: c.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: c.surfaceLowest,
            border: Border.all(color: c.outlineVariant),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildFeatureRow(
                c: c,
                icon: PhosphorIconsRegular.waveform,
                iconColor: c.primary,
                title: loc('feature_voice_title'),
                description: loc('feature_voice_desc'),
              ),
              const SizedBox(height: 18),
              Container(height: 1, color: c.outlineVariant),
              const SizedBox(height: 18),
              _buildFeatureRow(
                c: c,
                icon: PhosphorIconsRegular.compass,
                iconColor: const Color(0xFF2E5F6E),
                title: loc('feature_self_title'),
                description: loc('feature_self_desc'),
              ),
              const SizedBox(height: 18),
              Container(height: 1, color: c.outlineVariant),
              const SizedBox(height: 18),
              _buildFeatureRow(
                c: c,
                icon: PhosphorIconsRegular.plant,
                iconColor: const Color(0xFF10B981),
                title: loc('feature_growth_title'),
                description: loc('feature_growth_desc'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureRow({
    required ResonanceColors c,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: c.primaryContainer,
            shape: BoxShape.circle,
            border: Border.all(color: c.outlineVariant),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1424161C),
                offset: Offset(1.5, 1.5),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: c.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: c.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryCta(BuildContext context, ResonanceColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: widget.onNext,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: _pressed
                  ? c.primary.withValues(alpha: 0.85)
                  : c.primary,
              borderRadius: BorderRadius.circular(999),
              boxShadow: _pressed
                  ? []
                  : const [
                      BoxShadow(
                        color: Color(0x4024161C),
                        offset: Offset(4, 4),
                      ),
                    ],
            ),
            child: Center(
              child: Text(
                AppLocalizations.tr('start_now'),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginRow(ResonanceColors c, String Function(String) loc) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          loc('has_account'),
          style: GoogleFonts.inter(
            fontSize: 14,
            color: c.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const AuthScreen()),
            );
          },
          child: Text(
            loc('login'),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: c.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(ResonanceColors c) {
    return Center(
      child: Text(
        'FEM-PSYCHMONITOR · VOICE-EMOTION AI',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.5,
          color: c.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildLangSwitcher(BuildContext context, ResonanceColors c) {
    return Consumer<LocaleProvider>(
      builder: (context, locale, _) {
        final isEn = locale.locale == 'en';
        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: c.surfaceLowest,
            border: Border.all(color: c.outlineVariant),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF24161C).withValues(alpha: 0.1),
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _langOption(context, c, 'ID', !isEn, () => locale.setLocale('id')),
              const SizedBox(width: 2),
              _langOption(context, c, 'EN', isEn, () => locale.setLocale('en')),
            ],
          ),
        );
      },
    );
  }

  Widget _langOption(
    BuildContext context,
    ResonanceColors c,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? c.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : c.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}