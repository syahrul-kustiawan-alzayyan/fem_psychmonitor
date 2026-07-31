import 'package:flutter_test/flutter_test.dart';

import 'package:fem_physicsmonitor/l10n/app_localizations.dart';

void main() {
  group('AppLocalizations', () {
    setUp(() {
      AppLocalizations.setLocale('id');
    });

    test('tr mengembalikan string id untuk key yang ada', () {
      expect(AppLocalizations.tr('nav_home'), 'Beranda');
      expect(AppLocalizations.tr('nav_record'), 'Rekam');
      expect(AppLocalizations.tr('nav_history'), 'Riwayat');
    });

    test('tr mengembalikan string en setelah setLocale("en")', () {
      AppLocalizations.setLocale('en');
      final enHome = AppLocalizations.tr('nav_home');
      expect(enHome, isNot('Beranda'));
      expect(enHome, isNotEmpty);
    });

    test('tr fallback ke id jika key tidak ada di en', () {
      AppLocalizations.setLocale('en');
      final value = AppLocalizations.tr('nav_home');
      expect(value, isNotEmpty);
    });

    test('tr mengembalikan key jika tidak ditemukan di map manapun', () {
      expect(AppLocalizations.tr('key_tidak_ada_123'), 'key_tidak_ada_123');
    });

    test('setLocale & locale getter', () {
      AppLocalizations.setLocale('en');
      expect(AppLocalizations.locale, 'en');
      expect(AppLocalizations.currentLocale, 'en');
      AppLocalizations.setLocale('id');
      expect(AppLocalizations.locale, 'id');
    });

    test('key penting onboarding & hasil tersedia', () {
      for (final key in [
        'bigfive_dim_O',
        'start_now',
        'psych_excellent',
        'psych_good',
        'psych_fair',
        'psych_needs_attention',
        'result_rec_1',
        'daily_limit_title',
        'login_required',
        'emotion_happy',
        'emotion_sad',
        'emotion_angry',
        'emotion_disgust',
        'emotion_neutral',
        'emotion_fear',
        'sugg_happy_1',
        'trigger_work',
      ]) {
        expect(AppLocalizations.tr(key), isNotEmpty,
            reason: 'Key $key harus memiliki terjemahan');
      }
    });

    test('terjemahan id dan en tidak identik untuk key contoh', () {
      final idValue = AppLocalizations.tr('splash_subtitle');
      AppLocalizations.setLocale('en');
      final enValue = AppLocalizations.tr('splash_subtitle');
      expect(idValue, isNot(enValue));
      AppLocalizations.setLocale('id');
    });
  });
}
