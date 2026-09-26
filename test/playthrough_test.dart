import 'dart:math';
import 'package:puzzlebox/games/spelling_bee/spelling_bee_screen.dart';
import 'package:puzzlebox/games/letter_boxed/letter_boxed_screen.dart';
import 'package:puzzlebox/games/letter_boxed/boxed_generator.dart';
import 'package:puzzlebox/games/vertex/vertex_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:puzzlebox/core/providers/settings_provider.dart';
import 'package:puzzlebox/core/services/practice_service.dart';
import 'package:puzzlebox/core/services/puzzle_content.dart';
import 'package:puzzlebox/core/theme/app_theme.dart';
import 'package:puzzlebox/games/daily_five/logic/word_list.dart';
import 'package:puzzlebox/games/connections/connections_screen.dart';
import 'package:puzzlebox/games/crossword/crossword_screen.dart';
import 'package:puzzlebox/games/crossword/crossword_generator.dart';
import 'package:puzzlebox/games/sudoku/sudoku_screen.dart';
import 'package:puzzlebox/games/sudoku/sudoku_generator.dart';
import 'package:puzzlebox/games/strands/strands_screen.dart';
import 'package:puzzlebox/games/strands/strands_solver.dart';
import 'package:puzzlebox/games/tiles/tiles_screen.dart';

void main() {
  Future<SharedPreferences> mount(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(500, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'installation_puzzle_seed': 42});
    final prefs = await SharedPreferences.getInstance();
    await tester.runAsync(WordList.init);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(theme: AppTheme.light, home: screen),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 700)),
    );
    await tester.pump();
    return prefs;
  }

  Future<void> verifyWin(
    WidgetTester tester,
    SharedPreferences prefs,
    String game,
  ) async {
    await tester.pump();
    expect(PracticeService(prefs).getSolvedCount(game), 1);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 700)),
    );
    await tester.pump();
    expect(PracticeService(prefs).getSolvedCount(game), 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets(
    'Sudoku full entry through visible cells completes and advances',
    (tester) async {
      final prefs = await mount(tester, const SudokuScreen());
      final dynamic state = tester.state(find.byType(SudokuScreen));
      final puzzle = generateSudoku(state.puzzleRequest);
      for (var i = 0; i < 81; i++) {
        if (puzzle.givens[i] != 0) continue;
        await tester.tap(find.byKey(ValueKey('sudoku_${i ~/ 9}_${i % 9}')));
        await tester.pump();
        await tester.tap(
          find.byKey(ValueKey('sudoku_number_${puzzle.solution[i]}')),
        );
        await tester.pump();
      }
      await verifyWin(tester, prefs, 'sudoku');
    },
  );
  for (final mini in [false, true]) {
    testWidgets('${mini ? 'Mini' : 'Crossword'} full cell playthrough', (
      tester,
    ) async {
      final prefs = await mount(tester, CrosswordScreen(mini: mini));
      final dynamic state = tester.state(find.byType(CrosswordScreen));
      final puzzle = CrosswordGenerator().generate(state.puzzleRequest);
      for (var i = 0; i < puzzle.solution.length; i++) {
        if (puzzle.solution[i] == '#') continue;
        await tester.tap(find.byKey(ValueKey('crossword_cell_$i')));
        await tester.pump();
        // The keyboard's letter is the final exact match after grid cells.
        await tester.tap(find.text(puzzle.solution[i]).last);
        await tester.pump();
      }
      await verifyWin(tester, prefs, mini ? 'mini_crossword' : 'crossword');
    });
  }
  testWidgets('Connections solves all four groups', (tester) async {
    final prefs = await mount(tester, const ConnectionsScreen());
    var solved = 0;
    for (final words in categoryBank.values) {
      final visible = words
          .where((w) => find.text(w).evaluate().isNotEmpty)
          .toList();
      if (visible.length != 4) continue;
      for (final word in visible) {
        await tester.tap(find.text(word));
        await tester.pump();
      }
      await tester.tap(find.text('Submit'));
      await tester.pump();
      solved++;
      if (solved == 4) break;
    }
    expect(solved, 4);
    await verifyWin(tester, prefs, 'connections');
  });
  testWidgets('Tiles matches every pair and progresses', (tester) async {
    final prefs = await mount(tester, const TilesScreen());
    final symbols = tester
        .widgetList<Text>(find.byType(Text))
        .map((w) => w.data ?? '')
        .where((w) => w.runes.length == 1)
        .toSet();
    for (final symbol in symbols) {
      if (find.text(symbol).evaluate().length != 2) continue;
      await tester.tap(find.text(symbol).first);
      await tester.pump();
      await tester.tap(find.text(symbol).last);
      await tester.pump();
    }
    await verifyWin(tester, prefs, 'tiles');
  });
  testWidgets('Strands hints produce a complete non-overlapping board', (
    tester,
  ) async {
    final prefs = await mount(tester, const StrandsScreen());
    for (
      var i = 0;
      i < 15 && PracticeService(prefs).getSolvedCount('strands') == 0;
      i++
    ) {
      await tester.tap(find.byTooltip('In-App Hints'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));
      final submitFinder = find.text('Submit Word');
      if (submitFinder.evaluate().isNotEmpty) {
        await tester.tap(submitFinder, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
    await verifyWin(tester, prefs, 'strands');
  });

  testWidgets('Spelling Bee accepts a complete set of playable words', (
    tester,
  ) async {
    final prefs = await mount(tester, const SpellingBeeScreen());
    final dynamic state = tester.state(find.byType(SpellingBeeScreen));
    final random = Random(state.puzzleSeed());
    final bases = List<String>.from(beePangrams)..shuffle(random);
    final letters = bases.first.split('').toSet().toList()..shuffle(random);
    final words = {...WordList.answers, ...clueBank.keys, ...beePangrams}
        .where(
          (w) =>
              w.length >= 4 &&
              w.contains(letters.first) &&
              w.split('').every(letters.contains),
        )
        .take(6)
        .toList();
    for (final word in words) {
      for (final letter in word.split('')) {
        await tester.tap(find.text(letter).last);
        await tester.pump();
      }
      await tester.tap(find.text('Enter'));
      await tester.pump();
    }
    await verifyWin(tester, prefs, 'spelling_bee');
  });
  testWidgets(
    'Letter Boxed completes a legal chain through the letter controls',
    (tester) async {
      final prefs = await mount(tester, const LetterBoxedScreen());
      final dynamic state = tester.state(find.byType(LetterBoxedScreen));
      final puzzle = generateBoxed(
        {...WordList.answers, ...clueBank.keys}.toList(),
        state.puzzleSeed(),
        3,
      );
      for (var i = 0; i < puzzle.solution.length; i++) {
        final word = puzzle.solution[i];
        for (final letter in word.substring(i == 0 ? 0 : 1).split('')) {
          await tester.tap(find.text(letter).last);
          await tester.pump();
        }
        await tester.tap(find.text('Submit Word'));
        await tester.pump();
      }
      await verifyWin(tester, prefs, 'letter_boxed');
    },
  );
  testWidgets(
    'Vertex undo restores a removed edge and valid degree graphs win',
    (tester) async {
      final prefs = await mount(tester, const VertexScreen());
      dynamic painter() => tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .firstWhere(
            (w) => w.painter.runtimeType.toString() == '_VertexPainter',
          )
          .painter;
      Future<void> connect(int a, int b) async {
        await tester.tap(find.byKey(ValueKey('vertex_dot_$a')));
        await tester.pump();
        await tester.tap(find.byKey(ValueKey('vertex_dot_$b')));
        await tester.pump();
      }

      await connect(1, 2);
      await connect(1, 2);
      expect((painter().connections as List).length, 0);
      await tester.tap(find.text('Undo'));
      await tester.pump();
      expect((painter().connections as List).length, 1);
      await tester.tap(find.text('Undo'));
      await tester.pump();
      expect((painter().connections as List).length, 0);
      final dots = List<DotNode>.from(painter().dots);
      final remaining = {for (final d in dots) d.id: d.targetConnections};
      while (remaining.values.any((n) => n > 0)) {
        final ordered = remaining.keys.toList()
          ..sort((a, b) => remaining[b]!.compareTo(remaining[a]!));
        final a = ordered.first, count = remaining[ordered.first]!;
        remaining[a] = 0;
        for (final b in ordered.skip(1).take(count)) {
          expect(remaining[b], greaterThan(0));
          remaining[b] = remaining[b]! - 1;
          await connect(a, b);
        }
      }
      await verifyWin(tester, prefs, 'vertex');
    },
  );
  test('Strands solver respects occupied cells and rejects blocked boards', () {
    final grid = [
      ['C', 'A', 'T'],
      ['D', 'O', 'G'],
    ];
    final solution = solveStrands(grid, ['CAT', 'DOG'], {});
    expect(solution, isNotNull);
    expect(solution!.values.expand((v) => v).toSet().length, 6);
    expect(solveStrands(grid, ['CAT'], {1}), isNull);
  });
}
