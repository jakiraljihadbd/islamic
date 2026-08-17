import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// একটা সূরার তথ্য — assets/data/surahs.json থেকে লোড হয়।
class Surah {
  final int number;
  final String nameArabic;
  final String nameBengali;
  final int ayahs;
  final String revelationType; // "মক্কী" | "মাদানী"
  final int pdfPage;
  final bool pageEstimated;

  const Surah({
    required this.number,
    required this.nameArabic,
    required this.nameBengali,
    required this.ayahs,
    required this.revelationType,
    this.pdfPage = 1,
    this.pageEstimated = false,
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

  Surah copyWithPage(int page, bool estimated) => Surah(
        number: number,
        nameArabic: nameArabic,
        nameBengali: nameBengali,
        ayahs: ayahs,
        revelationType: revelationType,
        pdfPage: page,
        pageEstimated: estimated,
      );
}

/// assets/data/surahs.json থেকে ১১৪টা সূরা লোড করে।
class SurahRepository {
  static List<Surah>? _cache;

  static Future<List<Surah>> loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/surahs.json');
    final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
    var surahs = list.map((e) => Surah.fromJson(e as Map<String, dynamic>)).toList();

    // surah number -> PDF page mapping যোগ করা হচ্ছে।
    // সূরা ১-৭৭: বান্ডেল quran.pdf-এর ডেকোরেটেড টাইটেল-ব্যানার পেজ থেকে সরাসরি শনাক্ত করা (নির্ভুল)।
    // সূরা ৭৮-১১৪ (জুয আম্মার ছোট সূরাগুলো): আয়াত-সংখ্যা অনুপাতে আনুমানিক হিসাব করা,
    // কারণ একই পেজে একাধিক ছোট সূরা শুরু হয় — পরে ম্যানুয়ালি ভেরিফাই করে নির্ভুল করা উচিত।
    try {
      final pageRaw = await rootBundle.loadString('assets/data/surah_pages.json');
      final Map<String, dynamic> pageMap = jsonDecode(pageRaw) as Map<String, dynamic>;
      surahs = surahs.map((s) {
        final entry = pageMap['${s.number}'] as Map<String, dynamic>?;
        if (entry == null) return s;
        return s.copyWithPage(entry['page'] as int, entry['estimated'] as bool);
      }).toList();
    } catch (_) {
      // page map না পাওয়া গেলে ডিফল্ট page=1 থেকে যাবে।
    }

    _cache = surahs;
    return _cache!;
  }
}
