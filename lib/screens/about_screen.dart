import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 5.5: About/অ্যাপ সম্পর্কে স্ক্রিন — অ্যাপ পরিচিতি, ভার্সন, ফিচার লিস্ট।
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _features = [
    'নামাজের সময়সূচী (GPS-ভিত্তিক নির্ভুল হিসাব)',
    'পূর্ণাঙ্গ কুরআন (১১৪টা সূরা, PDF রিডার)',
    'দোয়া সংকলন (আরবি + উচ্চারণ + বাংলা অনুবাদ)',
    'ডিজিটাল তাসবিহ কাউন্টার',
    'কিবলা নির্দেশক (কম্পাস + GPS)',
    'আল্লাহর ৯৯ নাম',
    'হিজরি ক্যালেন্ডার',
    'যাকাত ক্যালকুলেটর',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('অ্যাপ সম্পর্কে')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.mosque, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 12),
                const Text('IslamicZone', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('ভার্সন ১.০.০', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'IslamicZone একটি সম্পূর্ণ ইসলামিক অ্যাসিস্ট্যান্ট অ্যাপ — নামাজের সময়, কুরআন, দোয়া, '
            'কিবলা, তাসবিহ এবং আরো অনেক ফিচার এক জায়গায়।',
            style: TextStyle(fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 20),
          const Text('ফিচারসমূহ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._features.map(
            (f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, size: 18, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(child: Text(f, style: const TextStyle(fontSize: 14))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'আল্লাহ আমাদের সবাইকে দ্বীনের উপর অবিচল রাখুন। আমীন।',
              style: TextStyle(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
