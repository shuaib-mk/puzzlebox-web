import 'dart:async';
import 'package:flutter/foundation.dart';
import 'sudoku_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/stats_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/game_mode_toggle.dart';
import '../../core/mixins/practice_mode_mixin.dart';

class SudokuScreen extends ConsumerStatefulWidget {
  const SudokuScreen({super.key});

  @override
  ConsumerState<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends ConsumerState<SudokuScreen>
    with PracticeModeMixin {
  @override
  String get gameType => 'sudoku';

  int _selectedRow = 0;
  int _selectedCol = 0;
  bool _pencilMode = false;
  Timer? _timer;
  int _seconds = 0;
  bool _isSolved = false;

  late List<List<int>> _initialGrid;
  late List<List<int>> _userGrid;
  late List<List<Set<int>>> _pencilGrid;

  List<int> _solution = [];
  bool _loading = true;
  bool _generationFailed = false;
  int _request = 0;
  final List<(List<List<int>>, List<List<Set<int>>>)> _history = [];
  @override
  void initState() {
    super.initState();
    initPracticeMode();
    _loadPuzzle();
  }

  @override
  void onPracticeModeChanged(GameMode mode) {
    _loadPuzzle();
  }

  @override
  void loadDailyPuzzle() {
    _loadPuzzle();
  }

  @override
  void loadPracticePuzzle() {
    _loadPuzzle();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadPuzzle() async {
    final request = ++_request;
    _timer?.cancel();
    setState(() {
      _loading = true;
      _generationFailed = false;
    });
    try {
      final puzzle = await compute(generateSudoku, puzzleRequest);
      if (!mounted || request != _request) return;
      setState(() {
        _solution = puzzle.solution;
        _initialGrid = List.generate(
          9,
          (r) => puzzle.givens.sublist(r * 9, r * 9 + 9),
        );
        _userGrid = _initialGrid.map((r) => List<int>.from(r)).toList();
        _pencilGrid = List.generate(9, (_) => List.generate(9, (_) => <int>{}));
        _history.clear();
        _seconds = 0;
        _isSolved = false;
        _selectedRow = 0;
        _selectedCol = 0;
        _pencilMode = false;
        _loading = false;
      });
      startSession();
      _startTimer();
    } catch (_) {
      if (mounted && request == _request) {
        setState(() => _generationFailed = true);
        showPuzzleHint('Generation failed. Tap Next to retry.');
      }
    }
  }

  void _remember() => _history.add((
    _userGrid.map((r) => List<int>.from(r)).toList(),
    _pencilGrid.map((r) => r.map((n) => Set<int>.from(n)).toList()).toList(),
  ));
  void _undo() {
    if (_history.isEmpty || _isSolved) return;
    setState(() {
      final previous = _history.removeLast();
      _userGrid = previous.$1;
      _pencilGrid = previous.$2;
    });
  }

  void _hint() {
    if (_loading || _isSolved) return;
    final flat = _userGrid.expand((r) => r).toList();
    var cell = flat.indexWhere((n) => n == 0);
    for (var i = 0; i < 81; i++) {
      if (flat[i] != 0 && flat[i] != _solution[i]) {
        showPuzzleHint(
          'Check row ${i ~/ 9 + 1}, column ${i % 9 + 1}: that entry prevents the solution.',
        );
        setState(() {
          _selectedRow = i ~/ 9;
          _selectedCol = i % 9;
        });
        return;
      }
      if (flat[i] == 0 && candidates(flat, i).length == 1) {
        cell = i;
        break;
      }
    }
    if (cell < 0) return;
    final options = candidates(flat, cell);
    showPuzzleHint(
      options.length == 1
          ? 'Row ${cell ~/ 9 + 1}, column ${cell % 9 + 1}: only ${_solution[cell]} fits its row, column and box.'
          : 'A solution reveal: row ${cell ~/ 9 + 1}, column ${cell % 9 + 1} is ${_solution[cell]}.',
    );
    setState(() {
      _selectedRow = cell ~/ 9;
      _selectedCol = cell % 9;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      if (mounted &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        setState(() => _seconds++);
      }
    });
  }

  void _onNumberTap(int num) {
    if (_initialGrid[_selectedRow][_selectedCol] != 0 || _isSolved) return;
    if (_pencilMode && _userGrid[_selectedRow][_selectedCol] != 0) return;
    _remember();
    setState(() {
      if (_pencilMode) {
        if (_pencilGrid[_selectedRow][_selectedCol].contains(num)) {
          _pencilGrid[_selectedRow][_selectedCol].remove(num);
        } else {
          _pencilGrid[_selectedRow][_selectedCol].add(num);
        }
      } else {
        _userGrid[_selectedRow][_selectedCol] = num;
        _pencilGrid[_selectedRow][_selectedCol].clear();
        for (var r = 0; r < 9; r++) {
          for (var c = 0; c < 9; c++) {
            if (r == _selectedRow ||
                c == _selectedCol ||
                (r ~/ 3 == _selectedRow ~/ 3 && c ~/ 3 == _selectedCol ~/ 3)) {
              _pencilGrid[r][c].remove(num);
            }
          }
        }
        _checkWin();
      }
    });
  }

  void _erase() {
    if (_initialGrid[_selectedRow][_selectedCol] != 0 || _isSolved) return;
    _remember();
    setState(() {
      _userGrid[_selectedRow][_selectedCol] = 0;
      _pencilGrid[_selectedRow][_selectedCol].clear();
    });
  }

  void _checkWin() {
    bool win = true;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (_userGrid[r][c] == 0 || _hasConflict(r, c)) {
          win = false;
        }
      }
    }
    if (win) {
      _timer?.cancel();
      setState(() => _isSolved = true);

      if (mode == GameMode.daily) {
        ref
            .read(statsServiceProvider)
            .recordResult(
              gameType: 'sudoku',
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

  bool _hasConflict(int row, int col) {
    final val = _userGrid[row][col];
    if (val == 0) return false;

    for (int c = 0; c < 9; c++) {
      if (c != col && _userGrid[row][c] == val) return true;
    }
    for (int r = 0; r < 9; r++) {
      if (r != row && _userGrid[r][col] == val) return true;
    }
    final startR = (row ~/ 3) * 3;
    final startC = (col ~/ 3) * 3;
    for (int r = startR; r < startR + 3; r++) {
      for (int c = startC; c < startC + 3; c++) {
        if ((r != row || c != col) && _userGrid[r][c] == val) return true;
      }
    }
    return false;
  }

  @override
  Map<String, dynamic> captureProgress() => _loading || _isSolved
      ? {}
      : {
          'grid': _userGrid,
          'notes': _pencilGrid
              .map((r) => r.map((n) => n.toList()).toList())
              .toList(),
          'seconds': _seconds,
        };
  @override
  void restoreProgress(Map<String, dynamic> d) {
    _userGrid = (d['grid'] as List).map((r) => List<int>.from(r)).toList();
    _pencilGrid = (d['notes'] as List)
        .map((r) => (r as List).map((n) => Set<int>.from(n)).toList())
        .toList();
    _seconds = d['seconds'] as int;
  }

  @override
  Widget build(BuildContext context) {
    final timerStr =
        '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}';

    return AppScaffold(
      title: mode == GameMode.daily ? 'Sudoku' : 'Sudoku — Unlimited',
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
                Divider(height: 1),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Wrap(
                    spacing: 12,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Text('Unique solution'),
                      Text(
                        'Time $timerStr',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1),

                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black, width: 2.5),
                            boxShadow: const [
                              BoxShadow(color: Colors.black, offset: Offset(3.5, 3.5), blurRadius: 0),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 9,
                            ),
                            itemCount: 81,
                            itemBuilder: (context, index) {
                              final r = index ~/ 9;
                              final c = index % 9;
                              final isInitial = _initialGrid[r][c] != 0;
                              final val = _userGrid[r][c];
                              final isSelected = r == _selectedRow && c == _selectedCol;
                              final isConflict = _hasConflict(r, c);
                              final notes = _pencilGrid[r][c];

                              final borderRight = (c + 1) % 3 == 0 && c != 8 ? 2.5 : 0.8;
                              final borderBottom = (r + 1) % 3 == 0 && r != 8 ? 2.5 : 0.8;

                              return GestureDetector(
                                key: ValueKey('sudoku_${r}_$c'),
                                onTap: () => setState(() {
                                  _selectedRow = r;
                                  _selectedCol = c;
                                }),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : isConflict
                                            ? Theme.of(context).colorScheme.errorContainer
                                            : Colors.transparent,
                                    border: Border(
                                      right: BorderSide(color: Colors.black, width: borderRight),
                                      bottom: BorderSide(color: Colors.black, width: borderBottom),
                                      left: const BorderSide(color: Colors.black, width: 0.4),
                                      top: const BorderSide(color: Colors.black, width: 0.4),
                                    ),
                                  ),
                                  child: Center(
                                    child: val != 0
                                        ? Text(
                                            '$val',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w900,
                                              color: isInitial
                                                  ? (isSelected ? Colors.black : Theme.of(context).colorScheme.onSurface)
                                                  : isConflict
                                                      ? AppColors.error
                                                      : (isSelected ? Colors.black : Theme.of(context).colorScheme.primary),
                                            ),
                                          )
                                        : notes.isNotEmpty
                                            ? Wrap(
                                                children: notes
                                                    .map(
                                                      (n) => Text(
                                                        '$n ',
                                                        style: const TextStyle(
                                                          fontSize: 8,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                              )
                                            : null,
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

                // Control Action Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _pencilMode = !_pencilMode),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: _pencilMode
                                  ? Theme.of(context).colorScheme.primary
                                  : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black, width: 2.0),
                              boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2.5, 2.5), blurRadius: 0)],
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.edit_note, size: 20, color: Colors.black),
                                SizedBox(width: 4),
                                Text('Pencil', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.black)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: _undo,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black, width: 2.0),
                              boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2.5, 2.5), blurRadius: 0)],
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.undo, size: 18, color: Colors.black),
                                SizedBox(width: 4),
                                Text('Undo', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.black)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: _erase,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black, width: 2.0),
                              boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2.5, 2.5), blurRadius: 0)],
                            ),
                            child: const Text('Erase', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.black)),
                          ),
                        ),
                        if (shouldShowNextButton(_isSolved)) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: nextPuzzle,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.black, width: 2.0),
                                boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2.5, 2.5), blurRadius: 0)],
                              ),
                              child: Row(
                                children: const [
                                  Text('Next', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.black)),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.black),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Number keypad
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        9,
                        (i) => Container(
                          width: 36,
                          margin: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: InkWell(
                            key: ValueKey('sudoku_number_${i + 1}'),
                            onTap: () => _onNumberTap(i + 1),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.black, width: 2.0),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }
}
