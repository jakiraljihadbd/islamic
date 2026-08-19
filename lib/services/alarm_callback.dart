import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

import 'alarm_service.dart';

/// This is the top-level alarm callback invoked by android_alarm_manager_plus.
/// It must be a top-level function so the background isolate can find it.
/// The callback receives the int id that was passed when scheduling the alarm.
///
/// android_alarm_manager_plus (wakeup: true) wakes the device/CPU and starts
/// this callback in a fresh background isolate at the scheduled prayer time.
///
/// সেশন ৩ নোট: এখন প্রধান আলার্ম UI হলো flutter_local_notifications-এর
/// fullScreenIntent নোটিফিকেশন, যেটা সরাসরি AzanAlarmScreen খুলে দেয় (দেখুন
/// alarm_service.dart এর schedulePrayer() ও main.dart)। এই ব্যাকগ্রাউন্ড
/// isolate callback টা তার পাশাপাশি একটা backup হিসেবে থেকে যাচ্ছে — যদি
/// কোনো কারণে fullScreenIntent কাজ না করে (কিছু OEM এ), তাহলেও অন্তত আজানের
/// শব্দ বাজবে।
// CRITICAL: without this pragma, Dart's release-mode tree shaker/AOT
// compiler can strip this function since nothing in the main isolate
// appears to call it directly (it's only ever invoked by native code in
// a background isolate). Without the annotation, azan alarms can silently
// stop firing specifically in release APKs — the exact build this CI
// pipeline produces — while still working fine in debug runs.
@pragma('vm:entry-point')
Future<void> alarmCallback(int id) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Read saved metadata for this alarm
  final prefs = await SharedPreferences.getInstance();
  final prayerName = prefs.getString('alarm_prayer_$id') ?? 'নামাজ';
  final recurring = prefs.getBool('alarm_recurring_$id') ?? false;

  // Play azan.mp3 via the shared AlarmService (handles max volume + 3 min
  // timeout + cleanup internally).
  try {
    await AlarmService.instance.playAzanFromAsset();
  } catch (e) {
    debugPrint('Alarm callback ($prayerName) azan playback error: $e');
  }

  // If recurring, schedule next day's same time
  if (recurring) {
    final hour = prefs.getInt('alarm_hour_$id');
    final min = prefs.getInt('alarm_min_$id');
    if (hour != null && min != null) {
      final now = DateTime.now();
      DateTime next = DateTime(now.year, now.month, now.day, hour, min);
      if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
      await AndroidAlarmManager.oneShotAt(next, id, alarmCallback, exact: true, wakeup: true, rescheduleOnReboot: true);
    }
  }
}
