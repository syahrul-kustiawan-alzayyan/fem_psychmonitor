import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/emotion_model.dart';
import '../providers/auth_provider.dart';
import '../services/audio_recorder_detection.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/emotion_badge.dart';
import '../widgets/suggestion_card.dart';

/// LiveDetectionScreen - Layar deteksi emosi real-time menggunakan TFLite
///
/// Fitur:
/// - Live audio recording
/// - Real-time emotion detection menggunakan model TFLite
/// - Visualisasi waveform
/// - Hasil deteksi dengan confidence score
class LiveDetectionScreen extends StatefulWidget {
  const LiveDetectionScreen({super.key});

  @override
  State<LiveDetectionScreen> createState() => _LiveDetectionScreenState();
}

class _LiveDetectionScreenState extends State<LiveDetectionScreen>
    with TickerProviderStateMixin {
  bool _isRecording = false;
  bool _hasResult = false;
  bool _isModelLoading = true;
  bool _isModelReady = false;
  bool _hasPermission = false;

  // Animation controllers
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _waveCtrl;
  late AnimationController _resultFadeCtrl;
  late Animation<double> _resultFade;

  // Detection results
  EmotionType? _detectedEmotion;
  double? _detectedConfidence;
  Map<EmotionType, double>? _detectedScores;

  // Audio Recorder with Detection
  final AudioRecorderWithDetection _recorder =
      AudioRecorderWithDetection.instance;
  StreamSubscription? _detectionSubscription;

  // Random untuk visualisasi waveform
  final _rand = Random();
  List<double> _waveHeights = List.generate(20, (_) => 0.3);

  @override
  void initState() {
    super.initState();

    // Setup animations
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

    // Load model
    _loadModel();

    // Setup waveform animation
    _waveCtrl.addListener(_updateWaveform);
  }

  Future<void> _loadModel() async {
    setState(() => _isModelLoading = true);

    try {
      // Check permission first
      _hasPermission = await _recorder.checkAndRequestPermission();

      // Load model
      await _recorder.loadModel();

      setState(() {
        _isModelReady = true;
        _isModelLoading = false;
      });

      // Subscribe to detection stream
      _detectionSubscription = _recorder.detectionStream.listen(
        _onDetectionResult,
      );
    } catch (e) {
      setState(() => _isModelLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat model: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onDetectionResult(result) {
    if (mounted && _isRecording) {
      setState(() {
        _detectedEmotion = result.dominantEmotion;
        _detectedConfidence = result.confidence;
        _detectedScores = result.scores;
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
    _resultFadeCtrl.dispose();
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

    if (!_isModelReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Model belum siap. Tunggu sebentar...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permission microphone diperlukan untuk fitur ini'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_isRecording) {
      // START RECORDING
      try {
        await _recorder.startRecording();
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
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memulai rekaman: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // STOP RECORDING
      await _recorder.stopRecording();
      _pulseCtrl.stop();
      _pulseCtrl.reset();
      _waveCtrl.stop();

      // Save hasil ke database jika ada
      if (_detectedEmotion != null && _detectedScores != null) {
        final user = await DatabaseService.getUser();
        final userId = user?.id ?? 1;

        final record = RecordingData(
          userId: userId,
          dominantEmotion: _detectedEmotion!,
          confidence: _detectedConfidence ?? 0.0,
          date: DateTime.now(),
          suggestion: _detectedEmotion!.recordingSuggestions.first,
          audioEmotions: _detectedScores!,
          transcriptEmotions: _detectedScores!,
        );

        await DatabaseService.insertRecording(record);

        setState(() {
          _isRecording = false;
          _hasResult = true;
          _resultFadeCtrl.forward();
        });
      } else {
        setState(() {
          _isRecording = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
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
            Text('Deteksi Emosi Live'),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
          child: Column(
            children: [
              const SizedBox(height: AppTheme.spaceMd),

              // Status model
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
                            AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Memuat model TFLite...',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.textS(context),
                        ),
                      ),
                    ],
                  ),
                ),

              // Visualizer
              _buildWaveVisualizer(),

              const SizedBox(height: AppTheme.space2xl),

              // Recording button
              _buildRecordingSection(context),

              const SizedBox(height: AppTheme.spaceXl),

              // Live detection results
              if (_detectedEmotion != null && _isRecording) _buildLiveResults(),

              // Final results after recording
              if (_hasResult && _detectedEmotion != null)
                FadeTransition(
                  opacity: _resultFade,
                  child: Column(
                    children: [
                      _buildFinalResults(),
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

              // Guide when idle
              if (!_hasResult && !_isRecording && !_isModelLoading)
                _buildIdleGuide(),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaveVisualizer() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(20, (index) {
          return AnimatedContainer(
            duration: Duration(milliseconds: _isRecording ? 100 : 400),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 8,
            height: _isRecording
                ? 40 + (_waveHeights[index] * 120)
                : 20 + (_waveHeights[index] * 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isRecording
                    ? [AppTheme.primaryColor, AppTheme.secondaryColor]
                    : [
                        AppTheme.textH(context).withValues(alpha: 0.3),
                        AppTheme.textH(context).withValues(alpha: 0.1),
                      ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRecordingSection(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (context, child) {
            return Transform.scale(
              scale: _isRecording ? _pulseAnim.value : 1.0,
              child: GestureDetector(
                onTap: _toggleRecording,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _isRecording
                        ? LinearGradient(
                            colors: [Colors.red, Colors.red.shade700],
                          )
                        : AppTheme.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_isRecording ? Colors.red : AppTheme.primaryColor)
                                .withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          _isRecording
              ? 'Sentuh untuk menghentikan'
              : _isModelLoading
              ? 'Memuat model...'
              : 'Sentuh untuk memulai',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.textS(context),
            fontWeight: FontWeight.w500,
          ),
        ),
        if (_isRecording) ...[
          const SizedBox(height: 8),
          Text(
            _detectedEmotion != null
                ? 'Emosi terdeteksi: ${_detectedEmotion!.displayName}'
                : 'Mendeteksi emosi...',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.textH(context),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLiveResults() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // Current emotion
          Row(
            children: [
              Icon(
                Icons.analytics_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Deteksi Live',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textP(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Emotion badge
          if (_detectedEmotion != null)
            EmotionBadge(
              emotion: _detectedEmotion!,
              confidence: _detectedConfidence ?? 0.0,
            ),

          const SizedBox(height: 16),

          // Distribution
          if (_detectedScores != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Distribusi Emosi:',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textS(context),
                  ),
                ),
                const SizedBox(height: 8),
                ..._detectedScores!.entries
                    .where((e) => e.value > 0.05)
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 80,
                              child: Text(
                                entry.key.displayName,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppTheme.textS(context),
                                ),
                              ),
                            ),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: entry.value,
                                backgroundColor: AppTheme.surfVar(context),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  entry.key.color,
                                ),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(entry.value * 100).toStringAsFixed(0)}%',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: entry.key.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFinalResults() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Hasil Deteksi',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textP(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_detectedEmotion != null)
            EmotionBadge(
              emotion: _detectedEmotion!,
              confidence: _detectedConfidence ?? 0.0,
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
            color: AppTheme.primaryColor,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            'Cara Menggunakan',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textP(context),
            ),
          ),
          const SizedBox(height: 12),
          _buildGuideStep('1', 'Sentuh tombol mikrofon untuk memulai'),
          const SizedBox(height: 8),
          _buildGuideStep('2', 'Bicara dengan jelas selama 5-10 detik'),
          const SizedBox(height: 8),
          _buildGuideStep('3', 'Sentuh lagi untuk menghentikan'),
          const SizedBox(height: 8),
          _buildGuideStep('4', 'Lihat hasil deteksi emosi Anda'),
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
