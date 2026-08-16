import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fem_physicsmonitor/providers/locale_provider.dart';
import 'package:fem_physicsmonitor/providers/premium_provider.dart';
import 'package:fem_physicsmonitor/providers/theme_provider.dart';

/// Menyiapkan penyimpanan lokal kosong — setara mock backend pada level respons.
void initBlackboxEnvironment() {
  SharedPreferences.setMockInitialValues({});
}

/// Bootstrap aplikasi minimal untuk pengujian blackbox murni.
///
/// Provider dibuat hanya dengan konstruktor default (nilai awal aplikasi).
/// Tidak ada pemanggilan method penyuntik state (mis. `setPremium`,
/// `setLocale`) — semua perubahan perilaku harus datang dari interaksi UI.
Widget wrapBlackbox({required Widget child}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LocaleProvider>.value(value: LocaleProvider()),
      ChangeNotifierProvider<ThemeProvider>.value(value: ThemeProvider()),
      ChangeNotifierProvider<PremiumProvider>.value(value: PremiumProvider()),
    ],
    child: MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: child,
    ),
  );
}
