import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../l10n/app_localizations.dart';
import '../models/emotion_model.dart';

class TextEmotionService {
  TextEmotionService._();
  static final instance = TextEmotionService._();

  Map<EmotionType, List<String>> _keywords = {};
  bool _loaded = false;
  String _loadedLocale = '';

  Future<void> loadAll() async {
    final currentLocale = AppLocalizations.currentLocale;
    // Reload if locale changed or not loaded yet.
    if (_loaded && _loadedLocale == currentLocale) return;
    _keywords = {};
    _loadedLocale = currentLocale;

    final file = currentLocale == 'en'
        ? 'assets/emotion_en.json'
        : 'assets/emotion.json';
    final jsonStr = await rootBundle.loadString(file);
    final Map<String, dynamic> data = json.decode(jsonStr);

    for (final entry in data.entries) {
      final emotion = _parseEmotion(entry.key);
      if (emotion == null) continue;
      final words = List<String>.from(entry.value);
      _keywords[emotion] = (_keywords[emotion] ?? [])..addAll(words);
    }

    _loaded = true;
  }

  EmotionType? _parseEmotion(String key) {
    switch (key) {
      case 'happy':   return EmotionType.happy;
      case 'sad':     return EmotionType.sad;
      case 'angry':   return EmotionType.angry;
      case 'disgust': return EmotionType.disgust;
      case 'neutral': return EmotionType.neutral;
      case 'fear':    return EmotionType.fear;
      default:        return null;
    }
  }

  Map<EmotionType, double> analyze(String text) {
    return analyzeDetailed(text).scores;
  }

  /// Analisis detail: skor + jumlah keyword mentah + flag prior.
  ///
  /// [hits] adalah jumlah keyword yang cocok (frasa multi-kata dihitung 2,
  /// sama seperti bobot skor). Transkrip kosong atau nol keyword memberi
  /// `hits = 0` dan `isPrior = true` sehingga confident-switch
  /// ([FusionGate]) tidak pernah fire untuk kasus ini.
  TextEmotionAnalysis analyzeDetailed(String text) {
    if (text.trim().isEmpty || !_loaded) {
      return const TextEmotionAnalysis(
        scores: {
          EmotionType.happy: 0.1,
          EmotionType.sad: 0.1,
          EmotionType.angry: 0.1,
          EmotionType.disgust: 0.1,
          EmotionType.neutral: 0.5,
          EmotionType.fear: 0.1,
        },
        hits: 0,
        isPrior: true,
      );
    }

    final lower = text.toLowerCase();
    final words = lower.split(RegExp(r'[\s,.!?;:()\-]+'));

    Map<EmotionType, double> scores = {};
    int totalMatches = 0;

    for (final entry in _keywords.entries) {
      final emotion = entry.key;
      final kws = entry.value;
      int count = 0;

      for (final kw in kws) {
        if (kw.contains(' ')) {
          if (lower.contains(kw)) {
            count += 2;
          }
        } else {
          count += words.where((w) => w == kw).length;
        }
      }

      scores[emotion] = count.toDouble();
      totalMatches += count;
    }

    if (totalMatches == 0) {
      return const TextEmotionAnalysis(
        scores: {
          EmotionType.happy: 0.1,
          EmotionType.sad: 0.1,
          EmotionType.angry: 0.1,
          EmotionType.disgust: 0.1,
          EmotionType.neutral: 0.5,
          EmotionType.fear: 0.1,
        },
        hits: 0,
        isPrior: true,
      );
    }

    for (final e in EmotionType.values) {
      scores[e] = (scores[e] ?? 0) / totalMatches;
    }

    return TextEmotionAnalysis(
        scores: scores, hits: totalMatches, isPrior: false);
  }
}

/// Hasil analisis emosi teks beserta metadata mentah untuk fusi.
class TextEmotionAnalysis {
  /// Distribusi 6 emosi (jumlah = 1.0).
  final Map<EmotionType, double> scores;

  /// Jumlah keyword mentah yang cocok (bobot frasa ikut dihitung).
  final int hits;

  /// True bila tidak ada sinyal teks (kosong / nol keyword / belum load)
  /// sehingga [scores] hanyalah prior default.
  final bool isPrior;

  const TextEmotionAnalysis({
    required this.scores,
    required this.hits,
    required this.isPrior,
  });
}
