import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fem_physicsmonitor/providers/admin_provider.dart';
import 'package:fem_physicsmonitor/providers/locale_provider.dart';
import 'package:fem_physicsmonitor/providers/premium_provider.dart';
import 'package:fem_physicsmonitor/providers/theme_provider.dart';

/// Siapkan SharedPreferences mock + binding untuk semua test.
void initTestEnvironment() {
  SharedPreferences.setMockInitialValues({});
}

/// Bungkus [child] dengan provider yang aman di-test (tanpa Firebase).
///
/// [AuthProvider] TIDAK disertakan karena konstruktornya mengakses
/// `FirebaseAuth.instance` yang tidak tersedia di lingkungan test.
Widget wrapWithProviders({
  required Widget child,
  bool premium = false,
}) {
  final localeProvider = LocaleProvider();
  final themeProvider = ThemeProvider();
  final premiumProvider = PremiumProvider()
    ..setPremium(value: premium);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
      ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
      ChangeNotifierProvider<PremiumProvider>.value(value: premiumProvider),
      ChangeNotifierProvider<AdminProvider>.value(value: AdminProvider()),
    ],
    child: MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: child,
    ),
  );
}

/// Bungkus widget dalam MaterialApp biasa tanpa provider (untuk widget statis).
Widget wrapInApp({required Widget child}) {
  return MaterialApp(home: child);
}
