// lib/main.dart
//
// Mien Dictionary (CSV-driven) with:
// - Google-Translate-style TWO PANEL layout
// - startsWith-only matching (input language only)
// - clear "X" in search box (like Google)
// - speech-to-search mic button (dictation fills search box)
// - speaker icon shown ONLY when Mien is on that side:
//      * LEFT speaker only when Input=Mien
//      * RIGHT speaker only when Output=Mien
// - Mandarin/Cantonese shown ONLY when Output=Chinese
//
// Requires pubspec.yaml:
// flutter:
//   uses-material-design: true
//   assets:
//     - assets/words.csv
//
// Add dependency in pubspec.yaml:
// dependencies:
//   speech_to_text: ^7.3.0
//
// Then run: flutter pub get

import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() => runApp(const MienDictionaryApp());

class MienDictionaryApp extends StatelessWidget {
  const MienDictionaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mien Dictionary',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: const DictionaryHomePage(),
    );
  }
}

enum Lang { mien, english, chinese, thai }

extension LangLabel on Lang {
  String get label {
    switch (this) {
      case Lang.mien:
        return 'Mien';
      case Lang.english:
        return 'English';
      case Lang.chinese:
        return 'Chinese';
      case Lang.thai:
        return 'Thai';
    }
  }
}

class DictEntry {
  final String id;

  final String mien;
  final String pos;
  final String english;
  final String chinese;
  final String thai;

  final String mandarin;
  final String cantonese;
  final String example;
  final String usage;
  final String origin;

  const DictEntry({
    required this.id,
    required this.mien,
    required this.pos,
    required this.english,
    required this.chinese,
    required this.thai,
    required this.mandarin,
    required this.cantonese,
    required this.example,
    required this.usage,
    required this.origin,
  });

  String inLang(Lang lang) {
    switch (lang) {
      case Lang.mien:
        return mien;
      case Lang.english:
        return english;
      case Lang.chinese:
        return chinese;
      case Lang.thai:
        return thai;
    }
  }
}

class DictionaryHomePage extends StatefulWidget {
  const DictionaryHomePage({super.key});

  @override
  State<DictionaryHomePage> createState() => _DictionaryHomePageState();
}

class _DictionaryHomePageState extends State<DictionaryHomePage> {
  // Languages
  Lang _inputLang = Lang.english;
  Lang _outputLang = Lang.mien;

  // Search box
  final TextEditingController _queryCtrl = TextEditingController();
  final FocusNode _queryFocus = FocusNode();

  // Data
  bool _loading = true;
  String? _loadError;
  List<DictEntry> _entries = const [];
  List<DictEntry> _results = const [];
  DictEntry? _selected;

  // Speech-to-text
  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _isListening = false;
  String? _sttStatus;

  // IMPORTANT: session token to ignore late onResult callbacks (Chrome can deliver late)
  int _listenSession = 0;

  @override
  void initState() {
    super.initState();

    // filter results when text changes
    _queryCtrl.addListener(_applyFilter);

    // refresh UI so the clear "X" appears/disappears immediately
    _queryCtrl.addListener(() => setState(() {}));

    _enforceOutputRules();
    _loadCsv();
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    _queryFocus.dispose();
    _stt.stop();
    super.dispose();
  }

  // -------------------------
  // Output language rules (your requirement)
  // -------------------------
  List<Lang> _allowedOutputsFor(Lang input) {
    // If input is Mien -> output can be English/Chinese/Thai
    // If input is English/Chinese/Thai -> output can only be Mien
    if (input == Lang.mien) {
      return const [Lang.english, Lang.chinese, Lang.thai];
    }
    return const [Lang.mien];
  }

  void _enforceOutputRules() {
    final allowed = _allowedOutputsFor(_inputLang);
    if (!allowed.contains(_outputLang)) {
      _outputLang = allowed.first;
    }
  }

  // -------------------------
  // Excel/Clipboard cleanup (important for paste matching)
  // -------------------------
  String _cleanForMatch(String s, {required Lang lang}) {
    var t = s;

    // Remove BOM/zero-width chars from Excel/clipboard
    t = t.replaceAll(RegExp(r'[\uFEFF\u200B\u200C\u200D]'), '');

    // NBSP -> normal space
    t = t.replaceAll('\u00A0', ' ');

    // Remove leading apostrophe Excel sometimes adds
    t = t.replaceFirst(RegExp(r"^\s*'"), '');

    // Trim and collapse whitespace/newlines
    t = t.trim();
    t = t.replaceAll(RegExp(r'\s+'), ' ');

    // Case-fold for English and Mien romanization
    if (lang == Lang.english || lang == Lang.mien) {
      t = t.toLowerCase();
    }

    return t;
  }

  // -------------------------
  // startsWith-only search (your requirement)
  // -------------------------
  void _applyFilter() {
    if (_loading) return;

    final q = _cleanForMatch(_queryCtrl.text, lang: _inputLang);
    if (q.isEmpty) {
      setState(() {
        _results = const [];
        _selected = null;
      });
      return;
    }

    final matches =
        _entries.where((e) {
          final term = _cleanForMatch(e.inLang(_inputLang), lang: _inputLang);
          return term.startsWith(q);
        }).toList()..sort((a, b) {
          final at = _cleanForMatch(a.inLang(_inputLang), lang: _inputLang);
          final bt = _cleanForMatch(b.inLang(_inputLang), lang: _inputLang);
          final lenCmp = at.length.compareTo(bt.length);
          return lenCmp != 0 ? lenCmp : at.compareTo(bt);
        });

    setState(() {
      _results = matches;
      _selected = matches.isEmpty ? null : matches.first;
    });
  }

  // -------------------------
  // CSV loading/parsing
  // Header:
  // Mien,Part of Speech,English,Chinese,Thai,Mandarin,Cantonese,Example,Usage,Origin
  // -------------------------
  Future<void> _loadCsv() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final csvText = await rootBundle.loadString('assets/words.csv');
      final rows = _parseCsv(csvText);

      if (rows.isEmpty) throw Exception('CSV file is empty.');
      final header = rows.first.map((c) => c.trim()).toList();

      final index = <String, int>{};
      for (var i = 0; i < header.length; i++) {
        index[header[i]] = i;
      }

      String cell(List<String> r, String col) {
        final i = index[col];
        if (i == null || i < 0 || i >= r.length) return '';
        return r[i];
      }

      final entries = <DictEntry>[];
      for (var ri = 1; ri < rows.length; ri++) {
        final r = rows[ri];
        if (r.every((c) => c.trim().isEmpty)) continue;

        final mien = cell(r, 'Mien').trim();
        final pos = cell(r, 'Part of Speech').trim();
        final english = cell(r, 'English').trim();
        final chinese = cell(r, 'Chinese').trim();
        final thai = cell(r, 'Thai').trim();

        final mandarin = cell(r, 'Mandarin').trim();
        final cantonese = cell(r, 'Cantonese').trim();
        final example = cell(r, 'Example').trim();
        final usage = cell(r, 'Usage').trim();
        final origin = cell(r, 'Origin').trim();

        if (mien.isEmpty &&
            english.isEmpty &&
            chinese.isEmpty &&
            thai.isEmpty) {
          continue;
        }

        final idSource = '$mien|$english|$pos|$ri';
        final id = base64Url.encode(utf8.encode(idSource)).replaceAll('=', '');

        entries.add(
          DictEntry(
            id: id,
            mien: mien,
            pos: pos,
            english: english,
            chinese: chinese,
            thai: thai,
            mandarin: mandarin,
            cantonese: cantonese,
            example: example,
            usage: usage,
            origin: origin,
          ),
        );
      }

      setState(() {
        _entries = entries;
        _loading = false;
      });

      _enforceOutputRules();
      _applyFilter();
    } catch (e) {
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  /// Robust CSV parser:
  /// - supports commas
  /// - supports quoted fields with commas/newlines
  /// - supports escaped quotes ("")
  List<List<String>> _parseCsv(String input) {
    final rows = <List<String>>[];
    final row = <String>[];
    final field = StringBuffer();

    var inQuotes = false;

    for (var i = 0; i < input.length; i++) {
      final ch = input[i];

      if (ch == '"') {
        if (inQuotes) {
          final nextIsQuote = (i + 1 < input.length) && input[i + 1] == '"';
          if (nextIsQuote) {
            field.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          inQuotes = true;
        }
        continue;
      }

      if (!inQuotes && ch == ',') {
        row.add(field.toString());
        field.clear();
        continue;
      }

      if (!inQuotes && (ch == '\n' || ch == '\r')) {
        if (ch == '\r' && i + 1 < input.length && input[i + 1] == '\n') {
          i++;
        }
        row.add(field.toString());
        field.clear();

        if (row.any((c) => c.isNotEmpty)) {
          rows.add(List<String>.from(row));
        }
        row.clear();
        continue;
      }

      field.write(ch);
    }

    row.add(field.toString());
    if (row.any((c) => c.isNotEmpty)) {
      rows.add(List<String>.from(row));
    }

    return rows;
  }

  // -------------------------
  // Speech-to-text (mic -> fills search box)
  // -------------------------
  String _sttLocaleFor(Lang lang) {
    switch (lang) {
      case Lang.english:
        return 'en_US';
      case Lang.chinese:
        return 'zh_CN';
      case Lang.thai:
        return 'th_TH';
      case Lang.mien:
        // Mien STT is usually not supported; use English to capture romanized letters.
        return 'en_US';
    }
  }

  Future<void> _stopDictationSession({String? status}) async {
    _listenSession++; // invalidate any late callbacks
    if (_isListening) {
      await _stt.stop();
    }
    if (!mounted) return;
    setState(() {
      _isListening = false;
      _sttStatus = status ?? 'stopped';
    });
  }

  Future<void> _clearSearchAndCancelDictation() async {
    await _stopDictationSession(status: 'cleared');
    _queryCtrl.clear();
    _queryFocus.requestFocus();
  }

  Future<void> _toggleDictation() async {
    if (_isListening) {
      await _stopDictationSession(status: 'stopped');
      return;
    }

    final available = await _stt.initialize(
      onStatus: (s) => setState(() => _sttStatus = s),
      onError: (e) => _toast('Speech error: ${e.errorMsg}'),
    );

    if (!available) {
      _toast('Speech recognition not available on this device/browser.');
      return;
    }

    final localeId = _sttLocaleFor(_inputLang);

    // New session token for this listen call
    _listenSession++;
    final mySession = _listenSession;

    // Clear at start so old word never "sticks"
    _queryCtrl.clear();
    _queryFocus.requestFocus();

    setState(() {
      _isListening = true;
      _sttStatus = 'listening';
    });

    await _stt.listen(
      localeId: localeId,
      partialResults: true,
      listenMode: stt.ListenMode.search,
      onResult: (res) {
        // Ignore late results from previous sessions (e.g., after pressing X)
        if (mySession != _listenSession) return;

        final txt = res.recognizedWords.trim();
        if (txt.isEmpty) return;

        // Optional: ignore very short junk partials (helps with "tia." style noise)
        if (!res.finalResult && txt.length < 3) return;

        // CHROME-FRIENDLY: update textbox on partial results too
        _queryCtrl.text = txt;
        _queryCtrl.selection = TextSelection.collapsed(offset: txt.length);

        // If final, stop listening UI state
        if (res.finalResult) {
          setState(() => _isListening = false);
        }
      },
    );
  }

  // -------------------------
  // UI helpers
  // -------------------------
  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ✅ Mandarin/Cantonese ONLY when output is Chinese
  String _metaLines(DictEntry e) {
    final parts = <String>[];

    // Always allowed (language-neutral metadata)
    if (e.example.trim().isNotEmpty) parts.add('Example: ${e.example.trim()}');
    if (e.usage.trim().isNotEmpty) parts.add('Usage: ${e.usage.trim()}');
    if (e.origin.trim().isNotEmpty) parts.add('Origin: ${e.origin.trim()}');

    // Only when output = Chinese
    if (_outputLang == Lang.chinese) {
      if (e.mandarin.trim().isNotEmpty) {
        parts.add('Mandarin: ${e.mandarin.trim()}');
      }
      if (e.cantonese.trim().isNotEmpty) {
        parts.add('Cantonese: ${e.cantonese.trim()}');
      }
    }

    return parts.join('\n');
  }

  // -------------------------
  // Build UI
  // -------------------------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // ✅ iPhone Safari keyboard/viewport helper
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // ✅ iPhone Safari rotation stability
    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            title: const Text('Mien Dictionary'),
            actions: [
              IconButton(
                tooltip: 'Reload CSV',
                onPressed: _loadCsv,
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: 'Clear search',
                onPressed: _clearSearchAndCancelDictation,
                icon: const Icon(Icons.clear),
              ),
            ],
          ),
          body: SafeArea(
            child: _loading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Loading assets/words.csv…'),
                      ],
                    ),
                  )
                : (_loadError != null)
                ? _errorView(cs, _loadError!)
                : LayoutBuilder(
                    builder: (context, c) {
                      final wide = c.maxWidth >= 900;

                      if (wide) {
                        // Desktop/tablet: keep your original layout
                        final panels = Row(
                          children: [
                            Expanded(child: _leftPanel(cs, orientation)),
                            const SizedBox(width: 12),
                            Expanded(child: _rightPanel(cs)),
                          ],
                        );

                        return Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Expanded(child: panels),
                              const SizedBox(height: 12),
                              _resultsPanel(cs),
                            ],
                          ),
                        );
                      }

                      // ✅ Mobile: single scrollable page
                      // ✅ FIX: Results should appear under the input (not after output)
                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: ListView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.only(bottom: bottomInset + 16),
                          children: [
                            _leftPanel(cs, orientation),
                            const SizedBox(height: 12),

                            // ✅ moved here: results directly under input
                            _resultsPanel(cs),

                            const SizedBox(height: 12),
                            _rightPanel(cs),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  Widget _errorView(ColorScheme cs, String err) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Could not load CSV',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(err, style: TextStyle(color: cs.onSurfaceVariant)),
              const SizedBox(height: 12),
              Text(
                'Check:\n'
                '1) pubspec.yaml includes assets/words.csv\n'
                '2) file exists at assets/words.csv\n'
                '3) run flutter pub get\n'
                '4) CSV saved as UTF-8 (Excel: CSV UTF-8)',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _leftPanel(ColorScheme cs, Orientation orientation) {
    final showLeftSpeaker = _inputLang == Lang.mien; // ONLY when searching Mien

    // ✅ Safari landscape tends to be short; reduce search box height in landscape
    final searchBoxHeight = (orientation == Orientation.landscape)
        ? 120.0
        : 180.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _langRow(
              title: 'Input',
              value: _inputLang,
              items: Lang.values,
              onChanged: (v) {
                setState(() => _inputLang = v);
                _enforceOutputRules();
                _applyFilter();
              },
            ),
            const SizedBox(height: 6),

            // Speak-to-search mic button
            Row(
              children: [
                IconButton(
                  tooltip: _isListening ? 'Stop dictation' : 'Speak to search',
                  onPressed: _toggleDictation,
                  icon: Icon(_isListening ? Icons.stop_circle : Icons.mic),
                ),
                Expanded(
                  child: Text(
                    _isListening
                        ? 'Listening… (speech fills the search box)'
                        : 'Tap mic to speak a search word.',
                    style: TextStyle(color: cs.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_sttStatus != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      _sttStatus!,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Search box (with clear "X" like Google)
            SizedBox(
              height: searchBoxHeight,
              child: TextField(
                controller: _queryCtrl,
                focusNode: _queryFocus,

                // ✅ iPhone Safari: ensure focused field can scroll above keyboard
                scrollPadding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 120,
                ),

                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText:
                      'Type/paste in ${_inputLang.label} (startsWith only)…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  isDense: true,

                  // Clear "X" (also cancels dictation!)
                  suffixIcon: _queryCtrl.text.trim().isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.clear),
                          onPressed: _clearSearchAndCancelDictation,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Bottom row: loaded count + optional LEFT speaker
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Loaded: ${_entries.length} entries • Matching: startsWith only',
                    style: TextStyle(color: cs.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showLeftSpeaker) ...[
                  IconButton(
                    tooltip: kIsWeb
                        ? 'Mien pronunciation (input) — audio later'
                        : 'Mien pronunciation (input) — audio later',
                    onPressed: () => _toast('Audio will be added later.'),
                    icon: Icon(Icons.volume_up, color: cs.primary),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rightPanel(ColorScheme cs) {
    final allowed = _allowedOutputsFor(_inputLang);
    final selected = _selected;

    final inputText = selected?.inLang(_inputLang) ?? '';
    final outputText = selected?.inLang(_outputLang) ?? '';

    final showRightSpeaker =
        _outputLang == Lang.mien; // ONLY when output is Mien
    final meta = (selected == null) ? '' : _metaLines(selected);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _langRow(
              title: 'Output',
              value: _outputLang,
              items: allowed,
              onChanged: (v) => setState(() => _outputLang = v),
            ),
            const SizedBox(height: 10),

            // Output display box (Google style)
            SizedBox(
              height: 240,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outlineVariant),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: selected == null
                    ? Text(
                        'No selection.\n\nType on the left to search.',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inputText.isEmpty ? '—' : inputText,
                            style: TextStyle(
                              fontSize: 14,
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            outputText.isEmpty ? '—' : outputText,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (selected.pos.trim().isNotEmpty)
                            Text(
                              selected.pos,
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          if (meta.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                meta,
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 10),

            // RIGHT speaker only when Output=Mien
            if (showRightSpeaker)
              Row(
                children: [
                  IconButton(
                    tooltip: kIsWeb
                        ? 'Mien pronunciation (output) — audio later'
                        : 'Mien pronunciation (output) — audio later',
                    onPressed: () => _toast('Audio will be added later.'),
                    icon: Icon(Icons.volume_up, color: cs.primary),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Mien pronunciation (output).',
                      style: TextStyle(color: cs.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _resultsPanel(ColorScheme cs) {
    final q = _cleanForMatch(_queryCtrl.text, lang: _inputLang);

    if (q.isEmpty) {
      return _bottomCard(
        cs,
        child: Text(
          'Type/paste (or speak) on the left to search. Results must START WITH your input.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      );
    }

    if (_results.isEmpty) {
      return _bottomCard(
        cs,
        child: Text(
          'No matches for “$q”. (startsWith-only is strict)',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      );
    }

    return _bottomCard(
      cs,
      child: SizedBox(
        height: 240,
        child: ListView.separated(
          // ✅ Helps nested scrolls on mobile Safari
          primary: false,
          itemCount: _results.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final e = _results[i];
            final isSel = _selected?.id == e.id;

            final inputText = e.inLang(_inputLang);
            final outputText = e.inLang(_outputLang);

            return ListTile(
              selected: isSel,
              onTap: () => setState(() => _selected = e),
              title: Text(
                inputText.isEmpty ? '—' : inputText,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${outputText.isEmpty ? '—' : outputText}   •   ${e.pos}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _langRow({
    required String title,
    required Lang value,
    required List<Lang> items,
    required ValueChanged<Lang> onChanged,
  }) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<Lang>(
            initialValue: value,
            items: items
                .map((l) => DropdownMenuItem(value: l, child: Text(l.label)))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              onChanged(v);
            },
            decoration: InputDecoration(
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomCard(ColorScheme cs, {required Widget child}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }
}
