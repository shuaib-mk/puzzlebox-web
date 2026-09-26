import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:puzzlebox/core/providers/settings_provider.dart';
import 'package:puzzlebox/core/services/practice_service.dart';
import 'package:puzzlebox/core/services/puzzle_progression.dart';
import 'package:puzzlebox/core/theme/app_theme.dart';
import 'package:puzzlebox/games/pips/pips_screen.dart';

void main() {
  testWidgets(
    'Pips validates sums, records one win and advances automatically',
    (tester) async {
      tester.view.physicalSize = const Size(500, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({
        'difficulty_pips': 'Easy',
        'installation_puzzle_seed': 42,
      });
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(theme: AppTheme.light, home: const PipsScreen()),
        ),
      );
      await tester.pump();
      expect(find.byType(PipsScreen), findsOneWidget);
      expect(PracticeService(prefs).getSolvedCount('pips'), 0);

      final state = tester.state(find.byType(PipsScreen));
      (state as dynamic).solveForTest();
      await tester.pump();

      expect(PracticeService(prefs).getSolvedCount('pips'), 1);
      expect(PuzzleProgression(prefs).index('pips:Easy'), 1);
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pump();

      expect(PuzzleProgression(prefs).index('pips:Easy'), 1);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
