import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../services/suggestion_service.dart';

/// Provider untuk mengelola locale (bahasa) aplikasi.
/// Menyimpan pilihan bahasa ke SharedPreferences.
class LocaleProvider extends ChangeNotifier {
  static const String _key = 'app_locale';

  String _locale = 'id';
  String get locale => _locale;

  /// Inisialisasi — panggil sebelum runApp
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _locale = prefs.getString(_key) ?? 'id';
    AppLocalizations.setLocale(_locale);
    notifyListeners();
  }

  /// Ganti bahasa & simpan
  Future<void> setLocale(String newLocale) async {
    if (_locale == newLocale) return;
    _locale = newLocale;
    AppLocalizations.setLocale(newLocale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, newLocale);
    // Reset & muat ulang saran sesuai locale baru
    SuggestionService().reset();
    await SuggestionService().load();
    notifyListeners();
  }

  /// Toggle antara 'id' dan 'en'
  Future<void> toggleLocale() async {
    await setLocale(_locale == 'id' ? 'en' : 'id');
  }
}
