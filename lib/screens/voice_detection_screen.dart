import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/emotion_model.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../utils/animations.dart';
import '../widgets/emotion_badge.dart';
import '../widgets/gradient_background.dart';
import '../widgets/particle_animation.dart';
import '../widgets/suggestion_card.dart';
import 'auth_screen.dart';

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
  bool _hasResult = false;

  // Controller untuk pulse ring pada mic button
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // Controller untuk animasi waveform bars
  late AnimationController _waveCtrl;

  // Controller untuk fade-in hasil deteksi
  late AnimationController _resultFadeCtrl;
  late Animation<double> _resultFade;

  // Data deteksi
  EmotionType? _detectedEmotion;
  double? _detectedConfidence;
  Map<EmotionType, double>? _detectedScores;

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

    _resultFadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _resultFade = CurvedAnimation(
      parent: _resultFadeCtrl,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    _resultFadeCtrl.dispose();
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
        _hasResult = false;
        _detectedEmotion = null;
        _detectedConfidence = null;
        _detectedScores = null;
        _resultFadeCtrl.reset();
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

      // Simpan ke SQLite
      final record = RecordingData(
        userId: userId,
        dominantEmotion: selectedEmotion,
        confidence: confidence,
        date: DateTime.now(),
        suggestion: selectedEmotion.recordingSuggestions.first,
        audioEmotions: scores,
        transcriptEmotions: scores,
      );

      await DatabaseService.insertRecording(record);

      setState(() {
        _isRecording = false;
        _detectedEmotion = selectedEmotion;
        _detectedConfidence = confidence;
        _detectedScores = scores;
        _hasResult = true;
        _resultFadeCtrl.forward();
      });
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

                // ── Hasil Deteksi (muncul setelah rekaman) ──────────
                if (_hasResult)
                  FadeTransition(
                    opacity: _resultFade,
                    child: Column(
                      children: [
                        _buildDetectionResults(),
                        const SizedBox(height: AppTheme.spaceMd),
                        _buildPsychMessage(),
                        const SizedBox(height: AppTheme.spaceMd),
                        SuggestionCard(
                          title:
                              '${AppLocalizations.tr('suggestion_for_emotion')} ${_detectedEmotion!.displayName}',
                          suggestions: _detectedEmotion!.recordingSuggestions,
                          icon: Icons.lightbulb_outline_rounded,
                          color: _detectedEmotion!.color,
                          isCollapsible: true,
                        ),
                      ],
                    ),
                  ),

                // ── Prompt Kata-kata Pemancing ─────────────────────
                if (!_hasResult && !_isRecording) _buildStoryPrompts(),

                // ── Panduan saat Idle ───────────────────────────────
                if (!_hasResult && !_isRecording) _buildIdleGuide(),

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
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Particle effect background saat recording
                    if (_isRecording)
                      Positioned.fill(
                        child: ParticleAnimation(
                          width: 160,
                          height: 160,
                          particleCount: 15,
                          particleColor: AppTheme.secondaryColor,
                        ),
                      ),

                    // Ring 3 (terluar, gradient)
                    if (_isRecording)
                      Transform.scale(
                        scale: _pulseAnim.value * 1.1,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor.withValues(alpha: 0.15),
                                AppTheme.secondaryColor.withValues(alpha: 0.15),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Ring 2 (gradient)
                    if (_isRecording)
                      Transform.scale(
                        scale: _pulseAnim.value * 0.95,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor.withValues(alpha: 0.25),
                                AppTheme.secondaryColor.withValues(alpha: 0.25),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Ring 1 (idle state)
                    if (!_isRecording)
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor.withValues(alpha: 0.15),
                              AppTheme.secondaryColor.withValues(alpha: 0.15),
                            ],
                          ),
                        ),
                      ),

                    // Tombol utama dengan gradient border
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _isRecording
                            ? AppTheme.recordingGradient
                            : AppTheme.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.5),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                          BoxShadow(
                            color: AppTheme.secondaryColor.withValues(
                              alpha: 0.4,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: Icon(
                          _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                          key: ValueKey(_isRecording),
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 18),

        // Status label dengan animasi warna
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Column(
            key: ValueKey(
              _isRecording ? 'rec' : (_hasResult ? 'done' : 'idle'),
            ),
            children: [
              Text(
                _isRecording
                    ? AppLocalizations.tr('recording')
                    : (_hasResult
                          ? AppLocalizations.tr('detection_done')
                          : AppLocalizations.tr('press_to_record')),
                style: GoogleFonts.poppins(
                  color: _isRecording
                      ? const Color(0xFFF87171)
                      : (_hasResult
                            ? AppTheme.primaryColor
                            : AppTheme.textS(context)),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              if (_isRecording) ...[
                const SizedBox(height: 8),
                // Timer placeholder visual
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    border: Border.all(
                      color: const Color(0xFFF87171).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFF87171),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'REC',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF87171),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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

  // ─────────────────────────────────────────────────────────────
  // Widget: Hasil Deteksi — EmotionResultCard + distribusi bar
  // ─────────────────────────────────────────────────────────────
  Widget _buildDetectionResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _detectedEmotion!.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _detectedEmotion!.icon,
                color: _detectedEmotion!.color,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.tr('detection_result'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: AppTheme.textP(context)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Kartu emosi dominan
        EmotionResultCard(
          emotion: _detectedEmotion!,
          confidence: _detectedConfidence!,
        ),

        const SizedBox(height: 20),

        // Sub-header distribusi
        Text(
          AppLocalizations.tr('all_emotion_dist'),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: AppTheme.textS(context)),
        ),
        const SizedBox(height: 12),

        // Semua skor dalam styled bar
        Container(
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            children: (_detectedScores ?? DummyData.detectionScores).entries
                .map((e) => _buildEmotionScoreBar(e.key, e.value))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmotionScoreBar(EmotionType emotion, double score) {
    final pct = (score * 100).toStringAsFixed(0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Emotion icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: emotion.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(emotion.icon, color: emotion.color, size: 16),
          ),
          const SizedBox(width: 10),
          // Name label
          SizedBox(
            width: 70,
            child: Text(
              emotion.displayName,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                color: AppTheme.textP(context),
              ),
            ),
          ),
          // Progress bar
          Expanded(
            child: Stack(
              children: [
                // Background track
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: emotion.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                ),
                // Filled portion
                FractionallySizedBox(
                  widthFactor: score.clamp(0.0, 1.0),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: emotion.color,
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Percentage chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: emotion.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Text(
              '$pct%',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: emotion.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Widget: Pesan Psikologis / Afirmasi Positif
  // ─────────────────────────────────────────────────────────────
  Widget _buildPsychMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceXl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _detectedEmotion!.color.withValues(alpha: 0.12),
            _detectedEmotion!.color.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: _detectedEmotion!.color.withValues(alpha: 0.28),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _detectedEmotion!.color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_rounded,
              color: _detectedEmotion!.color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.tr('psych_message'),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _detectedEmotion!.color,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _detectedEmotion!.psychMessage,
                  style: GoogleFonts.poppins(
                    color: AppTheme.textP(context),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
