import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/app_localizations.dart';

/// Layanan notifikasi lokal untuk pengingat harian deteksi emosi.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const int _reminderBaseId = 1001;
  static const int _reminderCount = 8; // 24 jam / 3 jam
  static const String _enabledKey = 'reminder_enabled';
  static const String _hourKey = 'reminder_hour';
  static const String _minuteKey = 'reminder_minute';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    try {
      final tzName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      // Fallback UTC bila timezone device tidak dapat dibaca
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;

    // Pulihkan jadwal pengingat dari sesi sebelumnya
    await restoreSchedule();
  }

  Future<bool> requestPermission() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final grantedAndroid =
        await androidImpl?.requestNotificationsPermission() ?? true;

    final iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    final grantedIos = await iosImpl?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        true;

    return grantedAndroid && grantedIos;
  }

  /// Jadwalkan pengingat rutin: 8 notifikasi per hari, setiap 3 jam,
  /// dimulai dari jam & menit yang dipilih (teks mengikuti bahasa aktif).
  Future<void> scheduleRoutine({
    required int startHour,
    required int startMinute,
  }) async {
    for (var i = 0; i < _reminderCount; i++) {
      final totalMinutes = startHour * 60 + startMinute + i * 3 * 60;
      final hour = (totalMinutes ~/ 60) % 24;
      final minute = totalMinutes % 60;

      await _plugin.zonedSchedule(
        _reminderBaseId + i,
        AppLocalizations.tr('reminder_notification_title'),
        AppLocalizations.tr('reminder_notification_body'),
        _nextInstanceOf(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'routine_reminder',
            'Pengingat Rutin',
            channelDescription: 'Pengingat rutin untuk deteksi emosi',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancelReminder() async {
    for (var i = 0; i < _reminderCount; i++) {
      await _plugin.cancel(_reminderBaseId + i);
    }
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  // ── Preferensi (SharedPreferences) ─────────────────────────

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  Future<TimeOfDayPrefs> getReminderPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return TimeOfDayPrefs(
      enabled: prefs.getBool(_enabledKey) ?? false,
      hour: prefs.getInt(_hourKey) ?? 19,
      minute: prefs.getInt(_minuteKey) ?? 0,
    );
  }

  Future<void> saveEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  Future<void> saveTime({required int hour, required int minute}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hourKey, hour);
    await prefs.setInt(_minuteKey, minute);
  }

  /// Pulihkan & jadwalkan ulang pengingat jika sebelumnya aktif.
  Future<void> restoreSchedule() async {
    final prefs = await getReminderPrefs();
    if (!prefs.enabled) return;
    try {
      await scheduleRoutine(startHour: prefs.hour, startMinute: prefs.minute);
    } catch (e) {
      debugPrint('Reminder reschedule error: $e');
    }
  }
}

class TimeOfDayPrefs {
  final bool enabled;
  final int hour;
  final int minute;

  const TimeOfDayPrefs({
    required this.enabled,
    required this.hour,
    required this.minute,
  });
}
