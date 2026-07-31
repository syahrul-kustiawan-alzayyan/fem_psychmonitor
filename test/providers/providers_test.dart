import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fem_physicsmonitor/l10n/app_localizations.dart';
import 'package:fem_physicsmonitor/providers/locale_provider.dart';
import 'package:fem_physicsmonitor/providers/premium_provider.dart';
import 'package:fem_physicsmonitor/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppLocalizations.setLocale('id');
  });

  group('LocaleProvider', () {
    test('default locale id', () async {
      final provider = LocaleProvider();
      await provider.init();
      expect(provider.locale, 'id');
      expect(AppLocalizations.locale, 'id');
    });

    test('memuat locale tersimpan dari prefs', () async {
      SharedPreferences.setMockInitialValues({'app_locale': 'en'});
      final provider = LocaleProvider();
      await provider.init();
      expect(provider.locale, 'en');
    });

    test('setLocale menyimpan & men-toggle', () async {
      final provider = LocaleProvider();
      await provider.init();
      await provider.setLocale('en');
      expect(provider.locale, 'en');

      await provider.toggleLocale();
      expect(provider.locale, 'id');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale'), 'id');
    });

    test('setLocale tidak memanggil ulang bila sama', () async {
      final provider = LocaleProvider();
      await provider.init();
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);
      await provider.setLocale('id');
      expect(notifyCount, 0);
    });
  });

  group('ThemeProvider', () {
    test('default light', () async {
      final provider = ThemeProvider();
      await provider.init();
      expect(provider.themeMode, ThemeMode.light);
      expect(provider.isDark, isFalse);
    });

    test('memuat tema tersimpan', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'dark'});
      final provider = ThemeProvider();
      await provider.init();
      expect(provider.isDark, isTrue);
    });

    test('setThemeMode & toggleTheme', () async {
      final provider = ThemeProvider();
      await provider.init();
      await provider.setThemeMode(ThemeMode.dark);
      expect(provider.isDark, isTrue);

      await provider.toggleTheme();
      expect(provider.themeMode, ThemeMode.light);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_mode'), 'light');
    });
  });

  group('PremiumProvider', () {
    test('default bukan premium', () {
      final provider = PremiumProvider();
      provider.init();
      expect(provider.isPremium, isFalse);
      expect(provider.expiryDate, isNull);
      expect(provider.isExpired, isFalse);
    });

    test('setPremium & clearPremium', () {
      final provider = PremiumProvider();
      provider.init();
      final future = DateTime.now().add(const Duration(days: 30));
      provider.setPremium(value: true, expiry: future);
      expect(provider.isPremium, isTrue);
      expect(provider.isExpired, isFalse);

      provider.setPremium(value: true, expiry: DateTime.now().subtract(const Duration(days: 1)));
      expect(provider.isExpired, isTrue);

      provider.clearPremium();
      expect(provider.isPremium, isFalse);
    });

    test('notifyListeners dipanggil saat berubah', () {
      final provider = PremiumProvider();
      var count = 0;
      provider.addListener(() => count++);
      provider.setPremium(value: true, expiry: null);
      expect(count, 1);
    });
  });
}
