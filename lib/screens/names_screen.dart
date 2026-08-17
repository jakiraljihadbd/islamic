import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../theme/app_colors.dart';

class _AllahName {
  final int number;
  final String arabic;
  final String transliteration;
  final String bengali;
  const _AllahName({
    required this.number,
    required this.arabic,
    required this.transliteration,
    required this.bengali,
  });

  factory _AllahName.fromJson(Map<String, dynamic> json) => _AllahName(
        number: json['number'] as int,
        arabic: json['arabic'] as String,
        transliteration: json['transliteration'] as String,
        bengali: json['bengali'] as String,
      );
}

/// 5.1: আল্লাহর ৯৯ নাম (আসমাউল হুসনা) — লিস্ট স্ক্রিন।
class NamesScreen extends StatefulWidget {
  const NamesScreen({super.key});

  @override
  State<NamesScreen> createState() => _NamesScreenState();
}

class _NamesScreenState extends State<NamesScreen> {
  List<_AllahName>? _names;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString('assets/data/names_of_allah.json');
    final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
    final names = list.map((e) => _AllahName.fromJson(e as Map<String, dynamic>)).toList();
    if (!mounted) return;
    setState(() => _names = names);
  }

  @override
  Widget build(BuildContext context) {
    final names = _names;
    return Scaffold(
      appBar: AppBar(title: const Text('আল্লাহর ৯৯ নাম')),
      body: names == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: names.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, i) {
                final n = names[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                      child: Text('${n.number}', style: const TextStyle(color: AppColors.secondary, fontSize: 12)),
                    ),
                    title: Text(
                      n.arabic,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(fontFamily: 'Arabic', fontSize: 20),
                    ),
                    subtitle: Text('${n.transliteration}  •  ${n.bengali}'),
                  ),
                );
              },
            ),
    );
  }
}
