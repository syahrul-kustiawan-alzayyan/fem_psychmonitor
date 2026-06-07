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

class GeminiService {
  GeminiService._();
  static final GeminiService _instance = GeminiService._();
  factory GeminiService() => _instance;

  static Map<EmotionType, double> combineResults(
    Map<EmotionType, double> audioScores,
    Map<EmotionType, double> textScores, {
    double audioWeight = 0.6,
    double textWeight = 0.4,
  }) {
    Map<EmotionType, double> combined = {};
    for (final e in EmotionType.values) {
      combined[e] = (audioScores[e] ?? 0) * audioWeight +
          (textScores[e] ?? 0) * textWeight;
    }
    return combined;
  }
}
