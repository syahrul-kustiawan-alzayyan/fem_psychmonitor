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
    if (psychologicalScore! <= 10) return 'Baik';
    if (psychologicalScore! <= 20) return 'Cukup';
    return 'Perlu Perhatian';
  }

  /// Deskripsi kondisi mental
  String get mentalHealthDescription {
    if (psychologicalScore == null) {
      return 'Anda belum mengisi kuesioner kesehatan mental.';
    }
    if (psychologicalScore! <= 10) {
      return 'Kondisi psikis Anda saat ini terpelihara dengan baik. Anda memiliki ketahanan mental yang sehat dan mampu mengelola stres sehari-hari secara efektif.';
    } else if (psychologicalScore! <= 20) {
      return 'Kondisi mental Anda sedang berada di area kuning. Anda mulai merasakan beban dari tekanan sehari-hari yang menumpuk. Ini adalah sinyal bahwa Anda sedang diforsir terlalu keras.';
    } else {
      return 'Kondisi mental Anda saat ini sedang sangat terkuras. Anda sedang menanggung beban emosional dan psikis yang cukup berat. Sangat penting untuk tidak mengabaikan perasaan ini.';
    }
  }

  /// Saran berdasarkan skor mental
  String get mentalHealthAdvice {
    if (psychologicalScore == null) {
      return 'Silakan isi kuesioner kesehatan mental untuk mendapatkan saran.';
    }
    if (psychologicalScore! <= 10) {
      return 'Pertahankan rutinitas self-care Anda, jaga keseimbangan antara pekerjaan dan kehidupan pribadi, serta tetap luangkan waktu untuk diri sendiri (me-time).';
    } else if (psychologicalScore! <= 20) {
      return 'Anda perlu menekan tombol jeda. Mulailah menetapkan batasan yang sehat (belajar berkata "tidak"), kurangi beban kerja yang tidak esensial, delegasikan tugas jika memungkinkan, dan prioritaskan tidur yang cukup.';
    } else {
      return 'Sangat penting untuk tidak mengabaikan perasaan ini atau memendamnya sendirian. Ini adalah waktu yang tepat untuk mencari bantuan profesional. Berkonsultasi dengan psikolog akan sangat membantu Anda.';
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
  final String questionId; // ID pertanyaan (ID)
  final String questionEn; // Pertanyaan (EN)
  final String optionA; // Pilihan A (ID)
  final String optionAEn; // Pilihan A (EN)
  final String optionB; // Pilihan B (ID)
  final String optionBEn; // Pilihan B (EN)
  final String dimension; // 'EI', 'SN', 'TF', 'JP'
  final String firstType; // Tipe untuk pilihan A ('E', 'S', 'T', 'J')
  final String secondType; // Tipe untuk pilihan B ('I', 'N', 'F', 'P')

  const MBTIQuestion({
    required this.questionId,
    required this.questionEn,
    required this.optionA,
    required this.optionAEn,
    required this.optionB,
    required this.optionBEn,
    required this.dimension,
    required this.firstType,
    required this.secondType,
  });

  /// Ambil pertanyaan sesuai locale
  String get question {
    final locale = AppLocalizations.currentLocale;
    return locale == 'en' ? questionEn : questionId;
  }

  /// Ambil opsi A sesuai locale
  String get optionAText {
    final locale = AppLocalizations.currentLocale;
    return locale == 'en' ? optionAEn : optionA;
  }

  /// Ambil opsi B sesuai locale
  String get optionBText {
    final locale = AppLocalizations.currentLocale;
    return locale == 'en' ? optionBEn : optionB;
  }
}

// ==========================================
// 20 PERTANYAAN MBTI (Bilingual ID/EN)
// 5 per dimensi: E/I, S/N, T/F, J/P
// ==========================================
const List<MBTIQuestion> mbtiQuestions = [
  // ── EXTRAVERSION vs INTROVERSION (5 pertanyaan) ──
  MBTIQuestion(
    questionId: 'Di acara sosial, kamu lebih suka...',
    questionEn: 'At social events, you prefer to...',
    optionA: 'Berinteraksi dengan banyak orang, termasuk yang belum dikenal',
    optionAEn: 'Interact with many people, including strangers',
    optionB: 'Mengobrol mendalam dengan satu atau dua orang yang sudah dikenal',
    optionBEn: 'Have deep conversations with one or two people you know well',
    dimension: 'EI',
    firstType: 'E',
    secondType: 'I',
  ),
  MBTIQuestion(
    questionId:
        'Setelah seharian beraktivitas, kamu mengisi ulang energi dengan...',
    questionEn: 'After a long day, you recharge by...',
    optionA: 'Berkumpul dan bersosialisasi dengan teman-teman',
    optionAEn: 'Gathering and socializing with friends',
    optionB: 'Menyendiri di tempat tenang, membaca atau mendengarkan musik',
    optionBEn: 'Being alone in a quiet place, reading or listening to music',
    dimension: 'EI',
    firstType: 'E',
    secondType: 'I',
  ),
  MBTIQuestion(
    questionId: 'Saat mengerjakan proyek, kamu lebih suka...',
    questionEn: 'When working on a project, you prefer to...',
    optionA: 'Berkolaborasi dan brainstorming dengan tim secara langsung',
    optionAEn: 'Collaborate and brainstorm with the team directly',
    optionB: 'Bekerja mandiri dulu, lalu sharing hasilnya',
    optionBEn: 'Work independently first, then share the results',
    dimension: 'EI',
    firstType: 'E',
    secondType: 'I',
  ),
  MBTIQuestion(
    questionId: 'Kamu lebih mudah berpikir jernih saat...',
    questionEn: 'You think more clearly when...',
    optionA: 'Berdiskusi dan menyampaikan ide secara verbal',
    optionAEn: 'Discussing and expressing ideas verbally',
    optionB: 'Merenungkan dan memproses ide dalam pikiran sendiri',
    optionBEn: 'Reflecting and processing ideas in your own mind',
    dimension: 'EI',
    firstType: 'E',
    secondType: 'I',
  ),
  MBTIQuestion(
    questionId: 'Teman-temanmu mendeskripsikan kamu sebagai orang yang...',
    questionEn: 'Your friends describe you as someone who is...',
    optionA: 'Terbuka, ekspresif, dan mudah bergaul',
    optionAEn: 'Open, expressive, and easy to get along with',
    optionB: 'Tenang, penuh pikiran, dan introspektif',
    optionBEn: 'Calm, thoughtful, and introspective',
    dimension: 'EI',
    firstType: 'E',
    secondType: 'I',
  ),

  // ── SENSING vs INTUITION (5 pertanyaan) ──
  MBTIQuestion(
    questionId: 'Saat mempelajari hal baru, kamu lebih suka...',
    questionEn: 'When learning something new, you prefer...',
    optionA: 'Instruksi langkah demi langkah yang jelas dan praktis',
    optionAEn: 'Clear, step-by-step practical instructions',
    optionB: 'Memahami konsep besar dan teorinya terlebih dahulu',
    optionBEn: 'Understanding the big concept and theory first',
    dimension: 'SN',
    firstType: 'S',
    secondType: 'N',
  ),
  MBTIQuestion(
    questionId: 'Kamu lebih memperhatikan...',
    questionEn: 'You pay more attention to...',
    optionA: 'Detail dan fakta-fakta konkret di depan mata',
    optionAEn: 'Details and concrete facts in front of you',
    optionB: 'Pola, makna tersembunyi, dan kemungkinan masa depan',
    optionBEn: 'Patterns, hidden meanings, and future possibilities',
    dimension: 'SN',
    firstType: 'S',
    secondType: 'N',
  ),
  MBTIQuestion(
    questionId: 'Dalam menyelesaikan masalah, kamu cenderung...',
    questionEn: 'When solving problems, you tend to...',
    optionA: 'Menggunakan metode yang sudah terbukti berhasil',
    optionAEn: 'Use methods that have been proven to work',
    optionB: 'Mencari pendekatan baru dan solusi kreatif',
    optionBEn: 'Seek new approaches and creative solutions',
    dimension: 'SN',
    firstType: 'S',
    secondType: 'N',
  ),
  MBTIQuestion(
    questionId: 'Kamu lebih tertarik pada...',
    questionEn: 'You are more interested in...',
    optionA: 'Apa yang sedang terjadi saat ini (realita)',
    optionAEn: 'What is happening right now (reality)',
    optionB: 'Apa yang mungkin terjadi di masa depan (potensi)',
    optionBEn: 'What could happen in the future (potential)',
    dimension: 'SN',
    firstType: 'S',
    secondType: 'N',
  ),
  MBTIQuestion(
    questionId: 'Saat membaca, kamu lebih menikmati...',
    questionEn: 'When reading, you enjoy more...',
    optionA: 'Konten yang jelas, faktual, dan langsung ke inti',
    optionAEn: 'Content that is clear, factual, and straight to the point',
    optionB: 'Narasi imajinatif yang kaya akan metafora dan simbolisme',
    optionBEn: 'Imaginative narratives rich in metaphors and symbolism',
    dimension: 'SN',
    firstType: 'S',
    secondType: 'N',
  ),

  // ── THINKING vs FEELING (5 pertanyaan) ──
  MBTIQuestion(
    questionId: 'Saat mengambil keputusan penting, kamu lebih mengandalkan...',
    questionEn: 'When making important decisions, you rely more on...',
    optionA: 'Logika, data, dan analisis objektif',
    optionAEn: 'Logic, data, and objective analysis',
    optionB: 'Perasaan, nilai personal, dan dampak pada orang lain',
    optionBEn: 'Feelings, personal values, and impact on others',
    dimension: 'TF',
    firstType: 'T',
    secondType: 'F',
  ),
  MBTIQuestion(
    questionId: 'Saat teman curhat tentang masalahnya, kamu cenderung...',
    questionEn: 'When a friend shares their problems, you tend to...',
    optionA: 'Langsung memberikan solusi dan saran praktis',
    optionAEn: 'Immediately offer solutions and practical advice',
    optionB: 'Mendengarkan dengan empati dan validasi perasaannya',
    optionBEn: 'Listen with empathy and validate their feelings',
    dimension: 'TF',
    firstType: 'T',
    secondType: 'F',
  ),
  MBTIQuestion(
    questionId: 'Kamu merasa lebih terganggu oleh...',
    questionEn: 'You feel more bothered by...',
    optionA: 'Keputusan yang tidak logis atau tidak konsisten',
    optionAEn: 'Decisions that are illogical or inconsistent',
    optionB: 'Perlakuan yang tidak adil atau tidak berempati',
    optionBEn: 'Treatment that is unfair or lacks empathy',
    dimension: 'TF',
    firstType: 'T',
    secondType: 'F',
  ),
  MBTIQuestion(
    questionId: 'Dalam debat atau diskusi, kamu...',
    questionEn: 'In debates or discussions, you...',
    optionA: 'Fokus pada kebenaran dan fakta, meskipun kadang tajam',
    optionAEn: 'Focus on truth and facts, even if sometimes its blunt',
    optionB: 'Mempertimbangkan perasaan semua pihak agar tetap harmonis',
    optionBEn: 'Consider everyone\'s feelings to maintain harmony',
    dimension: 'TF',
    firstType: 'T',
    secondType: 'F',
  ),
  MBTIQuestion(
    questionId: 'Kamu lebih menghargai orang yang...',
    questionEn: 'You value people who are more...',
    optionA: 'Kompeten, efisien, dan rasional',
    optionAEn: 'Competent, efficient, and rational',
    optionB: 'Penuh kasih, pengertian, dan suportif',
    optionBEn: 'Compassionate, understanding, and supportive',
    dimension: 'TF',
    firstType: 'T',
    secondType: 'F',
  ),

  // ── JUDGING vs PERCEIVING (5 pertanyaan) ──
  MBTIQuestion(
    questionId: 'Dalam kehidupan sehari-hari, kamu lebih suka...',
    questionEn: 'In daily life, you prefer...',
    optionA: 'Jadwal yang terstruktur dan rencana yang jelas',
    optionAEn: 'Structured schedules and clear plans',
    optionB: 'Fleksibilitas dan spontanitas, biarkan mengalir',
    optionBEn: 'Flexibility and spontaneity, just go with the flow',
    dimension: 'JP',
    firstType: 'J',
    secondType: 'P',
  ),
  MBTIQuestion(
    questionId: 'Menghadapi deadline, kamu biasanya...',
    questionEn: 'Facing deadlines, you usually...',
    optionA: 'Menyelesaikan jauh sebelum deadline agar tidak terburu-buru',
    optionAEn: 'Finish well before the deadline to avoid rushing',
    optionB: 'Bekerja paling produktif mendekati deadline (last minute rush)',
    optionBEn:
        'Work most productively close to the deadline (last minute rush)',
    dimension: 'JP',
    firstType: 'J',
    secondType: 'P',
  ),
  MBTIQuestion(
    questionId: 'Lemari dan meja kerjamu biasanya...',
    questionEn: 'Your closet and desk are usually...',
    optionA: 'Rapi, terorganisir, setiap barang punya tempatnya',
    optionAEn: 'Neat, organized, everything has its place',
    optionB: 'Sedikit berantakan tapi kamu tahu di mana semuanya',
    optionBEn: 'A bit messy but you know where everything is',
    dimension: 'JP',
    firstType: 'J',
    secondType: 'P',
  ),
  MBTIQuestion(
    questionId: 'Saat berlibur, kamu lebih suka...',
    questionEn: 'When on vacation, you prefer...',
    optionA: 'Itinerary yang sudah direncanakan detail dari awal',
    optionAEn: 'A detailed planned itinerary from the start',
    optionB: 'Jalan-jalan tanpa rencana, lihat situasi di sana',
    optionBEn: 'Going without plans, seeing what happens there',
    dimension: 'JP',
    firstType: 'J',
    secondType: 'P',
  ),
  MBTIQuestion(
    questionId: 'Kamu merasa lebih nyaman ketika...',
    questionEn: 'You feel more comfortable when...',
    optionA: 'Keputusan sudah final dan semuanya sudah diatur',
    optionAEn: 'Decisions are final and everything is arranged',
    optionB: 'Opsi masih terbuka dan bisa berubah kapan saja',
    optionBEn: 'Options are still open and can change anytime',
    dimension: 'JP',
    firstType: 'J',
    secondType: 'P',
  ),
];

// ==========================================
// Helper: Hitung tipe MBTI dari jawaban
// ==========================================
/// Hitung tipe MBTI 4-huruf dari daftar jawaban.
/// [answers] = list 20 item, tiap item 0 (opsi A) atau 1 (opsi B).
/// Returns `({String type, Map<String, int> scores})`.
({String type, Map<String, int> scores}) calculateMBTI(List<int> answers) {
  final scores = <String, int>{
    'E': 0,
    'I': 0,
    'S': 0,
    'N': 0,
    'T': 0,
    'F': 0,
    'J': 0,
    'P': 0,
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
