import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 11.2 (worklist_salat_screen.txt): অ্যাপ-লেভেল ১২/২৪-ঘন্টা সময় ফরম্যাট
/// প্রেফারেন্স — SettingsScreen থেকে টগল করলে সাথে সাথে যে স্ক্রিন এই
/// controller শোনে সেখানে বদলে যায়, shared_preferences দিয়ে persist হয়
/// (পরের বার অ্যাপ খুললেও মনে রাখে)। ThemeController-এর সাথে হুবহু একই প্যাটার্ন।
class TimeFormatController extends ValueNotifier<bool> {
  // ডিফল্ট true (২৪-ঘন্টা) — অ্যাপ এতদিন যেভাবে সময় দেখাত (DateFormat('HH:mm'))
  // তার সাথে মিলিয়ে, যাতে আগে থেকে ব্যবহার করা কারো জন্য হঠাৎ বদলে না যায়।
  TimeFormatController._() : super(true);

  static final TimeFormatController instance = TimeFormatController._();

  static const _prefsKey = 'time_format_24h';

  Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    value = prefs.getBool(_prefsKey) ?? true;
  }

  bool get is24Hour => value;

  Future<void> setIs24Hour(bool is24Hour) async {
    value = is24Hour;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, is24Hour);
  }
}
