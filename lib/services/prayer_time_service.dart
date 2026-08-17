import 'package:adhan/adhan.dart';

/// একটা দিনের ৬টা নামাজের সময় (ফজর, সূর্যোদয়, যোহর, আসর, মাগরিব, এশা)।
class DailyPrayerTimes {
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;

  const DailyPrayerTimes({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  /// UI-তে দেখানোর জন্য নাম -> সময়, ক্রম অনুযায়ী।
  List<MapEntry<String, DateTime>> get ordered => [
        MapEntry('ফজর', fajr),
        MapEntry('সূর্যোদয়', sunrise),
        MapEntry('যোহর', dhuhr),
        MapEntry('আসর', asr),
        MapEntry('মাগরিব', maghrib),
        MapEntry('এশা', isha),
      ];
}

/// `adhan` প্যাকেজ দিয়ে lat/lng/date থেকে নামাজের সময় বের করে।
/// এখনো কোনো UI-তে জোড়া লাগানো হয়নি (sub-task 1.3 এ হবে)।
class PrayerTimeService {
  /// ক্যালকুলেশন মেথড — ডিফল্ট হিসেবে Karachi (University of Islamic
  /// Sciences) ব্যবহার করা হচ্ছে, যেটা বাংলাদেশে সবচেয়ে বেশি প্রচলিত।
  static CalculationParameters _params() {
    final params = CalculationMethod.karachi.getParameters();
    params.madhab = Madhab.shafi; // আসরের হিসাব শাফি অনুযায়ী (bd এ প্রচলিত)
    return params;
  }

  /// নির্দিষ্ট lat/lng ও তারিখের জন্য ৬টা নামাজের সময় রিটার্ন করে।
  static DailyPrayerTimes calculate({
    required double latitude,
    required double longitude,
    required DateTime date,
  }) {
    final coordinates = Coordinates(latitude, longitude);
    final dateComponents = DateComponents.from(date);
    final prayerTimes = PrayerTimes(coordinates, dateComponents, _params());

    return DailyPrayerTimes(
      fajr: prayerTimes.fajr,
      sunrise: prayerTimes.sunrise,
      dhuhr: prayerTimes.dhuhr,
      asr: prayerTimes.asr,
      maghrib: prayerTimes.maghrib,
      isha: prayerTimes.isha,
    );
  }

  /// এখনকার সময় অনুযায়ী পরবর্তী নামাজ কোনটা তা বের করে।
  /// রিটার্ন করে নামাজের নাম আর সেই সময়টা (আজকের মধ্যে না পেলে আগামীকালের ফজর)।
  static MapEntry<String, DateTime> nextPrayer({
    required double latitude,
    required double longitude,
    required DateTime now,
  }) {
    final today = calculate(latitude: latitude, longitude: longitude, date: now);
    for (final entry in today.ordered) {
      if (entry.key == 'সূর্যোদয়') continue; // সূর্যোদয় নামাজ না, বাদ
      if (entry.value.isAfter(now)) return entry;
    }
    // আজকের সব শেষ — আগামীকালের ফজর
    final tomorrow = calculate(
      latitude: latitude,
      longitude: longitude,
      date: now.add(const Duration(days: 1)),
    );
    return MapEntry('ফজর', tomorrow.fajr);
  }
}
