import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fem_physicsmonitor/l10n/app_localizations.dart';
import 'package:fem_physicsmonitor/screens/onboarding/welcome_section.dart';

import '../helpers/test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    initTestEnvironment();
    AppLocalizations.setLocale('id');
  });

  testWidgets('WelcomeSection menampilkan tombol mulai', (WidgetTester tester) async {
    var nextCalled = false;
    await tester.pumpWidget(wrapWithProviders(
      child: Scaffold(
        body: WelcomeSection(onNext: () => nextCalled = true),
      ),
    ));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text(AppLocalizations.tr('start_now')), findsOneWidget);
  });

  testWidgets('tap tombol mulai memanggil onNext', (WidgetTester tester) async {
    var nextCalled = false;
    await tester.pumpWidget(wrapWithProviders(
      child: Scaffold(
        body: WelcomeSection(onNext: () => nextCalled = true),
      ),
    ));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    await tester.ensureVisible(find.text(AppLocalizations.tr('start_now')));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.tap(find.text(AppLocalizations.tr('start_now')));
    expect(nextCalled, isTrue);
  });

  testWidgets('toggle bahasa ID <-> EN mengganti teks', (WidgetTester tester) async {
    await tester.pumpWidget(wrapWithProviders(
      child: Scaffold(
        body: WelcomeSection(onNext: () {}),
      ),
    ));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    final idWelcome = AppLocalizations.tr('welcome_desc');

    // Tap EN
    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(AppLocalizations.locale, 'en');
    expect(AppLocalizations.tr('welcome_desc'), isNot(idWelcome));

    // Tap ID kembali
    await tester.tap(find.text('ID'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(AppLocalizations.locale, 'id');
  });
}
