import 'package:flutter_test/flutter_test.dart';

import 'package:fem_physicsmonitor/l10n/app_localizations.dart';
import 'package:fem_physicsmonitor/screens/onboarding/onboarding_state.dart';

/// Konversi skor psy mentah (0-60, rendah = baik) ke skor tampilan 0-100.
/// Logika sama dengan OnboardingScreen.savePendingOnboardingToFirestore.
int displayScore(int rawPsyScore) => ((60 - rawPsyScore) / 60 * 100).round();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AppLocalizations.setLocale('id');
  });

  group('OnboardingState.loadQuestions', () {
    test('memuat 20 pertanyaan Big Five & psy dari aset', () async {
      final state = OnboardingState();
      await state.loadQuestions();

      expect(state.isLoading, isFalse);
      expect(state.bigFiveQuestions, hasLength(20));
      expect(state.psyQuestions, hasLength(20));
      expect(state.bigFiveAnswers, hasLength(20));
      expect(state.psyAnswers, hasLength(20));
    });

    test('semua jawaban null -> belum lengkap', () async {
      final state = OnboardingState();
      await state.loadQuestions();
      expect(state.isBigFiveComplete, isFalse);
      expect(state.isPsyComplete(), isFalse);
    });

    test('keyed Big Five terisi + dan -', () async {
      final state = OnboardingState();
      await state.loadQuestions();
      final keyed = state.bigFiveQuestions.map((q) => q.keyed).toSet();
      expect(keyed, contains('+'));
      expect(keyed, contains('-'));
    });

    test('opsi psy berskor 0-3', () async {
      final state = OnboardingState();
      await state.loadQuestions();
      final q = state.psyQuestions.first;
      expect(q.options, isNotEmpty);
      expect(q.options.first.score, inInclusiveRange(0, 3));
    });
  });

  group('OnboardingState — workflow scoring', () {
    test('Big Five: jawab semua -> hasil 5 dimensi 1-5', () async {
      final state = OnboardingState();
      await state.loadQuestions();

      for (var i = 0; i < state.bigFiveAnswers.length; i++) {
        state.setBigFiveAnswer(i, (i % 5) + 1);
      }
      expect(state.isBigFiveComplete, isTrue);

      state.calculateBigFiveResult();
      expect(state.bigFiveScores.keys, containsAll(['O', 'C', 'E', 'A', 'N']));
      for (final score in state.bigFiveScores.values) {
        expect(score, inInclusiveRange(1.0, 5.0));
      }
    });

    test('Psy: jawab semua -> psyScore = jumlah skor opsi', () async {
      final state = OnboardingState();
      await state.loadQuestions();

      for (var i = 0; i < state.psyAnswers.length; i++) {
        // pilih opsi terakhir (skor 3) untuk semua -> 20*3 = 60
        state.setPsyAnswer(i, 3);
      }
      expect(state.isPsyComplete(), isTrue);

      state.calculatePsyResult();
      expect(state.psyScore, 60);
      // skor tampilan terburuk = 0
      expect(displayScore(state.psyScore), 0);
    });

    test('jawaban psy semua 0 -> skor tampilan terbaik 100', () async {
      final state = OnboardingState();
      await state.loadQuestions();
      for (var i = 0; i < state.psyAnswers.length; i++) {
        state.setPsyAnswer(i, 0);
      }
      state.calculatePsyResult();
      expect(state.psyScore, 0);
      expect(displayScore(state.psyScore), 100);
    });

    test('kombinasi skor psy -> kategori benar', () {
      expect(displayScore(0), 100);
      expect(displayScore(9), 85);   // >= 76 => Sehat Optimal
      expect(displayScore(20), 67);  // >= 51 => Cukup
      expect(displayScore(35), 42);  // >= 26 => Rentan
      expect(displayScore(48), 20);  // < 26 => Butuh Perhatian
      expect(displayScore(60), 0);
    });

    test('setSaving mengontrol flag isSaving', () {
      final state = OnboardingState();
      state.setSaving(true);
      expect(state.isSaving, isTrue);
      state.setSaving(false);
      expect(state.isSaving, isFalse);
    });
  });
}
