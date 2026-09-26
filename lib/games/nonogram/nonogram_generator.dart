import 'dart:math';
import '../../core/services/puzzle_progression.dart';

/// A generated Nonogram (Picture Cross) puzzle.
///
/// [solution] is a flattened row-major grid of 0/1 values, length
/// [size] * [size]. [rowClues] and [colClues] are the run-length clues
/// a solver reads off the edges of the grid.
class NonogramPuzzle {
  final int size;
  final List<List<int>> rowClues;
  final List<List<int>> colClues;
  final List<int> solution;
  const NonogramPuzzle(this.size, this.rowClues, this.colClues, this.solution);
}

/// Run-length clue for a single 0/1 line, e.g. [0,1,1,0,1] -> [2, 1].
/// An all-empty line yields [0], matching standard nonogram notation.
List<int> clueFor(List<int> line) {
  final out = <int>[];
  var run = 0;
  for (final v in line) {
    if (v == 1) {
      run++;
    } else if (run > 0) {
      out.add(run);
      run = 0;
    }
  }
  if (run > 0) out.add(run);
  return out.isEmpty ? const [0] : out;
}

/// Every line of length [n] whose runs satisfy [clue] and which agrees
/// with the currently-known cells in [known] (-1 = unknown, 0/1 = fixed).
List<List<int>> _placements(int n, List<int> clue, List<int> known) {
  final result = <List<int>>[];
  if (clue.length == 1 && clue[0] == 0) {
    if (known.every((k) => k != 1)) result.add(List<int>.filled(n, 0));
    return result;
  }
  bool matches(List<int> candidate) {
    for (var i = 0; i < candidate.length; i++) {
      if (known[i] != -1 && known[i] != candidate[i]) return false;
    }
    return true;
  }

  void rec(int filled, int blockIndex, List<int> line) {
    if (blockIndex == clue.length) {
      final candidate = List<int>.of(line)
        ..addAll(List<int>.filled(n - filled, 0));
      if (matches(candidate)) result.add(candidate);
      return;
    }
    var remaining = 0;
    for (var k = blockIndex; k < clue.length; k++) {
      remaining += clue[k];
    }
    remaining += clue.length - blockIndex - 1;
    for (var start = filled; start <= n - remaining; start++) {
      var candidate = List<int>.of(line)
        ..addAll(List<int>.filled(start - filled, 0))
        ..addAll(List<int>.filled(clue[blockIndex], 1));
      if (blockIndex < clue.length - 1) {
        candidate = List<int>.of(candidate)..add(0);
      }
      if (matches(candidate)) rec(candidate.length, blockIndex + 1, candidate);
    }
  }

  rec(0, 0, []);
  return result;
}

/// Solves a nonogram purely by logical deduction (no guessing). Every cell
/// this fills is *necessarily* that value in any grid matching the clues,
/// so a fully-filled result proves the puzzle has exactly one solution.
List<List<int>>? _lineSolve(
  List<List<int>> rowClues,
  List<List<int>> colClues,
  int n,
) {
  final grid = List.generate(n, (_) => List<int>.filled(n, -1));
  var changed = true;
  while (changed) {
    changed = false;
    for (var r = 0; r < n; r++) {
      final options = _placements(n, rowClues[r], grid[r]);
      if (options.isEmpty) return null;
      for (var c = 0; c < n; c++) {
        if (grid[r][c] != -1) continue;
        final v = options.first[c];
        if (options.every((p) => p[c] == v)) {
          grid[r][c] = v;
          changed = true;
        }
      }
    }
    for (var c = 0; c < n; c++) {
      final column = [for (var r = 0; r < n; r++) grid[r][c]];
      final options = _placements(n, colClues[c], column);
      if (options.isEmpty) return null;
      for (var r = 0; r < n; r++) {
        if (grid[r][c] != -1) continue;
        final v = options.first[r];
        if (options.every((p) => p[r] == v)) {
          grid[r][c] = v;
          changed = true;
        }
      }
    }
  }
  return grid;
}

class NonogramGenerator {
  NonogramPuzzle generate(PuzzleRequest request) {
    final n = [5, 8, 10][request.difficulty.index];
    final rand = Random(request.seed);
    for (var attempt = 0; attempt < 400; attempt++) {
      var grid = List.generate(
        n,
        (_) => List<int>.generate(n, (_) => rand.nextDouble() < 0.5 ? 1 : 0),
      );
      // One pass of majority smoothing groups pixels into blockier,
      // more solvable-looking shapes instead of pure static.
      final smoothed = List.generate(n, (_) => List<int>.filled(n, 0));
      for (var r = 0; r < n; r++) {
        for (var c = 0; c < n; c++) {
          var sum = 0, count = 0;
          for (var dr = -1; dr <= 1; dr++) {
            for (var dc = -1; dc <= 1; dc++) {
              final rr = r + dr, cc = c + dc;
              if (rr >= 0 && rr < n && cc >= 0 && cc < n) {
                sum += grid[rr][cc];
                count++;
              }
            }
          }
          smoothed[r][c] = sum * 2 > count
              ? 1
              : (sum * 2 < count ? 0 : grid[r][c]);
        }
      }
      grid = smoothed;
      if (grid.any((row) => row.every((v) => v == 0))) continue;
      var emptyColumn = false;
      for (var c = 0; c < n; c++) {
        if (List.generate(n, (r) => grid[r][c]).every((v) => v == 0)) {
          emptyColumn = true;
          break;
        }
      }
      if (emptyColumn) continue;
      final rowClues = [for (final row in grid) clueFor(row)];
      final colClues = [
        for (var c = 0; c < n; c++)
          clueFor([for (var r = 0; r < n; r++) grid[r][c]]),
      ];
      final solved = _lineSolve(rowClues, colClues, n);
      if (solved != null && solved.every((row) => row.every((v) => v != -1))) {
        return NonogramPuzzle(n, rowClues, colClues, [
          for (final row in grid) ...row,
        ]);
      }
    }
    // Practically unreachable given generation success rates observed in
    // testing, but a deterministic, always-valid fallback keeps this total.
    final fallback = List.generate(
      n,
      (r) => List<int>.generate(n, (c) => (r + c).isEven ? 1 : 0),
    );
    final rowClues = [for (final row in fallback) clueFor(row)];
    final colClues = [
      for (var c = 0; c < n; c++)
        clueFor([for (var r = 0; r < n; r++) fallback[r][c]]),
    ];
    return NonogramPuzzle(n, rowClues, colClues, [
      for (final row in fallback) ...row,
    ]);
  }

  bool validate(NonogramPuzzle puzzle) {
    if (puzzle.solution.length != puzzle.size * puzzle.size) return false;
    if (puzzle.solution.any((v) => v != 0 && v != 1)) return false;
    final n = puzzle.size;
    for (var r = 0; r < n; r++) {
      final row = puzzle.solution.sublist(r * n, r * n + n);
      if (clueFor(row).toString() != puzzle.rowClues[r].toString()) {
        return false;
      }
    }
    for (var c = 0; c < n; c++) {
      final col = [for (var r = 0; r < n; r++) puzzle.solution[r * n + c]];
      if (clueFor(col).toString() != puzzle.colClues[c].toString()) {
        return false;
      }
    }
    return true;
  }
}

NonogramPuzzle generateNonogram(PuzzleRequest request) =>
    NonogramGenerator().generate(request);
