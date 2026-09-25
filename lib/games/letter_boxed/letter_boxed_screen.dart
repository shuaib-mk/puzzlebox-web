import 'package:flutter/foundation.dart';
import 'boxed_generator.dart';
import '../daily_five/logic/word_list.dart';
import '../../core/services/puzzle_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/stats_service.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/game_mode_toggle.dart';
import '../../core/widgets/neo_toast.dart';
import '../../core/mixins/practice_mode_mixin.dart';

class LetterBoxedSquareItem {
  final List<String> top;
  final List<String> right;
  final List<String> bottom;
  final List<String> left;

  const LetterBoxedSquareItem({
    required this.top,
    required this.right,
    required this.bottom,
    required this.left,
  });
}

class LetterBoxedScreen extends ConsumerStatefulWidget {
  const LetterBoxedScreen({super.key});

  @override
  ConsumerState<LetterBoxedScreen> createState() => _LetterBoxedScreenState();
}

class _LetterBoxedScreenState extends ConsumerState<LetterBoxedScreen>
    with PracticeModeMixin {
  @override
  String get gameType => 'letter_boxed';

  List<String> _solution = [];
  bool _loading = true;
  bool _generationFailed = false;
  int _request = 0;
  Set<String> get _dictionary => {...WordList.answers, ...clueBank.keys};
  late List<String> _top;
  late List<String> _right;
  late List<String> _bottom;
  late List<String> _left;

  String _currentWord = '';
  int? _lastSide;
  final Set<String> _usedLetters = {};
  final List<String> _completedWords = [];
  bool _isSolved = false;

  @override
  void initState() {
    super.initState();
    initPracticeMode();
    _loadBoxedPuzzle();
  }

  @override
  void onPracticeModeChanged(GameMode mode) {
    _loadBoxedPuzzle();
  }

  @override
  void loadDailyPuzzle() {
    _loadBoxedPuzzle();
  }

  @override
  void loadPracticePuzzle() {
    _loadBoxedPuzzle();
  }

  Future<void> _loadBoxedPuzzle() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _generationFailed = false;
    });
    try {
      final input = (
        _dictionary.toList(),
        puzzleSeed(),
        difficulty == 'Hard' ? 4 : 3,
      );
      final puzzle = await compute(_makeBox, input);
      if (!mounted || request != _request) return;
      setState(() {
        _top = puzzle.sides[0];
        _right = puzzle.sides[1];
        _bottom = puzzle.sides[2];
        _left = puzzle.sides[3];
        _solution = puzzle.solution;
        _currentWord = '';
        _lastSide = null;
        _usedLetters.clear();
        _completedWords.clear();
        _isSolved = false;
        _loading = false;
        if (difficulty == 'Easy') {
          _currentWord = _solution.first;
          _lastSide = _side(_currentWord[_currentWord.length - 1]);
        }
        startSession();
      });
    } catch (_) {
      if (mounted && request == _request) {
        setState(() => _generationFailed = true);
        showPuzzleHint('Could not prepare this box. Tap Next to try another.');
      }
    }
  }

  static BoxedPuzzle _makeBox((List<String>, int, int) input) =>
      generateBoxed(input.$1, input.$2, input.$3);
  int _side(String letter) =>
      [_top, _right, _bottom, _left].indexWhere((s) => s.contains(letter));
  void _hint() {
    if (_loading) return;
    final next = _solution.firstWhere(
      (w) => !_completedWords.contains(w),
      orElse: () => _solution.first,
    );
    showPuzzleHint(
      'A complete legal chain is ${_solution.join(" → ")}. Next suggested word: $next.',
    );
  }

  void _onLetterTap(String letter, int side) {
    if (_isSolved || _currentWord.length >= 24) return;
    if (_lastSide == side) {
      NeoToast.show(
        context,
        'Cannot pick consecutive letters from the same side!',
        icon: Icons.block_rounded,
        color: const Color(0xFFF43F5E),
        duration: const Duration(milliseconds: 1500),
      );
      return;
    }
    setState(() {
      _currentWord += letter;
      _lastSide = side;
    });
  }

  void _submitWord() {
    if (_currentWord.length < 3 || _isSolved) return;
    if (!_dictionary.contains(_currentWord) &&
        !WordList.dictionary.contains(_currentWord)) {
      showPuzzleHint('Not in the bundled word list.');
      return;
    }
    if (_completedWords.contains(_currentWord)) {
      showPuzzleHint('Already used that word.');
      return;
    }

    setState(() {
      _completedWords.add(_currentWord);
      for (final ch in _currentWord.split('')) {
        _usedLetters.add(ch);
      }
      _currentWord = _completedWords.last[_completedWords.last.length - 1];
      _lastSide = _side(_currentWord);
    });

    if (_usedLetters.length >= 12) {
      setState(() => _isSolved = true);

      if (mode == GameMode.daily) {
        ref
            .read(statsServiceProvider)
            .recordResult(
              gameType: 'letter_boxed',
              todayKey: dailyDateKey,
              won: true,
            );
        _showResultDialog();
      } else {
        recordPracticeWin();
      }
    }
  }

  void _showResultDialog() {
    finishPuzzle();
  }

  void _clearCurrent() {
    setState(() {
      _currentWord = _completedWords.isEmpty
          ? ''
          : _completedWords.last[_completedWords.last.length - 1];
      _lastSide = _currentWord.isEmpty ? null : _side(_currentWord);
    });
  }

  @override
  Map<String, dynamic> captureProgress() => _loading || _isSolved
      ? {}
      : {'words': _completedWords, 'input': _currentWord};
  @override
  void restoreProgress(Map<String, dynamic> d) {
    _completedWords.addAll(List<String>.from(d['words']));
    _usedLetters.addAll(_completedWords.join().split(''));
    _currentWord = d['input'] as String;
    _lastSide = _currentWord.isEmpty
        ? null
        : _side(_currentWord[_currentWord.length - 1]);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: mode == GameMode.daily
          ? 'Letter Boxed'
          : 'Letter Boxed — Unlimited',
      showBackButton: true,
      actions: [
        IconButton(
          onPressed: _hint,
          icon: Icon(Icons.lightbulb_outline),
          tooltip: 'Hint',
        ),
      ],
      body: _loading
          ? Column(
              children: [
                buildPracticeModeToggle(),
                Expanded(
                  child: Center(
                    child: _generationFailed
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('This puzzle could not be prepared.'),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _loadBoxedPuzzle,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Try again'),
                              ),
                            ],
                          )
                        : const CircularProgressIndicator(),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                buildPracticeModeToggle(),
                Divider(height: 1),

                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Used Letters Count Header
                        Text(
                          'Letters Used: ${_usedLetters.length} / 12',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        SizedBox(height: 12),

                        // Active Word Display
                        Container(
                          height: 44,
                          alignment: Alignment.center,
                          child: Text(
                            _currentWord,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        SizedBox(height: 12),

                        // Square Box UI (Top, Left, Right, Bottom)
                        Expanded(
                          child: Center(
                            child: FittedBox(
                              child: SizedBox(
                                width: 300,
                                height: 300,
                                child: AnimatedContainer(
                                  duration:
                                      MediaQuery.disableAnimationsOf(context)
                                      ? Duration.zero
                                      : const Duration(milliseconds: 160),
                                  curve: Curves.easeOutCubic,
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.black, width: 2.5),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black, offset: Offset(3.5, 3.5), blurRadius: 0),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Top Side (Side 0)
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: _top
                                            .map(
                                              (l) => _SideLetter(
                                                letter: l,
                                                side: 0,
                                                onTap: () => _onLetterTap(l, 0),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                      // Middle Row (Left Side 3 & Right Side 1)
                                      Expanded(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: _left
                                                  .map(
                                                    (l) => _SideLetter(
                                                      letter: l,
                                                      side: 3,
                                                      onTap: () =>
                                                          _onLetterTap(l, 3),
                                                    ),
                                                  )
                                                  .toList(),
                                            ),
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: _right
                                                  .map(
                                                    (l) => _SideLetter(
                                                      letter: l,
                                                      side: 1,
                                                      onTap: () =>
                                                          _onLetterTap(l, 1),
                                                    ),
                                                  )
                                                  .toList(),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Bottom Side (Side 2)
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: _bottom
                                            .map(
                                              (l) => _SideLetter(
                                                letter: l,
                                                side: 2,
                                                onTap: () => _onLetterTap(l, 2),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Controls or Next Puzzle
                        if (shouldShowNextButton(_isSolved)) ...[
                          ElevatedButton.icon(
                            icon: Icon(Icons.arrow_forward_rounded),
                            label: Text('Next Box'),
                            onPressed: nextPuzzle,
                          ),
                        ] else ...[
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              OutlinedButton(
                                onPressed: _clearCurrent,
                                child: Text('Clear'),
                              ),
                              IconButton(
                                tooltip: 'Delete letter',
                                icon: const Icon(Icons.backspace_outlined),
                                onPressed: () {
                                  final minimum = _completedWords.isEmpty
                                      ? 0
                                      : 1;
                                  if (_currentWord.length <= minimum) return;
                                  setState(() {
                                    _currentWord = _currentWord.substring(
                                      0,
                                      _currentWord.length - 1,
                                    );
                                    _lastSide = _currentWord.isEmpty
                                        ? null
                                        : _side(
                                            _currentWord[_currentWord.length -
                                                1],
                                          );
                                  });
                                },
                              ),
                              IconButton(
                                tooltip: 'Undo word',
                                icon: Icon(Icons.undo),
                                onPressed: () {
                                  if (_completedWords.isEmpty || _isSolved) {
                                    return;
                                  }
                                  setState(() {
                                    _completedWords.removeLast();
                                    _usedLetters.clear();
                                    _usedLetters.addAll(
                                      _completedWords.join().split(''),
                                    );
                                  });
                                  _clearCurrent();
                                },
                              ),
                              ElevatedButton(
                                onPressed: _currentWord.length >= 3
                                    ? _submitWord
                                    : null,
                                child: Text('Submit Word'),
                              ),
                            ],
                          ),
                        ],
                        SizedBox(height: 12),

                        // Completed Words
                        Wrap(
                          spacing: 8,
                          children: _completedWords
                              .map(
                                (w) => Chip(
                                  label: Text(w),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SideLetter extends StatelessWidget {
  final String letter;
  final int side;
  final VoidCallback onTap;

  const _SideLetter({
    required this.letter,
    required this.side,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black, width: 2.2),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0),
          ],
        ),
        child: Center(
          child: Text(
            letter,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
