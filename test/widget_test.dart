import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:puzzlebox/core/providers/settings_provider.dart';
import 'package:puzzlebox/core/theme/app_theme.dart';
import 'package:puzzlebox/main.dart';
import 'package:puzzlebox/games/daily_five/logic/word_list.dart';
import 'package:puzzlebox/games/daily_five/widgets/daily_five_screen.dart';
import 'package:puzzlebox/games/connections/connections_screen.dart';
import 'package:puzzlebox/games/spelling_bee/spelling_bee_screen.dart';
import 'package:puzzlebox/games/crossword/crossword_screen.dart';
import 'package:puzzlebox/games/mini_crossword/mini_crossword_screen.dart';
import 'package:puzzlebox/games/sudoku/sudoku_screen.dart';
import 'package:puzzlebox/games/strands/strands_screen.dart';
import 'package:puzzlebox/games/pips/pips_screen.dart';
import 'package:puzzlebox/games/tiles/tiles_screen.dart';
import 'package:puzzlebox/games/letter_boxed/letter_boxed_screen.dart';
import 'package:puzzlebox/games/vertex/vertex_screen.dart';
import 'package:puzzlebox/games/chess/chess_screen.dart';
import 'package:puzzlebox/games/nonogram/nonogram_screen.dart';
import 'package:puzzlebox/games/binary/binary_screen.dart';
import 'package:puzzlebox/games/cages/cages_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await WordList.init();
  });
  testWidgets('Home presents the free collection', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const PuzzleboxApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('My Puzzles'), findsOneWidget);
    expect(find.textContaining('Chess'), findsWidgets);
  });
  final screens = <String, Widget>{
    'daily_five': const DailyFiveScreen(),
    'connections': const ConnectionsScreen(),
    'spelling_bee': const SpellingBeeScreen(),
    'crossword': const CrosswordScreen(),
    'mini_crossword': const MiniCrosswordScreen(),
    'sudoku': const SudokuScreen(),
    'strands': const StrandsScreen(),
    'pips': const PipsScreen(),
    'tiles': const TilesScreen(),
    'letter_boxed': const LetterBoxedScreen(),
    'vertex': const VertexScreen(),
    'chess': const ChessScreen(),
    'nonogram': const NonogramScreen(),
    'binary': const BinaryScreen(),
    'cages': const CagesScreen(),
  };
  for (final size in [const Size(390, 844), const Size(320, 700)]) {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} loads, keeps controls and advances at $size', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final prefs = await SharedPreferences.getInstance();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: MaterialApp(theme: AppTheme.light, home: entry.value),
          ),
        );
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 500));
        });
        expect(tester.takeException(), isNull);
        if (entry.key == 'connections') {
          expect(find.text('Submit'), findsOneWidget);
        }
        if (entry.key == 'strands') {
          expect(find.text('Submit Word'), findsOneWidget);
        }
        if (entry.key != 'chess') {
          await tester.tap(find.text('Next').first, warnIfMissed: false);
          await tester.pump();
        }
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 500));
        });
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
