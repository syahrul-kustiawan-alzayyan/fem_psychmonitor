import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fem_physicsmonitor/screens/settings_screen.dart';

import 'blackbox_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(initBlackboxEnvironment);

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(wrapBlackbox(child: const SettingsScreen()));
    await tester.pumpAndSettle();
  }

  Future<void> scrollToAndTap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('BB-S01 layar pengaturan menampilkan seluruh seksi dan menu',
      (WidgetTester tester) async {
    await pumpSettings(tester);

    expect(find.text('Pengaturan'), findsOneWidget);
    expect(find.text('PROFIL'), findsOneWidget);
    expect(find.text('UMUM'), findsOneWidget);
    expect(find.text('TENTANG'), findsOneWidget);
    expect(find.text('AKUN'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Bahasa'), findsOneWidget);
    expect(find.text('Tema Tampilan'), findsOneWidget);
    expect(find.text('Panduan Aplikasi'), findsOneWidget);
    expect(find.text('Syarat & Ketentuan'), findsOneWidget);
    expect(find.text('Backup Data'), findsOneWidget);
    expect(find.text('Restore Data'), findsOneWidget);
    expect(find.text('Hapus Akun & Data'), findsOneWidget);
    expect(find.text('Upgrade ke Premium'), findsOneWidget);
    expect(find.textContaining('Fem-Psych Monitor v2.1.5'), findsOneWidget);
  });

  testWidgets('BB-S02 switch tema ke Gelap mengubah ikon tema',
      (WidgetTester tester) async {
    await pumpSettings(tester);

    expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);

    await scrollToAndTap(tester, find.text('Gelap'));

    expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);
  });

  testWidgets('BB-S03 menu Panduan Aplikasi membuka lembar panduan',
      (WidgetTester tester) async {
    await pumpSettings(tester);

    await scrollToAndTap(tester, find.text('Panduan Aplikasi'));

    expect(find.text('Rekam Suaramu'), findsOneWidget);
    expect(find.text('Panduan Aplikasi'), findsWidgets);
  });

  testWidgets('BB-S04 menu Syarat & Ketentuan membuka lembar ketentuan',
      (WidgetTester tester) async {
    await pumpSettings(tester);

    await scrollToAndTap(tester, find.text('Syarat & Ketentuan'));

    expect(find.text('Syarat & Ketentuan'), findsWidgets);
  });

  testWidgets('BB-S05 status non-premium menampilkan menu upgrade',
      (WidgetTester tester) async {
    await pumpSettings(tester);

    expect(find.text('Upgrade ke Premium'), findsOneWidget);
    expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);
  });

  testWidgets('BB-S06 switch bahasa ID ke EN dan kembali mengubah label',
      (WidgetTester tester) async {
    await pumpSettings(tester);

    expect(find.text('Bahasa'), findsOneWidget);

    await scrollToAndTap(tester, find.text('EN'));

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Upgrade to Premium'), findsOneWidget);
    expect(find.text('Delete Account & Data'), findsOneWidget);
    expect(find.text('Terms & Conditions'), findsOneWidget);
    expect(find.text('Bahasa'), findsNothing);

    await scrollToAndTap(tester, find.text('ID'));

    expect(find.text('Bahasa'), findsOneWidget);
    expect(find.text('Upgrade ke Premium'), findsOneWidget);
  });
}
