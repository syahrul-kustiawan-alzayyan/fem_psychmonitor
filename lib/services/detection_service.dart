import 'dart:math';
import '../models/emotion_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DetectionService — Mock emotion detection & suggestion generation
//
// Simulasi workflow:
//   1. detectAudioEmotion()     → Random emotion scores dari suara
//   2. detectTextEmotion()      → Emotion scores dari transkrip teks
//   3. combineEmotions()        → Weighted merge (audio 60% + text 40%)
//   4. generateSuggestion()     → Saran berdasarkan MBTI + emosi
// ─────────────────────────────────────────────────────────────────────────────
class DetectionService {
  static final _rand = Random();

  /// Simulasi deteksi emosi dari audio (setiap 3 detik)
  /// Returns skor probabilitas untuk setiap emosi (total = 1.0)
  static Map<EmotionType, double> detectAudioEmotion() {
    // Generate random scores
    final raw = <EmotionType, double>{};
    double total = 0;
    for (final e in EmotionType.values) {
      final score = _rand.nextDouble() * 10;
      raw[e] = score;
      total += score;
    }
    // Normalize ke 0-1
    return raw.map((k, v) => MapEntry(k, v / total));
  }

  /// Simulasi transkrip suara menjadi teks
  static String transcribeAudio(int secondsElapsed) {
    final transcripts = [
      'Hari ini saya merasa cukup baik...',
      'Ada beberapa hal yang membuat saya berpikir...',
      'Saya mencoba untuk tetap tenang menghadapi situasi ini...',
      'Kadang saya merasa sedikit cemas tentang masa depan...',
      'Tapi secara keseluruhan saya bersyukur...',
      'Ada momen yang membuat saya tersenyum hari ini...',
      'Saya sedang berusaha untuk lebih positif...',
      'Hubungan saya dengan orang-orang terdekat cukup baik...',
      'Saya belajar untuk menerima keadaan...',
      'Semoga besok akan lebih baik lagi...',
    ];
    final idx = (secondsElapsed ~/ 3) % transcripts.length;
    return transcripts[idx];
  }

  /// Simulasi deteksi emosi dari teks transkrip
  static Map<EmotionType, double> detectTextEmotion(String text) {
    // Mock: text-based detection juga random tapi dengan bias berbeda
    final raw = <EmotionType, double>{};
    double total = 0;

    // Bias berdasarkan kata kunci sederhana
    double happyBias = 1.0;
    double sadBias = 1.0;
    double fearBias = 1.0;

    if (text.contains('baik') || text.contains('bersyukur') || text.contains('tersenyum')) {
      happyBias = 3.0;
    }
    if (text.contains('cemas') || text.contains('takut')) {
      fearBias = 3.0;
    }
    if (text.contains('sedih') || text.contains('kecewa')) {
      sadBias = 3.0;
    }

    for (final e in EmotionType.values) {
      double bias = 1.0;
      if (e == EmotionType.happy) bias = happyBias;
      if (e == EmotionType.sad) bias = sadBias;
      if (e == EmotionType.fear) bias = fearBias;

      final score = (_rand.nextDouble() * 5) * bias;
      raw[e] = score;
      total += score;
    }
    return raw.map((k, v) => MapEntry(k, v / total));
  }

  /// Gabungkan hasil audio + transcript (audio 60%, text 40%)
  static Map<EmotionType, double> combineEmotions(
    Map<EmotionType, double> audio,
    Map<EmotionType, double> text,
  ) {
    const audioWeight = 0.6;
    const textWeight = 0.4;

    final combined = <EmotionType, double>{};
    double total = 0;

    for (final e in EmotionType.values) {
      final score = (audio[e] ?? 0) * audioWeight + (text[e] ?? 0) * textWeight;
      combined[e] = score;
      total += score;
    }

    // Re-normalize
    if (total > 0) {
      return combined.map((k, v) => MapEntry(k, v / total));
    }
    return combined;
  }

  /// Tentukan emosi dominan dari skor gabungan
  static EmotionType getDominantEmotion(Map<EmotionType, double> scores) {
    EmotionType dominant = EmotionType.neutral;
    double maxScore = 0;
    for (final entry in scores.entries) {
      if (entry.value > maxScore) {
        maxScore = entry.value;
        dominant = entry.key;
      }
    }
    return dominant;
  }

  /// Generate saran AI berdasarkan MBTI type + emosi terdeteksi
  static String generateSuggestion(String mbtiType, EmotionType emotion) {
    final suggestions = _mbtiEmotionSuggestions[mbtiType] ??
        _mbtiEmotionSuggestions['DEFAULT']!;

    return suggestions[emotion] ?? suggestions[EmotionType.neutral]!;
  }

  /// Template saran berdasarkan MBTI type + emosi
  static final Map<String, Map<EmotionType, String>> _mbtiEmotionSuggestions = {
    // ── Analyst Types ──
    'INTJ': {
      EmotionType.happy: 'Kebahagiaan Anda sebagai INTJ sering muncul dari pencapaian intelektual. Tetap pertahankan visi jangka panjang Anda dan rayakan progres kecil setiap hari.',
      EmotionType.sad: 'Sebagai INTJ, Anda cenderung memproses emosi secara internal. Coba tulis jurnal pikiran Anda — ini membantu memetakan perasaan secara logis.',
      EmotionType.angry: 'Kemarahan INTJ sering berakar dari inefisiensi. Ambil jeda, analisis akar masalahnya, dan buat rencana perbaikan yang terstruktur.',
      EmotionType.fear: 'Kecemasan Anda mungkin terkait ketidakpastian. Buatlah contingency plan — INTJ merasa lebih tenang saat punya rencana cadangan.',
      EmotionType.neutral: 'Status netral bisa jadi tanda keseimbangan atau kekosongan. Luangkan waktu untuk refleksi: apa tujuan terbesar Anda saat ini?',
      EmotionType.disgust: 'Rasa tidak nyaman ini bisa menjadi sinyal bahwa sesuatu tidak sejalan dengan standar tinggi Anda. Evaluasi situasinya secara objektif.',
    },
    'INTP': {
      EmotionType.happy: 'Kreativitas intelektual Anda sedang tinggi! Manfaatkan momen ini untuk eksplorasi ide baru atau proyek yang menantang.',
      EmotionType.sad: 'INTP kadang kesulitan mengekspresikan emosi. Coba diskusikan perasaan Anda dengan seseorang yang Anda percaya — perspektif baru bisa membantu.',
      EmotionType.angry: 'Frustrasi Anda mungkin karena orang lain tidak memahami logika Anda. Cobalah jelaskan pemikiran Anda dengan analogi yang sederhana.',
      EmotionType.fear: 'Overthinking bisa meningkatkan kecemasan. Fokus pada satu masalah konkret, pecahkan, lalu lanjut ke yang berikutnya.',
      EmotionType.neutral: 'Pikiran Anda selalu aktif. Gunakan momen tenang ini untuk brainstorming atau membaca sesuatu yang menginspirasi.',
      EmotionType.disgust: 'Ketidakpuasan ini bisa menjadi motivasi untuk menemukan solusi yang lebih elegan. Channelkan energi ini ke problem-solving.',
    },
    'ENTJ': {
      EmotionType.happy: 'Semangat kepemimpinan Anda sedang tinggi! Bagikan energi positif ini dengan tim atau orang-orang di sekitar Anda.',
      EmotionType.sad: 'ENTJ jarang menunjukkan kerentanan, tapi penting untuk mengakui perasaan ini. Istirahat sejenak bukan kelemahan — itu strategi.',
      EmotionType.angry: 'Gunakan energi kemarahan Anda sebagai bahan bakar untuk perubahan positif. Buat action plan yang konkret.',
      EmotionType.fear: 'Ketakutan sering berasal dari kurangnya kontrol. Identifikasi apa yang bisa Anda kontrol dan fokus di situ.',
      EmotionType.neutral: 'Momen ini cocok untuk strategic planning. Evaluasi progress Anda dan tetapkan milestone baru.',
      EmotionType.disgust: 'Standar tinggi Anda adalah kekuatan. Gunakan perasaan ini untuk mendorong perbaikan, bukan menghakimi.',
    },
    'ENTP': {
      EmotionType.happy: 'Antusiasme Anda menular! Ini saat yang tepat untuk memulai proyek kreatif atau debat intelektual yang menyenangkan.',
      EmotionType.sad: 'ENTP kadang menutupi kesedihan dengan humor. Tidak apa-apa merasa tidak baik — berikan diri Anda ruang untuk memproses.',
      EmotionType.angry: 'Channelkan energi ini ke debat konstruktif atau aktivitas fisik. Kemarahan yang tersalurkan bisa menghasilkan inovasi.',
      EmotionType.fear: 'Kecemasan Anda mungkin terkait rutinitas atau keterbatasan. Cari cara kreatif untuk memecahkan kebuntuan.',
      EmotionType.neutral: 'Bosan? Cari stimulus baru — podcast, buku, atau percakapan mendalam dengan perspektif yang berbeda.',
      EmotionType.disgust: 'Ketidakpuasan ini bisa menjadi katalis untuk ide inovatif. Apa yang bisa Anda ubah atau tingkatkan?',
    },

    // ── Diplomat Types ──
    'INFJ': {
      EmotionType.happy: 'Kebahagiaan mendalam Anda sebagai INFJ berasal dari koneksi bermakna. Pertahankan hubungan-hubungan yang memberikan energi positif.',
      EmotionType.sad: 'INFJ merasakan emosi sangat dalam. Berikan diri Anda izin untuk merasa, lalu channelkan ke ekspresi kreatif seperti menulis atau seni.',
      EmotionType.angry: 'Kemarahan INFJ sering muncul dari ketidakadilan. Gunakan idealisme Anda untuk advokasi, bukan untuk menyimpan dendam.',
      EmotionType.fear: 'Intuisi Anda yang kuat kadang menciptakan kecemasan berlebih. Grounding exercise dan meditasi bisa sangat membantu.',
      EmotionType.neutral: 'Momen ketenangan ini berharga untuk INFJ. Gunakan untuk introspeksi dan menyelaraskan tindakan dengan nilai-nilai Anda.',
      EmotionType.disgust: 'Sensitivitas Anda terhadap hal negatif perlu dikelola. Batasi paparan terhadap situasi toxic dan fokus pada yang bermakna.',
    },
    'INFP': {
      EmotionType.happy: 'Kegembiraan Anda menginspirasi orang lain. Ekspresikan melalui kreativitas — tulisan, musik, atau seni visual.',
      EmotionType.sad: 'INFP merasakan segalanya dengan intens. Jadikan perasaan ini bahan bakar untuk ekspresi kreatif yang autentik.',
      EmotionType.angry: 'Kemarahan Anda biasanya terkait pelanggaran nilai. Gunakan energi ini untuk membela apa yang Anda yakini benar.',
      EmotionType.fear: 'Kecemasan sering muncul dari ketakutan tidak autentik. Ingat: Anda tidak perlu menjadi sempurna untuk layak dicintai.',
      EmotionType.neutral: 'Ketenangan ini bisa menjadi ruang kreatif terbaik Anda. Apa yang ingin Anda ciptakan atau jelajahi?',
      EmotionType.disgust: 'Perasaan ini mungkin sinyal bahwa Anda perlu menjauh dari lingkungan yang tidak sejalan dengan nilai Anda.',
    },
    'ENFJ': {
      EmotionType.happy: 'Energi positif Anda sangat berpengaruh! Gunakan untuk menginspirasi dan membimbing orang-orang di sekitar Anda.',
      EmotionType.sad: 'Anda sering mendahulukan orang lain. Ingat bahwa merawat diri sendiri bukan egois — Anda perlu mengisi ulang energi.',
      EmotionType.angry: 'Kemarahan Anda sering berasal dari ketidakseimbangan memberi dan menerima. Tetapkan batasan yang sehat.',
      EmotionType.fear: 'Ketakutan gagal membuat Anda terus mendorong diri. Belajar bahwa "cukup baik" kadang memang sudah cukup.',
      EmotionType.neutral: 'Gunakan momen ini untuk evaluasi: apakah hubungan dan komitmen Anda saat ini selaras dengan tujuan Anda?',
      EmotionType.disgust: 'Ketidaknyamanan ini mungkin tanda burnout dari terlalu banyak membantu orang lain. Prioritaskan diri sendiri.',
    },
    'ENFP': {
      EmotionType.happy: 'Antusiasme ENFP sangat menular! Bagikan kebahagiaan ini dan buat dampak positif di lingkungan Anda.',
      EmotionType.sad: 'Meskipun Anda terlihat ceria, perasaan ini valid. Izinkan diri Anda vulnerable dengan orang yang Anda percaya.',
      EmotionType.angry: 'ENFP yang marah bisa sangat intens. Channelkan ke aktivitas fisik atau diskusi terbuka yang konstruktif.',
      EmotionType.fear: 'FOMO dan ketakutan kehilangan potensi sering menghantui ENFP. Fokus pada satu prioritas utama saat ini.',
      EmotionType.neutral: 'Ketenangan untuk ENFP bisa terasa membosankan. Cari inspirasi baru — tapi jangan overcommit!',
      EmotionType.disgust: 'Anda mungkin merasa terjebak dalam rutinitas. Cari cara untuk menambahkan variasi dan spontanitas.',
    },

    // ── Sentinel Types ──
    'ISTJ': {
      EmotionType.happy: 'Kepuasan Anda berasal dari tugas yang selesai dengan baik. Hargai pencapaian Anda dan nikmati momen ini.',
      EmotionType.sad: 'ISTJ cenderung memendam perasaan. Coba ungkapkan melalui jurnal atau percakapan terstruktur dengan orang terpercaya.',
      EmotionType.angry: 'Frustrasi sering muncul dari aturan yang dilanggar. Tetapkan ekspektasi yang jelas dan komunikasikan dengan tegas.',
      EmotionType.fear: 'Ketidakpastian membuat ISTJ tidak nyaman. Buatlah rencana detail untuk skenario yang memungkinkan.',
      EmotionType.neutral: 'Status stabil ini ideal untuk perencanaan jangka panjang. Review prioritas dan optimasi sistem Anda.',
      EmotionType.disgust: 'Standar Anda yang tinggi terganggu. Fokus pada solusi daripada masalah — pendekatan sistematis lebih efektif.',
    },
    'ISFJ': {
      EmotionType.happy: 'Kebahagiaan ISFJ sering berasal dari membantu orang lain. Terus jaga keseimbangan antara memberi dan merawat diri.',
      EmotionType.sad: 'Anda menyerap emosi orang lain. Penting untuk membedakan perasaan Anda sendiri dan memberi ruang untuk self-care.',
      EmotionType.angry: 'ISFJ jarang menunjukkan kemarahan, tapi penting untuk mengekspresikannya secara sehat daripada menyimpannya.',
      EmotionType.fear: 'Kekhawatiran berlebih tentang orang tersayang adalah hal yang wajar. Fokus pada apa yang bisa Anda kontrol.',
      EmotionType.neutral: 'Momen tenang ini cocok untuk aktivitas yang membuat Anda rileks — memasak, bercocok tanam, atau membaca.',
      EmotionType.disgust: 'Anda mungkin merasa dimanfaatkan. Belajar berkata "tidak" adalah keterampilan penting untuk kesehatan mental.',
    },
    'ESTJ': {
      EmotionType.happy: 'Produktivitas dan efisiensi membawa kepuasan bagi ESTJ. Bagikan metode sukses Anda dengan orang lain.',
      EmotionType.sad: 'Menerima kerentanan bukan kelemahan. Izinkan diri Anda istirahat dan memproses emosi tanpa judgment.',
      EmotionType.angry: 'Channelkan kemarahan Anda ke tindakan terstruktur. Buat daftar solusi dan implementasikan secara metodis.',
      EmotionType.fear: 'Ketakutan kehilangan kontrol bisa dikelola dengan delegasi dan sistem backup. Anda tidak harus melakukan semuanya sendiri.',
      EmotionType.neutral: 'Waktu yang tepat untuk review dan optimasi. Apa yang bisa ditingkatkan dalam rutinitas atau proyek Anda?',
      EmotionType.disgust: 'Inefisiensi mengganggu ESTJ. Identifikasi bottleneck dan buat rencana perbaikan yang terukur.',
    },
    'ESFJ': {
      EmotionType.happy: 'Harmoni sosial membawa kebahagiaan bagi ESFJ. Bagikan energi positif ini melalui pelayanan dan kebaikan.',
      EmotionType.sad: 'Anda sering menutupi kesedihan demi orang lain. Ingat bahwa meminta bantuan juga bentuk kekuatan.',
      EmotionType.angry: 'Konflik sangat menekan ESFJ. Selesaikan perbedaan melalui dialog empatis, bukan penghindaran.',
      EmotionType.fear: 'Ketakutan penolakan sering menghantui ESFJ. Ingat bahwa pendapat orang lain tidak menentukan nilai Anda.',
      EmotionType.neutral: 'Gunakan waktu ini untuk aktivitas sosial berkualitas yang mengisi, bukan menguras energi Anda.',
      EmotionType.disgust: 'Anda mungkin lelah dari dinamika sosial yang toxic. Jaga batasan dan prioritaskan lingkungan yang positif.',
    },

    // ── Explorer Types ──
    'ISTP': {
      EmotionType.happy: 'Kebebasan dan tantangan membuat ISTP bahagia. Cari petualangan atau proyek hands-on yang mengikat.',
      EmotionType.sad: 'ISTP cenderung menghindari pembicaraan emosional. Coba ekspresikan melalui aktivitas fisik atau hobi teknis.',
      EmotionType.angry: 'Kemarahan ISTP bisa sangat tajam tapi singkat. Berikan diri Anda ruang, lalu analisis situasinya secara rasional.',
      EmotionType.fear: 'Kecemasan sering muncul dari perasaan terjebak. Pastikan Anda punya opsi dan fleksibilitas.',
      EmotionType.neutral: 'ISTP di momen tenang sering menemukan insight teknis terbaik. Eksplorasi sesuatu yang baru.',
      EmotionType.disgust: 'Ketidaknyamanan mungkin dari aturan yang terlalu kaku. Cari cara kreatif untuk bekerja dalam batasan.',
    },
    'ISFP': {
      EmotionType.happy: 'Keindahan dan autentisitas membawa kebahagiaan mendalam. Ekspresikan diri melalui seni atau alam.',
      EmotionType.sad: 'Perasaan ini bisa menjadi sumber kreativitas. Transformasikan ke ekspresi artistik yang bermakna.',
      EmotionType.angry: 'ISFP jarang marah, tapi saat marah sangat intens. Cari tempat tenang dan ekspresikan melalui seni.',
      EmotionType.fear: 'Ketakutan akan konfrontasi bisa diatasi dengan mengekspresikan kebutuhan Anda secara lembut tapi tegas.',
      EmotionType.neutral: 'Momen ini cocok untuk menikmati keindahan kecil — alam, musik, atau seni. Isi jiwa Anda dengan inspirasi.',
      EmotionType.disgust: 'Anda mungkin merasa dipaksa untuk menjadi seseorang yang bukan diri Anda. Tetap authentik.',
    },
    'ESTP': {
      EmotionType.happy: 'Energi tinggi ESTP butuh outlet! Manfaatkan momen ini untuk olahraga, networking, atau petualangan baru.',
      EmotionType.sad: 'ESTP jarang mau mengakui kesedihan. Tapi perasaan ini manusiawi — coba bicarakan rasa ini dengan teman dekat.',
      EmotionType.angry: 'Kemarahan ESTP sangat langsung. Channelkan ke olahraga kompetitif atau aktivitas fisik intens.',
      EmotionType.fear: 'ESTP jarang takut, tapi ketika ya, biasanya tentang kehilangan kebebasan. Evaluasi apa yang membatasi Anda.',
      EmotionType.neutral: 'Kebosanan adalah musuh ESTP. Cari stimulus baru — tantangan, kompetisi, atau pengalaman baru.',
      EmotionType.disgust: 'Frustasi dari rutinitas monoton? Cari cara untuk menambahkan elemen kejutan dalam hari Anda.',
    },
    'ESFP': {
      EmotionType.happy: 'Kegembiraan ESFP menular ke semua orang! Sebarkan energi positif ini dan ciptakan kenangan berharga.',
      EmotionType.sad: 'Meskipun Anda biasanya ceria, perasaan ini perlu diakui. Berbicaralah dengan seseorang alih-alih menekapnya.',
      EmotionType.angry: 'Kemarahan ESFP bisa sangat ekspresif. Ambil napas dalam, lalu cari pemecahan yang konstruktif.',
      EmotionType.fear: 'Ketakutan sering berasal dari pikiran tentang masa depan. Fokus pada momen sekarang — kekuatan utama Anda.',
      EmotionType.neutral: 'ESFP yang tenang mungkin butuh stimulasi sosial. Hubungi teman atau rencanakan aktivitas menyenangkan.',
      EmotionType.disgust: 'Anda mungkin merasa terjebak di situasi membosankan. Cari cara kreatif untuk menambahkan kesenangan.',
    },

    // ── Default fallback ──
    'DEFAULT': {
      EmotionType.happy: 'Selamat! Anda sedang dalam kondisi emosional yang baik. Pertahankan aktivitas dan hubungan yang memberikan kebahagiaan ini.',
      EmotionType.sad: 'Sedih itu manusiawi dan wajar. Cobalah bicarakan perasaan Anda dengan seseorang yang dipercaya, atau tulis jurnal perasaan.',
      EmotionType.angry: 'Kemarahan adalah sinyal bahwa ada sesuatu yang perlu diperhatikan. Ambil napas dalam dan cari akar masalahnya.',
      EmotionType.fear: 'Kecemasan bisa dikelola. Cobalah teknik grounding: sebutkan 5 hal yang bisa Anda lihat, 4 yang disentuh, 3 yang didengar.',
      EmotionType.neutral: 'Keseimbangan emosional yang baik. Gunakan momen tenang ini untuk refleksi dan self-care.',
      EmotionType.disgust: 'Perasaan tidak nyaman ini wajar. Identifikasi pemicunya dan pertimbangkan langkah untuk mengatasinya.',
    },
  };
}
