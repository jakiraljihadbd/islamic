import 'package:flutter/material.dart';
import '../models/dua.dart';
import '../theme/app_colors.dart';

/// একটা নির্দিষ্ট দোয়া-ক্যাটাগরির ভেতরের সবগুলো দোয়া (আরবি + উচ্চারণ + অনুবাদ) দেখায়।
class DuaDetailScreen extends StatelessWidget {
  final DuaCategory category;

  const DuaDetailScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category.category)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: category.duas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, i) => _DuaCard(dua: category.duas[i]),
      ),
    );
  }
}

class _DuaCard extends StatelessWidget {
  final Dua dua;

  const _DuaCard({required this.dua});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dua.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              dua.arabic,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontFamily: 'Arabic',
                fontSize: 22,
                height: 1.8,
                color: AppColors.onSurface,
              ),
            ),
            const Divider(height: 24, color: AppColors.divider),
            Text(
              dua.uccharon,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 14,
                color: AppColors.primaryVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              dua.bengali,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                dua.reference,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
