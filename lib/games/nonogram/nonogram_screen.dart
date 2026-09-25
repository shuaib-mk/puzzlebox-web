import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'nonogram_generator.dart';
import '../../core/services/stats_service.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/game_mode_toggle.dart';
import '../../core/mixins/practice_mode_mixin.dart';

/// Cell states: 0 = empty, 1 = filled, 2 = marked (ruled out).
class NonogramScreen extends ConsumerStatefulWidget {
  const NonogramScreen({super.key});
  @override
  ConsumerState<NonogramScreen> createState() => _NonogramScreenState();
}

class _NonogramScreenState extends ConsumerState<NonogramScreen>
    with PracticeModeMixin {
  @override
  String get gameType => 'nonogram';

  NonogramPuzzle? _puzzle;
  List<int> _grid = [];
  final List<List<int>> _history = [];
  bool _loading = true;
  bool _generationFailed = false;
  bool _isSolved = false;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    initPracticeMode();
    _loadPuzzle();
  }

  @override
  void onPracticeModeChanged(GameMode mode) => _loadPuzzle();
  @override
  void loadDailyPuzzle() => _loadPuzzle();
  @override
  void loadPracticePuzzle() => _loadPuzzle();

  Future<void> _loadPuzzle() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _generationFailed = false;
    });
    try {
      final puzzle = await compute(generateNonogram, puzzleRequest);
      if (!mounted || request != _request) return;
      setState(() {
        _puzzle = puzzle;
        _grid = List<int>.filled(puzzle.size * puzzle.size, 0);
        _history.clear();
        _isSolved = false;
        _loading = false;
      });
      startSession();
    } catch (_) {
      if (mounted && request == _request) {
        setState(() => _generationFailed = true);
        showPuzzleHint('Generation failed. Tap Next to retry.');
      }
    }
  }

  void _remember() => _history.add(List<int>.of(_grid));

  void _undo() {
    if (_history.isEmpty || _isSolved) return;
    setState(() => _grid = _history.removeLast());
  }

  void _onCellTap(int index) {
    if (_isSolved || _puzzle == null) return;
    _remember();
    setState(() {
      _grid[index] = (_grid[index] + 1) % 3;
      _checkWin();
    });
  }

  void _onCellLongPress(int index) {
    if (_isSolved || _puzzle == null) return;
    _remember();
    setState(() {
      _grid[index] = _grid[index] == 2 ? 0 : 2;
      _checkWin();
    });
  }

  void _checkWin() {
    final puzzle = _puzzle;
    if (puzzle == null) return;
    for (var i = 0; i < _grid.length; i++) {
      final filled = _grid[i] == 1 ? 1 : 0;
      if (filled != puzzle.solution[i]) return;
    }
    setState(() => _isSolved = true);
    if (mode == GameMode.daily) {
      ref
          .read(statsServiceProvider)
          .recordResult(
            gameType: 'nonogram',
            todayKey: dailyDateKey,
            won: true,
          );
      finishPuzzle();
    } else {
      recordPracticeWin();
    }
  }

  void _hint() {
    final puzzle = _puzzle;
    if (_loading || _isSolved || puzzle == null) return;
    for (var i = 0; i < _grid.length; i++) {
      final filled = _grid[i] == 1 ? 1 : 0;
      if (filled != puzzle.solution[i]) {
        _remember();
        setState(() {
          _grid[i] = puzzle.solution[i] == 1 ? 1 : 2;
          _checkWin();
        });
        final r = i ~/ puzzle.size + 1;
        final c = i % puzzle.size + 1;
        showPuzzleHint('Row $r, column $c revealed.');
        return;
      }
    }
  }

  bool _rowDone(int r) {
    final puzzle = _puzzle!;
    final line = [
      for (var c = 0; c < puzzle.size; c++)
        _grid[r * puzzle.size + c] == 1 ? 1 : 0,
    ];
    return listEquals(clueFor(line), puzzle.rowClues[r]);
  }

  bool _colDone(int c) {
    final puzzle = _puzzle!;
    final line = [
      for (var r = 0; r < puzzle.size; r++)
        _grid[r * puzzle.size + c] == 1 ? 1 : 0,
    ];
    return listEquals(clueFor(line), puzzle.colClues[c]);
  }

  @override
  Map<String, dynamic> captureProgress() =>
      (_loading || _isSolved || _puzzle == null) ? {} : {'grid': _grid};
  @override
  void restoreProgress(Map<String, dynamic> d) {
    final saved = List<int>.from(d['grid'] as List);
    if (saved.length == _grid.length) _grid = saved;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppScaffold(
      title: mode == GameMode.daily ? 'Nonogram' : 'Nonogram — Unlimited',
      showBackButton: true,
      actions: [
        IconButton(
          onPressed: _undo,
          icon: const Icon(Icons.undo),
          tooltip: 'Undo',
        ),
        IconButton(
          onPressed: _hint,
          icon: const Icon(Icons.lightbulb_outline),
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
                                onPressed: _loadPuzzle,
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
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tap to fill · long-press to mark ✕'),
                      if (_isSolved)
                        Text(
                          'Solved!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final puzzle = _puzzle!;
                        final maxRowClueLen = puzzle.rowClues
                            .map((c) => c.length)
                            .reduce((a, b) => a > b ? a : b);
                        final maxColClueLen = puzzle.colClues
                            .map((c) => c.length)
                            .reduce((a, b) => a > b ? a : b);
                        final leftWidth = (16.0 * maxRowClueLen + 12).clamp(
                          32.0,
                          96.0,
                        );
                        final topHeight = (14.0 * maxColClueLen + 12).clamp(
                          32.0,
                          88.0,
                        );
                        final cell =
                            ((constraints.maxWidth - leftWidth) /
                                    puzzle.size)
                                .clamp(18.0, 46.0);
                        final gridHeight =
                            constraints.maxHeight - topHeight;
                        final cellFromHeight =
                            (gridHeight / puzzle.size).clamp(18.0, 46.0);
                        final size = cell < cellFromHeight
                            ? cell
                            : cellFromHeight;
                        return SingleChildScrollView(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  SizedBox(width: leftWidth, height: topHeight),
                                  for (var c = 0; c < puzzle.size; c++)
                                    SizedBox(
                                      width: size,
                                      height: topHeight,
                                      child: Center(
                                        child: Text(
                                          puzzle.colClues[c].join('\n'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            height: 1.15,
                                            color: _colDone(c)
                                                ? colors.primary
                                                : colors.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              for (var r = 0; r < puzzle.size; r++)
                                Row(
                                  children: [
                                    SizedBox(
                                      width: leftWidth,
                                      height: size,
                                      child: Center(
                                        child: Text(
                                          puzzle.rowClues[r].join(' '),
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: _rowDone(r)
                                                ? colors.primary
                                                : colors.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ),
                                    for (var c = 0; c < puzzle.size; c++)
                                      _NonogramCell(
                                        key: ValueKey('nonogram_${r}_$c'),
                                        size: size,
                                        rightBorder: (c + 1) % 5 == 0 &&
                                            c != puzzle.size - 1,
                                        bottomBorder: (r + 1) % 5 == 0 &&
                                            r != puzzle.size - 1,
                                        state: _grid[r * puzzle.size + c],
                                        onTap: () =>
                                            _onCellTap(r * puzzle.size + c),
                                        onLongPress: () => _onCellLongPress(
                                          r * puzzle.size + c,
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (shouldShowNextButton(_isSolved))
                        ElevatedButton.icon(
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text('Next Nonogram'),
                          onPressed: nextPuzzle,
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _NonogramCell extends StatelessWidget {
  final double size;
  final int state;
  final bool rightBorder;
  final bool bottomBorder;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _NonogramCell({
    super.key,
    required this.size,
    required this.state,
    required this.rightBorder,
    required this.bottomBorder,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 120),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: state == 1
              ? colors.primary
              : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white),
          border: Border(
            right: BorderSide(
              color: Colors.black,
              width: rightBorder ? 2.5 : 0.8,
            ),
            bottom: BorderSide(
              color: Colors.black,
              width: bottomBorder ? 2.5 : 0.8,
            ),
            left: const BorderSide(color: Colors.black, width: 0.5),
            top: const BorderSide(color: Colors.black, width: 0.5),
          ),
        ),
        child: state == 2
            ? Center(
                child: Text(
                  '✕',
                  style: TextStyle(
                    fontSize: size * 0.5,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
