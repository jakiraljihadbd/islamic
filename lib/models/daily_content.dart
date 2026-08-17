import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// একটা আয়াত বা হাদিস — আরবি টেক্সট, বাংলা অনুবাদ, রেফারেন্স।
class VerseHadith {
  final int id;
  final String arabic;
  final String bengali;
  final String reference;

  const VerseHadith({
    required this.id,
    required this.arabic,
    required this.bengali,
    required this.reference,
  });

  factory VerseHadith.fromJson(Map<String, dynamic> json) {
    return VerseHadith(
      id: json['id'] as int,
      arabic: json['arabic'] as String,
      bengali: json['bengali'] as String,
      reference: json['reference'] as String,
    );
  }
}

/// assets/data/verses.json ও assets/data/hadith.json থেকে ডেটা লোড করে,
/// এবং তারিখ অনুযায়ী fix (deterministic) একটা আয়াত/হাদিস বেছে দেয় —
/// একই দিনে বারবার খুললেও একই আয়াত/হাদিস দেখাবে, পরের দিন পরিবর্তন হবে।
class DailyContentRepository {
  static List<VerseHadith>? _verses;
  static List<VerseHadith>? _hadiths;

  static Future<List<VerseHadith>> loadVerses() async {
    if (_verses != null) return _verses!;
    final raw = await rootBundle.loadString('assets/data/verses.json');
    final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
    _verses = list.map((e) => VerseHadith.fromJson(e as Map<String, dynamic>)).toList();
    return _verses!;
  }

  static Future<List<VerseHadith>> loadHadiths() async {
    if (_hadiths != null) return _hadiths!;
    final raw = await rootBundle.loadString('assets/data/hadith.json');
    final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
    _hadiths = list.map((e) => VerseHadith.fromJson(e as Map<String, dynamic>)).toList();
    return _hadiths!;
  }

  /// বছরের কততম দিন (১-৩৬৬), এটা দিয়ে দিনের জন্য fix ইনডেক্স বের করা হয়।
  static int _dayOfYear(DateTime date) {
    final start = DateTime(date.year, 1, 1);
    return date.difference(start).inDays;
  }

  static Future<VerseHadith> todaysVerse({DateTime? now}) async {
    final verses = await loadVerses();
    final day = _dayOfYear(now ?? DateTime.now());
    return verses[day % verses.length];
  }

  static Future<VerseHadith> todaysHadith({DateTime? now}) async {
    final hadiths = await loadHadiths();
    final day = _dayOfYear(now ?? DateTime.now());
    return hadiths[day % hadiths.length];
  }
}
