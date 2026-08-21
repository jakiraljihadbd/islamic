import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/theme_controller.dart';
import '../services/time_format_controller.dart';
import '../widgets/alarm_reliability_dialog.dart';

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
          const SizedBox(height: 12),
          // 11.2 (worklist_salat_screen.txt): সময় ফরম্যাট — ১২/২৪ ঘন্টা
          Card(
            child: ValueListenableBuilder<bool>(
              valueListenable: TimeFormatController.instance,
              builder: (context, is24Hour, _) {
                return SwitchListTile(
                  secondary: const Icon(Icons.access_time_outlined, color: AppColors.primary),
                  title: const Text('২৪-ঘন্টা সময় ফরম্যাট'),
                  subtitle: Text(
                    is24Hour ? 'যেমন: ১৮:৩৫' : 'বন্ধ থাকলে ১২-ঘন্টা AM/PM ফরম্যাট দেখাবে (যেমন: ৬:৩৫ PM)',
                  ),
                  value: is24Hour,
                  activeColor: AppColors.primary,
                  onChanged: (value) => TimeFormatController.instance.setIs24Hour(value),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
              title: const Text('আজান যেন মিস না হয়'),
              subtitle: const Text('ব্যাটারি অপটিমাইজেশন ও অটোস্টার্ট সেটিংস ঠিক করুন'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showAlarmReliabilityDialog(context),
            ),
          ),
        ],
      ),
    );
  }
}
