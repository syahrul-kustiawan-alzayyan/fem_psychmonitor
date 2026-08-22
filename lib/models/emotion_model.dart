import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

// ==========================================
// ENUM: Tag pemicu emosi
// ==========================================
enum TriggerTag { work, romance, finance, health, family, social, other }

extension TriggerTagExtension on TriggerTag {
  String get displayName {
    switch (this) {
      case TriggerTag.work:    return AppLocalizations.tr('trigger_work');
      case TriggerTag.romance: return AppLocalizations.tr('trigger_romance');
      case TriggerTag.finance: return AppLocalizations.tr('trigger_finance');
      case TriggerTag.health:  return AppLocalizations.tr('trigger_health');
      case TriggerTag.family:  return AppLocalizations.tr('trigger_family');
      case TriggerTag.social:  return AppLocalizations.tr('trigger_social');
      case TriggerTag.other:   return AppLocalizations.tr('trigger_other');
    }
  }

  String get emoji {
    switch (this) {
      case TriggerTag.work:    return '\u{1F4BC}';
      case TriggerTag.romance: return '\u{1F494}';
      case TriggerTag.finance: return '\u{1F4B0}';
      case TriggerTag.health:  return '\u{1FA78}';
      case TriggerTag.family:  return '\u{1F468}\u200D\u{1F469}\u200D\u{1F467}\u200D\u{1F466}';
      case TriggerTag.social:  return '\u{1F465}';
      case TriggerTag.other:   return '\u{1F4CC}';
    }
  }
}

// ==========================================
// ENUM: Jenis-jenis emosi yang dapat dideteksi
// ==========================================
enum EmotionType { happy, sad, angry, disgust, neutral, fear }

/// Extension untuk mendapatkan properti tiap emosi
extension EmotionTypeExtension on EmotionType {
  /// Nama tampilan dalam Bahasa Indonesia/Inggris
  String get displayName {
    switch (this) {
      case EmotionType.happy:   return AppLocalizations.tr('emotion_happy');
      case EmotionType.sad:     return AppLocalizations.tr('emotion_sad');
      case EmotionType.angry:   return AppLocalizations.tr('emotion_angry');
      case EmotionType.disgust: return AppLocalizations.tr('emotion_disgust');
      case EmotionType.neutral: return AppLocalizations.tr('emotion_neutral');
      case EmotionType.fear:    return AppLocalizations.tr('emotion_fear');
    }
  }

  /// Emoji representatif
  String get emoji {
    switch (this) {
      case EmotionType.happy:   return '😊';
      case EmotionType.sad:     return '😢';
      case EmotionType.angry:   return '😠';
      case EmotionType.disgust: return '🤢';
      case EmotionType.neutral: return '😐';
      case EmotionType.fear:    return '😨';
    }
  }

  /// Path aset PNG dari folder assets/icon/emosi/
  String get assetIconPath {
    switch (this) {
      case EmotionType.happy:   return 'assets/icon/emosi/happy.png';
      case EmotionType.sad:     return 'assets/icon/emosi/sad.png';
      case EmotionType.angry:   return 'assets/icon/emosi/anger.png';
      case EmotionType.disgust: return 'assets/icon/emosi/disgust.png';
      case EmotionType.neutral: return 'assets/icon/emosi/neutral.png';
      case EmotionType.fear:    return 'assets/icon/emosi/fear.png';
    }
  }

  /// Ikon Material Icons
  IconData get icon {
    switch (this) {
      case EmotionType.happy:   return Icons.sentiment_very_satisfied_rounded;
      case EmotionType.sad:     return Icons.sentiment_very_dissatisfied_rounded;
      case EmotionType.angry:   return Icons.sentiment_dissatisfied_rounded;
      case EmotionType.disgust: return Icons.sick_rounded;
      case EmotionType.neutral: return Icons.sentiment_neutral_rounded;
      case EmotionType.fear:    return Icons.warning_amber_rounded;
    }
  }

  /// Warna representatif (dari AppTheme)
  Color get color {
    const lookup = {
      EmotionType.happy:   Color(0xFFFCD34D),
      EmotionType.sad:     Color(0xFF93C5FD),
      EmotionType.angry:   Color(0xFFFCA5A5),
      EmotionType.disgust: Color(0xFF6EE7B7),
      EmotionType.neutral: Color(0xFFCBD5E1),
      EmotionType.fear:    Color(0xFFC4B5FD),
    };
    return lookup[this] ?? AppTheme.primaryColor;
  }

  /// Pesan psikologis singkat
  String get psychMessage {
    switch (this) {
      case EmotionType.happy:   return AppLocalizations.tr('msg_happy');
      case EmotionType.sad:     return AppLocalizations.tr('msg_sad');
      case EmotionType.angry:   return AppLocalizations.tr('msg_angry');
      case EmotionType.disgust: return AppLocalizations.tr('msg_disgust');
      case EmotionType.neutral: return AppLocalizations.tr('msg_neutral');
      case EmotionType.fear:    return AppLocalizations.tr('msg_fear');
    }
  }

  /// Label kondisi psikis ringkasan
  String get psychStatus {
    switch (this) {
      case EmotionType.happy:   return 'Sangat Baik';
      case EmotionType.sad:     return 'Perlu Perhatian';
      case EmotionType.angry:   return 'Butuh Jeda';
      case EmotionType.disgust: return 'Kurang Nyaman';
      case EmotionType.neutral: return 'Stabil';
      case EmotionType.fear:    return 'Perlu Dukungan';
    }
  }

  /// Nilai numerik emosi untuk mempengaruhi skor kesehatan mental
  /// Positif = baik, Negatif = butuh perhatian
  int get emotionValue {
    switch (this) {
      case EmotionType.happy:   return 10;
      case EmotionType.neutral: return 0;
      case EmotionType.sad:     return -6;
      case EmotionType.angry:   return -8;
      case EmotionType.fear:    return -6;
      case EmotionType.disgust: return -4;
    }
  }

  /// Label singkat untuk nilai emosi
  String get valueLabel {
    final v = emotionValue;
    return v > 0 ? '+$v' : '$v';
  }

  /// Daftar saran spesifik setelah rekaman emosi terdeteksi
  List<String> get recordingSuggestions {
    switch (this) {
      case EmotionType.happy: return [
        AppLocalizations.tr('sugg_happy_1'),
        AppLocalizations.tr('sugg_happy_2'),
        AppLocalizations.tr('sugg_happy_3'),
      ];
      case EmotionType.sad: return [
        AppLocalizations.tr('sugg_sad_1'),
        AppLocalizations.tr('sugg_sad_2'),
        AppLocalizations.tr('sugg_sad_3'),
        AppLocalizations.tr('sugg_sad_4'),
      ];
      case EmotionType.angry: return [
        AppLocalizations.tr('sugg_angry_1'),
        AppLocalizations.tr('sugg_angry_2'),
        AppLocalizations.tr('sugg_angry_3'),
        AppLocalizations.tr('sugg_angry_4'),
      ];
      case EmotionType.disgust: return [
        AppLocalizations.tr('sugg_disgust_1'),
        AppLocalizations.tr('sugg_disgust_2'),
        AppLocalizations.tr('sugg_disgust_3'),
        AppLocalizations.tr('sugg_disgust_4'),
      ];
      case EmotionType.neutral: return [
        AppLocalizations.tr('sugg_neutral_1'),
        AppLocalizations.tr('sugg_neutral_2'),
        AppLocalizations.tr('sugg_neutral_3'),
      ];
      case EmotionType.fear: return [
        AppLocalizations.tr('sugg_fear_1'),
        AppLocalizations.tr('sugg_fear_2'),
        AppLocalizations.tr('sugg_fear_3'),
        AppLocalizations.tr('sugg_fear_4'),
      ];
    }
  }

}

// ==========================================
// FUNGSI: Penyesuaian skor kesehatan mental
// ==========================================

/// Penyesuaian skor kesehatan mental (0-100) dari distribusi emosi gabungan.
///
/// Aturan:
/// - Dominan netral -> 0. Distribusi bawaan servis teks memuat massa
///   probabilitas latar pada emosi negatif; tanpa gerbang ini rekaman
///   netral akan terus mengikis skor secara sistematis.
/// - Selain itu -> jumlah berbobot semua emosi, sehingga rekaman ambigu
///   otomatis dampaknya kecil.
double computeMentalHealthAdjustment(
  Map<EmotionType, double> scores, {
  required EmotionType dominant,
}) {
  if (dominant == EmotionType.neutral) return 0;
  return scores.entries
      .fold<double>(0, (sum, e) => sum + e.key.emotionValue * e.value);
}

// ==========================================
// MODEL: Record/log satu deteksi emosi
// ==========================================
class EmotionRecord {
  final EmotionType emotion;      // Jenis emosi
  final double confidence;        // Tingkat kepercayaan (0.0 - 1.0)
  final DateTime timestamp;       // Waktu deteksi
  final int? recordingId;         // ID recording di database (nullable untuk dummy)
  final String triggerTag;        // Tag pemicu (nama TriggerTag atau '' jika tidak ada)

  const EmotionRecord({
    required this.emotion,
    required this.confidence,
    required this.timestamp,
    this.recordingId,
    this.triggerTag = '',
  });

  /// Format waktu singkat: "14 Mar, 09:30"
  String get formattedTime {
    final months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Ags','Sep','Okt','Nov','Des'];
    return '${timestamp.day} ${months[timestamp.month - 1]}, ${timestamp.hour.toString().padLeft(2,'0')}:${timestamp.minute.toString().padLeft(2,'0')}';
  }

  /// Confidence dalam persen: "87%"
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(0)}%';

  /// Skor emosi berbobot: emotionValue × confidence
  /// Contoh: Happy 87% → 10 × 0.87 = +8.7
  double get emotionScore => emotion.emotionValue * confidence;

  /// Label skor emosi: "+4.4" atau "-2.1"
  String get emotionScoreLabel {
    final s = emotionScore;
    return s > 0 ? '+${s.toStringAsFixed(1)}' : s.toStringAsFixed(1);
  }
}

// ==========================================
// DUMMY DATA: Data palsu untuk preview UI
// ==========================================
class DummyData {
  /// Emosi terakhir yang terdeteksi (untuk dashboard)
  static final EmotionRecord latestEmotion = EmotionRecord(
    emotion: EmotionType.happy,
    confidence: 0.87,
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
  );

  /// Daftar riwayat emosi (untuk Home snippet & History screen)
  static final List<EmotionRecord> emotionHistory = [
    EmotionRecord(emotion: EmotionType.happy,   confidence: 0.87, timestamp: DateTime.now().subtract(const Duration(hours: 2))),
    EmotionRecord(emotion: EmotionType.neutral, confidence: 0.72, timestamp: DateTime.now().subtract(const Duration(hours: 5))),
    EmotionRecord(emotion: EmotionType.sad,     confidence: 0.65, timestamp: DateTime.now().subtract(const Duration(hours: 9))),
    EmotionRecord(emotion: EmotionType.fear,    confidence: 0.58, timestamp: DateTime.now().subtract(const Duration(days: 1))),
    EmotionRecord(emotion: EmotionType.angry,   confidence: 0.79, timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 4))),
    EmotionRecord(emotion: EmotionType.happy,   confidence: 0.91, timestamp: DateTime.now().subtract(const Duration(days: 2))),
    EmotionRecord(emotion: EmotionType.neutral, confidence: 0.68, timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 6))),
    EmotionRecord(emotion: EmotionType.disgust, confidence: 0.55, timestamp: DateTime.now().subtract(const Duration(days: 3))),
    EmotionRecord(emotion: EmotionType.sad,     confidence: 0.82, timestamp: DateTime.now().subtract(const Duration(days: 3, hours: 3))),
    EmotionRecord(emotion: EmotionType.happy,   confidence: 0.94, timestamp: DateTime.now().subtract(const Duration(days: 4))),
  ];

  /// Data chart: jumlah kemunculan tiap emosi dalam 7 hari
  static final Map<EmotionType, int> emotionFrequency = {
    EmotionType.happy:   4,
    EmotionType.neutral: 3,
    EmotionType.sad:     2,
    EmotionType.fear:    1,
    EmotionType.angry:   1,
    EmotionType.disgust: 1,
  };

  /// Hasil deteksi semua skor emosi (untuk Voice Detection screen)
  static final Map<EmotionType, double> detectionScores = {
    EmotionType.happy:   0.87,
    EmotionType.neutral: 0.06,
    EmotionType.sad:     0.04,
    EmotionType.fear:    0.02,
    EmotionType.angry:   0.01,
    EmotionType.disgust: 0.00,
  };
}
