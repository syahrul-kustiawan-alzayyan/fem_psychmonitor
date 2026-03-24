// Model data pengguna aplikasi Fem-PhysicsMonitor.
// Menyimpan username dan hasil skor assessment psikis awal.

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
      case PsychLevel.excellent:      return 'Sangat Sehat';
      case PsychLevel.good:           return 'Baik';
      case PsychLevel.fair:           return 'Cukup';
      case PsychLevel.needsAttention: return 'Perlu Perhatian';
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
      case PsychLevel.excellent:
        return [
          'Pertahankan rutinitas positifmu! Kondisi psikismu sangat baik.',
          'Bagikan energi positifmu kepada orang-orang di sekitarmu.',
          'Lanjutkan aktivitas fisik & sosial yang sudah berjalan baik.',
          'Tetap jadwalkan waktu istirahat yang cukup setiap hari.',
        ];
      case PsychLevel.good:
        return [
          'Kondisimu baik! Pertahankan keseimbangan hidup sehari-hari.',
          'Luangkan 10 menit setiap hari untuk refleksi diri atau jurnal.',
          'Jaga kualitas tidur — tidur 7-8 jam membantu stabilitas emosi.',
          'Coba teknik pernapasan dalam saat mulai merasa stres.',
        ];
      case PsychLevel.fair:
        return [
          'Kondisimu cukup stabil. Sedikit upaya ekstra bisa membuat perbedaan besar.',
          'Mulai terapkan rutinitas harian yang konsisten: makan, tidur, olahraga.',
          'Ceritakan perasaanmu kepada orang yang kamu percaya.',
          'Pertimbangkan untuk mencoba meditasi atau journaling selama 5 menit/hari.',
          'Batasi paparan konten negatif di media sosial.',
        ];
      case PsychLevel.needsAttention:
        return [
          'Kondisimu memerlukan perhatian lebih. Kamu tidak sendirian! 💙',
          'Sangat disarankan untuk berbicara dengan konselor atau psikolog.',
          'Fokus pada kebutuhan dasar: makan teratur, tidur cukup, gerak ringan.',
          'Coba teknik grounding: sebutkan 5 hal yang kamu lihat, 4 yang bisa disentuh.',
          'Jangan ragu menghubungi layanan kesehatan jiwa jika merasa kewalahan.',
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
