import '../models/emotion_model.dart';

/// Keputusan fusi audio-teks dengan aturan confident-switch tervalidasi.
///
/// Aturan (jangan ubah ambang tanpa validasi ulang):
///   textTop >= 0.8 AND keywordHits >= 2  ->  pakai kelas teks
///   selain itu                            ->  pakai kelas audio
///
/// Bukti validasi: acted TESS n=1200 → 0 kali fire (nol harm, fused 0.94);
/// explicit EN n=48 → 7 kali fire dengan presisi-fired 100%.
class FusionDecision {
  /// Kelas emosi pemenang.
  final EmotionType label;

  /// True bila kelas berasal dari kanal teks, false bila dari audio.
  final bool textUsed;

  /// Skor maksimum kanal teks (untuk diagnostik).
  final double textTop;

  /// Jumlah keyword mentah yang cocok di transkrip.
  final int keywordHits;

  const FusionDecision({
    required this.label,
    required this.textUsed,
    required this.textTop,
    required this.keywordHits,
  });

  @override
  String toString() =>
      'FusionDecision(label: ${label.name}, textUsed: $textUsed, '
      'textTop: ${textTop.toStringAsFixed(3)}, hits: $keywordHits)';
}

class FusionGate {
  /// Ambang kepercayaan kanal teks (tervalidasi, jangan ubah sembarang).
  static const double textThreshold = 0.8;

  /// Jumlah keyword minimum agar kanal teks boleh menang (tervalidasi).
  static const int minHits = 2;

  /// Tentukan kelas pemenang dari dua kanal.
  ///
  /// [audioScores] dan [textScores] adalah distribusi (jumlah = 1.0).
  /// [keywordHits] adalah jumlah keyword mentah dari analisis teks —
  /// transkrip kosong / nol keyword HARUS memberi 0 agar gate tak pernah fire.
  static FusionDecision decide({
    required Map<EmotionType, double> audioScores,
    required Map<EmotionType, double> textScores,
    required int keywordHits,
  }) {
    final audioTop = _argmax(audioScores);
    final textTopEntry = _argmaxEntry(textScores);

    final fires = textTopEntry.value >= textThreshold && keywordHits >= minHits;
    if (fires) {
      return FusionDecision(
        label: textTopEntry.key,
        textUsed: true,
        textTop: textTopEntry.value,
        keywordHits: keywordHits,
      );
    }
    return FusionDecision(
      label: audioTop,
      textUsed: false,
      textTop: textTopEntry.value,
      keywordHits: keywordHits,
    );
  }

  /// Kelas dengan skor tertinggi (urutan enum pertama menang bila seri).
  static EmotionType _argmax(Map<EmotionType, double> scores) {
    var best = EmotionType.values.first;
    var bestScore = scores[best] ?? double.negativeInfinity;
    for (final e in EmotionType.values.skip(1)) {
      final s = scores[e] ?? double.negativeInfinity;
      if (s > bestScore) {
        best = e;
        bestScore = s;
      }
    }
    return best;
  }

  static MapEntry<EmotionType, double> _argmaxEntry(
      Map<EmotionType, double> scores) {
    final key = _argmax(scores);
    return MapEntry(key, scores[key] ?? 0.0);
  }
}
