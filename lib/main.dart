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
// NEW:
// 5) Bottom footer shows contributor + WIP notice (always visible, SafeArea-friendly)
// 6) Header banner at top of page (web-friendly, safe for readability)
// 7) ✅ Phone layout redone to match your mock:
//    - Top teal bar with Input dropdown + swap + Output dropdown (same row)
//    - Input section with small label + underline field
//    - Output panel with match word + speaker (NO filename), POS, notes/examples/usage or Mandarin/Cantonese
//    - Word options panel below output panel
//    - Desktop stays side-by-side panels
//
// IMPORTANT:
// - Your pubspec.yaml assets must include:
//     - assets/data/
//     - assets/audio/
//     - assets/ui/
// - Your audio files are .wav and stored under assets/audio/
// - Your active JSON file:
//     assets/data/mien_translation_feb23.json

import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart';

void main() {
  debugPrint('RUNNING NEW MOCK BUILD');
  runApp(const MienDictionaryApp());
}

class MienDictionaryApp extends StatelessWidget {
  const MienDictionaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Faan Mienh Waac (Mien Translation)',
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
  static const String kDictAssetPath =
      'assets/data/mien_translation_feb23.json';

  // Header banner image (put this file at assets/ui/mien_header.jpg)
  static const String kHeaderBannerAsset = 'assets/ui/mien_header.jpg';

  // ========= FEEDBACK (Google Form) =========
  static const String kFeedbackPrefillBaseUrl =
      'https://docs.google.com/forms/d/e/1FAIpQLSeTxlhmNZkZXR6nHarKuuLeBd14E4S9BRvKUU4LCOxJi5mMSg/viewform?usp=header';

  // ========= FOOTER TEXT =========
  static const String kFooterLine1 =
      'Work in progress • Audio and entries still being improved';
  static const String kFooterLine2 =
      'Contributors: Dr. Kal Phan • The Center for Mien Advancement';

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
      final oldInputLang = _inputLang;
      final oldOutputLang = _outputLang;

      final oldSelected = _selected;

      _inputLang = oldOutputLang;
      _outputLang = oldInputLang;

      _enforceDifferentLanguages();

      // ✅ Move previous translation into the search box
      if (oldSelected != null) {
        final reversedText = oldSelected.inLang(_inputLang).trim();
        _queryCtrl.text = reversedText;
        _queryCtrl.selection = TextSelection.collapsed(
          offset: reversedText.length,
        );
      }

      // ✅ Clear selection to prevent mismatched UI state
      _selected = null;

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
        icon: Icon(
          MediaQuery.of(context).size.width < 900
              ? Icons.swap_vert
              : Icons.swap_horiz,
        ),
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
    if (term.startsWith(q)) {
      return 3500 + (800 - _cap(term.length)); // shorter terms bubble up
    }
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

    debugPrint('*** RUNNING FEB23 BUILD ***');

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
          'Audio', // your current JSON uses "Audio"
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
    if (s.startsWith('assets/')) {
      s = s.substring('assets/'.length); // "audio/xxx.wav" or "audio/..."
    }
    if (s.startsWith('audio/')) {
      // ok
      return s;
    }

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
      kFeedbackPrefillBaseUrl.trim().startsWith('https://');
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
    if (!_feedbackConfigured) {
      _toast(
        'Feedback form not configured yet. Paste your responder link in main.dart.',
      );
      return;
    }

    final uri = Uri.parse(kFeedbackPrefillBaseUrl);
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
  // Header banner (top of page) - responsive height (phone safe, desktop stable)
  // -------------------------
  Widget _headerBanner(ColorScheme cs) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final h = (w * 0.22).clamp(78.0, 140.0);

          return SizedBox(
            height: h,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  kHeaderBannerAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    // If the image is missing, show a clean fallback instead of crashing.
                    return Container(
                      color: cs.surfaceContainerHighest,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'Mien Online Dictionary',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                    );
                  },
                ),
                // subtle overlay for readability
                Container(color: Colors.black.withOpacity(0.12)),
              ],
            ),
          );
        },
      ),
    );
  }

  // -------------------------
  // Footer (bottom of page)
  // -------------------------
  Widget _footer(ColorScheme cs) {
    return SizedBox(
      height: 96,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            kHeaderBannerAsset, // assets/ui/mien_header.jpg
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: cs.surfaceContainerHighest),
          ),

          // Dark overlay improves text readability
          Container(color: Colors.black.withOpacity(0.35)),

          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                '$kFooterLine1\n$kFooterLine2',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PHONE LAYOUT (matches your mock)
  // Top bar: Input dropdown + swap + Output dropdown
  // Input section: small label + underline field
  // Output panel: small label + match word + speaker (NO filename) + POS + notes or Mandarin/Cantonese
  // Word options: selectable list
  // ============================================================
  Widget _mobileMockLayout(ColorScheme cs) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 12, 12, bottomInset > 0 ? 8 : 12),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                _mobileTopBar(cs),
                const SizedBox(height: 10),
                _mobileInputSection(cs),
                const SizedBox(height: 12),

                _mobileOutputAndOptions(cs),

                // ✅ extra bottom space so last options aren’t hidden by global bottomSheet button
                const SizedBox(height: 70),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileTopBar(ColorScheme cs) {
    final allowedOutputs = _allowedOutputsFor(_inputLang);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          // Input dropdown shows the ACTUAL selected language name
          Expanded(
            child: DropdownButtonFormField<Lang>(
              isExpanded: true,
              value: _inputLang,
              items: _allLangs
                  .map((l) => DropdownMenuItem(value: l, child: Text(l.label)))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _inputLang = v;
                  _enforceDifferentLanguages();
                  _applyFilter();
                });
              },
              decoration: InputDecoration(
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Swap button (force horizontal icon)
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              border: Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              tooltip: 'Swap input/output',
              iconSize: 28,
              icon: const Icon(Icons.swap_horiz), // ✅ always horizontal
              onPressed: _swapLanguages,
            ),
          ),

          const SizedBox(width: 10),

          // Output dropdown shows the ACTUAL selected language name
          Expanded(
            child: DropdownButtonFormField<Lang>(
              isExpanded: true,
              value: _outputLang,
              items: allowedOutputs
                  .map((l) => DropdownMenuItem(value: l, child: Text(l.label)))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _outputLang = v);
              },
              decoration: InputDecoration(
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileInputSection(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _inputLang.label,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _queryCtrl,
            focusNode: _queryFocus,
            decoration: InputDecoration(
              hintText: 'Enter Text',
              border: const UnderlineInputBorder(),
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
        ],
      ),
    );
  }

  Widget _mobileOutputAndOptions(ColorScheme cs) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _mobileOutputPanel(cs),
        const SizedBox(height: 10),
        _mobileWordOptionsPanel(cs),
      ],
    );
  }

  Widget _mobileOutputPanel(ColorScheme cs) {
    final selected = _selected;

    final outputText = selected?.inLang(_outputLang).trim() ?? '';
    final showSpeaker =
        (_outputLang == Lang.mien) && (selected?.hasMienAudio ?? false);
    final exu = (selected == null) ? '' : _exampleUsageOriginLines(selected);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: selected == null
          ? Text(
              'No selection.\n\nType above and pick a word option below.',
              style: TextStyle(color: cs.onSurfaceVariant),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _outputLang.label,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 6),

                // Match word + speaker (NO filename)
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6, // ✅ "a few spaces" after the word
                  children: [
                    Text(
                      outputText.isEmpty ? '—' : outputText,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (showSpeaker)
                      IconButton(
                        tooltip: 'Play Mien audio',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _playMienAudioIfAvailable(selected),
                        icon: Icon(Icons.volume_up, color: cs.primary),
                      ),
                  ],
                ),

                if (selected.pos.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    selected.pos.trim(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],

                // Chinese extra lines only if output is Chinese
                if (_outputLang == Lang.chinese) ...[
                  if (selected.mandarin.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
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
                ] else ...[
                  if (exu.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(exu, style: TextStyle(color: cs.onSurfaceVariant)),
                  ],
                ],
              ],
            ),
    );
  }

  Widget _mobileWordOptionsPanel(ColorScheme cs) {
    final q = _cleanForMatch(_queryCtrl.text, lang: _inputLang);

    final hasList = q.isNotEmpty && _results.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // ✅ critical
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Word options',
            style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface),
          ),
          const SizedBox(height: 6),
          Text(
            q.isEmpty
                ? 'Type above to see options.'
                : (_results.isEmpty
                      ? 'No matches for “$q”.'
                      : 'Tap a word to select.'),
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // ✅ NO Expanded. Show list only when needed.
          if (!hasList)
            const SizedBox.shrink()
          else
            ListView.separated(
              shrinkWrap: true, // ✅ critical
              physics: const NeverScrollableScrollPhysics(), // ✅ critical
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final e = _results[i];
                final isSel = _selected?.id == e.id;

                final title = e.inLang(_inputLang).trim();
                final subtitle = (_inputLang == Lang.mien)
                    ? e.inLang(_outputLang).trim()
                    : e.mien.trim();

                return ListTile(
                  dense: true,
                  selected: isSel,
                  onTap: () => setState(() => _selected = e),
                  title: Text(
                    title.isEmpty ? '—' : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSel ? cs.primary : cs.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    subtitle.isEmpty ? '—' : subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // -------------------------
  // Build UI
  // -------------------------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // ✅ Global keyboard-open detector for footer + global feedback button
    final kbOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    // ✅ Show feedback only when keyboard closed AND either no query yet OR a selection exists
    final showFeedbackGlobal =
        !kbOpen && (_queryCtrl.text.trim().isEmpty || _selected != null);

    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            title: const Text('Faan Mienh Waac (Mien Translation)'),
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
              IconButton(
                tooltip: 'About',
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Faan Mienh Waac (Mien Translation)',
                    applicationVersion: 'Feb 23 Edition',
                    children: const [
                      SizedBox(height: 12),
                      Text(
                        'Developed by Dr. Kal Phan\n'
                        'The Center for Mien Advancement\n\n'
                        'This is a community Mien language development '
                        'and preservation project.',
                      ),
                    ],
                  );
                },
              ),
            ],
          ),

          // ✅ Footer always visible at bottom (and hidden when keyboard is open)
          bottomNavigationBar: kbOpen ? const SizedBox.shrink() : _footer(cs),

          // ✅ ONE global feedback button system (mobile + desktop), hidden when keyboard is open
          bottomSheet: showFeedbackGlobal
              ? SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: _openFeedbackFormForSelected,
                        icon: const Icon(Icons.feedback_outlined),
                        label: const Text('Feedback and Suggestion'),
                      ),
                    ),
                  ),
                )
              : null,

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

                      // Desktop/web: your original two-panel layout
                      if (wide) {
                        return Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              _headerBanner(cs),
                              const SizedBox(height: 12),
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _leftPanel(cs, orientation),
                                    ),
                                    const SizedBox(width: 10),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 18),
                                      child: _swapBox(cs),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(child: _rightPanel(cs)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Phone: mock-style layout
                      return _mobileMockLayout(cs);
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

  // LEFT PANEL (desktop)
  Widget _leftPanel(ColorScheme cs, Orientation orientation) {
    final selected = _selected;
    final showInputMienSpeaker =
        (_inputLang == Lang.mien) && (selected?.hasMienAudio ?? false);

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
            Expanded(
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

        // decide what to show on the second line (subtitle)
        final subtitleText = (_inputLang == Lang.mien)
            ? e.inLang(_outputLang).trim()
            : e.mien.trim();

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
            subtitleText.isEmpty ? '—' : subtitleText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }

  // RIGHT PANEL (desktop) - audio button shows, NO filename shown
  Widget _rightPanel(ColorScheme cs) {
    final allowed = _allowedOutputsFor(_inputLang);
    final selected = _selected;

    final outputText = selected?.inLang(_outputLang) ?? '';

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
            Expanded(
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
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    outputText.isEmpty ? '—' : outputText,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (showRightSpeaker)
                                  IconButton(
                                    tooltip: 'Play Mien audio',
                                    onPressed: () =>
                                        _playMienAudioIfAvailable(selected),
                                    icon: Icon(
                                      Icons.volume_up,
                                      color: cs.primary,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (selected.pos.trim().isNotEmpty)
                              Text(
                                selected.pos,
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
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
                          ],
                        ),
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

  // Dropdown row (FIX: no hidden options / better web behavior)
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
            isExpanded: true,
            menuMaxHeight: MediaQuery.of(context).size.height * 0.55,
            value: value, // controlled
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
                vertical: 8,
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
