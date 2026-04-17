import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../l10n/app_localizations.dart';
import '../models/emotion_model.dart';
import '../providers/auth_provider.dart';
import '../services/audio_recorder_detection.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/emotion_badge.dart';
import 'result_screen.dart';

class LiveDetectionScreen extends StatefulWidget {
  const LiveDetectionScreen({super.key});

  @override
  State<LiveDetectionScreen> createState() => _LiveDetectionScreenState();
}

class _LiveDetectionScreenState extends State<LiveDetectionScreen>
    with TickerProviderStateMixin {
  bool _isRecording = false;
  bool _isModelLoading = true;
  bool _isModelReady = false;
  bool _hasPermission = false;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _waveCtrl;

  EmotionType? _detectedEmotion;
  double? _detectedConfidence;
  Map<EmotionType, double>? _detectedScores;

  final AudioRecorderWithDetection _recorder =
      AudioRecorderWithDetection.instance;
  StreamSubscription? _detectionSubscription;

  final _rand = Random();
  List<double> _waveHeights = List.generate(20, (_) => 0.3);

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
      _hasPermission = await _recorder.checkAndRequestPermission();
      await _recorder.loadModel();

      setState(() {
        _isModelReady = true;
        _isModelLoading = false;
      });

      _detectionSubscription = _recorder.detectionStream.listen(
        _onDetectionResult,
      );
    } catch (e) {
      setState(() => _isModelLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat model: \$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onDetectionResult(result) {
    if (mounted) {
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
        _startAudioSimulation();

        setState(() {
          _isRecording = true;
          _detectedEmotion = null;
          _detectedConfidence = null;
          _detectedScores = null;
          _pulseCtrl.repeat(reverse: true);
          _waveCtrl.repeat();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memulai rekaman: \$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // STOP RECORDING
      final audioPath = await _recorder.stopRecording();
      _stopAudioSimulation();

      _pulseCtrl.stop();
      _pulseCtrl.reset();
      _waveCtrl.stop();
      
      setState(() {
        _isRecording = false;
      });

      final hasEmotionData = _detectedEmotion != null && _detectedScores != null;

      if (hasEmotionData && audioPath != null) {
        try {
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
            transcriptText: '',
          );

          await DatabaseService.insertRecording(record);
          
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ResultScreen(recordingData: record)),
            );
          }
        } catch (e) {
          debugPrint('❌ Error saving recording: \$e');
        }
      }
    }
  }

  Timer? _audioSimulationTimer;

  void _startAudioSimulation() {
    final rand = Random();
    _audioSimulationTimer?.cancel();
    _audioSimulationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final samples = List.generate(
        1600,
        (_) => (rand.nextDouble() * 2 - 1) * 0.5,
      );
      _recorder.addAudioSamples(samples);
    });
  }

  void _stopAudioSimulation() {
    _audioSimulationTimer?.cancel();
    _audioSimulationTimer = null;
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
            Text(AppLocalizations.tr('live_detection_title')),
          ],
        ),
      ),
      body: SafeArea(
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
                            AppTheme.primaryColor,
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
                _buildLiveResults(),
                const SizedBox(height: AppTheme.spaceMd),
              ],

              if (!_isRecording) _buildStoryPrompts(),

              if (!_isRecording && !_isModelLoading)
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
      height: 180,
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
            _isRecording ? 'Menganalisis Suara Live...' : 'Siap Mendengarkan',
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
                    ? AppLocalizations.tr('tap_to_stop')
                    : _isModelLoading
                    ? AppLocalizations.tr('loading_model_short')
                    : AppLocalizations.tr('tap_to_start'),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: _isRecording ? Colors.redAccent : AppTheme.textP(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (_isRecording) ...[
          const SizedBox(height: 12),
          Text(
            _detectedEmotion != null
                ? '${AppLocalizations.tr("emotion_detected")} ${_detectedEmotion!.displayName}'
                : AppLocalizations.tr('detecting_emotion'),
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
          Row(
            children: [
              Icon(
                Icons.analytics_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Distribusi Emosi Live',
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

          const SizedBox(height: 24),

          if (_detectedScores != null)
            SizedBox(
              height: 200,
              child: RadarChart(
                RadarChartData(
                  dataSets: [
                    RadarDataSet(
                      fillColor: AppTheme.primaryColor.withOpacity(0.2),
                      borderColor: AppTheme.primaryColor,
                      entryRadius: 3,
                      dataEntries: EmotionType.values.map((e) {
                        return RadarEntry(value: _detectedScores![e] ?? 0.0);
                      }).toList(),
                      borderWidth: 2,
                    ),
                  ],
                  radarBackgroundColor: Colors.transparent,
                  borderData: FlBorderData(show: false),
                  radarBorderData: const BorderSide(color: Colors.transparent),
                  tickCount: 3,
                  ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 10),
                  tickBorderData: BorderSide(color: AppTheme.textH(context).withOpacity(0.2)),
                  gridBorderData: BorderSide(color: AppTheme.textH(context).withOpacity(0.2), width: 1.5),
                  getTitle: (index, angle) {
                    final emotion = EmotionType.values[index];
                    return RadarChartTitle(
                      text: emotion.displayName,
                      angle: 0,
                      positionPercentageOffset: 0.1,
                    );
                  },
                ),
                swapAnimationDuration: const Duration(milliseconds: 200),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStoryPrompts() {
    final prompts = [
      {'emoji': '💭', 'text': 'Apa yang paling membuatmu khawatir hari ini?'},
      {'emoji': '🌟', 'text': 'Ceritakan hal yang membuatmu bangga akhir-akhir ini'},
      {'emoji': '💪', 'text': 'Bagaimana cara kamu menghadapi tantangan recently?'},
      {'emoji': '🤗', 'text': 'Siapa yang selalu mendukungmu? Ceritakan tentang mereka'},
      {'emoji': '😔', 'text': 'Apa yang paling membuatmu sedih minggu ini?'},
      {'emoji': '🎯', 'text': 'Apa target yang ingin kamu capai bulan ini?'},
      {'emoji': '❤️', 'text': 'Apa hal terbaik yang terjadi padamu baru-baru ini?'},
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
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Ceritakan Keluh Kesahmu',
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
            'Pilih salah satu pertanyaan di bawah ini dan ceritakan perasaanmu:',
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
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppTheme.primaryColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '💡 Tekan tombol mikrofon dan mulailah bercerita',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: AppTheme.primaryColor,
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
