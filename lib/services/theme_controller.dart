import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 6.3: অ্যাপ-লেভেল dark mode state — SettingsScreen থেকে টগল করলে
/// পুরো অ্যাপে সাথে সাথে থিম পরিবর্তন হয়, আর shared_preferences দিয়ে
/// পরের বার অ্যাপ খুললেও মনে রাখে।
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController._() : super(ThemeMode.light);

  static final ThemeController instance = ThemeController._();

  static const _prefsKey = 'theme_mode';

  Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == 'dark') {
      value = ThemeMode.dark;
    } else if (saved == 'system') {
      value = ThemeMode.system;
    } else {
      value = ThemeMode.light;
    }
  }

  bool get isDark => value == ThemeMode.dark;

  Future<void> setDark(bool dark) async {
    value = dark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, dark ? 'dark' : 'light');
  }
}
