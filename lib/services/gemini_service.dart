import '../models/emotion_model.dart';

class GeminiResult {
  final String transcript;
  final EmotionType dominantEmotion;
  final double confidence;
  final Map<EmotionType, double> scores;

  GeminiResult({
    required this.transcript,
    required this.dominantEmotion,
    required this.confidence,
    required this.scores,
  });
}

/// Catatan: blend berbobot tetap (`combineResults` 0.6/0.4) sudah dihapus.
/// Fusi emosi memakai confident-switch tervalidasi di `fusion_gate.dart`.
class GeminiService {
  GeminiService._();
  static final GeminiService _instance = GeminiService._();
  factory GeminiService() => _instance;
}
