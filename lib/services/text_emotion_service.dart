import '../models/emotion_model.dart';

class TextEmotionService {
  static const Map<EmotionType, List<String>> _keywords = {
    EmotionType.happy: [
      'bahagia', 'senang', 'gembira', 'puas', 'ceria',
      'terima kasih', 'syukur', 'bersyukur', 'bangga',
      'menyenangkan', 'indah', 'hebat', 'luar biasa', 'mantap',
      'sukses', 'happy', 'senyum', 'tertawa', 'bersemangat',
      'cinta', 'suka', 'nikmat', 'enak', 'asyik', 'keren', 'wow',
      'sehat', 'favorit', 'istimewa', 'berharga', 'semangat',
      'optimis', 'cerah', 'wonderful', 'amazing', 'great', 'good',
      'bagus', 'seru', 'fun', 'menarik', 'mengagumkan', 'lega',
      'plong', 'bahagia', 'grinning',
    ],
    EmotionType.sad: [
      'sedih', 'menangis', 'nangis', 'kecewa', 'kesepian',
      'sendiri', 'sunyi', 'hampa', 'pilu', 'nestapa', 'galau',
      'murung', 'lesu', 'putus asa', 'patah hati', 'merana',
      'rindu', 'kangen', 'kehilangan', 'menyesal', 'gagal',
      'buruk', 'worst', 'sial', 'payah', 'menderita', 'sengsara',
      'terpuruk', 'down', 'sedih banget', 'nelangsa', 'sendu',
      'muram', 'suram', 'tragis', 'malang', 'kalah', 'hancur',
      'broken', 'cry', 'weep', 'sobbing', 'miserable', 'depresi',
      'tertekan', 'beban', 'lelah', 'capai', 'letih',
    ],
    EmotionType.angry: [
      'marah', 'kesal', 'jengkel', 'sebel', 'emosi', 'bete',
      'geregetan', 'frustrasi', 'sebal', 'tersinggung', 'benci',
      'dendam', 'geram', 'panas', 'meledak', 'berang', 'murka',
      'ngamuk', 'marah besar', 'keki', 'gondok', 'naik darah',
      'emosi tinggi', 'mengamuk', 'kesal banget', 'jengkel banget',
      'sebel banget', 'geram', 'gemas', 'masalah', 'berantem',
      'bertengkar', 'ribut', 'gusar', 'memarahi', 'ngomel',
      'greget', 'gregetan', 'membenci', 'tidak suka', 'sumpah',
      'kesel', 'jengkelin', 'nyebelin', 'mengganggu', 'menggangu',
    ],
    EmotionType.disgust: [
      'jijik', 'muak', 'enek', 'mual', 'menggelikan',
      'menjijikkan', 'jorok', 'kotor', 'norak', 'payah',
      'alay', 'kampungan', 'risih', 'geli', 'ngeri',
      'menjijikan', 'jorok banget', 'kotor banget', 'norak banget',
      'alay banget', 'tidak sopan', 'kurang ajar', 'memalukan',
      'aib', 'nista', 'hina', 'rendah', 'budek', 'tolol',
      'bodoh', 'bego', 'idiot', 'goblok', 'sampah', 'busuk',
      'benci', 'muak banget', 'enek banget', 'jorok',
      'menyebalkan', 'menjengkelkan',
    ],
    EmotionType.neutral: [
      'biasa', 'standar', 'netral', 'stabil', 'tenang',
      'santai', 'relax', 'ok', 'baik', 'cukup', 'biasa aja',
      'aman', 'kalem', 'adem', 'tenteram', 'damai', 'seperti biasa',
      'nothing', 'fine', 'okay', 'baik baik', 'baik-baik',
      'biasa saja', 'lumayan', 'cukup baik', 'tidak apa apa',
      'tidak apa-apa', 'gpp', 'engga apa apa', 'engga apa-apa',
      'baiklah', 'oke', 'okelah', 'terserah', 'mungkin',
      'biasanya', 'normal', 'sama aja', 'sama saja',
    ],
    EmotionType.fear: [
      'takut', 'cemas', 'khawatir', 'gelisah', 'panik',
      'gugup', 'deg-degan', 'was-was', 'ngeri', 'horor',
      'mengancam', 'terancam', 'khawatir banget', 'parno',
      'gelo', 'anxiety', 'stres', 'tertekan', 'tegang',
      'grogi', 'minder', 'insecure', 'ragu', 'bimbang',
      'tidak yakin', 'gak yakin', 'tidak percaya diri',
      'gak percaya diri', 'takut banget', 'cemas banget',
      'khawatiran', 'ketakutan', 'encemen', 'waswas',
      'curiga', 'prasangka', 'was-was', 'degdegan',
      'jantung berdebar', 'keringat dingin', 'merinding',
      'bulu kuduk', 'seram', 'angker', 'gentar', 'ciut',
    ],
  };

  static Map<EmotionType, double> analyze(String text) {
    if (text.trim().isEmpty) {
      return {
        EmotionType.happy: 0.1,
        EmotionType.sad: 0.1,
        EmotionType.angry: 0.1,
        EmotionType.disgust: 0.1,
        EmotionType.neutral: 0.5,
        EmotionType.fear: 0.1,
      };
    }

    final lower = text.toLowerCase();
    final words = lower.split(RegExp(r'[\s,.!?;:()\-]+'));

    Map<EmotionType, double> scores = {};
    int totalMatches = 0;

    for (final entry in _keywords.entries) {
      final emotion = entry.key;
      final kws = entry.value;
      int count = 0;

      for (final kw in kws) {
        if (kw.contains(' ')) {
          if (lower.contains(kw)) {
            count += 2;
          }
        } else {
          count += words.where((w) => w == kw).length;
        }
      }

      scores[emotion] = count.toDouble();
      totalMatches += count;
    }

    if (totalMatches == 0) {
      return {
        EmotionType.happy: 0.1,
        EmotionType.sad: 0.1,
        EmotionType.angry: 0.1,
        EmotionType.disgust: 0.1,
        EmotionType.neutral: 0.5,
        EmotionType.fear: 0.1,
      };
    }

    for (final e in EmotionType.values) {
      scores[e] = (scores[e] ?? 0) / totalMatches;
    }

    return scores;
  }
}
