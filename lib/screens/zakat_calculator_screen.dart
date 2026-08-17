import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 5.3: যাকাত ক্যালকুলেটর — নগদ, স্বর্ণ/রূপার মূল্য, ব্যবসায়িক সম্পদ, ঋণ ইনপুট নিয়ে
/// নিসাবের সাথে তুলনা করে ২.৫% যাকাত হিসাব করে।
class ZakatCalculatorScreen extends StatefulWidget {
  const ZakatCalculatorScreen({super.key});

  @override
  State<ZakatCalculatorScreen> createState() => _ZakatCalculatorScreenState();
}

class _ZakatCalculatorScreenState extends State<ZakatCalculatorScreen> {
  final _cashController = TextEditingController();
  final _goldController = TextEditingController();
  final _businessController = TextEditingController();
  final _debtController = TextEditingController();
  final _nisabController = TextEditingController(text: '87000');

  double? _zakat;
  bool? _eligible;

  @override
  void dispose() {
    _cashController.dispose();
    _goldController.dispose();
    _businessController.dispose();
    _debtController.dispose();
    _nisabController.dispose();
    super.dispose();
  }

  double _parse(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  void _calculate() {
    final cash = _parse(_cashController);
    final gold = _parse(_goldController);
    final business = _parse(_businessController);
    final debt = _parse(_debtController);
    final nisab = _parse(_nisabController);

    final totalAssets = cash + gold + business;
    final netWealth = totalAssets - debt;
    final eligible = netWealth >= nisab && nisab > 0;

    setState(() {
      _eligible = eligible;
      _zakat = eligible ? netWealth * 0.025 : 0;
    });
  }

  Widget _field(String label, TextEditingController controller, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('যাকাত ক্যালকুলেটর')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('আপনার সম্পদের হিসাব (টাকায়)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _field('নগদ টাকা ও ব্যাংক ব্যালেন্স', _cashController),
            _field('স্বর্ণ/রূপার বাজারমূল্য', _goldController),
            _field('ব্যবসায়িক সম্পদের মূল্য', _businessController),
            _field('ঋণ ও দায় (বাদ যাবে)', _debtController),
            _field('নিসাবের পরিমাণ', _nisabController, hint: 'ডিফল্ট: বর্তমান রূপার নিসাব আনুমানিক'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('যাকাত হিসাব করুন', style: TextStyle(color: Colors.white)),
            ),
            if (_zakat != null) ...[
              const SizedBox(height: 20),
              Card(
                color: _eligible == true ? AppColors.primary.withValues(alpha: 0.08) : null,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        _eligible == true ? 'আপনার উপর যাকাত ফরজ' : 'নিসাব পূর্ণ হয়নি, যাকাত ফরজ নয়',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _eligible == true ? AppColors.primary : AppColors.error,
                        ),
                      ),
                      if (_eligible == true) ...[
                        const SizedBox(height: 8),
                        Text(
                          'প্রদেয় যাকাত: ৳ ${_zakat!.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.secondary),
                        ),
                        const SizedBox(height: 4),
                        const Text('(মোট সম্পদের ২.৫%)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
