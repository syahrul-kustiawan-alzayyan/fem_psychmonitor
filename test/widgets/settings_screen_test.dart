import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fem_physicsmonitor/l10n/app_localizations.dart';
import 'package:fem_physicsmonitor/screens/settings_screen.dart';

import '../helpers/test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    initTestEnvironment();
    AppLocalizations.setLocale('id');
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(wrapWithProviders(child: const SettingsScreen()));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  }

  testWidgets('SettingsScreen menampilkan semua section', (WidgetTester tester) async {
    await pumpSettings(tester);

    expect(find.text(AppLocalizations.tr('settings_title')), findsOneWidget);
    expect(find.text(AppLocalizations.tr('language')), findsOneWidget);
    expect(find.text(AppLocalizations.tr('theme_mode')), findsOneWidget);
    expect(find.text(AppLocalizations.tr('profile_menu')), findsWidgets);
    expect(find.text(AppLocalizations.tr('app_guide')), findsOneWidget);
    expect(find.text(AppLocalizations.tr('terms_services')), findsOneWidget);
    expect(find.text(AppLocalizations.tr('backup_data')), findsOneWidget);
    expect(find.text(AppLocalizations.tr('delete_account_data')), findsOneWidget);
    expect(find.textContaining('v2.1.0'), findsOneWidget);
  });

  testWidgets('switch bahasa ID -> EN mengubah label', (WidgetTester tester) async {
    await pumpSettings(tester);

    expect(find.text('Bahasa'), findsOneWidget);

    // Segmen "EN"
    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(AppLocalizations.locale, 'en');
    expect(find.text('Language'), findsOneWidget);
  });

  testWidgets('switch tema Light -> Dark mengubah ikon tema',
      (WidgetTester tester) async {
    await pumpSettings(tester);

    // Awal: light -> ikon light_mode
    expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);

    await tester.tap(find.text(AppLocalizations.tr('theme_dark')));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    // Setelah dark -> ikon dark_mode
    expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);
  });

  testWidgets('tile upgrade premium muncul saat non-premium',
      (WidgetTester tester) async {
    await pumpSettings(tester);

    expect(find.text('Upgrade ke Premium'), findsOneWidget);
    expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);
  });

  testWidgets('tap panduan membuka bottom sheet', (WidgetTester tester) async {
    await pumpSettings(tester);

    await tester.ensureVisible(find.text(AppLocalizations.tr('app_guide')));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.tap(find.text(AppLocalizations.tr('app_guide')));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text(AppLocalizations.tr('guide_title')), findsWidgets);
  });
}
