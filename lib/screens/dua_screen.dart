import 'package:flutter/material.dart';
import '../models/dua.dart';
import '../theme/app_colors.dart';
import 'dua_detail_screen.dart';

class DuaScreen extends StatefulWidget {
  const DuaScreen({super.key});

  @override
  State<DuaScreen> createState() => _DuaScreenState();
}

// প্রতিটা ক্যাটাগরির জন্য আলাদা Material আইকন — original res/drawable/ic_{...}.xml এর
// সাথে সবচেয়ে কাছাকাছি ম্যাপিং (ভেক্টর আইকনগুলো সাধারণ, তাই Material Icons ব্যবহার করা হয়েছে)।
const Map<String, IconData> _categoryIcons = {
  'sokal_sondha': Icons.wb_twilight,
  'khabarer_dua': Icons.restaurant_outlined,
  'ghumer_dua': Icons.bedtime_outlined,
  'sofor_dua': Icons.flight_outlined,
  'istighfar': Icons.self_improvement_outlined,
  'durud_sharif': Icons.auto_awesome_outlined,
  'namazer_dua': Icons.mosque_outlined,
  'osusthotar_dua': Icons.healing_outlined,
  'bibaher_dua': Icons.favorite_outline,
  'ruqyah': Icons.shield_outlined,
};

class _DuaScreenState extends State<DuaScreen> {
  List<DuaCategory>? _categories;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final categories = await DuaRepository.loadAll();
    if (!mounted) return;
    setState(() => _categories = categories);
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categories;
    return Scaffold(
      appBar: AppBar(title: const Text('দোয়া')),
      body: categories == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final c = categories[i];
                return Card(
                  child: ListTile(
                    leading: Icon(_categoryIcons[c.id] ?? Icons.volunteer_activism_outlined, color: AppColors.primary),
                    title: Text(c.category),
                    subtitle: Text('${c.duas.length}টা দোয়া'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DuaDetailScreen(category: c),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
