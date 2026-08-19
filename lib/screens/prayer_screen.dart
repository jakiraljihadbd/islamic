import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

import '../services/prayer_time_service.dart';
import '../services/aladhan_service.dart';
import '../services/alarm_service.dart';
import '../theme/app_colors.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({Key? key}) : super(key: key);

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  double _lat = 23.8103;
  double _lng = 90.4125;
  DailyPrayerTimes? _times;
  bool _loading = true;
  MapEntry<String, DateTime>? _nextPrayer;
  List<bool> _toggles = [];
  int _activeIndex = -1;

  @override
  void initState() {
    super.initState();
    _initServicesAndLoad();
  }

  Future<void> _initServicesAndLoad() async {
    try {
      await AlarmService.instance.init();
    } catch (_) {}
    await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final localCalc = PrayerTimeService.calculate(latitude: _lat, longitude: _lng, date: DateTime.now());
      _times = localCalc;
    } catch (_) {}

    try {
      final fetched = await AladhanService.fetchTimings(latitude: _lat, longitude: _lng, date: DateTime.now(), method: 1);
      _times = fetched;
    } catch (_) {}

    final count = _times?.ordered.length ?? _prayerMeta.length;
    _toggles = List.filled(count, false);
    final prefs = await SharedPreferences.getInstance();
    for (var i = 0; i < count; i++) {
      _toggles[i] = prefs.getBool('alarm_enabled_$i') ?? false;
    }

    if (_times != null) {
      final now = DateTime.now();
      _nextPrayer = PrayerTimeService.nextPrayer(latitude: _lat, longitude: _lng, now: now);
      
      final times = _times!.ordered;
      _activeIndex = -1;
      for (var i = 0; i < times.length; i++) {
        if (now.isBefore(times[i].value)) {
          _activeIndex = i;
          break;
        }
      }
    }

    setState(() => _loading = false);
  }

  String _fmtTime(DateTime t) => DateFormat('HH:mm').format(t);

  Future<void> _onToggleChanged(int index, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('alarm_enabled_$index', value);
    setState(() => _toggles[index] = value);

    final times = _times?.ordered;
    DateTime when;
    if (times != null && index < times.length) {
      when = times[index].value;
    } else {
      when = DateTime.now().add(const Duration(minutes: 1));
    }

    final id = index + 1;
    if (value) {
      // Ask once for battery-optimization exemption the first time someone
      // turns an alarm on — this is what actually keeps the azan reliable
      // on Xiaomi/Oppo/Vivo/Samsung-style aggressive battery savers.
      await AlarmService.instance.requestIgnoreBatteryOptimizations();
      await AlarmService.instance.schedulePrayer(
        id: id,
        dateTime: when,
        prayerName: _prayerMeta[index].name,
        recurring: true,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_prayerMeta[index].name} এর জন্য আলার্ম চালু হয়েছে')),
        );
      }
    } else {
      await AlarmService.instance.cancelPrayer(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_prayerMeta[index].name} এর জন্য আলার্ম বন্ধ হয়েছে')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final times = _times?.ordered;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('বুধ, ২१ সফর', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildProgressSection(),
                  const SizedBox(height: 24),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: List.generate(_prayerMeta.length, (i) {
                        final meta = _prayerMeta[i];
                        final time = times != null && i < times.length ? _fmtTime(times[i].value) : '--:--';
                        final isActive = _activeIndex == i;
                        
                        return _buildPrayerRow(
                          meta: meta,
                          time: time,
                          index: i,
                          isActive: isActive,
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  painter: _SemiCirclePainter(
                    progress: _getProgressPercentage(),
                    activeIndex: _activeIndex,
                  ),
                  size: const Size(double.infinity, 160),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      _nextPrayer?.key ?? 'নামাজ',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'পরবর্তী নামাজ',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _nextPrayer != null ? _fmtTime(_nextPrayer!.value) : '--:--',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 8,
            children: [
              _buildChip('সাভার', Colors.grey[300]!),
              _buildChip('সাহরি: ০४:१२', Colors.grey[300]!),
              _buildChip('ইফতার: ०६:३५', Colors.grey[300]!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.black87),
      ),
    );
  }

  Widget _buildPrayerRow({
    required _PrayerMeta meta,
    required String time,
    required int index,
    required bool isActive,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? Colors.green.withOpacity(0.08) : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: isActive ? Border.all(color: AppColors.success.withOpacity(0.3)) : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: meta.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(meta.icon, color: meta.color, size: 22),
            ),
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meta.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: index < _toggles.length ? _toggles[index] : false,
                onChanged: (v) => _onToggleChanged(index, v),
                activeColor: AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getProgressPercentage() {
    if (_times == null) return 0;
    
    final now = DateTime.now();
    final times = _times!.ordered;
    
    if (_activeIndex == -1 || _activeIndex >= times.length) {
      return 0;
    }
    
    final currentPrayer = times[_activeIndex].value;
    final nextPrayer = _activeIndex + 1 < times.length ? times[_activeIndex + 1].value : currentPrayer.add(const Duration(hours: 1));
    
    final total = nextPrayer.difference(currentPrayer).inMinutes;
    final elapsed = now.difference(currentPrayer).inMinutes;
    
    if (elapsed < 0) return 0;
    if (elapsed > total) return 1;
    
    return elapsed / total;
  }
}

// Custom painter for semi-circle progress indicator
class _SemiCirclePainter extends CustomPainter {
  final double progress;
  final int activeIndex;

  _SemiCirclePainter({required this.progress, required this.activeIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height;
    final radius = size.width / 2 - 8;

    // Background gray arc
    final bgPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      math.pi,
      math.pi,
      false,
      bgPaint,
    );

    // Progress green arc
    if (activeIndex >= 0) {
      final progressPaint = Paint()
        ..color = AppColors.success
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
        math.pi,
        math.pi * progress,
        false,
        progressPaint,
      );
    }

    // Yellow sun icon at top
    final sunPaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(centerX, centerY - radius - 4), 8, sunPaint);
  }

  @override
  bool shouldRepaint(_SemiCirclePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.activeIndex != activeIndex;
  }
}

// Prayer metadata - define outside class
class _PrayerMeta {
  final String name;
  final Color color;
  final IconData icon;

  const _PrayerMeta({required this.name, required this.color, required this.icon});
}

// Prayer metadata list
const List<_PrayerMeta> _prayerMeta = [
  _PrayerMeta(name: 'ফজর', color: Color(0xFF8B4513), icon: Icons.wb_twilight),
  _PrayerMeta(name: 'যোহর', color: Color(0xFFFFC107), icon: Icons.wb_sunny),
  _PrayerMeta(name: 'আসর', color: Color(0xFFFF9800), icon: Icons.cloud),
  _PrayerMeta(name: 'মাগরিব', color: Color(0xFFFF6F00), icon: Icons.brightness_4),
  _PrayerMeta(name: 'ইশা', color: Color(0xFF1A237E), icon: Icons.nights_stay),
];
