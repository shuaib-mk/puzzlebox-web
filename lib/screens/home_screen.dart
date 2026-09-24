import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/widgets/app_scaffold.dart';
import '../core/services/practice_service.dart';
import '../games/daily_five/widgets/daily_five_screen.dart';
import '../games/connections/connections_screen.dart';
import '../games/spelling_bee/spelling_bee_screen.dart';
import '../games/crossword/crossword_screen.dart';
import '../games/mini_crossword/mini_crossword_screen.dart';
import '../games/sudoku/sudoku_screen.dart';
import '../games/strands/strands_screen.dart';
import '../games/pips/pips_screen.dart';
import '../games/tiles/tiles_screen.dart';
import '../games/letter_boxed/letter_boxed_screen.dart';
import '../games/vertex/vertex_screen.dart';
import '../games/chess/chess_screen.dart';
import '../core/widgets/puzzle_pal.dart';
import '../core/widgets/pressable_scale.dart';
import '../core/services/engagement_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeState();
}

class _HomeState extends ConsumerState<HomeScreen> {
  String _filter = 'All';
  String _query = '';
  final _games = <(String, String, String, IconData, String, Widget)>[
    (
      'daily_five',
      'Daily Five',
      'A word. Six guesses. Follow the clues.',
      Icons.grid_view_rounded,
      'Words',
      const DailyFiveScreen(),
    ),
    (
      'sudoku',
      'Sudoku',
      'Nine numbers. One satisfying solution.',
      Icons.apps_rounded,
      'Logic',
      const SudokuScreen(),
    ),
    (
      'connections',
      'Connections',
      'Find the thread connecting four words.',
      Icons.category_outlined,
      'Words',
      const ConnectionsScreen(),
    ),
    (
      'spelling_bee',
      'Spelling Bee',
      'Seven letters, a growing collection of words.',
      Icons.hive_outlined,
      'Words',
      const SpellingBeeScreen(),
    ),
    (
      'mini_crossword',
      'The Mini',
      'A small crossing of words and ideas.',
      Icons.dashboard_outlined,
      'Words',
      const MiniCrosswordScreen(),
    ),
    (
      'crossword',
      'Crossword',
      'Follow the clues. Fill every crossing.',
      Icons.border_all_rounded,
      'Words',
      const CrosswordScreen(),
    ),
    (
      'strands',
      'Strands',
      'Trace neighboring letters. Uncover a theme.',
      Icons.gesture_rounded,
      'Words',
      const StrandsScreen(),
    ),
    (
      'pips',
      'Pips',
      'Find a home for every domino by its sum.',
      Icons.casino_outlined,
      'Logic',
      const PipsScreen(),
    ),
    (
      'tiles',
      'Tiles',
      'Spot pairs and build a matching streak.',
      Icons.layers_outlined,
      'Patterns',
      const TilesScreen(),
    ),
    (
      'letter_boxed',
      'Letter Boxed',
      'Chain real words around all four sides.',
      Icons.crop_square_rounded,
      'Words',
      const LetterBoxedScreen(),
    ),
    (
      'vertex',
      'Vertex',
      'Connect the dots. Balance every number.',
      Icons.polyline_outlined,
      'Patterns',
      const VertexScreen(),
    ),
    (
      'chess',
      'Chess',
      'Tactics puzzles, vs AI, and Pass & Play.',
      Icons.extension_rounded,
      'Logic',
      const ChessScreen(),
    ),
  ];
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final solved = _games.fold<int>(
      0,
      (n, g) => n + ref.read(practiceServiceProvider).getSolvedCount(g.$1),
    );
    ref.watch(engagementRevisionProvider);
    final engagement = ref.read(engagementServiceProvider).load();
    final games = _games
        .where(
          (g) =>
              (_filter == 'All' || g.$5 == _filter) &&
              '${g.$2} ${g.$3}'.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    return AppScaffold(
      title: 'puzzlebox',
      showSettingsAction: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(28),
                border: Border(
                  bottom: BorderSide(
                    color: colors.primary.withValues(alpha: .25),
                    width: 5,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ready, set,\npuzzle!',
                              style: TextStyle(
                                fontSize: 32,
                                height: 1.05,
                                fontWeight: FontWeight.w900,
                                color: colors.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'A fresh challenge.\nA little victory.',
                              style: TextStyle(
                                fontSize: 15,
                                color: colors.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const PuzzlePal(size: 100),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${_games.length} games. Always free. Play offline.',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.workspace_premium_rounded,
                          color: colors.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '$solved puzzles solved',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    engagement.currentStreak == 0
                        ? '🔥 Solve one today to start a streak'
                        : '🔥 ${engagement.currentStreak} day streak',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Pick your playground',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -.5,
              ),
            ),
            const SizedBox(height: 12),
            SearchBar(
              hintText: 'Find a game',
              leading: const Icon(Icons.search_rounded),
              elevation: const WidgetStatePropertyAll(0),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['All', 'Words', 'Logic', 'Patterns']
                  .map(
                    (f) => ChoiceChip(
                      label: Text(f),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            ...games.map((game) {
              final accent = [
                const Color(0xFF157A6E),
                const Color(0xFF286CB0),
                const Color(0xFF8652B4),
                const Color(0xFFA96708),
                const Color(0xFFB84562),
              ][_games.indexOf(game) % 5];
              final count = ref
                  .read(practiceServiceProvider)
                  .getSolvedCount(game.$1);
              return PressableScale(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: colors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                      side: BorderSide(color: colors.outlineVariant, width: 2),
                    ),
                    elevation: 1,
                    shadowColor: Colors.black26,
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: ValueKey('${game.$1}_card'),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => game.$6),
                        );
                        if (mounted) setState(() {});
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                game.$4,
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? colors.onSurface
                                    : accent,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    game.$2,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    game.$3,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                  if (count > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        '$count solved',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: colors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            Text(
              'No subscriptions. No ads. No lives to refill.\nYour progress stays on this device.',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 12,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
