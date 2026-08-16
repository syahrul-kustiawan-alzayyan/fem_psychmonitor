import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../models/emotion_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model: Hasil saran terstruktur (multi-trait)
// ─────────────────────────────────────────────────────────────────────────────
class SuggestionResult {
  final EmotionType emotion;
  final List<TraitSuggestion> traitSuggestions;
  final bool isSafetyReferral;
  final String? safetyMessage;
  final List<String>? safetyActions;

  const SuggestionResult({
    required this.emotion,
    required this.traitSuggestions,
    this.isSafetyReferral = false,
    this.safetyMessage,
    this.safetyActions,
  });

  /// Semua saran flat (untuk backward compat)
  List<String> get allSuggestions =>
      traitSuggestions.expand((t) => t.suggestions).toList();

  /// Saran pertama
  String get firstSuggestion =>
      allSuggestions.isNotEmpty ? allSuggestions.first : '';

  bool get isEmpty => traitSuggestions.isEmpty && !isSafetyReferral;
}

class TraitSuggestion {
  final String trait;
  final String traitName;
  final String level;
  final List<String> suggestions;

  const TraitSuggestion({
    required this.trait,
    required this.traitName,
    required this.level,
    required this.suggestions,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// SuggestionService v2 — Big Five OCEAN + Emosi + Safety Layer
//
// Logika:
//   1. Cek lapisan keselamatan (krisis/distres berkepanjangan)
//   2. Hitung deviasi tiap trait dari titik tengah 3.0
//   3. Saring trait netral (2.80-3.20)
//   4. Ambil semua trait non-netral, urut berdasarkan deviasi
//   5. Ambil 2 saran per trait
// ─────────────────────────────────────────────────────────────────────────────
class SuggestionService {
  static final SuggestionService _instance = SuggestionService._internal();
  factory SuggestionService() => _instance;
  SuggestionService._internal();

  Map<String, dynamic>? _rawData;
  Map<String, dynamic>? _recommendations;
  Map<String, dynamic>? _safetyLayer;
  Map<String, dynamic>? _defaultNeutral;
  String? _loadedLocale;

  bool get isLoaded => _recommendations != null;

  void reset() {
    _rawData = null;
    _recommendations = null;
    _safetyLayer = null;
    _defaultNeutral = null;
    _loadedLocale = null;
  }

  /// Muat data saran v2 dari assets
  Future<void> load() async {
    final locale = AppLocalizations.locale;
    if (_rawData != null && _loadedLocale == locale) return;

    _loadedLocale = locale;
    final fileName = locale.startsWith('en')
        ? 'assets/saran_bigfive_v2_en.json'
        : 'assets/saran_bigfive_v2.json';

    try {
      final jsonString = await rootBundle.loadString(fileName);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      _rawData = data;
      _recommendations =
          Map<String, dynamic>.from(data['bigfive_recommendations'] ?? {});
      _safetyLayer = data['lapisan_keselamatan'] as Map<String, dynamic>?;
      _defaultNeutral = data['logika_penggabungan'] != null
          ? (data['logika_penggabungan'] as Map<String, dynamic>)['saran_default_netral'] as Map<String, dynamic>?
          : null;
    } catch (e) {
      // Fallback ke v1
      try {
        final fallbackName = locale.startsWith('en')
            ? 'assets/saran_bigfive_en.json'
            : 'assets/saran_bigfive.json';
        final jsonString = await rootBundle.loadString(fallbackName);
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        _rawData = data;
        _recommendations =
            Map<String, dynamic>.from(data['bigfive_recommendations'] ?? {});
        _safetyLayer = null;
        _defaultNeutral = null;
      } catch (e2) {
        _rawData = {};
        _recommendations = {};
        _safetyLayer = null;
        _defaultNeutral = null;
      }
    }
  }

  // ── Safety Layer ──────────────────────────────────────────────

  /// Get safety data regardless of emotion/scores (for psych card display)
  Future<SuggestionResult?> getSafetyData() async {
    await load();
    final safetyData = _safetyLayer?['jika_salah_satu_terpenuhi']
        as Map<String, dynamic>?;
    final output = safetyData?['output'] as Map<String, dynamic>?;
    if (output == null) return null;
    return SuggestionResult(
      emotion: EmotionType.neutral,
      traitSuggestions: [],
      isSafetyReferral: true,
      safetyMessage: output['pesan_validasi']?.toString(),
      safetyActions: (output['tindakan'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  // ── Core Logic v2 ────────────────────────────────────────────

  /// Dapatkan saran terstruktur (multi-trait) berdasarkan v2 logic
  SuggestionResult getStructuredSuggestions(
    Map<String, double> bigFiveScores,
    EmotionType emotion,
  ) {
    if (_recommendations == null || _recommendations!.isEmpty) {
      return SuggestionResult(
        emotion: emotion,
        traitSuggestions: [],
      );
    }

    // Langkah 2: Hitung deviasi dari titik tengah 3.0
    final deviations = <String, double>{};
    for (final entry in bigFiveScores.entries) {
      deviations[entry.key] = (entry.value - 3.0).abs();
    }

    // Langkah 3: Saring trait netral (2.80 - 3.20)
    final candidates = <String, double>{};
    for (final entry in bigFiveScores.entries) {
      final score = entry.value;
      if (score < 2.8 || score > 3.2) {
        candidates[entry.key] = deviations[entry.key] ?? 0;
      }
    }

    // Jika semua trait netral, gunakan saran default
    if (candidates.isEmpty) {
      final defaultSuggestions = _getDefaultNeutralSuggestions(emotion);
      return SuggestionResult(
        emotion: emotion,
        traitSuggestions: [
          TraitSuggestion(
            trait: '-',
            traitName: AppLocalizations.locale.startsWith('en')
                ? 'Balanced Profile'
                : 'Profil Seimbang',
            level: AppLocalizations.locale.startsWith('en')
                ? 'Neutral'
                : 'Netral',
            suggestions: defaultSuggestions,
          ),
        ],
      );
    }

    // Langkah 4: Urutkan berdasarkan deviasi, ambil semua non-netral
    final sorted = candidates.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Langkah 5 & 6: Tentukan level dan ambil saran
    final traitSuggestions = <TraitSuggestion>[];
    for (final entry in sorted) {
      final trait = entry.key;
      final score = bigFiveScores[trait] ?? 3.0;
      final level = score > 3.2 ? 'high' : 'low';
      final levelLabel = score > 3.2
          ? (AppLocalizations.locale.startsWith('en') ? 'High' : 'Tinggi')
          : (AppLocalizations.locale.startsWith('en') ? 'Low' : 'Rendah');

      final suggestions = _getSuggestionsForTrait(trait, level, emotion);
      if (suggestions.isNotEmpty) {
        traitSuggestions.add(TraitSuggestion(
          trait: trait,
          traitName: _getTraitName(trait),
          level: levelLabel,
          suggestions: (suggestions..shuffle(Random())).take(2).toList(),
        ));
      }
    }

    return SuggestionResult(
      emotion: emotion,
      traitSuggestions: traitSuggestions,
    );
  }

  /// Ambil saran dari basis data untuk satu trait
  List<String> _getSuggestionsForTrait(
      String trait, String level, EmotionType emotion) {
    final emotionKey = _emotionToJsonKey(emotion);
    final dimData = _recommendations?[trait] as Map<String, dynamic>?;
    if (dimData == null) return [];

    final levelData = dimData[level] as Map<String, dynamic>?;
    if (levelData == null) return [];

    final suggestions = levelData[emotionKey] as List<dynamic>?;
    if (suggestions == null) return [];

    return suggestions.map((e) => e.toString()).toList();
  }

  /// Ambil saran default netral (semua trait di zona netral)
  List<String> _getDefaultNeutralSuggestions(EmotionType emotion) {
    if (_defaultNeutral == null) return emotion.recordingSuggestions;

    final emotionKey = _emotionToJsonKey(emotion);
    final suggestions = _defaultNeutral![emotionKey] as List<dynamic>?;
    if (suggestions == null || suggestions.isEmpty) {
      return emotion.recordingSuggestions;
    }
    return suggestions.map((e) => e.toString()).toList();
  }

  // ── Backward Compatibility ────────────────────────────────────

  /// Flat list of suggestions (backward compat)
  List<String> getSuggestions(Map<String, double> bigFiveScores, EmotionType emotion) {
    final result = getStructuredSuggestions(bigFiveScores, emotion);
    if (result.isSafetyReferral) return result.safetyActions ?? [];
    return result.allSuggestions;
  }

  /// First suggestion only (backward compat)
  String getFirstSuggestion(Map<String, double> bigFiveScores, EmotionType emotion) {
    final result = getStructuredSuggestions(bigFiveScores, emotion);
    return result.firstSuggestion;
  }

  // ── Helpers ───────────────────────────────────────────────────

  String getDominantDimension(Map<String, double> bigFiveScores) {
    if (bigFiveScores.isEmpty) return '';
    final sorted = bigFiveScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  String buildTitle(Map<String, double> bigFiveScores, EmotionType emotion) {
    final emotionName = emotion.displayName;
    final locale = AppLocalizations.locale;

    if (bigFiveScores.isEmpty) {
      return locale.startsWith('en')
          ? 'A few suggestions for you who are currently feeling $emotionName'
          : 'Sedikit saran untukmu yang sedang memiliki emosi $emotionName';
    }

    final result = getStructuredSuggestions(bigFiveScores, emotion);
    if (result.isSafetyReferral) {
      return locale.startsWith('en')
          ? 'Safety Referral'
          : 'Rujukan Keselamatan';
    }

    return locale.startsWith('en')
        ? 'A few suggestions for you who are currently feeling $emotionName'
        : 'Sedikit saran untukmu yang sedang memiliki emosi $emotionName';
  }

  String _getTraitName(String trait) {
    const names = {
      'O': 'Openness',
      'C': 'Conscientiousness',
      'E': 'Extraversion',
      'A': 'Agreeableness',
      'N': 'Neuroticism',
    };
    return names[trait] ?? trait;
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
