import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fem_physicsmonitor/screens/auth_screen.dart';

import 'blackbox_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(initBlackboxEnvironment);

  Future<void> pumpAuth(WidgetTester tester) async {
    await tester.pumpWidget(wrapBlackbox(child: const AuthScreen()));
    await tester.pumpAndSettle();
  }

  Finder masukButton() => find.widgetWithText(InkWell, 'Masuk');

  Finder privacyText() =>
      find.textContaining('Saya menyetujui', findRichText: true);

  Future<void> tapPrivacy(WidgetTester tester) async {
    await tester.ensureVisible(privacyText());
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getTopLeft(privacyText()) - const Offset(16, 0));
    await tester.pump();
  }

  Future<void> tapMasuk(WidgetTester tester) async {
    await tester.ensureVisible(masukButton());
    await tester.pumpAndSettle();
    await tester.tap(masukButton());
    await tester.pumpAndSettle();
  }

  Future<void> fillCredentials(
    WidgetTester tester, {
    required String email,
    required String password,
  }) async {
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), email);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), password);
  }

  testWidgets('BB-A01 formulir masuk menampilkan elemen input dan tombol',
      (WidgetTester tester) async {
    await pumpAuth(tester);

    expect(find.text('Fem-Psych Monitor'), findsOneWidget);
    expect(find.text('Masuk'), findsNWidgets(2));
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Lanjutkan dengan Google'), findsOneWidget);
    expect(find.text('atau'), findsOneWidget);
    expect(privacyText(), findsOneWidget);
  });

  testWidgets('BB-A02 tanpa persetujuan privasi, tombol Masuk menampilkan '
      'peringatan', (WidgetTester tester) async {
    await pumpAuth(tester);

    await tester.tap(masukButton());
    await tester.pump();

    expect(find.text('Centang kebijakan privasi terlebih dahulu'),
        findsOneWidget);
    expect(find.text('Email wajib diisi'), findsNothing);
  });

  testWidgets('BB-A03 dengan privasi disetujui tetapi formulir kosong, '
      'muncul error validasi', (WidgetTester tester) async {
    await pumpAuth(tester);

    await tapPrivacy(tester);
    await tapMasuk(tester);

    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Password wajib diisi'), findsOneWidget);
  });

  testWidgets('BB-A04 format email tidak valid ditolak validasi',
      (WidgetTester tester) async {
    await pumpAuth(tester);

    await tapPrivacy(tester);
    await fillCredentials(
        tester, email: 'bukanemail', password: 'rahasia123');
    await tapMasuk(tester);

    expect(find.text('Format email tidak valid'), findsOneWidget);
    expect(find.text('Minimal 6 karakter'), findsNothing);
  });

  testWidgets('BB-A05 password lima karakter (di bawah batas 6) ditolak',
      (WidgetTester tester) async {
    await pumpAuth(tester);

    await tapPrivacy(tester);
    await fillCredentials(
        tester, email: 'user@example.com', password: '12345');
    await tapMasuk(tester);

    expect(find.text('Minimal 6 karakter'), findsOneWidget);
    expect(find.text('Format email tidak valid'), findsNothing);
  });

  testWidgets('BB-A06 tanpa persetujuan privasi, tombol Google menampilkan '
      'peringatan', (WidgetTester tester) async {
    await pumpAuth(tester);

    await tester.ensureVisible(find.text('Lanjutkan dengan Google'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lanjutkan dengan Google'));
    await tester.pump();

    expect(find.text('Centang kebijakan privasi terlebih dahulu'),
        findsOneWidget);
  });

  testWidgets('BB-A07 ikon visibilitas password berubah saat diketuk',
      (WidgetTester tester) async {
    await pumpAuth(tester);

    expect(find.byIcon(Icons.visibility_off_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility_off_rounded));
    await tester.pump();

    expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);
  });
}
