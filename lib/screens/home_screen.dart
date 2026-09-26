import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/settings_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_scaffold.dart';
import '../core/services/game_rules.dart';
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
import '../games/nonogram/nonogram_screen.dart';
import '../games/binary/binary_screen.dart';
import '../games/cages/cages_screen.dart';
import '../core/widgets/pressable_scale.dart';
import '../core/services/engagement_service.dart';

typedef _GameEntry = (
  String id,
  String title,
  String subtitle,
  IconData icon,
  String category,
  Color tabColor,
  Widget screen,
);


const _categoryIcons = {
  'All': Icons.apps_rounded,
  'Words': Icons.spellcheck_rounded,
  'Logic': Icons.psychology_rounded,
  'Patterns': Icons.auto_awesome_mosaic_rounded,
};

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeState();
}

class _HomeState extends ConsumerState<HomeScreen> {
  String _filter = 'All';
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  final _games = <_GameEntry>[
    (
      'chess',
      'Chess',
      'Tactics & vs AI practice',
      Icons.extension_rounded,
      'Logic',
      const Color(0xFFFB923C),
      const ChessScreen(),
    ),
    (
      'sudoku',
      'Sudoku',
      'Classic 9x9 logic placement',
      Icons.apps_rounded,
      'Logic',
      const Color(0xFFFACC15),
      const SudokuScreen(),
    ),
    (
      'daily_five',
      'Daily Five',
      '6 tries to guess 5-letter word',
      Icons.grid_on_rounded,
      'Words',
      const Color(0xFF4ADE80),
      const DailyFiveScreen(),
    ),
    (
      'connections',
      'Connections',
      'Group 4 sets of 4 words',
      Icons.hub_rounded,
      'Words',
      const Color(0xFFF43F5E),
      const ConnectionsScreen(),
    ),
    (
      'mini_crossword',
      'The Mini',
      'Quick daily 5x5 crossword',
      Icons.space_dashboard_rounded,
      'Words',
      const Color(0xFF38BDF8),
      const MiniCrosswordScreen(),
    ),
    (
      'spelling_bee',
      'Spelling Bee',
      'Spell words with 7 letters',
      Icons.hive_rounded,
      'Words',
      const Color(0xFFC084FC),
      const SpellingBeeScreen(),
    ),
    (
      'crossword',
      'Crossword',
      'Full size crossword puzzle',
      Icons.border_all_rounded,
      'Words',
      const Color(0xFFFB923C),
      const CrosswordScreen(),
    ),
    (
      'strands',
      'Strands',
      'Trace hidden theme words',
      Icons.gesture_rounded,
      'Words',
      const Color(0xFF4ADE80),
      const StrandsScreen(),
    ),
    (
      'pips',
      'Pips',
      'Domino sum grid logic',
      Icons.casino_rounded,
      'Logic',
      const Color(0xFFF43F5E),
      const PipsScreen(),
    ),
    (
      'tiles',
      'Tiles',
      'Match pattern traits',
      Icons.layers_rounded,
      'Patterns',
      const Color(0xFFFACC15),
      const TilesScreen(),
    ),
    (
      'letter_boxed',
      'Letter Boxed',
      'Chain words around sides',
      Icons.crop_square_rounded,
      'Words',
      const Color(0xFF38BDF8),
      const LetterBoxedScreen(),
    ),
    (
      'vertex',
      'Vertex',
      'Connect edges to balance',
      Icons.polyline_rounded,
      'Patterns',
      const Color(0xFFC084FC),
      const VertexScreen(),
    ),
    (
      'nonogram',
      'Nonogram',
      'Picross picture logic',
      Icons.table_chart_rounded,
      'Patterns',
      const Color(0xFF4ADE80),
      const NonogramScreen(),
    ),
    (
      'binary',
      'Binary',
      'Balance 0s and 1s in grid',
      Icons.filter_2_rounded,
      'Logic',
      const Color(0xFFF43F5E),
      const BinaryScreen(),
    ),
    (
      'cages',
      'Cages',
      'Killer Sudoku math arithmetic',
      Icons.calculate_rounded,
      'Logic',
      const Color(0xFFFACC15),
      const CagesScreen(),
    ),
  ];

  static const _newGames = <String>{};

  Future<void> _openGame(_GameEntry game) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => game.$7));
    if (mounted) setState(() {});
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          SingleChildScrollView(child: SettingsSheet(helpText: rulesFor(''))),
    );
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final primaryAccent = AppTheme.getAccentColor(const Color(0xFFFACC15), settings.palette);

    final solved = _games.fold<int>(
      0,
      (n, g) => n + ref.read(practiceServiceProvider).getSolvedCount(g.$1),
    );
    ref.watch(engagementRevisionProvider);
    final engagement = ref.read(engagementServiceProvider).load();

    final filteredGames = _games
        .where(
          (g) =>
              (_filter == 'All' || g.$5 == _filter) &&
              '${g.$2} ${g.$3}'.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Neo-Brutal Header Bar (Tuckii Style)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    _NeoSquareIconButton(
                      icon: Icons.tune_rounded,
                      onPressed: _openSettings,
                      backgroundColor: primaryAccent,
                    ),
                    const Spacer(),
                    if (engagement.currentStreak > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: primaryAccent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black, width: 2.5),
                          boxShadow: const [
                            BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_fire_department_rounded, size: 18, color: Colors.black),
                            const SizedBox(width: 4),
                            Text(
                              '${engagement.currentStreak}d Streak',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Main Neo-Brutalist Bold Headline
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Solve now.\nPlay anytime.',
                      style: TextStyle(
                        fontFamily: 'PuzzleSans',
                        fontSize: 32,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '15 hand-crafted offline logic & word puzzles.',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tuckii Search Box with Yellow Action Button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black, width: 2.5),
                          boxShadow: const [
                            BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _query = v),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: '# Search puzzle or category...',
                            hintStyle: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(Icons.search_rounded, color: Colors.black, size: 22),
                            suffixIcon: _query.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded, color: Colors.black, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _query = '');
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: primaryAccent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black, width: 2.5),
                        boxShadow: const [
                          BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.grid_view_rounded, color: Colors.black, size: 24),
                        onPressed: () {
                          setState(() {
                            _filter = 'All';
                            _query = '';
                            _searchController.clear();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Neo Metric Stat Strip Cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: _NeoStatCard(
                        value: '$solved',
                        label: 'Solved',
                        color: AppTheme.getAccentColor(const Color(0xFF4ADE80), settings.palette),
                        icon: Icons.check_circle_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _NeoStatCard(
                        value: '${engagement.currentStreak}',
                        label: 'Streak',
                        color: AppTheme.getAccentColor(const Color(0xFFFACC15), settings.palette),
                        icon: Icons.local_fire_department_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _NeoStatCard(
                        value: '${_games.length}',
                        label: 'Games',
                        color: AppTheme.getAccentColor(const Color(0xFF38BDF8), settings.palette),
                        icon: Icons.apps_rounded,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Category Chips Selection
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'My Puzzles',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.5,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${filteredGames.length} games',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categoryIcons.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final cat = _categoryIcons.keys.elementAt(i);
                          final selected = _filter == cat;
                          final count = cat == 'All'
                              ? _games.length
                              : _games.where((g) => g.$5 == cat).length;
                          return ChoiceChip(
                            avatar: Icon(
                              _categoryIcons[cat],
                              size: 16,
                              color: selected ? Colors.black : colors.onSurfaceVariant,
                            ),
                            label: Text('$cat ($count)'),
                            selected: selected,
                            onSelected: (_) => setState(() => _filter = cat),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Folder-Tab Grid Cards (Tuckii Neo-Brutal Style)
            if (filteredGames.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 44, color: isDark ? Colors.white : Colors.black),
                      const SizedBox(height: 12),
                      Text(
                        _query.isEmpty
                            ? 'No games in this category yet'
                            : 'No games match "$_query"',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 22,
                    crossAxisSpacing: 14,
                    mainAxisExtent: 155, // Folder Card Height
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final game = filteredGames[index];
                    final count = ref
                        .read(practiceServiceProvider)
                        .getSolvedCount(game.$1);
                    return _FolderCard(
                      game: game,
                      solvedCount: count,
                      isNew: _newGames.contains(game.$1),
                      onTap: () => _openGame(game),
                    );
                  }, childCount: filteredGames.length),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Neo-Brutalist Square Action Button with Hard Border & Offset Shadow
class _NeoSquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;

  const _NeoSquareIconButton({
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.primary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black, width: 2.5),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: Colors.black, size: 22),
        onPressed: onPressed,
      ),
    );
  }
}

/// Neo Stat Card Strip Tile
class _NeoStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _NeoStatCard({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2.5),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(3.5, 3.5), blurRadius: 0),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Icon(icon, size: 16, color: Colors.black),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF525252),
            ),
          ),
        ],
      ),
    );
  }
}

/// Folder-Tab Card Widget (Exact Tuckii Folder Style)
class _FolderCard extends ConsumerWidget {
  final _GameEntry game;
  final int solvedCount;
  final bool isNew;
  final VoidCallback onTap;

  const _FolderCard({
    required this.game,
    required this.solvedCount,
    required this.isNew,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final accentColor = AppTheme.getAccentColor(game.$6, settings.palette);

    return PressableScale(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('${game.$1}_folder'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Folder Main Body Card
              Container(
                width: double.infinity,
                height: double.infinity,
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border.all(color: Colors.black, width: 2.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black, width: 2.0),
                          ),
                          child: Icon(game.$4, color: Colors.black, size: 20),
                        ),
                        const Spacer(),
                        if (isNew)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF43F5E),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.black, width: 1.5),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          )
                        else if (solvedCount > 0)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4ADE80),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 1.5),
                            ),
                            child: const Icon(Icons.check_rounded, size: 12, color: Colors.black),
                          ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black,
                            letterSpacing: -.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          game.$3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF525252),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Folder Top-Left Ear/Tab
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                    border: Border.all(color: Colors.black, width: 2.5),
                  ),
                  child: Text(
                    game.$5.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .5,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
