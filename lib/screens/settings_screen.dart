import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/theme_controller.dart';

/// 6.3: ডার্ক মোড টগল এখন সরাসরি ThemeController-এর সাথে জোড়া লাগানো —
/// টগল করলেই পুরো অ্যাপে সাথে সাথে থিম বদলে যায় এবং shared_preferences
/// দিয়ে পছন্দ মনে রাখা হয় (পরের বার অ্যাপ খুললেও একই থাকে)।
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('সেটিংস')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeController.instance,
              builder: (context, mode, _) {
                final isDark = mode == ThemeMode.dark;
                return SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.primary),
                  title: const Text('ডার্ক মোড'),
                  subtitle: const Text('পুরো অ্যাপে সাথে সাথে প্রয়োগ হয়'),
                  value: isDark,
                  activeColor: AppColors.primary,
                  onChanged: (value) => ThemeController.instance.setDark(value),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
