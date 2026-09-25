import 'dart:math';
import '../../core/services/puzzle_progression.dart';

/// A single cage: a connected group of cells whose values combine with
/// [op] ('+', '-', '*', '/', or '=' for a single-cell cage) to equal
/// [target].
class Cage {
  final List<int> cells;
  final String op;
  final int target;
  const Cage(this.cells, this.op, this.target);
}

/// A generated Cages puzzle: fill an n×n Latin square (1..n, no repeats
/// in any row or column) so every cage's arithmetic clue is satisfied.
class CagesPuzzle {
  final int size;
  final List<Cage> cages;
  final List<int> solution;
  const CagesPuzzle(this.size, this.cages, this.solution);
}

List<List<int>> _latinSquare(Random rand, int n) {
  final base = List.generate(n, (i) => List.generate(n, (j) => (i + j) % n));
  final rowOrder = List.generate(n, (i) => i)..shuffle(rand);
  final colOrder = List.generate(n, (i) => i)..shuffle(rand);
  final symbols = List.generate(n, (i) => i + 1)..shuffle(rand);
  return List.generate(
    n,
    (i) => List.generate(
      n,
      (j) => symbols[base[rowOrder[i]][colOrder[j]]],
    ),
  );
}

List<List<int>> _carveCages(Random rand, int n, List<int> sizePool) {
  final cageOf = List<int>.filled(n * n, -1);
  final cages = <List<int>>[];
  final order = List.generate(n * n, (i) => i)..shuffle(rand);
  for (final start in order) {
    if (cageOf[start] != -1) continue;
    final id = cages.length;
    final cells = [start];
    cageOf[start] = id;
    final size = sizePool[rand.nextInt(sizePool.length)];
    while (cells.length < size) {
      final options = <int>[];
      for (final cell in cells) {
        final r = cell ~/ n, c = cell % n;
        for (final d in const [
          [1, 0],
          [-1, 0],
          [0, 1],
          [0, -1],
        ]) {
          final rr = r + d[0], cc = c + d[1];
          if (rr >= 0 && rr < n && cc >= 0 && cc < n) {
            final idx = rr * n + cc;
            if (cageOf[idx] == -1) options.add(idx);
          }
        }
      }
      if (options.isEmpty) break;
      final next = options[rand.nextInt(options.length)];
      cells.add(next);
      cageOf[next] = id;
    }
    cages.add(cells);
  }
  return cages;
}

/// Whether [values] (in any order) satisfy a cage's [op]/[target] clue.
/// Exposed for the game screen to use when checking a filled cage.
bool cageSatisfied(String op, int target, List<int> values) =>
    _cageArithmeticOk(op, target, values);

bool _cageArithmeticOk(String op, int target, List<int> values) {
  switch (op) {
    case '=':
      return values[0] == target;
    case '+':
      return values.fold(0, (a, b) => a + b) == target;
    case '*':
      return values.fold(1, (a, b) => a * b) == target;
    case '-':
      return (values[0] - values[1]).abs() == target;
    case '/':
      {
        final a = values[0] > values[1] ? values[0] : values[1];
        final b = values[0] > values[1] ? values[1] : values[0];
        return b != 0 && a % b == 0 && a ~/ b == target;
      }
  }
  return false;
}

List<Cage> _assignOps(
  Random rand,
  List<List<int>> solution,
  List<List<int>> cageCells,
  int n,
  bool allowDivision,
) {
  final cages = <Cage>[];
  for (final cells in cageCells) {
    final values = [for (final c in cells) solution[c ~/ n][c % n]];
    if (cells.length == 1) {
      cages.add(Cage(cells, '=', values.first));
      continue;
    }
    if (cells.length == 2) {
      final sorted = [...values]..sort();
      final a = sorted[1], b = sorted[0];
      final options = ['+', '-', '*'];
      if (allowDivision && a % b == 0) options.add('/');
      final op = options[rand.nextInt(options.length)];
      final target = switch (op) {
        '+' => a + b,
        '-' => a - b,
        '*' => a * b,
        '/' => a ~/ b,
        _ => 0,
      };
      cages.add(Cage(cells, op, target));
      continue;
    }
    final op = rand.nextBool() ? '+' : '*';
    final target = op == '+'
        ? values.fold(0, (a, b) => a + b)
        : values.fold(1, (a, b) => a * b);
    cages.add(Cage(cells, op, target));
  }
  return cages;
}

/// Counts solutions to a cage layout up to [limit], pruning a cage's
/// branch as soon as its partially-filled values can no longer possibly
/// satisfy its clue.
int _countCageSolutions(
  int n,
  List<int> cageOf,
  List<Cage> cages,
  int limit,
) {
  final grid = List<int>.filled(n * n, 0);
  var count = 0;

  bool partialOk(int cageId) {
    final cage = cages[cageId];
    final values = [for (final c in cage.cells) grid[c]];
    if (values.contains(0)) {
      final known = values.where((v) => v != 0).toList();
      switch (cage.op) {
        case '+':
          return known.fold(0, (a, b) => a + b) < cage.target;
        case '*':
          final product = known.fold(1, (a, b) => a * b);
          return product == 0 || cage.target % product == 0;
        default:
          return true;
      }
    }
    return _cageArithmeticOk(cage.op, cage.target, values);
  }

  void rec(int pos) {
    if (count >= limit) return;
    if (pos == n * n) {
      count++;
      return;
    }
    final r = pos ~/ n, c = pos % n;
    for (var v = 1; v <= n; v++) {
      var clashes = false;
      for (var k = 0; k < c; k++) {
        if (grid[r * n + k] == v) {
          clashes = true;
          break;
        }
      }
      if (!clashes) {
        for (var k = 0; k < r; k++) {
          if (grid[k * n + c] == v) {
            clashes = true;
            break;
          }
        }
      }
      if (clashes) continue;
      grid[pos] = v;
      if (partialOk(cageOf[pos])) rec(pos + 1);
      grid[pos] = 0;
      if (count >= limit) return;
    }
  }

  rec(0);
  return count;
}

class CagesGenerator {
  CagesPuzzle generate(PuzzleRequest request) {
    final n = [4, 5, 6][request.difficulty.index];
    final sizePools = [
      [1, 2, 2, 2],
      [1, 2, 2, 3, 3],
      [2, 2, 3, 3, 4],
    ];
    final allowDivision = request.difficulty.index > 0;
    final sizePool = sizePools[request.difficulty.index];
    final rand = Random(request.seed);
    for (var attempt = 0; attempt < 20000; attempt++) {
      final solution = _latinSquare(rand, n);
      final cageCells = _carveCages(rand, n, sizePool);
      final cages = _assignOps(rand, solution, cageCells, n, allowDivision);
      final cageOf = List<int>.filled(n * n, 0);
      for (var id = 0; id < cages.length; id++) {
        for (final cell in cages[id].cells) {
          cageOf[cell] = id;
        }
      }
      if (_countCageSolutions(n, cageOf, cages, 2) == 1) {
        return CagesPuzzle(n, cages, [for (final row in solution) ...row]);
      }
    }
    // Fallback: a trivial all-singleton "cage per cell" puzzle. Always
    // unique by construction; unreachable in practice given the very
    // high generation success rate observed in testing.
    final solution = _latinSquare(rand, n);
    final cages = [
      for (var i = 0; i < n * n; i++)
        Cage([i], '=', solution[i ~/ n][i % n]),
    ];
    return CagesPuzzle(n, cages, [for (final row in solution) ...row]);
  }

  bool validate(CagesPuzzle puzzle) {
    final n = puzzle.size;
    if (puzzle.solution.length != n * n) return false;
    for (var r = 0; r < n; r++) {
      if ({for (var c = 0; c < n; c++) puzzle.solution[r * n + c]}.length !=
          n) {
        return false;
      }
    }
    for (var c = 0; c < n; c++) {
      if ({for (var r = 0; r < n; r++) puzzle.solution[r * n + c]}.length !=
          n) {
        return false;
      }
    }
    final covered = <int>{};
    for (final cage in puzzle.cages) {
      covered.addAll(cage.cells);
      final values = [for (final c in cage.cells) puzzle.solution[c]];
      if (!_cageArithmeticOk(cage.op, cage.target, values)) return false;
    }
    return covered.length == n * n;
  }
}

CagesPuzzle generateCages(PuzzleRequest request) =>
    CagesGenerator().generate(request);
