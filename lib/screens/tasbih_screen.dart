import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';

/// Ported from TasbihActivity.java - counter + target chips (33/99/100) + reset.
/// 6.4: count/totalCount/targetCount এখন shared_preferences দিয়ে persist হয় —
/// অ্যাপ বন্ধ করে আবার খুললেও শেষ অবস্থা মনে থাকে।
class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  static const _keyCount = 'tasbih_count';
  static const _keyTotal = 'tasbih_total_count';
  static const _keyTarget = 'tasbih_target_count';

  int _count = 0;
  int _totalCount = 0;
  int _targetCount = 33;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _count = prefs.getInt(_keyCount) ?? 0;
      _totalCount = prefs.getInt(_keyTotal) ?? 0;
      _targetCount = prefs.getInt(_keyTarget) ?? 33;
      _loaded = true;
    });
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCount, _count);
    await prefs.setInt(_keyTotal, _totalCount);
    await prefs.setInt(_keyTarget, _targetCount);
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

  @override
  Widget build(BuildContext context) {
    final progress = _count / _targetCount;

    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('তাসবিহ')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text('মোট: $_totalCount', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 8),
              Text('লক্ষ্য: $_targetCount', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                children: [33, 99, 100].map((t) {
                  return ChoiceChip(
                    label: Text('$t'),
                    selected: _targetCount == t,
                    onSelected: (_) => _setTarget(t),
                  );
                }).toList(),
              ),
              const Spacer(),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CircularProgressIndicator(
                      value: progress.clamp(0, 1),
                      strokeWidth: 10,
                      backgroundColor: AppColors.divider,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                  Text('$_count', style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold)),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh),
                    label: const Text('রিসেট'),
                  ),
                  FilledButton(
                    onPressed: _increment,
                    style: FilledButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(28),
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Icon(Icons.touch_app, size: 32),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
