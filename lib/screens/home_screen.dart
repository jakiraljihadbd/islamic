import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/daily_content.dart';
import '../services/prayer_time_service.dart';
import '../theme/app_colors.dart';
import '../widgets/prayer_flower_widget.dart';
import '../widgets/salat_tracker_card.dart';
import '../widgets/quran_tracker_card.dart';
import 'tasbih_screen.dart';
import 'qibla_screen.dart';
import 'zakat_calculator_screen.dart';

class _QuickAction {
  final String label;
  final IconData icon;
  const _QuickAction(this.label, this.icon);
}

const _quickActions = [
  _QuickAction('কুরআন', Icons.menu_book),
  _QuickAction('হাদিস', Icons.article_outlined),
  _QuickAction('তাসবিহ', Icons.fingerprint),
  _QuickAction('কিবলা', Icons.explore_outlined),
  _QuickAction('যাকাত', Icons.percent),
  _QuickAction('রমজান', Icons.nightlight_round),
  _QuickAction('হজ্জ', Icons.mosque_outlined),
  _QuickAction('আরো', Icons.apps),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _lat = 23.8103;
  double _lng = 90.4125;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      var granted = permission == LocationPermission.always || permission == LocationPermission.whileInUse;
      if (!granted) {
        final requested = await Geolocator.requestPermission();
        granted = requested == LocationPermission.always || requested == LocationPermission.whileInUse;
      }
      if (granted && await Geolocator.isLocationServiceEnabled()) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
        );
        if (mounted) {
          setState(() {
            _lat = pos.latitude;
            _lng = pos.longitude;
          });
        }
      }
    } catch (_) {
      // location না পেলে ডিফল্ট ঢাকা কোঅর্ডিনেট ব্যবহার হবে।
    }
  }

  void _onQuickAction(BuildContext context, String label) {
    switch (label) {
      case 'তাসবিহ':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TasbihScreen()));
        break;
      case 'কিবলা':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QiblaScreen()));
        break;
      case 'যাকাত':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ZakatCalculatorScreen()));
        break;
      default:
        // TODO: wire remaining quick actions once their screens are built.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              decoration: const BoxDecoration(
                // 7.5: bg_header_gradient.xml
                gradient: AppColors.headerGradient,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('আসসালামু আলাইকুম',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const _NextPrayerCard(),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            sliver: SliverToBoxAdapter(
              child: PrayerFlowerWidget(lat: _lat, lng: _lng),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('দ্রুত অ্যাক্সেস', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _quickActions.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemBuilder: (context, i) {
                      final action = _quickActions[i];
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _onQuickAction(context, action.label),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 26,
                              // 7.5: bg_icon_circle.xml
                              backgroundColor: AppColors.iconCircleBackground,
                              child: Icon(action.icon, color: AppColors.primary),
                            ),
                            const SizedBox(height: 6),
                            Text(action.label, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Phase-3: আজকের সালাত ট্র্যাকার (৫ ওয়াক্ত টিক/ক্রস, SharedPreferences persist)
                  const SalatTrackerCard(),
                  const SizedBox(height: 12),
                  // Phase-4 (ডেমো): কুরআন তিলাওয়াত সময় + আয়াত কাউন্ট ট্র্যাকার
                  const QuranTrackerCard(),
                  const SizedBox(height: 24),
                  const Text('আজকের আয়াত ও হাদিস', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  const _DailyVerseHadithCard(),
                  const SizedBox(height: 24),
                  const Text('দৈনিক লক্ষ্য', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  const _DailyGoalsCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextPrayerCard extends StatefulWidget {
  const _NextPrayerCard();

  @override
  State<_NextPrayerCard> createState() => _NextPrayerCardState();
}

class _NextPrayerCardState extends State<_NextPrayerCard> {
  // Default: Dhaka (location resolve না হলে এই ফলব্যাক)।
  double _lat = 23.8103;
  double _lng = 90.4125;
  MapEntry<String, DateTime>? _next;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final permission = await Geolocator.checkPermission();
      var granted = permission == LocationPermission.always || permission == LocationPermission.whileInUse;
      if (!granted) {
        final requested = await Geolocator.requestPermission();
        granted = requested == LocationPermission.always || requested == LocationPermission.whileInUse;
      }
      if (granted && await Geolocator.isLocationServiceEnabled()) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
        );
        _lat = pos.latitude;
        _lng = pos.longitude;
      }
    } catch (_) {
      // location না পেলে ডিফল্ট ঢাকা কোঅর্ডিনেট ব্যবহার হবে।
    }
    _refresh();
  }

  void _refresh() {
    final next = PrayerTimeService.nextPrayer(latitude: _lat, longitude: _lng, now: DateTime.now());
    if (!mounted) return;
    setState(() => _next = next);
  }

  String _countdown(DateTime target) {
    final diff = target.difference(DateTime.now());
    if (diff.isNegative) return '০০:০০';
    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _fmt(DateTime t) {
    final hour24 = t.hour;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final suffix = hour24 < 12 ? 'AM' : 'PM';
    return '$hour12:$minute $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final next = _next;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('পরবর্তী নামাজ', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                next?.key ?? '...',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                next != null ? _fmt(next.value) : '--:--',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                next != null ? 'বাকি ${_countdown(next.value)}' : '',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 4.2: রোজ একটা fix আয়াত + একটা fix হাদিস দেখায় (তারিখ অনুযায়ী, সারাদিন একই থাকে)
class _DailyVerseHadithCard extends StatefulWidget {
  const _DailyVerseHadithCard();

  @override
  State<_DailyVerseHadithCard> createState() => _DailyVerseHadithCardState();
}

class _DailyVerseHadithCardState extends State<_DailyVerseHadithCard> {
  VerseHadith? _verse;
  VerseHadith? _hadith;
  final PageController _pageController = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final verse = await DailyContentRepository.todaysVerse();
    final hadith = await DailyContentRepository.todaysHadith();
    if (!mounted) return;
    setState(() {
      _verse = verse;
      _hadith = hadith;
    });
  }

  Widget _slideCard({required String label, required IconData icon, required VerseHadith item, required Color referenceColor}) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: AppColors.secondary),
                  const SizedBox(width: 6),
                  Text(label,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                        letterSpacing: 0.3,
                      )),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.arabic,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontFamily: 'Bahij', fontSize: 21, height: 2.0),
              ),
              const SizedBox(height: 12),
              Text(item.bengali, style: const TextStyle(fontSize: 14.5, height: 1.6)),
              const SizedBox(height: 8),
              Text(item.reference,
                  style: TextStyle(fontSize: 11.5, color: referenceColor, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final verse = _verse;
    final hadith = _hadith;
    if (verse == null || hadith == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    // dark mode-এ AppColors.primaryVariant (গাঢ় সবুজ) dark card background-এর
    // উপর কম-কনট্রাস্ট/পড়তে কষ্ট হয়, তাই dark mode-এ হালকা primaryLight ব্যবহার।
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final referenceColor = isDark ? AppColors.primaryLight : AppColors.primaryVariant;
    final pages = [
      _slideCard(label: 'আজকের আয়াত', icon: Icons.menu_book_outlined, item: verse, referenceColor: referenceColor),
      _slideCard(label: 'আজকের হাদিস', icon: Icons.article_outlined, item: hadith, referenceColor: referenceColor),
    ];
    return Column(
      children: [
        SizedBox(
          // আগে ছিল hard-coded 280 (guess); এখন 260 + কার্ডের ভেতরে SingleChildScrollView
          // দিয়ে overflow-সেফ করা হয়েছে (লম্বা আয়াত/হাদিস টেক্সটেও কার্ড ভাঙবে না)।
          height: 260,
          child: PageView(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _page = i),
            children: pages,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pages.length, (i) {
            final active = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.primary.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// 4.3: দৈনিক লক্ষ্য কার্ড — আপাতত static ইনপুট (কুরআন তিলাওয়াত, তাসবিহ, দোয়া)।
/// ৫ ওয়াক্ত নামাজ আলাদা SalatTrackerCard এ (Phase-3, real persist) সরানো হয়েছে,
/// এখানে ডুপ্লিকেট রাখা হয়নি। কুরআন/তাসবিহ/দোয়া পরে Phase-4/5-এ real হবে।
class _DailyGoalsCard extends StatelessWidget {
  const _DailyGoalsCard();

  static const _goals = [
    _Goal('কুরআন তিলাওয়াত', Icons.menu_book_outlined, 1, 1),
    _Goal('তাসবি�� (১০০ বার)', Icons.fingerprint, 0, 1),
    _Goal('সকাল-সন্ধ্যার দোয়া', Icons.volunteer_activism_outlined, 1, 2),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: _goals
              .map((g) => ListTile(
                    leading: Icon(g.icon, color: AppColors.primary),
                    title: Text(g.label),
                    trailing: Text(
                      '${g.done}/${g.target}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: g.done >= g.target ? AppColors.success : AppColors.secondary,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _Goal {
  final String label;
  final IconData icon;
  final int done;
  final int target;
  const _Goal(this.label, this.icon, this.done, this.target);
}
