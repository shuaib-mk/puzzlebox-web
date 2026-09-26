import 'dart:math';
import '../../core/services/puzzle_progression.dart';

/// A generated Binary (Takuzu) puzzle: fill an n×n grid with 0s and 1s so
/// that every row and column has an equal split, no three same values sit
/// in a row, and no two rows or two columns are identical.
class BinaryPuzzle {
  final int size;
  final List<int> givens; // -1 = blank, 0/1 = fixed clue
  final List<int> solution;
  const BinaryPuzzle(this.size, this.givens, this.solution);
}

bool _lineOk(List<int> line, int n) {
  final half = n ~/ 2;
  var zeros = 0, ones = 0;
  for (final v in line) {
    if (v == 0) zeros++;
    if (v == 1) ones++;
  }
  if (zeros > half || ones > half) return false;
  for (var i = 0; i + 2 < line.length; i++) {
    final a = line[i], b = line[i + 1], c = line[i + 2];
    if (a != -1 && a == b && b == c) return false;
  }
  return true;
}

bool _cellOk(List<List<int>> grid, int n, int r, int c) {
  if (!_lineOk(grid[r], n)) return false;
  if (!_lineOk([for (var i = 0; i < n; i++) grid[i][c]], n)) return false;
  if (!grid[r].contains(-1)) {
    for (var i = 0; i < n; i++) {
      if (i != r && listIntEquals(grid[i], grid[r])) return false;
    }
  }
  final col = [for (var i = 0; i < n; i++) grid[i][c]];
  if (!col.contains(-1)) {
    for (var j = 0; j < n; j++) {
      final other = [for (var i = 0; i < n; i++) grid[i][j]];
      if (j != c && listIntEquals(other, col)) return false;
    }
  }
  return true;
}

bool listIntEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Counts solutions up to [limit] (default 2, i.e. "is it unique?").
int countBinarySolutions(List<List<int>> given, int n, {int limit = 2}) {
  final grid = [for (final row in given) List<int>.of(row)];
  for (var r = 0; r < n; r++) {
    for (var c = 0; c < n; c++) {
      if (grid[r][c] != -1 && !_cellOk(grid, n, r, c)) return 0;
    }
  }
  var count = 0;
  void rec(int pos) {
    if (count >= limit) return;
    var p = pos;
    while (p < n * n && grid[p ~/ n][p % n] != -1) {
      p++;
    }
    if (p == n * n) {
      count++;
      return;
    }
    final r = p ~/ n, c = p % n;
    for (final v in [0, 1]) {
      grid[r][c] = v;
      if (_cellOk(grid, n, r, c)) rec(p + 1);
      grid[r][c] = -1;
      if (count >= limit) return;
    }
  }

  rec(0);
  return count;
}

List<List<int>> _fullSolution(Random rand, int n) {
  final grid = List.generate(n, (_) => List<int>.filled(n, -1));
  bool rec(int pos) {
    if (pos == n * n) return true;
    final r = pos ~/ n, c = pos % n;
    final values = [0, 1]..shuffle(rand);
    for (final v in values) {
      grid[r][c] = v;
      if (_cellOk(grid, n, r, c) && rec(pos + 1)) return true;
      grid[r][c] = -1;
    }
    return false;
  }

  final ok = rec(0);
  assert(ok, 'Binary full-grid backtracking should always succeed');
  return grid;
}

class BinaryGenerator {
  BinaryPuzzle generate(PuzzleRequest request) {
    final n = [6, 8, 10][request.difficulty.index];
    final keepFraction = [0.52, 0.45, 0.38][request.difficulty.index];
    final rand = Random(request.seed);
    final solution = _fullSolution(rand, n);
    final flatSolution = [for (final row in solution) ...row];
    final grid = [for (final row in solution) List<int>.of(row)];
    final positions = List.generate(n * n, (i) => i)..shuffle(rand);
    var kept = n * n;
    final target = (n * n * keepFraction).round();
    for (final pos in positions) {
      final r = pos ~/ n, c = pos % n;
      final old = grid[r][c];
      grid[r][c] = -1;
      if (countBinarySolutions(grid, n) != 1) {
        grid[r][c] = old;
      } else {
        kept--;
      }
      if (kept <= target) break;
    }
    return BinaryPuzzle(n, [for (final row in grid) ...row], flatSolution);
  }

  bool validate(BinaryPuzzle puzzle) {
    final n = puzzle.size;
    if (puzzle.solution.length != n * n) return false;
    final grid = List.generate(
      n,
      (r) => puzzle.solution.sublist(r * n, r * n + n),
    );
    for (var r = 0; r < n; r++) {
      if (!_lineOk(grid[r], n) || grid[r].contains(-1)) return false;
    }
    for (var c = 0; c < n; c++) {
      final col = [for (var r = 0; r < n; r++) grid[r][c]];
      if (!_lineOk(col, n)) return false;
    }
    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        if (listIntEquals(grid[i], grid[j])) return false;
        final ci = [for (var r = 0; r < n; r++) grid[r][i]];
        final cj = [for (var r = 0; r < n; r++) grid[r][j]];
        if (listIntEquals(ci, cj)) return false;
      }
    }
    for (var i = 0; i < n * n; i++) {
      if (puzzle.givens[i] != -1 && puzzle.givens[i] != puzzle.solution[i]) {
        return false;
      }
    }
    return countBinarySolutions(
          List.generate(n, (r) => puzzle.givens.sublist(r * n, r * n + n)),
          n,
        ) ==
        1;
  }
}

BinaryPuzzle generateBinary(PuzzleRequest request) =>
    BinaryGenerator().generate(request);
