import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/emotion_model.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/emotion_badge.dart';
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

  // Data dummy deteksi — diambil dari DummyData
  final EmotionType _detectedEmotion = DummyData.latestEmotion.emotion;
  final double _detectedConfidence = DummyData.latestEmotion.confidence;

  // Random seed tetap agar desain waveform konsisten saat idle
  final _rand = Random(77);

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.22).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

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
  void _toggleRecording() {
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

    setState(() {
      _isRecording = !_isRecording;
      if (_isRecording) {
        _hasResult = false;
        _resultFadeCtrl.reset();
        _pulseCtrl.repeat(reverse: true);
        _waveCtrl.repeat();
      } else {
        _pulseCtrl.stop();
        _pulseCtrl.reset();
        _waveCtrl.stop();
        _hasResult = true;
        _resultFadeCtrl.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: _buildAppBar(context),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceLg, vertical: 8),
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
                            '${AppLocalizations.tr('suggestion_for_emotion')} ${_detectedEmotion.displayName}',
                        suggestions: _detectedEmotion.recordingSuggestions,
                        icon: Icons.lightbulb_outline_rounded,
                        color: _detectedEmotion.color,
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
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Widget: AppBar Custom
  // ─────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.bg(context),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.mic_rounded,
              color: AppTheme.primaryColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Text(AppLocalizations.tr('voice_detection'),
            style: TextStyle(color: AppTheme.textP(context)),
          ),
        ],
      ),
      iconTheme: IconThemeData(color: AppTheme.textP(context)),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Widget: Waveform Visualizer — animated bars mirrored top/bottom
  // ─────────────────────────────────────────────────────────────
  Widget _buildWaveVisualizer() {
    return AnimatedBuilder(
      animation: _waveCtrl,
      builder: (context, _) {
        // Saat rekam: generate heights random per frame
        final waveRand = _isRecording ? Random() : _rand;
        final count = 32;

        return Container(
          width: double.infinity,
          height: 130,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            boxShadow: AppTheme.cardShadow,
            border: Border.all(
              color: _isRecording
                  ? AppTheme.primaryColor.withValues(alpha: 0.25)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(count, (i) {
              // Pola waveform: tengah lebih tinggi, tepi lebih rendah
              final centerFactor =
                  1.0 - ((i - count / 2).abs() / (count / 2)) * 0.4;
              final baseH = _isRecording
                  ? (8 + waveRand.nextDouble() * 52) * centerFactor
                  : 6.0 + (sin(i * 0.5) * 6).abs();

              // Warna bar: gradien dari tengah ke tepi saat rekaman
              final opacity = _isRecording
                  ? 0.5 + centerFactor * 0.5
                  : 0.2;

              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Bar atas (mirror effect)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: baseH / 2,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3),
                          ),
                          color: (_isRecording
                                  ? AppTheme.primaryColor
                                  : AppTheme.primaryColor)
                              .withValues(alpha: opacity),
                        ),
                      ),
                      // Garis tengah (axis)
                      Container(
                        height: 1.5,
                        color: AppTheme.primaryColor.withValues(alpha: 0.12),
                      ),
                      // Bar bawah (mirror)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: baseH / 2,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(3),
                          ),
                          color: (_isRecording
                                  ? AppTheme.accentColor
                                  : AppTheme.primaryColor)
                              .withValues(alpha: opacity * 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Widget: Area Rekaman — Mic button + status label
  // ─────────────────────────────────────────────────────────────
  Widget _buildRecordingSection(BuildContext context) {
    return Column(
      children: [
        // Mic Button dengan concentric pulse rings
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
                    // Ring 3 (terluar, paling transparan)
                    if (_isRecording)
                      Transform.scale(
                        scale: _pulseAnim.value,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFF87171)
                                .withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                    // Ring 2
                    if (_isRecording)
                      Transform.scale(
                        scale: _pulseAnim.value * 0.85,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFF87171)
                                .withValues(alpha: 0.13),
                          ),
                        ),
                      ),
                    // Ring 1 (idle: sage green)
                    if (!_isRecording)
                      Container(
                        width: 116,
                        height: 116,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              AppTheme.primaryColor.withValues(alpha: 0.1),
                        ),
                      ),
                    // Tombol utama
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _isRecording
                            ? AppTheme.recordingGradient
                            : AppTheme.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: (_isRecording
                                    ? const Color(0xFFF87171)
                                    : AppTheme.primaryColor)
                                .withValues(alpha: 0.45),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: Icon(
                          _isRecording
                              ? Icons.stop_rounded
                              : Icons.mic_rounded,
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

        const SizedBox(height: 18),

        // Status label dengan animasi warna
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Column(
            key: ValueKey(_isRecording ? 'rec' : (_hasResult ? 'done' : 'idle')),
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
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusFull),
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
                    horizontal: 14, vertical: 10),
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
        color: const Color(0xFFFFB300),
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
                color: _detectedEmotion.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _detectedEmotion.icon,
                color: _detectedEmotion.color,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.tr('detection_result'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textP(context)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Kartu emosi dominan
        EmotionResultCard(
          emotion: _detectedEmotion,
          confidence: _detectedConfidence,
        ),

        const SizedBox(height: 20),

        // Sub-header distribusi
        Text(
          AppLocalizations.tr('all_emotion_dist'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textS(context),
          ),
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
            children: DummyData.detectionScores.entries
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
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusFull),
                  ),
                ),
                // Filled portion
                FractionallySizedBox(
                  widthFactor: score.clamp(0.0, 1.0),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: emotion.color,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusFull),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Percentage chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
            _detectedEmotion.color.withValues(alpha: 0.12),
            _detectedEmotion.color.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: _detectedEmotion.color.withValues(alpha: 0.28),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _detectedEmotion.color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_rounded,
              color: _detectedEmotion.color,
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
                    color: _detectedEmotion.color,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _detectedEmotion.psychMessage,
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
