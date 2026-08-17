import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// একটা একক দোয়া — আরবি, উচ্চারণ, বাংলা অনুবাদ, রেফারেন্স।
class Dua {
  final String title;
  final String arabic;
  final String uccharon;
  final String bengali;
  final String reference;

  const Dua({
    required this.title,
    required this.arabic,
    required this.uccharon,
    required this.bengali,
    required this.reference,
  });

  factory Dua.fromJson(Map<String, dynamic> json) {
    return Dua(
      title: json['title'] as String,
      arabic: json['arabic'] as String,
      uccharon: json['uccharon'] as String,
      bengali: json['bengali'] as String,
      reference: json['reference'] as String,
    );
  }
}

/// একটা দোয়ার ক্যাটাগরি (যেমন "সকাল-সন্ধ্যার দোয়া") — কতগুলো Dua ধারণ করে।
class DuaCategory {
  final String id;
  final String category;
  final List<Dua> duas;

  const DuaCategory({
    required this.id,
    required this.category,
    required this.duas,
  });

  factory DuaCategory.fromJson(Map<String, dynamic> json) {
    final list = (json['duas'] as List<dynamic>)
        .map((e) => Dua.fromJson(e as Map<String, dynamic>))
        .toList();
    return DuaCategory(
      id: json['id'] as String,
      category: json['category'] as String,
      duas: list,
    );
  }
}

/// assets/data/duas.json থেকে সবগুলো দোয়া-ক্যাটাগরি লোড করে।
class DuaRepository {
  static List<DuaCategory>? _cache;

  static Future<List<DuaCategory>> loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/duas.json');
    final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
    _cache = list
        .map((e) => DuaCategory.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
  }
}
