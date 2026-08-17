import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/quran_screen.dart';
import '../screens/prayer_screen.dart';
import '../screens/dua_screen.dart';
import '../screens/more_screen.dart';
import '../theme/app_colors.dart';

/// Mirrors MainActivity.java: a persistent bottom nav bar swapping between
/// 5 top-level screens. IndexedStack keeps each tab's state alive, like the
/// original app's FragmentManager did (fragments weren't recreated on swap).
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    QuranScreen(),
    PrayerScreen(),
    DuaScreen(),
    MoreScreen(),
  ];

  // মূল bottom_navigation.xml এর img_nav_{home,quran,prayer,dua,more}.png
  // ব্যবহার করে, itemIconTint (res/color/bottom_nav_color.xml: checked → primary,
  // unchecked → #757575) এর হুবহু সমতুল্য ColorFiltered দিয়ে।
  static const _navAssets = [
    'assets/images/nav/img_nav_home.png',
    'assets/images/nav/img_nav_quran.png',
    'assets/images/nav/img_nav_prayer.png',
    'assets/images/nav/img_nav_dua.png',
    'assets/images/nav/img_nav_more.png',
  ];

  static const _labels = ['হোম', 'কুরআন', 'নামাজ', 'দোয়া', 'আরো'];

  static const _unselectedTint = Color(0xFF757575);

  Widget _navIcon(String asset, bool selected) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        selected ? AppColors.primary : _unselectedTint,
        BlendMode.srcIn,
      ),
      child: Image.asset(asset, width: 24, height: 24),
    );
  }

  List<NavigationDestination> get _destinations => List.generate(
        _navAssets.length,
        (i) => NavigationDestination(
          icon: _navIcon(_navAssets[i], false),
          selectedIcon: _navIcon(_navAssets[i], true),
          label: _labels[i],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _destinations,
      ),
    );
  }
}
