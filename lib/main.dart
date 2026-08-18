import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'services/crash_logger.dart';
import 'services/theme_controller.dart';
import 'widgets/root_shell.dart';

void main() {
  // পুরো অ্যাপ এই wrapper-এর ভেতর থেকে চালানো হচ্ছে যাতে কোনো ধরনের
  // uncaught exception (widget build error, async error ইত্যাদি) সরাসরি
  // ফোনের Android/data/com.islamiczone.org/files/islamic_zone_crash_log.txt
  // ফাইলে লেখা হয় — adb/logcat ছাড়াই crash-এর কারণ দেখা যাবে।
  CrashLogger.runGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Original app locks orientation to portrait for every screen.
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    await ThemeController.instance.loadSaved();
    runApp(const IslamicZoneApp());
  });
}

class IslamicZoneApp extends StatelessWidget {
  const IslamicZoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'IslamicZone',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: const RootShell(),
        );
      },
    );
  }
}
