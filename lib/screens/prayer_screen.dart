import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/prayer_time_service.dart';
import '../theme/app_colors.dart';

class _PrayerMeta {
  final String name;
  final Color color;
  const _PrayerMeta(this.name, this.color);
}

const _prayerMeta = [
  _PrayerMeta('ফজর', AppColors.prayerFajr),
  _PrayerMeta('সূর্যোদয়', AppColors.prayerSunrise),
  _PrayerMeta('যোহর', AppColors.prayerDhuhr),
  _PrayerMeta('আসর', AppColors.prayerAsr),
  _PrayerMeta('মাগরিব', AppColors.prayerMaghrib),
  _PrayerMeta('ইশা', AppColors.prayerIsha),
];

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  // Default: Dhaka (location resolve না হলে এই ফলব্যাক)।
  double _lat = 23.8103;
  double _lng = 90.4125;
  DailyPrayerTimes? _times;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
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
    if (!mounted) return;
    setState(() {
      _times = PrayerTimeService.calculate(latitude: _lat, longitude: _lng, date: DateTime.now());
      _loading = false;
    });
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
    final times = _times?.ordered;
    return Scaffold(
      appBar: AppBar(title: const Text('নামাজের সময়')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _prayerMeta.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final meta = _prayerMeta[i];
                final time = times != null ? _fmt(times[i].value) : '--:--';
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: meta.color.withValues(alpha: 0.15),
                      child: Icon(Icons.wb_twighlight, color: meta.color),
                    ),
                    title: Text(meta.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Text(time, style: const TextStyle(fontSize: 16)),
                  ),
                );
              },
            ),
    );
  }
}
