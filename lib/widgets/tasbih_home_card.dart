import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/tasbih_screen.dart';
import '../theme/app_colors.dart';

/// 10.9: হোম স্ক্রিনে তাসবিহর কম্প্যাক্ট প্রিভিউ কার্ড। TasbihScreen এ আগে থেকেই
/// থাকা persist লজিক (SharedPreferences: tasbih_count/tasbih_target_count/
/// tasbih_dhikr_index) থেকেই ডেটা পড়া হয় — এখানে নতুন কোনো persist লজিক নেই,
/// শুধু read-only প্রিভিউ। ট্যাপ করলে পুরো TasbihScreen এ নেভিগেট করে।
///
/// দ্বিক্‌র তালিকা tasbih_screen.dart এর _dhikrPhrases এর সাথে ইনডেক্স-বাই-ইনডেক্স
/// মিলিয়ে রাখা হয়েছে (ওটা প্রাইভেট বলে import করা যায় না, তাই এখানে একই ক্রমে
/// বাংলা লেবেল আলাদা করে রাখা হলো) — TasbihScreen এ তালিকা বদলালে এটাও মেলাতে হবে।
const _dhikrLabels = ['সুবহানাল্লাহ', 'আল্লাহু আকবর', 'আস্তাগফিরুল্লাহ', 'আলহামদুলিল্লাহ'];

class TasbihHomeCard extends StatefulWidget {
  const TasbihHomeCard({super.key});

  @override
  State<TasbihHomeCard> createState() => _TasbihHomeCardState();
}

class _TasbihHomeCardState extends State<TasbihHomeCard> {
  int _count = 0;
  int _targetCount = 33;
  int _dhikrIndex = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _count = prefs.getInt('tasbih_count') ?? 0;
      _targetCount = prefs.getInt('tasbih_target_count') ?? 33;
      _dhikrIndex = (prefs.getInt('tasbih_dhikr_index') ?? 0).clamp(0, _dhikrLabels.length - 1);
      _loaded = true;
    });
  }

  Future<void> _openTasbihScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TasbihScreen()),
    );
    // TasbihScreen থেকে ফিরে এলে কাউন্ট/টার্গেট/দ্বিক্‌র বদলে থাকতে পারে বলে রিফ্রেশ করা হয়।
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final label = _loaded ? _dhikrLabels[_dhikrIndex] : '...';
    final countText = _loaded ? '$_count/$_targetCount' : '';

    return InkWell(
      onTap: _openTasbihScreen,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.iconCircleBackground,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.fingerprint_rounded, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              const Text('তাসবিহ ট্র্যাকার',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400)),
              const Spacer(),
              // একলাইন pill: বর্তমান জিকিরের নাম + কাউন্ট/টার্গেট, যেমন "সুবহানাল্লাহ ৩৩/৩৩"
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        countText,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
