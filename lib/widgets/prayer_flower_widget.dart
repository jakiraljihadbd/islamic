import 'dart:async';
import 'package:flutter/material.dart';
import '../services/prayer_time_service.dart';
import '../theme/app_colors.dart';

/// প্রার্থনা-ফুল উইজেট (7.2b) — ট্যাপ করলে সেই ওয়াক্তের নীল রঙের ফুলে
/// স্পিন-অ্যানিমেশন দিয়ে বদলায় (২.৫ সেকেন্ড পর আবার বর্তমান ওয়াক্তের
/// সবুজ ফুলে ফিরে আসে), আর active পাপড়ির চারপাশে bg_petal_active গ্রেডিয়েন্ট
/// রিং হাইলাইট হয়।
class PrayerFlowerWidget extends StatefulWidget {
  final double lat;
  final double lng;

  const PrayerFlowerWidget({
    super.key,
    this.lat = 23.8103,
    this.lng = 90.4125,
  });

  @override
  State<PrayerFlowerWidget> createState() => _PrayerFlowerWidgetState();
}

class _Petal {
  final String name;
  final String petalIcon;
  final String flowerGreen;
  final String flowerBlue;
  final DateTime time;
  const _Petal(this.name, this.petalIcon, this.flowerGreen, this.flowerBlue, this.time);
}

class _PrayerFlowerWidgetState extends State<PrayerFlowerWidget> {
  static const _defs = [
    ('ফজর', 'ic_petal_fajr', 'img_flower_fajr'),
    ('সূর্যোদয়', 'ic_petal_sunrise', 'img_flower_sunrise'),
    ('যোহর', 'ic_petal_dhuhr', 'img_flower_dhuhr'),
    ('আসর', 'ic_petal_asr', 'img_flower_asr'),
    ('মাগরিব', 'ic_petal_maghrib', 'img_flower_maghrib'),
    ('ইশা', 'ic_petal_isha', 'img_flower_isha'),
  ];

  late List<_Petal> _petals;
  late int _activeIndex;
  int? _selectedIndex;
  String _currentFlower = 'assets/images/flower/img_flower_neutral.png';
  Timer? _revertTimer;

  @override
  void initState() {
    super.initState();
    _setupPetals();
  }

  @override
  void didUpdateWidget(covariant PrayerFlowerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lat != widget.lat || oldWidget.lng != widget.lng) {
      _setupPetals();
    }
  }

  @override
  void dispose() {
    _revertTimer?.cancel();
    super.dispose();
  }

  void _setupPetals() {
    final now = DateTime.now();
    final times = PrayerTimeService.calculate(latitude: widget.lat, longitude: widget.lng, date: now);
    final ordered = times.ordered; // ফজর, সূর্যোদয়, যোহর, আসর, মাগরিব, এশা (একই ক্রম _defs এর সাথে মিলে)
    _petals = List.generate(_defs.length, (i) {
      final (name, petalIcon, flowerBase) = _defs[i];
      return _Petal(name, petalIcon, '${flowerBase}_green', '${flowerBase}_blue', ordered[i].value);
    });
    _activeIndex = _calcActiveIndex(now);
    _currentFlower = 'assets/images/flower/${_petals[_activeIndex].flowerGreen}.png';
  }

  /// বর্তমান সময়ের আগের সর্বশেষ ওয়াক্ত-ই "active" (আসল PrayerTimeService এর
  /// real সময় ব্যবহার করে — original Java এর হার্ডকোড করা ঘন্টার বদলে)।
  /// কোনোটাই আগে না হলে (মধ্যরাতের পর, ফজরের আগে) আগের দিনের এশা ধরা হয়।
  int _calcActiveIndex(DateTime now) {
    int active = -1;
    for (int i = 0; i < _petals.length; i++) {
      if (!_petals[i].time.isAfter(now)) active = i;
    }
    return active == -1 ? _petals.length - 1 : active;
  }

  void _onPetalTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
      _currentFlower = 'assets/images/flower/${_petals[index].flowerBlue}.png';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_petals[index].name} — ${TimeOfDay.fromDateTime(_petals[index].time).format(context)}'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _revertTimer?.cancel();
    _revertTimer = Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      setState(() {
        _selectedIndex = null;
        _currentFlower = 'assets/images/flower/${_petals[_activeIndex].flowerGreen}.png';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // active/tapped ওয়াক্ত অনুযায়ী সবুজ/নীল ফুল — স্পিন+স্কেল অ্যানিমেশন দিয়ে বদলায়
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => RotationTransition(
              turns: Tween<double>(begin: 0.5, end: 1.0).animate(animation),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.0).animate(animation),
                child: child,
              ),
            ),
            child: Image.asset(
              _currentFlower,
              key: ValueKey(_currentFlower),
              width: 280,
              height: 280,
              fit: BoxFit.contain,
            ),
          ),
          // বিসমিল্লাহ ফ্রেম (center overlap)
          Image.asset(
            'assets/images/flower/img_bismi_frame.png',
            width: 160,
            height: 160,
            fit: BoxFit.contain,
          ),
          // ৬টা পেটাল (ট্যাপযোগ্য)
          _petalPosition(0, -100, -60),  // ফজর (top-left)
          _petalPosition(1, 100, -60),   // সূর্যোদয় (top-right)
          _petalPosition(2, 140, 0),     // যোহর (right)
          _petalPosition(3, 100, 60),    // আসর (bottom-right)
          _petalPosition(4, -100, 60),   // মাগরিব (bottom-left)
          _petalPosition(5, -140, 0),    // ইশা (left)
        ],
      ),
    );
  }

  Widget _petalPosition(int index, double offsetX, double offsetY) {
    final petal = _petals[index];
    final isActive = index == (_selectedIndex ?? _activeIndex);
    return Positioned(
      left: 140 + offsetX,
      top: 140 + offsetY,
      child: GestureDetector(
        onTap: () => _onPetalTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // bg_petal_active.xml (oval, success→primary_variant) — শুধু active
                // পাপড়িতে; বাকিগুলোতে আগের নিউট্রাল হালকা ব্যাকগ্রাউন্ড।
                gradient: isActive ? AppColors.petalActiveGradient : null,
                color: isActive ? null : AppColors.primary.withValues(alpha: 0.1),
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/flower/${petal.petalIcon}.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              petal.name,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
