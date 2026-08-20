import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// APK সাইজ কমানোর জন্য বান্ডেল quran.pdf (৪.২MB) ও syncfusion_flutter_pdfviewer
/// সরিয়ে ফেলা হয়েছে (APK_SIZE_OPTIMIZATION.md অনুযায়ী)। আগে এখানে QuranPdfScreen
/// PDF viewer খুলত — এখন এই স্ক্রিন ইচ্ছাকৃতভাবে খালি রাখা হয়েছে, ভবিষ্যতে
/// real কুরআন কন্টেন্ট (যেমন অন-ডিমান্ড ডাউনলোড বা টেক্সট-ভিত্তিক আয়াত রিডার)
/// এখানে যোগ করা যাবে।
class QuranReaderScreen extends StatelessWidget {
  final int? surahIndex;
  final String? surahName;
  const QuranReaderScreen({super.key, this.surahIndex, this.surahName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(surahName ?? 'কুরআন শরীফ')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_outlined, size: 56, color: AppColors.primary.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              const Text(
                'শীঘ্রই আসছে',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              const Text(
                'কুরআন রিডার এখানে যুক্ত হবে',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
