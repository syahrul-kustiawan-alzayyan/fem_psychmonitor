import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fem_physicsmonitor/screens/onboarding_screen.dart';

import 'blackbox_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await rootBundle.loadString('assets/BigFive_MiniIPIP20.json');
    await rootBundle.loadString('assets/BigFive_MiniIPIP20_en.json');
    await rootBundle.loadString('assets/psych.json');
    await rootBundle.loadString('assets/psych_en.json');
  });

  setUp(() {
    initBlackboxEnvironment();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpOnboarding(WidgetTester tester) async {
    await tester.pumpWidget(wrapBlackbox(
      child: OnboardingScreen(onCompleted: _noop),
    ));
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  Future<void> tapCtaAndWaitForQuestion(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Mulai Sekarang'));
    await tester.pump();
    await tester.tap(find.text('Mulai Sekarang'));
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 200));
      if (find.textContaining('(1 / 20)').evaluate().isNotEmpty) return;
    }
  }

  Future<void> goToBigFiveQuestions(WidgetTester tester) async {
    await tapAndSettle(tester, find.text('Mulai Sekarang'));
    expect(find.text('Psikologi Big Five'), findsOneWidget);
    await tapCtaAndWaitForQuestion(tester);
    expect(find.textContaining('(1 / 20)'), findsOneWidget);
  }

  Future<void> answerBigFive(
    WidgetTester tester, {
    String label = 'Netral',
  }) async {
    for (var i = 0; i < 20; i++) {
      await tapAndSettle(tester, find.text(label));
    }
  }

  Future<void> answerPsy(WidgetTester tester, List<int> scores) async {
    await tester.ensureVisible(find.text('Mulai Asesmen'));
    await tester.pump();
    await tester.tap(find.text('Mulai Asesmen'));
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 200));
      if (find.textContaining('(1 / 20)').evaluate().isNotEmpty) break;
    }
    for (final score in scores) {
      await tapAndSettle(tester, find.text('$score'));
    }
  }

  Future<void> settleAsync(WidgetTester tester) async {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('BB-O01 alur kuesioner lengkap menampilkan hasil di layar',
      (WidgetTester tester) async {
    await pumpOnboarding(tester);

    expect(find.text('Mulai Sekarang'), findsOneWidget);

    await goToBigFiveQuestions(tester);
    await answerBigFive(tester, label: 'Netral');

    expect(find.text('Mulai Asesmen'), findsOneWidget);
    await answerPsy(tester, List.filled(20, 0));

    expect(find.text('Hasil Asesmen Anda'), findsOneWidget);
    expect(find.text('Skor Big Five Anda'), findsOneWidget);
    expect(find.text('Kesehatan Mental'), findsOneWidget);
    expect(find.text('100'), findsOneWidget);
    expect(find.text('/ 100'), findsOneWidget);
    expect(find.text('Baik'), findsOneWidget);
    expect(find.textContaining('Sedang'), findsNWidgets(5));
    expect(find.textContaining('Ekstraversi'), findsWidgets);
  });

  testWidgets('BB-O02 skor psikis pada batas atas kategori Baik (skor 77) '
      'ditampilkan sebagai Baik', (WidgetTester tester) async {
    await pumpOnboarding(tester);

    await goToBigFiveQuestions(tester);
    await answerBigFive(tester, label: 'Netral');

    await answerPsy(tester, List.generate(20, (i) => i < 14 ? 1 : 0));

    expect(find.text('Hasil Asesmen Anda'), findsOneWidget);
    expect(find.text('77'), findsOneWidget);
    expect(find.text('Baik'), findsOneWidget);
  });

  testWidgets('BB-O03 skor psikis di bawah ambang batas (skor 25) '
      'ditampilkan sebagai Butuh Perhatian', (WidgetTester tester) async {
    await pumpOnboarding(tester);

    await goToBigFiveQuestions(tester);
    await answerBigFive(tester, label: 'Netral');

    await answerPsy(tester, List.generate(20, (i) => i < 15 ? 3 : 0));

    expect(find.text('Hasil Asesmen Anda'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
    expect(find.text('Butuh Perhatian'), findsOneWidget);
  });

  testWidgets('BB-O04 switch bahasa pada halaman selamat datang mengubah '
      'seluruh teks dan kembali', (WidgetTester tester) async {
    await pumpOnboarding(tester);

    expect(find.text('Mulai Sekarang'), findsOneWidget);

    await tapAndSettle(tester, find.text('EN'));

    expect(find.text('Start Now'), findsOneWidget);
    expect(find.text('Already have an account?'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);

    await tapAndSettle(tester, find.text('ID'));

    expect(find.text('Mulai Sekarang'), findsOneWidget);
    expect(find.text('Sudah punya akun?'), findsOneWidget);

    await settleAsync(tester);
  });
}

void _noop() {}
