import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';

enum _SalatStatus { none, done, missed }

class _SalatEntry {
  final String id;
  final String label;
  final IconData icon;
  const _SalatEntry(this.id, this.label, this.icon);
}

const _salatEntries = [
  _SalatEntry('fajr', 'ফজর', Icons.wb_twilight_outlined),
  _SalatEntry('dhuhr', 'যোহর', Icons.wb_sunny_outlined),
  _SalatEntry('asr', 'আসর', Icons.filter_drama_outlined),
  _SalatEntry('maghrib', 'মাগরিব', Icons.nights_stay_outlined),
  _SalatEntry('isha', 'এশা', Icons.bedtime_outlined),
];

/// Phase-3: আজকের সালাত ট্র্যাকার — ৫ ওয়াক্তের প্রতিটার জন্য টিক (আদায়) বা
/// ক্রস (কাজা) মার্ক করা যায়। shared_preferences এ তারিখ-ভিত্তিক key দিয়ে persist
/// হয় (yyyy-mm-dd প্রতিদিন আলাদা key), তাই রাত পেরোলে নতুন দিনের জন্য
/// স্বয়ংক্রিয়ভাবে খালি অবস্থায় শুরু হয়, আগের দিনগুলোর ডেটা মুছে যায় না।
class SalatTrackerCard extends StatefulWidget {
  const SalatTrackerCard({super.key});

  @override
  State<SalatTrackerCard> createState() => _SalatTrackerCardState();
}

class _SalatTrackerCardState extends State<SalatTrackerCard> {
  late final String _dateKey;
  Map<String, _SalatStatus> _status = {
    for (final e in _salatEntries) e.id: _SalatStatus.none,
  };
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _load();
  }

  String _prefKey(String id) => 'salat_${_dateKey}_$id';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final loaded = <String, _SalatStatus>{};
    for (final e in _salatEntries) {
      final v = prefs.getInt(_prefKey(e.id)) ?? 0;
      loaded[e.id] = _SalatStatus.values[v.clamp(0, _SalatStatus.values.length - 1)];
    }
    if (!mounted) return;
    setState(() {
      _status = loaded;
      _loaded = true;
    });
  }

  Future<void> _setStatus(String id, _SalatStatus status) async {
    setState(() => _status[id] = status);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey(id), status.index);
  }

  /// পিলে ট্যাপ করলে অবস্থা চক্রাকারে বদলায়: none → আদায় → কাজা → none।
  void _cycle(String id) {
    final current = _status[id] ?? _SalatStatus.none;
    final next = _SalatStatus.values[(current.index + 1) % _SalatStatus.values.length];
    _setStatus(id, next);
  }

  @override
  Widget build(BuildContext context) {
    final doneCount = _status.values.where((s) => s == _SalatStatus.done).length;
    final allDone = doneCount == _salatEntries.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('আজকের সালাত',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: allDone
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$doneCount/৫ আদায়',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: allDone ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!_loaded)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _salatEntries
                    .map(
                      (e) => _SalatPill(
                        entry: e,
                        status: _status[e.id] ?? _SalatStatus.none,
                        onTap: () => _cycle(e.id),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

/// রেফারেন্স ডিজাইনের মতো stadium-shaped পিল: লেবেল + ডানে ছোট স্ট্যাটাস সার্কেল।
/// আদায় → সবুজ পিল + সাদা টিক, কাজা → লাল পিল + সাদা ক্রস, none → হালকা আউটলাইন
/// পিল + ধূসর "!" (এখনো মার্ক করা হয়নি)। ট্যাপ করলে চক্রাকারে অবস্থা বদলায়।
class _SalatPill extends StatelessWidget {
  final _SalatEntry entry;
  final _SalatStatus status;
  final VoidCallback onTap;

  const _SalatPill({
    required this.entry,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = status == _SalatStatus.done;
    final isMissed = status == _SalatStatus.missed;

    final Color fill = isDone
        ? AppColors.success
        : (isMissed ? AppColors.error : AppColors.surface);
    final Color textColor = (isDone || isMissed) ? Colors.white : AppColors.onSurface;
    final Color border = (isDone || isMissed) ? Colors.transparent : AppColors.divider;

    final IconData badgeIcon =
        isDone ? Icons.check_rounded : (isMissed ? Icons.close_rounded : Icons.priority_high_rounded);
    final Color badgeBg = isDone
        ? Colors.white
        : (isMissed ? Colors.white : AppColors.onSurface.withValues(alpha: 0.75));
    final Color badgeIconColor = isDone
        ? AppColors.success
        : (isMissed ? AppColors.error : Colors.white);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: border, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              entry.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(width: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(color: badgeBg, shape: BoxShape.circle),
              child: Icon(badgeIcon, size: 13, color: badgeIconColor),
            ),
          ],
        ),
      ),
    );
  }
}
