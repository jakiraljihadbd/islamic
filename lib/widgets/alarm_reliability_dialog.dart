import 'package:flutter/material.dart';

import '../services/alarm_reliability_service.dart';
import '../theme/app_colors.dart';

/// প্রথমবার কোনো নামাজের alarm চালু করলে (এবং সেটিংস থেকে ইচ্ছামতো) দেখানো
/// চেকলিস্ট — ফোনের ব্র্যান্ড অনুযায়ী কোন সেটিংস অন করলে আজান কখনো মিস
/// হবে না, তা ধাপে ধাপে দেখায়। প্রতিটা ধাপ ব্যবহারকারী নিজে গিয়ে অন
/// করবে (Android নিরাপত্তার কারণে এগুলো কোড দিয়ে সরাসরি অন করা যায় না),
/// তাই dialog শুধু সঠিক সেটিংস স্ক্রিনে নিয়ে যাওয়ার কাজ করে।
Future<void> showAlarmReliabilityDialog(BuildContext context) async {
  await AlarmReliabilityService.instance.markShown();
  if (!context.mounted) return;

  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => const _AlarmReliabilityDialog(),
  );
}

class _AlarmReliabilityDialog extends StatefulWidget {
  const _AlarmReliabilityDialog();

  @override
  State<_AlarmReliabilityDialog> createState() => _AlarmReliabilityDialogState();
}

class _AlarmReliabilityDialogState extends State<_AlarmReliabilityDialog> {
  bool _batteryDone = false;
  bool _autostartDone = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('আজান যেন মিস না হয়'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'কিছু ফোনে (Xiaomi, Oppo, Vivo, Huawei, Samsung ইত্যাদি) সিস্টেম '
              'নিজে থেকেই ব্যাকগ্রাউন্ড অ্যাপ বন্ধ করে দেয়, যার ফলে আজান বাজে না। '
              'নিচের ২টা অপশন অন করে দিন — এটা একবারই করতে হবে।',
              style: TextStyle(fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 18),
            _step(
              done: _batteryDone,
              title: 'ব্যাটারি অপটিমাইজেশন বন্ধ করুন',
              subtitle: 'অ্যাপকে "No restrictions" / "Unrestricted" রাখুন',
              buttonLabel: 'ওপেন করুন',
              onPressed: () async {
                await AlarmReliabilityService.instance.requestBatteryExemption();
                if (mounted) setState(() => _batteryDone = true);
              },
            ),
            const SizedBox(height: 14),
            _step(
              done: _autostartDone,
              title: 'Autostart / ব্যাকগ্রাউন্ড পারমিশন চালু করুন',
              subtitle: 'ফোনের ব্র্যান্ড অনুযায়ী সঠিক সেটিংস পেজ খুলবে',
              buttonLabel: 'ওপেন করুন',
              onPressed: () async {
                await AlarmReliabilityService.instance.openAutostartSettings();
                if (mounted) setState(() => _autostartDone = true);
              },
            ),
            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 12),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: AppColors.secondary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'এছাড়া রিসেন্ট অ্যাপস থেকে সোয়াইপ করে অ্যাপটা বন্ধ করবেন না — '
                    'বরং লক (padlock) আইকন থাকলে সেটা চালু রাখুন।',
                    style: TextStyle(fontSize: 12.5, color: Colors.black54, height: 1.4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('বুঝেছি'),
        ),
      ],
    );
  }

  Widget _step({
    required bool done,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          color: done ? AppColors.success : Colors.black38,
          size: 22,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 6),
              SizedBox(
                height: 34,
                child: OutlinedButton(
                  onPressed: onPressed,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(buttonLabel, style: const TextStyle(fontSize: 12.5)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
