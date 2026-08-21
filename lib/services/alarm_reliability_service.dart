import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'alarm_service.dart';

/// আজান alarm যাতে সব ফোনে (বিশেষ করে Xiaomi/Oppo/Vivo/Huawei/Samsung এর মতো
/// আক্রমণাত্মক battery-manager থাকা OEM গুলোতে) মিস না হয়, তার জন্য দরকারি
/// সব "সিস্টেম-লেভেল" ধাপ এক জায়গায় — এগুলো কোনোটাই কোডে ফিক্স করা যায় না,
/// প্রতিটার জন্য ব্যবহারকারীকে একবার করে হাতে গিয়ে একটা সেটিংস অন করে দিতে হয়।
class AlarmReliabilityService {
  AlarmReliabilityService._();
  static final instance = AlarmReliabilityService._();

  static const _prefShownKey = 'alarm_reliability_dialog_shown';

  /// ডিভাইসের ম্যানুফ্যাকচারার (lowercase), শুধু Android এ।
  Future<String> _manufacturer() async {
    if (!Platform.isAndroid) return '';
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      return info.manufacturer.toLowerCase();
    } catch (_) {
      return '';
    }
  }

  /// প্রথমবার কোনো নামাজের alarm চালু করার সময় একবার reliability
  /// checklist dialog দেখানো উচিত কিনা।
  Future<bool> shouldShowOnFirstAlarm() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_prefShownKey) ?? false);
  }

  Future<void> markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefShownKey, true);
  }

  /// ব্যাটারি অপটিমাইজেশন থেকে অ্যাপকে বাদ দেওয়ার সিস্টেম ডায়ালগ।
  Future<void> requestBatteryExemption() {
    return AlarmService.instance.requestIgnoreBatteryOptimizations();
  }

  /// ফোনের ব্র্যান্ড অনুযায়ী "Autostart" / background-permission সেটিংস
  /// স্ক্রিন খোলার চেষ্টা করে। প্রতিটা ব্যর্থ হলে পরেরটা ট্রাই করে, সবকটা
  /// ব্যর্থ হলে শেষমেশ অ্যাপের সাধারণ App Info স্ক্রিন খোলে (যেখান থেকে
  /// ব্যবহারকারী নিজেই battery/permission অপশন খুঁজে নিতে পারবে) — কখনো
  /// silently কিছু না করে থেমে যায় না।
  Future<void> openAutostartSettings() async {
    if (!Platform.isAndroid) return;
    final brand = await _manufacturer();

    final candidates = <AndroidIntent>[];

    if (brand.contains('xiaomi') || brand.contains('redmi') || brand.contains('poco')) {
      candidates.add(_intent(
        package: 'com.miui.securitycenter',
        componentName:
            'com.miui.securitycenter/com.miui.permcenter.autostart.AutoStartManagementActivity',
      ));
    } else if (brand.contains('oppo') || brand.contains('realme')) {
      candidates.addAll([
        _intent(
          package: 'com.coloros.safecenter',
          componentName:
              'com.coloros.safecenter/com.coloros.safecenter.permission.startup.StartupAppListActivity',
        ),
        _intent(
          package: 'com.coloros.safecenter',
          componentName: 'com.coloros.safecenter/.startupapp.StartupAppListActivity',
        ),
        _intent(
          package: 'com.coloros.oppoguardelf',
          componentName:
              'com.coloros.oppoguardelf/com.coloros.powermanager.fuelgaue.PowerConsumptionActivity',
        ),
      ]);
    } else if (brand.contains('vivo')) {
      candidates.addAll([
        _intent(
          package: 'com.vivo.permissionmanager',
          componentName:
              'com.vivo.permissionmanager/com.vivo.permissionmanager.activity.BgStartUpManagerActivity',
        ),
        _intent(
          package: 'com.iqoo.secure',
          componentName: 'com.iqoo.secure/com.iqoo.secure.ui.phoneoptimize.BgStartUpManager',
        ),
      ]);
    } else if (brand.contains('huawei') || brand.contains('honor')) {
      candidates.add(_intent(
        package: 'com.huawei.systemmanager',
        componentName:
            'com.huawei.systemmanager/com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity',
      ));
    } else if (brand.contains('samsung')) {
      candidates.add(_intent(
        package: 'com.samsung.android.lool',
        componentName: 'com.samsung.android.lool/com.samsung.android.sm.ui.battery.BatteryActivity',
      ));
    } else if (brand.contains('asus')) {
      candidates.add(_intent(
        package: 'com.asus.mobilemanager',
        componentName:
            'com.asus.mobilemanager/com.asus.mobilemanager.autostart.AutoStartActivity',
      ));
    } else if (brand.contains('oneplus')) {
      candidates.add(_intent(
        package: 'com.oneplus.security',
        componentName:
            'com.oneplus.security/com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity',
      ));
    }

    for (final intent in candidates) {
      try {
        await intent.launch();
        return; // একটা সফল হলেই যথেষ্ট
      } catch (e) {
        debugPrint('Autostart intent failed for $brand: $e');
      }
    }

    // ব্র্যান্ড-নির্দিষ্ট কোনো স্ক্রিন খুঁজে না পেলে (বা অজানা ব্র্যান্ড হলে)
    // অন্তত অ্যাপের নিজের সেটিংস পেজ খুলে দাও।
    await openAppSettingsScreen();
  }

  /// অ্যাপের সাধারণ System App Info স্ক্রিন — ফলব্যাক হিসেবে এবং settings
  /// পেজের "অ্যাপ ইনফো খুলুন" বাটনের জন্য।
  Future<void> openAppSettingsScreen() async {
    if (!Platform.isAndroid) return;
    try {
      await _intent(
        action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
        data: 'package:com.islamiczone.org',
      ).launch();
    } catch (e) {
      debugPrint('Open app settings failed: $e');
    }
  }

  AndroidIntent _intent({
    String? package,
    String? componentName,
    String? action,
    String? data,
  }) {
    return AndroidIntent(
      action: action ?? 'action_main',
      package: package,
      componentName: componentName,
      data: data,
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );
  }
}
