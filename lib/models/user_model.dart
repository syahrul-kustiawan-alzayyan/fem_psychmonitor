import '../l10n/app_localizations.dart';

// ==========================================
// MODEL: Data pengguna
// ==========================================
class AppUser {
  final int? id;
  final String name;
  final Map<String, double> bigFiveScores;
  final int? psychologicalScore;
  final DateTime createdAt;

  const AppUser({
    this.id,
    required this.name,
    this.bigFiveScores = const {},
    this.psychologicalScore,
    required this.createdAt,
  });

  AppUser copyWith({
    int? id,
    String? name,
    Map<String, double>? bigFiveScores,
    int? psychologicalScore,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      bigFiveScores: bigFiveScores ?? this.bigFiveScores,
      psychologicalScore: psychologicalScore ?? this.psychologicalScore,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get mentalHealthCategory {
    if (psychologicalScore == null) return 'Belum Dinilai';
    if (psychologicalScore! >= 76) return 'Sehat Optimal';
    if (psychologicalScore! >= 51) return 'Cukup';
    if (psychologicalScore! >= 26) return 'Rentan';
    return 'Butuh Perhatian Klinis';
  }

  String get mentalHealthDescription {
    if (psychologicalScore == null) {
      return 'Anda belum mengisi kuesioner kesehatan mental.';
    }
    if (psychologicalScore! >= 76) {
      return 'Kondisi kesehatan mental Anda sangat baik. Anda memiliki mekanisme koping yang tangguh, batasan personal yang sehat, dan mampu mengelola stres serta tuntutan sosial dengan sangat efektif. Tetap pertahankan gaya hidup sehat dan dukungan sosial Anda.';
    } else if (psychologicalScore! >= 51) {
      return 'Kesehatan mental Anda secara umum stabil, namun ada beberapa pemicu stres (seperti beban ganda atau fluktuasi hormonal) yang mulai memengaruhi rutinitas. Ini adalah fase wajar. Sangat disarankan untuk meningkatkan waktu istirahat dan self-care.';
    } else if (psychologicalScore! >= 26) {
      return 'Anda sedang menghadapi tantangan emosional yang signifikan. Terdapat gejala kelelahan mental (burnout), kecemasan, atau masalah citra diri yang mulai mengganggu fungsi harian. Mulailah berbicara dengan orang terpercaya atau pertimbangkan sesi konseling awal.';
    } else {
      return 'Skor ini mengindikasikan distres psikologis yang tinggi. Anda mungkin merasa kewalahan, putus asa, atau mengalami gejala psikosomatis yang mengganggu kesehatan fisik. Sangat disarankan untuk segera mencari bantuan profesional (psikolog klinis/psikiater) untuk mendapatkan intervensi yang tepat.';
    }
  }

  String get mentalHealthAdvice {
    if (psychologicalScore == null) {
      return 'Silakan isi kuesioner kesehatan mental untuk mendapatkan saran.';
    }
    if (psychologicalScore! >= 76) {
      return 'Pertahankan rutinitas sehat dan terus mendukung mereka yang membutuhkan.';
    } else if (psychologicalScore! >= 51) {
      return 'Tambahkan waktu istirahat dan aktivitas self-care ke dalam kegiatan sehari-hari Anda.';
    } else if (psychologicalScore! >= 26) {
      return 'Segera bicarakan dengan orang terpercaya atau konsultan profesional.';
    } else {
      return 'Segera cari bantuan profesional (psikolog klinis atau psikiater).';
    }
  }

  // ── Big Five helpers ──────────────────────────────────────
  bool get hasBigFive => bigFiveScores.isNotEmpty;

  String get bigFiveSummary {
    if (!hasBigFive) return '';
    final dims = {
      'O': 'Openness',
      'C': 'Conscientiousness',
      'E': 'Extraversion',
      'A': 'Agreeableness',
      'N': 'Neuroticism',
    };
    final parts = <String>[];
    for (final d in ['O', 'C', 'E', 'A', 'N']) {
      final score = bigFiveScores[d] ?? 0;
      final label = dims[d]!;
      final level = score >= 3.5 ? 'High' : (score <= 2.5 ? 'Low' : 'Moderate');
      parts.add('$label: $level ($score)');
    }
    return parts.join('\n');
  }

  String get bigFiveDescription {
    if (!hasBigFive) {
      return AppLocalizations.locale == 'en'
          ? 'Complete the Big Five assessment to discover your personality profile.'
          : 'Lengkapi asesmen Big Five untuk mengetahui profil kepribadian Anda.';
    }
    return AppLocalizations.locale == 'en'
        ? 'Your Big Five personality profile based on the Mini-IPIP assessment.'
        : 'Profil kepribadian Big Five Anda berdasarkan asesmen Mini-IPIP.';
  }

  List<String> get bigFiveStrengths {
    if (!hasBigFive) {
      return AppLocalizations.locale == 'en'
          ? ['Adaptive', 'Unique', 'Creative']
          : ['Adaptif', 'Unik', 'Kreatif'];
    }
    final strengths = <String>[];
    for (final d in ['O', 'C', 'E', 'A']) {
      if ((bigFiveScores[d] ?? 0) >= 3.5) {
        switch (d) {
          case 'O':
            strengths.add(AppLocalizations.locale == 'en' ? 'Creative & Curious' : 'Kreatif & Penasaran');
            break;
          case 'C':
            strengths.add(AppLocalizations.locale == 'en' ? 'Organized & Reliable' : 'Terorganisir & Andal');
            break;
          case 'E':
            strengths.add(AppLocalizations.locale == 'en' ? 'Energetic & Outgoing' : 'Energik & Sosial');
            break;
          case 'A':
            strengths.add(AppLocalizations.locale == 'en' ? 'Compassionate & Cooperative' : 'Penuh Kasih & Kooperatif');
            break;
        }
      }
    }
    if ((bigFiveScores['N'] ?? 0) < 2.5) {
      strengths.add(AppLocalizations.locale == 'en' ? 'Emotionally Stable' : 'Stabil Emosi');
    }
    if (strengths.isEmpty) {
      return AppLocalizations.locale == 'en'
          ? ['Adaptive', 'Unique', 'Creative']
          : ['Adaptif', 'Unik', 'Kreatif'];
    }
    return strengths;
  }
}

// ==========================================
// MODEL: Pertanyaan Big Five (Mini-IPIP)
// ==========================================
class BigFiveQuestion {
  final int questionId;
  final String question;
  final String dimension;
  final String dimensionName;
  final String keyed;

  const BigFiveQuestion({
    required this.questionId,
    required this.question,
    required this.dimension,
    required this.dimensionName,
    required this.keyed,
  });

  factory BigFiveQuestion.fromJson(Map<String, dynamic> json) {
    return BigFiveQuestion(
      questionId: json['id'],
      question: json['statement'],
      dimension: json['dimension'],
      dimensionName: json['dimension_name'],
      keyed: json['keyed'],
    );
  }
}

// ==========================================
// Helper: Hitung skor Big Five
// ==========================================
/// Hitung skor 5 dimensi Big Five dari daftar jawaban.
/// [answers] = list jawaban tiap pertanyaan (1-5).
/// [questions] = daftar BigFiveQuestion.
/// Returns `Map<String, double>` berisi rata-rata skor tiap dimensi.
Map<String, double> calculateBigFive(List<int> answers, List<BigFiveQuestion> questions) {
  final scores = <String, List<int>>{
    'O': [],
    'C': [],
    'E': [],
    'A': [],
    'N': [],
  };

  for (int i = 0; i < questions.length && i < answers.length; i++) {
    final q = questions[i];
    int rawScore = answers[i];
    // Reverse scoring for keyed '-'
    if (q.keyed == '-') {
      rawScore = 6 - rawScore; // 1↔5, 2↔4, 3↔3
    }
    scores[q.dimension]!.add(rawScore);
  }

  return scores.map((key, values) {
    if (values.isEmpty) return MapEntry(key, 0.0);
    final avg = values.reduce((a, b) => a + b) / values.length;
    return MapEntry(key, double.parse(avg.toStringAsFixed(2)));
  });
}

// ==========================================
// PsyQuestion
// ==========================================
class PsyQuestion {
  final int id;
  final String category;
  final String question;
  final List<PsyOption> options;

  const PsyQuestion({
    required this.id,
    required this.category,
    required this.question,
    required this.options,
  });

  factory PsyQuestion.fromJson(Map<String, dynamic> json) {
    return PsyQuestion(
      id: json['id'],
      category: json['category'],
      question: json['question'],
      options: (json['options'] as List).map((o) => PsyOption.fromJson(o)).toList(),
    );
  }
}

class PsyOption {
  final String answer;
  final int score;

  const PsyOption({required this.answer, required this.score});

  factory PsyOption.fromJson(Map<String, dynamic> json) {
    return PsyOption(
      answer: json['answer'],
      score: json['score'],
    );
  }
}
