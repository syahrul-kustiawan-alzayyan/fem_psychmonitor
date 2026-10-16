import 'package:flutter_test/flutter_test.dart';

import 'package:fem_physicsmonitor/l10n/app_localizations.dart';
import 'package:fem_physicsmonitor/models/emotion_model.dart';
import 'package:fem_physicsmonitor/services/fusion_gate.dart';
import 'package:fem_physicsmonitor/services/text_emotion_service.dart';

/// Uji aturan confident-switch tervalidasi:
///   textTop >= 0.8 AND hits >= 2  ->  kelas teks, selain itu kelas audio.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<EmotionType, double> dist(Map<EmotionType, double> m) => m;

  const audioSad = {
    EmotionType.happy: 0.10,
    EmotionType.sad: 0.70,
    EmotionType.angry: 0.05,
    EmotionType.disgust: 0.05,
    EmotionType.neutral: 0.05,
    EmotionType.fear: 0.05,
  };

  group('FusionGate', () {
    test('textTop < 0.8 -> label dari audio', () {
      const text = {
        EmotionType.happy: 0.60,
        EmotionType.sad: 0.10,
        EmotionType.angry: 0.10,
        EmotionType.disgust: 0.05,
        EmotionType.neutral: 0.10,
        EmotionType.fear: 0.05,
      };
      final d = FusionGate.decide(
        audioScores: dist(audioSad),
        textScores: dist(text),
        keywordHits: 5,
      );
      expect(d.textUsed, isFalse);
      expect(d.label, EmotionType.sad);
    });

    test('textTop >= 0.8 tapi hits = 1 -> label dari audio', () {
      const text = {
        EmotionType.happy: 0.85,
        EmotionType.sad: 0.05,
        EmotionType.angry: 0.02,
        EmotionType.disgust: 0.02,
        EmotionType.neutral: 0.04,
        EmotionType.fear: 0.02,
      };
      final d = FusionGate.decide(
        audioScores: dist(audioSad),
        textScores: dist(text),
        keywordHits: 1,
      );
      expect(d.textUsed, isFalse);
      expect(d.label, EmotionType.sad);
    });

    test('textTop >= 0.8 dan hits >= 2 -> label dari teks', () {
      const text = {
        EmotionType.happy: 0.90,
        EmotionType.sad: 0.02,
        EmotionType.angry: 0.02,
        EmotionType.disgust: 0.02,
        EmotionType.neutral: 0.02,
        EmotionType.fear: 0.02,
      };
      final d = FusionGate.decide(
        audioScores: dist(audioSad),
        textScores: dist(text),
        keywordHits: 3,
      );
      expect(d.textUsed, isTrue);
      expect(d.label, EmotionType.happy);
    });

    test('ambang tepat 0.8 dan 2 hits -> fire (batas inklusif)', () {
      const text = {
        EmotionType.happy: 0.80,
        EmotionType.sad: 0.05,
        EmotionType.angry: 0.05,
        EmotionType.disgust: 0.03,
        EmotionType.neutral: 0.04,
        EmotionType.fear: 0.03,
      };
      final d = FusionGate.decide(
        audioScores: dist(audioSad),
        textScores: dist(text),
        keywordHits: 2,
      );
      expect(d.textUsed, isTrue);
      expect(d.label, EmotionType.happy);
    });
  });

  group('TextEmotionAnalysis + gate (transkrip kosong)', () {
    test('transkrip kosong -> hits 0, isPrior, gate tidak fire', () async {
      AppLocalizations.setLocale('id');
      await TextEmotionService.instance.loadAll();
      final a = TextEmotionService.instance.analyzeDetailed('');
      expect(a.hits, 0);
      expect(a.isPrior, isTrue);
      final d = FusionGate.decide(
        audioScores: dist(audioSad),
        textScores: a.scores,
        keywordHits: a.hits,
      );
      expect(d.textUsed, isFalse);
      expect(d.label, EmotionType.sad);
    });

    test('tanpa keyword cocok -> hits 0, isPrior, skor prior netral', () async {
      AppLocalizations.setLocale('id');
      await TextEmotionService.instance.loadAll();
      final a = TextEmotionService.instance
          .analyzeDetailed('xyz qwerty blorpo fnord zzz top');
      expect(a.hits, 0);
      expect(a.isPrior, isTrue);
      expect(a.scores[EmotionType.neutral], 0.5);
    });

    test('skor kanal pemenang tetap berjumlah 1.0', () async {
      AppLocalizations.setLocale('id');
      await TextEmotionService.instance.loadAll();
      final audios = dist(audioSad);
      final audioTotal = audios.values.fold<double>(0, (a, b) => a + b);
      expect(audioTotal, closeTo(1.0, 1e-9));
      final a = TextEmotionService.instance.analyzeDetailed('');
      final priorTotal = a.scores.values.fold<double>(0, (x, y) => x + y);
      expect(priorTotal, closeTo(1.0, 1e-9));
    });
  });
}
