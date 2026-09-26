import '../../core/services/puzzle_content.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/date_service.dart';
import '../../core/services/stats_service.dart';
import '../../core/services/app_feedback_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/game_mode_toggle.dart';
import '../../core/widgets/neo_toast.dart';
import '../../core/mixins/practice_mode_mixin.dart';

class CategoryGroup {
  final String title;
  final List<String> words;
  final Color color;
  final String difficultyLabel;

  const CategoryGroup({
    required this.title,
    required this.words,
    required this.color,
    required this.difficultyLabel,
  });
}

final connectionsCategories = [
  CategoryGroup(
    title: 'TYPES OF MUSIC GENRES',
    words: ['ROCK', 'JAZZ', 'BLUES', 'DISCO'],
    color: AppColors.difficultyEasy,
    difficultyLabel: 'Yellow (Easy)',
  ),
  CategoryGroup(
    title: 'ITEMS IN A KITCHEN',
    words: ['SPOON', 'OVEN', 'FRIDGE', 'BLENDER'],
    color: AppColors.difficultyMedium,
    difficultyLabel: 'Green (Medium)',
  ),
  CategoryGroup(
    title: 'WORDS THAT START WITH A FRUIT',
    words: ['APPLESEED', 'PLUMBER', 'PEACHY', 'MANGOSTEEN'],
    color: AppColors.difficultyHard,
    difficultyLabel: 'Blue (Hard)',
  ),
  CategoryGroup(
    title: '______ BOARD GAMES',
    words: ['CLUE', 'CHESS', 'SORRY', 'RISK'],
    color: AppColors.difficultyExpert,
    difficultyLabel: 'Purple (Tricky)',
  ),
];

class ConnectionsScreen extends ConsumerStatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  ConsumerState<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends ConsumerState<ConnectionsScreen>
    with PracticeModeMixin {
  @override
  String get gameType => 'connections';

  late List<CategoryGroup> _categories;
  late List<String> _remainingWords;
  final List<String> _selectedWords = [];
  final List<CategoryGroup> _solvedCategories = [];
  final Set<String> _previousGuesses = {};
  int _mistakesRemaining = 4;
  bool _isGameOver = false;

  @override
  void initState() {
    super.initState();
    initPracticeMode();
    _resetPuzzle();
  }

  @override
  void onPracticeModeChanged(GameMode mode) {
    _resetPuzzle();
  }

  @override
  void loadDailyPuzzle() {
    _resetPuzzle();
  }

  @override
  void loadPracticePuzzle() {
    _resetPuzzle();
  }

  void _resetPuzzle() {
    final rand = Random(puzzleSeed());
    final bank = categoryBank.entries.toList();
    final eligible = difficulty == 'Easy'
        ? bank.take(18).toList()
        : difficulty == 'Hard'
        ? bank.skip(12).toList()
        : bank;
    eligible.shuffle(rand);
    _categories = [];
    final used = <String>{};
    for (final entry in eligible) {
      final words = entry.value.where((w) => !used.contains(w)).toList()
        ..shuffle(rand);
      if (words.length < 4) continue;
      final picked = words.take(4).toList();
      used.addAll(picked);
      _categories.add(
        CategoryGroup(
          title: entry.key,
          words: picked,
          color: [
            AppColors.difficultyEasy,
            AppColors.difficultyMedium,
            AppColors.difficultyHard,
            AppColors.difficultyExpert,
          ][_categories.length],
          difficultyLabel: difficulty,
        ),
      );
      if (_categories.length == 4) break;
    }
    final shuffledCategories = _categories;

    setState(() {
      _remainingWords = shuffledCategories.expand((c) => c.words).toList()
        ..shuffle(rand);
      _selectedWords.clear();
      _solvedCategories.clear();
      _previousGuesses.clear();
      _mistakesRemaining = 4;
      _isGameOver = false;
      startSession();
    });
  }

  void _onWordTap(String word) {
    if (_isGameOver) return;
    AppFeedbackService.tap(ref);
    setState(() {
      if (_selectedWords.contains(word)) {
        _selectedWords.remove(word);
      } else {
        if (_selectedWords.length < 4) {
          _selectedWords.add(word);
        }
      }
    });
  }

  void _shuffle() {
    AppFeedbackService.tap(ref);
    setState(() {
      _remainingWords.shuffle();
    });
  }

  void _deselectAll() {
    AppFeedbackService.tap(ref);
    setState(() {
      _selectedWords.clear();
    });
  }

  void _submit() {
    if (_selectedWords.length != 4 || _isGameOver) return;

    final guess = (_selectedWords.toList()..sort()).join('|');
    if (!_previousGuesses.add(guess)) {
      AppFeedbackService.error(ref);
      showPuzzleHint(
        'You already tried that group. Choose a different combination.',
      );
      return;
    }
    CategoryGroup? matched;
    for (final cat in _categories) {
      if (_solvedCategories.contains(cat)) continue;
      if (cat.words.every((w) => _selectedWords.contains(w))) {
        matched = cat;
        break;
      }
    }

    setState(() {
      if (matched != null) {
        _solvedCategories.add(matched);
        _remainingWords.removeWhere((w) => matched!.words.contains(w));
        _selectedWords.clear();
        if (_solvedCategories.length == 4) {
          _isGameOver = true;
          _recordWin();
          AppFeedbackService.victory(ref);
        } else {
          AppFeedbackService.tap(ref);
        }
      } else {
        AppFeedbackService.error(ref);
        _mistakesRemaining--;
        if (_mistakesRemaining == 0) {
          _isGameOver = true;
          _recordLoss();
        } else {
          NeoToast.show(
            context,
            _categories.any(
                  (c) => c.words.where(_selectedWords.contains).length == 3,
                )
                ? 'One away!'
                : 'Try another grouping.',
            icon: Icons.hub_rounded,
            color: const Color(0xFFF43F5E),
            duration: const Duration(seconds: 2),
          );
        }
      }
    });
  }

  void _recordWin() {
    if (mode == GameMode.daily) {
      ref
          .read(statsServiceProvider)
          .recordResult(
            gameType: 'connections',
            todayKey: dailyDateKey,
            won: true,
          );
    } else {}
    _showBotAnalysis();
  }

  void _recordLoss() {
    if (mode == GameMode.daily) {
      ref
          .read(statsServiceProvider)
          .recordResult(
            gameType: 'connections',
            todayKey: dailyDateKey,
            won: false,
          );
    }
    _showBotAnalysis();
  }

  void _showBotAnalysis() {
    if (_solvedCategories.length < 4) {
      finishPuzzle(
        won: false,
        explanation: _categories
            .where((c) => !_solvedCategories.contains(c))
            .map((c) => '${c.title}: ${c.words.join(", ")}')
            .join(' • '),
      );
    }
    finishPuzzle(won: _solvedCategories.length == 4);
  }

  void _hint() {
    final remaining = _categories
        .where((c) => !_solvedCategories.contains(c))
        .toList();
    if (remaining.isEmpty) return;
    final group = remaining.first;
    showPuzzleHint(
      '${group.words.take(2).join(" and ")} belong together. Think: ${group.title}.',
    );
  }

  @override
  Map<String, dynamic> captureProgress() => _isGameOver
      ? {}
      : {
          'solved': _solvedCategories.map((c) => c.title).toList(),
          'mistakes': _mistakesRemaining,
          'guesses': _previousGuesses.toList(),
          'selected': _selectedWords,
        };
  @override
  void restoreProgress(Map<String, dynamic> d) {
    _solvedCategories.addAll(
      _categories.where((c) => (d['solved'] as List).contains(c.title)),
    );
    _remainingWords.removeWhere(
      (w) => _solvedCategories.any((c) => c.words.contains(w)),
    );
    _mistakesRemaining = (d['mistakes'] as int).clamp(1, 4);
    _previousGuesses.addAll(List<String>.from(d['guesses'] ?? []));
    _selectedWords.addAll(
      List<String>.from(
        d['selected'] ?? [],
      ).where(_remainingWords.contains).take(4),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: mode == GameMode.daily
          ? 'Connections #${DateService.puzzleNumber()}'
          : 'Connections — Unlimited',
      showBackButton: true,
      actions: [
        AppBarIconButton(
          icon: Icons.lightbulb_outline_rounded,
          tooltip: 'In-App Hints',
          onTap: _hint,
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
                  Text(
                    'Create four groups of four!',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Solved Category Banners
                  ..._solvedCategories.map(
                    (cat) => Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cat.color,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black, width: 2.5),
                        boxShadow: const [
                          BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            cat.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cat.words.join(', '),
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 4x4 Grid of Remaining Words
                  if (_remainingWords.isNotEmpty)
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.2,
                        ),
                        itemCount: _remainingWords.length,
                        itemBuilder: (context, index) {
                          final word = _remainingWords[index];
                          final isSelected = _selectedWords.contains(word);
                          final isDark = Theme.of(context).brightness == Brightness.dark;

                          return GestureDetector(
                            onTap: () => _onWordTap(word),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.black, width: 2.2),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black, offset: Offset(2.5, 2.5), blurRadius: 0),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  word,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  // Mistakes remaining indicator
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Mistakes: ',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      ...List.generate(
                        4,
                        (i) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < _mistakesRemaining
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade400,
                            border: Border.all(color: Colors.black, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons or Next Puzzle
                  if (shouldShowNextButton(_isGameOver)) ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Next Puzzle'),
                      onPressed: nextPuzzle,
                    ),
                  ] else ...[
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        GestureDetector(
                          onTap: _shuffle,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.black, width: 2.2),
                              boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2.5, 2.5), blurRadius: 0)],
                            ),
                            child: const Text('Shuffle', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.black)),
                          ),
                        ),
                        GestureDetector(
                          onTap: _selectedWords.isEmpty ? null : _deselectAll,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedWords.isEmpty ? Colors.grey.shade300 : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.black, width: 2.2),
                              boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2.5, 2.5), blurRadius: 0)],
                            ),
                            child: const Text('Deselect All', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.black)),
                          ),
                        ),
                        GestureDetector(
                          onTap: _selectedWords.length == 4 && !_isGameOver ? _submit : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedWords.length == 4 && !_isGameOver
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.black, width: 2.2),
                              boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2.5, 2.5), blurRadius: 0)],
                            ),
                            child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.black)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
