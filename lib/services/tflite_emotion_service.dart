import 'package:flutter_litert/flutter_litert.dart';
import 'package:flutter_litert_flex/flutter_litert_flex.dart';
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
    String modelPath = 'assets/final_female_model.tflite',
  }) async {
    if (_isModelLoaded) return;

    try {
      print('🔄 Memuat model TFLite: $modelPath');
      
      final flexDelegate = await FlexDelegate.create();
      final interpreterOptions = InterpreterOptions()..addDelegate(flexDelegate);
      _interpreter = await Interpreter.fromAsset(
        modelPath,
        options: interpreterOptions,
      );

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
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;

      final timeSteps = 128;
      final nFeatures = 121;

      final reshapedInput = List.filled(
        1,
        List.filled(
          timeSteps,
          List.filled(nFeatures, 0.0),
        ),
      );
      for (int t = 0; t < timeSteps; t++) {
        for (int f = 0; f < nFeatures; f++) {
          reshapedInput[0][t][f] = audioFeatures[t * nFeatures + f];
        }
      }

      final outputLength = outputShape.reduce((a, b) => a * b);
      final output = List.filled(outputLength, 0.0);

      _interpreter!.run(reshapedInput.cast<List<double>>(), [output]);

      final probabilities = <EmotionType, double>{};
      for (int i = 0; i < _emotionLabels.length && i < output.length; i++) {
        probabilities[_emotionLabels[i]] = (output[i] as num).toDouble();
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
