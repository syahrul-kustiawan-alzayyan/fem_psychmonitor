import 'package:flutter_test/flutter_test.dart';

import 'package:fem_physicsmonitor/l10n/app_localizations.dart';
import 'package:fem_physicsmonitor/models/emotion_model.dart';
import 'package:fem_physicsmonitor/services/text_emotion_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    AppLocalizations.setLocale('id');
    await TextEmotionService.instance.loadAll();
  });

  group('TextEmotionService', () {
    test('teks kosong mengembalikan profil default', () {
      final result = TextEmotionService.instance.analyze('');
      expect(result[EmotionType.neutral], 0.5);
      expect(result[EmotionType.happy], 0.1);
    });

    test('teks happy terdeteksi sebagai happy dominan', () {
      final result = TextEmotionService.instance.analyze(
        'Hari ini aku sangat bahagia, senang dan puas sekali!',
      );
      final dominant = result.entries.reduce((a, b) => a.value >= b.value ? a : b);
      expect(dominant.key, EmotionType.happy);
      expect(result[EmotionType.happy], greaterThan(0.5));
    });

    test('teks sedih terdeteksi sebagai sad dominan', () {
      final result = TextEmotionService.instance.analyze(
        'Aku merasa sedih dan kecewa, hatiku pilu',
      );
      final dominant = result.entries.reduce((a, b) => a.value >= b.value ? a : b);
      expect(dominant.key, EmotionType.sad);
    });

    test('teks marah terdeteksi sebagai angry', () {
      final result = TextEmotionService.instance.analyze(
        'Aku marah sekali, kesal dan benci',
      );
      final dominant = result.entries.reduce((a, b) => a.value >= b.value ? a : b);
      expect(dominant.key, EmotionType.angry);
    });

    test('teks takut terdeteksi sebagai fear', () {
      final result = TextEmotionService.instance.analyze(
        'Aku takut, khawatir dan cemas berlebihan',
      );
      final dominant = result.entries.reduce((a, b) => a.value >= b.value ? a : b);
      expect(dominant.key, EmotionType.fear);
    });

    test('kata majemuk (2 kata) dihitung ganda', () {
      final result = TextEmotionService.instance.analyze('terima kasih banyak');
      final happy = result[EmotionType.happy] ?? 0;
      expect(happy, greaterThan(0.1));
    });

    test('hasil selalu ternormalisasi menjadi total 1.0', () {
      final result = TextEmotionService.instance.analyze(
        'bahagia sedih marah takut jijik netral senang cemas',
      );
      final total = result.values.fold<double>(0, (a, b) => a + b);
      expect(total, closeTo(1.0, 0.001));
    });

    test('mendukung keyword bahasa inggris', () {
      final result = TextEmotionService.instance.analyze(
        'I am so happy and excited today',
      );
      final dominant = result.entries.reduce((a, b) => a.value >= b.value ? a : b);
      expect(dominant.key, EmotionType.happy);
    });
  });
}
