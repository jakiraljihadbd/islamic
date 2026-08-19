import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart' as tz;
import 'prayer_time_service.dart';

/// Fetches prayer timings from Aladhan API and converts them into DailyPrayerTimes.
class AladhanService {
  /// Get timings for given coordinates and date (local date). Method default 2 (ISNA) or 1 etc.
  /// Returns DailyPrayerTimes parsed with timezone from API.
  static Future<DailyPrayerTimes> fetchTimings({
    required double latitude,
    required double longitude,
    required DateTime date,
    int method = 1,
  }) async {
    final dateString = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final uri = Uri.parse('https://api.aladhan.com/v1/timings/$dateString')
        .replace(queryParameters: {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'method': method.toString(),
      'timestamp': (date.millisecondsSinceEpoch ~/ 1000).toString(),
    });

    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw Exception('Aladhan API error: ${res.statusCode}');
    }
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    if (map['code'] != 200) {
      throw Exception('Aladhan API returned non-200 code: ${map['code']}');
    }
    final data = map['data'] as Map<String, dynamic>;
    final timings = data['timings'] as Map<String, dynamic>;
    final meta = data['meta'] as Map<String, dynamic>?;
    final timezoneName = meta != null && meta['timezone'] != null ? meta['timezone'] as String : tz.local.name;

    DateTime _fromTimeString(String timeStr) {
      // timeStr example: "04:12 (BST)" or "04:12"
      final cleaned = timeStr.split(' ').first;
      final parts = cleaned.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final dt = DateTime(date.year, date.month, date.day, h, m);
      final location = tz.getLocation(timezoneName);
      return tz.TZDateTime.from(dt, location).toLocal();
    }

    final fajr = _fromTimeString(timings['Fajr'] as String);
    final sunrise = _fromTimeString(timings['Sunrise'] as String);
    final dhuhr = _fromTimeString(timings['Dhuhr'] as String);
    final asr = _fromTimeString(timings['Asr'] as String);
    final maghrib = _fromTimeString(timings['Maghrib'] as String);
    final isha = _fromTimeString(timings['Isha'] as String);

    return DailyPrayerTimes(
      fajr: fajr,
      sunrise: sunrise,
      dhuhr: dhuhr,
      asr: asr,
      maghrib: maghrib,
      isha: isha,
    );
  }
}
