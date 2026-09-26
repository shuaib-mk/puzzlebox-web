import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/mixins/practice_mode_mixin.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/game_mode_toggle.dart';
import '../../core/services/stats_service.dart';
import 'crossword_generator.dart';

class CrosswordScreen extends ConsumerStatefulWidget {
  final bool mini;
  const CrosswordScreen({super.key, this.mini = false});
  @override
  ConsumerState<CrosswordScreen> createState() => _CrosswordState();
}

class _CrosswordState extends ConsumerState<CrosswordScreen>
    with PracticeModeMixin {
  @override
  String get gameType => widget.mini ? 'mini_crossword' : 'crossword';
  late CrosswordPuzzle _puzzle;
  late List<String> _letters;
  final List<List<String>> _history = [];
  int _selected = 0, _seconds = 0;
  late CrosswordEntry _entry;
  bool _solved = false, _checked = false;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    initPracticeMode();
    _load();
  }

  @override
  void onPracticeModeChanged(GameMode mode) => _load();
  void _load() {
    _timer?.cancel();
    _puzzle = CrosswordGenerator().generate(puzzleRequest);
    _letters = List.filled(_puzzle.solution.length, '');
    _entry = _puzzle.entries.first;
    _selected = _entry.cells(_puzzle.size).first;
    _history.clear();
    _seconds = 0;
    _solved = false;
    _checked = false;
    if (difficulty == 'Easy') {
      for (final e in _puzzle.entries) {
        final i = e.cells(_puzzle.size).first;
        _letters[i] = _puzzle.solution[i];
      }
    }
    startSession();
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      if (mounted &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        setState(() => _seconds++);
      }
    });
  }

  void _key(String value) {
    if (_solved) return;
    setState(() {
      _history.add(List.from(_letters));
      _letters[_selected] = value;
      final cells = _entry.cells(_puzzle.size);
      final i = cells.indexOf(_selected);
      if (value.isNotEmpty && i + 1 < cells.length) _selected = cells[i + 1];
    });
    _checkWin();
  }

  void _checkWin() {
    if (_solved) return;
    if (!_puzzle.solution.asMap().entries.every(
      (e) => e.value == '#' || _letters[e.key] == e.value,
    )) {
      return;
    }
    setState(() => _solved = true);
    _timer?.cancel();
    if (mode == GameMode.daily) {
      ref
          .read(statsServiceProvider)
          .recordResult(gameType: gameType, todayKey: dailyDateKey, won: true);
    }
    finishPuzzle();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Map<String, dynamic> captureProgress() =>
      _solved ? {} : {'letters': _letters, 'seconds': _seconds};
  @override
  void restoreProgress(Map<String, dynamic> d) {
    _letters = List<String>.from(d['letters']);
    _seconds = d['seconds'] as int;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = _entry.cells(_puzzle.size);
    return AppScaffold(
      title: widget.mini ? 'The Mini' : 'Crossword',
      showBackButton: true,
      body: Column(
        children: [
          buildPracticeModeToggle(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_puzzle.entries.length} clues · ${_seconds ~/ 60}:${(_seconds % 60).toString().padLeft(2, "0")}',
                  ),
                ),
                IconButton(
                  tooltip: 'Undo',
                  icon: Icon(Icons.undo),
                  onPressed: _history.isEmpty || _solved
                      ? null
                      : () => setState(() => _letters = _history.removeLast()),
                ),
                IconButton(
                  tooltip: 'Check letters',
                  icon: Icon(Icons.fact_check_outlined),
                  onPressed: () => setState(() => _checked = !_checked),
                ),
                IconButton(
                  tooltip: 'Reveal selected letter',
                  icon: Icon(Icons.lightbulb_outline),
                  onPressed: () {
                    showPuzzleHint(
                      '${_entry.clue}: selected letter is ${_puzzle.solution[_selected]}.',
                    );
                    _key(_puzzle.solution[_selected]);
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E293B)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black, width: 2.2),
                boxShadow: const [
                  BoxShadow(color: Colors.black, offset: Offset(2.5, 2.5), blurRadius: 0),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<CrosswordEntry>(
                  value: _entry,
                  isExpanded: true,
                  dropdownColor: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.black),
                  style: TextStyle(
                    fontFamily: 'PuzzleSans',
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                  items: _puzzle.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(
                            '${e.number}${e.across ? "A" : "D"}. ${e.clue} (${e.answer.length})',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (e) {
                    if (e != null) {
                      setState(() {
                        _entry = e;
                        _selected = e.cells(_puzzle.size).first;
                      });
                    }
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: _puzzle.size / (_letters.length ~/ _puzzle.size),
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
                  padding: const EdgeInsets.all(6),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _letters.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _puzzle.size,
                      crossAxisSpacing: 3,
                      mainAxisSpacing: 3,
                    ),
                    itemBuilder: (context, i) {
                      if (_puzzle.solution[i] == '#') {
                        return DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }
                      final starts = _puzzle.entries
                          .where((e) => e.cells(_puzzle.size).first == i)
                          .toList();
                      final wrong =
                          _checked &&
                          _letters[i].isNotEmpty &&
                          _letters[i] != _puzzle.solution[i];
                      return InkWell(
                        key: ValueKey('crossword_cell_$i'),
                        onTap: () => setState(() {
                          final choices = _puzzle.entries
                              .where((e) => e.cells(_puzzle.size).contains(i))
                              .toList();
                          if (i == _selected && choices.length > 1) {
                            _entry = choices.firstWhere((e) => e != _entry);
                          } else if (!active.contains(i)) {
                            _entry = choices.first;
                          }
                          _selected = i;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: i == _selected
                                ? colors.primary
                                : active.contains(i)
                                    ? colors.primary.withValues(alpha: 0.35)
                                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                            border: Border.all(
                              color: wrong ? colors.error : Colors.black,
                              width: wrong ? 2.0 : 1.5,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Stack(
                            children: [
                              if (starts.isNotEmpty)
                                Positioned(
                                  left: 2,
                                  top: 0,
                                  child: Text(
                                    '${starts.first.number}',
                                    style: TextStyle(fontSize: 8),
                                  ),
                                ),
                              Center(
                                child: Text(
                                  _letters[i],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: wrong
                                        ? colors.error
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
          for (final row in ['QWERTYUIOP', 'ASDFGHJKL', 'ZXCVBNM'])
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Row(
                children: [
                  for (final letter in row.split(''))
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 1),
                        child: SizedBox(
                          height: 44,
                          child: FilledButton.tonal(
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onPressed: _solved ? null : () => _key(letter),
                            child: Text(letter),
                          ),
                        ),
                      ),
                    ),
                  if (row == 'ZXCVBNM')
                    IconButton(
                      onPressed: () => _key(''),
                      tooltip: 'Erase',
                      icon: Icon(Icons.backspace_outlined),
                    ),
                ],
              ),
            ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}
