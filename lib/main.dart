import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'app.dart';
import 'services/crash_logger.dart';
import 'services/theme_controller.dart';
import 'screens/azan_alarm_screen.dart';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'services/alarm_service.dart';

void main() {
  CrashLogger.runGuarded(() async {
    final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

    // splash screen ফিক্স: আগে native splash (LaunchTheme) শেষ হয়ে যাওয়ার পর,
    // নিচের async init (alarm manager/notification/prefs) শেষ না হওয়া পর্যন্ত
    // একটা ফাঁকা/সাদা ফ্রেম দেখাত (native splash সরে গেছে কিন্তু runApp() এখনো
    // কল হয়নি) — এটাই আসল "২-৩ সেকেন্ড splash" সমস্যার কারণ, যা
    // FlutterNativeSplash.preserve() না থাকায় হতো। preserve() native splash কে
    // আটকে রাখে যতক্ষণ না নিচে remove() কল হয়, তাই init চলাকালীন কোনো white-screen
    // flash/overlap হবে না — একটাই মসৃণ স্প্ল্যাশ, দুইটা আলাদা স্প্ল্যাশের ওভারল্যাপ না।
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

    // Portrait lock
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    await ThemeController.instance.loadSaved();

    // Must be initialized before any alarm is scheduled — this is what lets
    // android_alarm_manager_plus wake a background isolate at prayer time.
    await AndroidAlarmManager.initialize();

    // Initialize AlarmService with a notification response handler so that
    // when the user taps the notification, taps its inline "স্টপ" action,
    // or the OS brings us to the foreground via fullScreenIntent while
    // we're already running, we react correctly — either opening the
    // full-screen azan alert or stopping playback directly.
    await AlarmService.instance.init(
      onDidReceiveNotificationResponse: (response) async {
        if (response.actionId == kStopAzanActionId) {
          await AlarmService.instance.stopAzan();
          return;
        }

        String prayerName = 'নামাজ';
        int alarmId = 0;
        final payload = response.payload;
        if (payload != null) {
          try {
            final map = jsonDecode(payload) as Map<String, dynamic>;
            prayerName = (map['prayerName'] as String?) ?? prayerName;
            alarmId = (map['id'] as int?) ?? alarmId;
          } catch (_) {}
        }

        rootNavigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => AzanAlarmScreen(prayerName: prayerName, alarmId: alarmId),
          ),
        );
      },
    );

    // Restore previously saved scheduled notifications (re-register)
    await AlarmService.instance.restoreAlarmsFromPrefs();

    // If the app was cold-started by the user tapping/full-screen-intent
    // from an azan notification, open straight into the alarm screen
    // instead of the normal home screen (avoids a flash of RootShell first).
    final launchPayload = await AlarmService.instance.getLaunchPayload();

    runApp(IslamicZoneApp(initialAlarmPayload: launchPayload));

    // init শেষ, এখন প্রথম ফ্রেম আঁকা হওয়ার পর native splash সরিয়ে দাও।
    FlutterNativeSplash.remove();
  });
}
