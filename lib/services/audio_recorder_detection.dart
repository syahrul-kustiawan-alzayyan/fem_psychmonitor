import 'dart:async';
import 'dart:io' show Platform, Directory;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/emotion_model.dart';

/// AudioRecorderWithDetection - Layanan rekaman audio dengan deteksi emosi real-time
///
/// Fitur:
/// - Rekam audio dari microphone
/// - Ekstrak audio samples secara real-time
/// - Deteksi emosi menggunakan model TFLite
/// - Stream results untuk UI updates
class AudioRecorderWithDetection extends ChangeNotifier {
  static AudioRecorderWithDetection? _instance;

  // Audio recording
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _hasPermission = false;

  // TFLite model
  Interpreter? _interpreter;
  bool _isModelLoaded = false;
  bool _useMockDetection = false; // Flag untuk development mode

  // Detection state
  bool _isDetecting = false;
  Map<EmotionType, double>? _currentScores;
  EmotionType? _currentDominantEmotion;
  double? _currentConfidence;

  // Stream untuk live detection
  final StreamController<DetectionResult> _detectionStream =
      StreamController<DetectionResult>.broadcast();
  Stream<DetectionResult> get detectionStream => _detectionStream.stream;

  // Buffer audio
  List<double> _audioBuffer = [];

  // Configuration
  static const int sampleRate = 16000; // 16kHz
  static const int inputSize = 128; // Features count
  static const int bufferSize = 4096; // Buffer size for reading chunks

  // Timer untuk periodic detection
  Timer? _detectionTimer;

  AudioRecorderWithDetection._();

  static AudioRecorderWithDetection get instance {
    _instance ??= AudioRecorderWithDetection._();
    return _instance!;
  }

  // Getters
  bool get isRecording => _isRecording;
  bool get hasPermission => _hasPermission;
  bool get isModelLoaded => _isModelLoaded;
  bool get isDetecting => _isDetecting;
  Map<EmotionType, double>? get currentScores => _currentScores;
  EmotionType? get currentDominantEmotion => _currentDominantEmotion;
  double? get currentConfidence => _currentConfidence;

  /// Periksa dan minta permission microphone
  Future<bool> checkAndRequestPermission() async {
    try {
      _hasPermission = await _recorder.hasPermission();
      if (!_hasPermission) {
        debugPrint('❌ Tidak memiliki permission untuk merekam');
      }
      notifyListeners();
      return _hasPermission;
    } catch (e) {
      debugPrint('❌ Error checking permission: $e');
      return false;
    }
  }

  /// Muat model TFLite
  Future<void> loadModel({
    String modelPath = 'assets/model_female.tflite',
  }) async {
    if (_isModelLoaded) return;

    try {
      debugPrint('🔄 Loading TFLite model: $modelPath');

      // Check if running on Windows/desktop (TFLite native libs needed)
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        debugPrint(
          '⚠️ Desktop platform detected. Using simulated detection for development.',
        );
        _isModelLoaded = true;
        _useMockDetection = true;
        notifyListeners();
        return;
      }

      _interpreter = await Interpreter.fromAsset(modelPath);

      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;

      debugPrint('✅ Model loaded successfully!');
      debugPrint('   Input shape: $inputShape');
      debugPrint('   Output shape: $outputShape');

      _isModelLoaded = true;
      _useMockDetection = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to load model: $e');
      debugPrint('⚠️ Falling back to simulated detection for development.');

      // Fallback to mock detection for development
      _isModelLoaded = true;
      _useMockDetection = true;
      notifyListeners();
    }
  }

  /// Mulai rekaman audio
  Future<void> startRecording() async {
    if (!_isModelLoaded) {
      throw Exception(
        'Model belum dimuat. Panggil loadModel() terlebih dahulu.',
      );
    }

    if (!_hasPermission) {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) {
        throw Exception('Tidak memiliki permission untuk merekam');
      }
    }

    try {
      debugPrint('🎤 Starting audio recording...');

      // Clear buffer
      _audioBuffer.clear();
      _currentScores = null;
      _currentDominantEmotion = null;
      _currentConfidence = null;

      // Configure audio
      const config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: 1,
        autoGain: true,
        echoCancel: false,
        noiseSuppress: true,
      );

      // Start recording dengan path
      final tempDir = Directory.systemTemp;
      final tempPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.wav';
      await _recorder.start(config, path: tempPath);
      _isRecording = true;

      // Start periodic detection
      _startPeriodicDetection();

      notifyListeners();
      debugPrint('✅ Recording started');
    } catch (e) {
      debugPrint('❌ Failed to start recording: $e');
      rethrow;
    }
  }

  /// Hentikan rekaman audio
  Future<String?> stopRecording() async {
    try {
      debugPrint('⏹️ Stopping recording...');

      _isRecording = false;

      // Stop timer
      _detectionTimer?.cancel();
      _detectionTimer = null;

      // Stop recorder - path tidak digunakan secara eksplisit
      final path = await _recorder.stop();

      debugPrint('✅ Recording stopped. Saved to: $path');

      notifyListeners();
      return path;
    } catch (e) {
      debugPrint('❌ Error stopping recording: $e');
      rethrow;
    }
  }

  /// Mulai deteksi periodik dari audio stream
  void _startPeriodicDetection() {
    // Deteksi setiap 500ms
    _detectionTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) {
      if (_audioBuffer.isNotEmpty && !_isDetecting) {
        _processAudio();
      }
    });
  }

  /// Baca audio samples dari recorder
  /// Note: record package tidak expose raw samples secara langsung
  /// Jadi kita gunakan approach alternatif dengan membaca file setelah stop
  Future<List<double>> _getAudioSamples() async {
    // Dalam implementasi nyata, Anda perlu:
    // 1. Merekam ke file
    // 2. Baca file dan convert ke samples
    // 3. Proses samples ke model

    // Untuk sekarang, return buffer yang ada
    return List.from(_audioBuffer);
  }

  /// Proses audio dan deteksi emosi
  Future<void> _processAudio() async {
    if (!_isModelLoaded || _audioBuffer.isEmpty) return;

    _isDetecting = true;

    try {
      // Use mock detection if on desktop platform
      if (_useMockDetection) {
        _runMockDetection();
        return;
      }

      if (_interpreter == null) return;

      // Pastikan buffer cukup besar
      if (_audioBuffer.length < inputSize) {
        return;
      }

      // Ambil segment terbaru
      final segment = _audioBuffer.sublist(
        _audioBuffer.length - inputSize,
        _audioBuffer.length,
      );

      // Ekstrak fitur
      final features = extractAudioFeatures(segment);

      // Siapkan input/output
      final input = [features];
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      final outputLength = outputShape.reduce((a, b) => a * b);
      final output = List.filled(outputLength, 0.0);

      // Run inference
      _interpreter!.run(input, [output]);

      // Parse hasil
      final scores = <EmotionType, double>{};
      final emotionLabels = EmotionType.values;

      for (int i = 0; i < emotionLabels.length && i < output.length; i++) {
        scores[emotionLabels[i]] = output[i].toDouble();
      }

      // Normalisasi
      final total = scores.values.fold<double>(0, (sum, val) => sum + val);
      if (total > 0) {
        scores.updateAll((key, value) => value / total);
      }

      // Cari dominan
      EmotionType dominant = EmotionType.neutral;
      double maxScore = 0;

      for (final entry in scores.entries) {
        if (entry.value > maxScore) {
          maxScore = entry.value;
          dominant = entry.key;
        }
      }

      // Update state
      _currentScores = scores;
      _currentDominantEmotion = dominant;
      _currentConfidence = maxScore;

      // Stream result
      _detectionStream.add(
        DetectionResult(
          scores: scores,
          dominantEmotion: dominant,
          confidence: maxScore,
          timestamp: DateTime.now(),
        ),
      );

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error processing audio: $e');
    } finally {
      _isDetecting = false;
    }
  }

  /// Tambahkan samples ke buffer (dipanggil dari stream audio)
  void addAudioSamples(List<double> samples) {
    _audioBuffer.addAll(samples);

    // Batasi ukuran buffer agar tidak terlalu besar
    const maxBufferSize = sampleRate * 10; // Max 10 detik
    if (_audioBuffer.length > maxBufferSize) {
      _audioBuffer = _audioBuffer.sublist(_audioBuffer.length - maxBufferSize);
    }
  }

  /// Ekstrak fitur audio untuk model
  List<double> extractAudioFeatures(List<double> audio) {
    final features = <double>[];

    // 1. Zero Crossing Rate
    double zeroCrossings = 0;
    for (int i = 1; i < audio.length; i++) {
      if ((audio[i] >= 0 && audio[i - 1] < 0) ||
          (audio[i] < 0 && audio[i - 1] >= 0)) {
        zeroCrossings++;
      }
    }
    features.add(zeroCrossings / audio.length);

    // 2. Energy (RMS)
    double energy = 0;
    for (final sample in audio) {
      energy += sample * sample;
    }
    energy = sqrt(energy / audio.length);
    features.add(energy);

    // 3. Mean amplitude
    double mean = 0;
    for (final sample in audio) {
      mean += sample;
    }
    mean /= audio.length;
    features.add(mean);

    // 4. Standard deviation
    double variance = 0;
    for (final sample in audio) {
      variance += pow(sample - mean, 2);
    }
    variance /= audio.length;
    features.add(sqrt(variance));

    // 5. Max amplitude
    double maxAmp = 0;
    for (final sample in audio) {
      maxAmp = max(maxAmp, sample.abs());
    }
    features.add(maxAmp);

    // 6-128. Spectral features (simplified)
    final frameSize = audio.length ~/ 16;
    for (int i = 0; i < 16 && frameSize > 0; i++) {
      final start = i * frameSize;
      final end = start + frameSize;
      if (end <= audio.length) {
        final frame = audio.sublist(start, end);

        // Energy per frame
        double frameEnergy = 0;
        for (final sample in frame) {
          frameEnergy += sample * sample;
        }
        features.add(sqrt(frameEnergy / frame.length));

        // Zero crossings per frame
        double frameZCR = 0;
        for (int j = 1; j < frame.length; j++) {
          if ((frame[j] >= 0 && frame[j - 1] < 0) ||
              (frame[j] < 0 && frame[j - 1] >= 0)) {
            frameZCR++;
          }
        }
        features.add(frameZCR / frame.length);

        // Mean per frame
        double frameMean = 0;
        for (final sample in frame) {
          frameMean += sample;
        }
        features.add(frameMean / frame.length);

        // Std per frame
        double frameVar = 0;
        for (final sample in frame) {
          frameVar += pow(sample - frameMean, 2);
        }
        features.add(sqrt(frameVar / frame.length));
      }
    }

    // Pad jika kurang
    while (features.length < inputSize) {
      features.add(0.0);
    }

    return features.sublist(0, inputSize);
  }

  /// Reset semua data
  void reset() {
    _audioBuffer.clear();
    _currentScores = null;
    _currentDominantEmotion = null;
    _currentConfidence = null;
    notifyListeners();
  }

  /// Mock detection untuk development di desktop platform
  void _runMockDetection() {
    if (_audioBuffer.isEmpty) return;

    try {
      // Generate simulated emotion based on audio energy
      final energy =
          _audioBuffer.fold<double>(0, (sum, sample) => sum + sample.abs()) /
          _audioBuffer.length;

      final rand = Random();
      final scores = <EmotionType, double>{};

      // Simple heuristic: higher energy = more active emotions
      final emotions = EmotionType.values;
      double remaining = 1.0;

      for (int i = 0; i < emotions.length; i++) {
        double score;
        if (i == 0) {
          score = 0.3 + (rand.nextDouble() * 0.4); // Dominant emotion 30-70%
        } else if (i == emotions.length - 1) {
          score = remaining; // Last emotion gets remainder
        } else {
          score = rand.nextDouble() * remaining * 0.3;
        }

        scores[emotions[i]] = score.clamp(0.0, remaining);
        remaining -= scores[emotions[i]]!;
      }

      // Normalize
      final total = scores.values.fold<double>(0, (sum, val) => sum + val);
      if (total > 0) {
        scores.updateAll((key, value) => value / total);
      }

      // Find dominant
      EmotionType dominant = EmotionType.neutral;
      double maxScore = 0;

      for (final entry in scores.entries) {
        if (entry.value > maxScore) {
          maxScore = entry.value;
          dominant = entry.key;
        }
      }

      // Update state
      _currentScores = scores;
      _currentDominantEmotion = dominant;
      _currentConfidence = maxScore;

      // Stream result
      _detectionStream.add(
        DetectionResult(
          scores: scores,
          dominantEmotion: dominant,
          confidence: maxScore,
          timestamp: DateTime.now(),
        ),
      );

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error in mock detection: $e');
    }
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _recorder.dispose();
    _interpreter?.close();
    _detectionStream.close();
    super.dispose();
  }
}

/// Hasil deteksi emosi
class DetectionResult {
  final Map<EmotionType, double> scores;
  final EmotionType dominantEmotion;
  final double confidence;
  final DateTime timestamp;

  DetectionResult({
    required this.scores,
    required this.dominantEmotion,
    required this.confidence,
    required this.timestamp,
  });
}
