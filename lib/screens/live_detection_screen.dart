import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/emotion_model.dart';
import '../providers/auth_provider.dart';
import '../services/audio_recorder_detection.dart'
    show AudioRecorderWithDetection, DetectionResult;
import '../theme/resonance_colors.dart';
import 'emotion_detection_screen.dart';

class LiveDetectionScreen extends StatefulWidget {
  const LiveDetectionScreen({super.key});

  @override
  State<LiveDetectionScreen> createState() => _LiveDetectionScreenState();
}

class _LiveDetectionScreenState extends State<LiveDetectionScreen>
    with TickerProviderStateMixin {
  final bool _isRecording = false;
  bool _isModelLoading = true;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _waveCtrl;

  EmotionType? _detectedEmotion;

  final AudioRecorderWithDetection _recorder =
      AudioRecorderWithDetection.instance;
  StreamSubscription? _detectionSubscription;

  final _rand = Random();
  final List<double> _waveHeights = List.generate(20, (_) => 0.3);

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

    _loadModel();
    _waveCtrl.addListener(_updateWaveform);
  }

  Future<void> _loadModel() async {
    setState(() => _isModelLoading = true);
    try {
      await _recorder.checkAndRequestPermission();
      await _recorder.loadModel();

      setState(() {
        _isModelLoading = false;
      });

      _detectionSubscription = _recorder.detectionStream.listen(
        _onDetectionResult,
      );
    } catch (e) {
      setState(() {
        _isModelLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat model: $e (mode simulasi diaktifkan)'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _onDetectionResult(DetectionResult result) {
    if (mounted) {
      setState(() {
        _detectedEmotion = result.dominantEmotion;
      });
    }
  }

  void _updateWaveform() {
    if (_isRecording) {
      setState(() {
        for (int i = 0; i < _waveHeights.length; i++) {
          _waveHeights[i] = 0.2 + (_rand.nextDouble() * 0.6);
        }
      });
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    _detectionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.tr('login_required')),
          backgroundColor: ResonanceColors.of(context).primary,
        ),
      );
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const EmotionDetectionScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ResonanceColors.of(context);

    return Scaffold(
      backgroundColor: c.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: c.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                PhosphorIconsRegular.microphone,
                color: c.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.tr('live_detection_title'),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: c.onSurface,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 16),

              if (_isModelLoading)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: c.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.outlineVariant),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            c.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.tr('loading_model'),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: c.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

              _buildWaveVisualizer(context),

              const SizedBox(height: 28),

              _buildRecordingSection(context),

              const SizedBox(height: 24),

              if (_isRecording) ...[
                const SizedBox(height: 16),
              ],

              if (!_isRecording) _buildStoryPrompts(context),

              if (!_isRecording && !_isModelLoading) ...[
                const SizedBox(height: 24),
                _buildIdleGuide(context),
              ],

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaveVisualizer(BuildContext context) {
    final c = ResonanceColors.of(context);
    return ResonanceCard(
      c: c,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(20, (index) {
              return AnimatedContainer(
                duration: Duration(milliseconds: _isRecording ? 100 : 400),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 6,
                height: _isRecording
                    ? 30 + (_waveHeights[index] * 80)
                    : 15 + (_waveHeights[index] * 15),
                decoration: BoxDecoration(
                  color: _isRecording
                      ? c.primary
                      : c.outlineVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            }),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _isRecording ? c.primary : c.outline,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _isRecording
                    ? AppLocalizations.tr('analyzing_voice')
                    : AppLocalizations.tr('ready_to_listen'),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _isRecording ? c.primary : c.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingSection(BuildContext context) {
    final c = ResonanceColors.of(context);

    return Column(
      children: [
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
                            color: c.primary.withValues(alpha: 0.12),
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
                            color: c.primary.withValues(alpha: 0.2),
                          ),
                        ),
                      ),

                    // Main Button
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.primary,
                        boxShadow: [
                          BoxShadow(
                            color: c.shadowColorStrong,
                            offset: const Offset(4, 4),
                            blurRadius: 12,
                            spreadRadius: -3,
                          ),
                        ],
                      ),
                      child: Icon(
                        PhosphorIconsRegular.microphone,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        ResonanceChip(
          c: c,
          label: _isModelLoading
              ? AppLocalizations.tr('loading_model_short')
              : AppLocalizations.tr('tap_to_start'),
          icon: _isModelLoading
              ? null
              : PhosphorIconsRegular.caretRight,
        ),
        if (_detectedEmotion != null) ...[
          const SizedBox(height: 12),
          Text(
            '${AppLocalizations.tr("emotion_detected")} ${_detectedEmotion!.displayName}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: c.primary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStoryPrompts(BuildContext context) {
    final c = ResonanceColors.of(context);
    final locale = AppLocalizations.locale;
    final isEn = locale.startsWith('en');

    final prompts = isEn
        ? [
            {
              'icon': PhosphorIconsRegular.question,
              'color': const Color(0xFF8C7075),
              'text': "What's been worrying you the most lately?",
            },
            {
              'icon': PhosphorIconsRegular.star,
              'color': const Color(0xFFF59E0B),
              'text': 'Tell me about something you\'re proud of recently',
            },
            {
              'icon': PhosphorIconsRegular.flame,
              'color': const Color(0xFFF97316),
              'text': 'How have you been dealing with challenges?',
            },
            {
              'icon': PhosphorIconsRegular.usersThree,
              'color': const Color(0xFF10B981),
              'text': 'Who always supports you? Tell me about them',
            },
            {
              'icon': PhosphorIconsRegular.smileySad,
              'color': const Color(0xFF8B5CF6),
              'text': 'What made you saddest this week?',
            },
            {
              'icon': PhosphorIconsRegular.target,
              'color': const Color(0xFF3B82F6),
              'text': 'What goal do you want to achieve this month?',
            },
            {
              'icon': PhosphorIconsRegular.heart,
              'color': const Color(0xFFEF4444),
              'text': 'What\'s the best thing that happened to you recently?',
            },
            {
              'icon': PhosphorIconsRegular.plant,
              'color': const Color(0xFF84CC16),
              'text': 'How do you feel about your life balance?',
            },
          ]
        : [
            {
              'icon': PhosphorIconsRegular.question,
              'color': const Color(0xFF8C7075),
              'text': 'Apa yang paling membuatmu khawatir hari ini?',
            },
            {
              'icon': PhosphorIconsRegular.star,
              'color': const Color(0xFFF59E0B),
              'text': 'Ceritakan hal yang membuatmu bangga akhir-akhir ini',
            },
            {
              'icon': PhosphorIconsRegular.flame,
              'color': const Color(0xFFF97316),
              'text': 'Bagaimana cara kamu menghadapi tantangan recently?',
            },
            {
              'icon': PhosphorIconsRegular.usersThree,
              'color': const Color(0xFF10B981),
              'text': 'Siapa yang selalu mendukungmu? Ceritakan tentang mereka',
            },
            {
              'icon': PhosphorIconsRegular.smileySad,
              'color': const Color(0xFF8B5CF6),
              'text': 'Apa yang paling membuatmu sedih minggu ini?',
            },
            {
              'icon': PhosphorIconsRegular.target,
              'color': const Color(0xFF3B82F6),
              'text': 'Apa target yang ingin kamu capai bulan ini?',
            },
            {
              'icon': PhosphorIconsRegular.heart,
              'color': const Color(0xFFEF4444),
              'text': 'Apa hal terbaik yang terjadi padamu baru-baru ini?',
            },
            {
              'icon': PhosphorIconsRegular.plant,
              'color': const Color(0xFF84CC16),
              'text': 'Bagaimana perasaanmu tentang keseimbangan hidupmu?',
            },
          ];

    return ResonanceCard(
      c: c,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: c.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  PhosphorIconsRegular.chatCircleText,
                  color: c.primary,
                  size: 17,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isEn ? 'Share Your Thoughts' : 'Ceritakan Keluh Kesahmu',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: c.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isEn
                ? 'Choose one of the questions below and share your feelings:'
                : 'Pilih salah satu pertanyaan di bawah ini dan ceritakan perasaanmu:',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: c.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ...prompts.map(
            (prompt) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.outlineVariant),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: (prompt['color']! as Color).withValues(
                          alpha: 0.12,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        prompt['icon'] as IconData,
                        color: prompt['color'] as Color,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          prompt['text']! as String,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            color: c.onSurface,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.primaryContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: c.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIconsRegular.lightbulb,
                  color: c.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.tr('press_mic_tip'),
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: c.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleGuide(BuildContext context) {
    final c = ResonanceColors.of(context);

    return ResonanceCard(
      c: c,
      padding: const EdgeInsets.all(20),
      softShadow: true,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              PhosphorIconsRegular.info,
              color: c.primary,
              size: 20,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.tr('how_to_use_title'),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: c.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          _buildGuideStep(context, '1', AppLocalizations.tr('guide_step_1_record')),
          const SizedBox(height: 10),
          _buildGuideStep(context, '2', AppLocalizations.tr('guide_step_2_speak')),
          const SizedBox(height: 10),
          _buildGuideStep(context, '3', AppLocalizations.tr('guide_step_3_stop')),
          const SizedBox(height: 10),
          _buildGuideStep(context, '4', AppLocalizations.tr('guide_step_4_view')),
        ],
      ),
    );
  }

  Widget _buildGuideStep(BuildContext context, String number, String text) {
    final c = ResonanceColors.of(context);

    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: c.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: c.shadowColor,
                offset: const Offset(1.5, 1.5),
                blurRadius: 4,
              ),
            ],
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: c.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}