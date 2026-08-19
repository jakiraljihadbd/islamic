import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'services/crash_logger.dart';
import 'services/theme_controller.dart';
import 'screens/azan_alarm_screen.dart';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'services/alarm_service.dart';

void main() {
  CrashLogger.runGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

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
  });
}
