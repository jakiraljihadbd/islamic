import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:just_audio/just_audio.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'alarm_callback.dart';

/// Notification action id for the inline "স্টপ" button shown directly on
/// the azan notification. Some OEMs (MIUI/ColorOS/etc.) restrict full-screen
/// intents when the app is battery-optimized, so this button is a fallback
/// that always works even if the full-screen alarm activity never appears.
const String kStopAzanActionId = 'STOP_AZAN';

class AlarmService {
  AlarmService._();
  static final instance = AlarmService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final AudioPlayer _player = AudioPlayer();

  bool get isPlaying => _player.playing;

  /// Initialize AlarmService and notification plugin.
  ///
  /// [onDidReceiveNotificationResponse] will be forwarded to
  /// `flutter_local_notifications` initialize call so the app can react to
  /// notification taps / full-screen-intent launches (e.g. show the full
  /// screen azan alert or stop playback from the inline action button).
  Future<void> init({void Function(NotificationResponse)? onDidReceiveNotificationResponse}) async {
    // Timezone
    tzdata.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );

    // Create notification channel with importance/category tuned for an
    // alarm-style notification (high-priority sound channel, not just a
    // regular reminder channel) — required for fullScreenIntent to reliably
    // work across Android versions/OEMs.
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'prayer_channel',
      'Prayer Times (Azan Alarm)',
      description: 'নামাজের সময় হলে আজান আলার্ম দেখায়',
      importance: Importance.max,
      playSound: true,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(channel);

    // Android 13+ (API 33+) hides all notifications, including the azan
    // alarm's fullScreenIntent one, until POST_NOTIFICATIONS is granted at
    // runtime — declaring it in the manifest alone is not enough.
    await androidPlugin?.requestNotificationsPermission();

    // Android 12+ requires the user to explicitly grant exact-alarm access
    // (it's a special access toggle in system settings, not a normal
    // runtime dialog); on Android 14+ it's denied by default. Without this,
    // schedulePrayer()'s zonedSchedule with exactAllowWhileIdle can throw a
    // SecurityException or silently degrade to an inexact/delayed alarm —
    // which defeats the point of an azan alarm.
    await androidPlugin?.requestExactAlarmsPermission();
  }

  /// Ask the user to exempt the app from battery optimization. Many Android
  /// OEMs (Xiaomi/MIUI, Oppo/ColorOS, Vivo, Samsung power-saver, etc.)
  /// aggressively kill background alarms unless this is granted — without
  /// it the azan can silently fail to fire on those phones. Safe to call
  /// repeatedly; does nothing if already granted or on non-Android.
  Future<void> requestIgnoreBatteryOptimizations() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (!status.isGranted) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    } catch (_) {
      // Not available on this platform/OS version — ignore.
    }
  }

  /// Force playback volume to maximum before/while azan plays.
  Future<void> setMaxVolume() async {
    try {
      await _player.setVolume(1.0);
    } catch (_) {}
  }

  /// Play azan from bundled Flutter asset (assets/azan.mp3)
  /// Compatible with Android v9+
  Future<void> playAzanFromAsset({Duration timeout = const Duration(minutes: 3)}) async {
    try {
      await _player.setAsset('assets/azan.mp3');
      await setMaxVolume();
      await _player.play();
      // wait until finished or timeout
      await _player.playerStateStream
          .firstWhere(
            (s) => s.processingState == ProcessingState.completed,
            orElse: () => PlayerState(playing: false, processingState: ProcessingState.idle),
          )
          .timeout(timeout);
    } catch (e) {
      // ignore playback errors
      debugPrint('Azan playback error: $e');
    } finally {
      try {
        await _player.stop();
      } catch (_) {}
    }
  }

  /// Stop azan playback immediately. Used by the "Stop"/"বন্ধ করুন" button
  /// on the full-screen alarm screen and the notification's inline action.
  Future<void> stopAzan() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  /// Schedule a notification (zoned). If [recurring] is true it repeats daily at the given time.
  Future<void> schedulePrayer({
    required int id,
    required DateTime dateTime,
    required String prayerName,
    bool recurring = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('alarm_prayer_$id', prayerName);
    await prefs.setInt('alarm_hour_$id', dateTime.hour);
    await prefs.setInt('alarm_min_$id', dateTime.minute);
    await prefs.setBool('alarm_recurring_$id', recurring);

    final tzDate = tz.TZDateTime.from(dateTime, tz.local);

    // fullScreenIntent + category alarm + max importance/priority together
    // are what let this notification wake the screen and launch the app's
    // full-screen azan alert even over the lock screen — the same mechanism
    // real alarm-clock apps use. The inline "স্টপ" action is a fallback for
    // OEMs that suppress full-screen intents when battery-optimized.
    final androidDetails = AndroidNotificationDetails(
      'prayer_channel',
      'Prayer Times (Azan Alarm)',
      channelDescription: 'নামাজের সময় হলে আজান আলার্ম দেখায়',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      ongoing: true,
      autoCancel: false,
      actions: const [
        AndroidNotificationAction(kStopAzanActionId, 'বন্ধ করুন', cancelNotification: true),
      ],
    );
    final details = NotificationDetails(android: androidDetails);
    final payload = jsonEncode({'id': id, 'prayerName': prayerName});

    // flutter_local_notifications v18+ removed androidAllowWhileIdle and
    // uiLocalNotificationDateInterpretation entirely — androidScheduleMode
    // is now the single way to say "fire at the exact time even if the
    // device is idle", which is what this azan alarm needs.
    if (recurring) {
      await _plugin.zonedSchedule(
        id,
        prayerName,
        '$prayerName এর সময় হয়েছে',
        tzDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
    } else {
      await _plugin.zonedSchedule(
        id,
        prayerName,
        '$prayerName এর সময় হয়েছে',
        tzDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    }

    // flutter_local_notifications above only shows the visible notification —
    // it does NOT run any Dart code in the background. android_alarm_manager_plus
    // is what actually wakes a background isolate at prayer time and runs
    // alarmCallback(), which is what plays the azan sound. Both must be scheduled.
    await AndroidAlarmManager.oneShotAt(
      dateTime,
      id,
      alarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  }

  Future<void> cancelPrayer(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('alarm_prayer_$id');
    await prefs.remove('alarm_hour_$id');
    await prefs.remove('alarm_min_$id');
    await prefs.remove('alarm_recurring_$id');
    await _plugin.cancel(id);
    await AndroidAlarmManager.cancel(id);
  }

  /// Dismiss the currently-showing azan notification (id-specific). The
  /// notification is `ongoing: true` so it won't auto-dismiss on tap; the
  /// full-screen alarm screen's Stop button and the inline action both call
  /// this once playback is stopped.
  Future<void> dismissNotification(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }

  /// Returns details about the notification that launched the app (if the
  /// app was cold-started by tapping/full-screen-intent from an azan
  /// notification), or null for a normal launch. Call once at startup.
  Future<Map<String, dynamic>?> getLaunchPayload() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details == null || !details.didNotificationLaunchApp) return null;
      final payload = details.notificationResponse?.payload;
      if (payload == null) return null;
      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Restore scheduled notifications from SharedPreferences (call on app start)
  Future<void> restoreAlarmsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (!key.startsWith('alarm_prayer_')) continue;
      final idStr = key.replaceFirst('alarm_prayer_', '');
      final id = int.tryParse(idStr);
      if (id == null) continue;
      final hour = prefs.getInt('alarm_hour_$id');
      final min = prefs.getInt('alarm_min_$id');
      final recurring = prefs.getBool('alarm_recurring_$id') ?? false;
      final prayerName = prefs.getString('alarm_prayer_$id') ?? 'নামাজ';
      if (hour == null || min == null) continue;
      final now = DateTime.now();
      DateTime scheduled = DateTime(now.year, now.month, now.day, hour, min);
      if (!scheduled.isAfter(now)) scheduled = scheduled.add(const Duration(days: 1));
      await schedulePrayer(id: id, dateTime: scheduled, prayerName: prayerName, recurring: recurring);
    }
  }
}
