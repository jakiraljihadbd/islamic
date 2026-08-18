import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// অ্যাপ ক্র্যাশ হলে তার কারণ (error + stack trace) একটা টেক্সট ফাইলে লিখে
/// রাখে, যাতে adb/logcat ছাড়াই শুধু File Manager দিয়ে ফোনে গিয়ে দেখা যায়।
///
/// ফাইলটা পাওয়া যাবে এখানে:
///   Android/data/com.islamiczone.org/files/islamic_zone_crash_log.txt
///
/// (এটা অ্যাপের নিজের external files ডিরেক্টরি — এর জন্য আলাদা কোনো
/// storage permission লাগে না।)
class CrashLogger {
  static const _fileName = 'islamic_zone_crash_log.txt';

  /// পুরো অ্যাপ এই ফাংশনের ভেতর থেকে চালাতে হবে, যাতে যেকোনো uncaught
  /// exception এখানে ধরা পড়ে এবং ফাইলে লেখা হয়।
  static Future<void> runGuarded(FutureOr<void> Function() body) async {
    await runZonedGuarded<Future<void>>(() async {
      // Flutter framework-এর নিজস্ব error (widget build ইত্যাদির মধ্যে) ধরা
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        _write(details.exceptionAsString(), details.stack);
      };

      // Flutter framework-এর বাইরের (platform/async) error ধরা
      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        _write(error.toString(), stack);
        return true;
      };

      await body();
    }, (Object error, StackTrace stack) {
      // runZonedGuarded-এর নিজস্ব zone-এর বাইরে ছুটে যাওয়া error ধরা
      _write(error.toString(), stack);
    });
  }

  static void _write(String error, StackTrace? stack) {
    // ফাইলে লেখাটা fire-and-forget রাখা হচ্ছে, যাতে crash handling নিজেই
    // অ্যাপকে আরও ধীর/ব্লক না করে দেয়।
    unawaited(_writeAsync(error, stack));
  }

  static Future<void> _writeAsync(String error, StackTrace? stack) async {
    try {
      final dir = await getExternalStorageDirectory();
      if (dir == null) return;
      final file = File('${dir.path}/$_fileName');
      final buffer = StringBuffer()
        ..writeln('===== ${DateTime.now()} =====')
        ..writeln(error)
        ..writeln(stack ?? '')
        ..writeln();
      // নতুন crash আগেরটার নিচে যোগ হবে (append), পুরনো লগ মুছে যাবে না।
      await file.writeAsString(buffer.toString(), mode: FileMode.append, flush: true);
    } catch (_) {
      // লগ লেখাই যদি ব্যর্থ হয়, সেটার জন্য আর কিছু করার নেই — চুপচাপ বাদ দাও,
      // যাতে crash logger নিজেই নতুন সমস্যার কারণ না হয়ে দাঁড়ায়।
    }
  }
}
