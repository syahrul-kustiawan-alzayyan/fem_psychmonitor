import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/emotion_model.dart';

/// AudioEmotionDetector - Deteksi emosi dari audio secara real-time menggunakan TFLite
///
/// Fitur:
/// - Load model TFLite
/// - Proses audio samples menjadi fitur
/// - Deteksi emosi secara real-time
/// - Streaming results untuk live detection
class AudioEmotionDetector extends ChangeNotifier {
  static AudioEmotionDetector? _instance;

  Interpreter? _interpreter;
  bool _isModelLoaded = false;
  bool _isDetecting = false;

  // Hasil deteksi terbaru
  Map<EmotionType, double>? _currentScores;
  EmotionType? _currentDominantEmotion;
  double? _currentConfidence;

  // Stream untuk live detection
  final StreamController<DetectionResult> _detectionStream =
      StreamController<DetectionResult>.broadcast();
  Stream<DetectionResult> get detectionStream => _detectionStream.stream;

  // Sample rate dan konfigurasi audio
  static const int sampleRate = 16000; // 16kHz standard untuk speech
  static const int inputSize = 128; // Sesuaikan dengan model Anda

  // Buffer untuk audio frames
  List<double> _audioBuffer = [];

  AudioEmotionDetector._();

  static AudioEmotionDetector get instance {
    _instance ??= AudioEmotionDetector._();
    return _instance!;
  }

  // Getters
  bool get isModelLoaded => _isModelLoaded;
  bool get isDetecting => _isDetecting;
  Map<EmotionType, double>? get currentScores => _currentScores;
  EmotionType? get currentDominantEmotion => _currentDominantEmotion;
  double? get currentConfidence => _currentConfidence;

  /// Muat model TFLite
  Future<void> loadModel({
    String modelPath = 'lib/src/model_female.tflite',
  }) async {
    if (_isModelLoaded) return;

    try {
      debugPrint('🔄 Loading TFLite model: $modelPath');
      _interpreter = await Interpreter.fromAsset(modelPath);

      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;

      debugPrint('✅ Model loaded successfully!');
      debugPrint('   Input shape: $inputShape');
      debugPrint('   Output shape: $outputShape');

      _isModelLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to load model: $e');
      _isModelLoaded = false;
      rethrow;
    }
  }

  /// Tambahkan audio sample ke buffer
  void addAudioSamples(List<double> samples) {
    _audioBuffer.addAll(samples);

    // Jika buffer cukup besar, lakukan deteksi
    if (_audioBuffer.length >= inputSize && !_isDetecting) {
      _processAudio();
    }
  }

  /// Proses audio dan deteksi emosi
  Future<void> _processAudio() async {
    if (!_isModelLoaded || _interpreter == null) return;

    _isDetecting = true;

    try {
      // Ambil segment audio terbaru
      final segment = _audioBuffer.sublist(
        _audioBuffer.length - inputSize,
        _audioBuffer.length,
      );

      // Ekstrak fitur dari audio
      final features = extractAudioFeatures(segment);

      // Siapkan input untuk model
      final input = [features];

      // Dapatkan output shape
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      final outputLength = outputShape.reduce((a, b) => a * b);
      final output = List.filled(outputLength, 0.0);

      // Jalankan inferensi
      _interpreter!.run(input, [output]);

      // Parse hasil
      final scores = <EmotionType, double>{};
      final emotionLabels = EmotionType.values;

      for (int i = 0; i < emotionLabels.length && i < output.length; i++) {
        scores[emotionLabels[i]] = output[i].toDouble();
      }

      // Normalisasi skor agar total = 1.0
      final total = scores.values.fold<double>(0, (sum, val) => sum + val);
      if (total > 0) {
        scores.updateAll((key, value) => value / total);
      }

      // Dapatkan emosi dominan
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

      // Kirim ke stream
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
      debugPrint('❌ Error during audio processing: $e');
    } finally {
      _isDetecting = false;
    }
  }

  /// Ekstrak fitur audio untuk model
  ///
  /// Fitur yang umum digunakan untuk emosi suara:
  /// - Zero Crossing Rate
  /// - Energy/RMS
  /// - Spectral features
  /// - MFCC (jika model mendukung)
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
    // Bagi audio menjadi frame dan hitung fitur per frame
    final frameSize = audio.length ~/ 16;
    for (int i = 0; i < 16; i++) {
      final start = i * frameSize;
      final end = start + frameSize;
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

    // Pastikan jumlah fitur = inputSize
    while (features.length < inputSize) {
      features.add(0.0);
    }

    return features.sublist(0, inputSize);
  }

  /// Mulai deteksi real-time
  void startDetection() {
    _audioBuffer.clear();
    _currentScores = null;
    _currentDominantEmotion = null;
    _currentConfidence = null;
    notifyListeners();
  }

  /// Hentikan deteksi
  void stopDetection() {
    _audioBuffer.clear();
    notifyListeners();
  }

  /// Reset semua data
  void reset() {
    _audioBuffer.clear();
    _currentScores = null;
    _currentDominantEmotion = null;
    _currentConfidence = null;
    notifyListeners();
  }

  @override
  void dispose() {
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
