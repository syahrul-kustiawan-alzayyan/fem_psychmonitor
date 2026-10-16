import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../l10n/app_localizations.dart';
import '../models/emotion_model.dart';
import '../providers/auth_provider.dart';
import '../providers/premium_provider.dart';
import '../services/ad_service.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../services/fusion_gate.dart';
import '../services/ser_service.dart';
import '../services/suggestion_service.dart';
import '../services/text_emotion_service.dart';
import '../theme/app_theme.dart';
import '../theme/resonance_colors.dart';
import '../widgets/painters.dart';
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
  final List<double> _waveTargets = List.generate(30, (_) => 0.4);
  int _waveformFrame = 0;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _rippleCtrl;

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

    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _startRecording();
  }

  Future<bool> _showRewardSuccessDialog() async {
    return (await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: const Color(0xFFF59E0B), size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppLocalizations.tr('reward_earned_title'),
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textP(context),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          AppLocalizations.tr('reward_earned_message'),
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppTheme.textS(context),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              AppLocalizations.tr('cancel'),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: AppTheme.textS(context),
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.tr('start_recording')),
          ),
        ],
      ),
    )) ?? false;
  }

  Future<bool> _showRewardedAdDialog() async {
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.tr('daily_limit_title')),
        content: Text(AppLocalizations.tr('daily_limit_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: Text(AppLocalizations.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'watch'),
            child: Text(AppLocalizations.tr('watch_ad')),
          ),
        ],
      ),
    );
    if (action == 'watch') {
      return await AdService().showRewardedAd();
    }
    return false;
  }

  Future<void> _startRecording() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final premium = context.read<PremiumProvider>();
    if (!premium.isPremium) {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final remaining = await StorageService.getRemainingDetections(uid);
      if (remaining <= 0) {
        if (!mounted) return;
        final watched = await _showRewardedAdDialog();
        if (!watched) {
          if (mounted) Navigator.pop(context);
          return;
        }
        if (!mounted) return;
        final proceed = await _showRewardSuccessDialog();
        if (!proceed) {
          if (mounted) Navigator.pop(context);
          return;
        }
      }
    }

    try {
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
              // Gelombang organik: lerping menuju target, bukan lompatan
              // acak murni, agar bergerak seperti gelombang suara nyata.
              for (int i = 0; i < _waveHeights.length; i++) {
                _waveHeights[i] +=
                    (_waveTargets[i] - _waveHeights[i]) * 0.45;
              }
              if (_waveformFrame % 3 == 0) {
                final mid = (_waveTargets.length - 1) / 2;
                for (int i = 0; i < _waveTargets.length; i++) {
                  // Envelope: batang tengah cenderung lebih tinggi.
                  final centerBias =
                      1.0 - ((i - mid).abs() / mid).clamp(0.0, 1.0);
                  _waveTargets[i] = 0.15 +
                      _rand.nextDouble() * 0.6 * (0.35 + 0.65 * centerBias);
                }
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

    // NOTE pengujian lokal: skor live di atas hanya animasi preview,
    // TIDAK dipakai sebagai hasil. Skor final wajib dari server SER
    // (fail-closed, tanpa fallback mock).
    _finalAudioScores = {};

    // Step 1: Stop recording
    String? recordedPath;
    try {
      recordedPath = await _audioRecorder.stop();
    } catch (e) {
      debugPrint('🎙️ Stop recording error: $e');
    }
    final path = recordedPath ?? _wavPath;
    _wavPath = path; // sync untuk upload nanti

    if (path == null) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.tr('emotion_data_unavailable')),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Step 1b: Server SER lokal — inferensi emosi + transkripsi PARALEL
    // (pengganti TFLite/mock dan Whisper on-device sebagai sumber utama).
    // Aturan gagal: emosi gagal -> batal simpan (fail-closed);
    // transkrip server gagal -> fallback Whisper on-device di bawah.
    String transcript = '';
    String transcriptionInfo = '';
    if (mounted) {
      setState(() => _processingMessage = 'Inferensi server (emosi + transkripsi)...');
    }
    try {
      final results = await Future.wait([
        SerService().predictEmotion(path),
        // Transkrip server boleh gagal sendiri: tangkap di sini agar
        // Future.wait tidak ikut gagal, lalu fallback on-device.
        SerService().transcribe(path).then<String>((t) => t).catchError((Object e) {
          debugPrint('⚠️ Transkrip server gagal, fallback on-device: $e');
          return '';
        }),
      ]);
      final ser = results[0] as SerResult;
      transcript = results[1] as String;
      _finalAudioScores = Map<EmotionType, double>.from(ser.scores);
      if (transcript.isNotEmpty) {
        transcriptionInfo = 'Transkrip: server (faster-whisper)';
      }
      if (mounted) {
        setState(() {
          _currentScores = Map<EmotionType, double>.from(ser.scores);
          _currentEmotion = ser.dominant;
        });
      }
      debugPrint('✅ SER ${ser.label} (${(ser.confidence * 100).toStringAsFixed(1)}%, ${ser.inferSeconds}s)');
      if (transcript.isNotEmpty) {
        debugPrint('📝 Transkrip server: "$transcript"');
      }
    } on SerException catch (e) {
      debugPrint('❌ SER gagal: $e');
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Server emosi lokal gagal: $e\nJalankan: python ser_server/server_ssl.py',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Step 2: Transkrip server kosong/gagal -> lanjut TANPA fallback
    // on-device (model on-device dihapus). Skor teks memakai profil
    // default netral (lihat TextEmotionService.analyze).
    if (transcript.isEmpty) {
      transcriptionInfo = 'Tidak ada teks terdeteksi';
    }
    if (mounted && transcriptionInfo.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(transcriptionInfo),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    // Step 3: Analyze emotion from transcript text (local, no API)
    if (mounted) {
      setState(() => _processingMessage = AppLocalizations.tr('analyzing_text_emotion'));
    }
    await Future.delayed(const Duration(milliseconds: 300));

    await TextEmotionService.instance.loadAll();
    final textAnalysis = TextEmotionService.instance.analyzeDetailed(transcript);
    final textScores = textAnalysis.scores;

    final hasAudioData =
        _finalAudioScores.isNotEmpty && _finalAudioScores.values.any((v) => v > 0);

    if (hasAudioData) {
      if (mounted) {
        setState(() => _processingMessage = 'Menerapkan confident-switch');
      }
      // Confident-switch tervalidasi; bukan blend berbobot tetap.
      final decision = FusionGate.decide(
        audioScores: _finalAudioScores,
        textScores: textScores,
        keywordHits: textAnalysis.hits,
      );

      // Distribusi untuk konsumen hilir: kanal yang menang (sum = 1) supaya
      // computeMentalHealthAdjustment() tetap bermakna.
      final combined = decision.textUsed ? textScores : _finalAudioScores;
      final dominant = MapEntry(
        decision.label,
        combined[decision.label] ?? 0.0,
      );
      debugPrint('🔀 Fusion: $decision');

      final user = await DatabaseService.getUser();
      final userId = user?.id ?? 1;

      final suggService = SuggestionService();
      await suggService.load();
      final bigFiveScores = user?.bigFiveScores ?? {};
      final firstSugg = suggService.getFirstSuggestion(bigFiveScores, dominant.key);

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

      // Upload audio ke backend cPanel
      if (_wavPath != null) {
        try {
          final file = File(_wavPath!);
          if (!file.existsSync()) {
            debugPrint('⚠️ File audio tidak ditemukan: $_wavPath');
          } else {
            debugPrint('📤 Upload audio: $_wavPath (${await file.length()} bytes)');
            final audioUrl = await ApiService().uploadAudio(_wavPath!);
            debugPrint('✅ Audio uploaded: $audioUrl');
            await DatabaseService.updateRecordingAudioUrl(recId, audioUrl);
          }
        } catch (e) {
          debugPrint('❌ Upload audio gagal: $e');
        }
      }

      // Update psychological score di Firebase dengan adjustment emosi.
      // Dominan netral -> tidak ada perubahan sama sekali; selain itu
      // jumlah berbobot semua emosi (lihat computeMentalHealthAdjustment).
      final currentUser = await DatabaseService.getUser();
      if (currentUser?.psychologicalScore != null &&
          dominant.key != EmotionType.neutral) {
        final emotionScore =
            computeMentalHealthAdjustment(combined, dominant: dominant.key);
        final newScore = ((currentUser!.psychologicalScore! + emotionScore).clamp(0, 100)).round();
        if (newScore != currentUser.psychologicalScore) {
          await DatabaseService.updateUser(
            currentUser.copyWith(psychologicalScore: newScore),
          );
        }
      }

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

      if (mounted && !context.read<PremiumProvider>().isPremium) {
        final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        await StorageService.incrementDetectionCount(uid);
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(recordingData: savedRecord),
          ),
        );
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
    _rippleCtrl.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Widget _buildRemainingChip() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return FutureBuilder<int>(
      future: StorageService.getRemainingDetections(uid),
      builder: (context, snapshot) {
        final premium = context.watch<PremiumProvider>();
        final remaining = snapshot.data ?? 5;
        final isLow = remaining <= 2;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: premium.isPremium
                ? const Color(0xFF10B981).withValues(alpha: 0.1)
                : isLow
                    ? const Color(0xFFF87171).withValues(alpha: 0.1)
                    : const Color(0xFFF59E0B).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: premium.isPremium
                  ? const Color(0xFF10B981).withValues(alpha: 0.3)
                  : isLow
                      ? const Color(0xFFF87171).withValues(alpha: 0.3)
                      : const Color(0xFFF59E0B).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                premium.isPremium
                    ? Icons.auto_awesome_rounded
                    : Icons.wifi_tethering_rounded,
                size: 14,
                color: premium.isPremium
                    ? const Color(0xFF10B981)
                    : isLow
                        ? const Color(0xFFF87171)
                        : const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 6),
              Text(
                premium.isPremium
                    ? AppLocalizations.tr('remaining_unlimited')
                    : '$remaining/${StorageService.maxFreeDetections}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: premium.isPremium
                      ? const Color(0xFF10B981)
                      : isLow
                          ? const Color(0xFFF87171)
                          : const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = ResonanceColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 0,
        centerTitle: false,
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
              AppLocalizations.tr('emotion_detection'),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: c.onSurface,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
          children: [
            Positioned.fill(
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 130),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _buildRemainingChip(),
                      const SizedBox(height: 12),
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
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: 1,
                  duration: const Duration(milliseconds: 250),
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.55),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: _buildProcessingCard(context),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
    );
  }

  /// Kartu pemrosesan gaya "stepper" — menunjukkan urutan tahapan
  /// transkripsi → analisis → penyimpanan, bukan spinner generik.
  Widget _buildProcessingCard(BuildContext context) {
    final c = ResonanceColors.of(context);
    final isEn = AppLocalizations.locale.startsWith('en');
    final steps = isEn
        ? ['Transcribing audio', 'Server emotion inference', 'Analyzing text emotion', 'Preparing results']
        : [
            'Transkripsi audio',
            'Inferensi server emosi',
            'Analisis emosi teks',
            'Menyiapkan hasil',
          ];
    final current = _processingStep;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.tr('processing_result'),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textP(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...List.generate(steps.length, (i) {
              final done = i < current;
              final active = i == current;
              final color = done
                  ? const Color(0xFF10B981)
                  : active
                      ? AppTheme.primaryColor
                      : c.outlineVariant;
              final icon = done
                  ? Icons.check_rounded
                  : active
                      ? null
                      : null;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: done
                                  ? color.withValues(alpha: 0.15)
                                  : Colors.transparent,
                              border: Border.all(color: color, width: 1.5),
                            ),
                            child: icon != null
                                ? Icon(icon, size: 15, color: color)
                                : active
                                    ? Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            color,
                                          ),
                                        ),
                                      )
                                    : null,
                          ),
                          if (i < steps.length - 1)
                            Expanded(
                              child: Container(
                                width: 2,
                                margin:
                                    const EdgeInsets.symmetric(vertical: 3),
                                color: i < current
                                    ? const Color(0xFF10B981)
                                        .withValues(alpha: 0.4)
                                    : c.outlineVariant,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 14),
                          child: Text(
                            steps[i],
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: active
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: done || active
                                  ? AppTheme.textP(context)
                                  : AppTheme.textH(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Tahapan pemrosesan aktif (0=transkripsi, 1=server SER, 2=analisis teks, 3=finalisasi).
  int get _processingStep {
    final m = _processingMessage.toLowerCase();
    if (m.contains('server') || m.contains('inferensi') || m.contains('inference')) {
      return 1;
    }
    if (m.contains('analisis') ||
        m.contains('analyz') ||
        m.contains('emosi teks')) {
      return 2;
    }
    if (m.contains('hasil') || m.contains('result') || m.isEmpty) return 3;
    return 0;
  }

  Widget _buildTimerIndicator() {
    final c = ResonanceColors.of(context);
    final elapsed = _recordingStartTime != null
        ? DateTime.now().difference(_recordingStartTime!)
        : Duration.zero;
    final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Titik REC berdenyut
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, child) => Transform.scale(
            scale: 0.9 + (_pulseAnim.value - 1.0) * 1.6,
            child: child,
          ),
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEF4444),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'REC',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
            color: const Color(0xFFEF4444),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 14),
          width: 1,
          height: 22,
          color: c.outlineVariant,
        ),
        // Timer besar gaya HUD
        Text(
          '$minutes:$seconds',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: c.onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildWaveform() {
    final c = ResonanceColors.of(context);
    return Container(
      width: double.infinity,
      height: 150,
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
            color: c.shadowColor,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Cahaya ambient di belakang gelombang
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, _) => Container(
                  width: 260,
                  height: 90 * _pulseAnim.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(60),
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.primaryColor.withValues(alpha: 0.14),
                        AppTheme.primaryColor.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(30, (index) {
                final mid = 29 / 2;
                final centerBias =
                    (1.0 - ((index - mid).abs() / mid)).clamp(0.35, 1.0);
                final isCenter = (index - mid).abs() < 3;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: isCenter ? 6 : 4.5,
                  height:
                      14 + (_waveHeights[index] * 90 * centerBias).clamp(6, 92),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        index == _currentPeakIndex
                            ? const Color(0xFFF59E0B)
                            : AppTheme.primaryColor,
                        AppTheme.secondaryColor,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// Batang tertinggi saat ini — diberi aksen amber agar terasa hidup.
  int get _currentPeakIndex {
    int peak = 0;
    for (int i = 1; i < _waveHeights.length; i++) {
      if (_waveHeights[i] > _waveHeights[peak]) peak = i;
    }
    return peak;
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
          Row(
            children: [
              Text(
                AppLocalizations.tr('emotion_score').toUpperCase(),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: AppTheme.textS(context),
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _rippleCtrl,
                builder: (context, _) => Opacity(
                  opacity: 0.4 + 0.6 * _rippleCtrl.value.abs(),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'LIVE',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...sorted.asMap().entries.map(
                (entry) => _buildScoreBarRow(
                  entry.value.key,
                  entry.value.value,
                  entry.key + 1,
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildScoreBarRow(EmotionType emotion, double score, int rank) {
    final isTop = rank == 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: Text(
              rank.toString().padLeft(2, '0'),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isTop ? emotion.color : AppTheme.textH(context),
              ),
            ),
          ),
          const SizedBox(width: 6),
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
                fontWeight: isTop ? FontWeight.w700 : FontWeight.w500,
                color: isTop ? emotion.color : AppTheme.textP(context),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: isTop ? 8 : 6,
                decoration: BoxDecoration(
                  color: AppTheme.surfVar(context),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: score,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          emotion.color,
                          emotion.color.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 38,
            child: Text(
              '${(score * 100).toStringAsFixed(0)}%',
              textAlign: TextAlign.right,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isTop ? emotion.color : AppTheme.textS(context),
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
    const bgColors = {
      EmotionType.happy:   Color(0xFFFEF9C3),
      EmotionType.sad:     Color(0xFFDBEAFE),
      EmotionType.angry:   Color(0xFFFEE2E2),
      EmotionType.disgust: Color(0xFFD1FAE5),
      EmotionType.neutral: Color(0xFFF1F5F9),
      EmotionType.fear:    Color(0xFFEDE9FE),
    };
    final bgColor = bgColors[e] ?? AppTheme.surfVar(context);
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          e.color.withValues(alpha: 0.06),
          AppTheme.surface(context),
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: e.color.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: ResonanceColors.of(context).shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutBack,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: anim, child: child),
        ),
        child: Column(
          key: ValueKey(e),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ConfidenceRing(
              progress: conf,
              size: 96,
              strokeWidth: 5,
              color: e.color,
              trackColor: AppTheme.surfVar(context),
              child: Container(
                width: 66,
                height: 66,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(33),
                  child: Image.asset(
                    e.assetIconPath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      e.icon,
                      size: 30,
                      color: e.color,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              e.displayName,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: e.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(conf * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: AppTheme.textS(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadarChart() {
    final scores = _currentScores;
    final dom = _currentEmotion ?? EmotionType.neutral;
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
          color: dom.color.withValues(alpha: 0.2),
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
            return RadarChartTitle(text: e.displayName);
          },
          dataSets: [
            RadarDataSet(
              fillColor: dom.color.withValues(alpha: 0.14),
              borderColor: dom.color,
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
    final isEn = AppLocalizations.locale.startsWith('en');
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 20,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: _stopRecording,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _rippleCtrl,
                builder: (context, child) {
                  return SizedBox(
                    width: 150,
                    height: 150,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Dua ripple ring bergantian — kesan "sonar".
                        for (final phase in [0.0, 0.5])
                          Builder(builder: (context) {
                            final t = (_rippleCtrl.value - phase) % 1.0;
                            final ringSize = 76 + (t * 66);
                            return Container(
                              width: ringSize,
                              height: ringSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFFF5252)
                                      .withValues(alpha: 0.45 * (1 - t)),
                                  width: 2,
                                ),
                              ),
                            );
                          }),
                        child!,
                      ],
                    ),
                  );
                },
                child: Container(
                  width: 76,
                  height: 76,
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
                    size: 38,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isEn
                    ? 'Tap to finish & see results'
                    : 'Ketuk untuk selesai & lihat hasil',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textS(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
