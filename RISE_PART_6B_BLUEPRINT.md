# ============================================================
# RISE — AI ALARM CLOCK
# MASTER BLUEPRINT: PART 6 OF 12  (FILE 2 OF 2)
# Wake Games + Leaderboard + Challenge + Social UI
# ============================================================
# COMMAND TO AI CODING AGENT:
# This is the continuation of Part 6A. Read Part 6A first.
# This file covers: the 5 wake game widgets, leaderboard
# service + UI, sleep challenge service + UI, wallet screen,
# referral screen, and subscription paywall screen.
# ============================================================

## FILE 10: lib/features/wake_games/games/math_game.dart
## PURPOSE: 3 arithmetic questions. Difficulty-scaled.
## Easy: addition/subtraction ≤ 20. Single-digit answers.
## Medium: multiplication ≤ 12×12.
## Hard: multi-step (a × b) − c = ?
## EC-2.6: Wrong answers never dismiss — only correct ones advance.
## EC-3.8: Large font in accessibility mode. No time pressure.

```dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/wake_game_engine.dart';

class MathGameQuestion {
  final String expression;
  final int    answer;
  const MathGameQuestion({required this.expression, required this.answer});
}

class MathGame extends StatefulWidget {
  final GameDifficulty difficulty;
  final bool           accessibilityMode;
  final void Function(bool passed, int timeTakenSeconds, int wrongAnswers)
      onComplete;

  const MathGame({
    super.key,
    required this.difficulty,
    required this.accessibilityMode,
    required this.onComplete,
  });

  @override
  State<MathGame> createState() => _MathGameState();
}

class _MathGameState extends State<MathGame> {
  final _rng       = Random();
  final _ctrl      = TextEditingController();
  late List<MathGameQuestion> _questions;
  int     _questionIdx  = 0;
  int     _wrongAnswers = 0;
  int     _startMs      = 0;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _startMs   = DateTime.now().millisecondsSinceEpoch;
    _questions = List.generate(3, (_) => _generate());
  }

  MathGameQuestion _generate() {
    switch (widget.difficulty) {
      case GameDifficulty.easy:
        if (_rng.nextBool()) {
          final a = _rng.nextInt(10) + 1;
          final b = _rng.nextInt(10) + 1;
          return MathGameQuestion(expression: '$a + $b = ?', answer: a + b);
        } else {
          final a = _rng.nextInt(9) + 10;
          final b = _rng.nextInt(9) + 1;
          return MathGameQuestion(expression: '$a − $b = ?', answer: a - b);
        }
      case GameDifficulty.medium:
        final a = _rng.nextInt(11) + 2;
        final b = _rng.nextInt(11) + 2;
        return MathGameQuestion(expression: '$a × $b = ?', answer: a * b);
      case GameDifficulty.hard:
        final a = _rng.nextInt(10) + 3;
        final b = _rng.nextInt(8)  + 2;
        final c = _rng.nextInt(15) + 1;
        return MathGameQuestion(
            expression: '($a × $b) − $c = ?', answer: a * b - c);
    }
  }

  void _submit() {
    final entered = int.tryParse(_ctrl.text.trim());
    if (entered == null) {
      setState(() => _errorMsg = 'Enter a number.');
      return;
    }
    if (entered != _questions[_questionIdx].answer) {
      // EC-2.6: wrong answer NEVER dismisses the alarm
      _wrongAnswers++;
      HapticFeedback.mediumImpact();
      setState(() { _errorMsg = 'Not quite — try again.'; _ctrl.clear(); });
      return;
    }
    HapticFeedback.lightImpact();
    _ctrl.clear();
    setState(() => _errorMsg = null);
    if (_questionIdx < _questions.length - 1) {
      setState(() => _questionIdx++);
    } else {
      final elapsed =
          ((DateTime.now().millisecondsSinceEpoch - _startMs) / 1000).round();
      widget.onComplete(true, elapsed, _wrongAnswers);
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final q        = _questions[_questionIdx];
    final bigFont  = widget.accessibilityMode ? 44.0 : 52.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Progress dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: 10, height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i <= _questionIdx
                  ? Colors.white : Colors.white.withOpacity(0.25),
            ),
          )),
        ),
        const SizedBox(height: 40),
        Text(q.expression, style: TextStyle(
          color: Colors.white, fontSize: bigFont,
          fontWeight: FontWeight.w300, letterSpacing: 2,
        ), textAlign: TextAlign.center),
        const SizedBox(height: 32),
        SizedBox(
          width: 180,
          child: TextField(
            controller:   _ctrl,
            autofocus:    true,
            textAlign:    TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            style: TextStyle(
              color: Colors.white,
              fontSize: widget.accessibilityMode ? 32.0 : 28.0,
            ),
            decoration: InputDecoration(
              hintText:  'Answer',
              hintStyle: const TextStyle(color: Colors.white38),
              enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white38)),
              focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white)),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        if (_errorMsg != null) ...[
          const SizedBox(height: 12),
          Text(_errorMsg!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
        ],
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          ),
          child: Text('Confirm',
              style: TextStyle(
                  fontSize: widget.accessibilityMode ? 22 : 18)),
        ),
        const SizedBox(height: 20),
        Text('${_questionIdx + 1} of 3',
            style: const TextStyle(color: Colors.white38, fontSize: 13)),
      ],
    );
  }
}
```

---

## FILE 11: lib/features/wake_games/games/memory_grid_game.dart
## PURPOSE: Show a lit pattern for 3 seconds → user recreates it.
## Easy: 3×3 grid, 3 lit cells.
## Medium: 4×4 grid, 5 lit cells.
## Hard: 5×5 grid, 8 lit cells.
## EC-2.6: Incorrect submission shows pattern again — never dismisses.

```dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/wake_game_engine.dart';

class MemoryGridGame extends StatefulWidget {
  final GameDifficulty difficulty;
  final bool           accessibilityMode;
  final void Function(bool, int, int) onComplete;

  const MemoryGridGame({
    super.key,
    required this.difficulty,
    required this.accessibilityMode,
    required this.onComplete,
  });

  @override
  State<MemoryGridGame> createState() => _MemoryGridState();
}

class _MemoryGridState extends State<MemoryGridGame> {
  late int        _size;
  late int        _count;
  late Set<int>   _target;
  Set<int>        _selected     = {};
  bool            _showPattern  = true;
  int             _wrongAnswers = 0;
  final int       _startMs      = DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    switch (widget.difficulty) {
      case GameDifficulty.easy:   _size = 3; _count = 3;
      case GameDifficulty.medium: _size = 4; _count = 5;
      case GameDifficulty.hard:   _size = 5; _count = 8;
    }
    _target = _makePattern();
    _beginShowPhase();
  }

  void _beginShowPhase() {
    setState(() { _showPattern = true; _selected = {}; });
    Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showPattern = false);
    });
  }

  Set<int> _makePattern() {
    final rng = Random();
    final s   = <int>{};
    while (s.length < _count) s.add(rng.nextInt(_size * _size));
    return s;
  }

  void _tap(int idx) {
    if (_showPattern) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (_selected.contains(idx)) {
        _selected.remove(idx);
      } else if (_selected.length < _count) {
        _selected.add(idx);
      }
    });
  }

  void _checkAnswer() {
    if (_selected.length != _count) return;
    if (_selected.containsAll(_target) && _target.containsAll(_selected)) {
      final elapsed =
          ((DateTime.now().millisecondsSinceEpoch - _startMs) / 1000).round();
      widget.onComplete(true, elapsed, _wrongAnswers);
    } else {
      _wrongAnswers++;
      HapticFeedback.mediumImpact();
      _beginShowPhase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tileSize = widget.accessibilityMode ? 70.0 : 56.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _showPattern ? 'Remember the pattern…' : 'Recreate it',
          style: TextStyle(
            color: Colors.white,
            fontSize: widget.accessibilityMode ? 22 : 18,
          ),
        ),
        const SizedBox(height: 28),
        GridView.builder(
          shrinkWrap:       true,
          physics:          const NeverScrollableScrollPhysics(),
          gridDelegate:     SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:   _size,
            crossAxisSpacing: 6,
            mainAxisSpacing:  6,
          ),
          itemCount: _size * _size,
          itemBuilder: (_, i) {
            final isTarget   = _target.contains(i);
            final isSelected = _selected.contains(i);
            final color = _showPattern
                ? (isTarget ? Colors.indigoAccent
                            : Colors.white.withOpacity(0.07))
                : (isSelected ? Colors.white.withOpacity(0.85)
                              : Colors.white.withOpacity(0.07));
            return GestureDetector(
              onTap: () => _tap(i),
              child: AnimatedContainer(
                duration:   const Duration(milliseconds: 150),
                width:      tileSize,
                height:     tileSize,
                decoration: BoxDecoration(
                  color:        color,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        if (!_showPattern) ...[
          Text('${_selected.length} / $_count selected',
              style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 16),
          if (_selected.length == _count)
            ElevatedButton(
              onPressed: _checkAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                    horizontal: 48, vertical: 16),
              ),
              child: const Text("That's it", style: TextStyle(fontSize: 18)),
            ),
        ],
      ],
    );
  }
}
```

---

## FILE 12: lib/features/wake_games/games/word_unscramble_game.dart
## PURPOSE: Tap letter tiles to build the target word.
## Easy: 4-letter words. Medium: 6-letter. Hard: 8-letter.
## EC-3.8: Large tiles, tap-to-place (no fine motor drag required).
## EC-2.6: Wrong submission reshuffles tiles — never dismisses.

```dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/wake_game_engine.dart';

class WordUnscrambleGame extends StatefulWidget {
  final GameDifficulty difficulty;
  final bool           accessibilityMode;
  final void Function(bool, int, int) onComplete;

  const WordUnscrambleGame({
    super.key,
    required this.difficulty,
    required this.accessibilityMode,
    required this.onComplete,
  });

  @override
  State<WordUnscrambleGame> createState() => _WordUnscrambleState();
}

class _WordUnscrambleState extends State<WordUnscrambleGame> {
  static const _easy   = ['JUMP', 'RISE', 'WAKE', 'DAWN', 'MOVE', 'STEP'];
  static const _medium = ['AWAKEN', 'BRIGHT', 'ENERGY', 'ACTIVE', 'MORTAL'];
  static const _hard   = ['ACHIEVE', 'SUNRISE', 'VIBRANT', 'MORNING', 'HEALTHY'];

  late String       _word;
  late List<String> _pool;    // Shuffled tiles; '' = already placed
  late List<String> _answer;  // User's placed letters
  int               _wrong    = 0;
  final int         _startMs  = DateTime.now().millisecondsSinceEpoch;
  String?           _error;

  @override
  void initState() {
    super.initState();
    final bank = switch (widget.difficulty) {
      GameDifficulty.easy   => _easy,
      GameDifficulty.medium => _medium,
      GameDifficulty.hard   => _hard,
    };
    _word   = bank[Random().nextInt(bank.length)];
    _pool   = List.from(_word.split(''))..shuffle();
    _answer = List.filled(_word.length, '');
  }

  void _place(int poolIdx) {
    final slot = _answer.indexWhere((s) => s.isEmpty);
    if (slot == -1) return;
    HapticFeedback.selectionClick();
    setState(() {
      _answer[slot]   = _pool[poolIdx];
      _pool[poolIdx]  = '';
    });
  }

  void _remove(int answerIdx) {
    if (_answer[answerIdx].isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      final letter = _answer[answerIdx];
      final empty  = _pool.indexWhere((s) => s.isEmpty);
      if (empty != -1) _pool[empty] = letter;
      _answer[answerIdx] = '';
    });
  }

  void _submit() {
    final composed = _answer.join();
    if (composed.contains('')) return;
    if (composed == _word) {
      final elapsed =
          ((DateTime.now().millisecondsSinceEpoch - _startMs) / 1000).round();
      widget.onComplete(true, elapsed, _wrong);
    } else {
      _wrong++;
      HapticFeedback.mediumImpact();
      setState(() {
        _pool   = List.from(_word.split(''))..shuffle();
        _answer = List.filled(_word.length, '');
        _error  = 'Not quite — try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tileW  = widget.accessibilityMode ? 58.0 : 46.0;
    final tileH  = widget.accessibilityMode ? 58.0 : 46.0;
    final font   = widget.accessibilityMode ? 22.0 : 18.0;
    final filled = !_answer.contains('');

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Unscramble the word',
            style: TextStyle(color: Colors.white54, fontSize: 14)),
        const SizedBox(height: 28),

        // Answer slots — tap to remove
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_word.length, (i) => GestureDetector(
            onTap: () => _remove(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              margin:   const EdgeInsets.symmetric(horizontal: 3),
              width: tileW, height: tileH,
              decoration: BoxDecoration(
                color:        _answer[i].isNotEmpty
                    ? Colors.white : Colors.transparent,
                border:       Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(_answer[i],
                    style: TextStyle(
                        color: Colors.black, fontSize: font,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          )),
        ),

        const SizedBox(height: 36),

        // Tile pool — tap to place
        Wrap(
          spacing: 6, runSpacing: 6,
          alignment: WrapAlignment.center,
          children: List.generate(_pool.length, (i) {
            if (_pool[i].isEmpty) return const SizedBox.shrink();
            return GestureDetector(
              onTap: () => _place(i),
              child: Container(
                width: tileW, height: tileH,
                decoration: BoxDecoration(
                  color:        Colors.indigo.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(_pool[i],
                      style: TextStyle(color: Colors.white,
                          fontSize: font, fontWeight: FontWeight.w700)),
                ),
              ),
            );
          }),
        ),

        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.redAccent)),
        ],

        const SizedBox(height: 28),
        if (filled)
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            ),
            child: Text("That's the word",
                style: TextStyle(
                    fontSize: widget.accessibilityMode ? 20 : 16)),
          ),
      ],
    );
  }
}
```

---

## FILE 13: lib/features/wake_games/games/sequence_tap_game.dart
## PURPOSE: EC-3.11 cognitive accessibility. Tap 5 large buttons 1→5.
## TTS announces each next number. No wrong-answer penalty.
## No timer, no failure state — always completable.

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

class SequenceTapGame extends StatefulWidget {
  final void Function(bool, int, int) onComplete;
  const SequenceTapGame({super.key, required this.onComplete});

  @override
  State<SequenceTapGame> createState() => _SequenceTapState();
}

class _SequenceTapState extends State<SequenceTapGame> {
  int          _nextExpected = 1;
  List<bool>   _done         = List.filled(5, false);
  final int    _startMs      = DateTime.now().millisecondsSinceEpoch;
  final _tts   = FlutterTts();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 600), () {
      _tts.speak('Tap 1, then 2, then 3, then 4, then 5.');
    });
  }

  void _tap(int n) {
    if (n != _nextExpected) {
      HapticFeedback.lightImpact();
      return; // Silent — no penalty, no error message
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _done[n - 1] = true;
      _nextExpected++;
    });
    if (_nextExpected > 5) {
      final elapsed =
          ((DateTime.now().millisecondsSinceEpoch - _startMs) / 1000).round();
      Future.delayed(const Duration(milliseconds: 400), () {
        widget.onComplete(true, elapsed, 0);
      });
    } else {
      _tts.speak('$_nextExpected');
    }
  }

  @override
  void dispose() { _tts.stop(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Tap in order',
            style: TextStyle(color: Colors.white, fontSize: 26,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text('1  →  2  →  3  →  4  →  5',
            style: TextStyle(color: Colors.white54, fontSize: 16,
                letterSpacing: 4)),
        const SizedBox(height: 48),
        Wrap(
          spacing: 16, runSpacing: 16,
          alignment: WrapAlignment.center,
          children: List.generate(5, (i) {
            final n      = i + 1;
            final done   = _done[i];
            final isNext = n == _nextExpected;
            return GestureDetector(
              onTap: () => _tap(n),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 96, height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? Colors.greenAccent.withOpacity(0.85)
                      : isNext
                          ? Colors.white
                          : Colors.white.withOpacity(0.12),
                  border: isNext && !done
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                ),
                child: Center(
                  child: Text('$n',
                      style: TextStyle(
                        color:      done || isNext ? Colors.black : Colors.white54,
                        fontSize:   38,
                        fontWeight: FontWeight.w700,
                      )),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
```

---

## FILE 14: lib/features/wake_games/games/barcode_scan_game.dart
## PURPOSE: Scan a pre-registered barcode (set up at alarm creation).
## Forces user to get out of bed and walk to the barcode location.
## EC-2.6: Camera view only — random taps cannot dismiss.
## EC-3.8: Accessibility mode skips this game (engine never selects it).

```dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScanGame extends StatefulWidget {
  final String targetBarcode;    // Pre-registered code from alarm setup
  final void Function(bool, int, int) onComplete;

  const BarcodeScanGame({
    super.key,
    required this.targetBarcode,
    required this.onComplete,
  });

  @override
  State<BarcodeScanGame> createState() => _BarcodeScanState();
}

class _BarcodeScanState extends State<BarcodeScanGame> {
  final _controller = MobileScannerController();
  bool  _detected   = false;
  bool  _wrongScan  = false;
  final int _startMs = DateTime.now().millisecondsSinceEpoch;

  void _onDetect(BarcodeCapture capture) {
    if (_detected) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null) return;

    if (code == widget.targetBarcode) {
      _detected = true;
      final elapsed =
          ((DateTime.now().millisecondsSinceEpoch - _startMs) / 1000).round();
      _controller.stop();
      widget.onComplete(true, elapsed, _wrongScan ? 1 : 0);
    } else {
      // Wrong barcode scanned — show message but keep scanning
      setState(() => _wrongScan = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _wrongScan = false);
      });
    }
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect:   _onDetect,
        ),
        // Overlay frame + instruction
        Positioned.fill(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 220, height: 220,
                decoration: BoxDecoration(
                  border:       Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  _wrongScan
                      ? 'Wrong item — scan the correct one.'
                      : 'Scan your registered item to dismiss.',
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

---

## FILE 15: lib/features/social/leaderboard_service.dart

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';

class LeaderboardEntry {
  final int    rank;
  final String userId;
  final String displayName;
  final double score;
  final bool   isPrizeEligible;
  final bool   isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.score,
    required this.isPrizeEligible,
    this.isCurrentUser = false,
  });
}

/// Prize amounts scale with Pro user count.
/// Server stores current tier in Firestore /app_config/prizes.
class LeaderboardPrizes {
  final int first;
  final int second;
  final int third;
  const LeaderboardPrizes(
      {required this.first, required this.second, required this.third});
  static const baseline = LeaderboardPrizes(
      first: 10000, second: 7000, third: 5000);
}

class LeaderboardService {
  static final LeaderboardService _i = LeaderboardService._internal();
  factory LeaderboardService() => _i;
  LeaderboardService._internal();

  final _db = FirebaseFirestore.instance;

  // ── Current month's top 100 ──────────────────────────────────────────────
  Future<List<LeaderboardEntry>> getTop100({required String currentUserId}) async {
    final now   = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final snap = await _db
        .collection('leaderboard_monthly')
        .doc(month)
        .collection('entries')
        .orderBy('score', descending: true)
        .limit(100)
        .get();

    return snap.docs.asMap().entries.map((e) {
      final d = e.value.data();
      return LeaderboardEntry(
        rank:            e.key + 1,
        userId:          d['userId'] as String,
        displayName:     d['displayName'] as String,
        score:           (d['score'] as num).toDouble(),
        isPrizeEligible: d['isPrizeEligible'] as bool? ?? false,
        isCurrentUser:   d['userId'] == currentUserId,
      );
    }).toList();
  }

  // ── Get current prize pool from server ───────────────────────────────────
  Future<LeaderboardPrizes> getCurrentPrizes() async {
    try {
      final doc = await _db.collection('app_config').doc('prizes').get();
      final d   = doc.data();
      if (d == null) return LeaderboardPrizes.baseline;
      return LeaderboardPrizes(
        first:  d['first']  as int? ?? 10000,
        second: d['second'] as int? ?? 7000,
        third:  d['third']  as int? ?? 5000,
      );
    } catch (_) {
      return LeaderboardPrizes.baseline;
    }
  }

  // ── Find current user's rank (they may not be in top 100) ────────────────
  Future<LeaderboardEntry?> getMyRank(String userId) async {
    final now   = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    try {
      final doc = await _db
          .collection('leaderboard_monthly')
          .doc(month)
          .collection('entries')
          .doc(userId)
          .get();
      if (!doc.exists) return null;
      final d = doc.data()!;
      // Rank requires a count query — use server-side function
      final rankDoc = await _db
          .collection('leaderboard_monthly')
          .doc(month)
          .collection('rank_cache')
          .doc(userId)
          .get();
      final rank = rankDoc.data()?['rank'] as int? ?? 0;
      return LeaderboardEntry(
        rank:            rank,
        userId:          userId,
        displayName:     d['displayName'] as String,
        score:           (d['score'] as num).toDouble(),
        isPrizeEligible: d['isPrizeEligible'] as bool? ?? false,
        isCurrentUser:   true,
      );
    } catch (_) {
      return null;
    }
  }
}
```

---

## FILE 16: lib/features/social/sleep_challenge_service.dart

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/sleep_challenge.dart';

class SleepChallengeService {
  static final SleepChallengeService _i = SleepChallengeService._internal();
  factory SleepChallengeService() => _i;
  SleepChallengeService._internal();

  final _db        = FirebaseFirestore.instance;
  final _functions = FirebaseFunctions.instance;

  // ── Create a challenge (payment held in escrow server-side) ──────────────
  Future<ChallengeCreateResult> createChallenge({
    required String creatorId,
    required String creatorName,
    required int    durationDays,      // 7, 14, or 30
    required int    stakePerPersonCents,
    required String tierId,
  }) async {
    if (stakePerPersonCents < AppConstants.challengeMinStakeCents) {
      return ChallengeCreateResult.stakeTooSmall;
    }
    // Validate stake against tier limit
    final maxStake = _maxStakeForTier(tierId);
    if (stakePerPersonCents > maxStake) {
      return ChallengeCreateResult.stakeExceedsTierLimit;
    }

    try {
      final r = await _functions.httpsCallable('createSleepChallenge').call({
        'creatorId':           creatorId,
        'creatorName':         creatorName,
        'durationDays':        durationDays,
        'stakePerPersonCents': stakePerPersonCents,
      });
      return ChallengeCreateResult.success;
    } catch (_) {
      return ChallengeCreateResult.error;
    }
  }

  // ── Join a challenge by invite code ──────────────────────────────────────
  Future<ChallengeJoinResult> joinChallenge({
    required String challengeId,
    required String userId,
    required String displayName,
    required String tierId,
  }) async {
    try {
      final r = await _functions.httpsCallable('joinSleepChallenge').call({
        'challengeId': challengeId,
        'userId':      userId,
        'displayName': displayName,
      });
      return ChallengeJoinResult.values
          .byName(r.data['result'] as String? ?? 'error');
    } catch (_) {
      return ChallengeJoinResult.error;
    }
  }

  // ── Stream active challenges for a user ──────────────────────────────────
  Stream<List<SleepChallenge>> activeChallengesStream(String userId) {
    return _db
        .collection('sleep_challenges')
        .where('participantIds', arrayContains: userId)
        .where('status', whereIn: ['active', 'pending'])
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => SleepChallenge.fromFirestore(d.data(), d.id))
            .toList());
  }

  // ── Check disqualification for all active challenges ─────────────────────
  // Called daily by background service. If user has 0 sessions for
  // AppConstants.challengeDisqualifyDays consecutive days, they are DQ'd.
  Future<void> runDisqualificationCheck({
    required String userId,
    required List<String> activeChallengeIds,
  }) async {
    if (activeChallengeIds.isEmpty) return;
    try {
      await _functions.httpsCallable('checkChallengeDisqualification').call({
        'userId':       userId,
        'challengeIds': activeChallengeIds,
      });
    } catch (_) {}
  }

  int _maxStakeForTier(String tierId) {
    // Reuse the tier model's limit
    return switch (tierId) {
      AppConstants.tierPro ||
      AppConstants.tierGuardian ||
      AppConstants.tierLifetime => AppConstants.challengeMaxStakeCents,
      _                         => 500, // $5 for Starter/Core
    };
  }
}

enum ChallengeCreateResult {
  success, stakeTooSmall, stakeExceedsTierLimit, error,
}
enum ChallengeJoinResult {
  success, full, alreadyJoined, challengeStarted, error,
}
```

---

## FILE 17: lib/features/social/leaderboard_screen.dart
## PURPOSE: The global leaderboard UI + reward wallet balance display.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/subscription_tier.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/subscription_provider.dart';
import 'leaderboard_service.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  List<LeaderboardEntry>? _entries;
  LeaderboardEntry?       _myEntry;
  LeaderboardPrizes?      _prizes;
  bool                    _loading  = true;
  final _svc = LeaderboardService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = ref.read(authProvider).currentUser?.uid ?? '';
    final results = await Future.wait([
      _svc.getTop100(currentUserId: uid),
      _svc.getMyRank(uid),
      _svc.getCurrentPrizes(),
    ]);
    if (!mounted) return;
    setState(() {
      _entries = results[0] as List<LeaderboardEntry>;
      _myEntry = results[1] as LeaderboardEntry?;
      _prizes  = results[2] as LeaderboardPrizes;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tier = SubscriptionTier.fromId(
        ref.watch(subscriptionProvider).tier);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.white38))
            : CustomScrollView(
                slivers: [
                  _buildHeader(tier),
                  if (_prizes != null) _buildPrizeCards(),
                  if (_myEntry != null) _buildMyRankTile(),
                  _buildEntriesList(),
                ],
              ),
      ),
    );
  }

  SliverToBoxAdapter _buildHeader(SubscriptionTier tier) {
    final now   = DateTime.now();
    final month = _monthName(now.month);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.emoji_events,
                  color: Color(0xFFFFD700), size: 28),
              const SizedBox(width: 10),
              Text('$month Leaderboard',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 22,
                      fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 6),
            Text('Resets on the 1st. Prizes paid on the 3rd.',
                style: TextStyle(color: Colors.white.withOpacity(0.45),
                    fontSize: 12)),
            if (!tier.prizeEligible) ...[
              const SizedBox(height: 12),
              _UpgradeBanner(message:
                'Upgrade to Pro to compete for prizes.'),
            ],
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildPrizeCards() {
    final p = _prizes!;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(children: [
          _PrizeTile(place: '🥇', label: '1st place',
              amount: p.first),
          const SizedBox(width: 8),
          _PrizeTile(place: '🥈', label: '2nd place',
              amount: p.second),
          const SizedBox(width: 8),
          _PrizeTile(place: '🥉', label: '3rd place',
              amount: p.third),
        ]),
      ),
    );
  }

  SliverToBoxAdapter _buildMyRankTile() {
    final e = _myEntry!;
    return SliverToBoxAdapter(
      child: Container(
        margin:  const EdgeInsets.fromLTRB(20, 8, 20, 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        Colors.indigo.withOpacity(0.25),
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: Colors.indigo.withOpacity(0.5)),
        ),
        child: Row(children: [
          Text('#${e.rank}',
              style: const TextStyle(color: Colors.white,
                  fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(width: 12),
          const Text('You',
              style: TextStyle(color: Colors.white70, fontSize: 15)),
          const Spacer(),
          Text(e.score.toStringAsFixed(1),
              style: const TextStyle(color: Colors.white,
                  fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          const Text('/100',
              style: TextStyle(color: Colors.white38, fontSize: 11)),
        ]),
      ),
    );
  }

  SliverList _buildEntriesList() {
    final entries = _entries ?? [];
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) {
          if (i == 0) {
            return const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text('Top 100',
                  style: TextStyle(color: Colors.white54,
                      fontSize: 12, fontWeight: FontWeight.w600,
                      letterSpacing: 1)),
            );
          }
          final e   = entries[i - 1];
          final col = switch (e.rank) {
            1 => const Color(0xFFFFD700),
            2 => const Color(0xFFC0C0C0),
            3 => const Color(0xFFCD7F32),
            _ => Colors.white54,
          };
          return Container(
            margin:  const EdgeInsets.fromLTRB(20, 0, 20, 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color:        e.isCurrentUser
                  ? Colors.indigo.withOpacity(0.15)
                  : const Color(0xFF161628),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              SizedBox(
                width: 36,
                child: Text('#${e.rank}',
                    style: TextStyle(color: col,
                        fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              Expanded(
                child: Text(
                    e.isCurrentUser ? '${e.displayName} (you)' : e.displayName,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    overflow: TextOverflow.ellipsis),
              ),
              Text(e.score.toStringAsFixed(1),
                  style: const TextStyle(color: Colors.white,
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              const Text('/100',
                  style: TextStyle(color: Colors.white38, fontSize: 10)),
              if (e.isPrizeEligible && e.rank <= 3) ...[
                const SizedBox(width: 6),
                const Icon(Icons.workspace_premium,
                    color: Color(0xFFFFD700), size: 14),
              ],
            ]),
          );
        },
        childCount: (entries.length) + 1,
      ),
    );
  }

  String _monthName(int m) => const [
    '', 'January', 'February', 'March', 'April',
    'May', 'June', 'July', 'August', 'September',
    'October', 'November', 'December',
  ][m];
}

class _PrizeTile extends StatelessWidget {
  final String place, label;
  final int    amount;
  const _PrizeTile({
    required this.place, required this.label, required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final d = amount ~/ 100;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color:        const Color(0xFF161628),
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Column(children: [
          Text(place, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text('\$$d',
              style: const TextStyle(color: Colors.white,
                  fontSize: 18, fontWeight: FontWeight.w700)),
          Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ]),
      ),
    );
  }
}

class _UpgradeBanner extends StatelessWidget {
  final String message;
  const _UpgradeBanner({required this.message});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:        Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.lock_outline, color: Colors.amber, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(message,
            style: const TextStyle(color: Colors.amber, fontSize: 12))),
      ]),
    );
  }
}
```

---

## FILE 18: lib/features/social/wallet_screen.dart
## PURPOSE: In-app reward wallet. Shows balance, pending, recent
##          transactions, and withdrawal options.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/reward_ledger.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/economy_service.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authProvider).currentUser?.uid ?? '';
    final svc = EconomyService();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Reward Wallet',
            style: TextStyle(color: Colors.white)),
        leading: const BackButton(color: Colors.white),
      ),
      body: StreamBuilder<RewardWallet>(
        stream: svc.walletStream(uid),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white38));
          }
          final wallet = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _BalanceCard(wallet: wallet),
              const SizedBox(height: 16),
              if (wallet.showTaxWarning) _TaxWarning(),
              const SizedBox(height: 16),
              if (wallet.canWithdraw)
                _WithdrawButton(wallet: wallet, userId: uid),
              const SizedBox(height: 24),
              _TransactionList(wallet: wallet),
            ],
          );
        },
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final RewardWallet wallet;
  const _BalanceCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A3E), Color(0xFF2D1B69)],
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Available Balance',
            style: TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 8),
        Text(wallet.availableDisplay,
            style: const TextStyle(color: Colors.white,
                fontSize: 42, fontWeight: FontWeight.w300)),
        if (wallet.pendingCents > 0) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.schedule, color: Colors.white38, size: 14),
            const SizedBox(width: 6),
            Text(
              '\$${(wallet.pendingCents / 100).toStringAsFixed(2)} pending '
              '(in hold period)',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ]),
        ],
        const SizedBox(height: 16),
        const Divider(color: Colors.white12),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.trending_up, color: Colors.greenAccent, size: 14),
          const SizedBox(width: 6),
          Text(
            '\$${(wallet.lifetimeEarnedCents / 100).toStringAsFixed(2)} '
            'earned lifetime',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ]),
      ]),
    );
  }
}

class _TaxWarning extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: const Row(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Icon(Icons.info_outline, color: Colors.orange, size: 18),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'You\'ve earned \$600+ from RISE. US users may receive a 1099 '
            'form. Consult a tax professional for guidance.',
            style: TextStyle(color: Colors.orange, fontSize: 12),
          ),
        ),
      ]),
    );
  }
}

class _WithdrawButton extends StatelessWidget {
  final RewardWallet wallet;
  final String       userId;
  const _WithdrawButton({required this.wallet, required this.userId});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _showWithdrawSheet(context),
      icon: const Icon(Icons.account_balance_wallet_outlined),
      label: Text('Withdraw ${wallet.availableDisplay}'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.greenAccent,
        foregroundColor: Colors.black,
        minimumSize:     const Size.fromHeight(52),
        shape:           RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _showWithdrawSheet(BuildContext context) {
    showModalBottomSheet(
      context:           context,
      backgroundColor:   const Color(0xFF161628),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _WithdrawSheet(
          wallet: wallet, userId: userId),
    );
  }
}

class _WithdrawSheet extends StatefulWidget {
  final RewardWallet wallet;
  final String       userId;
  const _WithdrawSheet({required this.wallet, required this.userId});

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  String _method   = 'paypal';
  final  _acctCtrl = TextEditingController();
  bool   _submitting = false;
  String? _result;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Withdraw Funds',
              style: TextStyle(color: Colors.white, fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Minimum: \$10.00  ·  Maximum: \$500.00 per transaction',
              style: TextStyle(color: Colors.white.withOpacity(0.4),
                  fontSize: 12)),
          const SizedBox(height: 24),

          // Method selection
          Row(children: [
            _MethodChip(label: 'PayPal', selected: _method == 'paypal',
                onTap: () => setState(() => _method = 'paypal')),
            const SizedBox(width: 10),
            _MethodChip(label: 'Bank Transfer', selected: _method == 'stripe',
                onTap: () => setState(() => _method = 'stripe')),
          ]),
          const SizedBox(height: 16),

          TextField(
            controller:  _acctCtrl,
            style:       const TextStyle(color: Colors.white),
            decoration:  InputDecoration(
              hintText:       _method == 'paypal'
                  ? 'PayPal email address'
                  : 'Bank account number',
              hintStyle:      const TextStyle(color: Colors.white38),
              enabledBorder:  const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24)),
              focusedBorder:  const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 24),

          if (_result != null) ...[
            Text(_result!, style: TextStyle(
                color: _result!.startsWith('✓')
                    ? Colors.greenAccent : Colors.redAccent)),
            const SizedBox(height: 12),
          ],

          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _submitting
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Withdraw ${widget.wallet.availableDisplay}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_acctCtrl.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    final result = await EconomyService().requestWithdrawal(
      userId:     widget.userId,
      amountCents: widget.wallet.availableCents,
      method:     _method,
      accountId:  _acctCtrl.text.trim(),
    );
    setState(() {
      _submitting = false;
      _result = switch (result) {
        WithdrawalResult.success  => '✓ Withdrawal requested. Arrives in 2–5 business days.',
        WithdrawalResult.tooSmall => '✗ Minimum withdrawal is \$10.00.',
        WithdrawalResult.tooLarge => '✗ Maximum withdrawal is \$500.00 per transaction.',
        WithdrawalResult.failed   => '✗ Something went wrong. Try again later.',
      };
    });
  }
}

class _MethodChip extends StatelessWidget {
  final String   label;
  final bool     selected;
  final VoidCallback onTap;
  const _MethodChip({
    required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color:        selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        border:       Border.all(color: Colors.white38),
      ),
      child: Text(label,
          style: TextStyle(
              color: selected ? Colors.black : Colors.white70,
              fontWeight: FontWeight.w600)),
    ),
  );
}

class _TransactionList extends StatelessWidget {
  final RewardWallet wallet;
  const _TransactionList({required this.wallet});

  @override
  Widget build(BuildContext context) {
    if (wallet.recentTransactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No transactions yet',
              style: TextStyle(color: Colors.white38)),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Transactions',
            style: TextStyle(color: Colors.white54, fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...wallet.recentTransactions.map((t) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color:        const Color(0xFF161628),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.description,
                    style: const TextStyle(color: Colors.white70,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text(_formatDate(t.createdAt),
                    style: const TextStyle(color: Colors.white38,
                        fontSize: 11)),
                if (t.isHeld)
                  const Text('Pending · in hold period',
                      style: TextStyle(
                          color: Colors.amber, fontSize: 10)),
              ],
            )),
            Text(t.formattedAmount,
                style: TextStyle(
                  color: t.amountCents >= 0
                      ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                )),
          ]),
        )),
      ],
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';
  static const _months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];
}
```

---

## FILE 19: lib/features/social/referral_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/referral_service.dart';

class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});
  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  ReferralStats? _stats;
  bool           _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = ref.read(authProvider).currentUser?.uid ?? '';
    final s   = await ReferralService().getStats(uid);
    if (!mounted) return;
    setState(() { _stats = s; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading:  const BackButton(color: Colors.white),
        title:    const Text('Invite Friends',
            style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(
              color: Colors.white38))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final s = _stats!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // How it works
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1A3E), Color(0xFF2D1B69)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Earn by sharing RISE',
                  style: TextStyle(color: Colors.white,
                      fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              _EarnRow(
                  icon: Icons.person_add_outlined,
                  text: 'You earn \$2 for every friend who subscribes'),
              const SizedBox(height: 10),
              _EarnRow(
                  icon: Icons.card_giftcard_outlined,
                  text: 'Your friend gets \$1 off their first month'),
              const SizedBox(height: 10),
              _EarnRow(
                  icon: Icons.workspace_premium_outlined,
                  text: 'Gift to 30+ users → earn 15% of their renewals'),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Referral code box
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color:        const Color(0xFF161628),
            borderRadius: BorderRadius.circular(16),
            border:       Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: Column(children: [
            const Text('Your referral code',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(s.code, style: const TextStyle(
                    color: Colors.white, fontSize: 24,
                    fontWeight: FontWeight.w700, letterSpacing: 3)),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: s.code));
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied!')));
                  },
                  child: const Icon(Icons.copy, color: Colors.white54),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Share.share(
                  'Wake up smarter with RISE — the alarm app that actually '
                  'keeps you accountable. Use my code ${s.code} to get \$1 '
                  'off your first month: ${s.link}'),
              icon:  const Icon(Icons.share),
              label: const Text('Share your link'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize:     const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ]),
        ),

        const SizedBox(height: 20),

        // Stats
        Row(children: [
          _StatCard(
              value: '${s.confirmed}',
              label: 'Confirmed\nreferrals'),
          const SizedBox(width: 10),
          _StatCard(
              value: '\$${(s.totalEarnedCents / 100).toStringAsFixed(2)}',
              label: 'Total\nearned'),
          const SizedBox(width: 10),
          _StatCard(
              value: '${s.qualifying}',
              label: 'Qualifying\n(14-day hold)'),
        ]),

        const SizedBox(height: 20),

        // Terms
        Text(
          'Terms: Referral credited when friend maintains subscription '
          'for 14+ days. Max 500 referrals per account. '
          'Wallet credits held 30 days before withdrawal.',
          style: TextStyle(color: Colors.white.withOpacity(0.3),
              fontSize: 11),
        ),
      ],
    );
  }
}

class _EarnRow extends StatelessWidget {
  final IconData icon;
  final String   text;
  const _EarnRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: Colors.greenAccent, size: 18),
    const SizedBox(width: 10),
    Expanded(child: Text(text,
        style: const TextStyle(color: Colors.white70, fontSize: 13))),
  ]);
}

class _StatCard extends StatelessWidget {
  final String value, label;
  const _StatCard({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        const Color(0xFF161628),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Text(value, style: const TextStyle(
            color: Colors.white, fontSize: 22,
            fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(
            color: Colors.white38, fontSize: 11),
            textAlign: TextAlign.center),
      ]),
    ),
  );
}
```

---

## PART 6 COMPLETE FILE INVENTORY

```
Part 6A (File 1 of 2):
  ECONOMICS SPEC                               ← Read first
  lib/core/constants/app_constants.dart        ← ADD economy constants
  lib/core/models/subscription_tier.dart       ← NEW
  lib/core/models/reward_ledger.dart           ← NEW
  lib/core/models/sleep_challenge.dart         ← NEW
  lib/core/models/dream_entry.dart             ← NEW (typeId: 8)
  lib/core/models/referral_record.dart         ← NEW
  lib/core/services/economy_service.dart       ← NEW
  lib/core/services/referral_service.dart      ← NEW
  lib/core/services/dream_journal_service.dart ← NEW
  lib/core/services/wake_game_engine.dart      ← NEW

Part 6B (this file):
  lib/features/wake_games/games/math_game.dart          ← NEW
  lib/features/wake_games/games/memory_grid_game.dart   ← NEW
  lib/features/wake_games/games/word_unscramble_game.dart ← NEW
  lib/features/wake_games/games/sequence_tap_game.dart  ← NEW (EC-3.11)
  lib/features/wake_games/games/barcode_scan_game.dart  ← NEW
  lib/features/social/leaderboard_service.dart          ← NEW
  lib/features/social/sleep_challenge_service.dart      ← NEW
  lib/features/social/leaderboard_screen.dart           ← NEW
  lib/features/social/wallet_screen.dart                ← NEW
  lib/features/social/referral_screen.dart              ← NEW
```

---

## NEW pubspec.yaml DEPENDENCIES

```yaml
dependencies:
  mobile_scanner:  ^3.5.2    # Barcode scan game
  share_plus:      ^7.2.1    # Referral link sharing
  flutter_tts:     ^3.8.5    # EC-3.11 sequence tap TTS
  cloud_functions: ^4.6.0    # Economy Cloud Function calls
```

---

## AFTER CREATING ALL FILES — RUN:

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
```

Expected: 0 errors. dream_entry.g.dart will be generated.

---

## WHAT PART 7 WILL COVER:
The main alarm screen — the full-screen UI that fires when the alarm
goes off. This is where the wake game engine, biometric verification,
audio escalation, buddy notification timer, post-dismissal watchdog
(EC-4.9), and all the visual/haptic layers come together in one
cohesive experience.

---
## END OF PART 6 BLUEPRINT (File 2 of 2)
## Subscription model:   COMPLETE ✓ (4 tiers, exact pricing, all feature flags)
## Economy:              COMPLETE ✓ ($100 sleep reward, leaderboard prizes,
##                                   challenges, referrals, reseller 15%)
## Dream journal:        COMPLETE ✓ (faith-based AI, 8 traditions, 5 msg/day)
## Wake games:           COMPLETE ✓ (math, memory, word, sequence, barcode)
## Leaderboard:          COMPLETE ✓ (global top 100, scalable prize pool)
## Wallet:               COMPLETE ✓ (balance, pending, withdraw, tax warning)
## Referral screen:      COMPLETE ✓ (share link, stats, 30-reseller gate)
