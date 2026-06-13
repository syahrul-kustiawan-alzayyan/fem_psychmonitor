import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:record/record.dart';
import 'package:whisper_kit/whisper_kit.dart';
import 'package:path_provider/path_provider.dart';
import '../l10n/app_localizations.dart';
import '../models/emotion_model.dart';
import '../providers/auth_provider.dart';
import '../providers/premium_provider.dart';
import '../services/ad_service.dart';
import '../services/database_service.dart';
import '../services/gemini_service.dart';
import '../services/suggestion_service.dart';
import '../services/text_emotion_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';
import 'result_screen.dart';

class EmotionDetectionScreen extends StatefulWidget {
  const EmotionDetectionScreen({super.key});

  @override
  State<EmotionDetectionScreen> createState() =>
      _EmotionDetectionScreenState();
}

class _EmotionDetectionScreenState extends State<EmotionDetectionScreen>
    with TickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  Whisper? _whisper;
  String? _wavPath;

  bool _isRecording = false;
  bool _isProcessing = false;
  String _processingMessage = '';

  EmotionType? _currentEmotion;
  Map<EmotionType, double> _currentScores = {
    for (final e in EmotionType.values) e: 1.0 / EmotionType.values.length,
  };

  Map<EmotionType, double> _finalAudioScores = {};
  DateTime? _recordingStartTime;

  Timer? _emotionUpdateTimer;
  Timer? _waveformTimer;
  final _rand = Random();
  final List<double> _waveHeights = List.generate(30, (_) => 0.3);
  int _waveformFrame = 0;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

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

    _startRecording();
  }

  Future<void> _startRecording() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      if (mounted) Navigator.pop(context);
      return;
    }

    try {
      _whisper = Whisper(model: WhisperModel.base);

      final dir = await getTemporaryDirectory();
      _wavPath = '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: _wavPath!,
      );

      _recordingStartTime = DateTime.now();
      setState(() => _isRecording = true);
      _pulseCtrl.repeat(reverse: true);

      _emotionUpdateTimer = Timer.periodic(
        const Duration(seconds: 3),
        (_) {
          if (mounted) {
            setState(() {
              _currentScores = _generateMockScores();
              _currentEmotion = _currentScores.entries.reduce(
                (a, b) => a.value >= b.value ? a : b,
              ).key;
            });
          }
        },
      );
      if (mounted) {
        setState(() {
          _currentScores = _generateMockScores();
          _currentEmotion = _currentScores.entries.reduce(
            (a, b) => a.value >= b.value ? a : b,
          ).key;
        });
      }

      _waveformTimer = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) {
          if (_isRecording && mounted) {
            setState(() {
              _waveformFrame++;
              for (int i = 0; i < _waveHeights.length; i++) {
                _waveHeights[i] = 0.2 + (_rand.nextDouble() * 0.6);
              }
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.tr('failed_start_recording_detail').replaceFirst('{error}', '$e'))),
        );
        Navigator.pop(context);
      }
    }
  }

  Map<EmotionType, double> _generateMockScores() {
    final scores = <EmotionType, double>{};
    double remaining = 1.0;
    final values = EmotionType.values.toList()..shuffle(_rand);
    for (int i = 0; i < values.length - 1; i++) {
      final v = remaining * (0.05 + _rand.nextDouble() * 0.35);
      scores[values[i]] = v;
      remaining -= v;
    }
    scores[values.last] = remaining;
    return scores;
  }

  Future<void> _stopRecording() async {
    setState(() => _isProcessing = true);
    _emotionUpdateTimer?.cancel();
    _waveformTimer?.cancel();
    _pulseCtrl.stop();
    _pulseCtrl.reset();

    _finalAudioScores = Map.from(_currentScores);

    // Step 1: Stop recording
    String? recordedPath;
    try {
      recordedPath = await _audioRecorder.stop();
    } catch (e) {
      debugPrint('🎙️ Stop recording error: $e');
    }
    final path = recordedPath ?? _wavPath;

    // Step 2: Transcribe with Whisper (offline, no Google Services)
    String transcript = '';
    if (path != null && _whisper != null) {
      if (mounted) {
        setState(() => _processingMessage = AppLocalizations.tr('processing_transcription_first'));
      }
      try {
        final result = await _whisper!.transcribe(
          transcribeRequest: TranscribeRequest(
            audio: path,
          ),
        );
        transcript = result.text.trim();
        debugPrint('📝 Whisper transcript: "$transcript"');
      } catch (e) {
        debugPrint('🎙️ Whisper transcribe error: $e');
      }
    }

    // Step 3: Analyze emotion from transcript text (local, no API)
    if (mounted) {
      setState(() => _processingMessage = AppLocalizations.tr('analyzing_text_emotion'));
    }
    await Future.delayed(const Duration(milliseconds: 300));

    await TextEmotionService.instance.loadAll();
    final textScores = TextEmotionService.instance.analyze(transcript);

    final hasAudioData =
        _finalAudioScores.isNotEmpty && _finalAudioScores.values.any((v) => v > 0);

    if (hasAudioData) {
      final combined = GeminiService.combineResults(
        _finalAudioScores,
        textScores,
        audioWeight: 0.6,
        textWeight: 0.4,
      );

      final dominant = combined.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );

      final user = await DatabaseService.getUser();
      final userId = user?.id ?? 1;

      final suggService = SuggestionService();
      await suggService.load();
      final mbtiType = user?.mbtiType ?? '';
      final firstSugg = (mbtiType.isNotEmpty && mbtiType != 'XXXX')
          ? suggService.getFirstSuggestion(mbtiType, dominant.key)
          : dominant.key.recordingSuggestions.first;

      final durationSec = _recordingStartTime != null
          ? DateTime.now().difference(_recordingStartTime!).inSeconds
          : 0;

      final record = RecordingData(
        userId: userId,
        dominantEmotion: dominant.key,
        confidence: dominant.value,
        date: DateTime.now(),
        suggestion: firstSugg,
        audioEmotions: _finalAudioScores,
        transcriptEmotions: textScores,
        transcriptText: transcript,
        durationSeconds: durationSec,
        triggerTag: '',
      );

      final recId = await DatabaseService.insertRecording(record);
      final savedRecord = RecordingData(
        id: recId,
        userId: record.userId,
        date: record.date,
        dominantEmotion: record.dominantEmotion,
        confidence: record.confidence,
        suggestion: record.suggestion,
        audioEmotions: record.audioEmotions,
        transcriptEmotions: record.transcriptEmotions,
        transcriptText: record.transcriptText,
        durationSeconds: record.durationSeconds,
        triggerTag: record.triggerTag,
      );

      if (mounted) {
        final premium = context.read<PremiumProvider>();
        if (!premium.isPremium) {
          await AdService().showInterstitialAd();
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ResultScreen(recordingData: savedRecord),
            ),
          );
        }
      }
    } else {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.tr('emotion_data_unavailable')),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _emotionUpdateTimer?.cancel();
    _waveformTimer?.cancel();
    _pulseCtrl.dispose();
    _audioRecorder.dispose();
    super.dispose();
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
        leadingWidth: 0,
        centerTitle: false,
        title: ShaderMask(
          shaderCallback: (bounds) =>
              AppTheme.primaryGradient.createShader(bounds),
          child: Row(
            children: [
              Icon(Icons.mic_rounded, size: 22, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.tr('emotion_detection'),
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
        child: Stack(
          children: [
            Positioned.fill(
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 130),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _buildTimerIndicator(),
                      const SizedBox(height: 16),
                      _buildWaveform(),
                      const SizedBox(height: 20),
                      _buildEmotionRow(),
                      const SizedBox(height: 20),
                      _buildEmotionScoreBars(),
                    ],
                  ),
                ),
              ),
            ),
            if (!_isProcessing) _buildFloatingStopButton(),
            if (_isProcessing)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 40,
                left: 20,
                right: 20,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.surface(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.12),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Text(
                              key: ValueKey(_processingMessage),
                              _processingMessage.isNotEmpty
                                  ? _processingMessage
                                  : AppLocalizations.tr('processing_result'),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textS(context),
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
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildTimerIndicator() {
    final elapsed = _recordingStartTime != null
        ? DateTime.now().difference(_recordingStartTime!)
        : Duration.zero;
    final dotCount = (_waveformFrame ~/ 5) % 4;
    final dots = '.' * dotCount;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${AppLocalizations.tr('listening_label')}$dots',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _buildChip(
          Icons.timer_outlined,
          _formatDuration(elapsed),
          AppTheme.primaryColor,
        ),
        const SizedBox(width: 10),
        _buildChip(
          Icons.mood_outlined,
          _currentEmotion?.displayName ?? '-',
          _currentEmotion?.color ?? AppTheme.textHint,
        ),
      ],
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveform() {
    return Container(
      width: double.infinity,
      height: 140,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.12),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(30, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: 5,
              height: 20 + (_waveHeights[index] * 80),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildEmotionRow() {
    final emotion = _currentEmotion;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: _buildEmotionIcon(emotion),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: _buildRadarChart(),
        ),
      ],
    );
  }

  Widget _buildEmotionScoreBars() {
    final scores = _currentScores;
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.12),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.tr('emotion_score'),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textS(context),
            ),
          ),
          const SizedBox(height: 12),
          ...sorted.map((e) => _buildScoreBarRow(e.key, e.value)),
        ],
      ),
    );
  }

  Widget _buildScoreBarRow(EmotionType emotion, double score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 16, height: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                emotion.assetIconPath,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Icon(
                  emotion.icon, size: 14, color: emotion.color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: Text(
              emotion.displayName,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.textP(context),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.surfVar(context),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: score,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [emotion.color, emotion.color.withValues(alpha: 0.7)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(
              '${(score * 100).toStringAsFixed(0)}%',
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: emotion.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionIcon(EmotionType? emotion) {
    final e = emotion ?? EmotionType.neutral;
    final scores = _currentScores;
    final conf = scores[e] ?? 0;
    final bgColors = AppTheme.emotionBgColors;
    final bgColor = bgColors[e.displayName] ?? AppTheme.surfVar(context);
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: e.color.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: e.color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: Image.asset(
                e.assetIconPath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  e.icon,
                  size: 32,
                  color: e.color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            e.displayName,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: e.color,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: e.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${(conf * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: e.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarChart() {
    final scores = _currentScores;
    final entries = EmotionType.values
        .map((e) => RadarEntry(value: (scores[e] ?? 0) * 100))
        .toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.12),
          width: 1.5,
        ),
      ),
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.polygon,
          tickCount: 3,
          tickBorderData: BorderSide(
            color: AppTheme.surfVar(context),
            width: 0.5,
          ),
          gridBorderData: BorderSide(
            color: AppTheme.surfVar(context),
            width: 0.5,
          ),
          titlePositionPercentageOffset: 0.2,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppTheme.textS(context),
          ),
          getTitle: (index, _) {
            final e = EmotionType.values[index];
            return RadarChartTitle(text: e.name);
          },
          dataSets: [
            RadarDataSet(
              fillColor: AppTheme.primaryColor.withValues(alpha: 0.12),
              borderColor: AppTheme.primaryColor,
              borderWidth: 2,
              entryRadius: 3,
              dataEntries: entries,
            ),
          ],
        ),
        duration: const Duration(milliseconds: 400),
      ),
    );
  }

  Widget _buildFloatingStopButton() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 24,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: _stopRecording,
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, child) {
              return Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5252), Color(0xFFD32F2F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.stop_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
