// Model data pengguna aplikasi Fem-PhysicsMonitor.
// Menyimpan username dan hasil skor assessment psikis awal.
import '../l10n/app_localizations.dart';

// ==========================================
// MODEL: Data pengguna
// ==========================================
class AppUser {
  final String name;           // Nama pengguna
  final int psychScore;        // Total skor assessment (10–40)
  final DateTime createdAt;    // Waktu registrasi

  const AppUser({
    required this.name,
    required this.psychScore,
    required this.createdAt,
  });

  /// Buat salinan dengan field yang diubah
  AppUser copyWith({String? name, int? psychScore, DateTime? createdAt}) {
    return AppUser(
      name: name ?? this.name,
      psychScore: psychScore ?? this.psychScore,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Level kesehatan psikis berdasarkan skor total
  PsychLevel get psychLevel {
    if (psychScore >= 35) return PsychLevel.excellent;
    if (psychScore >= 27) return PsychLevel.good;
    if (psychScore >= 20) return PsychLevel.fair;
    return PsychLevel.needsAttention;
  }
}

/// Level/kategori kesehatan psikis
enum PsychLevel { excellent, good, fair, needsAttention }

extension PsychLevelExtension on PsychLevel {
  String get label {
    switch (this) {
      case PsychLevel.excellent:      return AppLocalizations.tr('psych_excellent');
      case PsychLevel.good:           return AppLocalizations.tr('psych_good');
      case PsychLevel.fair:           return AppLocalizations.tr('psych_fair');
      case PsychLevel.needsAttention: return AppLocalizations.tr('psych_needs_attention');
    }
  }

  String get emoji {
    switch (this) {
      case PsychLevel.excellent:      return '🌟';
      case PsychLevel.good:           return '😊';
      case PsychLevel.fair:           return '😐';
      case PsychLevel.needsAttention: return '💙';
    }
  }

  /// Saran umum berdasarkan level psikis keseluruhan
  List<String> get overallSuggestions {
    switch (this) {
      case PsychLevel.excellent: return [
        AppLocalizations.tr('overall_exc_1'),
        AppLocalizations.tr('overall_exc_2'),
        AppLocalizations.tr('overall_exc_3'),
        AppLocalizations.tr('overall_exc_4'),
      ];
      case PsychLevel.good: return [
        AppLocalizations.tr('overall_good_1'),
        AppLocalizations.tr('overall_good_2'),
        AppLocalizations.tr('overall_good_3'),
        AppLocalizations.tr('overall_good_4'),
      ];
      case PsychLevel.fair: return [
        AppLocalizations.tr('overall_fair_1'),
        AppLocalizations.tr('overall_fair_2'),
        AppLocalizations.tr('overall_fair_3'),
        AppLocalizations.tr('overall_fair_4'),
        AppLocalizations.tr('overall_fair_5'),
      ];
      case PsychLevel.needsAttention: return [
        AppLocalizations.tr('overall_attn_1'),
        AppLocalizations.tr('overall_attn_2'),
        AppLocalizations.tr('overall_attn_3'),
        AppLocalizations.tr('overall_attn_4'),
        AppLocalizations.tr('overall_attn_5'),
      ];
    }
  }
}

// ==========================================
// MODEL: Satu pertanyaan assessment psikis
// ==========================================
class PsychQuestion {
  final String question;          // Teks pertanyaan
  final List<String> options;     // 4 pilihan jawaban
  final List<int> scores;         // Skor untuk tiap pilihan (1–4)
  final String category;          // Kategori (Stres, Tidur, Sosial, dll)

  const PsychQuestion({
    required this.question,
    required this.options,
    required this.scores,
    required this.category,
  });
}

// ==========================================
// 10 PERTANYAAN ASSESSMENT PSIKIS
// ==========================================
const List<PsychQuestion> onboardingQuestions = [
  PsychQuestion(
    category: '😴 Kualitas Tidur',
    question: 'Bagaimana kualitas tidurmu dalam seminggu terakhir?',
    options: [
      'Sangat buruk, sering terbangun',
      'Kurang nyenyak, sering mimpi buruk',
      'Cukup baik, terkadang kurang',
      'Sangat baik dan nyenyak',
    ],
    scores: [1, 2, 3, 4],
  ),
  PsychQuestion(
    category: '😰 Tingkat Stres',
    question: 'Seberapa sering kamu merasa tertekan atau overwhelmed?',
    options: [
      'Hampir setiap hari',
      'Beberapa kali seminggu',
      'Sesekali saja',
      'Jarang sekali',
    ],
    scores: [1, 2, 3, 4],
  ),
  PsychQuestion(
    category: '😊 Suasana Hati',
    question: 'Bagaimana suasana hatimu secara umum belakangan ini?',
    options: [
      'Sering sedih atau kosong',
      'Naik turun, tidak menentu',
      'Cukup stabil dan baik',
      'Sangat positif dan bersemangat',
    ],
    scores: [1, 2, 3, 4],
  ),
  PsychQuestion(
    category: '🤝 Hubungan Sosial',
    question: 'Bagaimana hubunganmu dengan orang-orang di sekitarmu?',
    options: [
      'Merasa terisolasi dan kesepian',
      'Sedikit koneksi, kurang nyaman',
      'Cukup baik dengan beberapa orang',
      'Sangat baik dan saling mendukung',
    ],
    scores: [1, 2, 3, 4],
  ),
  PsychQuestion(
    category: '⚡ Energi & Motivasi',
    question: 'Bagaimana tingkat energi dan motivasimu sehari-hari?',
    options: [
      'Sangat rendah, sulit beraktivitas',
      'Sering lesu dan kurang bersemangat',
      'Cukup bertenaga untuk aktivitas rutin',
      'Bersemangat dan antusias',
    ],
    scores: [1, 2, 3, 4],
  ),
  PsychQuestion(
    category: '🧠 Fokus & Konsentrasi',
    question: 'Seberapa baik kemampuan fokus dan konsentrasimu?',
    options: [
      'Sangat sulit berkonsentrasi',
      'Sering terdistraksi dan lupa',
      'Cukup fokus untuk tugas biasa',
      'Sangat fokus dan produktif',
    ],
    scores: [1, 2, 3, 4],
  ),
  PsychQuestion(
    category: '💪 Manajemen Emosi',
    question: 'Bagaimana kemampuanmu mengelola emosi saat ada masalah?',
    options: [
      'Sering meledak atau menarik diri',
      'Agak kesulitan, butuh waktu lama',
      'Cukup baik, bisa pulih dalam beberapa jam',
      'Sangat baik dan adaptif',
    ],
    scores: [1, 2, 3, 4],
  ),
  PsychQuestion(
    category: '🌱 Rasa Syukur',
    question: 'Seberapa sering kamu merasakan rasa syukur dalam hidupmu?',
    options: [
      'Hampir tidak pernah',
      'Kadang-kadang saja',
      'Cukup sering',
      'Hampir setiap hari',
    ],
    scores: [1, 2, 3, 4],
  ),
  PsychQuestion(
    category: '🏃 Aktivitas Fisik',
    question: 'Seberapa sering kamu berolahraga atau beraktivitas fisik?',
    options: [
      'Hampir tidak pernah',
      '1–2 kali sebulan',
      '1–2 kali seminggu',
      '3+ kali seminggu',
    ],
    scores: [1, 2, 3, 4],
  ),
  PsychQuestion(
    category: '🎯 Tujuan Hidup',
    question: 'Seberapa jelas kamu merasa memiliki tujuan dan arah dalam hidup?',
    options: [
      'Sama sekali tidak jelas',
      'Masih bingung dan mencari',
      'Cukup jelas meskipun belum sempurna',
      'Sangat jelas dan termotivasi',
    ],
    scores: [1, 2, 3, 4],
  ),
];
