import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/emotion_model.dart';
import '../providers/auth_provider.dart';
import '../services/audio_recorder_detection.dart' show AudioRecorderWithDetection, DetectionResult;
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';
import 'emotion_detection_screen.dart';

class LiveDetectionScreen extends StatefulWidget {
  const LiveDetectionScreen({super.key});

  @override
  State<LiveDetectionScreen> createState() => _LiveDetectionScreenState();
}

class _LiveDetectionScreenState extends State<LiveDetectionScreen>
    with TickerProviderStateMixin {
  bool _isRecording = false;
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
          backgroundColor: AppTheme.primaryColor,
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppTheme.primaryGradient.createShader(bounds),
              child: const Icon(
                Icons.mic_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppTheme.primaryGradient.createShader(
                    Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                  ),
              child: Text(
                AppLocalizations.tr('live_detection_title'),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
      ),
      body: GradientBackground(
        useOverlay: true,
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
            child: Column(
              children: [
                const SizedBox(height: AppTheme.spaceMd),

                if (_isModelLoading)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfVar(context),
                      borderRadius: BorderRadius.circular(12),
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
                              AppTheme.iconColor(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppLocalizations.tr('loading_model'),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppTheme.textS(context),
                          ),
                        ),
                      ],
                    ),
                  ),

                _buildWaveVisualizer(),

                const SizedBox(height: AppTheme.space2xl),

                _buildRecordingSection(context),

                const SizedBox(height: AppTheme.spaceXl),

                if (_isRecording) ...[
                  const SizedBox(height: AppTheme.spaceMd),
                ],

                if (!_isRecording) _buildStoryPrompts(),

                if (!_isRecording && !_isModelLoading) ...[
                  const SizedBox(height: 24),
                  _buildIdleGuide(),
                ],

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaveVisualizer() {
    return Container(
      height: 220,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surface(context),
            AppTheme.surface(context).withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
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
                  gradient: LinearGradient(
                     colors: _isRecording
                         ? [AppTheme.primaryColor, AppTheme.secondaryColor]
                         : [
                             AppTheme.primaryColor.withValues(alpha: 0.3),
                             AppTheme.secondaryColor.withValues(alpha: 0.3),
                           ],
                     begin: Alignment.bottomCenter,
                     end: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          Text(
            _isRecording ? AppLocalizations.tr('analyzing_voice') : AppLocalizations.tr('ready_to_listen'),
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _isRecording ? AppTheme.primaryColor : AppTheme.textS(context),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingSection(BuildContext context) {
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
                        gradient: AppTheme.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.mic_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.surfVar(context),
              width: 1,
            )
          ),
          child: Text(
            _isModelLoading
                ? AppLocalizations.tr('loading_model_short')
                : AppLocalizations.tr('tap_to_start'),
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.textP(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (_detectedEmotion != null) ...[
          const SizedBox(height: 12),
          Text(
            '${AppLocalizations.tr("emotion_detected")} ${_detectedEmotion!.displayName}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ],
    );
  }


Widget _buildStoryPrompts() {
    final locale = AppLocalizations.locale;
    final isEn = locale.startsWith('en');
    
    final prompts = isEn
        ? [
            {'emoji': '💭', 'text': "What's been worrying you the most lately?"},
            {'emoji': '🌟', 'text': 'Tell me about something you\'re proud of recently'},
            {'emoji': '💪', 'text': 'How have you been dealing with challenges?'},
            {'emoji': '🤗', 'text': 'Who always supports you? Tell me about them'},
            {'emoji': '😔', 'text': 'What made you saddest this week?'},
            {'emoji': '🎯', 'text': 'What goal do you want to achieve this month?'},
            {'emoji': '❤️', 'text': 'What\'s the best thing that happened to you recently?'},
            {'emoji': '🧘', 'text': 'How do you feel about your life balance?'},
          ]
        : [
            {'emoji': '💭', 'text': 'Apa yang paling membuatmu khawatir hari ini?'},
            {'emoji': '🌟', 'text': 'Ceritakan hal yang membuatmu bangga akhir-akhir ini'},
            {'emoji': '💪', 'text': 'Bagaimana cara kamu menghadapi tantangan recently?'},
            {'emoji': '🤗', 'text': 'Siapa yang selalu mendukungmu? Ceritakan tentang mereka'},
            {'emoji': '😔', 'text': 'Apa yang paling membuatmu sedih minggu ini?'},
            {'emoji': '🎯', 'text': 'Apa target yang ingin kamu capai bulan ini?'},
            {'emoji': '❤️', 'text': 'Apa hal terbaik yang terjadi padamu baru-barui ini?'},
            {'emoji': '🧘', 'text': 'Bagaimana perasaanmu tentang keseimbangan hidupmu?'},
          ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppTheme.iconColor(context),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isEn ? 'Share Your Thoughts' : 'Ceritakan Keluh Kesahmu',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textP(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isEn 
                ? 'Choose one of the questions below and share your feelings:'
                : 'Pilih salah satu pertanyaan di bawah ini dan ceritakan perasaanmu:',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.textS(context),
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
                  color: AppTheme.surfVar(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.surfVar(context),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prompt['emoji']!,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        prompt['text']!,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          color: AppTheme.textP(context),
                          height: 1.4,
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
              color: AppTheme.iconColor(context).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.iconColor(context).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppTheme.iconColor(context),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '💡 ${AppLocalizations.tr('press_mic_tip')}',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: AppTheme.iconColor(context),
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

  Widget _buildIdleGuide() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfVar(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppTheme.iconColor(context),
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.tr('how_to_use_title'),
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textP(context),
            ),
          ),
          const SizedBox(height: 12),
_buildGuideStep('1', AppLocalizations.tr('guide_step_1_record')),
          _buildGuideStep('2', AppLocalizations.tr('guide_step_2_speak')),
          _buildGuideStep('3', AppLocalizations.tr('guide_step_3_stop')),
          _buildGuideStep('4', AppLocalizations.tr('guide_step_4_view')),
        ],
      ),
    );
  }

  Widget _buildGuideStep(String number, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.poppins(
                fontSize: 12,
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
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.textS(context),
            ),
          ),
        ),
      ],
    );
  }
}
