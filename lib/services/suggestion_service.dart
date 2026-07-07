import 'dart:convert';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../models/emotion_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SuggestionService — Layanan saran dinamis berdasarkan Big Five OCEAN + Emosi
//
// Memuat data dari assets/saran_bigfive.json (atau saran_bigfive_en.json)
// dan menyediakan rekomendasi yang dipersonalisasi sesuai skor Big Five
// pengguna dan emosi yang terdeteksi.
// ─────────────────────────────────────────────────────────────────────────────
class SuggestionService {
  static final SuggestionService _instance = SuggestionService._internal();
  factory SuggestionService() => _instance;
  SuggestionService._internal();

  /// Cache data saran dari JSON
  Map<String, dynamic>? _recommendations;

  /// Locale terakhir
  String? _loadedLocale;

  bool get isLoaded => _recommendations != null;

  void reset() {
    _recommendations = null;
    _loadedLocale = null;
  }

  /// Muat data saran dari assets
  Future<void> load() async {
    final locale = AppLocalizations.locale;

    if (_recommendations != null && _loadedLocale == locale) return;

    _loadedLocale = locale;
    final fileName = locale.startsWith('en')
        ? 'assets/saran_bigfive_en.json'
        : 'assets/saran_bigfive.json';

    try {
      final jsonString = await rootBundle.loadString(fileName);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      _recommendations =
          Map<String, dynamic>.from(data['bigfive_recommendations']);
    } catch (e) {
      try {
        final jsonString = await rootBundle.loadString('assets/saran_bigfive.json');
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        _recommendations =
            Map<String, dynamic>.from(data['bigfive_recommendations']);
      } catch (e2) {
        _recommendations = {};
      }
    }
  }

  /// Dapatkan saran berdasarkan skor Big Five dan emosi.
  /// Menggabungkan saran dari 1-3 dimensi dengan skor tertinggi/terendah.
  List<String> getSuggestions(Map<String, double> bigFiveScores, EmotionType emotion) {
    if (_recommendations == null || _recommendations!.isEmpty) {
      return emotion.recordingSuggestions;
    }

    final emotionKey = _emotionToJsonKey(emotion);
    final allSuggestions = <String>{};

    // Ambil saran dari dimensi dengan skor ekstrem (high ≥ 3.5 atau low ≤ 2.5)
    // Prioritaskan dimensi yang paling menonjol (tertinggi atau terendah)
    final sortedByHigh = bigFiveScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedByLow = bigFiveScores.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final topHigh = sortedByHigh.where((e) => e.value >= 3.5).take(2);
    final topLow = sortedByLow.where((e) => e.value <= 2.5).take(2);

    for (final entry in topHigh) {
      final dim = entry.key;
      final dimData = _recommendations![dim] as Map<String, dynamic>?;
      if (dimData == null) continue;
      final levelData = dimData['high'] as Map<String, dynamic>?;
      if (levelData == null) continue;
      final suggestions = levelData[emotionKey] as List<dynamic>?;
      if (suggestions != null) {
        for (final s in suggestions) {
          allSuggestions.add(s.toString());
        }
      }
    }

    for (final entry in topLow) {
      final dim = entry.key;
      final dimData = _recommendations![dim] as Map<String, dynamic>?;
      if (dimData == null) continue;
      final levelData = dimData['low'] as Map<String, dynamic>?;
      if (levelData == null) continue;
      final suggestions = levelData[emotionKey] as List<dynamic>?;
      if (suggestions != null) {
        for (final s in suggestions) {
          allSuggestions.add(s.toString());
        }
      }
    }

    // Fallback: jika tidak ada dimensi ekstrem, ambil dari dimensi tertinggi
    if (allSuggestions.isEmpty && sortedByHigh.isNotEmpty) {
      final topDim = sortedByHigh.first.key;
      final level = sortedByHigh.first.value >= 3.0 ? 'high' : 'low';
      final dimData = _recommendations![topDim] as Map<String, dynamic>?;
      if (dimData != null) {
        final levelData = dimData[level] as Map<String, dynamic>?;
        if (levelData != null) {
          final suggestions = levelData[emotionKey] as List<dynamic>?;
          if (suggestions != null) {
            for (final s in suggestions) {
              allSuggestions.add(s.toString());
            }
          }
        }
      }
    }

    final result = allSuggestions.toList();
    if (result.isEmpty) {
      return emotion.recordingSuggestions;
    }
    // Batasi maksimal 5 saran
    return result.take(5).toList();
  }

  /// Dapatkan saran pertama
  String getFirstSuggestion(Map<String, double> bigFiveScores, EmotionType emotion) {
    final suggestions = getSuggestions(bigFiveScores, emotion);
    return suggestions.isNotEmpty ? suggestions.first : '';
  }

  /// Dapatkan dimensi dominan dari Big Five
  String getDominantDimension(Map<String, double> bigFiveScores) {
    if (bigFiveScores.isEmpty) return '';
    final sorted = bigFiveScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  /// Bangun judul saran dinamis
  String buildTitle(Map<String, double> bigFiveScores, EmotionType emotion) {
    final emotionName = emotion.displayName;
    final dominantDim = getDominantDimension(bigFiveScores);
    final locale = AppLocalizations.locale;

    if (bigFiveScores.isEmpty) {
      return locale.startsWith('en')
          ? 'Suggestions for $emotionName emotion'
          : 'Saran untuk Emosi $emotionName';
    }

    final dimNames = {
      'O': 'Openness', 'C': 'Conscientiousness',
      'E': 'Extraversion', 'A': 'Agreeableness', 'N': 'Neuroticism',
    };
    final dimLabel = dimNames[dominantDim] ?? dominantDim;

    return locale.startsWith('en')
        ? 'Suggestions $emotionName — $dimLabel'
        : 'Saran $emotionName — $dimLabel';
  }

  String _emotionToJsonKey(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.happy:   return 'Happy';
      case EmotionType.sad:     return 'Sad';
      case EmotionType.angry:   return 'Angry';
      case EmotionType.disgust: return 'Disgust';
      case EmotionType.neutral: return 'Neutral';
      case EmotionType.fear:    return 'Fear';
    }
  }
}
