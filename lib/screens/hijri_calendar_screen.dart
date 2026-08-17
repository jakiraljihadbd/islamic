import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

const _hijriMonths = [
  'মুহাররম',
  'সফর',
  'রবিউল আউয়াল',
  'রবিউস সানি',
  'জমাদিউল আউয়াল',
  'জমাদিউস সানি',
  'রজব',
  'শাবান',
  'রমজান',
  'শাওয়াল',
  'জিলক্বদ',
  'জিলহজ্জ',
];

/// গ্রেগরিয়ান তারিখ থেকে আনুমানিক হিজরি তারিখে রূপান্তর (কুয়েতি অ্যালগরিদম)।
/// চাঁদ দেখার উপর নির্ভর করে বাস্তব হিজরি তারিখ ১ দিন আগে-পরে হতে পারে।
class HijriDate {
  final int day;
  final int month; // 1-12
  final int year;
  const HijriDate(this.day, this.month, this.year);

  static HijriDate fromGregorian(DateTime date) {
    final jd = _gregorianToJulianDay(date.year, date.month, date.day);
    final l = jd - 1948440 + 10632;
    final n = ((l - 1) / 10631).floor();
    var ll = l - 10631 * n + 354;
    final j = (((10985 - ll) / 5316).floor()) * ((50 * ll) ~/ 17719) +
        ((ll / 5670).floor()) * ((43 * ll) ~/ 15238);
    ll = ll -
        ((30 - j) / 15).floor() * ((17719 * j) ~/ 50) -
        (j / 16).floor() * ((15238 * j) ~/ 43) +
        29;
    final month = ((24 * ll) / 709).floor();
    final day = ll - ((709 * month) / 24).floor();
    final year = 30 * n + j - 30;
    return HijriDate(day, month, year);
  }

  static int _gregorianToJulianDay(int year, int month, int day) {
    final a = ((14 - month) / 12).floor();
    final y = year + 4800 - a;
    final m = month + 12 * a - 3;
    return day +
        ((153 * m + 2) / 5).floor() +
        365 * y +
        (y / 4).floor() -
        (y / 100).floor() +
        (y / 400).floor() -
        32045;
  }

  String get monthName => _hijriMonths[(month - 1).clamp(0, 11)];
}

/// 5.2: হিজরি ক্যালেন্ডার স্ক্রিন — আজকের হিজরি তারিখ + মাস বাছাই করে গ্রেগরিয়ান তারিখের
/// আনুমানিক হিজরি রূপান্তর দেখায়।
class HijriCalendarScreen extends StatefulWidget {
  const HijriCalendarScreen({super.key});

  @override
  State<HijriCalendarScreen> createState() => _HijriCalendarScreenState();
}

class _HijriCalendarScreenState extends State<HijriCalendarScreen> {
  DateTime _selected = DateTime.now();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selected,
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selected = picked);
  }

  @override
  Widget build(BuildContext context) {
    final hijri = HijriDate.fromGregorian(_selected);
    final gregorianStr = '${_selected.day}/${_selected.month}/${_selected.year}';

    return Scaffold(
      appBar: AppBar(title: const Text('হিজরি ক্যালেন্ডার')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: AppColors.primary,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      '${hijri.day} ${hijri.monthName} ${hijri.year} হিজরি',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'গ্রেগরিয়ান: $gregorianStr',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month),
              label: const Text('অন্য তারিখ বাছাই করুন'),
            ),
            const SizedBox(height: 12),
            const Text(
              'নোট: এটা গাণিতিক হিসাব-ভিত্তিক আনুমানিক তারিখ। স্থানীয় চাঁদ দেখা অনুযায়ী প্রকৃত '
              'হিজরি তারিখ ১ দিন আগে বা পরে হতে পারে।',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
