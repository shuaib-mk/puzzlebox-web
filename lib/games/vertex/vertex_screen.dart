import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/stats_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/game_mode_toggle.dart';
import '../../core/mixins/practice_mode_mixin.dart';

class DotNode {
  final int id;
  final Offset pos;
  final int targetConnections;

  DotNode(this.id, this.pos, this.targetConnections);
}

class VertexScreen extends ConsumerStatefulWidget {
  const VertexScreen({super.key});

  @override
  ConsumerState<VertexScreen> createState() => _VertexScreenState();
}

class _VertexScreenState extends ConsumerState<VertexScreen>
    with PracticeModeMixin {
  @override
  String get gameType => 'vertex';

  List<List<int>> _target = [];
  late List<DotNode> _dots;
  final List<List<int>> _userConnections = [];
  final List<List<List<int>>> _history = [];
  int? _selectedDotId;
  bool _isSolved = false;

  @override
  void initState() {
    super.initState();
    initPracticeMode();
    _generatePuzzle();
  }

  @override
  void onPracticeModeChanged(GameMode mode) {
    _generatePuzzle();
  }

  @override
  void loadDailyPuzzle() {
    _generatePuzzle();
  }

  @override
  void loadPracticePuzzle() {
    _generatePuzzle();
  }

  void _generatePuzzle() {
    final rand = Random(puzzleSeed());
    final int nodeCount = difficulty == 'Easy'
        ? 4
        : (difficulty == 'Medium' ? 6 : 8);

    final dots = <DotNode>[];
    final targetConns = <List<int>>[];
    final degrees = List<int>.filled(nodeCount + 1, 0);

    // Layout positions around a circle with slight jitter for organic shape variety
    final center = Offset(160, 160);
    final double radius = nodeCount == 4 ? 90 : (nodeCount == 6 ? 110 : 125);

    for (int i = 0; i < nodeCount; i++) {
      final angle = (2 * pi * i / nodeCount) + (rand.nextDouble() * 0.2 - 0.1);
      final offsetRadius = radius + (rand.nextDouble() * 20 - 10);
      final x = center.dx + offsetRadius * cos(angle);
      final y = center.dy + offsetRadius * sin(angle);
      dots.add(DotNode(i + 1, Offset(x, y), 0));
    }

    // Build cycle graph + internal chords for target graph
    for (int i = 0; i < nodeCount; i++) {
      final u = i + 1;
      final v = (i + 1) % nodeCount + 1;
      final pair = [u, v]..sort();
      if (!targetConns.any((c) => c[0] == pair[0] && c[1] == pair[1])) {
        targetConns.add(pair);
        degrees[u]++;
        degrees[v]++;
      }
    }

    // Add extra chords based on difficulty
    final extraEdges = nodeCount == 4 ? 1 : (nodeCount == 6 ? 2 : 4);
    int added = 0;
    int attempts = 0;
    while (added < extraEdges && attempts < 50) {
      attempts++;
      final u = rand.nextInt(nodeCount) + 1;
      final v = rand.nextInt(nodeCount) + 1;
      if (u != v) {
        final pair = [u, v]..sort();
        if (!targetConns.any((c) => c[0] == pair[0] && c[1] == pair[1])) {
          targetConns.add(pair);
          degrees[u]++;
          degrees[v]++;
          added++;
        }
      }
    }

    // Assign computed degree target to each DotNode
    _dots = dots.map((d) => DotNode(d.id, d.pos, degrees[d.id])).toList();
    _target = targetConns;
    _history.clear();
    _userConnections.clear();
    _selectedDotId = null;
    _isSolved = false;
    startSession();
    setState(() {});
  }

  void _onDotTap(int id) {
    if (_isSolved) return;
    setState(() {
      if (_selectedDotId == null) {
        _selectedDotId = id;
      } else {
        if (_selectedDotId != id) {
          _history.add(_userConnections.map((e) => List<int>.of(e)).toList());
          final pair = [_selectedDotId!, id]..sort();
          if (_userConnections.any((c) => c[0] == pair[0] && c[1] == pair[1])) {
            _userConnections.removeWhere(
              (c) => c[0] == pair[0] && c[1] == pair[1],
            );
          } else {
            _userConnections.add(pair);
          }
          _selectedDotId = null;
          _checkWin();
        } else {
          _selectedDotId = null;
        }
      }
    });
  }

  void _checkWin() {
    // Check if degree counts of user connections match all target node degrees
    final userDegrees = List<int>.filled(_dots.length + 1, 0);
    for (final conn in _userConnections) {
      userDegrees[conn[0]]++;
      userDegrees[conn[1]]++;
    }

    bool matched = true;
    for (final d in _dots) {
      if (userDegrees[d.id] != d.targetConnections) {
        matched = false;
        break;
      }
    }

    if (matched) {
      setState(() => _isSolved = true);
      if (mode == GameMode.daily) {
        ref
            .read(statsServiceProvider)
            .recordResult(
              gameType: 'vertex',
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

  @override
  Map<String, dynamic> captureProgress() =>
      _isSolved ? {} : {'edges': _userConnections, 'history': _history};
  @override
  void restoreProgress(Map<String, dynamic> d) {
    final edges = (d['edges'] as List).map((e) => List<int>.from(e)).toList();
    if (edges.any(
          (e) =>
              e.length != 2 || e[0] < 1 || e[1] > _dots.length || e[0] >= e[1],
        ) ||
        edges.map((e) => e.join(':')).toSet().length != edges.length) {
      return;
    }
    _userConnections.addAll(edges);
    // History from an older app is optional; validate before accepting it.
    final history = d['history'];
    if (history is List) {
      for (final entry in history) {
        final previous = (entry as List).map((e) => List<int>.from(e)).toList();
        if (previous.any(
          (e) =>
              e.length != 2 || e[0] < 1 || e[1] > _dots.length || e[0] >= e[1],
        )) {
          break;
        }
        _history.add(previous);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: mode == GameMode.daily
          ? 'Vertex Geometry'
          : 'Vertex Geometry — Unlimited',
      showBackButton: true,
      body: Column(
        children: [
          buildPracticeModeToggle(),
          Divider(height: 1),

          Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Connect dots so each dot has the number of lines shown. Tap a pair again to remove its line.',
            ),
          ),
          Wrap(
            children: [
              TextButton.icon(
                icon: Icon(Icons.undo),
                label: Text('Undo'),
                onPressed: () {
                  if (_history.isNotEmpty && !_isSolved) {
                    setState(() {
                      _userConnections
                        ..clear()
                        ..addAll(_history.removeLast());
                      _selectedDotId = null;
                    });
                  }
                },
              ),
              TextButton.icon(
                icon: Icon(Icons.lightbulb_outline),
                label: Text('Hint'),
                onPressed: () {
                  final extra = _userConnections
                      .where(
                        (e) =>
                            !_target.any((t) => t[0] == e[0] && t[1] == e[1]),
                      )
                      .toList();
                  if (extra.isNotEmpty) {
                    showPuzzleHint(
                      'One route to a solution: remove the line between dots ${extra.first.join(" and ")}. Dots are numbered clockwise from the right.',
                    );
                    return;
                  }
                  final missing = _target
                      .where(
                        (t) => !_userConnections.any(
                          (e) => t[0] == e[0] && t[1] == e[1],
                        ),
                      )
                      .toList();
                  if (missing.isNotEmpty) {
                    showPuzzleHint(
                      'Try connecting dots ${missing.first.join(" and ")}. Count clockwise from the right.',
                    );
                  }
                },
              ),
            ],
          ),
          // Canvas & Interactive Graph
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black, width: 2.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black, offset: Offset(3.5, 3.5), blurRadius: 0),
                ],
              ),
              child: FittedBox(
                child: SizedBox(
                  width: 320,
                  height: 320,
                  child: CustomPaint(
                    painter: _VertexPainter(
                      dots: _dots,
                      connections: _userConnections,
                      selectedId: _selectedDotId,
                    ),
                    child: Stack(
                      children: _dots.map((dot) {
                        final isSelected = _selectedDotId == dot.id;
                        return Positioned(
                          left: dot.pos.dx - 20,
                          top: dot.pos.dy - 20,
                          child: GestureDetector(
                            key: ValueKey('vertex_dot_${dot.id}'),
                            onTap: () => _onDotTap(dot.id),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black, width: 2.2),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '${dot.targetConnections}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.onSurface
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Next Puzzle Button (Practice Mode / Victory)
          if (shouldShowNextButton(_isSolved))
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ElevatedButton.icon(
                icon: Icon(Icons.arrow_forward_rounded),
                label: Text('Next Puzzle'),
                onPressed: nextPuzzle,
              ),
            ),
        ],
      ),
    );
  }
}

class _VertexPainter extends CustomPainter {
  final List<DotNode> dots;
  final List<List<int>> connections;
  final int? selectedId;

  const _VertexPainter({
    required this.dots,
    required this.connections,
    this.selectedId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.brand
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    for (final conn in connections) {
      final d1 = dots.firstWhere(
        (d) => d.id == conn[0],
        orElse: () => dots.first,
      );
      final d2 = dots.firstWhere(
        (d) => d.id == conn[1],
        orElse: () => dots.last,
      );
      canvas.drawLine(d1.pos, d2.pos, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
