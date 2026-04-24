// Model data pengguna aplikasi Fem-PhysicsMonitor.
// Menyimpan username, hasil MBTI assessment, dan skor kesehatan mental.
import '../l10n/app_localizations.dart';

// ==========================================
// MODEL: Data pengguna
// ==========================================
class AppUser {
  final int? id; // ID pengguna di SQLite
  final String name; // Nama pengguna
  final String mbtiType; // Tipe MBTI: "INFJ", "ESTP", dll
  final Map<String, int> mbtiScores; // Skor per dimensi: {'E':3, 'I':2, ...}
  final int? psychologicalScore; // Skor kuesioner kesehatan mental (0-30)
  final DateTime createdAt; // Waktu registrasi

  const AppUser({
    this.id,
    required this.name,
    required this.mbtiType,
    required this.mbtiScores,
    this.psychologicalScore,
    required this.createdAt,
  });

  /// Buat salinan dengan field yang diubah
  AppUser copyWith({
    int? id,
    String? name,
    String? mbtiType,
    Map<String, int>? mbtiScores,
    int? psychologicalScore,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      mbtiType: mbtiType ?? this.mbtiType,
      mbtiScores: mbtiScores ?? this.mbtiScores,
      psychologicalScore: psychologicalScore ?? this.psychologicalScore,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Kategori kondisi mental berdasarkan skor
  String get mentalHealthCategory {
    if (psychologicalScore == null) return 'Belum Dinilai';
    if (psychologicalScore! <= 15) return 'Sehat Optimal';
    if (psychologicalScore! <= 30) return 'Cukup Sehat';
    if (psychologicalScore! <= 45) return 'Rentan';
    return 'Butuh Perhatian Klinis';
  }

  /// Deskripsi kondisi mental
  String get mentalHealthDescription {
    if (psychologicalScore == null) {
      return 'Anda belum mengisi kuesioner kesehatan mental.';
    }
    if (psychologicalScore! <= 15) {
      return 'Kondisi kesehatan mental Anda sangat baik. Anda memiliki mekanisme koping yang tangguh, batasan personal yang sehat, dan mampu mengelola stres serta tuntutan sosial dengan sangat efektif. Tetap pertahankan gaya hidup sehat dan dukungan sosial Anda.';
    } else if (psychologicalScore! <= 30) {
      return 'Kesehatan mental Anda secara umum stabil, namun ada beberapa pemicu stres (seperti beban ganda atau fluktuasi hormonal) yang mulai memengaruhi rutinitas. Ini adalah fase wajar. Sangat disarankan untuk meningkatkan waktu istirahat dan self-care.';
    } else if (psychologicalScore! <= 45) {
      return 'Anda sedang menghadapi tantangan emosional yang signifikan. Terdapat gejala kelelahan mental (burnout), kecemasan, atau masalah citra diri yang mulai mengganggu fungsi harian. Mulailah berbicara dengan orang terpercaya atau pertimbangkan sesi konseling awal.';
    } else {
      return 'Skor ini mengindikasikan distres psikologis yang tinggi. Anda mungkin merasa kewalahan, putus asa, atau mengalami gejala psikosomatis yang mengganggu kesehatan fisik. Sangat disarankan untuk segera mencari bantuan profesional (psikolog klinis/psikiater) untuk mendapatkan intervensi yang tepat.';
    }
  }

  /// Saran berdasarkan skor mental
  String get mentalHealthAdvice {
    if (psychologicalScore == null) {
      return 'Silakan isi kuesioner kesehatan mental untuk mendapatkan saran.';
    }
    if (psychologicalScore! <= 15) {
      return 'Pertahankan rutinitas sehat dan terus mendukung mereka yang membutuhkan.';
    } else if (psychologicalScore! <= 30) {
      return 'Tambahkan waktu istirahat dan aktivitas self-care ke dalam kegiatan sehari-hari Anda.';
    } else if (psychologicalScore! <= 45) {
      return 'Segera bicarakan dengan orang terpercaya atau konsultan profesional.';
    } else {
      return 'Segera cari bantuan profesional (psikolog klinis atau psikiater).';
    }
  }

  /// Deskripsi singkat tipe MBTI
  String get mbtiDescription {
    return _mbtiDescriptions[mbtiType] ?? 'Tipe kepribadian unik Anda.';
  }

  /// Nama julukan tipe MBTI
  String get mbtiNickname {
    return _mbtiNicknames[mbtiType] ?? 'The Unique One';
  }

  /// Kekuatan utama berdasarkan MBTI
  List<String> get mbtiStrengths {
    return _mbtiStrengths[mbtiType] ?? ['Adaptif', 'Unik', 'Kreatif'];
  }
}

// ==========================================
// MBTI Type Descriptions
// ==========================================
const Map<String, String> _mbtiNicknames = {
  'INTJ': 'The Architect',
  'INTP': 'The Logician',
  'ENTJ': 'The Commander',
  'ENTP': 'The Debater',
  'INFJ': 'The Advocate',
  'INFP': 'The Mediator',
  'ENFJ': 'The Protagonist',
  'ENFP': 'The Campaigner',
  'ISTJ': 'The Logistician',
  'ISFJ': 'The Defender',
  'ESTJ': 'The Executive',
  'ESFJ': 'The Consul',
  'ISTP': 'The Virtuoso',
  'ISFP': 'The Adventurer',
  'ESTP': 'The Entrepreneur',
  'ESFP': 'The Entertainer',
};

const Map<String, String> _mbtiDescriptions = {
  'INTJ':
      'Pemikir strategis dengan visi jangka panjang. Mandiri, analitis, dan selalu mencari cara untuk meningkatkan sistem.',
  'INTP':
      'Pemikir kreatif yang haus pengetahuan. Inovatif, logis, dan selalu ingin memahami bagaimana hal-hal bekerja.',
  'ENTJ':
      'Pemimpin alami yang tegas dan efisien. Berorientasi pada tujuan dengan kemampuan organisasi yang luar biasa.',
  'ENTP':
      'Inovator yang cerdas dan antusias. Senang tantangan intelektual dan selalu mencari ide baru.',
  'INFJ':
      'Idealis yang penuh empati dan visioner. Menginspirasi orang lain dengan insight mendalam dan compassion.',
  'INFP':
      'Idealis kreatif dengan nilai-nilai kuat. Sangat empatik dan selalu berusaha untuk membuat dunia lebih baik.',
  'ENFJ':
      'Pemimpin karismatik yang menginspirasi. Sangat peduli terhadap orang lain dan kemajuan bersama.',
  'ENFP':
      'Penjelajah antusias yang penuh semangat. Kreatif, hangat, dan selalu melihat potensi di setiap orang.',
  'ISTJ':
      'Individu yang bertanggung jawab dan dapat diandalkan. Praktis, terorganisir, dan setia pada komitmen.',
  'ISFJ':
      'Pelindung yang hangat dan perhatian. Setia, teliti, dan selalu berusaha membantu orang lain.',
  'ESTJ':
      'Pengelola yang efisien dan tegas. Berpegang teguh pada aturan dan standar yang tinggi.',
  'ESFJ':
      'Individu yang hangat dan peduli. Sangat memperhatikan kebutuhan orang lain dan menjaga harmoni.',
  'ISTP':
      'Pengrajin yang praktis dan adaptif. Senang memahami cara kerja hal-hal dan memecahkan masalah langsung.',
  'ISFP':
      'Seniman yang lembut dan sensitif. Menghargai keindahan dan hidup sesuai nilai-nilai personal.',
  'ESTP':
      'Petualang yang energik dan pragmatis. Hidup di momen sekarang dengan keberanian dan spontanitas.',
  'ESFP':
      'Penghibur yang spontan dan energik. Membawa kegembiraan ke mana pun mereka pergi.',
};

const Map<String, List<String>> _mbtiStrengths = {
  'INTJ': ['Strategis', 'Mandiri', 'Visioner', 'Analitis'],
  'INTP': ['Inovatif', 'Logis', 'Objektif', 'Kreatif'],
  'ENTJ': ['Kepemimpinan', 'Efisien', 'Tegas', 'Strategis'],
  'ENTP': ['Kreatif', 'Cerdas', 'Adaptif', 'Berargumen'],
  'INFJ': ['Empatik', 'Visioner', 'Insightful', 'Idealis'],
  'INFP': ['Empatik', 'Kreatif', 'Idealis', 'Otentik'],
  'ENFJ': ['Karismatik', 'Empatik', 'Menginspirasi', 'Diplomat'],
  'ENFP': ['Antusias', 'Kreatif', 'Hangat', 'Optimis'],
  'ISTJ': ['Bertanggung jawab', 'Terorganisir', 'Teliti', 'Setia'],
  'ISFJ': ['Perhatian', 'Setia', 'Sabar', 'Teliti'],
  'ESTJ': ['Tegas', 'Efisien', 'Terorganisir', 'Jujur'],
  'ESFJ': ['Hangat', 'Peduli', 'Loyal', 'Kooperatif'],
  'ISTP': ['Praktis', 'Adaptif', 'Logis', 'Tenang'],
  'ISFP': ['Sensitif', 'Artistik', 'Loyal', 'Fleksibel'],
  'ESTP': ['Energik', 'Pragmatis', 'Berani', 'Observan'],
  'ESFP': ['Spontan', 'Energik', 'Ceria', 'Adaptif'],
};

// ==========================================
// MODEL: Satu pertanyaan MBTI
// ==========================================
class MBTIQuestion {
  final int questionId; // ID pertanyaan
  final String question; // Pertanyaan
  final String optionA; // Pilihan A
  final String optionB; // Pilihan B
  final String dimension; // 'E_I', 'S_N', 'T_F', 'J_P'
  final String firstType; // Tipe untuk pilihan A ('E', 'S', 'T', 'J')
  final String secondType; // Tipe untuk pilihan B ('I', 'N', 'F', 'P')

  const MBTIQuestion({
    required this.questionId,
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.dimension,
    required this.firstType,
    required this.secondType,
  });

  factory MBTIQuestion.fromJson(Map<String, dynamic> json) {
    return MBTIQuestion(
      questionId: json['id'],
      dimension: json['dimension'],
      question: json['question'],
      optionA: json['options'][0]['answer'],
      firstType: json['options'][0]['type'],
      optionB: json['options'][1]['answer'],
      secondType: json['options'][1]['type'],
    );
  }

  /// Helper untuk mempertahankan kompatibilitas getter dengan UI sebelumnya
  String get optionAText => optionA;
  String get optionBText => optionB;
}

// ==========================================
// Helper: Hitung tipe MBTI dari jawaban
// ==========================================
/// Hitung tipe MBTI 4-huruf dari daftar jawaban.
/// [answers] = list pilihan jawaban, 0 (opsi A) atau 1 (opsi B).
/// Returns `({String type, Map<String, int> scores})`.
({String type, Map<String, int> scores}) calculateMBTI(List<int> answers, List<MBTIQuestion> mbtiQuestions) {
  final scores = <String, int>{
    'E': 0, 'I': 0, 'S': 0, 'N': 0, 'T': 0, 'F': 0, 'J': 0, 'P': 0,
  };

  for (int i = 0; i < mbtiQuestions.length && i < answers.length; i++) {
    final q = mbtiQuestions[i];
    if (answers[i] == 0) {
      scores[q.firstType] = (scores[q.firstType] ?? 0) + 1;
    } else {
      scores[q.secondType] = (scores[q.secondType] ?? 0) + 1;
    }
  }

  final type = StringBuffer();
  type.write(scores['E']! >= scores['I']! ? 'E' : 'I');
  type.write(scores['S']! >= scores['N']! ? 'S' : 'N');
  type.write(scores['T']! >= scores['F']! ? 'T' : 'F');
  type.write(scores['J']! >= scores['P']! ? 'J' : 'P');

  return (type: type.toString(), scores: scores);
}

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
