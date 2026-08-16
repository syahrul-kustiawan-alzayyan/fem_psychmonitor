import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fem_physicsmonitor/l10n/app_localizations.dart';
import 'package:fem_physicsmonitor/screens/auth_screen.dart';

import '../helpers/test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    initTestEnvironment();
    AppLocalizations.setLocale('id');
  });

  Future<void> pumpAuth(WidgetTester tester) async {
    await tester.pumpWidget(wrapWithProviders(child: const AuthScreen()));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  }

  Finder masukButton() => find.byKey(const ValueKey('loginButton'));

  Finder registerButton() => find.byKey(const ValueKey('registerButton'));

  Finder registerTab() => find.byKey(const ValueKey('authModeTabRegister'));

  Finder loginTab() => find.byKey(const ValueKey('authModeTabLogin'));

  Finder privacyCheckbox() =>
      find.textContaining('Saya menyetujui', findRichText: true);

  Future<void> scrollIntoView(WidgetTester tester, Finder finder) async {
    final context = tester.element(finder);
    await Scrollable.ensureVisible(context, alignment: 0.5);
    await tester.pump();
  }

  Future<void> checkPrivacy(WidgetTester tester) async {
    await scrollIntoView(tester, privacyCheckbox());
    final checkbox = find.descendant(
      of: find
          .ancestor(of: privacyCheckbox(), matching: find.byType(GestureDetector))
          .first,
      matching: find.byType(AnimatedContainer),
    );
    await tester.tap(checkbox, warnIfMissed: false);
    await tester.pump();
  }

  Future<void> tapMasuk(WidgetTester tester) async {
    await scrollIntoView(tester, masukButton());
    await tester.tap(masukButton());
    await tester.pumpAndSettle();
  }

  Finder passwordTextField(WidgetTester tester) => find.descendant(
        of: find.widgetWithText(TextFormField, 'Password'),
        matching: find.byType(TextField),
      );

  testWidgets('AuthScreen menampilkan form login', (WidgetTester tester) async {
    await pumpAuth(tester);

    expect(find.text('Fem-Psych Monitor'), findsOneWidget);
    expect(find.text('Masuk'), findsNWidgets(2)); // heading + tombol
    expect(find.text('Lanjutkan dengan Google'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });

  testWidgets('tanpa centang privasi -> muncul snackbar peringatan',
      (WidgetTester tester) async {
    await pumpAuth(tester);

    await tapMasuk(tester);

    expect(find.text('Centang kebijakan privasi terlebih dahulu'), findsOneWidget);
  });

  testWidgets('centang privasi + submit kosong -> error validasi',
      (WidgetTester tester) async {
    await pumpAuth(tester);

    await checkPrivacy(tester);
    await tapMasuk(tester);

    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Password wajib diisi'), findsOneWidget);
  });

  testWidgets('email tidak valid -> error format', (WidgetTester tester) async {
    await pumpAuth(tester);

    await checkPrivacy(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'bukanemail');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'rahasia123');
    await tapMasuk(tester);

    expect(find.text('Format email tidak valid'), findsOneWidget);
  });

  testWidgets('password terlalu pendek -> error minimal 6 karakter',
      (WidgetTester tester) async {
    await pumpAuth(tester);

    await checkPrivacy(tester);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'user@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), '123');
    await tapMasuk(tester);

    expect(find.text('Minimal 6 karakter'), findsOneWidget);
  });

  testWidgets('toggle visibilitas password', (WidgetTester tester) async {
    await pumpAuth(tester);

    expect(
      tester.widget<TextField>(passwordTextField(tester)).obscureText,
      isTrue,
    );

    await tester.tap(find.byIcon(Icons.visibility_off_rounded));
    await tester.pump();
    expect(
      tester.widget<TextField>(passwordTextField(tester)).obscureText,
      isFalse,
    );
  });

  testWidgets('AuthScreen menampilkan form daftar saat tab Daftar dipilih',
      (WidgetTester tester) async {
    await pumpAuth(tester);

    await scrollIntoView(tester, registerTab());
    await tester.tap(registerTab());
    await tester.pumpAndSettle();

    expect(find.text('Buat Akun Baru'), findsOneWidget);
    expect(find.text('Nama Lengkap'), findsOneWidget);
    expect(find.text('Konfirmasi Password'), findsOneWidget);
    expect(find.text('Daftar'), findsNWidgets(2)); // tab + tombol
    expect(registerButton(), findsOneWidget);
  });

  testWidgets('daftar formulir kosong -> error validasi',
      (WidgetTester tester) async {
    await pumpAuth(tester);

    await scrollIntoView(tester, registerTab());
    await tester.tap(registerTab());
    await tester.pumpAndSettle();

    await checkPrivacy(tester);
    await scrollIntoView(tester, registerButton());
    await tester.tap(registerButton());
    await tester.pumpAndSettle();

    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Password wajib diisi'), findsOneWidget);
    expect(find.text('Konfirmasi password wajib diisi'), findsOneWidget);
  });

  testWidgets('konfirmasi password tidak cocok -> error validasi',
      (WidgetTester tester) async {
    await pumpAuth(tester);

    await scrollIntoView(tester, registerTab());
    await tester.tap(registerTab());
    await tester.pumpAndSettle();

    await checkPrivacy(tester);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'user@example.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'rahasia123');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Konfirmasi Password'), 'beda456');

    await scrollIntoView(tester, registerButton());
    await tester.tap(registerButton());
    await tester.pumpAndSettle();

    expect(find.text('Password tidak cocok'), findsOneWidget);
  });

  testWidgets('kembali ke tab Masuk menghapus field daftar',
      (WidgetTester tester) async {
    await pumpAuth(tester);

    await scrollIntoView(tester, registerTab());
    await tester.tap(registerTab());
    await tester.pumpAndSettle();
    expect(find.text('Konfirmasi Password'), findsOneWidget);

    await scrollIntoView(tester, loginTab());
    await tester.tap(loginTab());
    await tester.pumpAndSettle();

    expect(find.text('Selamat Datang Kembali'), findsOneWidget);
    expect(find.text('Konfirmasi Password'), findsNothing);
  });
}

