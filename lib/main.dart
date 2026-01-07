import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

String normalizeForSearch(String input) {
  var s = input.toLowerCase().trim();

  // Remove punctuation/spaces so ca'lengc == calengc
  s = s.replaceAll(RegExp(r"[’'`´\-\s]+"), "");

  // Remove tone numbers like jau4 kei4 -> jaukei
  s = s.replaceAll(RegExp(r"\d+"), "");

  // Strip common Mandarin tone marks
  const map = {
    'ā': 'a',
    'á': 'a',
    'ǎ': 'a',
    'à': 'a',
    'ē': 'e',
    'é': 'e',
    'ě': 'e',
    'è': 'e',
    'ī': 'i',
    'í': 'i',
    'ǐ': 'i',
    'ì': 'i',
    'ō': 'o',
    'ó': 'o',
    'ǒ': 'o',
    'ò': 'o',
    'ū': 'u',
    'ú': 'u',
    'ǔ': 'u',
    'ù': 'u',
    'ǖ': 'u',
    'ǘ': 'u',
    'ǚ': 'u',
    'ǜ': 'u',
    'ń': 'n',
    'ň': 'n',
    'ǹ': 'n',
    'ḿ': 'm',
  };

  final out = StringBuffer();
  for (final rune in s.runes) {
    final ch = String.fromCharCode(rune);
    out.write(map[ch] ?? ch);
  }
  return out.toString();
}

void main() => runApp(const DictionaryApp());

class DictionaryApp extends StatelessWidget {
  const DictionaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mien Dictionary',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const DictionaryHome(),
    );
  }
}

class RowEntry {
  final String mien;
  final String partOfSp;
  final String english;
  final String chinese;
  final String thai;
  final String mandarin;
  final String cantonese;
  final String example;
  final String usage;
  final String origin;
  final String searchBlob;

  bool matchesQuery(String qNorm) => searchBlob.contains(qNorm);

  RowEntry({
    required this.mien,
    required this.partOfSp,
    required this.english,
    required this.chinese,
    required this.thai,
    required this.mandarin,
    required this.cantonese,
    required this.example,
    required this.usage,
    required this.origin,
  }) : searchBlob = normalizeForSearch('$mien $english $chinese $thai');

  static String _s(dynamic v) => (v ?? '').toString().trim();

  factory RowEntry.fromJson(Map<String, dynamic> json) {
    return RowEntry(
      mien: _s(json['Mien']),
      partOfSp: _s(json['Part of Sp']),
      english: _s(json['English']),
      chinese: _s(json['Chinese']),
      thai: _s(json['Thai']),
      mandarin: _s(json['Mandarin']),
      cantonese: _s(json['Cantonese']),
      example: _s(json['Example']),
      usage: _s(json['Usage']),
      origin: _s(json['Origin']),
    );
  }

  bool matches(String q) {
    final query = q.toLowerCase();
    return mien.toLowerCase().contains(query) ||
        partOfSp.toLowerCase().contains(query) ||
        english.toLowerCase().contains(query) ||
        chinese.toLowerCase().contains(query) ||
        thai.toLowerCase().contains(query) ||
        mandarin.toLowerCase().contains(query) ||
        cantonese.toLowerCase().contains(query) ||
        example.toLowerCase().contains(query) ||
        usage.toLowerCase().contains(query) ||
        origin.toLowerCase().contains(query);
  }
}

class DictionaryHome extends StatefulWidget {
  const DictionaryHome({super.key});

  @override
  State<DictionaryHome> createState() => _DictionaryHomeState();
}

class _DictionaryHomeState extends State<DictionaryHome> {
  List<RowEntry> rows = const [];
  String q = '';

  Timer? _debounce;
  String _qNorm = '';
  String _previewMeaning(RowEntry e) {
    String pick(String s) => s.trim();

    final en = pick(e.english);
    final zh = pick(e.chinese);
    final th = pick(e.thai);

    final parts = <String>[];
    if (en.isNotEmpty) parts.add(en);
    if (zh.isNotEmpty) parts.add(zh);
    if (th.isNotEmpty) parts.add(th);

    if (parts.isEmpty)
      return e.partOfSp.trim().isEmpty ? '' : e.partOfSp.trim();

    // Keep it short so the list stays readable
    final joined = parts.join(' • ');
    return joined.length > 80 ? '${joined.substring(0, 80)}…' : joined;
  }

  List<RowEntry> get filtered {
    if (rows.isEmpty) return const [];

    final qn = _qNorm.trim();
    if (qn.isEmpty) return rows;

    return rows.where((r) => r.matchesQuery(qn)).toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString('assets/dictionary.json');
      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        throw const FormatException('dictionary.json must be a JSON array');
      }

      final parsed =
          decoded
              .whereType<Map<String, dynamic>>()
              .map(RowEntry.fromJson)
              .where((e) => e.mien.isNotEmpty)
              .toList()
            ..sort(
              (a, b) => a.mien.toLowerCase().compareTo(b.mien.toLowerCase()),
            );

      if (!mounted) return;
      setState(() => rows = parsed);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load dictionary: $e')));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mien Dictionary'),
        actions: [
          IconButton(
            tooltip: 'Reload',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search (Mien / English / Chinese / Thai / …)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 250), () {
                  setState(() {
                    _qNorm = normalizeForSearch(v);
                  });
                });
              },
            ),
          ),
          Expanded(
            child: rows.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : results.isEmpty
                ? const Center(child: Text('No matches'))
                : ListView.separated(
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final r = results[i];
                      return ListTile(
                        title: Text(r.mien),
                        subtitle: Text(_previewMeaning(r)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => RowDetail(row: r)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class RowDetail extends StatelessWidget {
  final RowEntry row;
  const RowDetail({super.key, required this.row});

  Widget _kv(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = row;

    return Scaffold(
      appBar: AppBar(title: Text(e.mien)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Meaning =====
              Text(
                'Meaning',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              _kv('English', e.english),
              _kv('Chinese', e.chinese),
              _kv('Thai', e.thai),

              const SizedBox(height: 16),

              // ===== Details =====
              Text(
                'Details',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              _kv('Part of Sp', e.partOfSp),
              _kv('Example', e.example),
              _kv('Usage', e.usage),
              _kv('Origin', e.origin),
            ],
          ),
        ),
      ),
    );
  }
}
