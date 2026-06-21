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
//    - INPUT-side Mien audio: show Native button if available
//    - OUTPUT-side Mien audio: show Native button if available
//    - Native audio uses audioplayers AssetSource
//
// MERGED corrections (as requested):
// A) No microphone UI for Mien (desktop mic row disappears; toggle is silently blocked)
// B) Mandarin + Cantonese speaker icons sit next to their lines (same inline placement style)
// C) Mandarin + Cantonese pronunciation speaks CHINESE CHARACTERS ONLY (entry.chinese), not romanized fields
//    - Web/Chrome: uses Web Speech API voice by lang: zh-CN and zh-HK
// D) TTS never pronounces "(Mienh)" (strip parenthetical text for all non-Mien speak paths)
// E) Lao pronunciation temporarily disabled (no Lao voice available on current web devices)
//
// 5) Bottom footer shows contributor + WIP notice (always visible, SafeArea-friendly)
// 6) Header banner at top of page (web-friendly, safe for readability)
// 7) Phone layout matches your mock
//
// IMPORTANT assets:
// - assets/data/
// - assets/audio/Original/
// - assets/ui/
//
// Active JSON file:
//   assets/data/mien_translation_june9.json

import 'dart:convert';
import 'tts_web_helper_stub.dart'
    if (dart.library.js) 'tts_web_helper_web.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_tts/flutter_tts.dart';
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
      title: 'Mien Translate',
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

  // display only (NOT spoken)
  final String mandarin;
  final String cantonese;

  final String example;
  final String exampleMien;
  final String exampleEnglish;
  final String exampleChinese;
  final String exampleThai;
  final String exampleFrench;
  final String exampleLao;
  final String exampleVietnamese;
  final String audioExample;
  final String usage;
  final String origin;

  // Mien audio field
  final String audioOriginal;
  final String audioAI;

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
    required this.exampleMien,
    required this.exampleEnglish,
    required this.exampleChinese,
    required this.exampleThai,
    required this.exampleFrench,
    required this.exampleLao,
    required this.exampleVietnamese,
    required this.audioExample,
    required this.usage,
    required this.origin,
    required this.audioOriginal,
    required this.audioAI,
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

  String exampleFor(Lang lang) {
    switch (lang) {
      case Lang.mien:
        return exampleMien.trim().isNotEmpty ? exampleMien : example;
      case Lang.english:
        return exampleEnglish;
      case Lang.chinese:
        return exampleChinese;
      case Lang.thai:
        return exampleThai;
      case Lang.french:
        return exampleFrench;
      case Lang.lao:
        return exampleLao;
      case Lang.vietnamese:
        return exampleVietnamese;
    }
  }

  bool get hasOriginalAudio => audioOriginal.trim().isNotEmpty;
  bool get hasAiAudio => audioAI.trim().isNotEmpty;
  bool get hasAnyMienAudio => hasOriginalAudio || hasAiAudio;
  bool get hasExampleAudio => audioExample.trim().isNotEmpty;
  bool get hasExample =>
      example.trim().isNotEmpty ||
      exampleMien.trim().isNotEmpty ||
      exampleEnglish.trim().isNotEmpty ||
      exampleChinese.trim().isNotEmpty ||
      exampleThai.trim().isNotEmpty ||
      exampleFrench.trim().isNotEmpty ||
      exampleLao.trim().isNotEmpty ||
      exampleVietnamese.trim().isNotEmpty;
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
      'assets/data/mien_translation_june9.json';

  // Header banner image (put this file at assets/ui/mien_header.jpg)
  static const String kHeaderBannerAsset = 'assets/ui/mien_header.jpg';

  // ========= FEEDBACK (Google Form) =========
  static const String kFeedbackPrefillBaseUrl =
      'https://docs.google.com/forms/d/e/1FAIpQLSeTxlhmNZkZXR6nHarKuuLeBd14E4S9BRvKUU4LCOxJi5mMSg/viewform?usp=header';

  // ========= FOOTER / CREDIT TEXT (screenshot-style box) =========
  static const String kCreditHeadline = 'Mienh waac makes us Mienh';
  static const String kCreditLine1 = 'Developed by: Dr. Kal Phan';
  static const String kCreditLine2 = 'The Center for Mien Advancement';
  static const String kCreditContact = 'phankal@comcast.net';

  // Audio player
  final AudioPlayer _audioPlayer = AudioPlayer();

  // TTS (non-Mien)
  final FlutterTts _tts = FlutterTts();

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

  bool _entryWasSelected = false;

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
    _initTts();
    _loadJson();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setSpeechRate(0.48);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      try {
        await _tts.awaitSpeakCompletion(true);
      } catch (_) {}
    } catch (e) {
      debugPrint('TTS init error: $e');
    }
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    _queryFocus.dispose();
    _stt.stop();
    _audioPlayer.dispose();
    _tts.stop();
    super.dispose();
  }

  // -------------------------
  // Google-Translate-style language freedom
  // -------------------------
  List<Lang> get _allLangs => Lang.values;

  List<Lang> _allowedOutputsFor(Lang input) {
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

      _inputLang = oldOutputLang;
      _outputLang = oldInputLang;

      _enforceDifferentLanguages();

      // Keep the selected entry so translation remains visible
      _entryWasSelected = true;
      _results = const [];

      if (_selected != null) {
        final newInputText = _selected!.inLang(_inputLang).trim();
        _queryCtrl.text = newInputText;
        _queryCtrl.selection = TextSelection.collapsed(
          offset: newInputText.length,
        );
      }
    });
  }

  void _selectEntry(DictEntry e) {
    setState(() {
      _entryWasSelected = true;
      _selected = e;
      _results = const [];

      final selectedText = e.inLang(_inputLang).trim();

      if (selectedText.isNotEmpty) {
        _queryCtrl.text = selectedText;
        _queryCtrl.selection = TextSelection.collapsed(
          offset: selectedText.length,
        );
      }

      _queryFocus.unfocus();
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

    if (lang == Lang.chinese) {
      t = t.replaceAll(RegExp(r'\s+'), '');
    } else {
      t = t.replaceAll(RegExp(r'\s+'), ' ');
    }

    if (lang == Lang.english || lang == Lang.mien) {
      t = t.toLowerCase();
    }

    return t;
  }

  // -------------------------
  // Search: prefix prioritized, contains allowed, ranked
  // -------------------------
  int _scoreTerm(String term, String q) {
    if (term == q) return 5000;
    if (term.startsWith(q)) {
      return 3500 + (800 - _cap(term.length));
    }
    if (_wordBoundaryContains(term, q)) return 2000;
    if (term.contains(q)) return 1200;

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
  int usageRank(String usage) {
    final u = usage.trim().toLowerCase();

    if (u.isEmpty) return 0;
    if (u.contains('literary')) return 1;
    if (u.contains('ritual')) return 2;
    if (u.contains('baby')) return 3;

    return 4;
  }

  void _applyFilter() {
    if (_loading) return;

    final q = _cleanForMatch(_queryCtrl.text, lang: _inputLang);

    if (_entryWasSelected) {
      setState(() {
        _results = const [];
      });
      return;
    }
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

      final ucmp = usageRank(a.entry.usage).compareTo(usageRank(b.entry.usage));
      if (ucmp != 0) return ucmp;

      final outA = a.entry.inLang(_outputLang).toLowerCase();
      final outB = b.entry.inLang(_outputLang).toLowerCase();

      return outA.compareTo(outB);
    });

    final matches = scored.map((x) => x.entry).take(400).toList();

    DictEntry? nextSelected = null;

    setState(() {
      _results = matches;
      _selected = nextSelected;
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

    debugPrint('*** RUNNING march1 BUILD ***');

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
        final exampleMien = getStr(m, [
          'Example (Mien)',
          'Mien (Example)',
          'Example Mien',
          'example_mien',
        ]);
        final exampleEnglish = getStr(m, [
          'Example (English)',
          'English (Example)',
          'Example English',
          'example_english',
        ]);
        final exampleChinese = getStr(m, [
          'Example (Chinese)',
          'Chinse (Example)',
          'Chinse (Example)',
          'Example Chinese',
          'example_chinese',
        ]);
        final exampleThai = getStr(m, [
          'Example (Thai)',
          'Thai (Example)',
          'Example Thai',
          'example_thai',
        ]);
        final exampleFrench = getStr(m, [
          'Example (French)',
          'French (Example)',
          'Example French',
          'example_french',
        ]);
        final exampleLao = getStr(m, [
          'Example (Lao)',
          'Lao (Example)',
          'Example Lao',
          'example_lao',
        ]);
        final exampleVietnamese = getStr(m, [
          'Example (Vietnamese)',
          'Vietnamese (Example)',
          'Example Vietnamese',
          'example_vietnamese',
        ]);
        final audioExample = getStr(m, [
          'AudioExample',
          'Audio Example',
          'audio_example',
        ]);
        final usage = getStr(m, ['Usage', 'usage']);
        final origin = getStr(m, ['Origin', 'origin']);

        final audioOriginal = getStr(m, [
          'AudioOriginal',
          'Audio Original',
          'Audio_Original',
          'audiooriginal',
          'audio_original',
          'OriginalAudio',
          'original_audio',
          'Audio (Original)',
        ]);

        final audioAI = getStr(m, [
          'AudioAI',
          'Audio AI',
          'Audio_AI',
          'audioAI',
          'audioai',
          'audio_ai',
          'AI',
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
            exampleMien: exampleMien,
            exampleEnglish: exampleEnglish,
            exampleChinese: exampleChinese,
            exampleThai: exampleThai,
            exampleFrench: exampleFrench,
            exampleLao: exampleLao,
            exampleVietnamese: exampleVietnamese,
            audioExample: audioExample,
            usage: usage,
            origin: origin,
            audioOriginal: audioOriginal,
            audioAI: audioAI,
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
    if (_inputLang == Lang.mien) return;

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
    setState(() {
      _entryWasSelected = false;
      _selected = null;
      _results = const [];
    });
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

        if (!res.finalResult && txt.length < 2) return;

        _queryCtrl.text = txt;
        _queryCtrl.selection = TextSelection.collapsed(offset: txt.length);

        if (res.finalResult) setState(() => _isListening = false);
      },
    );
  }

  // -------------------------
  // Audio helpers
  // -------------------------
  String _normalizeAudioToAssetSourcePath(String raw) {
    var s = raw.trim();
    s = s.replaceAll('\\', '/');
    if (s.isEmpty) return '';

    if (s.startsWith('assets/')) {
      s = s.substring('assets/'.length);
    }

    if (s.startsWith('audio/')) {
      return s;
    }

    if (s.startsWith('Original/') || s.startsWith('AI/')) {
      return 'audio/$s';
    }

    if (!s.contains('/')) {
      return 'audio/$s';
    }

    final idx = s.lastIndexOf('audio/');
    if (idx != -1) {
      return s.substring(idx);
    }

    return 'audio/$s';
  }

  Future<void> _playSpecificMienAssetAudio(
    String rawPath, {
    required String label,
  }) async {
    if (rawPath.trim().isEmpty) {
      _toast('No $label audio for this entry.');
      return;
    }

    final assetPath = _normalizeAudioToAssetSourcePath(rawPath);
    if (assetPath.isEmpty) {
      _toast('No $label audio for this entry.');
      return;
    }

    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(assetPath));
    } catch (err) {
      _toast('$label audio play failed: $err');
    }
  }

  Future<void> _playOriginalAudio(DictEntry e) async {
    await _playSpecificMienAssetAudio(e.audioOriginal, label: 'Native');
  }

  Future<void> _playAiAudio(DictEntry e) async {
    if (e.audioAI.trim().isEmpty) {
      _toast('No AI audio for this entry.');
      return;
    }

    try {
      String fileName = e.audioAI.trim();
      fileName = fileName.replaceAll('\\', '/');

      if (fileName.startsWith('AI/')) {
        fileName = fileName.substring(3);
      }

      final aiUrl =
          'https://mienadvancement.github.io/Mien-Dictionary/assets/assets/audio/AI/$fileName';

      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(aiUrl));
    } catch (err) {
      _toast('AI audio play failed: $err');
    }
  }

  // -------------------------
  // TTS helpers
  // -------------------------
  String _stripParenthetical(String s) {
    var t = s;
    t = t.replaceAll(RegExp(r'\s*\([^)]*\)\s*'), ' ');
    t = t.replaceAll(RegExp(r'\s*（[^）]*）\s*'), ' ');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t;
  }

  String _jsEscape(String s) {
    return s
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('\n', ' ')
        .replaceAll('\r', ' ');
  }

  String _localeForOutput(Lang lang) {
    switch (lang) {
      case Lang.english:
        return 'en-US';
      case Lang.french:
        return 'fr-FR';
      case Lang.thai:
        return 'th-TH';
      case Lang.lao:
        return 'lo-LA';
      case Lang.vietnamese:
        return 'vi-VN';
      case Lang.chinese:
        return 'zh-CN';
      case Lang.mien:
        return 'en-US';
    }
  }

  Future<bool> _webSpeak(String rawText, {required String lang}) async {
    final text = _stripParenthetical(rawText).trim();
    if (text.isEmpty) {
      _toast('Nothing to speak.');
      return false;
    }

    final jsText = _jsEscape(text);
    final jsLang = _jsEscape(lang);

    final script =
        """
(function(){
  const synth = window.speechSynthesis;
  if (!synth) return 'NO_API';
  const voices = synth.getVoices ? synth.getVoices() : [];
  if (!voices || voices.length === 0) return 'NO_VOICES';

  const v = voices.find(x => (x.lang||'') === '$jsLang')
         || voices.find(x => (x.lang||'').startsWith('$jsLang'));

  const u = new SpeechSynthesisUtterance('$jsText');
  u.lang = '$jsLang';
  if (v) u.voice = v;

  synth.cancel();
  synth.speak(u);
  return v ? ('OK:' + v.lang) : 'OK:NO_MATCH';
})();
""";

    final result = webEval(script).toString();
    if (result == 'NO_API') {
      _toast('Browser TTS not supported.');
      return false;
    }
    if (result == 'NO_VOICES') {
      _toast('Chrome reports no TTS voices loaded.');
      return false;
    }
    return result.startsWith('OK:');
  }

  Future<void> _speakMandarinFromChineseChars(DictEntry e) async {
    final chars = e.chinese.trim();
    if (chars.isEmpty) {
      _toast('No Chinese characters to speak.');
      return;
    }

    if (kIsWeb) {
      await _webSpeak(chars, lang: 'zh-CN');
      return;
    }

    try {
      await _tts.stop();
      await _tts.setLanguage('zh-CN');
      await _tts.speak(_stripParenthetical(chars));
    } catch (err) {
      _toast('TTS failed: $err');
    }
  }

  Future<void> _speakCantoneseFromChineseChars(DictEntry e) async {
    final chars = e.chinese.trim();
    if (chars.isEmpty) {
      _toast('No Chinese characters to speak.');
      return;
    }

    if (kIsWeb) {
      await _webSpeak(chars, lang: 'zh-HK');
      return;
    }

    try {
      await _tts.stop();
      await _tts.setLanguage('zh-HK');
      await _tts.speak(_stripParenthetical(chars));
    } catch (err) {
      _toast('TTS failed: $err');
    }
  }

  Future<void> _speakOutputIfNonMien(DictEntry e) async {
    if (_outputLang == Lang.lao) {
      _toast('Lao pronunciation is temporarily disabled.');
      return;
    }

    if (_outputLang == Lang.mien) {
      _toast('Mien uses recorded audio.');
      return;
    }

    if (_outputLang == Lang.chinese) {
      await _speakMandarinFromChineseChars(e);
      return;
    }

    final raw = e.inLang(_outputLang);
    final cleaned = _stripParenthetical(raw).trim();
    if (cleaned.isEmpty) {
      _toast('Nothing to speak.');
      return;
    }

    final locale = _localeForOutput(_outputLang);
    if (kIsWeb) {
      await _webSpeak(cleaned, lang: locale);
      return;
    }

    try {
      await _tts.stop();
      await _tts.setLanguage(locale);
      await _tts.speak(cleaned);
    } catch (err) {
      _toast('TTS failed: $err');
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
      'audioOriginal': _safeOneLine(e.audioOriginal),
      'audioExample': _safeOneLine(e.audioExample),
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

    final uri = _selected == null
        ? Uri.parse(kFeedbackPrefillBaseUrl)
        : _buildFeedbackUri(_selected!);

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) _toast('Could not open feedback form.');
  }

  Future<void> _openContactEmail() async {
    final subject = Uri.encodeComponent('Mien Translate Contact');
    final body = Uri.encodeComponent('Please write your message here:');
    final uri = Uri.parse('mailto:$kCreditContact?subject=$subject&body=$body');

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) _toast('Could not open email application.');
  }

  // -------------------------
  // UI helpers
  // -------------------------
  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _entryTextWithPos(DictEntry e, Lang lang) {
    final text = e.inLang(lang).trim();
    final pos = e.pos.trim();
    if (text.isEmpty) return '';
    if (lang == Lang.mien && pos.isNotEmpty) return '$text ($pos)';
    return text;
  }

  Widget _entryTextWithPosRich(
    DictEntry e,
    Lang lang, {
    double fontSize = 18,
    FontWeight wordWeight = FontWeight.w700,
  }) {
    final text = e.inLang(lang).trim();
    final pos = e.pos.trim();

    if (text.isEmpty) {
      return const Text('—');
    }

    final showPos = lang == Lang.mien && pos.isNotEmpty;

    return RichText(
      text: TextSpan(
        style: const TextStyle(decoration: TextDecoration.none),
        children: [
          TextSpan(
            text: text,
            style: TextStyle(
              decoration: TextDecoration.none,
              fontSize: fontSize,
              fontWeight: wordWeight,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (showPos)
            TextSpan(
              text: ' ($pos)',
              style: TextStyle(
                decoration: TextDecoration.none,
                fontSize: fontSize - 1,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  String _exampleUsageOriginLines(DictEntry e) {
    final parts = <String>[];

    final note = e.noteFor(_outputLang).trim();
    if (note.isNotEmpty) parts.add('Note: $note');

    if (e.usage.trim().isNotEmpty) parts.add('Usage: ${e.usage.trim()}');
    if (e.origin.trim().isNotEmpty) parts.add('Origin: ${e.origin.trim()}');

    return parts.join('\n');
  }

  Lang _exampleTranslationLang() {
    if (_outputLang != Lang.mien) return _outputLang;
    if (_inputLang != Lang.mien) return _inputLang;
    return Lang.english;
  }

  Future<void> _playExampleAudio(DictEntry e) async {
    await _playSpecificMienAssetAudio(e.audioExample, label: 'Example');
  }

  Future<void> _speakExampleTranslation(DictEntry e, Lang lang) async {
    final raw = e.exampleFor(lang).trim();
    if (raw.isEmpty) {
      _toast('No ${lang.label} example to speak.');
      return;
    }

    if (lang == Lang.mien) {
      if (e.hasExampleAudio) {
        await _playExampleAudio(e);
      } else {
        _toast('No Mien example audio for this entry.');
      }
      return;
    }

    if (lang == Lang.lao) {
      _toast('Lao pronunciation is temporarily disabled.');
      return;
    }

    if (lang == Lang.chinese) {
      final chars = e.exampleChinese.trim();
      if (chars.isEmpty) {
        _toast('No Chinese example to speak.');
        return;
      }
      if (kIsWeb) {
        await _webSpeak(chars, lang: 'zh-CN');
        return;
      }
      try {
        await _tts.stop();
        await _tts.setLanguage('zh-CN');
        await _tts.speak(_stripParenthetical(chars));
      } catch (err) {
        _toast('TTS failed: $err');
      }
      return;
    }

    final cleaned = _stripParenthetical(raw).trim();
    final locale = _localeForOutput(lang);
    if (kIsWeb) {
      await _webSpeak(cleaned, lang: locale);
      return;
    }

    try {
      await _tts.stop();
      await _tts.setLanguage(locale);
      await _tts.speak(cleaned);
    } catch (err) {
      _toast('TTS failed: $err');
    }
  }

  Future<void> _showExampleDialog(DictEntry e) async {
    final cs = Theme.of(context).colorScheme;
    final mienExample = e.exampleFor(Lang.mien).trim();
    final translationLang = _exampleTranslationLang();
    final translatedExample = e.exampleFor(translationLang).trim();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Example'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mien:',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          mienExample.isEmpty ? '—' : mienExample,
                          style: const TextStyle(fontSize: 16, height: 1.35),
                        ),
                      ),
                      if (e.hasExampleAudio)
                        IconButton(
                          tooltip: 'Play Mien example',
                          onPressed: () => _playExampleAudio(e),
                          icon: Icon(Icons.volume_up, color: cs.primary),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '${translationLang.label}:',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          translatedExample.isEmpty ? '—' : translatedExample,
                          style: const TextStyle(fontSize: 16, height: 1.35),
                        ),
                      ),
                      if (translatedExample.isNotEmpty &&
                          translationLang != Lang.lao)
                        IconButton(
                          tooltip: 'Speak ${translationLang.label} example',
                          onPressed: () =>
                              _speakExampleTranslation(e, translationLang),
                          icon: Icon(Icons.volume_up, color: cs.primary),
                        ),
                    ],
                  ),
                  if (translationLang == Lang.lao &&
                      translatedExample.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Lao pronunciation coming soon.',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  final bool enableAiAudio = true;

  Widget _mienAudioButtons(
    DictEntry selected,
    ColorScheme cs, {
    bool compact = false,
  }) {
    if (!selected.hasAnyMienAudio && !selected.hasExample) {
      return const SizedBox.shrink();
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        if (selected.hasOriginalAudio)
          OutlinedButton.icon(
            style: compact
                ? OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  )
                : null,
            onPressed: () => _playOriginalAudio(selected),
            icon: Icon(Icons.volume_up, color: cs.primary),
            label: const Text('Native'),
          ),

        if (enableAiAudio && selected.hasAiAudio)
          OutlinedButton.icon(
            style: compact
                ? OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  )
                : null,
            onPressed: () => _playAiAudio(selected),
            icon: Icon(Icons.smart_toy, color: cs.primary),
            label: const Text('AI'),
          ),

        if (selected.hasExample)
          OutlinedButton.icon(
            style: compact
                ? OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  )
                : null,
            onPressed: () => _showExampleDialog(selected),
            icon: Icon(Icons.article_outlined, color: cs.primary),
            label: const Text('Example'),
          ),
      ],
    );
  }

  // -------------------------
  // Header banner (top of page)
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
                Container(color: Colors.black.withOpacity(0.12)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // PHONE LAYOUT
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
          Expanded(
            child: DropdownButtonFormField<Lang>(
              isExpanded: true,
              initialValue: _inputLang,
              items: _allLangs
                  .map((l) => DropdownMenuItem(value: l, child: Text(l.label)))
                  .toList(),
              onChanged: (v) async {
                if (v == null) return;
                if (_isListening && v == Lang.mien) {
                  await _stopDictationSession(status: 'stopped');
                }
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
              icon: const Icon(Icons.swap_horiz),
              onPressed: _swapLanguages,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonFormField<Lang>(
              isExpanded: true,
              initialValue: _outputLang,
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
            onChanged: (_) {
              _entryWasSelected = false;
            },
            decoration: InputDecoration(
              hintText: 'Enter Text',
              border: const UnderlineInputBorder(),
              isDense: true,
              suffixIcon: _queryCtrl.text.trim().isNotEmpty
                  ? IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearchAndCancelDictation,
                    )
                  : (_inputLang == Lang.mien
                        ? null
                        : IconButton(
                            tooltip: _isListening
                                ? 'Stop dictation'
                                : 'Speak to search',
                            icon: Icon(
                              _isListening ? Icons.stop_circle : Icons.mic,
                            ),
                            onPressed: _toggleDictation,
                          )),
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
        if (!_entryWasSelected) ...[
          const SizedBox(height: 10),
          _mobileWordOptionsPanel(cs),
        ],
      ],
    );
  }

  Widget _mobileOutputPanel(ColorScheme cs) {
    final selected = _selected;

    final outputText = selected?.inLang(_outputLang).trim() ?? '';
    final showMienAudioOptions =
        (_outputLang == Lang.mien) &&
        ((selected?.hasAnyMienAudio ?? false) ||
            (selected?.hasExample ?? false));

    final exu = (selected == null) ? '' : _exampleUsageOriginLines(selected);
    final showExu = selected != null && exu.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _outputLang.label,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 8,
            children: [
              (selected == null || outputText.isEmpty)
                  ? const Text(
                      '—',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : _entryTextWithPosRich(
                      selected,
                      _outputLang,
                      fontSize: 18,
                      wordWeight: FontWeight.w700,
                    ),

              if (selected != null && showMienAudioOptions)
                _mienAudioButtons(selected, cs, compact: true),

              if (selected != null &&
                  _outputLang != Lang.mien &&
                  _outputLang != Lang.lao)
                IconButton(
                  tooltip: 'Speak',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _speakOutputIfNonMien(selected),
                  icon: Icon(Icons.volume_up, color: cs.primary),
                ),

              if (selected != null &&
                  selected.hasExample &&
                  !showMienAudioOptions)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  onPressed: () => _showExampleDialog(selected),
                  icon: Icon(Icons.article_outlined, color: cs.primary),
                  label: const Text('Example'),
                ),
            ],
          ),

          if (selected != null && _outputLang == Lang.lao) ...[
            const SizedBox(height: 6),
            Text(
              'Lao pronunciation coming soon.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],

          if (selected != null &&
              _outputLang != Lang.mien &&
              selected.pos.trim().isNotEmpty) ...[
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

          if (selected != null && _outputLang == Lang.chinese) ...[
            if (selected.mandarin.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  Text(
                    'Mandarin: ${selected.mandarin.trim()}',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  IconButton(
                    tooltip: 'Speak Mandarin (Chinese characters)',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _speakMandarinFromChineseChars(selected),
                    icon: Icon(Icons.volume_up, color: cs.primary),
                  ),
                ],
              ),
            ],
            if (selected.cantonese.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  Text(
                    'Cantonese: ${selected.cantonese.trim()}',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  IconButton(
                    tooltip: 'Speak Cantonese (Chinese characters)',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _speakCantoneseFromChineseChars(selected),
                    icon: Icon(Icons.volume_up, color: cs.primary),
                  ),
                ],
              ),
            ],
          ] else ...[
            if (showExu) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  exu,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
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
        mainAxisSize: MainAxisSize.min,
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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Input Language',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Output Language',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          if (!hasList)
            const SizedBox.shrink()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final e = _results[i];
                final isSel = _selected?.id == e.id;

                final inputText = _entryTextWithPos(e, _inputLang);
                final usage = e.usage.trim();
                final outputBase = _entryTextWithPos(e, _outputLang);
                final outputText = usage.isEmpty
                    ? outputBase
                    : '$outputBase [$usage]';

                return InkWell(
                  onTap: () => _selectEntry(e),
                  child: Container(
                    color: isSel
                        ? cs.primaryContainer.withOpacity(0.45)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            inputText.isEmpty ? '—' : inputText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSel ? cs.primary : cs.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            outputText.isEmpty ? '—' : outputText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
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

    final kbOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    final showFeedbackGlobal =
        !kbOpen && (_queryCtrl.text.trim().isEmpty || _selected != null);

    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            title: const Center(
              child: Text(
                'Mien Translate',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'About',
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Mien Translate',
                    applicationVersion: 'March 7 Edition',
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
          bottomNavigationBar: kbOpen
              ? const SizedBox.shrink()
              : const ContributorFooter(
                  headline: kCreditHeadline,
                  line1: kCreditLine1,
                  line2: kCreditLine2,
                ),
          bottomSheet: showFeedbackGlobal
              ? SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: PopupMenuButton<String>(
                        tooltip: 'Feedback, Suggestion, and Contact',
                        onSelected: (value) {
                          if (value == 'feedback') {
                            _openFeedbackFormForSelected();
                          } else if (value == 'contact') {
                            _openContactEmail();
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem<String>(
                            value: 'feedback',
                            child: Text('Feedback and Suggestion'),
                          ),
                          PopupMenuItem<String>(
                            value: 'contact',
                            child: Text('Contact'),
                          ),
                        ],
                        child: Container(
                          width: double.infinity,
                          height: 46,
                          decoration: BoxDecoration(
                            border: Border.all(),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.feedback_outlined),
                              SizedBox(width: 8),
                              Text('Feedback, Suggestion, and Contact'),
                            ],
                          ),
                        ),
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
    final showInputMienAudioOptions =
        (_inputLang == Lang.mien) &&
        ((selected?.hasAnyMienAudio ?? false) ||
            (selected?.hasExample ?? false));

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
              onChanged: (v) async {
                if (_isListening && v == Lang.mien) {
                  await _stopDictationSession(status: 'stopped');
                }
                setState(() {
                  _inputLang = v;
                  _enforceDifferentLanguages();
                  _applyFilter();
                });
              },
            ),
            const SizedBox(height: 6),

            if (_inputLang != Lang.mien)
              Row(
                children: [
                  IconButton(
                    tooltip: _isListening
                        ? 'Stop dictation'
                        : 'Speak to search',
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

            if (_inputLang != Lang.mien) const SizedBox(height: 10),

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
                      onChanged: (_) {
                        _entryWasSelected = false;
                      },
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
                              : _entryTextWithPos(selected, _inputLang),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (showInputMienAudioOptions) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _mienAudioButtons(selected, cs),
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

        final inputText = _entryTextWithPos(e, _inputLang);

        final subtitleText = _entryTextWithPos(e, _outputLang);

        return ListTile(
          dense: true,
          selected: isSel,
          onTap: () => _selectEntry(e),
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

  // RIGHT PANEL (desktop)
  Widget _rightPanel(ColorScheme cs) {
    final allowed = _allowedOutputsFor(_inputLang);
    final selected = _selected;

    final outputText = selected?.inLang(_outputLang) ?? '';
    final showRightMienAudioOptions =
        (_outputLang == Lang.mien) &&
        ((selected?.hasAnyMienAudio ?? false) ||
            (selected?.hasExample ?? false));

    final exu = (selected == null)
        ? ''
        : _exampleUsageOriginLines(selected).trim();
    final showExu = selected != null && exu.isNotEmpty;

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
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 8,
                        children: [
                          Text(
                            (selected == null || outputText.trim().isEmpty)
                                ? '—'
                                : _entryTextWithPos(selected, _outputLang),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (selected != null && showRightMienAudioOptions)
                            _mienAudioButtons(selected, cs, compact: true),
                          if (selected != null &&
                              _outputLang != Lang.mien &&
                              _outputLang != Lang.lao)
                            IconButton(
                              tooltip: 'Speak',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _speakOutputIfNonMien(selected),
                              icon: Icon(Icons.volume_up, color: cs.primary),
                            ),
                          if (selected != null &&
                              selected.hasExample &&
                              !showRightMienAudioOptions)
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                              ),
                              onPressed: () => _showExampleDialog(selected),
                              icon: Icon(
                                Icons.article_outlined,
                                color: cs.primary,
                              ),
                              label: const Text('Example'),
                            ),
                        ],
                      ),

                      if (selected != null && _outputLang == Lang.lao) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Lao pronunciation coming soon.',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],

                      const SizedBox(height: 10),

                      if (selected != null &&
                          _outputLang != Lang.mien &&
                          selected.pos.trim().isNotEmpty)
                        Text(
                          selected.pos,
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),

                      if (selected != null && _outputLang == Lang.chinese) ...[
                        if (selected.mandarin.trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            children: [
                              Text(
                                'Mandarin: ${selected.mandarin.trim()}',
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
                              IconButton(
                                tooltip: 'Speak Mandarin (Chinese characters)',
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () =>
                                    _speakMandarinFromChineseChars(selected),
                                icon: Icon(Icons.volume_up, color: cs.primary),
                              ),
                            ],
                          ),
                        ],
                        if (selected.cantonese.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            children: [
                              Text(
                                'Cantonese: ${selected.cantonese.trim()}',
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
                              IconButton(
                                tooltip: 'Speak Cantonese (Chinese characters)',
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () =>
                                    _speakCantoneseFromChineseChars(selected),
                                icon: Icon(Icons.volume_up, color: cs.primary),
                              ),
                            ],
                          ),
                        ],
                      ],

                      if (showExu) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            exu,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
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
            isExpanded: true,
            menuMaxHeight: MediaQuery.of(context).size.height * 0.55,
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

class ContributorFooter extends StatelessWidget {
  final String headline;
  final String line1;
  final String line2;

  const ContributorFooter({
    super.key,
    required this.headline,
    required this.line1,
    required this.line2,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      elevation: 2,
      color: cs.surface,
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: cs.outlineVariant)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                headline,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                line1,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              Text(
                line2,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
