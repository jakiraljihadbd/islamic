import 'package:flutter/material.dart';
import 'tasbih_screen.dart';
import 'qibla_screen.dart';
import 'names_screen.dart';
import 'hijri_calendar_screen.dart';
import 'zakat_calculator_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';

class _MenuEntry {
  final String label;
  final String imagePath;  // asset path instead of IconData
  final WidgetBuilder? builder;
  const _MenuEntry(this.label, this.imagePath, [this.builder]);
}

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = [
      _MenuEntry('তাসবিহ', 'assets/images/menu/img_tasbih.png', (_) => const TasbihScreen()),
      _MenuEntry('কিবলা নির্দেশক', 'assets/images/menu/img_qibla.png', (_) => const QiblaScreen()),
      _MenuEntry('আল্লাহর নাম', 'assets/images/menu/img_names.png', (_) => const NamesScreen()),
      _MenuEntry('ক্যালেন্ডার', 'assets/images/menu/img_calendar.png', (_) => const HijriCalendarScreen()),
      _MenuEntry('যাকাত ক্যালকুলেটর', 'assets/images/menu/img_zakat.png', (_) => const ZakatCalculatorScreen()),
      _MenuEntry('সেটিংস', 'assets/images/menu/img_settings.png', (_) => const SettingsScreen()),
      _MenuEntry('অ্যাপ সম্পর্কে', 'assets/images/menu/img_info.png', (_) => const AboutScreen()),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('আরো')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, i) {
          final e = entries[i];
          return ListTile(
            leading: SizedBox(
              width: 36,
              height: 36,
              child: Image.asset(
                e.imagePath,
                fit: BoxFit.contain,
              ),
            ),
            title: Text(e.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: e.builder == null
                ? null
                : () => Navigator.of(context).push(MaterialPageRoute(builder: e.builder!)),
          );
        },
      ),
    );
  }
}
