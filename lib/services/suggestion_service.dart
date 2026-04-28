import 'dart:convert';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../models/emotion_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SuggestionService — Layanan saran dinamis berdasarkan MBTI + Emosi
//
// Memuat data dari assets/saran.json (atau saran_en.json) dan menyediakan rekomendasi
// yang dipersonalisasi sesuai tipe MBTI pengguna dan emosi terdeteksi.
// ─────────────────────────────────────────────────────────────────────────────
class SuggestionService {
  // Singleton
  static final SuggestionService _instance = SuggestionService._internal();
  factory SuggestionService() => _instance;
  SuggestionService._internal();

  /// Cache data saran yang sudah dimuat
  List<Map<String, dynamic>>? _recommendations;

  /// Locale terakhir yang digunakan untuk memuat data
  String? _loadedLocale;

  /// Apakah data sudah dimuat
  bool get isLoaded => _recommendations != null;

  /// Reset cache agar data dimuat ulang saat locale berubah
  void reset() {
    _recommendations = null;
    _loadedLocale = null;
  }

  /// Muat data saran dari assets/saran.json atau saran_en.json berdasarkan locale
  Future<void> load() async {
    final locale = AppLocalizations.locale;

    // Reload jika locale berubah atau belum dimuat
    if (_recommendations != null && _loadedLocale == locale) return;

    _loadedLocale = locale;
    final fileName = locale.startsWith('en') ? 'assets/saran_en.json' : 'assets/saran.json';

    try {
      final jsonString = await rootBundle.loadString(fileName);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      _recommendations =
          List<Map<String, dynamic>>.from(data['mbti_recommendations']);
    } catch (e) {
      // Fallback ke bahasa Indonesia jika gagal
      try {
        final jsonString = await rootBundle.loadString('assets/saran.json');
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        _recommendations =
            List<Map<String, dynamic>>.from(data['mbti_recommendations']);
      } catch (e2) {
        _recommendations = [];
      }
    }
  }

  /// Dapatkan daftar saran berdasarkan MBTI type dan EmotionType.
  /// Mengembalikan List<String> berisi 5 saran spesifik.
  /// Jika MBTI tidak ditemukan, gunakan fallback dari emotion model.
  List<String> getSuggestions(String mbtiType, EmotionType emotion) {
    if (_recommendations == null || _recommendations!.isEmpty) {
      return emotion.recordingSuggestions; // fallback
    }

    // Cari entri MBTI yang cocok
    final entry = _recommendations!.firstWhere(
      (item) =>
          (item['mbti_type'] as String).toUpperCase() ==
          mbtiType.toUpperCase(),
      orElse: () => <String, dynamic>{},
    );

    if (entry.isEmpty) {
      return emotion.recordingSuggestions; // fallback
    }

    // Map EmotionType ke key di JSON
    final emotionKey = _emotionToJsonKey(emotion);
    final emotions = entry['emotions'] as Map<String, dynamic>?;

    if (emotions == null || !emotions.containsKey(emotionKey)) {
      return emotion.recordingSuggestions; // fallback
    }

    return List<String>.from(emotions[emotionKey]);
  }

  /// Dapatkan saran pertama (untuk field suggestion di RecordingData)
  String getFirstSuggestion(String mbtiType, EmotionType emotion) {
    final suggestions = getSuggestions(mbtiType, emotion);
    return suggestions.isNotEmpty ? suggestions.first : '';
  }

  /// Dapatkan alias MBTI dari saran.json (e.g. "The Architect")
  String getMbtiAlias(String mbtiType) {
    if (_recommendations == null || _recommendations!.isEmpty) return '';

    final entry = _recommendations!.firstWhere(
      (item) =>
          (item['mbti_type'] as String).toUpperCase() ==
          mbtiType.toUpperCase(),
      orElse: () => <String, dynamic>{},
    );

    return entry.isNotEmpty ? (entry['alias'] as String? ?? '') : '';
  }

  /// Dapatkan grup MBTI dari saran.json (e.g. "Analyst", "Diplomat")
  String getMbtiGroup(String mbtiType) {
    if (_recommendations == null || _recommendations!.isEmpty) return '';

    final entry = _recommendations!.firstWhere(
      (item) =>
          (item['mbti_type'] as String).toUpperCase() ==
          mbtiType.toUpperCase(),
      orElse: () => <String, dynamic>{},
    );

    return entry.isNotEmpty ? (entry['group'] as String? ?? '') : '';
  }

  /// Buat judul saran dinamis berdasarkan emosi dan MBTI
  String buildTitle(String mbtiType, EmotionType emotion) {
    final alias = getMbtiAlias(mbtiType);
    final emotionName = emotion.displayName;
    final locale = AppLocalizations.locale;

    if (mbtiType.isEmpty || mbtiType == 'XXXX') {
      return locale.startsWith('en') 
          ? 'Suggestions for $emotionName emotion' 
          : 'Saran untuk Emosi $emotionName';
    }

    if (alias.isNotEmpty) {
      return locale.startsWith('en') 
          ? 'Suggestions $emotionName — $mbtiType ($alias)' 
          : 'Saran $emotionName — $mbtiType ($alias)';
    }

    return locale.startsWith('en') 
        ? 'Suggestions $emotionName — $mbtiType' 
        : 'Saran $emotionName — $mbtiType';
  }

  /// Map EmotionType enum ke key string di saran.json
  String _emotionToJsonKey(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.happy:
        return 'Happy';
      case EmotionType.sad:
        return 'Sad';
      case EmotionType.angry:
        return 'Angry';
      case EmotionType.disgust:
        return 'Disgust';
      case EmotionType.neutral:
        return 'Neutral';
      case EmotionType.fear:
        return 'Fear';
    }
  }
}