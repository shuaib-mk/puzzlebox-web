import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:puzzlebox/core/mixins/practice_mode_mixin.dart';
import 'package:puzzlebox/core/providers/settings_provider.dart';
import 'package:puzzlebox/core/services/puzzle_progression.dart';
import 'package:puzzlebox/core/widgets/game_mode_toggle.dart';

class SessionHarness extends ConsumerStatefulWidget {
  const SessionHarness({super.key});
  @override
  ConsumerState<SessionHarness> createState() => SessionHarnessState();
}

class SessionHarnessState extends ConsumerState<SessionHarness>
    with PracticeModeMixin {
  int moves = 0;
  @override
  String get gameType => 'regression';
  @override
  void initState() {
    super.initState();
    initPracticeMode();
    startSession();
  }

  @override
  void onPracticeModeChanged(GameMode mode) {
    moves = 0;
    startSession();
  }

  @override
  Map<String, dynamic> captureProgress() => {'moves': moves};
  @override
  void restoreProgress(Map<String, dynamic> data) =>
      moves = data['moves'] as int;
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: buildPracticeModeToggle());
}

void main() {
  testWidgets(
    'Repeated Next taps advance once and difficulty saves remain separate',
    (tester) async {
      SharedPreferences.setMockInitialValues({'installation_puzzle_seed': 42});
      final prefs = await SharedPreferences.getInstance();
      final key = GlobalKey<SessionHarnessState>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(home: SessionHarness(key: key)),
        ),
      );
      final state = key.currentState!;
      final first = state.puzzleSeed();
      await Future.wait([
        state.nextPuzzle(),
        state.nextPuzzle(),
        state.nextPuzzle(),
      ]);
      await tester.pump();
      expect(PuzzleProgression(prefs).index('regression:Medium'), 1);
      expect(state.puzzleSeed(), isNot(first));
      state.moves = 7;
      await tester.tap(find.text('Hard'));
      await tester.pumpAndSettle();
      expect(state.moves, 0);
      state.moves = 3;
      await tester.tap(find.text('Medium'));
      await tester.pumpAndSettle();
      expect(state.moves, 7);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
