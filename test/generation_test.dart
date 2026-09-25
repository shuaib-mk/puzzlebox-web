import 'package:flutter_test/flutter_test.dart';
import 'package:puzzlebox/core/services/puzzle_progression.dart';
import 'package:puzzlebox/core/services/puzzle_content.dart';
import 'package:puzzlebox/games/sudoku/sudoku_generator.dart';
import 'package:puzzlebox/games/crossword/crossword_generator.dart';
import 'package:puzzlebox/games/letter_boxed/boxed_generator.dart';
import 'package:puzzlebox/games/daily_five/logic/word_list.dart';
import 'package:puzzlebox/games/nonogram/nonogram_generator.dart';
import 'package:puzzlebox/games/binary/binary_generator.dart';
import 'package:puzzlebox/games/cages/cages_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Sudoku: unique valid solutions, varied seeds and real clue presets',
    () {
      final counts = <int>[];
      for (final difficulty in PuzzleDifficulty.values) {
        var total = 0;
        for (var seed = 0; seed < 30; seed++) {
          final generator = SudokuGenerator();
          final request = PuzzleRequest('sudoku', seed, difficulty);
          final p = generator.generate(request);
          expect(generator.validate(p), isTrue);
          expect(generator.generate(request).givens, p.givens);
          for (var i = 0; i < 9; i++) {
            expect(p.solution.sublist(i * 9, i * 9 + 9).toSet().length, 9);
            expect(
              {for (var r = 0; r < 9; r++) p.solution[r * 9 + i]}.length,
              9,
            );
          }
          total += p.givens.where((n) => n != 0).length;
        }
        counts.add(total);
      }
      expect(counts[0], greaterThan(counts[1]));
      expect(counts[1], greaterThan(counts[2]));
    },
  );
  test('Crosswords: every clue agrees at every crossing across 600 boards', () {
    final generator = CrosswordGenerator();
    for (final game in ['crossword', 'mini_crossword']) {
      for (final difficulty in PuzzleDifficulty.values) {
        for (var seed = 0; seed < 100; seed++) {
          final p = generator.generate(PuzzleRequest(game, seed, difficulty));
          expect(
            generator.validate(p),
            isTrue,
            reason: '$game $difficulty $seed',
          );
          expect(
            p.entries.map((e) => e.answer).toSet().length,
            p.entries.length,
          );
          for (final e in p.entries) {
            expect(clueBank[e.answer], e.clue);
          }
        }
      }
    }
  });
  test(
    'Letter Boxed: chain uses every letter, real words and alternating sides',
    () async {
      await WordList.init();
      final words = {...WordList.answers, ...clueBank.keys}.toList();
      for (final count in [3, 4]) {
        for (var seed = 0; seed < 60; seed++) {
          final p = generateBoxed(words, seed, count);
          expect(p.sides.map((s) => s.length), [3, 3, 3, 3]);
          expect(
            p.solution.join().split('').toSet(),
            p.sides.expand((s) => s).toSet(),
          );
          for (var i = 0; i < p.solution.length; i++) {
            final w = p.solution[i];
            expect(words, contains(w));
            if (i > 0) expect(w[0], p.solution[i - 1].split('').last);
            for (var j = 1; j < w.length; j++) {
              expect(
                p.sides.indexWhere((s) => s.contains(w[j])),
                isNot(p.sides.indexWhere((s) => s.contains(w[j - 1]))),
              );
            }
          }
        }
      }
    },
  );
  test('Nonogram: every board is logically solvable from its own clues', () {
    final generator = NonogramGenerator();
    for (final difficulty in PuzzleDifficulty.values) {
      for (var seed = 0; seed < 30; seed++) {
        final p = generator.generate(PuzzleRequest('nonogram', seed, difficulty));
        expect(
          generator.validate(p),
          isTrue,
          reason: 'nonogram $difficulty $seed',
        );
        expect(p.solution.length, p.size * p.size);
        expect(generator.generate(PuzzleRequest('nonogram', seed, difficulty)).solution, p.solution);
      }
    }
  });
  test('Binary: unique, balanced, triple-free and repeat-free grids', () {
    final generator = BinaryGenerator();
    for (final difficulty in PuzzleDifficulty.values) {
      for (var seed = 0; seed < 30; seed++) {
        final p = generator.generate(PuzzleRequest('binary', seed, difficulty));
        expect(
          generator.validate(p),
          isTrue,
          reason: 'binary $difficulty $seed',
        );
        expect(p.givens.length, p.size * p.size);
        expect(
          generator.generate(PuzzleRequest('binary', seed, difficulty)).givens,
          p.givens,
        );
      }
    }
  });
  test('Cages: Latin-square solutions that satisfy every cage exactly', () {
    final generator = CagesGenerator();
    for (final difficulty in PuzzleDifficulty.values) {
      for (var seed = 0; seed < 30; seed++) {
        final p = generator.generate(PuzzleRequest('cages', seed, difficulty));
        expect(
          generator.validate(p),
          isTrue,
          reason: 'cages $difficulty $seed',
        );
        final covered = p.cages.expand((c) => c.cells).toSet();
        expect(covered.length, p.size * p.size);
      }
    }
  });
}
