import 'package:flutter/material.dart';
import '../models/surah.dart';
import '../theme/app_colors.dart';
import 'quran_reader_screen.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  List<Surah>? _surahs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final surahs = await SurahRepository.loadAll();
    if (!mounted) return;
    setState(() => _surahs = surahs);
  }

  @override
  Widget build(BuildContext context) {
    final surahs = _surahs;
    return Scaffold(
      appBar: AppBar(
        // 7.5: bg_header_gradient.xml, ported to Quran screen's header
        // (original fragment_quran.xml used the same drawable here).
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.onPrimary,
        title: const Text('কুরআন'),
      ),
      body: surahs == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: surahs.length,
              itemBuilder: (context, i) {
                final s = surahs[i];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      // 7.5: bg_icon_circle.xml
                      backgroundColor: AppColors.iconCircleBackground,
                      child: Text('${s.number}', style: const TextStyle(color: AppColors.primary)),
                    ),
                    title: Text(s.nameBengali),
                    subtitle: Text('${s.nameArabic}  •  আয়াত ${s.ayahs}  •  ${s.revelationType}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => QuranReaderScreen(surahIndex: s.number, surahName: s.nameBengali),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
