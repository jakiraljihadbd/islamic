import 'package:flutter/material.dart';

/// Colors ported 1:1 from the original Android res/values/colors.xml
/// so the Flutter app looks identical to the native IslamicZone app.
class AppColors {
  AppColors._();

  // Primary - Islamic Emerald
  static const primary = Color(0xFF0B6E4F);
  static const primaryVariant = Color(0xFF0E8C63);
  static const primaryDark = Color(0xFF073B2B);
  static const primaryLight = Color(0xFF4FBF8F);
  static const onPrimary = Color(0xFFFFFFFF);

  // Secondary - Royal Gold
  static const secondary = Color(0xFFD4A017);
  static const secondaryVariant = Color(0xFFF4C430);
  static const onSecondary = Color(0xFF1A1300);

  // Background / Surface (light)
  static const background = Color(0xFFF4F8F6);
  static const surface = Color(0xFFFFFFFF);
  static const onBackground = Color(0xFF13241C);
  static const onSurface = Color(0xFF13241C);

  // Dark theme
  static const backgroundDark = Color(0xFF0D1512);
  static const surfaceDark = Color(0xFF16221C);
  static const onBackgroundDark = Color(0xFFE6E1E5);

  // Prayer accent colors
  static const prayerSunrise = Color(0xFFFF8C42);
  static const prayerFajr = Color(0xFF2D6CC0);
  static const prayerDhuhr = Color(0xFFE8A33D);
  static const prayerAsr = Color(0xFFC06B3E);
  static const prayerMaghrib = Color(0xFFA14FA0);
  static const prayerIsha = Color(0xFF3F4FA1);

  // Status
  static const success = Color(0xFF2E9E5B);
  static const warning = Color(0xFFE8A93D);
  static const error = Color(0xFFD8483D);

  // Cards
  static const cardBackground = Color(0xFFFFFFFF);
  static const divider = Color(0xFFE2EAE6);

  // 7.5: bg_icon_circle.xml (oval, solid #E8F5E9) — generic soft-green
  // circle background used behind primary-colored icons (quick actions,
  // list leading avatars) across the app.
  static const iconCircleBackground = Color(0xFFE8F5E9);

  /// 7.5: bg_header_gradient.xml — linear gradient, angle 135°,
  /// primary_variant → primary → primary_dark. Android angle 135 runs
  /// bottom-right → top-left, so mirrored here as bottomRight → topLeft.
  static const headerGradient = LinearGradient(
    begin: Alignment.bottomRight,
    end: Alignment.topLeft,
    colors: [primaryVariant, primary, primaryDark],
    stops: [0.0, 0.5, 1.0],
  );

  /// 7.2b: bg_petal_active.xml — oval, angle 135° (bottomRight → topLeft),
  /// success → primary_variant. প্রার্থনা-ফুলের active/tapped পাপড়ির
  /// circle background হিসেবে ব্যবহৃত।
  static const petalActiveGradient = LinearGradient(
    begin: Alignment.bottomRight,
    end: Alignment.topLeft,
    colors: [success, primaryVariant],
  );
}
