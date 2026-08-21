import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/daily_content.dart';
import '../theme/app_colors.dart';
import '../widgets/prayer_flower_widget.dart';
import '../widgets/salat_tracker_card.dart';
import '../widgets/quran_tracker_card.dart';
import '../widgets/tasbih_home_card.dart';

// 10.10: দ্রুত অ্যাক্সেস (তাসবিহ/কিবলা/যাকাত) সেকশন হোম থেকে সম্পূর্ণ সরানো হয়েছে —
// এই তিনটাই আগে থেকে MoreScreen-এর গ্রিডে আছে (more_screen.dart), তাই হোমে রাখলে
// ডুপ্লিকেট হতো। ইউজারের হাতে আঁকা রেফারেন্স ছবিতেও হোম স্ক্রিনে quick-access
// গ্রিড নেই — সরাসরি ফুল → আয়াত/হাদিস স্লাইড → ট্র্যাকারগুলো দেখানো হয়েছে।

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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // Worklist_home #1: "আসসালামু আলাইকুম" গ্রিটিং হেডার + "পরবর্তী নামাজ"
          // কার্ড (_NextPrayerCard, নিচে সম্পূর্ণ সরানো হয়েছে) — সম্পূর্ণ বাদ
          // দেওয়া হয়েছে। এখন স্ক্রল একদম উপর থেকেই PrayerFlowerWidget দিয়ে শুরু
          // হয় (যার নিজস্ব বিসমিল্লাহ ব্যানার আগে থেকেই আছে)।
          SliverPadding(
            // worklist_home #২: বিসমিল্লাহ ফ্রেমের উপরে-নিচের ফাঁকা জায়গা কমাতে
            // vertical প্যাডিং 16 → 10 করা হয়েছে (আরও কম্প্যাক্ট)। horizontal
            // 20 অপরিবর্তিত রাখা হয়েছে — এটাই সেই মান যা prayer_flower_widget.dart
            // -এ বিসমিল্লাহ ফ্রেমের negative margin (-20) দিয়ে ভাঙা হয়, যাতে শুধু
            // ফ্রেমটা full-width হয় আর পাপড়ি সেকশন আগের মতোই padded থাকে।
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverToBoxAdapter(
              child: PrayerFlowerWidget(lat: _lat, lng: _lng),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _DailyVerseHadithCard(),
                  const SizedBox(height: 12),
                  // Phase-3: আজকের সালাত ট্র্যাকার (৫ ওয়াক্ত টিক/ক্রস, SharedPreferences persist)
                  const SalatTrackerCard(),
                  const SizedBox(height: 12),
                  // Phase-4 (ডেমো): কুরআন তিলাওয়াত সময় + আয়াত কাউন্ট ট্র্যাকার
                  const QuranTrackerCard(),
                  const SizedBox(height: 12),
                  // 10.9: তাসবিহর কম্প্যাক্ট প্রিভিউ (real persist ডেটা, TasbihScreen এ নেভিগেট করে)
                  const TasbihHomeCard(),
                ],
              ),
            ),
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
        // worklist_home #৪: ভিতরের ফাঁকা জায়গা কমানো হয়েছে (18,16,18,14 → 16,12,16,10)
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, size: 15, color: AppColors.secondary),
                  const SizedBox(width: 6),
                  Text(label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondary,
                        letterSpacing: 0.3,
                      )),
                ],
              ),
              const SizedBox(height: 8),
              // worklist_home #৪: আয়াত/হাদিসের লেখা চোখে পড়ার মতো বড় করা হয়েছে
              // (21→24), আর weight হালকা/regular (w400) রাখা হয়েছে যাতে ভারী/বোল্ড
              // না লাগে।
              Text(
                item.arabic,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontFamily: 'Bahij', fontSize: 24, fontWeight: FontWeight.w400, height: 1.9),
              ),
              const SizedBox(height: 10),
              Text(
                item.bengali,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.65, letterSpacing: 0.15),
              ),
              const SizedBox(height: 6),
              Text(item.reference,
                  style: TextStyle(fontSize: 11.5, color: referenceColor, fontWeight: FontWeight.w500)),
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
          // worklist_home #৪: ফন্ট সাইজ বড় করার পর কন্টেন্ট আগের চেয়ে বেশি জায়গা
          // নেয়, তাই নিচের অতিরিক্ত ফাঁকা জায়গা কমাতে height 220 → 200 করা হয়েছে
          // (ভিতরের SingleChildScrollView + ClampingScrollPhysics এখনো overflow-সেফ)।
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            itemCount: pages.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, index) {
              // 10.6: হালকা fade + slide অ্যানিমেশন — পেজ যত দূরে সরে, তত ফিকে ও
              // পাশে সরে যায় (AnimatedBuilder দিয়ে _pageController-এর লাইভ
              // scroll offset শোনা হয়, প্লেইন PageView-এর বদলে PageView.builder)।
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double page = _page.toDouble();
                  if (_pageController.hasClients && _pageController.position.haveDimensions) {
                    page = _pageController.page ?? page;
                  }
                  final delta = (page - index).clamp(-1.0, 1.0);
                  final opacity = (1 - delta.abs()).clamp(0.0, 1.0);
                  return Opacity(
                    opacity: opacity,
                    child: Transform.translate(
                      offset: Offset(delta * 28, 0),
                      child: child,
                    ),
                  );
                },
                child: pages[index],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
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

// 10.10: _DailyGoalsCard ("দৈনিক লক্ষ্য") সম্পূর্ণ সরানো হয়েছে — ইউজার বলেছেন
// "বাকি সব লাগবে না"। কুরআন/সালাত/তাসবিহর real ট্র্যাকার কার্ড আগে থেকেই আলাদাভাবে
// আছে (উপরে), তাই এই static/hardcoded সামারি কার্ডটা ডুপ্লিকেট ছিল।
