import 'package:flutter_test/flutter_test.dart';

import 'package:fem_physicsmonitor/l10n/app_localizations.dart';
import 'package:fem_physicsmonitor/models/user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppUser', () {
    AppUser makeUser({int? psychScore, Map<String, double>? bigFive}) {
      return AppUser(
        name: 'Test User',
        bigFiveScores: bigFive ??
            const {'O': 4.0, 'C': 3.5, 'E': 2.0, 'A': 3.8, 'N': 2.4},
        psychologicalScore: psychScore,
        createdAt: DateTime(2024),
      );
    }

    test('constructor & copyWith', () {
      final u = makeUser(psychScore: 80);
      final u2 = u.copyWith(name: 'Nama Baru', psychologicalScore: 40);
      expect(u2.name, 'Nama Baru');
      expect(u2.psychologicalScore, 40);
      expect(u.name, 'Test User');
      expect(u.psychologicalScore, 80);
    });

    test('mentalHealthCategory mengikuti ambang batas', () {
      expect(makeUser(psychScore: null).mentalHealthCategory, 'Belum Dinilai');
      expect(makeUser(psychScore: 100).mentalHealthCategory, 'Sehat Optimal');
      expect(makeUser(psychScore: 76).mentalHealthCategory, 'Sehat Optimal');
      expect(makeUser(psychScore: 60).mentalHealthCategory, 'Cukup');
      expect(makeUser(psychScore: 51).mentalHealthCategory, 'Cukup');
      expect(makeUser(psychScore: 30).mentalHealthCategory, 'Rentan');
      expect(makeUser(psychScore: 26).mentalHealthCategory, 'Rentan');
      expect(makeUser(psychScore: 10).mentalHealthCategory, 'Butuh Perhatian Klinis');
    });

    test('deskripsi & saran tersedia untuk semua level', () {
      for (final s in [null, 100, 60, 30, 10]) {
        final u = makeUser(psychScore: s);
        expect(u.mentalHealthDescription, isNotEmpty);
        expect(u.mentalHealthAdvice, isNotEmpty);
      }
    });

    test('hasBigFive & summary', () {
      expect(makeUser().hasBigFive, isTrue);
      expect(makeUser().bigFiveSummary, contains('Openness'));
      final noBF = AppUser(name: 'X', bigFiveScores: {}, createdAt: DateTime(2024));
      expect(noBF.hasBigFive, isFalse);
      expect(noBF.bigFiveSummary, isEmpty);
    });

    test('bigFiveStrengths mencerminkan skor tinggi & neuroticism rendah', () {
      final strengths = makeUser().bigFiveStrengths;
      expect(strengths, isNotEmpty);
      // N = 2.4 < 2.5 => "Stabil Emosi"
      expect(strengths, contains('Stabil Emosi'));
    });

    test('bigFiveDescription bilingual', () {
      AppLocalizations.setLocale('id');
      expect(makeUser().bigFiveDescription, contains('Big Five'));
      AppLocalizations.setLocale('en');
      expect(makeUser().bigFiveDescription, contains('Big Five'));
      AppLocalizations.setLocale('id');
    });
  });

  group('calculateBigFive', () {
    List<BigFiveQuestion> buildQuestions() {
      // 4 pertanyaan per dimensi: 2 keyed '+', 2 keyed '-'
      final dims = ['O', 'C', 'E', 'A', 'N'];
      final qs = <BigFiveQuestion>[];
      var id = 1;
      for (final d in dims) {
        qs.add(BigFiveQuestion(
          questionId: id++, question: '$d-1', dimension: d, dimensionName: d, keyed: '+'));
        qs.add(BigFiveQuestion(
          questionId: id++, question: '$d-2', dimension: d, dimensionName: d, keyed: '+'));
        qs.add(BigFiveQuestion(
          questionId: id++, question: '$d-3', dimension: d, dimensionName: d, keyed: '-'));
        qs.add(BigFiveQuestion(
          questionId: id++, question: '$d-4', dimension: d, dimensionName: d, keyed: '-'));
      }
      return qs;
    }

    test('menghitung rata-rata per dimensi', () {
      final qs = buildQuestions();
      // Untuk 'O': 4, 4, dan keyed '-' (5 -> 1), (1 -> 5)
      final answers = List<int>.filled(20, 3);
      // O index 0..3
      answers[0] = 4; // O+ -> 4
      answers[1] = 4; // O+ -> 4
      answers[2] = 5; // O- -> 6-5=1
      answers[3] = 1; // O- -> 6-1=5
      // mean O = (4+4+1+5)/4 = 3.5
      final scores = calculateBigFive(answers, qs);
      expect(scores['O'], closeTo(3.5, 0.001));
    });

    test('reverse scoring keyed - benar', () {
      final qs = buildQuestions();
      final answers = List<int>.filled(20, 3);
      answers[0] = 1; // O+ low
      answers[2] = 1; // O- high (6-1=5)
      final scores = calculateBigFive(answers, qs);
      // O = (1 + 3 + 5 + 3)/4 = 3.0
      expect(scores['O'], closeTo(3.0, 0.001));
    });

    test('mengembalikan 5 dimensi', () {
      final scores = calculateBigFive(List.filled(20, 3), buildQuestions());
      expect(scores.keys, containsAll(['O', 'C', 'E', 'A', 'N']));
    });
  });

  group('BigFiveQuestion.fromJson', () {
    test('mengurai json', () {
      final q = BigFiveQuestion.fromJson({
        'id': 1,
        'dimension': 'E',
        'dimension_name': 'Extraversion',
        'keyed': '+',
        'statement': 'Pernyataan',
      });
      expect(q.question, 'Pernyataan');
      expect(q.dimension, 'E');
      expect(q.keyed, '+');
    });
  });

  group('PsyQuestion.fromJson', () {
    test('mengurai json beserta opsi', () {
      final q = PsyQuestion.fromJson({
        'id': 1,
        'category': 'Stres',
        'question': 'Pertanyaan?',
        'options': [
          {'answer': 'Tidak', 'score': 0},
          {'answer': 'Ya', 'score': 3},
        ],
      });
      expect(q.options, hasLength(2));
      expect(q.options[0].score, 0);
      expect(q.options[1].score, 3);
    });
  });
}
