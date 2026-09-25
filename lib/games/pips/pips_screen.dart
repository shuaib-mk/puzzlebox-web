import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/stats_service.dart';
import '../../core/services/app_feedback_service.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/game_mode_toggle.dart';
import '../../core/widgets/neo_toast.dart';
import '../../core/mixins/practice_mode_mixin.dart';

enum RegionRuleType { sum, equal, notEqual, greaterThan, lessThan }

class PipsRegion {
  final int id;
  final Color color;
  final RegionRuleType ruleType;
  final int targetValue;
  final List<Point<int>> cells;

  const PipsRegion({
    required this.id,
    required this.color,
    required this.ruleType,
    required this.targetValue,
    required this.cells,
  });

  String get label {
    switch (ruleType) {
      case RegionRuleType.sum:
        return '$targetValue';
      case RegionRuleType.equal:
        return '=';
      case RegionRuleType.notEqual:
        return '≠';
      case RegionRuleType.greaterThan:
        return '>$targetValue';
      case RegionRuleType.lessThan:
        return '<$targetValue';
    }
  }
}

class TrayDomino {
  final int id;
  final int val1;
  final int val2;
  bool isVertical;

  TrayDomino({
    required this.id,
    required this.val1,
    required this.val2,
    this.isVertical = false,
  });
}

class PlacedDomino {
  final int id;
  final int val1;
  final int val2;
  final int r1, c1;
  final int r2, c2;
  final bool isVertical;

  const PlacedDomino({
    required this.id,
    required this.val1,
    required this.val2,
    required this.r1,
    required this.c1,
    required this.r2,
    required this.c2,
    required this.isVertical,
  });
}

class PipsScreen extends ConsumerStatefulWidget {
  const PipsScreen({super.key});

  @override
  ConsumerState<PipsScreen> createState() => _PipsScreenState();
}

class _PipsScreenState extends ConsumerState<PipsScreen> with PracticeModeMixin {
  @override
  String get gameType => 'pips';

  int _rows = 4;
  int _cols = 4;
  late List<PipsRegion> _regions;
  late List<TrayDomino> _tray;
  final List<PlacedDomino> _boardDominoes = [];
  TrayDomino? _selectedTrayDomino;
  bool _isSolved = false;

  static const _regionColors = [
    Color(0xFFFEF08A), // Pastel Yellow
    Color(0xFFBAF7D0), // Pastel Green
    Color(0xFFBAE6FD), // Pastel Blue
    Color(0xFFFBCFE8), // Pastel Pink
    Color(0xFFDDD6FE), // Pastel Purple
    Color(0xFFFED7AA), // Pastel Orange
  ];

  @override
  void initState() {
    super.initState();
    initPracticeMode();
    _generatePipsPuzzle();
  }

  @override
  void onPracticeModeChanged(GameMode mode) {
    _generatePipsPuzzle();
  }

  @override
  void loadDailyPuzzle() {
    _generatePipsPuzzle();
  }

  @override
  void loadPracticePuzzle() {
    _generatePipsPuzzle();
  }

  void _generatePipsPuzzle() {
    final rand = Random(puzzleSeed());

    if (difficulty == 'Easy') {
      _rows = 4;
      _cols = 4;
    } else if (difficulty == 'Medium') {
      _rows = 4;
      _cols = 5;
    } else {
      _rows = 5;
      _cols = 5;
    }

    final totalCells = _rows * _cols;
    final gridDominoMap = List.generate(_rows, (_) => List<int>.filled(_cols, -1));
    final gridValues = List.generate(_rows, (_) => List<int>.filled(_cols, 0));
    final generatedDominoes = <TrayDomino>[];

    int dominoId = 0;
    for (int r = 0; r < _rows; r++) {
      for (int c = 0; c < _cols; c++) {
        if (gridDominoMap[r][c] != -1) continue;

        bool tryHorizontal = rand.nextBool();
        bool placed = false;

        if (tryHorizontal && c + 1 < _cols && gridDominoMap[r][c + 1] == -1) {
          int v1 = rand.nextInt(7);
          int v2 = rand.nextInt(7);
          gridDominoMap[r][c] = dominoId;
          gridDominoMap[r][c + 1] = dominoId;
          gridValues[r][c] = v1;
          gridValues[r][c + 1] = v2;
          generatedDominoes.add(TrayDomino(id: dominoId, val1: v1, val2: v2));
          dominoId++;
          placed = true;
        } else if (r + 1 < _rows && gridDominoMap[r + 1][c] == -1) {
          int v1 = rand.nextInt(7);
          int v2 = rand.nextInt(7);
          gridDominoMap[r][c] = dominoId;
          gridDominoMap[r + 1][c] = dominoId;
          gridValues[r][c] = v1;
          gridValues[r + 1][c] = v2;
          generatedDominoes.add(TrayDomino(id: dominoId, val1: v1, val2: v2, isVertical: true));
          dominoId++;
          placed = true;
        } else if (c + 1 < _cols && gridDominoMap[r][c + 1] == -1) {
          int v1 = rand.nextInt(7);
          int v2 = rand.nextInt(7);
          gridDominoMap[r][c] = dominoId;
          gridDominoMap[r][c + 1] = dominoId;
          gridValues[r][c] = v1;
          gridValues[r][c + 1] = v2;
          generatedDominoes.add(TrayDomino(id: dominoId, val1: v1, val2: v2));
          dominoId++;
          placed = true;
        }

        if (!placed && c > 0 && gridDominoMap[r][c - 1] != -1) {
          gridDominoMap[r][c] = gridDominoMap[r][c - 1];
          gridValues[r][c] = gridValues[r][c - 1];
        }
      }
    }

    // Partition grid into color-coded regions (cages) using BFS
    final regionMap = List.generate(_rows, (_) => List<int>.filled(_cols, -1));
    final regionsList = <PipsRegion>[];
    int regionId = 0;

    for (int r = 0; r < _rows; r++) {
      for (int c = 0; c < _cols; c++) {
        if (regionMap[r][c] != -1) continue;

        final targetSize = 2 + rand.nextInt(3);
        final cells = <Point<int>>[Point(r, c)];
        regionMap[r][c] = regionId;

        final queue = <Point<int>>[Point(r, c)];
        while (queue.isNotEmpty && cells.length < targetSize) {
          final curr = queue.removeAt(0);
          final neighbors = [
            Point(curr.x - 1, curr.y),
            Point(curr.x + 1, curr.y),
            Point(curr.x, curr.y - 1),
            Point(curr.x, curr.y + 1),
          ]..shuffle(rand);

          for (final n in neighbors) {
            if (n.x >= 0 && n.x < _rows && n.y >= 0 && n.y < _cols && regionMap[n.x][n.y] == -1) {
              regionMap[n.x][n.y] = regionId;
              cells.add(n);
              queue.add(n);
              if (cells.length >= targetSize) break;
            }
          }
        }

        final vals = cells.map((pt) => gridValues[pt.x][pt.y]).toList();
        final sum = vals.fold<int>(0, (a, b) => a + b);
        final allEqual = vals.every((v) => v == vals.first);
        final allUnique = vals.toSet().length == vals.length;

        RegionRuleType ruleType;
        int targetVal = sum;

        if (allEqual && rand.nextBool()) {
          ruleType = RegionRuleType.equal;
        } else if (allUnique && vals.length > 1 && rand.nextBool()) {
          ruleType = RegionRuleType.notEqual;
        } else {
          final choice = rand.nextInt(3);
          if (choice == 0 && sum > 4) {
            ruleType = RegionRuleType.greaterThan;
            targetVal = sum - (1 + rand.nextInt(2));
          } else if (choice == 1 && sum < 14) {
            ruleType = RegionRuleType.lessThan;
            targetVal = sum + (1 + rand.nextInt(2));
          } else {
            ruleType = RegionRuleType.sum;
            targetVal = sum;
          }
        }

        regionsList.add(
          PipsRegion(
            id: regionId,
            color: _regionColors[regionId % _regionColors.length],
            ruleType: ruleType,
            targetValue: targetVal,
            cells: cells,
          ),
        );
        regionId++;
      }
    }

    _regions = regionsList;
    _tray = generatedDominoes..shuffle(rand);
    _boardDominoes.clear();
    _selectedTrayDomino = null;
    _isSolved = false;

    startSession();
    setState(() {});
  }

  bool _isCellOccupied(int r, int c) {
    return _boardDominoes.any(
      (d) => (d.r1 == r && d.c1 == c) || (d.r2 == r && d.c2 == c),
    );
  }

  PlacedDomino? _getDominoAtCell(int r, int c) {
    for (final d in _boardDominoes) {
      if ((d.r1 == r && d.c1 == c) || (d.r2 == r && d.c2 == c)) return d;
    }
    return null;
  }

  PipsRegion _getRegionForCell(int r, int c) {
    return _regions.firstWhere(
      (reg) => reg.cells.any((pt) => pt.x == r && pt.y == c),
    );
  }

  bool _checkRegionSatisfied(PipsRegion region) {
    final values = <int>[];
    for (final pt in region.cells) {
      final pDom = _getDominoAtCell(pt.x, pt.y);
      if (pDom == null) return false;
      final val = (pDom.r1 == pt.x && pDom.c1 == pt.y) ? pDom.val1 : pDom.val2;
      values.add(val);
    }

    if (values.length < region.cells.length) return false;

    final sum = values.fold<int>(0, (a, b) => a + b);
    switch (region.ruleType) {
      case RegionRuleType.sum:
        return sum == region.targetValue;
      case RegionRuleType.equal:
        return values.every((v) => v == values.first);
      case RegionRuleType.notEqual:
        return values.toSet().length == values.length;
      case RegionRuleType.greaterThan:
        return sum > region.targetValue;
      case RegionRuleType.lessThan:
        return sum < region.targetValue;
    }
  }

  void _onBoardCellTap(int r, int c) {
    if (_isSolved) return;

    final existing = _getDominoAtCell(r, c);
    if (existing != null) {
      AppFeedbackService.tap(ref);
      setState(() {
        _boardDominoes.removeWhere((d) => d.id == existing.id);
        final trayDom = TrayDomino(
          id: existing.id,
          val1: existing.val1,
          val2: existing.val2,
          isVertical: existing.isVertical,
        );
        _tray.add(trayDom);
        _selectedTrayDomino = trayDom;
      });
      return;
    }

    if (_selectedTrayDomino != null) {
      final d = _selectedTrayDomino!;
      int r2 = d.isVertical ? r + 1 : r;
      int c2 = d.isVertical ? c : c + 1;

      if (r2 >= _rows || c2 >= _cols) {
        AppFeedbackService.error(ref);
        NeoToast.show(
          context,
          'Domino does not fit here!',
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFF43F5E),
        );
        return;
      }

      if (_isCellOccupied(r, c) || _isCellOccupied(r2, c2)) {
        AppFeedbackService.error(ref);
        NeoToast.show(
          context,
          'Space is already occupied!',
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFF43F5E),
        );
        return;
      }

      AppFeedbackService.tap(ref);
      setState(() {
        _boardDominoes.add(
          PlacedDomino(
            id: d.id,
            val1: d.val1,
            val2: d.val2,
            r1: r,
            c1: c,
            r2: r2,
            c2: c2,
            isVertical: d.isVertical,
          ),
        );
        _tray.removeWhere((t) => t.id == d.id);
        _selectedTrayDomino = null;
      });

      _checkFullPuzzleCompletion();
    }
  }

  void _checkFullPuzzleCompletion() {
    if (_tray.isNotEmpty) return;

    final allSatisfied = _regions.every((reg) => _checkRegionSatisfied(reg));
    if (allSatisfied) {
      setState(() => _isSolved = true);
      AppFeedbackService.victory(ref);

      NeoToast.show(
        context,
        'Pips Puzzle Solved! Perfect Domino Alignment! 🎉',
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFF4ADE80),
      );

      if (mode == GameMode.daily) {
        ref.read(statsServiceProvider).recordResult(gameType: 'pips', todayKey: dailyDateKey, won: true);
        finishPuzzle();
      } else {
        recordPracticeWin();
      }
    }
  }

  void _clearBoard() {
    AppFeedbackService.tap(ref);
    setState(() {
      for (final p in _boardDominoes) {
        _tray.add(TrayDomino(id: p.id, val1: p.val1, val2: p.val2, isVertical: p.isVertical));
      }
      _boardDominoes.clear();
      _selectedTrayDomino = null;
      _isSolved = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppScaffold(
      title: mode == GameMode.daily ? 'Pips Logic' : 'Pips Logic — Unlimited',
      showBackButton: true,
      body: Column(
        children: [
          buildPracticeModeToggle(),
          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Place dominoes into regions so every rule is satisfied.',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF525252),
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _clearBoard,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Clear', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),

          // Main Board & Grid Container
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cellSize = min(
                      constraints.maxWidth / _cols,
                      constraints.maxHeight / _rows,
                    );
                    final boardWidth = cellSize * _cols;
                    final boardHeight = cellSize * _rows;

                    return Container(
                      width: boardWidth,
                      height: boardHeight,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.black, width: 2.5),
                        boxShadow: const [
                          BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Stack(
                          children: [
                            // Base Grid Layer & Regions
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _PipsBoardPainter(
                                  rows: _rows,
                                  cols: _cols,
                                  cellSize: cellSize,
                                  regions: _regions,
                                  isDark: isDark,
                                ),
                              ),
                            ),

                            // Region Rule Badges
                            for (final reg in _regions)
                              Positioned(
                                left: reg.cells.first.y * cellSize + 5,
                                top: reg.cells.first.x * cellSize + 5,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _checkRegionSatisfied(reg)
                                        ? const Color(0xFF4ADE80)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.black, width: 1.5),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 0),
                                    ],
                                  ),
                                  child: Text(
                                    '${reg.label} ${_checkRegionSatisfied(reg) ? '✓' : ''}',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),

                            // Cell Taps Layer
                            Positioned.fill(
                              child: Stack(
                                children: [
                                  for (int r = 0; r < _rows; r++)
                                    for (int c = 0; c < _cols; c++)
                                      Positioned(
                                        left: c * cellSize,
                                        top: r * cellSize,
                                        width: cellSize,
                                        height: cellSize,
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () => _onBoardCellTap(r, c),
                                        ),
                                      ),
                                ],
                              ),
                            ),

                            // Placed 2-Cell Domino Tiles
                            for (final pDom in _boardDominoes)
                              Positioned(
                                left: pDom.c1 * cellSize + 3,
                                top: pDom.r1 * cellSize + 3,
                                width: pDom.isVertical ? (cellSize - 6) : (cellSize * 2 - 6),
                                height: pDom.isVertical ? (cellSize * 2 - 6) : (cellSize - 6),
                                child: GestureDetector(
                                  onTap: () => _onBoardCellTap(pDom.r1, pDom.c1),
                                  child: _DominoTileWidget(
                                    val1: pDom.val1,
                                    val2: pDom.val2,
                                    isVertical: pDom.isVertical,
                                    isPlaced: true,
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

          // Controls & Tray Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
            child: Row(
              children: [
                Text(
                  'Tray (${_tray.length} left)',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (_selectedTrayDomino != null)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    icon: const Icon(Icons.rotate_right_rounded, size: 16),
                    label: Text(
                      _selectedTrayDomino!.isVertical ? 'Vertical' : 'Horizontal',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                    onPressed: () {
                      AppFeedbackService.tap(ref);
                      setState(() {
                        _selectedTrayDomino!.isVertical = !_selectedTrayDomino!.isVertical;
                      });
                    },
                  ),
              ],
            ),
          ),

          // Tray List
          SizedBox(
            height: 72,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _tray.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final d = _tray[index];
                final isSelected = _selectedTrayDomino == d;

                return GestureDetector(
                  onTap: () {
                    AppFeedbackService.tap(ref);
                    setState(() {
                      _selectedTrayDomino = isSelected ? null : d;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: isSelected ? Border.all(color: const Color(0xFFFACC15), width: 3) : null,
                    ),
                    child: _DominoTileWidget(
                      val1: d.val1,
                      val2: d.val2,
                      isVertical: false,
                      isPlaced: false,
                      isSelected: isSelected,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Custom Board Painter for Region Cages & Boundaries
class _PipsBoardPainter extends CustomPainter {
  final int rows;
  final int cols;
  final double cellSize;
  final List<PipsRegion> regions;
  final bool isDark;

  _PipsBoardPainter({
    required this.rows,
    required this.cols,
    required this.cellSize,
    required this.regions,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fill region background cells
    for (final reg in regions) {
      final paint = Paint()
        ..color = reg.color.withOpacity(isDark ? 0.40 : 0.85)
        ..style = PaintingStyle.fill;

      for (final pt in reg.cells) {
        final rect = Rect.fromLTWH(pt.y * cellSize, pt.x * cellSize, cellSize, cellSize);
        canvas.drawRect(rect, paint);
      }
    }

    // Grid Inner Cell Lines
    final gridLinePaint = Paint()
      ..color = Colors.black.withOpacity(0.18)
      ..strokeWidth = 1.0;

    for (int r = 1; r < rows; r++) {
      canvas.drawLine(Offset(0, r * cellSize), Offset(cols * cellSize, r * cellSize), gridLinePaint);
    }
    for (int c = 1; c < cols; c++) {
      canvas.drawLine(Offset(c * cellSize, 0), Offset(c * cellSize, rows * cellSize), gridLinePaint);
    }

    // Region Cage Boundaries (Thicker Black Borders)
    final cagePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    for (final reg in regions) {
      final regSet = reg.cells.map((pt) => '${pt.x},${pt.y}').toSet();
      for (final pt in reg.cells) {
        final r = pt.x;
        final c = pt.y;

        // Top edge
        if (r == 0 || !regSet.contains('${r - 1},$c')) {
          canvas.drawLine(Offset(c * cellSize, r * cellSize), Offset((c + 1) * cellSize, r * cellSize), cagePaint);
        }
        // Bottom edge
        if (r == rows - 1 || !regSet.contains('${r + 1},$c')) {
          canvas.drawLine(Offset(c * cellSize, (r + 1) * cellSize), Offset((c + 1) * cellSize, (r + 1) * cellSize), cagePaint);
        }
        // Left edge
        if (c == 0 || !regSet.contains('$r,${c - 1}')) {
          canvas.drawLine(Offset(c * cellSize, r * cellSize), Offset(c * cellSize, (r + 1) * cellSize), cagePaint);
        }
        // Right edge
        if (c == cols - 1 || !regSet.contains('$r,${c + 1}')) {
          canvas.drawLine(Offset((c + 1) * cellSize, r * cellSize), Offset((c + 1) * cellSize, (r + 1) * cellSize), cagePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PipsBoardPainter oldDelegate) => true;
}

/// 2-Cell Domino Tile Piece (Single Physical Domino Object)
class _DominoTileWidget extends StatelessWidget {
  final int val1;
  final int val2;
  final bool isVertical;
  final bool isPlaced;
  final bool isSelected;

  const _DominoTileWidget({
    required this.val1,
    required this.val2,
    required this.isVertical,
    required this.isPlaced,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFACC15) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 2.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            offset: isPlaced ? const Offset(2.5, 2.5) : const Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Flex(
        direction: isVertical ? Axis.vertical : Axis.horizontal,
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PipDots(count: val1, size: 20, color: Colors.black),
                  Text(
                    '$val1',
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: isVertical ? double.infinity : 2.0,
            height: isVertical ? 2.0 : double.infinity,
            color: Colors.black,
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PipDots(count: val2, size: 20, color: Colors.black),
                  Text(
                    '$val2',
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
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

/// Domino Pip Dots Renderer (0 to 6)
class _PipDots extends StatelessWidget {
  final int count;
  final double size;
  final Color color;

  const _PipDots({required this.count, this.size = 20, this.color = Colors.black});

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Container(
            width: 3.5,
            height: 3.5,
            decoration: BoxDecoration(color: color.withOpacity(0.3), shape: BoxShape.circle),
          ),
        ),
      );
    }

    final dots = <int>[];
    switch (count) {
      case 1:
        dots.addAll([4]);
        break;
      case 2:
        dots.addAll([0, 8]);
        break;
      case 3:
        dots.addAll([0, 4, 8]);
        break;
      case 4:
        dots.addAll([0, 2, 6, 8]);
        break;
      case 5:
        dots.addAll([0, 2, 4, 6, 8]);
        break;
      case 6:
        dots.addAll([0, 2, 3, 5, 6, 8]);
        break;
    }

    return SizedBox(
      width: size,
      height: size,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
        itemCount: 9,
        itemBuilder: (context, i) {
          if (dots.contains(i)) {
            return Center(
              child: Container(
                width: size * 0.22,
                height: size * 0.22,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
