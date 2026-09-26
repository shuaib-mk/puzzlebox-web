import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'binary_generator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/stats_service.dart';
import '../../core/services/app_feedback_service.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/game_mode_toggle.dart';
import '../../core/mixins/practice_mode_mixin.dart';

class BinaryScreen extends ConsumerStatefulWidget {
  const BinaryScreen({super.key});
  @override
  ConsumerState<BinaryScreen> createState() => _BinaryScreenState();
}

class _BinaryScreenState extends ConsumerState<BinaryScreen>
    with PracticeModeMixin {
  @override
  String get gameType => 'binary';

  BinaryPuzzle? _puzzle;
  List<int> _user = [];
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
      final puzzle = await compute(generateBinary, puzzleRequest);
      if (!mounted || request != _request) return;
      setState(() {
        _puzzle = puzzle;
        _user = List<int>.of(puzzle.givens);
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

  void _remember() => _history.add(List<int>.of(_user));

  void _undo() {
    if (_history.isEmpty || _isSolved) return;
    setState(() => _user = _history.removeLast());
  }

  void _onCellTap(int index) {
    final puzzle = _puzzle;
    if (_isSolved || puzzle == null || puzzle.givens[index] != -1) return;
    AppFeedbackService.tap(ref);
    _remember();
    setState(() {
      _user[index] = _user[index] == -1 ? 0 : (_user[index] == 0 ? 1 : -1);
      _checkWin();
    });
  }

  void _checkWin() {
    final puzzle = _puzzle;
    if (puzzle == null) return;
    for (var i = 0; i < _user.length; i++) {
      if (_user[i] != puzzle.solution[i]) return;
    }
    setState(() => _isSolved = true);
    if (mode == GameMode.daily) {
      ref
          .read(statsServiceProvider)
          .recordResult(gameType: 'binary', todayKey: dailyDateKey, won: true);
      finishPuzzle();
    } else {
      recordPracticeWin();
    }
  }

  void _hint() {
    final puzzle = _puzzle;
    if (_loading || _isSolved || puzzle == null) return;
    for (var i = 0; i < _user.length; i++) {
      if (puzzle.givens[i] == -1 && _user[i] != puzzle.solution[i]) {
        _remember();
        setState(() {
          _user[i] = puzzle.solution[i];
          _checkWin();
        });
        final r = i ~/ puzzle.size + 1;
        final c = i % puzzle.size + 1;
        showPuzzleHint('Row $r, column $c revealed.');
        return;
      }
    }
  }

  Set<int> _conflicts() {
    final puzzle = _puzzle;
    if (puzzle == null) return {};
    final n = puzzle.size;
    final half = n ~/ 2;
    final bad = <int>{};
    List<int> row(int r) => [for (var c = 0; c < n; c++) _user[r * n + c]];
    List<int> col(int c) => [for (var r = 0; r < n; r++) _user[r * n + c]];
    void scanLine(List<int> line, bool isRow, int idx) {
      var zeros = 0, ones = 0;
      for (final v in line) {
        if (v == 0) zeros++;
        if (v == 1) ones++;
      }
      for (var i = 0; i < n; i++) {
        final over = (line[i] == 0 && zeros > half) ||
            (line[i] == 1 && ones > half);
        if (over) bad.add(isRow ? idx * n + i : i * n + idx);
      }
      for (var i = 0; i + 2 < n; i++) {
        if (line[i] != -1 && line[i] == line[i + 1] && line[i + 1] == line[i + 2]) {
          for (var k = i; k < i + 3; k++) {
            bad.add(isRow ? idx * n + k : k * n + idx);
          }
        }
      }
    }

    for (var r = 0; r < n; r++) {
      scanLine(row(r), true, r);
    }
    for (var c = 0; c < n; c++) {
      scanLine(col(c), false, c);
    }
    for (var i = 0; i < n; i++) {
      final ri = row(i);
      if (ri.contains(-1)) continue;
      for (var j = i + 1; j < n; j++) {
        final rj = row(j);
        if (rj.contains(-1) || !listIntEquals(ri, rj)) continue;
        for (var c = 0; c < n; c++) {
          bad.add(i * n + c);
          bad.add(j * n + c);
        }
      }
    }
    for (var i = 0; i < n; i++) {
      final ci = col(i);
      if (ci.contains(-1)) continue;
      for (var j = i + 1; j < n; j++) {
        final cj = col(j);
        if (cj.contains(-1) || !listIntEquals(ci, cj)) continue;
        for (var r = 0; r < n; r++) {
          bad.add(r * n + i);
          bad.add(r * n + j);
        }
      }
    }
    return bad;
  }

  @override
  Map<String, dynamic> captureProgress() =>
      (_loading || _isSolved || _puzzle == null) ? {} : {'grid': _user};
  @override
  void restoreProgress(Map<String, dynamic> d) {
    final saved = List<int>.from(d['grid'] as List);
    if (saved.length == _user.length) _user = saved;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final conflicts = _loading ? <int>{} : _conflicts();
    return AppScaffold(
      title: mode == GameMode.daily ? 'Binary' : 'Binary — Unlimited',
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
                      const Expanded(
                        child: Text(
                          'Equal 0s and 1s · no triples · no twins',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
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
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _puzzle!.size,
                            ),
                            itemCount: _puzzle!.size * _puzzle!.size,
                            itemBuilder: (context, index) {
                              final puzzle = _puzzle!;
                              final n = puzzle.size;
                              final r = index ~/ n, c = index % n;
                              final isGiven = puzzle.givens[index] != -1;
                              final value = _user[index];
                              final isConflict = conflicts.contains(index);
                              final rightBorder =
                                  (c + 1) % (n ~/ 2) == 0 && c != n - 1;
                              final bottomBorder =
                                  (r + 1) % (n ~/ 2) == 0 && r != n - 1;
                              return GestureDetector(
                                key: ValueKey('binary_${r}_$c'),
                                onTap: () => _onCellTap(index),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 140),
                                  decoration: BoxDecoration(
                                    color: isConflict
                                        ? colors.errorContainer
                                        : (value != -1 ? colors.primary.withValues(alpha: 0.3) : Colors.transparent),
                                    border: Border(
                                      right: BorderSide(
                                        color: Colors.black,
                                        width: rightBorder ? 2.5 : 0.8,
                                      ),
                                      bottom: BorderSide(
                                        color: Colors.black,
                                        width: bottomBorder ? 2.5 : 0.8,
                                      ),
                                      left: const BorderSide(
                                        color: Colors.black,
                                        width: 0.5,
                                      ),
                                      top: const BorderSide(
                                        color: Colors.black,
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: Center(
                                    child: value == -1
                                        ? null
                                        : Text(
                                            '$value',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                              color: isConflict
                                                  ? AppColors.error
                                                  : isGiven
                                                  ? colors.onSurface
                                                  : colors.primary,
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (shouldShowNextButton(_isSolved))
                        ElevatedButton.icon(
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text('Next Binary'),
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
