import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/prayer_time_service.dart';
import '../services/alarm_service.dart';
import '../services/alarm_reliability_service.dart';
import '../theme/app_colors.dart';
import 'alarm_reliability_dialog.dart';

/// প্রার্থনা-ফুল উইজেট।
///
/// === নতুন পাপড়ি-সিস্টেম (worklist_home.txt #৩, এই সেশনে রিডিজাইন করা) ===
/// আগে প্রতিটা ওয়াক্তের জন্য আলাদা পূর্ণাঙ্গ ফুল-ছবি ছিল (img_flower_{name}_green/
/// blue.png — যেখানে একটামাত্র পাপড়ি রঙিন/হাইলাইট করা থাকত বাকিগুলো নিউট্রাল), আর
/// প্রতিটা পাপড়ির আইকন একটা আলাদা সাদা/হালকা সার্কেল ব্যাজের ভেতরে বসানো থাকত।
/// এখন থেকে মাত্র **একটাই নিউট্রাল ফুল-ছবি** (img_flower_neutral_light.png)
/// ব্যবহার করা হয় — এর উপরেই ৬টা পাপড়ির প্রতিটার জায়গায় (মাপ নিচে ব্যাখ্যা করা
/// আছে) সংশ্লিষ্ট আইকন সরাসরি বসানো হয় (কোনো সাদা সার্কেল/ব্যাজ ছাড়া), আর
/// নাম+সময় পাপড়ির ঠিক মাঝ বরাবর align করা হয়। "সিলেক্ট স্টেট" এখন আর আলাদা
/// ছবি বদলে না, শুধু বর্তমান/active ওয়াক্তের টেক্সট রঙ সবুজ (AppColors.primary)
/// হয়ে বোঝানো হয় — বাকি সব পাপড়ির টেক্সট থিম-অনুযায়ী onSurface রঙে থাকে (এটাই
/// ডার্ক-মোড ফিক্স, নিচে দেখুন)।
///
/// --- পাপড়ির জ্যামিতি (img_flower_neutral_light.png, 720x720 ক্যানভাস) ---
/// ছবিটা পিক্সেল-অ্যানালাইসিস করে বের করা হয়েছে (প্রতিটা পাপড়ি-সার্কেলের bounding
/// box মেপে):
///   - ক্যানভাসের কেন্দ্র: (360, 360)
///   - কেন্দ্র থেকে প্রতিটা পাপড়ির কেন্দ্র পর্যন্ত দূরত্ব (hex radius): ≈ 211px
///     → অনুপাত হিসেবে 211/720 ≈ 0.2938 × ডিসপ্লে-সাইজ
///   - প্রতিটা পাপড়ি-সার্কেলের ব্যাসার্ধ: ≈ 93px → 93/720 ≈ 0.1292 × ডিসপ্লে-সাইজ
///   - ফজর ঠিক উপরে (12 টার কাঁটার পজিশন, 0°), তারপর ঘড়ির কাঁটার দিকে ৬০° পর পর:
///     সূর্যোদয়(৬০°) → যোহর(১২০°) → আসর(১৮০°, একদম নিচে) → মাগরিব(২৪০°) →
///     এশা(৩০০°) — এটাই আগের _hexOffset() ফাংশনের একই থিটা-ফর্মুলা, শুধু radius
///     এখন উপরের নতুন অনুপাত থেকে ডিসপ্লে-সাইজ অনুযায়ী হিসাব হয়।
/// এই দুটো অনুপাত (_kHexRadiusRatio, _kPetalRadiusRatio) ধ্রুবক রাখা হয়েছে যাতে
/// ডিসপ্লে-সাইজ (রেসপনসিভ, স্ক্রিন-প্রস্থ অনুযায়ী) যতই বদলাক, আইকন+টেক্সট সবসময়
/// আসল ছবির পাপড়ি-সার্কেলের ঠিক ভেতরেই/মাঝ বরাবর বসবে।
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
  final DateTime time;
  const _Petal(this.name, this.petalIcon, this.time);
}

class _PrayerFlowerWidgetState extends State<PrayerFlowerWidget> {
  static const _defs = [
    ('ফজর', 'ic_petal_fajr'),
    ('সূর্যোদয়', 'ic_petal_sunrise'),
    ('যোহর', 'ic_petal_dhuhr'),
    ('আসর', 'ic_petal_asr'),
    ('মাগরিব', 'ic_petal_maghrib'),
    ('ইশা', 'ic_petal_isha'),
  ];

  // === পাপড়ি জ্যামিতির ধ্রুবক (img_flower_neutral_light.png থেকে মাপা, উপরের
  // ক্লাস-ডকে বিস্তারিত ব্যাখ্যা দেখুন) ===
  static const double _kHexRadiusRatio = 0.2938;
  static const double _kPetalRadiusRatio = 0.1292;
  static const String _kFlowerAsset = 'assets/images/flower/img_flower_neutral_light.png';

  late List<_Petal> _petals;
  late int _activeIndex;
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
      final (name, petalIcon) = _defs[i];
      return _Petal(name, petalIcon, ordered[i].value);
    });
    _activeIndex = _calcActiveIndex(now);
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

  // পাপড়িতে ট্যাপ করলে বিস্তারিত পপ-আপ (bottom sheet) দেখায় — নাম, সময়,
  // countdown ও আলার্ম টগল। এখন আর ফুল-ছবি বদলায় না (একটাই নিউট্রাল ছবি সবসময়
  // থাকে) — শুধু "বর্তমান ওয়াক্ত" (active) পাপড়ির টেক্সট সবুজ থাকে, ট্যাপ করাটা
  // স্রেফ ডিটেইল শিট খোলে।
  Future<void> _onPetalTapped(int index) => _showPetalSheet(index);

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
        if (await AlarmReliabilityService.instance.shouldShowOnFirstAlarm() && mounted) {
          await showAlarmReliabilityDialog(context);
        }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // থিম-অনুযায়ী বিসমিল্লাহ টেক্সট কালার — আগে ব্যাকগ্রাউন্ড গ্রেডিয়েন্ট বক্স
    // থাকায় সবসময় উজ্জ্বল সোনালী রঙ ব্যবহার করা যেত (worklist_home #২: বাদ
    // দেওয়া হয়েছে), এখন ফ্রেমটা সরাসরি স্ক্রিনের নিজস্ব ব্যাকগ্রাউন্ডের উপর
    // বসে বলে লাইট মোডে হালকা ব্যাকগ্রাউন্ডে উজ্জ্বল সোনালী রঙ প্রায় দেখাই যায়
    // না — তাই লাইট মোডে গাঢ় ব্রোঞ্জ/সোনালী আর ডার্ক মোডে উজ্জ্বল সোনালী।
    const arabicColorDark = Color(0xFFFFD700);
    const arabicColorLight = Color(0xFF8A6A00);
    const subColorDark = Color(0xFFFFE97A);
    const subColorLight = Color(0xFF6B5300);
    final arabicColor = isDark ? arabicColorDark : arabicColorLight;
    final subColor = isDark ? subColorDark : subColorLight;
    final arabicShadow = isDark ? const Color(0xFF8B6914) : const Color(0xFFFFF3C4);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // === বিসমিল্লাহ ফ্রেম — worklist_home.txt #২ (এই সেশনে ৩ ধাপ সম্পন্ন) ===
        // ১) উপরে-নিচের মার্জিন/প্যাডিং কমানো হয়েছে (আরও কম্প্যাক্ট)
        // ২) ফুল-উইথ: প্যারেন্ট (home_screen.dart এর SliverPadding) থেকে আসা
        //    ২০px হরাইজন্টাল প্যাডিং negative margin দিয়ে ভেঙে বের করা হয়েছে,
        //    যাতে ফ্রেমটা স্ক্রিনের দুই এজ পর্যন্ত পুরো প্রশস্ত হয়। এই ২০ ভ্যালু
        //    home_screen.dart-এর SliverPadding(horizontal: 20)-এর সাথে মিলিয়ে
        //    রাখা হয়েছে — ওখানে বদলালে এখানেও বদলাতে হবে।
        // ৩) bg remove: আগের গ্রেডিয়েন্ট Container ব্যাকগ্রাউন্ড বক্স (ClipRRect+
        //    decoration) সম্পূর্ণ বাদ দেওয়া হয়েছে — এখন শুধু PNG ফ্রেম-আর্ট আর
        //    টেক্সট সরাসরি হোম স্ক্রিনের নিজস্ব ব্যাকগ্রাউন্ডের উপর ভাসে, কোনো
        //    বক্স/প্যানেল নেই। ছবিটার আসল অনুপাত (1167×350) অনুযায়ী AspectRatio
        //    ব্যবহার করা হয়েছে (আগে BoxFit.fill + fixed height:92 ছবিটাকে
        //    স্ট্রেচ করে বিকৃত করে দিত)।
        Container(
          margin: const EdgeInsets.symmetric(horizontal: -20),
          child: AspectRatio(
            aspectRatio: 1167 / 350,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/flower/img_bismi_frame.png',
                  fit: BoxFit.fill,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                        style: TextStyle(
                          fontFamily: 'Arabic',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 1.3,
                          color: arabicColor,
                          shadows: [Shadow(color: arabicShadow, offset: const Offset(1, 1), blurRadius: 3)],
                        ),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'বিসমিল্লাহি আর-রাহমানি আর-রাহিম',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: subColor,
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
        // লোকেশন — ইউজারের হাতে আঁকা রেফারেন্স ডেমো (IMG_20260820_083202_496.jpg)
        // অনুযায়ী এখন বিসমিল্লাহ ফ্রেমের ভিতরে না, ফ্রেমের ঠিক নিচে আলাদা লাইনে
        // (আগে ফ্রেমের ভিতরে টেক্সটের উপরে ছিল)।
        if (_locationName != null) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 12,
                color: subColor,
              ),
              const SizedBox(width: 3),
              Text(
                _locationName!,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w400,
                  color: subColor,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        // === পাপড়ি (ফুল) সেকশন — worklist_home.txt #৩ রিডিজাইন ===
        // LayoutBuilder দিয়ে available width অনুযায়ী রেসপনসিভ সাইজ (আগে ছিল
        // hardcoded 320x320 বক্সে 280x280 ছবি — এখন পুরো available width টাই
        // ব্যবহার হয়, ফলে ছবি ও পাপড়ি দুটোই আগের চেয়ে লক্ষণীয়ভাবে বড় দেখায়,
        // ছোট স্ক্রিনেও ভাঙবে না কারণ radius/font সবকিছু displaySize থেকে হিসাব)।
        LayoutBuilder(
          builder: (context, constraints) {
            final displaySize = constraints.maxWidth.clamp(260.0, 440.0);
            final hexRadius = displaySize * _kHexRadiusRatio;
            final petalRadius = displaySize * _kPetalRadiusRatio;
            return Center(
              child: SizedBox(
                width: displaySize,
                height: displaySize,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        _kFlowerAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ),
                    for (int i = 0; i < _petals.length; i++)
                      _petalContent(
                        context,
                        index: i,
                        offset: _hexOffset(i, hexRadius),
                        displaySize: displaySize,
                        petalRadius: petalRadius,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// index অনুযায়ী কেন্দ্র থেকে (offsetX, offsetY) — ফজর সবচেয়ে উপরে, তারপর
  /// ঘড়ির কাঁটার দিকে (clockwise) প্রতি পাপড়ি ৬০° পর পর, মোট ৬টা সমদূরত্বে —
  /// img_flower_neutral_light.png-এর আসল পাপড়ি-বিন্যাসের সাথে হুবহু মিলিয়ে।
  Offset _hexOffset(int index, double radius) {
    final theta = (index * 60) * (math.pi / 180.0);
    final dx = radius * math.sin(theta);
    final dy = -radius * math.cos(theta);
    return Offset(dx, dy);
  }

  /// একটা পাপড়ির ভেতরে (কোনো সাদা সার্কেল/ব্যাজ ছাড়া) সরাসরি: আইকন → নাম →
  /// (ঘড়ি-আইকন + সময়) — সব মিলিয়ে পাপড়ি-সার্কেলের ঠিক জ্যামিতিক কেন্দ্রে align।
  Widget _petalContent(
    BuildContext context, {
    required int index,
    required Offset offset,
    required double displaySize,
    required double petalRadius,
  }) {
    final petal = _petals[index];
    final isActive = index == _activeIndex;
    final center = displaySize / 2;
    final petalDiameter = petalRadius * 2;

    // ডার্ক-মোড ফিক্স: আগে static AppColors.onSurface (সবসময় গাঢ় রঙ, #13241C)
    // সরাসরি ব্যবহার হতো — ডার্ক থিমে ব্যাকগ্রাউন্ড গাঢ় হয়ে গেলেও টেক্সট গাঢ়ই
    // থেকে যেত, ফলে অদৃশ্য/অপঠনযোগ্য হয়ে যেত। এখন Theme.of(context) থেকে
    // থিম-অনুযায়ী onSurface রঙ নেওয়া হচ্ছে (light থিমে গাঢ়, dark থিমে হালকা)।
    final baseTextColor = Theme.of(context).colorScheme.onSurface;
    // "সিলেক্ট স্টেট" — একমাত্র বর্তমান/active ওয়াক্তের টেক্সট সবুজ (AppColors.primary)।
    final textColor = isActive ? AppColors.primary : baseTextColor.withValues(alpha: 0.82);

    final iconSize = (displaySize * 0.078).clamp(22.0, 34.0);
    final nameFontSize = (displaySize * 0.0245).clamp(9.0, 13.5);
    final timeFontSize = (displaySize * 0.0275).clamp(10.0, 15.0);
    final clockIconSize = (displaySize * 0.021).clamp(7.5, 11.0);

    return Positioned(
      left: center + offset.dx - petalRadius,
      top: center + offset.dy - petalRadius,
      width: petalDiameter,
      height: petalDiameter,
      child: GestureDetector(
        onTap: () => _onPetalTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // আইকন সরাসরি পাপড়ির ভেতরে, কোনো সাদা সার্কেল ব্যাকগ্রাউন্ড ছাড়া
              Image.asset(
                'assets/images/flower/${petal.petalIcon}.png',
                width: iconSize,
                height: iconSize,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.circle_outlined,
                  size: iconSize,
                  color: textColor,
                ),
              ),
              SizedBox(height: displaySize * 0.008),
              Text(
                petal.name,
                style: TextStyle(
                  fontSize: nameFontSize,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: textColor,
                  letterSpacing: 0.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: displaySize * 0.004),
              // সময়ের লেখার আগে ছোট ঘড়ি আইকন
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time_rounded, size: clockIconSize, color: textColor.withValues(alpha: 0.75)),
                  SizedBox(width: displaySize * 0.006),
                  Text(
                    TimeOfDay.fromDateTime(petal.time).format(context),
                    style: TextStyle(
                      fontSize: timeFontSize,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surface = Theme.of(context).colorScheme.surface;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: BoxDecoration(
          color: surface,
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
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: onSurface),
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
                color: onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 18),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.notifications_active_outlined, size: 20, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'আলার্ম',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: onSurface),
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
