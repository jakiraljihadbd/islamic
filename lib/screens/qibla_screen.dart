import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_colors.dart';

/// Ported from QiblaActivity.java. Uses the device magnetometer (via
/// flutter_compass) and the great-circle bearing formula to Kaaba.
class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  static const _kaabaLat = 21.4225;
  static const _kaabaLng = 39.8262;

  // Default location: Dhaka, matches the Java fallback.
  double _userLat = 23.8103;
  double _userLng = 90.4125;
  String _locationLabel = 'ঢাকা, বাংলাদেশ (ডিফল্ট)';
  bool _locating = true;

  @override
  void initState() {
    super.initState();
    _resolveLocation();
  }

  Future<void> _resolveLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      var granted = permission == LocationPermission.always || permission == LocationPermission.whileInUse;
      if (!granted) {
        final requested = await Geolocator.requestPermission();
        granted = requested == LocationPermission.always || requested == LocationPermission.whileInUse;
      }
      if (!granted || !await Geolocator.isLocationServiceEnabled()) {
        setState(() => _locating = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      setState(() {
        _userLat = pos.latitude;
        _userLng = pos.longitude;
        _locationLabel = 'বর্তমান অবস্থান';
        _locating = false;
      });
    } catch (_) {
      setState(() => _locating = false);
    }
  }

  double _calculateQiblaDirection() {
    final phiK = _kaabaLat * math.pi / 180;
    final lambdaK = _kaabaLng * math.pi / 180;
    final phi = _userLat * math.pi / 180;
    final lambda = _userLng * math.pi / 180;

    final qibla = math.atan2(
      math.sin(lambdaK - lambda),
      math.cos(phi) * math.tan(phiK) - math.sin(phi) * math.cos(lambdaK - lambda),
    );
    return (qibla * 180 / math.pi + 360) % 360;
  }

  @override
  Widget build(BuildContext context) {
    final qiblaDirection = _calculateQiblaDirection();

    return Scaffold(
      appBar: AppBar(title: const Text('কিবলা')),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(_locating ? 'অবস্থান নির্ণয় করা হচ্ছে...' : _locationLabel, style: TextStyle(color: Colors.grey[600])),
            Text('কিবলার দিক', style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w600)),
            Expanded(
              child: StreamBuilder<CompassEvent>(
                stream: FlutterCompass.events,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || FlutterCompass.events == null) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'এই ডিভাইসে ম্যাগনেটোমিটার সেন্সর পাওয়া যায়নি, অথবা সেন্সর রিডিং অপেক্ষা করা হচ্ছে।',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  final azimuth = snapshot.data!.heading ?? 0;
                  final targetDegree = qiblaDirection - azimuth;

                  return Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // compass_bg.xml সমতুল্য — বাইরের পুরু রিং + ৪০dp ভেতরে পাতলা রিং, রোটেট করে
                        Transform.rotate(
                          angle: -azimuth * math.pi / 180,
                          child: Container(
                            width: 260,
                            height: 260,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surface,
                              border: Border.fromBorderSide(
                                BorderSide(color: AppColors.primary, width: 3),
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 260 - 2 * 35,
                                height: 260 - 2 * 35,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.divider, width: 1.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // ic_kaaba.xml এর বদলে আসল img_kaaba.png — কিবলার real দিক নির্দেশ করে
                        Transform.rotate(
                          angle: targetDegree * math.pi / 180,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.arrow_drop_up, size: 32, color: AppColors.secondary),
                              Image.asset('assets/images/qibla/img_kaaba.png', width: 52, height: 52),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          child: Text('${qiblaDirection.toStringAsFixed(0)}°',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'ফোনটি সমতলে ধরুন এবং সোনালী তীরকে কাবার দিকে নির্দেশ করান',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
