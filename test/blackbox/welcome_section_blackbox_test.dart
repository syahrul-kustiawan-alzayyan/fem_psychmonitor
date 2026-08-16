import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fem_physicsmonitor/screens/onboarding/welcome_section.dart';

import 'blackbox_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(initBlackboxEnvironment);

  Future<void> pumpWelcome(WidgetTester tester) async {
    await tester.pumpWidget(wrapBlackbox(
      child: const Scaffold(body: WelcomeSection(onNext: _noop)),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('BB-W01 layar selamat datang menampilkan elemen utama',
      (WidgetTester tester) async {
    await pumpWelcome(tester);

    expect(find.text('Fem-Psych'), findsOneWidget);
    expect(find.text('Monitor'), findsOneWidget);
    expect(find.text('Mulai Sekarang'), findsOneWidget);
    expect(find.text('Sudah punya akun?'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('ID'), findsOneWidget);
    expect(find.text('EN'), findsOneWidget);
  });

  testWidgets('BB-W02 tautan Masuk berpindah ke layar masuk',
      (WidgetTester tester) async {
    await pumpWelcome(tester);

    await tester.ensureVisible(find.text('Masuk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Fem-Psych Monitor'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Lanjutkan dengan Google'), findsOneWidget);
  });
}

void _noop() {}
