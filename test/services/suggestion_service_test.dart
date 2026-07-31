import 'package:flutter_test/flutter_test.dart';

import 'package:fem_physicsmonitor/l10n/app_localizations.dart';
import 'package:fem_physicsmonitor/models/emotion_model.dart';
import 'package:fem_physicsmonitor/services/suggestion_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = SuggestionService();

  setUp(() async {
    AppLocalizations.setLocale('id');
    service.reset();
    await service.load();
    expect(service.isLoaded, isTrue);
  });

  Map<String, double> scores({
    double o = 3.0,
    double c = 3.0,
    double e = 3.0,
    double a = 3.0,
    double n = 3.0,
  }) {
    return {'O': o, 'C': c, 'E': e, 'A': a, 'N': n};
  }

  group('SuggestionService.getStructuredSuggestions', () {
    test('profil netral -> saran default (Profil Seimbang)', () {
      final result = service.getStructuredSuggestions(
        scores(),
        EmotionType.sad,
      );
      expect(result.traitSuggestions, hasLength(1));
      expect(result.traitSuggestions.first.trait, '-');
      expect(result.traitSuggestions.first.suggestions, isNotEmpty);
      expect(result.isSafetyReferral, isFalse);
    });

    test('trait ekstrem menghasilkan saran per trait', () {
      // O sangat tinggi (4.5), lainnya netral
      final result = service.getStructuredSuggestions(
        scores(o: 4.5),
        EmotionType.happy,
      );
      expect(result.traitSuggestions, isNotEmpty);
      final traits = result.traitSuggestions.map((t) => t.trait).toList();
      expect(traits, contains('O'));
    });

    test('trait rendah (2.2) masuk sebagai low', () {
      final result = service.getStructuredSuggestions(
        scores(n: 2.2),
        EmotionType.fear,
      );
      final nTrait = result.traitSuggestions.where((t) => t.trait == 'N');
      expect(nTrait, isNotEmpty);
      expect(nTrait.first.level, 'Rendah');
    });

    test('setiap trait saran max 2', () {
      // Semua ekstrem
      final result = service.getStructuredSuggestions(
        scores(o: 1.2, c: 4.8, e: 1.5, a: 4.5, n: 1.8),
        EmotionType.angry,
      );
      for (final t in result.traitSuggestions) {
        expect(t.suggestions.length, lessThanOrEqualTo(2));
      }
      expect(result.traitSuggestions, isNotEmpty);
    });

    test('allSuggestions & firstSuggestion konsisten', () {
      final result = service.getStructuredSuggestions(
        scores(o: 4.5, n: 2.0),
        EmotionType.happy,
      );
      expect(result.allSuggestions, isNotEmpty);
      expect(result.firstSuggestion, result.allSuggestions.first);
    });

    test('getSuggestions (backward compat) mengembalikan flat list', () {
      final list = service.getSuggestions(scores(o: 4.5), EmotionType.sad);
      expect(list, isA<List<String>>());
    });

    test('buildTitle menyebut emosi', () {
      final title = service.buildTitle(scores(o: 4.5), EmotionType.sad);
      expect(title, contains(EmotionType.sad.displayName));
    });

    test('getDominantDimension mengembalikan nilai tertinggi', () {
      expect(service.getDominantDimension(scores(o: 4.5)), 'O');
      expect(service.getDominantDimension({}), isEmpty);
    });
  });

  group('SuggestionService.getSafetyData', () {
    test('mengembalikan rujukan keselamatan', () async {
      final safety = await service.getSafetyData();
      expect(safety, isNotNull);
      expect(safety!.isSafetyReferral, isTrue);
      expect(safety.safetyMessage, isNotNull);
      expect(safety.safetyActions, isNotNull);
      expect(safety.safetyActions, isNotEmpty);
    });
  });
}
