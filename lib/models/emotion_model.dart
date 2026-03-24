import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ==========================================
// ENUM: Jenis-jenis emosi yang dapat dideteksi
// ==========================================
enum EmotionType { happy, sad, angry, disgust, neutral, fear }

/// Extension untuk mendapatkan properti tiap emosi
extension EmotionTypeExtension on EmotionType {
  /// Nama tampilan dalam Bahasa Indonesia/Inggris
  String get displayName {
    switch (this) {
      case EmotionType.happy:   return 'Happy';
      case EmotionType.sad:     return 'Sad';
      case EmotionType.angry:   return 'Angry';
      case EmotionType.disgust: return 'Disgust';
      case EmotionType.neutral: return 'Neutral';
      case EmotionType.fear:    return 'Fear';
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
    return AppTheme.emotionColors[displayName] ?? AppTheme.primaryColor;
  }

  /// Pesan psikologis singkat
  String get psychMessage {
    switch (this) {
      case EmotionType.happy:
        return 'Luar biasa! Suasana hatimu sangat positif hari ini. Pertahankan energi baikmu! 🌟';
      case EmotionType.sad:
        return 'Tidak apa-apa merasa sedih. Ambil napas dalam, kamu tidak sendirian. Kami ada untukmu. 💙';
      case EmotionType.angry:
        return 'Terdeteksi emosi kuat. Coba tarik napas perlahan selama 5 detik untuk menenangkan diri. 🌿';
      case EmotionType.disgust:
        return 'Kamu mungkin sedang tidak nyaman. Istirahat sebentar dan coba fokus pada hal positif. 🌈';
      case EmotionType.neutral:
        return 'Kondisimu stabil dan tenang hari ini. Tetap jaga keseimbanganmu! ⚖️';
      case EmotionType.fear:
        return 'Terdeteksi rasa cemas. Ingat, kamu lebih kuat dari ketakutanmu. Satu langkah kecil. 🤝';
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

  /// Daftar saran spesifik setelah rekaman emosi terdeteksi
  List<String> get recordingSuggestions {
    switch (this) {
      case EmotionType.happy:
        return [
          'Bagus sekali! Abadikan momen positif ini — tulis 3 hal yang membuatmu bahagia hari ini.',
          'Gunakan energi positifmu untuk menyelesaikan tugas yang sudah kamu tunda.',
          'Bagikan kebahagiaanmu kepada orang terdekat, kebaikan emosi itu menular! 🌟',
        ];
      case EmotionType.sad:
        return [
          'Tidak apa-apa untuk bersedih. Beri dirimu izin untuk merasakan emosi ini.',
          'Coba teknik 5-4-3-2-1: sebutkan 5 benda yang kamu lihat untuk kembali ke masa kini.',
          'Hubungi seseorang yang kamu percaya — berbagi cerita bisa sangat membantu.',
          'Lakukan aktivitas ringan yang kamu sukai: mendengarkan musik, membuat teh hangat.',
        ];
      case EmotionType.angry:
        return [
          'Hentikan sejenak. Tarik napas dalam 4 detik, tahan 4 detik, hembuskan 4 detik.',
          'Identifikasi sumber kemarahanmu — tuliskan apa yang terjadi tanpa menghakimi.',
          'Gerakkan tubuhmu: jalan santai 10 menit bisa meredakan ketegangan secara signifikan.',
          'Hindari pengambilan keputusan penting saat emosi sedang memuncak.',
        ];
      case EmotionType.disgust:
        return [
          'Rasa tidak nyaman ini valid. Coba identifikasi apa yang memicunya.',
          'Alihkan fokus dengan melihat atau menghirup sesuatu yang kamu sukai.',
          'Bersihkan area sekitarmu — lingkungan yang rapi bisa memperbaiki suasana hati.',
          'Tetapkan batasan yang sehat terhadap hal-hal yang membuatmu tidak nyaman.',
        ];
      case EmotionType.neutral:
        return [
          'Kondisimu stabil. Ini saat yang baik untuk merencanakan aktivitas produktif.',
          'Gunakan ketenangan ini untuk bermeditasi 5 menit — fokus pada pernapasanmu.',
          'Cek kembali tujuan harianmu dan apa yang sudah kamu capai.',
        ];
      case EmotionType.fear:
        return [
          'Ketakutan adalah sinyal, bukan musuh. Tanya dirimu: "Apa yang benar-benar aku takuti?"',
          'Coba teknik grounding: injak tanah dengan kaki, rasakan lantai di bawahmu.',
          'Pecah hal yang menakutimu menjadi langkah-langkah kecil yang bisa dilakukan.',
          'Ingat: kamu sudah melewati hari-hari sulit sebelumnya. Kamu lebih kuat dari yang kamu kira. 💪',
        ];
    }
  }

}

// ==========================================
// MODEL: Record/log satu deteksi emosi
// ==========================================
class EmotionRecord {
  final EmotionType emotion;      // Jenis emosi
  final double confidence;        // Tingkat kepercayaan (0.0 - 1.0)
  final DateTime timestamp;       // Waktu deteksi

  const EmotionRecord({
    required this.emotion,
    required this.confidence,
    required this.timestamp,
  });

  /// Format waktu singkat: "14 Mar, 09:30"
  String get formattedTime {
    final months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Ags','Sep','Okt','Nov','Des'];
    return '${timestamp.day} ${months[timestamp.month - 1]}, ${timestamp.hour.toString().padLeft(2,'0')}:${timestamp.minute.toString().padLeft(2,'0')}';
  }

  /// Confidence dalam persen: "87%"
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(0)}%';
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
