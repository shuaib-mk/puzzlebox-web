import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cages_generator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/stats_service.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/game_mode_toggle.dart';
import '../../core/mixins/practice_mode_mixin.dart';

const _cageAccents = [
  Color(0xFF2458A6),
  Color(0xFF3D7C16),
  Color(0xFFAD4930),
  Color(0xFF7048A5),
  Color(0xFF157A6E),
  Color(0xFFA96708),
  Color(0xFFB84562),
  Color(0xFF286CB0),
];

class CagesScreen extends ConsumerStatefulWidget {
  const CagesScreen({super.key});
  @override
  ConsumerState<CagesScreen> createState() => _CagesScreenState();
}

class _CagesScreenState extends ConsumerState<CagesScreen>
    with PracticeModeMixin {
  @override
  String get gameType => 'cages';

  CagesPuzzle? _puzzle;
  List<int> _user = [];
  List<int> _cageOf = [];
  int? _selected;
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
      final puzzle = await compute(generateCages, puzzleRequest);
      if (!mounted || request != _request) return;
      final cageOf = List<int>.filled(puzzle.size * puzzle.size, 0);
      for (var id = 0; id < puzzle.cages.length; id++) {
        for (final cell in puzzle.cages[id].cells) {
          cageOf[cell] = id;
        }
      }
      setState(() {
        _puzzle = puzzle;
        _cageOf = cageOf;
        _user = List<int>.filled(puzzle.size * puzzle.size, 0);
        _selected = null;
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
    if (_isSolved) return;
    setState(() => _selected = index);
  }

  void _onNumberTap(int value) {
    if (_isSolved || _selected == null) return;
    _remember();
    setState(() {
      _user[_selected!] = _user[_selected!] == value ? 0 : value;
      _checkWin();
    });
  }

  void _erase() {
    if (_isSolved || _selected == null || _user[_selected!] == 0) return;
    _remember();
    setState(() => _user[_selected!] = 0);
  }

  void _checkWin() {
    final puzzle = _puzzle;
    if (puzzle == null) return;
    for (var i = 0; i < _user.length; i++) {
      if (_user[i] != puzzle.solution[i]) return;
    }
    setState(() {
      _isSolved = true;
      _selected = null;
    });
    if (mode == GameMode.daily) {
      ref
          .read(statsServiceProvider)
          .recordResult(gameType: 'cages', todayKey: dailyDateKey, won: true);
      finishPuzzle();
    } else {
      recordPracticeWin();
    }
  }

  void _hint() {
    final puzzle = _puzzle;
    if (_loading || _isSolved || puzzle == null) return;
    for (var i = 0; i < _user.length; i++) {
      if (_user[i] != puzzle.solution[i]) {
        _remember();
        setState(() {
          _user[i] = puzzle.solution[i];
          _selected = i;
          _checkWin();
        });
        final n = puzzle.size;
        showPuzzleHint('Row ${i ~/ n + 1}, column ${i % n + 1} revealed.');
        return;
      }
    }
  }

  bool _hasConflict(int index) {
    final puzzle = _puzzle;
    if (puzzle == null) return false;
    final n = puzzle.size;
    final r = index ~/ n, c = index % n;
    final val = _user[index];
    if (val == 0) return false;
    for (var cc = 0; cc < n; cc++) {
      if (cc != c && _user[r * n + cc] == val) return true;
    }
    for (var rr = 0; rr < n; rr++) {
      if (rr != r && _user[rr * n + c] == val) return true;
    }
    return false;
  }

  bool _cageMismatch(int cageId) {
    final cage = _puzzle!.cages[cageId];
    final values = [for (final cell in cage.cells) _user[cell]];
    if (values.contains(0)) return false;
    return !cageSatisfied(cage.op, cage.target, values);
  }

  String _cageLabel(Cage cage) =>
      cage.op == '=' ? '${cage.target}' : '${cage.target}${cage.op}';

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
    return AppScaffold(
      title: mode == GameMode.daily ? 'Cages' : 'Cages — Unlimited',
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
                          'No repeats in any row or column',
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
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _puzzle!.size,
                            ),
                            itemCount: _puzzle!.size * _puzzle!.size,
                            itemBuilder: (context, index) {
                              final puzzle = _puzzle!;
                              final n = puzzle.size;
                              final r = index ~/ n, c = index % n;
                              final cageId = _cageOf[index];
                              final cage = puzzle.cages[cageId];
                              final accent =
                                  _cageAccents[cageId % _cageAccents.length];
                              final isLabelCell =
                                  cage.cells.reduce((a, b) => a < b ? a : b) ==
                                  index;
                              final neighborRight =
                                  c + 1 < n ? _cageOf[r * n + c + 1] : -1;
                              final neighborBottom =
                                  r + 1 < n ? _cageOf[(r + 1) * n + c] : -1;
                              final isSelected = _selected == index;
                              final isConflict = _hasConflict(index);
                              final isCageBad = _cageMismatch(cageId);
                              return GestureDetector(
                                key: ValueKey('cages_${r}_$c'),
                                onTap: () => _onCellTap(index),
                                child: Container(
                                  margin: const EdgeInsets.all(1),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colors.primary.withValues(alpha: 0.35)
                                        : (isConflict || isCageBad)
                                        ? colors.errorContainer
                                        : Colors.transparent,
                                    border: Border(
                                      right: BorderSide(
                                        color: neighborRight != cageId
                                            ? Colors.black
                                            : Colors.black38,
                                        width: neighborRight != cageId ? 2.5 : .5,
                                      ),
                                      bottom: BorderSide(
                                        color: neighborBottom != cageId
                                            ? Colors.black
                                            : Colors.black38,
                                        width: neighborBottom != cageId
                                            ? 2.5
                                            : .5,
                                      ),
                                      left: BorderSide(
                                        color: c == 0
                                            ? Colors.black
                                            : Colors.black38,
                                        width: c == 0 ? 2.5 : .5,
                                      ),
                                      top: BorderSide(
                                        color: r == 0
                                            ? Colors.black
                                            : Colors.black38,
                                        width: r == 0 ? 2.5 : .5,
                                      ),
                                    ),
                                  ),
                                  child: Stack(
                                  children: [
                                    if (isLabelCell)
                                      Positioned(
                                        top: 2,
                                        left: 4,
                                        child: Text(
                                          _cageLabel(cage),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: accent,
                                          ),
                                        ),
                                      ),
                                    Center(
                                      child: _user[index] == 0
                                          ? null
                                          : Text(
                                              '${_user[index]}',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w800,
                                                color: (isConflict || isCageBad)
                                                    ? AppColors.error
                                                    : colors.onSurface,
                                              ),
                                            ),
                                    ),
                                  ],
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(onPressed: _erase, child: const Text('Erase')),
                    if (shouldShowNextButton(_isSolved))
                      ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('Next Cages'),
                        onPressed: nextPuzzle,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      _puzzle!.size,
                      (i) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: InkWell(
                            key: ValueKey('cages_number_${i + 1}'),
                            onTap: () => _onNumberTap(i + 1),
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: colors.outlineVariant),
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: colors.onSurface,
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
