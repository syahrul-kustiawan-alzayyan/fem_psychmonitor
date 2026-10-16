import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fem_physicsmonitor/l10n/app_localizations.dart';
import 'package:fem_physicsmonitor/main.dart';
import 'package:fem_physicsmonitor/providers/admin_provider.dart';
import 'package:fem_physicsmonitor/providers/locale_provider.dart';
import 'package:fem_physicsmonitor/providers/premium_provider.dart';
import 'package:fem_physicsmonitor/providers/theme_provider.dart';

/// Mock channel path_provider untuk lingkungan test.
void mockPathProvider() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final channel in const <MethodChannel>[
    MethodChannel('plugins.flutter.io/path_provider'),
    MethodChannel('plugins.flutter.io/path_provider_windows'),
    MethodChannel('plugins.flutter.io/path_provider_linux'),
  ]) {
    messenger.setMockMethodCallHandler(channel, (MethodCall call) async {
      if (call.method.startsWith('getApplication')) {
        return Directory.systemTemp.path;
      }
      return null;
    });
  }
}

/// AuthProvider TIDAK disertakan karena konstruktornya mengakses
/// `FirebaseAuth.instance` yang tidak tersedia di lingkungan test.
Widget buildApp() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LocaleProvider>.value(value: LocaleProvider()),
      ChangeNotifierProvider<ThemeProvider>.value(value: ThemeProvider()),
      ChangeNotifierProvider<PremiumProvider>.value(value: PremiumProvider()),
      ChangeNotifierProvider<AdminProvider>.value(value: AdminProvider()),
    ],
    child: const FemPhysicsMonitorApp(),
  );
}

/// Pump AppRouter sampai future routing selesai.
///
/// AppRouter memadukan I/O nyata (path_provider, HTTP 400 dari mock) dengan
/// timer fake-async (delay 3 detik bawaan), jadi butuh `runAsync` untuk I/O
/// dan `pump(duration)` untuk memajukan timer.
Future<void> settleRouting(WidgetTester tester) async {
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
  });
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 4));
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    mockPathProvider();
    GoogleFonts.config.allowRuntimeFetching = false;
    AppLocalizations.setLocale('id');
  });

  testWidgets('Splash tampil dulu, lalu mengarah ke onboarding saat first launch',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(buildApp());

    // Frame pertama: future AppRouter belum selesai -> splash screen
    await tester.pump();
    expect(find.text('Fem-Psych Monitor'), findsOneWidget);

    // Future selesai -> first launch -> onboarding (welcome section)
    await settleRouting(tester);
    expect(find.text(AppLocalizations.tr('start_now')), findsOneWidget);
  });

  testWidgets('Bukan first launch -> langsung AuthScreen',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'first_launch': false});
    await tester.pumpWidget(buildApp());

    await settleRouting(tester);

    expect(find.text('Masuk'), findsWidgets);
  });
}
