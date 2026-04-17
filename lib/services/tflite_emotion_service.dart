import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/emotion_model.dart';

/// TFLiteEmotionService - Layanan deteksi emosi menggunakan model TFLite
///
/// Model ini memproses fitur audio dan menghasilkan probabilitas untuk setiap emosi.
/// Input: Fitur audio (sesuai dengan model)
/// Output: Probabilitas untuk 6 emosi (happy, sad, angry, disgust, neutral, fear)
class TFLiteEmotionService {
  static TFLiteEmotionService? _instance;
  Interpreter? _interpreter;
  bool _isModelLoaded = false;

  // Label emosi sesuai dengan EmotionType
  static const List<EmotionType> _emotionLabels = [
    EmotionType.happy,
    EmotionType.sad,
    EmotionType.angry,
    EmotionType.disgust,
    EmotionType.neutral,
    EmotionType.fear,
  ];

  TFLiteEmotionService._();

  static TFLiteEmotionService get instance {
    _instance ??= TFLiteEmotionService._();
    return _instance!;
  }

  /// Apakah model sudah dimuat
  bool get isModelLoaded => _isModelLoaded;

  /// Muat model TFLite dari assets
  Future<void> loadModel({
    String modelPath = 'assets/model_female.tflite',
  }) async {
    if (_isModelLoaded) return;

    try {
      print('🔄 Memuat model TFLite: $modelPath');
      _interpreter = await Interpreter.fromAsset(modelPath);

      // Tampilkan info model
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;

      print('✅ Model berhasil dimuat!');
      print('   Input shape: $inputShape');
      print('   Output shape: $outputShape');

      _isModelLoaded = true;
    } catch (e) {
      print('❌ Gagal memuat model: $e');
      _isModelLoaded = false;
      rethrow;
    }
  }

  /// Deteksi emosi dari fitur audio
  ///
  /// [audioFeatures] - Array fitur audio yang akan diproses
  /// Returns Map berisi probabilitas setiap emosi
  Future<Map<EmotionType, double>> detectEmotionFromFeatures(
    List<double> audioFeatures,
  ) async {
    if (!_isModelLoaded || _interpreter == null) {
      throw Exception(
        'Model belum dimuat. Panggil loadModel() terlebih dahulu.',
      );
    }

    try {
      // Siapkan input tensor
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;

      // Reshape input sesuai dengan model
      // Asumsi: model menerima input 1D array
      final input = [audioFeatures];
      final output = List.filled(
        outputShape.reduce((a, b) => a * b),
        0.0,
      ).reshape(outputShape.sublist(1));

      // Jalankan inferensi
      _interpreter!.run(input, output);

      // Parse output menjadi map emotion -> probability
      final probabilities = <EmotionType, double>{};
      final outputList = output is List ? output : [output];

      for (int i = 0; i < _emotionLabels.length && i < outputList.length; i++) {
        probabilities[_emotionLabels[i]] = outputList[i].toDouble();
      }

      return probabilities;
    } catch (e) {
      print('❌ Error saat inferensi: $e');
      rethrow;
    }
  }

  /// Dapatkan emosi dominan dari hasil deteksi
  EmotionType getDominantEmotion(Map<EmotionType, double> probabilities) {
    EmotionType dominant = EmotionType.neutral;
    double maxProb = -1.0;

    for (final entry in probabilities.entries) {
      if (entry.value > maxProb) {
        maxProb = entry.value;
        dominant = entry.key;
      }
    }

    return dominant;
  }

  /// Release resources
  void dispose() {
    _interpreter?.close();
    _isModelLoaded = false;
  }
}
