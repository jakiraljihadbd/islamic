import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// Equivalent to QuranPdfActivity.java - opens the bundled quran.pdf asset.
/// [surahIndex] সূরা নাম্বার (শুধু রেফারেন্সের জন্য রাখা)।
/// [jumpToPage] দিলে PDF viewer সেই পেজে সরাসরি নিয়ে যাবে (surah.dart এর
/// surah_pages.json ম্যাপিং থেকে আসে, সূরা ৭৮+ এর পেজ আনুমানিক হতে পারে)।
class QuranPdfScreen extends StatefulWidget {
  final int? surahIndex;
  final int? jumpToPage;
  const QuranPdfScreen({super.key, this.surahIndex, this.jumpToPage});

  @override
  State<QuranPdfScreen> createState() => _QuranPdfScreenState();
}

class _QuranPdfScreenState extends State<QuranPdfScreen> {
  final _controller = PdfViewerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('কুরআন শরীফ')),
      body: SfPdfViewer.asset(
        'assets/quran.pdf',
        controller: _controller,
        onDocumentLoaded: (details) {
          final page = widget.jumpToPage;
          if (page != null && page >= 1 && page <= details.document.pages.count) {
            _controller.jumpToPage(page);
          }
        },
      ),
    );
  }
}
