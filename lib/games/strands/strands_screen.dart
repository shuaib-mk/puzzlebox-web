import 'strands_solver.dart';
import 'path_generator.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/stats_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/game_mode_toggle.dart';
import '../../core/widgets/neo_toast.dart';
import '../../core/mixins/practice_mode_mixin.dart';

class StrandsThemeItem {
  final String themeHint;
  final String spangram;
  final List<String> themeWords;
  final List<List<String>> grid;

  const StrandsThemeItem({
    required this.themeHint,
    required this.spangram,
    required this.themeWords,
    required this.grid,
  });
}

class StrandsScreen extends ConsumerStatefulWidget {
  const StrandsScreen({super.key});

  @override
  ConsumerState<StrandsScreen> createState() => _StrandsScreenState();
}

class _StrandsScreenState extends ConsumerState<StrandsScreen>
    with PracticeModeMixin {
  @override
  String get gameType => 'strands';

  final int _rows = 8;
  final int _cols = 6;

  final Map<String, List<int>> _foundPaths = {};
  late StrandsThemeItem _currentTheme;
  final List<int> _selectedIndices = [];
  final Set<int> _foundIndices = {};
  final Set<int> _spangramIndices = {};
  final List<String> _foundThemeWords = [];
  bool _isSolved = false;

  @override
  void initState() {
    super.initState();
    initPracticeMode();
    _loadStrandsPuzzle();
  }

  @override
  void onPracticeModeChanged(GameMode mode) {
    _loadStrandsPuzzle();
  }

  @override
  void loadDailyPuzzle() {
    _loadStrandsPuzzle();
  }

  @override
  void loadPracticePuzzle() {
    _loadStrandsPuzzle();
  }

  final Map<String, List<int>> _canonicalPaths = {};

  void _loadStrandsPuzzle() {
    final rand = Random(puzzleSeed());
    final themes = [
      [
        'Night sky',
        'ASTRONOMY',
        'MOON',
        'STAR',
        'COMET',
        'GALAXY',
        'NEBULA',
        'PLANET',
        'ORBIT',
        'SUN',
      ],
      [
        'Under the sea',
        'OCEANLIFE',
        'SHARK',
        'CORAL',
        'WHALE',
        'DOLPHIN',
        'SQUID',
        'REEF',
        'FISH',
        'WAVE',
      ],
      [
        'In bloom',
        'FLOWERGARDEN',
        'ROSE',
        'LILY',
        'TULIP',
        'DAISY',
        'IRIS',
        'POPPY',
        'ASTER',
        'FERN',
      ],
      [
        'Tools in the kitchen',
        'COOKWARE',
        'SPOON',
        'FORK',
        'KNIFE',
        'LADLE',
        'WHISK',
        'PAN',
        'POT',
        'PLATE',
        'TONGS',
      ],
    ];
    final theme = themes[rand.nextInt(themes.length)];
    final words = theme.skip(2).toList()..shuffle(rand);
    final chosen = [theme[1], ...words];
    var path = [
      for (var r = 0; r < 8; r++)
        for (var c = 0; c < 6; c++) r * 6 + (r.isEven ? c : 5 - c),
    ];
    if (rand.nextBool()) path = path.reversed.toList();
    if (rand.nextBool()) {
      path = path.map((i) => i ~/ 6 * 6 + 5 - i % 6).toList();
    }
    path = weavePath(
      path,
      theme[1].length,
      difficulty == 'Easy'
          ? 0
          : difficulty == 'Medium'
          ? 60
          : 240,
      rand,
    );
    final grid = List.generate(
      8,
      (_) =>
          List.generate(6, (_) => String.fromCharCode(65 + rand.nextInt(26))),
    );
    _canonicalPaths.clear();
    var cursor = 0;
    for (final w in chosen) {
      final wPath = <int>[];
      for (var i = 0; i < w.length; i++) {
        final cell = path[cursor++];
        grid[cell ~/ 6][cell % 6] = w[i];
        wPath.add(cell);
      }
      _canonicalPaths[w] = wPath;
    }
    _currentTheme = StrandsThemeItem(
      themeHint: theme[0],
      spangram: theme[1],
      themeWords: chosen,
      grid: grid,
    );

    _selectedIndices.clear();
    _foundIndices.clear();
    _spangramIndices.clear();
    _foundThemeWords.clear();
    _foundPaths.clear();
    _isSolved = false;
    startSession();
    setState(() {});
  }

  void _onTileTap(int index) {
    if (_isSolved || _foundIndices.contains(index)) return;
    if (_selectedIndices.contains(index)) {
      setState(
        () => _selectedIndices.removeRange(
          _selectedIndices.indexOf(index),
          _selectedIndices.length,
        ),
      );
      return;
    }
    if (_selectedIndices.isNotEmpty) {
      final last = _selectedIndices.last;
      if ((last ~/ _cols - index ~/ _cols).abs() > 1 ||
          (last % _cols - index % _cols).abs() > 1) {
        showPuzzleHint('Choose a neighboring letter. Diagonals are allowed.');
        return;
      }
    }
    setState(() => _selectedIndices.add(index));
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _submitSelection() {
    final word = _selectedIndices
        .map((i) => _currentTheme.grid[i ~/ _cols][i % _cols])
        .join();

    if (_currentTheme.themeWords.contains(word) &&
        !_foundThemeWords.contains(word)) {
      final remaining = _currentTheme.themeWords
          .where((w) => w != word && !_foundThemeWords.contains(w))
          .toList();
      final isCanonical = _canonicalPaths[word] != null &&
          _listEquals(_selectedIndices, _canonicalPaths[word]!);
      if (!isCanonical &&
          remaining.isNotEmpty &&
          solveStrands(_currentTheme.grid, remaining, {
            ..._foundIndices,
            ..._selectedIndices,
          }) ==
          null) {
        showPuzzleHint(
          'Right word, but this route blocks another word. Try a different path.',
        );
        setState(() => _selectedIndices.clear());
        return;
      }
      setState(() {
        _foundPaths[word] = List<int>.from(_selectedIndices);
        _foundIndices.addAll(_selectedIndices);
        if (word == _currentTheme.spangram) {
          _spangramIndices.addAll(_selectedIndices);
        }
        _foundThemeWords.add(word);
        _selectedIndices.clear();
      });
      _showToast('Found $word! ⭐');
    } else {
      _showToast('Not a theme word');
      setState(() => _selectedIndices.clear());
    }

    if (_foundThemeWords.length == _currentTheme.themeWords.length) {
      setState(() => _isSolved = true);

      if (mode == GameMode.daily) {
        ref
            .read(statsServiceProvider)
            .recordResult(
              gameType: 'strands',
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

  void _showToast(String msg) {
    NeoToast.show(
      context,
      msg,
      icon: Icons.gesture_rounded,
      color: const Color(0xFF4ADE80),
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Map<String, dynamic> captureProgress() =>
      _isSolved ? {} : {'words': _foundThemeWords, 'paths': _foundPaths};
  @override
  void restoreProgress(Map<String, dynamic> d) {
    _foundThemeWords.addAll(List<String>.from(d['words']));
    for (final w in _foundThemeWords) {
      final path = List<int>.from(d['paths'][w]);
      _foundPaths[w] = path;
      _foundIndices.addAll(path);
      if (w == _currentTheme.spangram) _spangramIndices.addAll(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppScaffold(
      title: mode == GameMode.daily ? 'Strands' : 'Strands — Unlimited',
      showBackButton: true,
      actions: [
        IconButton(
          tooltip: 'Undo found word',
          icon: Icon(Icons.undo),
          onPressed: () {
            if (_isSolved || _foundThemeWords.isEmpty) return;
            setState(() {
              final word = _foundThemeWords.removeLast();
              final path = _foundPaths.remove(word)!;
              _foundIndices.removeAll(path);
              _spangramIndices.removeAll(path);
              _selectedIndices.clear();
            });
          },
        ),
        AppBarIconButton(
          icon: Icons.lightbulb_outline_rounded,
          tooltip: 'In-App Hints',
          onTap: () {
            final remaining = _currentTheme.themeWords
                .where((w) => !_foundThemeWords.contains(w))
                .toList();
            if (remaining.isEmpty) return;
            final w = remaining.first;
            final solution = solveStrands(
              _currentTheme.grid,
              remaining,
              _foundIndices,
            );
            final path = _canonicalPaths[w] ?? solution?[w];
            if (path == null) {
              showPuzzleHint(
                'Undo the last word to free a path, then try Hint again.',
              );
              return;
            }
            showPuzzleHint(
              '$w starts at row ${path.first ~/ 6 + 1}, column ${path.first % 6 + 1}. Follow neighboring letters.',
            );
            setState(() {
              _selectedIndices.clear();
              _selectedIndices.addAll(path);
            });
          },
        ),
      ],
      body: Column(
        children: [
          buildPracticeModeToggle(),
          Divider(height: 1),

          // Theme Header Banner
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                Text(
                  'FIND THE THEMED WORDS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${difficulty == 'Hard' ? 'Discover the hidden theme' : _currentTheme.themeHint} · ${_foundThemeWords.length}/${_currentTheme.themeWords.length}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          if (difficulty == 'Easy')
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                _currentTheme.themeWords
                    .where((w) => !_foundThemeWords.contains(w))
                    .join(' · '),
              ),
            ),
          SizedBox(height: 8),

          // Letter Grid
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 6 / 8,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black, width: 2.5),
                      boxShadow: const [
                        BoxShadow(color: Colors.black, offset: Offset(3.5, 3.5), blurRadius: 0),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    padding: const EdgeInsets.all(8),
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _cols,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                      ),
                      itemCount: _rows * _cols,
                      itemBuilder: (context, index) {
                        final r = index ~/ _cols;
                        final c = index % _cols;
                        final letter = _currentTheme.grid[r][c];

                        final isSelected = _selectedIndices.contains(index);
                        final isFound = _foundIndices.contains(index);
                        final isSpangram = _spangramIndices.contains(index);

                        Color tileBg = isDark ? const Color(0xFF1E293B) : Colors.white;

                        if (isSpangram) {
                          tileBg = AppColors.spangram;
                        } else if (isFound) {
                          tileBg = Theme.of(context).colorScheme.primary;
                        } else if (isSelected) {
                          tileBg = Theme.of(context).colorScheme.primary.withValues(alpha: 0.4);
                        }

                        return GestureDetector(
                          onTap: () => _onTileTap(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: tileBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.black, width: 2.0),
                              boxShadow: const [
                                BoxShadow(color: Colors.black, offset: Offset(1.5, 1.5), blurRadius: 0),
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
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Current Selection display & Submit / Next Puzzle
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _selectedIndices
                        .map((i) => _currentTheme.grid[i ~/ _cols][i % _cols])
                        .join(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                if (shouldShowNextButton(_isSolved))
                  ElevatedButton.icon(
                    icon: Icon(Icons.arrow_forward_rounded),
                    label: Text('Next Strands'),
                    onPressed: nextPuzzle,
                  )
                else
                  ElevatedButton(
                    onPressed: _selectedIndices.isNotEmpty
                        ? _submitSelection
                        : null,
                    child: Text('Submit Word'),
                  ),
              ],
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
