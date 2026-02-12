// lib/main.dart
//
// ✅ Keeps your previous app structure (speech_to_text + audioplayers + url_launcher + feedback button)
// ✅ Keeps your JSON structure + flexible header reading
//
// FIXES you asked for:
// 1) NO pre-list before typing: empty query => results empty + helper text (no alphabet list)
// 2) Language dropdown freedom like Google Translate:
//    - Input can be any language
//    - Output can be any language EXCEPT same as input
//    - No “only Mien output” restriction
// 3) Search improvements (incremental like Google):
//    - Prefix matches prioritized
//    - Contains matches allowed
//    - Ranked results update per keystroke
// 4) Audio behavior predictable (your rules):
//    - INPUT-side speaker: only if Input = Mien AND selected has audio (shown under selected word)
//    - OUTPUT-side speaker: only if Output = Mien AND selected has audio
//    - Uses audioplayers AssetSource with robust path normalization for values like:
//        "00001.wav", "audio/00001.wav", "assets/audio/00001.wav"
//
// IMPORTANT:
// - Your pubspec.yaml assets must include:
//     - assets/data/
//     - assets/audio/
// - Your audio files are .wav and stored under assets/audio/
// - Your active JSON file:
///    assets/data/mien_dictionary_feb8.json

import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart';

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

enum Lang { mien, english, chinese, thai, french, lao, vietnamese }

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
      case Lang.french:
        return 'French';
      case Lang.lao:
        return 'Lao';
      case Lang.vietnamese:
        return 'Vietnamese';
    }
  }
}

class DictEntry {
  final String id;

  final String mien;
  final String english;
  final String chinese;
  final String thai;
  final String french;
  final String lao;
  final String vietnamese;

  final String noteEnglish;
  final String noteFrench;
  final String noteThai;
  final String noteLao;
  final String noteVietnamese;
  final String noteChinese;

  final String mandarin;
  final String cantonese;

  final String example;
  final String usage;
  final String origin;

  // audio filename like "00001.wav" (stored under assets/audio/)
  final String audioMien;

  // optional (older datasets)
  final String pos;

  const DictEntry({
    required this.id,
    required this.mien,
    required this.english,
    required this.chinese,
    required this.thai,
    required this.french,
    required this.lao,
    required this.vietnamese,
    required this.noteEnglish,
    required this.noteFrench,
    required this.noteThai,
    required this.noteLao,
    required this.noteVietnamese,
    required this.noteChinese,
    required this.mandarin,
    required this.cantonese,
    required this.example,
    required this.usage,
    required this.origin,
    required this.audioMien,
    required this.pos,
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
      case Lang.french:
        return french;
      case Lang.lao:
        return lao;
      case Lang.vietnamese:
        return vietnamese;
    }
  }

  String noteFor(Lang lang) {
    switch (lang) {
      case Lang.english:
        return noteEnglish;
      case Lang.french:
        return noteFrench;
      case Lang.thai:
        return noteThai;
      case Lang.lao:
        return noteLao;
      case Lang.vietnamese:
        return noteVietnamese;
      case Lang.chinese:
        return noteChinese;
      case Lang.mien:
        return '';
    }
  }

  bool get hasMienAudio => audioMien.trim().isNotEmpty;
}

class DictionaryHomePage extends StatefulWidget {
  const DictionaryHomePage({super.key});

  @override
  State<DictionaryHomePage> createState() => _DictionaryHomePageState();
}

class _DictionaryHomePageState extends State<DictionaryHomePage> {
  // =========================
  // CONFIG
  // =========================
  static const String kDictAssetPath = 'assets/data/mien_dictionary_feb8.json';

  // ========= FEEDBACK (Google Form) =========
  static const String kFeedbackPrefillBaseUrl =
      'PASTE_YOUR_GOOGLE_FORM_PREFILL_URL_HERE';

  // Audio player (assets/audio/<filename>)
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Languages (Google-Translate-style freedom: all languages allowed except same-language pairing)
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

  // IMPORTANT: session token to ignore late onResult callbacks
  int _listenSession = 0;

  @override
  void initState() {
    super.initState();
    _queryCtrl.addListener(_applyFilter);
    _queryCtrl.addListener(() => setState(() {}));
    _enforceDifferentLanguages();
    _loadJson();
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    _queryFocus.dispose();
    _stt.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  // -------------------------
  // Google-Translate-style language freedom
  // -------------------------
  List<Lang> get _allLangs => Lang.values;

  List<Lang> _allowedOutputsFor(Lang input) {
    // allow everything except same-language pairing
    return _allLangs.where((l) => l != input).toList();
  }

  void _enforceDifferentLanguages() {
    if (_outputLang == _inputLang) {
      final allowed = _allowedOutputsFor(_inputLang);
      _outputLang = allowed.isEmpty ? _outputLang : allowed.first;
    }
  }

  // -------------------------
  // Swap box
  // -------------------------
  void _swapLanguages() {
    setState(() {
      final oldInput = _inputLang;
      final oldOutput = _outputLang;
      _inputLang = oldOutput;
      _outputLang = oldInput;
      _enforceDifferentLanguages();
      _applyFilter();
    });
  }

  Widget _swapBox(ColorScheme cs) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: IconButton(
        tooltip: 'Swap input/output',
        iconSize: 28,
        icon: const Icon(Icons.swap_horiz),
        onPressed: _swapLanguages,
      ),
    );
  }

  // -------------------------
  // Matching cleanup
  // -------------------------
  String _cleanForMatch(String s, {required Lang lang}) {
    var t = s;
    t = t.replaceAll(RegExp(r'[\uFEFF\u200B\u200C\u200D]'), '');
    t = t.replaceAll('\u00A0', ' ');
    t = t.replaceFirst(RegExp(r"^\s*'"), '');
    t = t.trim();
    t = t.replaceAll(RegExp(r'\s+'), ' ');
    // keep your old rule: only lower-case for English + Mien
    if (lang == Lang.english || lang == Lang.mien) t = t.toLowerCase();
    return t;
  }

  // -------------------------
  // Search: prefix prioritized, contains allowed, ranked
  // -------------------------
  int _scoreTerm(String term, String q) {
    // Exact > startsWith > word-boundary contains > contains
    if (term == q) return 5000;
    if (term.startsWith(q))
      return 3500 + (800 - _cap(term.length)); // shorter terms bubble up
    if (_wordBoundaryContains(term, q)) return 2000;
    if (term.contains(q)) return 1200;

    // Optional: ignore spaces/underscores for compound consistency
    final t2 = term.replaceAll(RegExp(r'[\s_]+'), '');
    final q2 = q.replaceAll(RegExp(r'[\s_]+'), '');
    if (t2 == q2) return 2600;
    if (t2.startsWith(q2)) return 1600;
    if (t2.contains(q2)) return 1100;

    return 0;
  }

  bool _wordBoundaryContains(String term, String q) {
    final pattern = RegExp(
      r'(^|[^a-z0-9])' + RegExp.escape(q),
      caseSensitive: false,
    );
    return pattern.hasMatch(term);
  }

  int _cap(int v) => v > 800 ? 800 : v;

  void _applyFilter() {
    if (_loading) return;

    final q = _cleanForMatch(_queryCtrl.text, lang: _inputLang);

    // ✅ No pre-list before typing
    if (q.isEmpty) {
      setState(() {
        _results = const [];
        _selected = null;
      });
      return;
    }

    final scored = <_ScoredEntry>[];

    for (final e in _entries) {
      final term = _cleanForMatch(e.inLang(_inputLang), lang: _inputLang);
      if (term.isEmpty) continue;

      final score = _scoreTerm(term, q);
      if (score > 0) scored.add(_ScoredEntry(e, score, term));
    }

    scored.sort((a, b) {
      final s = b.score.compareTo(a.score);
      if (s != 0) return s;

      // shorter wins, then alpha
      final len = a.term.length.compareTo(b.term.length);
      if (len != 0) return len;

      return a.term.compareTo(b.term);
    });

    final matches = scored.map((x) => x.entry).take(400).toList();

    setState(() {
      _results = matches;
      _selected = matches.isEmpty ? null : matches.first;
    });
  }

  // -------------------------
  // JSON loading/parsing
  // -------------------------
  Future<void> _loadJson() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final jsonText = await rootBundle.loadString(kDictAssetPath);
      final decoded = jsonDecode(jsonText);

      if (decoded is! List) {
        throw Exception(
          'JSON root must be a List. Got: ${decoded.runtimeType}',
        );
      }

      String getStr(Map<String, dynamic> m, List<String> keys) {
        final lower = {for (final e in m.entries) e.key.toLowerCase(): e.value};
        for (final k in keys) {
          final v = lower[k.toLowerCase()];
          if (v != null) {
            final t = v.toString().trim();
            if (t.isNotEmpty) return t;
          }
        }
        return '';
      }

      int skippedAllEmpty = 0;
      int skippedBadRow = 0;

      final entries = <DictEntry>[];

      for (var i = 0; i < decoded.length; i++) {
        final row = decoded[i];

        if (row is! Map) {
          skippedBadRow++;
          continue;
        }

        final m = row.map((k, v) => MapEntry(k.toString(), v));

        final mien = getStr(m, ['Mien', 'mien']);
        final english = getStr(m, ['English', 'english']);
        final chinese = getStr(m, ['Chinese', 'chinese']);
        final thai = getStr(m, ['Thai', 'thai']);
        final french = getStr(m, ['French', 'french']);
        final lao = getStr(m, ['Lao', 'lao']);
        final vietnamese = getStr(m, ['Vietnamese', 'vietnamese']);

        final noteEnglish = getStr(m, [
          'Note (English)',
          'Note English',
          'note_english',
        ]);
        final noteFrench = getStr(m, [
          'Note (French)',
          'Note French',
          'note_french',
        ]);
        final noteThai = getStr(m, ['Note (Thai)', 'Note Thai', 'note_thai']);
        final noteLao = getStr(m, ['Note (Lao)', 'Note Lao', 'note_lao']);
        final noteVietnamese = getStr(m, [
          'Note (Vietnamese)',
          'Note Vietnamese',
          'note_vietnamese',
        ]);
        final noteChinese = getStr(m, [
          'Note (Chinese)',
          'Note Chinese',
          'note_chinese',
        ]);

        final mandarin = getStr(m, ['Mandarin', 'mandarin']);
        final cantonese = getStr(m, ['Cantonese', 'cantonese']);
        final example = getStr(m, ['Example', 'example']);
        final usage = getStr(m, ['Usage', 'usage']);
        final origin = getStr(m, ['Origin', 'origin']);

        final audioMien = getStr(m, [
          'Audio (Mien)',
          'Audio(Mien)',
          'Audio Mien',
          'audio_mien',
          'audio (mien)',
          'audio',
        ]);

        final pos = getStr(m, [
          'Part of Speech',
          'Part of Sp',
          'Part of sp',
          'Part of Sp.',
          'POS',
          'pos',
        ]);

        if (mien.isEmpty &&
            english.isEmpty &&
            chinese.isEmpty &&
            thai.isEmpty &&
            french.isEmpty &&
            lao.isEmpty &&
            vietnamese.isEmpty) {
          skippedAllEmpty++;
          continue;
        }

        final idSource = '$mien|$english|$pos|$i';
        final id = base64Url.encode(utf8.encode(idSource)).replaceAll('=', '');

        entries.add(
          DictEntry(
            id: id,
            mien: mien,
            english: english,
            chinese: chinese,
            thai: thai,
            french: french,
            lao: lao,
            vietnamese: vietnamese,
            noteEnglish: noteEnglish,
            noteFrench: noteFrench,
            noteThai: noteThai,
            noteLao: noteLao,
            noteVietnamese: noteVietnamese,
            noteChinese: noteChinese,
            mandarin: mandarin,
            cantonese: cantonese,
            example: example,
            usage: usage,
            origin: origin,
            audioMien: audioMien,
            pos: pos,
          ),
        );
      }

      debugPrint('Loaded JSON from: $kDictAssetPath');
      debugPrint('JSON rows total: ${decoded.length}');
      debugPrint('Entries kept: ${entries.length}');
      debugPrint('Skipped (all empty main fields): $skippedAllEmpty');
      debugPrint('Skipped (bad row type): $skippedBadRow');

      setState(() {
        _entries = entries;
        _loading = false;
      });

      _enforceDifferentLanguages();
      _applyFilter();
    } catch (e) {
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  // -------------------------
  // Speech-to-text
  // -------------------------
  String _sttLocaleFor(Lang lang) {
    switch (lang) {
      case Lang.english:
        return 'en_US';
      case Lang.french:
        return 'fr_FR';
      case Lang.lao:
        return 'lo_LA';
      case Lang.chinese:
        return 'zh_CN';
      case Lang.thai:
        return 'th_TH';
      case Lang.vietnamese:
        return 'vi_VN';
      case Lang.mien:
        return 'en_US';
    }
  }

  Future<void> _stopDictationSession({String? status}) async {
    _listenSession++;
    if (_isListening) await _stt.stop();
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

    _listenSession++;
    final mySession = _listenSession;

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
        if (mySession != _listenSession) return;

        final txt = res.recognizedWords.trim();
        if (txt.isEmpty) return;

        // Keep your old “don’t spam with tiny partials”
        if (!res.finalResult && txt.length < 2) return;

        _queryCtrl.text = txt;
        _queryCtrl.selection = TextSelection.collapsed(offset: txt.length);

        if (res.finalResult) setState(() => _isListening = false);
      },
    );
  }

  // -------------------------
  // Audio helpers (WAV + Chrome-safe asset path normalization)
  // -------------------------
  String _normalizeAudioToAssetSourcePath(String raw) {
    // We must end with: "audio/<filename.wav>" for AssetSource()
    var s = raw.trim();
    s = s.replaceAll('\\', '/');
    if (s.isEmpty) return '';

    // Strip accidental prefixes
    if (s.startsWith('assets/'))
      s = s.substring('assets/'.length); // "audio/xxx.wav" or "audio/..."
    if (s.startsWith('audio/')) {
      // ok
      return s;
    }

    // If they stored "assets/audio/xxx.wav" -> after stripping "assets/" becomes "audio/xxx.wav"
    // If they stored only filename -> add "audio/"
    if (!s.contains('/')) {
      return 'audio/$s';
    }

    // If they stored "something/audio/xxx.wav" (rare), try to keep only after last "audio/"
    final idx = s.lastIndexOf('audio/');
    if (idx != -1) {
      return s.substring(idx);
    }

    // Otherwise, assume already relative from assets root
    return s;
  }

  Future<void> _playMienAudioIfAvailable(DictEntry e) async {
    if (!e.hasMienAudio) {
      _toast('No audio for this entry.');
      return;
    }

    final assetPath = _normalizeAudioToAssetSourcePath(e.audioMien);
    if (assetPath.isEmpty) {
      _toast('No audio for this entry.');
      return;
    }

    try {
      // User click => OK for Chrome autoplay policy.
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(assetPath));
    } catch (err) {
      _toast('Audio play failed: $err');
    }
  }

  // -------------------------
  // Feedback helpers
  // -------------------------
  bool get _feedbackConfigured =>
      kFeedbackPrefillBaseUrl.isNotEmpty &&
      !kFeedbackPrefillBaseUrl.contains(
        'PASTE_YOUR_GOOGLE_FORM_PREFILL_URL_HERE',
      );

  String _safeOneLine(String s) =>
      s.replaceAll('\n', ' ').replaceAll('\r', ' ').trim();

  Uri _buildFeedbackUri(DictEntry e) {
    final base = Uri.parse(kFeedbackPrefillBaseUrl);

    final ctx = <String, String>{
      'entryId': e.id,
      'mien': _safeOneLine(e.mien),
      'inputLang': _inputLang.label,
      'outputLang': _outputLang.label,
      'inputText': _safeOneLine(e.inLang(_inputLang)),
      'outputText': _safeOneLine(e.inLang(_outputLang)),
      'pos': _safeOneLine(e.pos),
      'note': _safeOneLine(e.noteFor(_outputLang)),
      'example': _safeOneLine(e.example),
      'usage': _safeOneLine(e.usage),
      'origin': _safeOneLine(e.origin),
      'audioMien': _safeOneLine(e.audioMien),
    };

    final merged = <String, String>{...base.queryParameters, ...ctx};
    return base.replace(queryParameters: merged);
  }

  Future<void> _openFeedbackFormForSelected() async {
    final e = _selected;
    if (e == null) {
      _toast('Select an entry first.');
      return;
    }
    if (!_feedbackConfigured) {
      _toast(
        'Feedback form not configured yet. Paste your prefill URL in main.dart.',
      );
      return;
    }

    final uri = _buildFeedbackUri(e);

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) _toast('Could not open feedback form.');
  }

  // -------------------------
  // UI helpers
  // -------------------------
  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _exampleUsageOriginLines(DictEntry e) {
    final parts = <String>[];

    final note = e.noteFor(_outputLang).trim();
    if (note.isNotEmpty) parts.add('Note: $note');

    if (e.example.trim().isNotEmpty) parts.add('Example: ${e.example.trim()}');
    if (e.usage.trim().isNotEmpty) parts.add('Usage: ${e.usage.trim()}');
    if (e.origin.trim().isNotEmpty) parts.add('Origin: ${e.origin.trim()}');

    return parts.join('\n');
  }

  // -------------------------
  // Build UI
  // -------------------------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            title: const Text('Mien Dictionary'),
            actions: [
              IconButton(
                tooltip: 'Reload JSON',
                onPressed: _loadJson,
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
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                      ],
                    ),
                  )
                : (_loadError != null)
                ? _errorView(cs, _loadError!)
                : LayoutBuilder(
                    builder: (context, c) {
                      final wide = c.maxWidth >= 900;

                      if (wide) {
                        return Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _leftPanel(cs, orientation)),
                              const SizedBox(width: 10),
                              Padding(
                                padding: const EdgeInsets.only(top: 18),
                                child: _swapBox(cs),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: _rightPanel(cs)),
                            ],
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: ListView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.only(bottom: bottomInset + 16),
                          children: [
                            _leftPanel(cs, orientation),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.center,
                              child: _swapBox(cs),
                            ),
                            const SizedBox(height: 10),
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
                'Could not load JSON',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(err, style: TextStyle(color: cs.onSurfaceVariant)),
              const SizedBox(height: 12),
              Text(
                'Check:\n'
                '1) pubspec.yaml includes assets/data/ (or $kDictAssetPath)\n'
                '2) file exists at $kDictAssetPath\n'
                '3) flutter pub get\n'
                '4) JSON root is a List of row objects',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // LEFT PANEL
  Widget _leftPanel(ColorScheme cs, Orientation orientation) {
    final selected = _selected;
    final showInputMienSpeaker =
        (_inputLang == Lang.mien) && (selected?.hasMienAudio ?? false);

    final inputBoxHeight = (orientation == Orientation.landscape)
        ? 360.0
        : 420.0;

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
              items: _allLangs,
              onChanged: (v) {
                setState(() {
                  _inputLang = v;
                  _enforceDifferentLanguages();
                  _applyFilter();
                });
              },
            ),
            const SizedBox(height: 6),
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
            const SizedBox(height: 10),
            SizedBox(
              height: inputBoxHeight,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outlineVariant),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _queryCtrl,
                      focusNode: _queryFocus,
                      decoration: InputDecoration(
                        hintText:
                            'Search ${_inputLang.label} (prefix + contains)…',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        isDense: true,
                        suffixIcon: _queryCtrl.text.trim().isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear',
                                icon: const Icon(Icons.clear),
                                onPressed: _clearSearchAndCancelDictation,
                              ),
                      ),
                    ),
                    if (selected != null) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          selected.inLang(_inputLang).trim().isEmpty
                              ? '—'
                              : selected.inLang(_inputLang).trim(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // ✅ INPUT-side Mien audio: only when Input = Mien AND selected has audio
                      if (showInputMienSpeaker) ...[
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            tooltip: 'Play Mien audio',
                            onPressed: () =>
                                _playMienAudioIfAvailable(selected),
                            icon: Icon(Icons.volume_up, color: cs.primary),
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'Matches: ${_results.length}',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                        const Spacer(),
                        Text(
                          'prefix + contains',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 6),
                    Expanded(child: _buildMatchesList(cs)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesList(ColorScheme cs) {
    final q = _cleanForMatch(_queryCtrl.text, lang: _inputLang);

    if (q.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          'Type/paste (or speak) above.\n\nMatches will appear here.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      );
    }

    if (_results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          'No matches for “$q”.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      );
    }

    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final e = _results[i];
        final isSel = _selected?.id == e.id;

        final inputText = e.inLang(_inputLang);
        final previewMien = e.mien.trim();

        return ListTile(
          dense: true,
          selected: isSel,
          onTap: () => setState(() => _selected = e),
          title: Text(
            inputText.isEmpty ? '—' : inputText,
            style: const TextStyle(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            previewMien.isEmpty ? '—' : previewMien,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }

  // RIGHT PANEL + feedback button
  Widget _rightPanel(ColorScheme cs) {
    final allowed = _allowedOutputsFor(_inputLang);
    final selected = _selected;

    final inputText = selected?.inLang(_inputLang) ?? '';
    final outputText = selected?.inLang(_outputLang) ?? '';

    // ✅ OUTPUT-side Mien audio: only when Output = Mien AND selected has audio
    final showRightSpeaker =
        (_outputLang == Lang.mien) && (selected?.hasMienAudio ?? false);

    final exu = (selected == null) ? '' : _exampleUsageOriginLines(selected);

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
            SizedBox(
              height: 300,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outlineVariant),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: selected == null
                    ? Text(
                        'No selection.\n\nSearch on the left and tap a result.',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      )
                    : SingleChildScrollView(
                        child: Column(
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

                            // Mandarin/Cantonese only when output is Chinese
                            if (_outputLang == Lang.chinese) ...[
                              if (selected.mandarin.trim().isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  'Mandarin: ${selected.mandarin.trim()}',
                                  style: TextStyle(color: cs.onSurfaceVariant),
                                ),
                              ],
                              if (selected.cantonese.trim().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Cantonese: ${selected.cantonese.trim()}',
                                  style: TextStyle(color: cs.onSurfaceVariant),
                                ),
                              ],
                            ],

                            if (showRightSpeaker) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Play Mien audio',
                                    onPressed: () =>
                                        _playMienAudioIfAvailable(selected),
                                    icon: Icon(
                                      Icons.volume_up,
                                      color: cs.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _normalizeAudioToAssetSourcePath(
                                        selected.audioMien,
                                      ),
                                      style: TextStyle(
                                        color: cs.onSurfaceVariant,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),

            // Feedback button
            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: _openFeedbackFormForSelected,
                icon: const Icon(Icons.feedback_outlined),
                label: Text(
                  _feedbackConfigured
                      ? 'Suggest correction'
                      : 'Suggest correction (configure form URL)',
                ),
              ),
            ),

            const SizedBox(height: 10),

            if (selected != null && exu.trim().isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(exu, style: TextStyle(color: cs.onSurfaceVariant)),
              )
            else
              Text(
                selected == null
                    ? 'Note/Example/Usage/Origin will appear here.'
                    : 'No Note/Example/Usage/Origin for this entry.',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
          ],
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
            value: value,
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
}

class _ScoredEntry {
  final DictEntry entry;
  final int score;
  final String term;
  _ScoredEntry(this.entry, this.score, this.term);
}
