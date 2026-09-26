import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:puzzlebox/core/providers/settings_provider.dart';
import 'package:puzzlebox/core/services/engagement_service.dart';
import 'package:puzzlebox/games/daily_five/logic/word_list.dart';
import 'package:puzzlebox/main.dart';

void main() {
  test('engagement tracks streak, history, hard wins and best time', () async {
    SharedPreferences.setMockInitialValues({});
    final service = EngagementService(await SharedPreferences.getInstance());
    await service.recordCompletion(
      game: 'sudoku',
      difficulty: 'Hard',
      seconds: 80,
      now: DateTime(2026, 9, 10),
    );
    await service.recordCompletion(
      game: 'sudoku',
      difficulty: 'Easy',
      seconds: 60,
      now: DateTime(2026, 9, 11),
    );
    final snapshot = service.load(now: DateTime(2026, 9, 11));
    expect(snapshot.currentStreak, 2);
    expect(snapshot.bestStreak, 2);
    expect(snapshot.totalCompleted, 2);
    expect(snapshot.hardWins, 1);
    expect(snapshot.bestSecondsFor('sudoku'), 60);
  });

  testWidgets('shell exposes Play, Progress, Settings and About', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(WordList.init);
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const PuzzleboxApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2200));
    for (final label in ['Play', 'Progress', 'Settings', 'About']) {
      expect(find.text(label), findsWidgets);
    }
    await tester.tap(find.text('Settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Default Difficulty'), findsOneWidget);
    await tester.tap(find.text('About'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('q04ti'), findsWidgets);
  });
}
