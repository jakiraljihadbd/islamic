import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// একটা সূরার তথ্য — assets/data/surahs.json থেকে লোড হয়।
class Surah {
  final int number;
  final String nameArabic;
  final String nameBengali;
  final int ayahs;
  final String revelationType; // "মক্কী" | "মাদানী"

  const Surah({
    required this.number,
    required this.nameArabic,
    required this.nameBengali,
    required this.ayahs,
    required this.revelationType,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      number: json['number'] as int,
      nameArabic: json['nameArabic'] as String,
      nameBengali: json['nameBengali'] as String,
      ayahs: json['ayahs'] as int,
      revelationType: json['revelationType'] as String,
    );
  }
}

/// assets/data/surahs.json থেকে ১১৪টা সূরা লোড করে।
class SurahRepository {
  static List<Surah>? _cache;

  static Future<List<Surah>> loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/surahs.json');
    final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
    final surahs = list.map((e) => Surah.fromJson(e as Map<String, dynamic>)).toList();
    _cache = surahs;
    return _cache!;
  }
}
