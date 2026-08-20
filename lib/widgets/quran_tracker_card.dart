import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';

/// Phase-4 (ডেমো): আজকের কুরআন তিলাওয়াত ট্র্যাকার — পড়ার সময় (স্টপওয়াচ) আর
/// আয়াত সংখ্যা (ম্যানুয়াল +/-) ট্র্যাক করে, তারিখ-ভিত্তিক key দিয়ে
/// shared_preferences এ persist হয় (SalatTrackerCard এর প্যাটার্ন অনুসরণ করে)।
/// এটা "ডেমো" কারণ কুরআন রিডারের সাথে অটোমেটিক পেজ/আয়াত ডিটেকশন যুক্ত
/// করা হয়নি এখনো (PDF viewer সরিয়ে ফেলা হয়েছে, APK সাইজ কমানোর জন্য) — সময়
/// ও আয়াত সংখ্যা ইউজার নিজে স্টার্ট/স্টপ ও +/- দিয়ে আপডেট করে, ডেটা real ভাবে সেভ থাকে।
class QuranTrackerCard extends StatefulWidget {
  const QuranTrackerCard({super.key});

  @override
  State<QuranTrackerCard> createState() => _QuranTrackerCardState();
}

class _QuranTrackerCardState extends State<QuranTrackerCard> {
  late final String _dateKey;
  int _seconds = 0;
  int _ayahs = 0;
  bool _loaded = false;
  bool _running = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _load();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String get _keySeconds => 'quran_track_${_dateKey}_seconds';
  String get _keyAyahs => 'quran_track_${_dateKey}_ayahs';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _seconds = prefs.getInt(_keySeconds) ?? 0;
      _ayahs = prefs.getInt(_keyAyahs) ?? 0;
      _loaded = true;
    });
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySeconds, _seconds);
    await prefs.setInt(_keyAyahs, _ayahs);
  }

  void _toggleRunning() {
    setState(() => _running = !_running);
    if (_running) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _seconds++);
        _persist();
      });
    } else {
      _ticker?.cancel();
    }
  }

  void _changeAyahs(int delta) {
    setState(() => _ayahs = (_ayahs + delta).clamp(0, 999999));
    _persist();
  }

  String get _formattedTime {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.06),
              AppColors.secondary.withValues(alpha: 0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('আজকের তিলাওয়াত',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('ডেমো',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondaryVariant)),
                    ),
                  ],
                ),
                Icon(Icons.auto_stories_outlined,
                    size: 18, color: AppColors.primary.withValues(alpha: 0.6)),
              ],
            ),
            const SizedBox(height: 10),
            if (!_loaded)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      icon: Icons.timer_outlined,
                      label: 'সময়',
                      value: _formattedTime,
                      trailing: SizedBox(
                        height: 30,
                        width: 30,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          style: IconButton.styleFrom(
                            backgroundColor: _running
                                ? AppColors.error.withValues(alpha: 0.12)
                                : AppColors.primary.withValues(alpha: 0.12),
                          ),
                          icon: Icon(
                            _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 16,
                            color: _running ? AppColors.error : AppColors.primary,
                          ),
                          onPressed: _toggleRunning,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.format_list_numbered_rounded,
                      label: 'আয়াত',
                      value: '$_ayahs',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _MiniButton(icon: Icons.remove_rounded, onTap: () => _changeAyahs(-1)),
                          const SizedBox(width: 4),
                          _MiniButton(icon: Icons.add_rounded, onTap: () => _changeAyahs(1)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget trailing;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: Colors.grey[600])),
                Text(value,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MiniButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: AppColors.primary),
      ),
    );
  }
}
