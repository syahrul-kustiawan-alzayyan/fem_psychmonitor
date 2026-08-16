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

  Finder masukButton() => find.byKey(const ValueKey('loginButton'));

  Finder registerButton() => find.byKey(const ValueKey('registerButton'));

  Finder loginTab() => find.byKey(const ValueKey('authModeTabLogin'));

  Finder registerTab() => find.byKey(const ValueKey('authModeTabRegister'));

  Finder privacyText() =>
      find.textContaining('Saya menyetujui', findRichText: true);

  Future<void> scrollIntoView(WidgetTester tester, Finder finder) async {
    final context = tester.element(finder);
    await Scrollable.ensureVisible(context, alignment: 0.5);
    await tester.pump();
  }

  Future<void> tapPrivacy(WidgetTester tester) async {
    await scrollIntoView(tester, privacyText());
    await tester.tapAt(tester.getTopLeft(privacyText()) - const Offset(16, 0));
    await tester.pump();
  }

  Future<void> tapMasuk(WidgetTester tester) async {
    await scrollIntoView(tester, masukButton());
    await tester.tap(masukButton());
    await tester.pumpAndSettle();
  }

  Future<void> openRegister(WidgetTester tester) async {
    await scrollIntoView(tester, registerTab());
    await tester.tap(registerTab());
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

    await tapMasuk(tester);

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

    await scrollIntoView(tester, find.text('Lanjutkan dengan Google'));
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

  testWidgets('BB-A08 modul daftar menampilkan elemen input dan tombol',
      (WidgetTester tester) async {
    await pumpAuth(tester);

    await openRegister(tester);

    expect(find.text('Buat Akun Baru'), findsOneWidget);
    expect(find.text('Daftar'), findsNWidgets(2)); // tab + tombol
    expect(find.text('Nama Lengkap'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Konfirmasi Password'), findsOneWidget);
    expect(find.text('Lanjutkan dengan Google'), findsOneWidget);
    expect(privacyText(), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget); // hanya tab
  });

  testWidgets('BB-A09 daftar tanpa persetujuan privasi menampilkan peringatan',
      (WidgetTester tester) async {
    await pumpAuth(tester);

    await openRegister(tester);
    await scrollIntoView(tester, registerButton());
    await tester.tap(registerButton());
    await tester.pump();

    expect(find.text('Centang kebijakan privasi terlebih dahulu'),
        findsOneWidget);
  });

  testWidgets('BB-A10 daftar dengan privasi disetujui tetapi formulir kosong, '
      'muncul error validasi', (WidgetTester tester) async {
    await pumpAuth(tester);

    await openRegister(tester);
    await tapPrivacy(tester);
    await scrollIntoView(tester, registerButton());
    await tester.tap(registerButton());
    await tester.pump();

    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Password wajib diisi'), findsOneWidget);
    expect(find.text('Konfirmasi password wajib diisi'), findsOneWidget);
  });

  testWidgets('BB-A11 konfirmasi password tidak cocok ditolak validasi',
      (WidgetTester tester) async {
    await pumpAuth(tester);

    await openRegister(tester);
    await tapPrivacy(tester);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'user@example.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'rahasia123');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Konfirmasi Password'), 'beda456');

    await scrollIntoView(tester, registerButton());
    await tester.tap(registerButton());
    await tester.pump();

    expect(find.text('Password tidak cocok'), findsOneWidget);
  });

  testWidgets('BB-A12 toggle modul kembali ke masuk mempertahankan formulir',
      (WidgetTester tester) async {
    await pumpAuth(tester);

    await openRegister(tester);
    expect(find.text('Konfirmasi Password'), findsOneWidget);

    await scrollIntoView(tester, loginTab());
    await tester.tap(loginTab());
    await tester.pumpAndSettle();

    expect(find.text('Selamat Datang Kembali'), findsOneWidget);
    expect(find.text('Konfirmasi Password'), findsNothing);
    expect(masukButton(), findsOneWidget);
  });
}
