import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fem_physicsmonitor/l10n/app_localizations.dart';
import 'package:fem_physicsmonitor/models/emotion_model.dart';
import 'package:fem_physicsmonitor/models/user_model.dart';
import 'package:fem_physicsmonitor/screens/onboarding/onboarding_state.dart';
import 'package:fem_physicsmonitor/services/pdf_export_service.dart';
import 'package:fem_physicsmonitor/services/suggestion_service.dart';
import 'package:fem_physicsmonitor/services/text_emotion_service.dart';

/// Kasus uji whitebox tambahan — menutup celah statement coverage yang
/// belum tercakup oleh suite uji utama (basis path / branch testing).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tambah: EmotionType — semua cabang switch', () {
    setUpAll(() => AppLocalizations.setLocale('id'));

    test('displayName untuk semua 6 emosi', () {
      for (final e in EmotionType.values) {
        expect(e.displayName, AppLocalizations.tr('emotion_${e.name}'));
      }
    });

    test('color tersedia untuk semua emosi', () {
      for (final e in EmotionType.values) {
        expect(e.color, isA<Color>());
      }
    });
  });

  group('Tambah: AppUser — cabang copyWith & Big Five tanpa skor', () {
    test('copyWith tanpa argumen memakai nilai asli (fallback ?? semua)', () {
      final u = AppUser(
        name: 'Test User',
        bigFiveScores: const {'O': 4.0},
        psychologicalScore: 80,
        createdAt: DateTime(2024),
      );
      final u2 = u.copyWith();
      expect(u2.name, 'Test User');
      expect(u2.psychologicalScore, 80);
      expect(u2.bigFiveScores, {'O': 4.0});
      expect(u2.createdAt, DateTime(2024));
    });

    test('deskripsi & strengths tanpa Big Five bilingual', () {
      final noBF = AppUser(name: 'X', bigFiveScores: {}, createdAt: DateTime(2024));

      AppLocalizations.setLocale('en');
      expect(noBF.bigFiveDescription, contains('Big Five'));
      expect(noBF.bigFiveStrengths, contains('Adaptive'));

      AppLocalizations.setLocale('id');
      expect(noBF.bigFiveStrengths, contains('Adaptif'));
    });

    test('strengths mencakup dimensi E tinggi (id & en)', () {
      final u = AppUser(
        name: 'X',
        bigFiveScores: {'O': 2.0, 'C': 2.0, 'E': 4.0, 'A': 2.0, 'N': 3.5},
        createdAt: DateTime(2024),
      );

      AppLocalizations.setLocale('id');
      expect(u.bigFiveStrengths, contains('Energik & Sosial'));

      AppLocalizations.setLocale('en');
      expect(u.bigFiveStrengths, contains('Energetic & Outgoing'));

      AppLocalizations.setLocale('id');
    });

    test('strengths kosong -> fallback adaptif (id & en)', () {
      final u = AppUser(
        name: 'X',
        bigFiveScores: {'O': 2.0, 'C': 2.0, 'E': 2.0, 'A': 2.0, 'N': 3.5},
        createdAt: DateTime(2024),
      );

      AppLocalizations.setLocale('id');
      expect(u.bigFiveStrengths, contains('Adaptif'));

      AppLocalizations.setLocale('en');
      expect(u.bigFiveStrengths, contains('Adaptive'));

      AppLocalizations.setLocale('id');
    });
  });

  group('Tambah: TextEmotionService — teks tanpa kata kunci', () {
    setUp(() async {
      AppLocalizations.setLocale('id');
      await TextEmotionService.instance.loadAll();
    });

    test('teks non-kosong tanpa kata kunci -> profil default', () {
      final result = TextEmotionService.instance.analyze('xyzqwjq');
      expect(result[EmotionType.neutral], 0.5);
      expect(result[EmotionType.happy], 0.1);
    });
  });

  group('Tambah: SuggestionService — cabang defensif & backward compat', () {
    final service = SuggestionService();

    setUp(() async {
      AppLocalizations.setLocale('id');
      service.reset();
      await service.load();
      expect(service.isLoaded, isTrue);
    });

    test('SuggestionResult.isEmpty & firstSuggestion kosong', () {
      final r = SuggestionResult(
        emotion: EmotionType.sad,
        traitSuggestions: const [],
      );
      expect(r.isEmpty, isTrue);
      expect(r.firstSuggestion, '');

      final r2 = SuggestionResult(
        emotion: EmotionType.sad,
        traitSuggestions: const [],
        isSafetyReferral: true,
      );
      expect(r2.isEmpty, isFalse);
    });

    test('trait tidak dikenal diabaikan (dimData null)', () {
      final result = service.getStructuredSuggestions(
        {'X': 4.8, 'O': 3.0, 'C': 3.0, 'E': 3.0, 'A': 3.0, 'N': 3.0},
        EmotionType.sad,
      );
      expect(result.traitSuggestions, isEmpty);
    });

    test('getFirstSuggestion mengembalikan saran pertama non-kosong', () {
      final first = service.getFirstSuggestion(
        const {'O': 4.5, 'C': 3.0, 'E': 3.0, 'A': 3.0, 'N': 3.0},
        EmotionType.happy,
      );
      expect(first, isNotEmpty);

      // Kasus tanpa saran -> string kosong
      final empty = service.getFirstSuggestion(const {'X': 4.8}, EmotionType.sad);
      expect(empty, '');
    });

    test('buildTitle skor kosong (id & en)', () {
      AppLocalizations.setLocale('en');
      expect(
        service.buildTitle({}, EmotionType.sad),
        'Suggestions for ${EmotionType.sad.displayName}',
      );

      AppLocalizations.setLocale('id');
      expect(
        service.buildTitle({}, EmotionType.sad),
        'Saran untuk ${EmotionType.sad.displayName}',
      );
    });

    test('buildTitle trait tidak dikenal -> fallback judul (id & en)', () {
      AppLocalizations.setLocale('en');
      expect(
        service.buildTitle({'X': 4.8}, EmotionType.sad),
        'Suggestions for ${EmotionType.sad.displayName}',
      );

      AppLocalizations.setLocale('id');
      expect(
        service.buildTitle({'X': 4.8}, EmotionType.sad),
        'Saran untuk ${EmotionType.sad.displayName}',
      );
    });
  });

  group('Tambah: PdfExportService — kategori & tanggal', () {
    test('generateUserReport mencakup semua kategori skor', () async {
      for (final score in [60, 30, 10]) {
        final user = {
          'name': 'X',
          'email': 'x@x.com',
          'psych_score': score,
          'created_at': '2023-04-15T08:00:00',
        };
        final bytes = await PdfExportService.generateUserReport(user, []);
        expect(bytes, isNotEmpty);
        expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
      }
    });

    test('created_at non-Timestamp -> fallback DateTime.now()', () async {
      final user = {
        'name': 'X',
        'email': 'x@x.com',
        'psych_score': 80,
        'created_at': '2024-01-01',
      };
      final bytes = await PdfExportService.generateUserReport(user, []);
      expect(bytes, isNotEmpty);
    });
  });

  group('Tambah: jalur error (asset gagal dimuat)', () {
    const assetChannel = MethodChannel('flutter/assets');

    Future<void> mockAssetFailure() async {
      TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger
          .setMockMethodCallHandler(assetChannel, (call) async {
        throw PlatformException(code: 'mock_asset_fail');
      });
    }

    Future<void> clearMock() async {
      TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger
          .setMockMethodCallHandler(assetChannel, null);
    }

    test('SuggestionService.load gagal -> fallback kosong, saran aman', () async {
      AppLocalizations.setLocale('id');
      // Bypass cache agar load() benar-benar memuat ulang dari channel.
      (rootBundle as CachingAssetBundle).evict('assets/saran_bigfive_v2.json');
      (rootBundle as CachingAssetBundle).evict('assets/saran_bigfive.json');

      final service = SuggestionService();
      service.reset();
      await mockAssetFailure();
      addTearDown(clearMock);

      await service.load();
      expect(service.isLoaded, isTrue);
      expect(
        service
            .getStructuredSuggestions(
              const {'O': 4.5, 'C': 3.0, 'E': 3.0, 'A': 3.0, 'N': 3.0},
              EmotionType.sad,
            )
            .traitSuggestions,
        isEmpty,
      );
    });

    test('OnboardingState.loadQuestions gagal -> isLoading false', () async {
      AppLocalizations.setLocale('id');
      await mockAssetFailure();
      addTearDown(clearMock);

      final state = OnboardingState();
      await state.loadQuestions();
      expect(state.isLoading, isFalse);
    });
  });
}
