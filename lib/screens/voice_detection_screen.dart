import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/emotion_model.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../services/suggestion_service.dart';
import '../theme/app_theme.dart';
import '../utils/animations.dart';
import '../widgets/emotion_badge.dart';
import '../widgets/gradient_background.dart';
import '../widgets/particle_animation.dart';
import '../widgets/suggestion_card.dart';
import 'auth_screen.dart';
import 'recording_result_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// VoiceDetectionScreen — Layar Rekaman & Deteksi Emosi
//
// Arsitektur Widget (modular):
//   • _buildWaveVisualizer()    → Visualizer gelombang suara estetik
//   • _buildRecordingSection()  → Area tombol mic dengan status label
//   • _buildIdleGuide()         → Panduan langkah saat idle
//   • _buildDetectionResults()  → Kartu emosi dominan + distribusi skor
//   • _buildPsychMessage()      → Pesan coping/afirmasi positif
// ─────────────────────────────────────────────────────────────────────────────
class VoiceDetectionScreen extends StatefulWidget {
  const VoiceDetectionScreen({super.key});

  @override
  State<VoiceDetectionScreen> createState() => _VoiceDetectionScreenState();
}

class _VoiceDetectionScreenState extends State<VoiceDetectionScreen>
    with TickerProviderStateMixin {
  bool _isRecording = false;

  // Controller untuk pulse ring pada mic button
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // Controller untuk animasi waveform bars
  late AnimationController _waveCtrl;

  // Random seed tetap agar desain waveform konsisten saat idle
  final _rand = Random();

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 1.22,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  // Toggle start/stop recording
  Future<void> _toggleRecording() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      // Buka pop-up atau arahkan ke login
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.tr('login_required')),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
      return;
    }

    if (!_isRecording) {
      // START RECORDING
      setState(() {
        _isRecording = true;
        _pulseCtrl.repeat(reverse: true);
        _waveCtrl.repeat();
      });
    } else {
      // STOP RECORDING
      _pulseCtrl.stop();
      _pulseCtrl.reset();
      _waveCtrl.stop();

      // MOKUP: Simulasikan hasil deteksi acak
      final emotions = EmotionType.values;
      final selectedEmotion = emotions[_rand.nextInt(emotions.length)];
      final confidence = 0.5 + (_rand.nextDouble() * 0.45); // 0.5 - 0.95

      // MOKUP: Generate scores acak untuk grafik
      final scores = <EmotionType, double>{};
      double remaining = 1.0 - confidence;
      for (final e in emotions) {
        if (e == selectedEmotion) {
          scores[e] = confidence;
        } else {
          final s = _rand.nextDouble() * remaining;
          scores[e] = s;
          remaining -= s;
        }
      }

      final user = await DatabaseService.getUser();
      final userId = user?.id ?? 1;

      // Ambil saran dari saran.json berdasarkan MBTI + emosi
      final suggService = SuggestionService();
      await suggService.load();
      final mbtiType = user?.mbtiType ?? '';
      final firstSugg = (mbtiType.isNotEmpty && mbtiType != 'XXXX')
          ? suggService.getFirstSuggestion(mbtiType, selectedEmotion)
          : selectedEmotion.recordingSuggestions.first;

      // Simpan ke SQLite
      final record = RecordingData(
        userId: userId,
        dominantEmotion: selectedEmotion,
        confidence: confidence,
        date: DateTime.now(),
        suggestion: firstSugg,
        audioEmotions: scores,
        transcriptEmotions: scores,
      );

      await DatabaseService.insertRecording(record);

      setState(() {
        _isRecording = false;
      });

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecordingResultScreen(
              detectedEmotion: selectedEmotion,
              confidence: confidence,
              scores: scores,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(context),
      body: GradientBackground(
        useOverlay: true,
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceLg,
              vertical: 8,
            ),
            child: Column(
              children: [
                const SizedBox(height: AppTheme.spaceMd),

                // ── Visualizer Gelombang Suara ──────────────────────
                _buildWaveVisualizer(),

                const SizedBox(height: AppTheme.space2xl),

                // ── Area Tombol Rekam ───────────────────────────────
                _buildRecordingSection(context),

                const SizedBox(height: AppTheme.space2xl),

                // ── Prompt Kata-kata Pemancing ─────────────────────
                if (!_isRecording) _buildStoryPrompts(),

                // ── Panduan saat Idle ───────────────────────────────
                if (!_isRecording) _buildIdleGuide(),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ), // End GradientBackground
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Widget: AppBar Custom
  // ─────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.mic_none_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.tr('nav_record'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Widget: Waveform Visualizer — animated bars mirrored top/bottom
  // ─────────────────────────────────────────────────────────────
  Widget _buildWaveVisualizer() {
    return GlassCard(
      useBlur: !(Platform.isWindows || Platform.isLinux || Platform.isMacOS),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated wave bars
          AnimatedWaveBars(
            width: double.infinity,
            height: 100,
            barCount: 40,
            isAnimating: _isRecording,
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
            ),
          ),

          const SizedBox(height: 12),

          // Status text
          Text(
            _isRecording
                ? AppLocalizations.tr('listening')
                : AppLocalizations.tr('ready_to_listen'),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              foreground: Paint()
                ..shader = AppTheme.primaryGradient.createShader(
                  const Rect.fromLTWH(0, 0, 150, 50),
                ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Widget: Area Rekaman — Mic button + status label
  // ─────────────────────────────────────────────────────────────
  Widget _buildRecordingSection(BuildContext context) {
    return Column(
      children: [
        // Mic Button dengan modern gradient pulse rings
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, child) {
            return GestureDetector(
              onTap: _toggleRecording,
              child: SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Pulse Ring
                    if (_isRecording)
                      Transform.scale(
                        scale: _pulseAnim.value * 1.15,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.redAccent.withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                    
                    // Inner Pulse Ring
                    if (_isRecording)
                      Transform.scale(
                        scale: _pulseAnim.value,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.redAccent.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                      
                    // Main Button
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _isRecording
                            ? const LinearGradient(
                                colors: [Color(0xFFFF5252), Color(0xFFD32F2F)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : AppTheme.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: (_isRecording ? Colors.red : AppTheme.primaryColor)
                                    .withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                        child: Icon(
                          _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                          key: ValueKey(_isRecording),
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        // Status label dengan animasi warna
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Column(
            key: ValueKey(
              _isRecording ? 'rec' : 'idle',
            ),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _isRecording ? Colors.red.withValues(alpha: 0.1) : AppTheme.surface(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isRecording ? Colors.red.withValues(alpha: 0.3) : AppTheme.surfVar(context),
                    width: 1,
                  )
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isRecording)
                      Container(
                        width: 8, height: 8,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      ),
                    Text(
                      _isRecording
                          ? AppLocalizations.tr('recording')
                          : AppLocalizations.tr('press_to_record'),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: _isRecording ? Colors.redAccent : AppTheme.textP(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Widget: Kata-kata pemancing untuk bercerita
  // ─────────────────────────────────────────────────────────────
  Widget _buildStoryPrompts() {
    final prompts = [
      AppLocalizations.tr('recording_prompt_1'),
      AppLocalizations.tr('recording_prompt_2'),
      AppLocalizations.tr('recording_prompt_3'),
      AppLocalizations.tr('recording_prompt_4'),
      AppLocalizations.tr('recording_prompt_5'),
      AppLocalizations.tr('recording_prompt_6'),
      AppLocalizations.tr('recording_prompt_7'),
      AppLocalizations.tr('recording_prompt_8'),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceLg),
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.06),
            AppTheme.secondaryColor.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(
          color: AppTheme.secondaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: AppTheme.warmGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.tips_and_updates_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppLocalizations.tr('recording_prompt_title'),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textP(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMd),

          // Prompt chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: prompts.map((prompt) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surface(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.format_quote_rounded,
                      size: 14,
                      color: AppTheme.secondaryColor,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        prompt,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textS(context),
                          fontStyle: FontStyle.italic,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Widget: Panduan penggunaan saat idle
  // ─────────────────────────────────────────────────────────────
  Widget _buildIdleGuide() {
    final steps = [
      (
        num: '1',
        icon: Icons.touch_app_rounded,
        text: AppLocalizations.tr('guide_step_1'),
        color: AppTheme.primaryColor,
      ),
      (
        num: '2',
        icon: Icons.record_voice_over_rounded,
        text: AppLocalizations.tr('guide_step_2'),
        color: AppTheme.secondaryColor, // Pink
      ),
      (
        num: '3',
        icon: Icons.stop_circle_outlined,
        text: AppLocalizations.tr('guide_step_3'),
        color: const Color(0xFFF87171),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceXl),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: AppTheme.primaryColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.tr('how_to_use'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textP(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...steps.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: s.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(s.icon, color: s.color, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        s.text,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textP(context),
                          height: 1.4,
                        ),
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

}
