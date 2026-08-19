import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../services/alarm_service.dart';
import '../theme/app_colors.dart';

/// Full-screen azan alert — shown over the lock screen (or on top of the
/// app, if already open) the moment a prayer alarm fires, the same way an
/// alarm-clock or incoming-call screen works. This is what actually makes
/// the alarm feel "শক্তিশালী" (strong/reliable): a quiet background
/// notification is easy to miss or get killed by the OS, a full-screen
/// wake-up with sound is not.
///
/// Launched two ways (both wired in main.dart / app.dart):
///  1. Cold start — app was closed, notification's fullScreenIntent launched
///     it directly into this screen (via getNotificationAppLaunchDetails).
///  2. Warm — app already running, onDidReceiveNotificationResponse pushes
///     this screen on top of whatever the user was doing.
class AzanAlarmScreen extends StatefulWidget {
  final String prayerName;
  final int alarmId;

  const AzanAlarmScreen({
    super.key,
    required this.prayerName,
    this.alarmId = 0,
  });

  @override
  State<AzanAlarmScreen> createState() => _AzanAlarmScreenState();
}

class _AzanAlarmScreenState extends State<AzanAlarmScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  bool _stopped = false;

  @override
  void initState() {
    super.initState();

    // Keep the screen readable at a glance even if it woke the device from
    // deep sleep — high-contrast, no reliance on system brightness.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    // Start playback immediately. Fire-and-forget: the Stop button calls
    // AlarmService.stopAzan() directly rather than awaiting this future, so
    // the UI never blocks on audio completion.
    AlarmService.instance.playAzanFromAsset();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _pulseController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _stop() async {
    if (_stopped) return;
    setState(() => _stopped = true);
    await AlarmService.instance.stopAzan();
    await AlarmService.instance.dismissNotification(widget.alarmId);
    HapticFeedback.mediumImpact();
    if (mounted) {
      // A short delay lets the button's "বন্ধ হয়েছে" state register before
      // the screen closes, instead of vanishing instantly.
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Swiping/back-button alone shouldn't silently dismiss a ringing
      // alarm — route it through the same stop logic instead.
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _stop();
      },
      child: Scaffold(
        backgroundColor: AppColors.primaryDark,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              Text(
                DateFormat('hh:mm a').format(_now),
                style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              ScaleTransition(
                scale: Tween(begin: 0.94, end: 1.06).animate(
                  CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                ),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                    border: Border.all(color: AppColors.secondary.withOpacity(0.6), width: 2),
                  ),
                  child: const Icon(Icons.mosque, color: AppColors.secondary, size: 56),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'নামাজের সময় হয়েছে',
                style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                widget.prayerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                child: SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _stopped ? null : _stop,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _stopped ? Colors.white24 : AppColors.secondary,
                      foregroundColor: _stopped ? Colors.white70 : AppColors.onSecondary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                    child: Text(
                      _stopped ? 'বন্ধ হয়েছে' : 'আজান বন্ধ করুন',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
