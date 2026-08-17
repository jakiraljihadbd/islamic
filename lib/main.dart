import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'services/theme_controller.dart';
import 'widgets/root_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Original app locks orientation to portrait for every screen.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) async {
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
