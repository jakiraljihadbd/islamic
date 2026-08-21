import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

import '../services/prayer_time_service.dart';
import '../services/aladhan_service.dart';
import '../services/alarm_service.dart';
import '../services/alarm_reliability_service.dart';
import '../services/time_format_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/alarm_reliability_dialog.dart';
import 'settings_screen.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({Key? key}) : super(key: key);

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> with SingleTickerProviderStateMixin {
  double _lat = 23.8103;
  double _lng = 90.4125;
  DailyPrayerTimes? _times;
  bool _loading = true;
  MapEntry<String, DateTime>? _nextPrayer;
  List<bool> _toggles = [];
  // 11.3: প্রতিটা নামাজের ম্যানুয়াল সময়-সমন্বয় (মিনিটে, +/-) —
  // shared_preferences key: prayer_offset_min_$index
  List<int> _offsets = [];
  int _activeIndex = -1;
  // 11.5: prayer_flower_widget.dart এর একই প্যাটার্নে lat/lng থেকে locality
  // বের করা হয় — ব্যর্থ হলে চুপচাপ hide থাকে, এরর দেখানো হয় না।
  String? _locationName;

  static const int _offsetStepMin = 5;
  static const int _offsetMaxMin = 30;

  // 11.7: সূর্যের pulsing/glow অ্যানিমেশনের জন্য — repeat(reverse:true) দিয়ে
  // ০↔১ এর মধ্যে অনবরত দোলে, _SemiCirclePainter এ pulse হিসেবে পাস হয়।
  late final AnimationController _sunPulseController;
  // 11.8: prayer_flower_widget.dart এর _PetalDetailSheet এর একই প্যাটার্ন —
  // প্রতি মিনিটে টিক দিয়ে countdown ("বাকি আছে X ঘন্টা Y মিনিট") রিফ্রেশ করে,
  // ব্যাটারি বাঁচাতে সেকেন্ড-লেভেল না, মিনিট-লেভেল।
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _sunPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    _initServicesAndLoad();
    _loadLocationName();
    // 11.2: settings-এ টগল করলে এই স্ক্রিনও সাথে সাথে ফরম্যাট বদলাবে
    TimeFormatController.instance.addListener(_onTimeFormatChanged);
  }

  // 11.5: prayer_flower_widget.dart._loadLocationName() এর হুবহু একই প্যাটার্ন
  // reuse করা হয়েছে (locality → subAdministrativeArea → administrativeArea
  // fallback), যাতে "সাভার" হার্ডকোড টেক্সটের বদলে আসল লোকেশন-নাম দেখায়।
  Future<void> _loadLocationName() async {
    try {
      final placemarks = await placemarkFromCoordinates(_lat, _lng);
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
      // geocoding ব্যর্থ হলে চিপ থেকে লোকেশন অংশ শুধু হাইড থাকবে
    }
  }

  @override
  void dispose() {
    TimeFormatController.instance.removeListener(_onTimeFormatChanged);
    _sunPulseController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // 11.8: prayer_flower_widget.dart এর _PetalDetailSheetState._formatRemaining()
  // এর হুবহু একই ফরম্যাট, সামঞ্জস্যতার জন্য।
  String _formatRemaining(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h <= 0 && m <= 0) return 'এখনই';
    final parts = <String>[];
    if (h > 0) parts.add('$h ঘন্টা');
    if (m > 0) parts.add('$m মিনিট');
    return parts.join(' ');
  }

  void _onTimeFormatChanged() {
    if (mounted) setState(() {});
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

    // 11.6: _prayerMeta (৫টা সালাত, সূর্যোদয় বাদ) এর সাথে সাইজ মেলাতে হবে —
    // _times.ordered ব্যবহার করলে ৬ (সূর্যোদয় সহ) হয়ে _prayerMeta এর সাথে
    // আর মেলে না, তাই সবসময় _prayerMeta.length ব্যবহার করা হচ্ছে।
    final count = _prayerMeta.length;
    _toggles = List.filled(count, false);
    _offsets = List.filled(count, 0);
    final prefs = await SharedPreferences.getInstance();
    for (var i = 0; i < count; i++) {
      _toggles[i] = prefs.getBool('alarm_enabled_$i') ?? false;
      _offsets[i] = prefs.getInt('prayer_offset_min_$i') ?? 0;
    }

    if (_times != null) {
      final now = DateTime.now();
      _nextPrayer = PrayerTimeService.nextPrayer(latitude: _lat, longitude: _lng, now: now);

      // 11.6: আগের লজিক (`if (now.isBefore(times[i].value)) break;`) আসলে
      // "পরবর্তী" নামাজ বের করত এবং সরাসরি times.ordered (৬-আইটেম, সূর্যোদয়
      // সহ) থেকে ইনডেক্স করত — দুটোই বাগ ছিল (দেখুন worklist_salat_screen.txt
      // 11.6)। এখন _calcActiveIndex() দিয়ে **চলমান** ওয়াক্ত বের করা হয়,
      // _prayerOnlyTimes (৫-আইটেম, _prayerMeta এর ক্রমে) এর সাথে মিলিয়ে।
      _activeIndex = _calcActiveIndex(now);
    }

    setState(() => _loading = false);
  }

  // 11.2: TimeFormatController অনুযায়ী ২৪-ঘন্টা (HH:mm) বা ১২-ঘন্টা (h:mm AM/PM)
  String _fmtTime(DateTime t) => DateFormat(
        TimeFormatController.instance.is24Hour ? 'HH:mm' : 'h:mm a',
      ).format(t);

  // 11.3: ক্যালকুলেশন থেকে পাওয়া আসল সময়ের সাথে ইউজারের ম্যানুয়াল অফসেট যোগ করে
  // দেখানো/অ্যালার্ম-শিডিউলিং এর জন্য ব্যবহৃত সময় বের করে। ক্যালকুলেশন মেথড
  // (PrayerTimeService/AladhanService) অপরিবর্তিত থাকে — শুধু ডিসপ্লে/scheduling
  // এই offset যোগ হয়।
  // 11.6 রুট-কজ ফিক্স: আগে এখানে _times!.ordered (৬-আইটেম, সূর্যোদয় সহ) থেকে
  // সরাসরি ইনডেক্স করা হতো, কিন্তু _prayerMeta/UI রো (৫-আইটেম, সূর্যোদয় বাদ)
  // এর সাথে ইনডেক্স না মিলে ভুল সময় বসে যেত (যেমন index 1 "যোহর" রো তে
  // আসলে সূর্যোদয়ের সময় দেখাত)। এখন _prayerOnlyTimes (৫-আইটেম,
  // _prayerMeta এর একই ক্রমে) থেকে ইনডেক্স করা হয়।
  List<DateTime>? get _prayerOnlyTimes {
    final t = _times;
    if (t == null) return null;
    return [t.fajr, t.dhuhr, t.asr, t.maghrib, t.isha];
  }

  DateTime? _adjustedTime(int index) {
    final times = _prayerOnlyTimes;
    if (times == null || index >= times.length) return null;
    final offset = index < _offsets.length ? _offsets[index] : 0;
    return times[index].add(Duration(minutes: offset));
  }

  // 11.6: prayer_flower_widget.dart এর _calcActiveIndex() এর একই প্যাটার্ন —
  // "পরবর্তী" নামাজ (যেটার সময় এখনো আসেনি) নয়, বরং **এই মুহূর্তে চলমান**
  // নামাজ (আগের যে ওয়াক্তের অ্যাডজাস্টেড সময় এখনো পর্যন্ত সর্বশেষ শুরু
  // হয়েছে) বের করে। কোনোটাই এখনো শুরু না হলে (মধ্যরাতের পর, ফজরের আগে)
  // আগের দিনের এশা (শেষ ইনডেক্স) ধরা হয় — wrap-around।
  int _calcActiveIndex(DateTime now) {
    int active = -1;
    for (var i = 0; i < _prayerMeta.length; i++) {
      final t = _adjustedTime(i);
      if (t != null && !t.isAfter(now)) active = i;
    }
    return active == -1 ? _prayerMeta.length - 1 : active;
  }

  // 11.9: _activeIndex অনুযায়ী প্রার্থনার scene ব্যাকগ্রাউন্ড ইমেজ বের করে
  // (prayer_scene_{fajr/dhuhr/asr/maghrib/isha}.png)।
  String _getPrayerSceneImage() {
    if (_activeIndex < 0 || _activeIndex >= _prayerMeta.length) {
      return 'assets/images/prayer_scenes/prayer_scene_isha.png'; // ডিফল্ট
    }
    return switch (_activeIndex) {
      0 => 'assets/images/prayer_scenes/prayer_scene_fajr.png',
      1 => 'assets/images/prayer_scenes/prayer_scene_dhuhr.png',
      2 => 'assets/images/prayer_scenes/prayer_scene_asr.png',
      3 => 'assets/images/prayer_scenes/prayer_scene_maghrib.png',
      4 => 'assets/images/prayer_scenes/prayer_scene_isha.png',
      _ => 'assets/images/prayer_scenes/prayer_scene_isha.png',
    };
  }

  Future<void> _adjustOffset(int index, int delta) async {
    if (index >= _offsets.length) return;
    final next = (_offsets[index] + delta).clamp(-_offsetMaxMin, _offsetMaxMin);
    if (next == _offsets[index]) return;

    setState(() {
      _offsets[index] = next;
      // অফসেট বদলালে সীমানা শিফট হতে পারে, তাই highlight/progress ও রিফ্রেশ
      _activeIndex = _calcActiveIndex(DateTime.now());
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('prayer_offset_min_$index', next);

    // এই নামাজের আলার্ম এখন চালু থাকলে, নতুন সমন্বয়-করা সময় অনুযায়ী পুনরায়
    // শিডিউল করতে হবে — নাহলে পুরনো সময়েই আজান বাজত।
    if (index < _toggles.length && _toggles[index]) {
      final adjusted = _adjustedTime(index);
      if (adjusted != null) {
        await AlarmService.instance.schedulePrayer(
          id: index + 1,
          dateTime: adjusted,
          prayerName: _prayerMeta[index].name,
          recurring: true,
        );
      }
    }
  }

  Future<void> _onToggleChanged(int index, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('alarm_enabled_$index', value);
    setState(() => _toggles[index] = value);

    final when = _adjustedTime(index) ?? DateTime.now().add(const Duration(minutes: 1));

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
      // প্রথমবার কোনো নামাজের alarm চালু করলে একবার reliability checklist
      // দেখাও — battery optimization/autostart বন্ধ না থাকলে অনেক ফোনে
      // (Xiaomi/Oppo/Vivo ইত্যাদি) alarm নীরবে মিস হয়ে যায়, dialog সেটা
      // আগেভাগেই ঠিক করিয়ে নেয়।
      if (await AlarmReliabilityService.instance.shouldShowOnFirstAlarm() && mounted) {
        await showAlarmReliabilityDialog(context);
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: scheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('বুধ, ২১ সফর', style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: scheme.onSurface),
            tooltip: 'সেটিংস',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
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
                  _buildProgressSection(scheme),
                  const SizedBox(height: 16),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: List.generate(_prayerMeta.length, (i) {
                        final meta = _prayerMeta[i];
                        final adjusted = _adjustedTime(i);
                        final isActive = _activeIndex == i;
                        
                        return _buildPrayerRow(
                          meta: meta,
                          time: adjusted != null ? _fmtTime(adjusted) : '--:--',
                          index: i,
                          isActive: isActive,
                          scheme: scheme,
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

  Widget _buildProgressSection(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    // 11.5: সাহরি ≈ ফজরের সময়, ইফতার = মাগরিবের সময় — _times থেকে রিয়েল
    // ভ্যালু, তারিখ/লোকেশন বদলালে এখন এগুলোও সাথে সাথে ঠিক হয়ে যায়।
    final sehriTime = _times != null ? _fmtTime(_times!.fajr) : null;
    final iftarTime = _times != null ? _fmtTime(_times!.maghrib) : null;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        children: [
          // 11.9: উপরের সেকশনের ব্যাকগ্রাউন্ড ওয়াক্ত-অনুযায়ী ইমেজ দিয়ে বদলানো —
          // প্রতিটা ওয়াক্তের জন্য আলাদা prayer scene image, _activeIndex দিয়ে
          // নির্ধারিত হয়। কোনো border-radius বা gradient নয়, শুধু সরল ইমেজ।
          Container(
            height: 176,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(_getPrayerSceneImage()),
                fit: BoxFit.cover,
              ),
            ),
            child: SizedBox(
              height: 176,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 11.7: AnimatedBuilder দিয়ে _sunPulseController এর সাথে
                  // _SemiCirclePainter কে বাইন্ড করা হয়েছে যাতে সূর্যের
                  // pulse/glow অনবরত রিপেইন্ট হয়, বাকি পেইন্টার একই রাখা হয়েছে।
                  AnimatedBuilder(
                    animation: _sunPulseController,
                    builder: (context, _) => CustomPaint(
                      painter: _SemiCirclePainter(
                        progress: _getProgressPercentage(),
                        activeIndex: _activeIndex,
                        bgArcColor: isDark ? scheme.onSurface.withValues(alpha: 0.12) : Colors.grey[300]!,
                        pulse: _sunPulseController.value,
                      ),
                      size: const Size(double.infinity, 176),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    const SizedBox(height: 20),
                    Text(
                      _nextPrayer?.key ?? 'নামাজ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'পরবর্তী নামাজ',
                      style: TextStyle(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _nextPrayer != null ? _fmtTime(_nextPrayer!.value) : '--:--',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    // 11.8: লাইভ countdown badge — _countdownTimer প্রতি
                    // মিনিটে setState ট্রিগার করায় এটা নিজে থেকেই আপডেট হয়।
                    if (_nextPrayer != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          () {
                            final now = DateTime.now();
                            final target = _nextPrayer!.value;
                            final isPast = target.isBefore(now);
                            final remaining = isPast ? Duration.zero : target.difference(now);
                            return isPast ? 'এখনই' : 'বাকি আছে ${_formatRemaining(remaining)}';
                          }(),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 10),
          
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              if (_locationName != null)
                _buildChip(_locationName!, scheme, icon: Icons.location_on_outlined),
              if (sehriTime != null) _buildChip('সাহরি: $sehriTime', scheme),
              if (iftarTime != null) _buildChip('ইফতার: $iftarTime', scheme),
            ],
          ),
        ],
      ),
    );
  }

  // 11.5: চিপে ঐচ্ছিক leading আইকন যোগ (লোকেশন চিপে 📍 দেখানোর জন্য) +
  // প্যাডিং কম্প্যাক্ট করা হয়েছে (আগের 12/6 → 10/5)।
  Widget _buildChip(String label, ColorScheme scheme, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: scheme.onSurface.withValues(alpha: 0.7)),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(fontSize: 12, color: scheme.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerRow({
    required _PrayerMeta meta,
    required String time,
    required int index,
    required bool isActive,
    required ColorScheme scheme,
  }) {
    final offset = index < _offsets.length ? _offsets[index] : 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? AppColors.success.withValues(alpha: 0.08) : scheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: isActive ? Border.all(color: AppColors.success.withValues(alpha: 0.3)) : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: meta.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(meta.icon, color: meta.color, size: 22),
            ),
            const SizedBox(width: 12),

            // 11.3: নাম (বড়) ও সময় এখন একই লাইনে — সময়ের দুই পাশে +/- বাটন
            // দিয়ে মসজিদ-ভিত্তিক ম্যানুয়াল সমন্বয় করা যায়।
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      meta.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: scheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _offsetButton(
                    icon: Icons.remove,
                    onTap: () => _adjustOffset(index, -_offsetStepMin),
                    scheme: scheme,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface.withValues(alpha: 0.85),
                          ),
                        ),
                        if (offset != 0)
                          Text(
                            offset > 0 ? '+$offset মি.' : '$offset মি.',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _offsetButton(
                    icon: Icons.add,
                    onTap: () => _adjustOffset(index, _offsetStepMin),
                    scheme: scheme,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 6),
            _buildAlarmToggle(index: index, scheme: scheme),
          ],
        ),
      ),
    );
  }

  // 11.4: ডিফল্ট Material Switch এর বদলে কাস্টম আইকন-ভিত্তিক টগল — বন্ধ থাকলে
  // ধূসর গোল ব্যাজে alarm-off আইকন, চালু থাকলে সবুজ গোল ব্যাজে alarm-on/✓ আইকন।
  // _onToggleChanged() এর existing persist+schedule/cancel লজিক অপরিবর্তিত,
  // শুধু UI widget-টা বদলানো হয়েছে।
  Widget _buildAlarmToggle({required int index, required ColorScheme scheme}) {
    final isOn = index < _toggles.length ? _toggles[index] : false;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _onToggleChanged(index, !isOn);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isOn ? AppColors.success.withValues(alpha: 0.15) : scheme.onSurface.withValues(alpha: 0.06),
          border: Border.all(
            color: isOn ? AppColors.success : scheme.onSurface.withValues(alpha: 0.2),
            width: 1.4,
          ),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: Icon(
              isOn ? Icons.alarm_on : Icons.alarm_off,
              key: ValueKey(isOn),
              size: 20,
              color: isOn ? AppColors.success : scheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
    );
  }

  // 11.3: ছোট গোল +/- বাটন — সময় সমন্বয়ের জন্য
  Widget _offsetButton({required IconData icon, required VoidCallback onTap, required ColorScheme scheme}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.onSurface.withValues(alpha: 0.08),
        ),
        child: Icon(icon, size: 14, color: scheme.onSurface.withValues(alpha: 0.7)),
      ),
    );
  }

  // 11.6: আগে এখানে _times!.ordered (৬-আইটেম, সূর্যোদয় সহ) ব্যবহার হতো যা
  // _activeIndex (এখন ৫-আইটেম _prayerMeta স্কিমে) এর সাথে আর মেলে না। এখন
  // _adjustedTime() (৫-আইটেম, অফসেট-সহ) ব্যবহার করা হয়, আর এশার (শেষ ইনডেক্স)
  // পরে আগামীকালের ফজর পর্যন্ত প্রগ্রেস হিসাব করে wrap-around করা হয়।
  double _getProgressPercentage() {
    final times = _prayerOnlyTimes;
    if (times == null || _activeIndex < 0 || _activeIndex >= times.length) {
      return 0;
    }

    final now = DateTime.now();
    final currentPrayer = _adjustedTime(_activeIndex) ?? times[_activeIndex];
    final nextIndex = _activeIndex + 1;
    final DateTime nextPrayer;
    if (nextIndex < times.length) {
      nextPrayer = _adjustedTime(nextIndex) ?? times[nextIndex];
    } else {
      // এশার পরে — আগামীকালের ফজর পর্যন্ত progress ধরা হয়
      nextPrayer = PrayerTimeService.calculate(
        latitude: _lat,
        longitude: _lng,
        date: now.add(const Duration(days: 1)),
      ).fajr;
    }

    final total = nextPrayer.difference(currentPrayer).inMinutes;
    final elapsed = now.difference(currentPrayer).inMinutes;

    if (total <= 0) return 0;
    if (elapsed < 0) return 0;
    if (elapsed > total) return 1;

    return elapsed / total;
  }
}

// Custom painter for semi-circle progress indicator
class _SemiCirclePainter extends CustomPainter {
  final double progress;
  final int activeIndex;
  final Color bgArcColor;
  // 11.7: pulse ০..১ এর মধ্যে অনবরত দোলে (AnimationController থেকে) —
  // সূর্যের glow/সাইজ এটা দিয়ে হালকা স্পন্দিত হয়।
  final double pulse;

  _SemiCirclePainter({
    required this.progress,
    required this.activeIndex,
    required this.bgArcColor,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height;
    final radius = size.width / 2 - 8;

    // Background arc (theme-aware: light grey in light mode, subtle light-on-dark in dark mode)
    final bgPaint = Paint()
      ..color = bgArcColor
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

    // 11.7: সূর্য আগে সবসময় আর্কের টপে স্ট্যাটিক বসানো থাকত। এখন progress
    // (বর্তমান ওয়াক্তের ভেতর কতটুকু সময় পার হয়েছে) অনুযায়ী আর্ক বরাবর বাম
    // প্রান্ত (progress=0) থেকে ডান প্রান্তে (progress=1) সরে — ঠিক সবুজ
    // progress arc এর টিপে থাকে। সাথে হালকা pulsing glow (blur + সাইজ
    // দোলন, pulse ০..১ থেকে)।
    final sunAngle = math.pi + math.pi * progress.clamp(0.0, 1.0);
    final sunCenter = Offset(
      centerX + radius * math.cos(sunAngle),
      centerY + radius * math.sin(sunAngle),
    );

    final glowPaint = Paint()
      ..color = Colors.amber.withValues(alpha: 0.20 + pulse * 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(sunCenter, 13 + pulse * 5, glowPaint);

    final sunPaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.fill;
    canvas.drawCircle(sunCenter, 7 + pulse * 1.5, sunPaint);
  }

  @override
  bool shouldRepaint(_SemiCirclePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeIndex != activeIndex ||
        oldDelegate.bgArcColor != bgArcColor ||
        oldDelegate.pulse != pulse;
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
