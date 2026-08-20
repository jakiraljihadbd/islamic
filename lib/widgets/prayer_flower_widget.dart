import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/prayer_time_service.dart';
import '../services/alarm_service.dart';
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
  String _currentFlower = 'assets/images/flower/img_flower_fajr_green.png';
  String? _locationName; // 10.2: lat/lng থেকে জেলা/শহরের নাম (geocoding দিয়ে)
  // 10.4: প্রতিটা পাপড়ির আলার্ম চালু/বন্ধ অবস্থা — prayer_screen.dart এর মতোই
  // SharedPreferences key 'alarm_enabled_$index' ব্যবহার করা হয় (index এখানে
  // PrayerTimeService.ordered() এর ক্রম অনুযায়ী: ফজর(0)/সূর্যোদয়(1)/যোহর(2)/
  // আসর(3)/মাগরিব(4)/এশা(5))।
  List<bool> _alarmEnabled = List.filled(_defs.length, false);

  @override
  void initState() {
    super.initState();
    _setupPetals();
    _loadLocationName();
    _loadAlarmStates();
  }

  Future<void> _loadAlarmStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _alarmEnabled = List.generate(_petals.length, (i) => prefs.getBool('alarm_enabled_$i') ?? false);
      });
    } catch (_) {
      // প্রেফারেন্স পড়তে ব্যর্থ হলে সব বন্ধ ধরে নেওয়া হয়, UI ভাঙে না
    }
  }

  @override
  void didUpdateWidget(covariant PrayerFlowerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lat != widget.lat || oldWidget.lng != widget.lng) {
      _setupPetals();
      _loadLocationName();
    }
  }

  /// lat/lng থেকে locality/জেলার নাম বের করে দেখায় (ব্যর্থ হলে চুপচাপ লুকানো থাকে,
  /// এরর দেখানো হয় না — শুধু একটা optional ছোট UI টাচ)।
  Future<void> _loadLocationName() async {
    try {
      final placemarks = await placemarkFromCoordinates(widget.lat, widget.lng);
      if (placemarks.isEmpty || !mounted) return;
      final p = placemarks.first;
      final name = p.locality?.trim().isNotEmpty == true
          ? p.locality!.trim()
          : (p.subAdministrativeArea?.trim().isNotEmpty == true
              ? p.subAdministrativeArea!.trim()
              : p.administrativeArea?.trim());
      if (name != null && name.isNotEmpty) {
        setState(() => _locationName = name);
      }
    } catch (_) {
      // geocoding ব্যর্থ হলে (নেটওয়ার্ক/পারমিশন) location row শুধু হাইড থাকবে
    }
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

  // 10.4: আগে ট্যাপে ২.৫ সেকেন্ডের SnackBar দেখাত, এখন বিস্তারিত পপ-আপ
  // (bottom sheet) দেখায় — নাম, সময়, countdown ও আলার্ম টগল। পপ-আপ বন্ধ হলে
  // (যেকোনো উপায়ে — টগল বাদেও) ফুল আবার বর্তমান ওয়াক্তের সবুজ ছবিতে ফিরে আসে।
  Future<void> _onPetalTapped(int index) async {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
        _currentFlower = 'assets/images/flower/${_petals[index].flowerBlue}.png';
      });
    }
    await _showPetalSheet(index);
    if (!mounted) return;
    setState(() {
      _selectedIndex = null;
      _currentFlower = 'assets/images/flower/${_petals[_activeIndex].flowerGreen}.png';
    });
  }

  Future<void> _showPetalSheet(int index) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return _PetalDetailSheet(
              petal: _petals[index],
              alarmOn: _alarmEnabled[index],
              onAlarmChanged: (value) async {
                await _setAlarm(index, value);
                setSheetState(() {}); // widget.alarmOn আপডেটেড মান দিয়ে শিট রিবিল্ড
              },
            );
          },
        );
      },
    );
  }

  /// prayer_screen.dart এর _onToggleChanged এর মতোই লজিক (id/key ফরম্যাট একই
  /// — 'alarm_enabled_$index'), নতুন করে alarm scheduling লজিক বানানো হয়নি,
  /// শুধু এই ফুল-উইজেট থেকেও কল করার জন্য এখানে দ্বিতীয় entry point।
  Future<void> _setAlarm(int index, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('alarm_enabled_$index', value);
    } catch (_) {}

    if (mounted) setState(() => _alarmEnabled[index] = value);

    final id = index + 1;
    final petal = _petals[index];
    try {
      if (value) {
        await AlarmService.instance.requestIgnoreBatteryOptimizations();
        await AlarmService.instance.schedulePrayer(
          id: id,
          dateTime: petal.time,
          prayerName: petal.name,
          recurring: true,
        );
      } else {
        await AlarmService.instance.cancelPrayer(id);
      }
    } catch (_) {
      // AlarmService init না হয়ে থাকলে/প্ল্যাটফর্ম সাপোর্ট না থাকলে চুপচাপ
      // ফিরে আসে — টগলের UI স্টেট এখনো prefs এ ঠিকভাবে সেভ থাকে
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // বিসমিল্লাহ ব্যানার — img_bismi_frame.png কে হেডারের background হিসেবে
        // ব্যবহার করা হয়েছে (10.2 বাগ-ফিক্স): আগে এই ইমেজ ভুলভাবে নিচের ফুল-স্ট্যাকের
        // মাঝখানে ১৬০x১৬০ বর্গক্ষেত্রে বসানো ছিল, কিন্তু আসল ইমেজটা একটা চওড়া
        // (১১৬৭x৩৫০) আয়তক্ষেত্রাকার ডেকোরেটিভ বর্ডার/ব্যানার — বর্গক্ষেত্রে জোর করে
        // বসানোয় সেটা চেপে/বিকৃত হয়ে দেখাত। মূল Java লেআউটেও (fragment_home.xml)
        // এই ইমেজ পুরো হেডার চওড়া জুড়ে fitXY দিয়ে stretch করা ছিল, ছোট আইকন হিসেবে না —
        // এখন সেভাবেই বসানো হয়েছে।
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            height: 92,
            decoration: const BoxDecoration(gradient: AppColors.headerGradient),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/flower/img_bismi_frame.png',
                  fit: BoxFit.fill,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_locationName != null) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 11,
                              color: Color(0xFFFFE97A),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _locationName!,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFFFFE97A),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                      ],
                      const Text(
                        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                        style: TextStyle(
                          fontFamily: 'Arabic',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                          color: Color(0xFFFFD700),
                          shadows: [Shadow(color: Color(0xFF8B6914), offset: Offset(1, 1), blurRadius: 3)],
                        ),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'বিসমিল্লাহি আর-রাহমানি আর-রাহিম',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFFFE97A),
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        // ৬টা পাপড়ির ফুল (10.3: সূর্যোদয় ফিরিয়ে আনা হয়েছে, সমান ৬০° কোণে হেক্সাগন বিন্যাস)
        Center(
          child: SizedBox(
            width: 320,
            height: 320,
            child: Stack(
              children: [
                // active/tapped ওয়াক্ত অনুযায়ী সবুজ/নীল ফুল — স্পিন+স্কেল অ্যানিমেশন
                Positioned(
                  left: 20,
                  top: 20,
                  child: AnimatedSwitcher(
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
                      errorBuilder: (context, error, stackTrace) {
                        // ইমেজ না পেলে fallback (ফজর সবুজ)
                        return Image.asset(
                          'assets/images/flower/img_flower_fajr_green.png',
                          width: 280,
                          height: 280,
                          fit: BoxFit.contain,
                        );
                      },
                    ),
                  ),
                ),
                // ৬টা পেটাল — কেন্দ্র (160,160) থেকে সমান ব্যাসার্ধে ৬০° পর পর
                for (int i = 0; i < _petals.length; i++) _petalPosition(i, _hexOffset(i)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// index অনুযায়ী কেন্দ্র থেকে (offsetX, offsetY) — ফজর সবচেয়ে উপরে, তারপর
  /// ঘড়ির কাঁটার দিকে (clockwise) প্রতি পাপড়ি ৬০° পর পর, মোট ৬টা সমদূরত্বে।
  Offset _hexOffset(int index) {
    const radius = 125.0;
    final theta = (index * 60) * (math.pi / 180.0);
    final dx = radius * math.sin(theta);
    final dy = -radius * math.cos(theta);
    return Offset(dx, dy);
  }

  Widget _petalPosition(int index, Offset offset) {
    final petal = _petals[index];
    final isActive = index == (_selectedIndex ?? _activeIndex);
    // কেন্দ্র (160,160) — SizedBox 320x320 এর মাঝখান, পাপড়ি সার্কেল (60x60 → half 30)
    // বাদ দিয়ে বসানো হয় যাতে অফসেট থেকে ঠিক কেন্দ্রবিন্দুতে align হয়।
    return Positioned(
      left: 160 + offset.dx - 32,
      top: 160 + offset.dy - 32,
      child: GestureDetector(
        onTap: () => _onPetalTapped(index),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isActive ? AppColors.petalActiveGradient : null,
                  color: isActive ? null : Colors.white,
                  border: isActive ? null : Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: isActive
                          ? AppColors.success.withValues(alpha: 0.35)
                          : Colors.black.withValues(alpha: 0.06),
                      blurRadius: isActive ? 12 : 6,
                      spreadRadius: isActive ? 1 : 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/flower/${petal.petalIcon}.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // পেটাল আইকন না পেলে সিম্পল সার্কেল আইকন দেখাও
                      return Icon(
                        Icons.circle_outlined,
                        size: 32,
                        color: isActive ? Colors.white : AppColors.primary,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 5),
              // নাম হালকা ওয়েট
              Text(
                petal.name,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w400,
                  color: isActive ? AppColors.primary : AppColors.onSurface.withValues(alpha: 0.7),
                  letterSpacing: 0.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // সময় — শুধু এটাই bold
              Text(
                TimeOfDay.fromDateTime(petal.time).format(context),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isActive ? AppColors.primary : AppColors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 10.4: পাপড়ি ট্যাপে দেখানো বটম-শিট — নাম/সময়/লাইভ countdown + আলার্ম টগল।
/// নিজস্ব ১-মিনিট পরপর টিক দেওয়া Timer আছে যাতে শিট খোলা অবস্থায় countdown
/// টেক্সট আপডেট হতে থাকে (অতিরিক্ত ব্যাটারি খরচ এড়াতে সেকেন্ড না, মিনিট
/// রেজোলিউশনে)।
class _PetalDetailSheet extends StatefulWidget {
  final _Petal petal;
  final bool alarmOn;
  final ValueChanged<bool> onAlarmChanged;

  const _PetalDetailSheet({
    required this.petal,
    required this.alarmOn,
    required this.onAlarmChanged,
  });

  @override
  State<_PetalDetailSheet> createState() => _PetalDetailSheetState();
}

class _PetalDetailSheetState extends State<_PetalDetailSheet> {
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _tickTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final petal = widget.petal;
    final now = DateTime.now();
    final isPast = petal.time.isBefore(now);
    final remaining = isPast ? Duration.zero : petal.time.difference(now);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, -4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.petalActiveGradient,
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/flower/${petal.petalIcon}.png',
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.circle_outlined, color: Colors.white, size: 30),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              petal.name,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: AppColors.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              TimeOfDay.fromDateTime(petal.time).format(context),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
            const SizedBox(height: 6),
            Text(
              isPast ? 'এই ওয়াক্ত শেষ হয়েছে' : 'বাকি আছে ${_formatRemaining(remaining)}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: AppColors.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 18),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.notifications_active_outlined, size: 20, color: AppColors.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'আলার্ম',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.onSurface),
                  ),
                ),
                Switch(
                  value: widget.alarmOn,
                  activeColor: AppColors.success,
                  onChanged: widget.onAlarmChanged,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatRemaining(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h <= 0 && m <= 0) return 'এখনই';
    final parts = <String>[];
    if (h > 0) parts.add('$h ঘন্টা');
    if (m > 0) parts.add('$m মিনিট');
    return parts.join(' ');
  }
}
