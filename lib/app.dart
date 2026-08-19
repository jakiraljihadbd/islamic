import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'services/theme_controller.dart';
import 'widgets/root_shell.dart';
import 'screens/azan_alarm_screen.dart';

/// Global navigator key so code with no BuildContext of its own — the
/// notification-tap callback in main.dart, which fires whether or not the
/// user is currently looking at a particular screen — can still push the
/// full-screen azan alert on top of the app.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class IslamicZoneApp extends StatelessWidget {
  /// If the app was cold-started by tapping/full-screen-intent from an azan
  /// notification, this carries {'id': ..., 'prayerName': ...} so we can
  /// open straight into the alarm screen instead of the normal home screen.
  final Map<String, dynamic>? initialAlarmPayload;

  const IslamicZoneApp({super.key, this.initialAlarmPayload});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (context, mode, _) {
        return MaterialApp(
          navigatorKey: rootNavigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'IslamicZone',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: initialAlarmPayload != null
              ? AzanAlarmScreen(
                  prayerName: (initialAlarmPayload!['prayerName'] as String?) ?? 'নামাজ',
                  alarmId: (initialAlarmPayload!['id'] as int?) ?? 0,
                )
              : const RootShell(),
        );
      },
    );
  }
}
