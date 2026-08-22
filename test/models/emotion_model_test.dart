import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fem_physicsmonitor/l10n/app_localizations.dart';
import 'package:fem_physicsmonitor/models/emotion_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLocalizations -> locale deterministik', () {
    test('set locale id', () {
      AppLocalizations.setLocale('id');
      expect(AppLocalizations.locale, 'id');
    });
  });

  group('EmotionType extension', () {
    setUpAll(() => AppLocalizations.setLocale('id'));

    test('semua 6 emosi tersedia', () {
      expect(EmotionType.values, hasLength(6));
      expect(
        EmotionType.values,
        containsAll(<EmotionType>[
          EmotionType.happy,
          EmotionType.sad,
          EmotionType.angry,
          EmotionType.disgust,
          EmotionType.neutral,
          EmotionType.fear,
        ]),
      );
    });

    test('displayName mengikuti l10n', () {
      expect(EmotionType.happy.displayName, AppLocalizations.tr('emotion_happy'));
      expect(EmotionType.sad.displayName, AppLocalizations.tr('emotion_sad'));
    });

    test('emoji setiap emosi', () {
      expect(EmotionType.happy.emoji, '😊');
      expect(EmotionType.sad.emoji, '😢');
      expect(EmotionType.angry.emoji, '😠');
      expect(EmotionType.disgust.emoji, '🤢');
      expect(EmotionType.neutral.emoji, '😐');
      expect(EmotionType.fear.emoji, '😨');
    });

    test('assetIconPath menunjuk folder emosi', () {
      expect(EmotionType.happy.assetIconPath, 'assets/icon/emosi/happy.png');
      expect(EmotionType.angry.assetIconPath, 'assets/icon/emosi/anger.png');
      expect(EmotionType.fear.assetIconPath, 'assets/icon/emosi/fear.png');
    });

    test('icon material tersedia untuk tiap emosi', () {
      for (final e in EmotionType.values) {
        expect(e.icon, isA<IconData>());
      }
    });

    test('emotionValue: positif untuk happy, negatif untuk emosi lain', () {
      expect(EmotionType.happy.emotionValue, greaterThan(0));
      expect(EmotionType.neutral.emotionValue, 0);
      expect(EmotionType.sad.emotionValue, lessThan(0));
      expect(EmotionType.angry.emotionValue, lessThan(0));
      expect(EmotionType.fear.emotionValue, lessThan(0));
      expect(EmotionType.disgust.emotionValue, lessThan(0));
    });

    test('valueLabel memakai tanda +/-', () {
      expect(EmotionType.happy.valueLabel, '+${EmotionType.happy.emotionValue}');
      expect(EmotionType.sad.valueLabel, '${EmotionType.sad.emotionValue}');
    });

    test('psychMessage mengikuti l10n', () {
      expect(EmotionType.fear.psychMessage, AppLocalizations.tr('msg_fear'));
    });

    test('psychStatus memiliki label non-kosong', () {
      for (final e in EmotionType.values) {
        expect(e.psychStatus, isNotEmpty);
      }
    });

    test('recordingSuggestions tidak kosong untuk semua emosi', () {
      for (final e in EmotionType.values) {
        expect(e.recordingSuggestions, isNotEmpty,
            reason: 'Emosi ${e.name} harus punya saran');
      }
    });
  });

  group('TriggerTag extension', () {
    setUpAll(() => AppLocalizations.setLocale('id'));

    test('semua tag punya displayName dan emoji', () {
      for (final t in TriggerTag.values) {
        expect(t.displayName, isNotEmpty);
        expect(t.emoji, isNotEmpty);
      }
    });

    test('work => l10n trigger_work', () {
      expect(TriggerTag.work.displayName, AppLocalizations.tr('trigger_work'));
    });
  });

  group('EmotionRecord', () {
    test('formattedTime format "d MMM, HH:mm"', () {
      final rec = EmotionRecord(
        emotion: EmotionType.happy,
        confidence: 0.87,
        timestamp: DateTime(2024, 3, 5, 9, 30),
      );
      expect(rec.formattedTime, '5 Mar, 09:30');
    });

    test('confidencePercent bulat ke persen', () {
      final rec = EmotionRecord(
        emotion: EmotionType.happy,
        confidence: 0.872,
        timestamp: DateTime(2024, 3, 5, 9, 30),
      );
      expect(rec.confidencePercent, '87%');
    });

    test('emotionScore = emotionValue * confidence', () {
      final rec = EmotionRecord(
        emotion: EmotionType.happy,
        confidence: 0.5,
        timestamp: DateTime(2024),
      );
      expect(rec.emotionScore, 5.0);

      final neg = EmotionRecord(
        emotion: EmotionType.sad,
        confidence: 0.5,
        timestamp: DateTime(2024),
      );
      expect(neg.emotionScore, EmotionType.sad.emotionValue * 0.5);
    });

    test('emotionScoreLabel memakai 1 desimal + tanda +', () {
      final rec = EmotionRecord(
        emotion: EmotionType.happy,
        confidence: 0.5,
        timestamp: DateTime(2024),
      );
      expect(rec.emotionScoreLabel, '+5.0');

      final neg = EmotionRecord(
        emotion: EmotionType.sad,
        confidence: 0.5,
        timestamp: DateTime(2024),
      );
      expect(neg.emotionScoreLabel, '-3.0');
    });
  });

  group('computeMentalHealthAdjustment', () {
    test('dominan netral -> selalu 0 walau distribusi tidak murni netral', () {
      // Kasus nyata: servis teks mengembalikan {neutral:0.5, sisanya 0.1}.
      final scores = {
        EmotionType.happy: 0.052,
        EmotionType.sad: 0.052,
        EmotionType.angry: 0.052,
        EmotionType.disgust: 0.052,
        EmotionType.neutral: 0.74,
        EmotionType.fear: 0.052,
      };
      expect(
        computeMentalHealthAdjustment(scores, dominant: EmotionType.neutral),
        0.0,
      );
    });

    test('distribusi seragam dengan dominan netral -> 0', () {
      final uniform = {
        for (final e in EmotionType.values) e: 1 / EmotionType.values.length,
      };
      expect(
        computeMentalHealthAdjustment(uniform, dominant: EmotionType.neutral),
        0.0,
      );
    });

    test('dominan bukan netral -> jumlah berbobot semua emosi', () {
      final scores = {
        EmotionType.happy: 0.6,
        EmotionType.sad: 0.2,
        EmotionType.angry: 0.1,
        EmotionType.disgust: 0.0,
        EmotionType.neutral: 0.1,
        EmotionType.fear: 0.0,
      };
      final expected =
          10 * 0.6 + (-6) * 0.2 + (-8) * 0.1 + 0 * 0.0 + 0 * 0.1 + 0 * 0.0;
      expect(
        computeMentalHealthAdjustment(scores, dominant: EmotionType.happy),
        closeTo(expected, 1e-9),
      );
    });

    test('murni satu emosi -> sama dengan emotionValue penuh', () {
      final pure = {
        for (final e in EmotionType.values) e: e == EmotionType.sad ? 1.0 : 0.0,
      };
      expect(
        computeMentalHealthAdjustment(pure, dominant: EmotionType.sad),
        EmotionType.sad.emotionValue.toDouble(),
      );
    });
  });

  group('DummyData', () {
    test('latestEmotion valid', () {
      expect(DummyData.latestEmotion.confidence, inInclusiveRange(0.0, 1.0));
    });

    test('emotionHistory punya 10 record', () {
      expect(DummyData.emotionHistory, hasLength(10));
    });

    test('emotionFrequency menjumlah 6 emosi', () {
      expect(DummyData.emotionFrequency.length, 6);
      final total = DummyData.emotionFrequency.values.fold<int>(0, (a, b) => a + b);
      expect(total, 12);
    });

    test('detectionScores dinormalisasi', () {
      final sum = DummyData.detectionScores.values.fold<double>(0, (a, b) => a + b);
      expect(sum, closeTo(1.0, 0.01));
    });
  });
}
