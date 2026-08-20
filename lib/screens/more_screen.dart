import 'package:flutter/material.dart';
import 'tasbih_screen.dart';
import 'qibla_screen.dart';
import 'names_screen.dart';
import 'hijri_calendar_screen.dart';
import 'zakat_calculator_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';
import '../theme/app_colors.dart';

class _MenuEntry {
  final String label;
  final String imagePath;  // asset path instead of IconData
  final WidgetBuilder? builder;
  const _MenuEntry(this.label, this.imagePath, [this.builder]);
}

/// গার্ড-সিস্টেম (grid) ভিউ — প্রতি লাইনে ৩টা করে বড় কার্ড, আগের ListTile
/// লিস্ট ভিউয়ের বদলে।
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
      // 10.5: হোম স্ক্রিনের quick-access থেকে সরিয়ে এখানে আনা হয়েছে। এখনো নিজস্ব স্ক্রিন
      // বানানো হয়নি (builder: null) — ট্যাপ করলে কিছু হবে না, শুধু "শীঘ্রই আসছে" দেখাবে।
      _MenuEntry('হাদিস সংকলন', 'assets/images/menu/img_hadith.png'),
      _MenuEntry('রমজান', 'assets/images/menu/img_ramadan.png'),
      _MenuEntry('হজ্জ গাইড', 'assets/images/menu/img_hajj.png'),
      _MenuEntry('সেটিংস', 'assets/images/menu/img_settings.png', (_) => const SettingsScreen()),
      _MenuEntry('অ্যাপ সম্পর্কে', 'assets/images/menu/img_info.png', (_) => const AboutScreen()),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('আরো')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.85,
        ),
        itemBuilder: (context, i) {
          final e = entries[i];
          final comingSoon = e.builder == null;
          return Material(
            color: comingSoon ? AppColors.cardBackground.withValues(alpha: 0.6) : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(18),
            elevation: comingSoon ? 0 : 1.5,
            shadowColor: AppColors.primary.withValues(alpha: 0.15),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: e.builder == null
                  ? null
                  : () => Navigator.of(context).push(MaterialPageRoute(builder: e.builder!)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Opacity(
                      opacity: comingSoon ? 0.45 : 1.0,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.iconCircleBackground,
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          e.imagePath,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      e.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: comingSoon ? Colors.grey.shade500 : AppColors.onSurface,
                      ),
                    ),
                    if (comingSoon) ...[
                      const SizedBox(height: 2),
                      const Text('শীঘ্রই আসছে', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
