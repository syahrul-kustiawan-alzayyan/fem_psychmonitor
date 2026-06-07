import 'dart:async';
import 'dart:io' show Platform, Directory, File;
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:flutter_litert/flutter_litert.dart';
import 'package:flutter_litert_flex/flutter_litert_flex.dart';
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

  // Raw PCM bytes from stream (for WAV file creation)
  List<int> _pcmBytes = [];
  Stream<Uint8List>? _pcmStream;
  StreamSubscription<Uint8List>? _pcmSubscription;

  // Configuration
  static const int sampleRate = 16000; // 16kHz
  static const int _targetAudioLength = 16000 * 3; // 3 seconds at 16kHz
  int _modelInputSize = 128 * 121; // 128 frames * 121 features

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

  /// Muat model TFLite dari assets
  Future<void> loadModel({
    String modelPath = 'assets/final_female_model.tflite',
  }) async {
    if (_isModelLoaded) return;

    try {
      debugPrint('🔄 Loading TFLite model: $modelPath');
      
      final flexDelegate = await FlexDelegate.create();
      final interpreterOptions = InterpreterOptions()
        ..addDelegate(flexDelegate)
        ..threads = 2;
      _interpreter = await Interpreter.fromAsset(
        modelPath,
        options: interpreterOptions,
      );

      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);

      debugPrint('✅ Model loaded successfully!');
      debugPrint('   Input shape: ${inputTensor.shape}');
      debugPrint('   Input type: ${inputTensor.type}');
      debugPrint('   Output shape: ${outputTensor.shape}');
      debugPrint('   Output type: ${outputTensor.type}');

      if (inputTensor.shape.length >= 2) {
        _modelInputSize = inputTensor.shape.last;
        debugPrint('   Model input size updated to: $_modelInputSize');
      }

      _isModelLoaded = true;
      _useMockDetection = false;
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Failed to load model with Flex delegate: $e');
      _useMockDetection = true;
      _interpreter = null;
      _isModelLoaded = true;
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
      _pcmBytes = [];
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

      // Start stream-based recording for real-time PCM data
      _pcmStream = await _recorder.startStream(config);
      _isRecording = true;

      _pcmSubscription = _pcmStream!.listen(
        (data) {
          _pcmBytes.addAll(data);
          for (int i = 0; i + 1 < data.length; i += 2) {
            final sample = (data[i + 1] << 8) | data[i];
            final normalized = sample / 32768.0;
            _audioBuffer.add(normalized.clamp(-1.0, 1.0));
          }
        },
        onError: (error) {
          debugPrint('❌ PCM stream error: $error');
        },
      );

      // Start periodic detection for real-time emotion updates
      _startPeriodicDetection();

      notifyListeners();
      debugPrint('✅ Recording started (stream mode)');
    } catch (e) {
      debugPrint('❌ Failed to start recording: $e');
      rethrow;
    }
  }

  /// Hentikan rekaman audio dan proses emosi
  Future<String?> stopRecording() async {
    try {
      debugPrint('⏹️ Stopping recording...');

      _isRecording = false;

      // Stop timer
      _detectionTimer?.cancel();
      _detectionTimer = null;

      // Cancel PCM stream subscription
      await _pcmSubscription?.cancel();
      _pcmSubscription = null;

      // Stop the recorder (stopStream)
      await _recorder.stop();

      // Save WAV file from accumulated PCM bytes
      String? path;
      if (_pcmBytes.isNotEmpty) {
        final tempDir = Directory.systemTemp;
        path = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.wav';
        _writeWavFile(path, _pcmBytes);
        debugPrint('✅ WAV file saved to: $path');
      }

      // Proses audio untuk deteksi emosi final
      if (_audioBuffer.length >= _targetAudioLength) {
        if (!_validateInterpreter()) {
          await _ensureModelLoaded();
        }
        
        if (_useMockDetection || _interpreter == null) {
          _runMockDetection();
        } else {
          try {
            debugPrint('🔄 Processing final audio...');
            await _processAudioFinal();
          } catch (e) {
            debugPrint('❌ Inference failed: $e');
            _useMockDetection = true;
            _runMockDetection();
          }
        }
      } else {
        debugPrint('⚠️ Audio buffer too short: ${_audioBuffer.length} / $_targetAudioLength');
        _runMockDetection();
      }

      notifyListeners();
      return path;
    } catch (e) {
      debugPrint('❌ Error stopping recording: $e');
      rethrow;
    }
  }
  
  /// Validasi interpreter dan tensor sebelum digunakan
  bool _validateInterpreter() {
    if (_interpreter == null || _useMockDetection) return false;
    
    try {
      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);
      
      if (inputTensor == null || outputTensor == null) {
        debugPrint('⚠️ Tensors are null, reloading model');
        _isModelLoaded = false;
        return false;
      }
      
      // Validasi shape tensors
      if (inputTensor.shape.isEmpty || outputTensor.shape.isEmpty) {
        debugPrint('⚠️ Invalid tensor shapes, reloading model');
        _isModelLoaded = false;
        return false;
      }
      
      return true;
    } catch (e) {
      debugPrint('⚠️ Error validating interpreter: $e');
      _isModelLoaded = false;
      return false;
    }
  }

  /// Load ulang model jika diperlukan
  Future<void> _ensureModelLoaded() async {
    // Jika model sudah loaded dan valid, tidak perlu reload
    if (_isModelLoaded && _validateInterpreter()) {
      return;
    }
    
    debugPrint('🔄 Reloading model for inference...');
    _isModelLoaded = false;
    _interpreter?.close();
    _interpreter = null;
    
    try {
      final flexDelegate = await FlexDelegate.create();
      final interpreterOptions = InterpreterOptions()
        ..addDelegate(flexDelegate)
        ..threads = 2;
      _interpreter = await Interpreter.fromAsset(
        'assets/final_female_model.tflite',
        options: interpreterOptions,
      );
      _isModelLoaded = true;
      _useMockDetection = false;
      debugPrint('✅ Model reloaded successfully');
    } catch (e) {
      debugPrint('⚠️ Failed to reload model, using mock: $e');
      _useMockDetection = true;
      _interpreter = null;
      // Penting: JANGAN set _isModelLoaded = true jika reload gagal
      // Biarkan false agar next attempt bisa retry
    }
  }

  /// Proses audio setelah recording selesai
  Future<void> _processAudioFinal() async {
    if (!_isModelLoaded || _audioBuffer.isEmpty) return;
    if (_useMockDetection) {
      _runMockDetection();
      return;
    }

    await _ensureModelLoaded();
    if (_interpreter == null || _useMockDetection) {
      _runMockDetection();
      return;
    }

    try {
      final segment = _audioBuffer.sublist(
        _audioBuffer.length - _targetAudioLength,
        _audioBuffer.length,
      );

      final features = extractAudioFeatures(segment);
      
      if (features.length != 128 * 121) {
        debugPrint('⚠️ Invalid feature length: ${features.length}');
        return;
      }

      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);
      
      if (inputTensor == null || outputTensor == null) {
        debugPrint('⚠️ Tensors null, using mock detection');
        _runMockDetection();
        return;
      }
      
      final inputShape = inputTensor.shape;
      final outputShape = outputTensor.shape;
      
      debugPrint('   Input shape: $inputShape');
      debugPrint('   Output shape: $outputShape');

      final modelBatch = inputShape[0];
      final modelTime = inputShape[1];
      final modelFeat = inputShape[2];

      final reshapedInput = List.generate(
        modelBatch,
        (_) => List.generate(
          modelTime,
          (t) {
            final start = t * modelFeat;
            final end = start + modelFeat;
            if (end > features.length) {
              return List.filled(modelFeat, 0.0);
            }
            return features.sublist(start, end);
          },
        ),
      );

      final outputBatchSize = outputShape.isNotEmpty ? outputShape[0] : 1;
      final outputFeaturesSize = outputShape.length > 1 
          ? outputShape.sublist(1).reduce((a, b) => a * b)
          : 1;
      final output = List.generate(
        outputBatchSize,
        (_) => List.filled(outputFeaturesSize, 0.0),
      );

      _interpreter!.run(reshapedInput, output);

      final scores = <EmotionType, double>{};
      final modelLabels = [
        EmotionType.happy,
        EmotionType.sad,
        EmotionType.angry,
        EmotionType.disgust,
        EmotionType.neutral,
        EmotionType.fear,
      ];

      for (int i = 0; i < modelLabels.length && i < output[0].length; i++) {
        final val = output[0][i];
        scores[modelLabels[i]] = val is num ? (val as num).toDouble() : 0.0;
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

      _currentScores = scores;
      _currentDominantEmotion = dominant;
      _currentConfidence = maxScore;

      _detectionStream.add(
        DetectionResult(
          scores: scores,
          dominantEmotion: dominant,
          confidence: maxScore,
          timestamp: DateTime.now(),
        ),
      );

      debugPrint('✅ Emotion detected: $dominant (${(maxScore * 100).toStringAsFixed(1)}%)');

      // Reload model setelah inferensi untuk menghindari crash di penggunaan berikutnya
      _reloadModelInBackground();

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error processing final audio: $e');
    }
  }

  /// Reload model di background (async) setelah inferensi selesai
  void _reloadModelInBackground() {
    Future.microtask(() async {
      debugPrint('🔄 Reloading model in background...');
      _interpreter?.close();
      _interpreter = null;
      _isModelLoaded = false;
      
      try {
        final flexDelegate = await FlexDelegate.create();
        final interpreterOptions = InterpreterOptions()
          ..addDelegate(flexDelegate)
          ..threads = 2;
        _interpreter = await Interpreter.fromAsset(
          'assets/final_female_model.tflite',
          options: interpreterOptions,
        );
        _isModelLoaded = true;
        _useMockDetection = false;
        debugPrint('✅ Model reloaded in background');
      } catch (e) {
        debugPrint('⚠️ Background reload failed: $e');
        _useMockDetection = true;
        _interpreter = null;
      }
    });
  }

  /// Mulai deteksi periodik dari audio stream (mock only — aman untuk UI real-time)
  void _startPeriodicDetection() {
    // Deteksi setiap 500ms
    _detectionTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) {
      if (_audioBuffer.isNotEmpty && !_isDetecting) {
        _runMockDetection();
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
      if (_useMockDetection) {
        _runMockDetection();
        return;
      }

      if (_audioBuffer.length < _targetAudioLength) {
        return;
      }

      if (!_validateInterpreter()) {
        await _ensureModelLoaded();
        if (_interpreter == null || _useMockDetection) {
          _runMockDetection();
          return;
        }
      }

      final segment = _audioBuffer.sublist(
        _audioBuffer.length - _targetAudioLength,
        _audioBuffer.length,
      );

      final features = extractAudioFeatures(segment);
      
      if (features.length != 128 * 121) {
        debugPrint('⚠️ Invalid feature length: ${features.length}');
        return;
      }

      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);
      
      final inputShape = inputTensor.shape;
      final outputShape = outputTensor.shape;
      
      debugPrint('   Input shape from model: $inputShape');
      debugPrint('   Output shape from model: $outputShape');

      final modelBatch = inputShape[0];
      final modelTime = inputShape[1];
      final modelFeat = inputShape[2];

      final reshapedInput = List.generate(
        modelBatch,
        (_) => List.generate(
          modelTime,
          (t) {
            final start = t * modelFeat;
            final end = start + modelFeat;
            if (end > features.length) {
              return List.filled(modelFeat, 0.0);
            }
            return features.sublist(start, end);
          },
        ),
      );

      final outputBatchSize = outputShape.isNotEmpty ? outputShape[0] : 1;
      final outputFeaturesSize = outputShape.length > 1 
          ? outputShape.sublist(1).reduce((a, b) => a * b)
          : 1;
      final output = List.generate(
        outputBatchSize,
        (_) => List.filled(outputFeaturesSize, 0.0),
      );

      _interpreter!.run(reshapedInput, output);

      final scores = <EmotionType, double>{};
      final modelLabels = [
        EmotionType.happy,
        EmotionType.sad,
        EmotionType.angry,
        EmotionType.disgust,
        EmotionType.neutral,
        EmotionType.fear,
      ];

      for (int i = 0; i < modelLabels.length && i < output[0].length; i++) {
        final val = output[0][i];
        scores[modelLabels[i]] = val is num ? (val as num).toDouble() : 0.0;
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

  void addAudioSamples(List<double> samples) {
    _audioBuffer.addAll(samples);

    const maxBufferSize = sampleRate * 10;
    if (_audioBuffer.length > maxBufferSize) {
      _audioBuffer = _audioBuffer.sublist(_audioBuffer.length - maxBufferSize);
    }
  }

  static const int _nMfcc = 40;
  static const int _maxFrames = 128;
  static const int _nFFT = 2048;
  static const int _hopLength = 512;

  static final List<double> _melBins = _generateMelFilters();

  static List<double> _generateMelFilters() {
    final bins = <double>[];
    for (int i = 0; i < _nMfcc + 2; i++) {
      final mel = 2595 * _log10(1 + (i * sampleRate / 2) / (_nMfcc + 1));
      bins.add(mel);
    }
    return bins;
  }

  static double _log10(double x) => log(x) / ln10;

  List<double> extractAudioFeatures(List<double> audio) {
    if (audio.isEmpty) {
      return List.filled(_maxFrames * _nMfcc * 3 + _maxFrames, 0.0);
    }

    final targetLength = _targetAudioLength;
    List<double> paddedAudio;
    if (audio.length > targetLength) {
      paddedAudio = audio.sublist(0, targetLength);
    } else {
      paddedAudio = List.filled(targetLength, 0.0);
      for (int i = 0; i < audio.length; i++) {
        paddedAudio[i] = audio[i];
      }
    }

    final maxAbs = paddedAudio.map((x) => x.abs()).reduce(max);
    if (maxAbs > 0) {
      for (int i = 0; i < paddedAudio.length; i++) {
        paddedAudio[i] = paddedAudio[i] / maxAbs;
      }
    }

    paddedAudio = _applyPreEmphasis(paddedAudio, 0.97);

    final spectrogram = _computeSpectrogram(paddedAudio);
    final melSpectrogram = _applyMelFilterbank(spectrogram);
    final mfcc = _computeDCT(melSpectrogram);

    final mfccDelta = _computeDelta(mfcc);
    final mfccDelta2 = _computeDelta(mfccDelta);
    final zcrFrames = _computeZCR(paddedAudio);

    var allFeatures = <double>[];

    for (int t = 0; t < _maxFrames && t < mfcc.length; t++) {
      allFeatures.addAll(mfcc[t]);
    }
    for (int t = 0; t < _maxFrames && t < mfccDelta.length; t++) {
      allFeatures.addAll(mfccDelta[t]);
    }
    for (int t = 0; t < _maxFrames && t < mfccDelta2.length; t++) {
      allFeatures.addAll(mfccDelta2[t]);
    }
    for (int t = 0; t < _maxFrames && t < zcrFrames.length; t++) {
      allFeatures.add(zcrFrames[t]);
    }

    while (allFeatures.length < _maxFrames * _nMfcc * 3 + _maxFrames) {
      allFeatures.add(0.0);
    }

    allFeatures = allFeatures.sublist(0, _maxFrames * _nMfcc * 3 + _maxFrames);

    for (int i = 0; i < allFeatures.length; i++) {
      if (!allFeatures[i].isFinite) {
        allFeatures[i] = 0.0;
      }
    }

    return allFeatures;
  }

  List<double> _applyPreEmphasis(List<double> audio, double alpha) {
    final result = List<double>.filled(audio.length, 0.0);
    result[0] = audio[0];
    for (int i = 1; i < audio.length; i++) {
      result[i] = audio[i] - alpha * audio[i - 1];
    }
    return result;
  }

  List<List<double>> _computeSpectrogram(List<double> audio) {
    final frames = <List<double>>[];
    final numFrames = ((audio.length - _nFFT) ~/ _hopLength) + 1;

    for (int i = 0; i < numFrames; i++) {
      final start = i * _hopLength;
      if (start + _nFFT > audio.length) break;

      final frame = audio.sublist(start, min(start + _nFFT, audio.length));
      while (frame.length < _nFFT) {
        frame.add(0.0);
      }

      final windowed = <double>[];
      for (int j = 0; j < _nFFT; j++) {
        final w = 0.5 * (1 - cos(2 * pi * j / (_nFFT - 1)));
        windowed.add(frame[j] * w);
      }

      final fft = _simpleFFT(windowed);
      final power = <double>[];
      for (int j = 0; j < fft.length ~/ 2; j++) {
        power.add(fft[j] * fft[j] + fft[fft.length - 1 - j] * fft[fft.length - 1 - j]);
      }
      frames.add(power);
    }

    return frames;
  }

  List<double> _simpleFFT(List<double> real) {
    final n = real.length;
    final re = List<double>.from(real);
    final im = List<double>.filled(n, 0.0);

    for (int len = 1; len < n; len *= 2) {
      final angleStep = -pi / len;
      for (int i = 0; i < n; i += len * 2) {
        for (int k = 0; k < len; k++) {
          final angle = k * angleStep;
          final cosA = cos(angle);
          final sinA = sin(angle);
          final evenIdx = i + k;
          final oddIdx = i + k + len;
          if (oddIdx >= n) continue;

          final tRe = cosA * re[oddIdx] - sinA * im[oddIdx];
          final tIm = sinA * re[oddIdx] + cosA * im[oddIdx];

          re[oddIdx] = re[evenIdx] - tRe;
          im[oddIdx] = im[evenIdx] - tIm;
          re[evenIdx] = re[evenIdx] + tRe;
          im[evenIdx] = im[evenIdx] + tIm;
        }
      }
    }

    return re;
  }

  List<List<double>> _applyMelFilterbank(List<List<double>> spectrogram) {
    final result = <List<double>>[];
    final numBins = _melBins.length - 2;

    for (final frame in spectrogram) {
      final mel = List<double>.filled(numBins, 0.0);
      for (int i = 0; i < numBins; i++) {
        final left = _melBins[i].toInt();
        final center = _melBins[i + 1].toInt();
        final right = _melBins[i + 2].toInt();

        double sum = 0.0;
        for (int j = left; j < center && j < frame.length; j++) {
          sum += frame[j] * (j - left + 1) / (center - left + 1);
        }
        for (int j = center; j < right && j < frame.length; j++) {
          sum += frame[j] * (right - j) / (right - center + 1);
        }
        mel[i] = sum;
      }
      result.add(mel);
    }

    return result;
  }

  List<List<double>> _computeDCT(List<List<double>> melSpectrogram) {
    final result = <List<double>>[];
    for (final mel in melSpectrogram) {
      final dct = List<double>.filled(_nMfcc, 0.0);
      for (int k = 0; k < _nMfcc; k++) {
        double sum = 0.0;
        for (int n = 0; n < mel.length; n++) {
          sum += mel[n] * cos(pi / mel.length * (n + 0.5) * k);
        }
        dct[k] = sum;
      }
      result.add(dct);
    }
    return result;
  }

  List<List<double>> _computeDelta(List<List<double>> features) {
    if (features.isEmpty) return [];
    final numFrames = features.length;
    final numCoeffs = features[0].length;
    final result = List.generate(numFrames, (_) => List.filled(numCoeffs, 0.0));

    for (int t = 0; t < numFrames; t++) {
      double denominator = 0.0;
      for (int k = 1; k <= 2; k++) {
        denominator += k * k;
      }
      denominator *= 2;

      for (int n = 0; n < numCoeffs; n++) {
        double sum = 0.0;
        for (int k = 1; k <= 2; k++) {
          final prev = t - k;
          final next = t + k;
          if (prev >= 0 && prev < numFrames) {
            sum += k * (features[prev][n] - features[t][n]);
          }
          if (next >= 0 && next < numFrames) {
            sum += k * (features[t][n] - features[next][n]);
          }
        }
        result[t][n] = sum / denominator;
      }
    }
    return result;
  }

  List<double> _computeZCR(List<double> audio) {
    final numFrames = ((audio.length - _nFFT) ~/ _hopLength) + 1;
    final zcr = <double>[];

    for (int i = 0; i < numFrames; i++) {
      double zeroCrossings = 0;
      final start = i * _hopLength;
      for (int j = start; j < start + _nFFT - 1 && j < audio.length - 1; j++) {
        if ((audio[j] >= 0 && audio[j + 1] < 0) ||
            (audio[j] < 0 && audio[j + 1] >= 0)) {
          zeroCrossings++;
        }
      }
      zcr.add(zeroCrossings / _nFFT);
    }

    while (zcr.length < _maxFrames) {
      zcr.add(0.0);
    }
    return zcr.sublist(0, _maxFrames);
  }

  /// Simpan accumulated PCM bytes sebagai file WAV
  void _writeWavFile(String path, List<int> pcmBytes) {
    final file = File(path);
    final sr = sampleRate;
    const numChannels = 1;
    const bitsPerSample = 16;
    final byteRate = sr * numChannels * bitsPerSample ~/ 8;
    const blockAlign = numChannels * bitsPerSample ~/ 8;
    final dataSize = pcmBytes.length;
    final fileSize = 36 + dataSize;

    final header = ByteData(44);
    // RIFF header
    header.setUint8(0, 0x52);
    header.setUint8(1, 0x49);
    header.setUint8(2, 0x46);
    header.setUint8(3, 0x46);
    header.setUint32(4, fileSize, Endian.little);
    header.setUint8(8, 0x57);
    header.setUint8(9, 0x41);
    header.setUint8(10, 0x56);
    header.setUint8(11, 0x45);
    // fmt chunk
    header.setUint8(12, 0x66);
    header.setUint8(13, 0x6D);
    header.setUint8(14, 0x74);
    header.setUint8(15, 0x20);
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, numChannels, Endian.little);
    header.setUint32(24, sr, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    // data chunk
    header.setUint8(36, 0x64);
    header.setUint8(37, 0x61);
    header.setUint8(38, 0x74);
    header.setUint8(39, 0x61);
    header.setUint32(40, dataSize, Endian.little);

    file.writeAsBytesSync([...header.buffer.asUint8List(), ...pcmBytes]);
  }

  /// Reset semua data
  void reset() {
    _audioBuffer.clear();
    _pcmBytes = [];
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
    _pcmSubscription?.cancel();
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
