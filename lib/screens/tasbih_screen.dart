import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';

/// Ported from TasbihActivity.java - counter + target chips (33/99/100) + reset.
/// 6.4: count/totalCount/targetCount শেয়ার্ড প্রেফারেন্স দিয়ে persist হয়
/// (key: tasbih_count/tasbih_total_count/tasbih_target_count) — লজিক অপরিবর্তিত।
/// UI আপডেট: gradient header, বড় ট্যাপযোগ্য কাউন্টার রিং, দ্বিক্‌র লেবেল
/// চিপ (আরবি) যোগ করা হয়েছে — শুধু ডিসপ্লে/লেবেল, কাউন্ট লজিকে কোনো পরিবর্তন নেই।
class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _Dhikr {
  final String arabic;
  final String bengali;
  const _Dhikr(this.arabic, this.bengali);
}

const _dhikrPhrases = [
  _Dhikr('سُبْحَانَ اللَّه', 'সুবহানাল্লাহ'),
  _Dhikr('اللَّهُ أَكْبَر', 'আল্লাহু আকবর'),
  _Dhikr('أَسْتَغْفِرُ اللَّه', 'আস্তাগফিরুল্লাহ'),
  _Dhikr('الْحَمْدُ لِلَّه', 'আলহামদুলিল্লাহ'),
];

class _TasbihScreenState extends State<TasbihScreen> with SingleTickerProviderStateMixin {
  static const _keyCount = 'tasbih_count';
  static const _keyTotal = 'tasbih_total_count';
  static const _keyTarget = 'tasbih_target_count';
  static const _keyDhikrIndex = 'tasbih_dhikr_index';

  int _count = 0;
  int _totalCount = 0;
  int _targetCount = 33;
  int _dhikrIndex = 0;
  bool _loaded = false;

  late final AnimationController _bumpController;

  @override
  void initState() {
    super.initState();
    _bumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
      lowerBound: 0.0,
      upperBound: 0.06,
    );
    _loadSaved();
  }

  @override
  void dispose() {
    _bumpController.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _count = prefs.getInt(_keyCount) ?? 0;
      _totalCount = prefs.getInt(_keyTotal) ?? 0;
      _targetCount = prefs.getInt(_keyTarget) ?? 33;
      _dhikrIndex = (prefs.getInt(_keyDhikrIndex) ?? 0).clamp(0, _dhikrPhrases.length - 1);
      _loaded = true;
    });
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCount, _count);
    await prefs.setInt(_keyTotal, _totalCount);
    await prefs.setInt(_keyTarget, _targetCount);
    await prefs.setInt(_keyDhikrIndex, _dhikrIndex);
  }

  void _increment() {
    setState(() {
      _count++;
      _totalCount++;
      if (_count >= _targetCount) {
        HapticFeedback.heavyImpact(); // longer buzz on target reached
        _count = 0;
      } else {
        HapticFeedback.lightImpact();
      }
    });
    _bumpController.forward(from: 0).then((_) => _bumpController.reverse());
    _persist();
  }

  void _reset() {
    setState(() => _count = 0);
    _persist();
  }

  void _setTarget(int target) {
    setState(() {
      _targetCount = target;
      _count = 0;
    });
    _persist();
  }

  void _setDhikr(int index) {
    setState(() => _dhikrIndex = index);
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final progress = (_count / _targetCount).clamp(0.0, 1.0);
    final dhikr = _dhikrPhrases[_dhikrIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
              decoration: const BoxDecoration(
                gradient: AppColors.headerGradient,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const Text('তাসবিহ কাউন্টার',
                          style: TextStyle(
                              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _HeaderStat(label: 'সর্বমোট', value: '$_totalCount'),
                      _HeaderStat(label: 'লক্ষ্য', value: '$_targetCount'),
                      _HeaderStat(
                          label: 'বাকি',
                          value: '${(_targetCount - _count).clamp(0, _targetCount)}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Dhikr selector chips
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                scrollDirection: Axis.horizontal,
                itemCount: _dhikrPhrases.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final selected = i == _dhikrIndex;
                  return ChoiceChip(
                    label: Text(_dhikrPhrases[i].bengali),
                    selected: selected,
                    onSelected: (_) => _setDhikr(i),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                    backgroundColor: AppColors.surface,
                    side: BorderSide(color: selected ? Colors.transparent : AppColors.divider),
                  );
                },
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    // Current dhikr card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.iconCircleBackground,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(dhikr.arabic,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                  fontFamily: 'Bahij', fontSize: 26, color: AppColors.primaryDark)),
                          const SizedBox(height: 4),
                          Text(dhikr.bengali,
                              style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Target chips
                    Wrap(
                      spacing: 8,
                      children: [33, 99, 100].map((t) {
                        final selected = _targetCount == t;
                        return ChoiceChip(
                          label: Text('$t'),
                          selected: selected,
                          onSelected: (_) => _setTarget(t),
                          selectedColor: AppColors.secondary,
                          labelStyle: TextStyle(
                            color: selected ? AppColors.onSecondary : AppColors.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                          backgroundColor: AppColors.surface,
                          side: BorderSide(color: selected ? Colors.transparent : AppColors.divider),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),

                    // Tap-anywhere counter ring
                    AnimatedBuilder(
                      animation: _bumpController,
                      builder: (context, child) => Transform.scale(
                        scale: 1 - _bumpController.value,
                        child: child,
                      ),
                      child: GestureDetector(
                        onTap: _increment,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 240,
                              height: 240,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: progress),
                                duration: const Duration(milliseconds: 250),
                                builder: (context, value, _) => CircularProgressIndicator(
                                  value: value,
                                  strokeWidth: 12,
                                  strokeCap: StrokeCap.round,
                                  backgroundColor: AppColors.divider,
                                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                                ),
                              ),
                            ),
                            Container(
                              width: 190,
                              height: 190,
                              decoration: const BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: Color(0x14000000), blurRadius: 16, spreadRadius: 2),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('$_count',
                                      style: const TextStyle(
                                          fontSize: 64,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryDark)),
                                  Text('/ $_targetCount',
                                      style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                                  const SizedBox(height: 6),
                                  Text('ট্যাপ করুন',
                                      style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    OutlinedButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.refresh),
                      label: const Text('বর্তমান কাউন্ট রিসেট'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  const _HeaderStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}
