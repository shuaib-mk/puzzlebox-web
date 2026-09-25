import '../daily_five/logic/word_list.dart';
import '../../core/services/puzzle_content.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/stats_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/game_mode_toggle.dart';
import '../../core/widgets/neo_toast.dart';
import '../../core/mixins/practice_mode_mixin.dart';

class SpellingBeeScreen extends ConsumerStatefulWidget {
  const SpellingBeeScreen({super.key});

  @override
  ConsumerState<SpellingBeeScreen> createState() => _SpellingBeeScreenState();
}

class _SpellingBeeScreenState extends ConsumerState<SpellingBeeScreen>
    with PracticeModeMixin {
  @override
  String get gameType => 'spelling_bee';

  String _centerLetter = 'A';
  List<String> _outerLetters = ['C', 'T', 'I', 'O', 'N', 'P'];
  String _currentInput = '';
  final List<String> _foundWords = [];
  int _score = 0;
  int _targetWords = 1;
  bool _isGameComplete = false;

  late Map<String, int> _validDictionary;

  @override
  void initState() {
    super.initState();
    initPracticeMode();
    _loadBeePuzzle();
  }

  @override
  void onPracticeModeChanged(GameMode mode) {
    _loadBeePuzzle();
  }

  @override
  void loadDailyPuzzle() {
    _loadBeePuzzle();
  }

  @override
  void loadPracticePuzzle() {
    _loadBeePuzzle();
  }

  void _loadBeePuzzle() {
    final rand = Random(puzzleSeed());
    final dictionary = {...WordList.answers, ...clueBank.keys, ...beePangrams};
    final bases = List<String>.from(beePangrams)..shuffle(rand);
    final letters = bases.first.split('').toSet().toList()..shuffle(rand);
    final center = letters.first;
    final words = dictionary
        .where(
          (w) =>
              w.length >= 4 &&
              w.contains(center) &&
              w.split('').every(letters.contains),
        )
        .toList();
    final goal = difficulty == 'Easy'
        ? 3
        : difficulty == 'Medium'
        ? 6
        : 10;
    _targetWords = words.length < goal ? words.length : goal;
    setState(() {
      _centerLetter = center;
      _outerLetters = letters.skip(1).toList();
      _validDictionary = {
        for (final w in words) w: w.length == 4 ? 1 : w.length,
      };
      _currentInput = '';
      _foundWords.clear();
      _score = 0;
      _isGameComplete = false;
      startSession();
    });
  }

  void _addLetter(String letter) {
    if (_isGameComplete || _currentInput.length >= 24) return;
    setState(() {
      _currentInput += letter;
    });
  }

  void _delete() {
    if (_currentInput.isNotEmpty) {
      setState(() {
        _currentInput = _currentInput.substring(0, _currentInput.length - 1);
      });
    }
  }

  void _shuffle() {
    setState(() {
      _outerLetters.shuffle();
    });
  }

  void _submit() {
    if (_isGameComplete) return;
    if (_currentInput.length < 4) {
      _showToast('Too short');
      return;
    }
    if (!_currentInput.contains(_centerLetter)) {
      _showToast('Missing center letter');
      return;
    }

    if (_foundWords.contains(_currentInput)) {
      _showToast('Already found');
      return;
    }

    final points =
        _validDictionary[_currentInput] ??
        (WordList.dictionary.contains(_currentInput)
            ? (_currentInput.length == 4 ? 1 : _currentInput.length)
            : 0);
    if (points > 0) {
      final isPangram =
          _outerLetters.every((l) => _currentInput.contains(l)) &&
          _currentInput.contains(_centerLetter);
      setState(() {
        _foundWords.add(_currentInput);
        _score += points + (isPangram ? 7 : 0);
        _currentInput = '';
      });
      _showToast(
        isPangram ? 'PANGRAM! +${points + 7} pts' : 'Nice! +$points pts',
      );

      // Check if all words found (simple completion heuristic)
      if (_foundWords.length >= _targetWords) {
        _completeGame();
      }
    } else {
      _showToast('Not in word list');
    }
  }

  void _completeGame() {
    if (_isGameComplete) return;
    setState(() => _isGameComplete = true);

    if (mode == GameMode.daily) {
      ref
          .read(statsServiceProvider)
          .recordResult(
            gameType: 'spelling_bee',
            todayKey: dailyDateKey,
            won: true,
          );
      _showResultDialog();
    } else {
      recordPracticeWin();
      _showNextPuzzleButton();
    }
  }

  void _showResultDialog() {
    finishPuzzle();
  }

  void _showNextPuzzleButton() {
    // The next puzzle button will appear in the actions row
  }

  void _showToast(String message) {
    NeoToast.show(
      context,
      message,
      icon: Icons.hive_rounded,
      color: const Color(0xFFC084FC),
      duration: const Duration(milliseconds: 2000),
    );
  }

  String get _rank {
    if (_score >= 30) return 'Genius 🐝';
    if (_score >= 20) return 'Amazing';
    if (_score >= 12) return 'Great';
    if (_score >= 6) return 'Moving Up';
    return 'Beginner';
  }

  @override
  Map<String, dynamic> captureProgress() =>
      _isGameComplete ? {} : {'found': _foundWords, 'score': _score};
  @override
  void restoreProgress(Map<String, dynamic> d) {
    _foundWords.addAll(List<String>.from(d['found']));
    _score = d['score'] as int;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: mode == GameMode.daily
          ? 'Spelling Bee'
          : 'Spelling Bee — Unlimited',
      showBackButton: true,
      actions: [
        AppBarIconButton(
          icon: Icons.lightbulb_outline_rounded,
          tooltip: 'In-App Hints',
          onTap: () {
            final words = _validDictionary.keys
                .where((w) => !_foundWords.contains(w))
                .toList();
            if (words.isNotEmpty) {
              showPuzzleHint(
                'Try a ${words.first.length}-letter word starting ${words.first.substring(0, 2)}. ${clueBank[words.first] ?? "It uses the center letter."}',
              );
            }
          },
        ),
        if (shouldShowNextButton(_isGameComplete))
          IconButton(
            icon: Icon(Icons.arrow_forward_rounded),
            tooltip: 'Next Puzzle',
            onPressed: nextPuzzle,
          ),
      ],
      body: Column(
        children: [
          buildPracticeModeToggle(),
          Divider(height: 1),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Score & Rank Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black, width: 2.5),
                      boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rank: $_rank',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Text(
                          'Score: $_score',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Current Input Display
                  Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black, width: 2.2),
                    ),
                    child: Text(
                      _currentInput,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Honeycomb 7-Letter View
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _BeeTile(
                                letter: _outerLetters[0],
                                onTap: () => _addLetter(_outerLetters[0]),
                              ),
                              const SizedBox(width: 8),
                              _BeeTile(
                                letter: _outerLetters[1],
                                onTap: () => _addLetter(_outerLetters[1]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _BeeTile(
                                letter: _outerLetters[2],
                                onTap: () => _addLetter(_outerLetters[2]),
                              ),
                              const SizedBox(width: 8),
                              _BeeTile(
                                letter: _centerLetter,
                                isCenter: true,
                                onTap: () => _addLetter(_centerLetter),
                              ),
                              const SizedBox(width: 8),
                              _BeeTile(
                                letter: _outerLetters[3],
                                onTap: () => _addLetter(_outerLetters[3]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _BeeTile(
                                letter: _outerLetters[4],
                                onTap: () => _addLetter(_outerLetters[4]),
                              ),
                              const SizedBox(width: 8),
                              _BeeTile(
                                letter: _outerLetters[5],
                                onTap: () => _addLetter(_outerLetters[5]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Honeycomb Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: _delete,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.black, width: 2.2),
                            boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2.5, 2.5), blurRadius: 0)],
                          ),
                          child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.black)),
                        ),
                      ),
                      GestureDetector(
                        onTap: _shuffle,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.black, width: 2.2),
                            boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2.5, 2.5), blurRadius: 0)],
                          ),
                          child: const Icon(Icons.refresh, color: Colors.black),
                        ),
                      ),
                      GestureDetector(
                        onTap: _isGameComplete ? null : _submit,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.black, width: 2.2),
                            boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2.5, 2.5), blurRadius: 0)],
                          ),
                          child: const Text('Enter', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.black)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Found Words Sheet Toggle
                  ExpansionTile(
                    title: Text(
                      'Found ${_foundWords.length} / $_targetWords words',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _foundWords
                            .map(
                              (w) => Chip(
                                label: Text(w, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                              ),
                            )
                            .toList(),
                      ),
                    ],
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

class _BeeTile extends StatelessWidget {
  final String letter;
  final bool isCenter;
  final VoidCallback onTap;

  const _BeeTile({
    required this.letter,
    this.isCenter = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: isCenter ? colors.primary : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 2.5),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
          ],
        ),
        child: Center(
          child: Text(
            letter,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
