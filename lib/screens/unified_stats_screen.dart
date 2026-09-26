import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../core/services/stats_service.dart';
import '../core/widgets/app_scaffold.dart';
import '../core/services/practice_service.dart';
import '../core/services/engagement_service.dart';
import '../core/providers/settings_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/neo_toast.dart';

class UnifiedStatsScreen extends ConsumerWidget {
  final bool embedded;
  const UnifiedStatsScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statsService = ref.read(statsServiceProvider);
    ref.watch(engagementRevisionProvider);
    final engagement = ref.read(engagementServiceProvider).load();
    final practice = ref.read(practiceServiceProvider);
    final settings = ref.watch(settingsProvider);
    final primaryAccent = AppTheme.getAccentColor(const Color(0xFFFACC15), settings.palette);

    final games = [
      {'type': 'daily_five', 'name': 'Daily Five', 'icon': Icons.grid_on_rounded, 'color': const Color(0xFF4ADE80)},
      {'type': 'connections', 'name': 'Connections', 'icon': Icons.hub_rounded, 'color': const Color(0xFFF43F5E)},
      {'type': 'spelling_bee', 'name': 'Spelling Bee', 'icon': Icons.hive_rounded, 'color': const Color(0xFFFACC15)},
      {'type': 'crossword', 'name': 'The Crossword', 'icon': Icons.border_all_rounded, 'color': const Color(0xFF38BDF8)},
      {'type': 'mini_crossword', 'name': 'The Mini', 'icon': Icons.space_dashboard_rounded, 'color': const Color(0xFFC084FC)},
      {'type': 'strands', 'name': 'Strands', 'icon': Icons.gesture_rounded, 'color': const Color(0xFFFB923C)},
      {'type': 'sudoku', 'name': 'Sudoku', 'icon': Icons.apps_rounded, 'color': const Color(0xFF4ADE80)},
      {'type': 'pips', 'name': 'Pips', 'icon': Icons.casino_rounded, 'color': const Color(0xFFF43F5E)},
      {'type': 'tiles', 'name': 'Tiles', 'icon': Icons.layers_rounded, 'color': const Color(0xFFFACC15)},
      {'type': 'letter_boxed', 'name': 'Letter Boxed', 'icon': Icons.crop_square_rounded, 'color': const Color(0xFF38BDF8)},
      {'type': 'vertex', 'name': 'Vertex', 'icon': Icons.polyline_rounded, 'color': const Color(0xFFC084FC)},
      {'type': 'chess', 'name': 'Chess', 'icon': Icons.extension_rounded, 'color': const Color(0xFFFB923C)},
      {'type': 'nonogram', 'name': 'Nonogram', 'icon': Icons.table_chart_rounded, 'color': const Color(0xFF4ADE80)},
      {'type': 'binary', 'name': 'Binary', 'icon': Icons.filter_2_rounded, 'color': const Color(0xFFF43F5E)},
      {'type': 'cages', 'name': 'Cages', 'icon': Icons.calculate_rounded, 'color': const Color(0xFFFACC15)},
    ];

    final content = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header title container
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryAccent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black, width: 2.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
                  ],
                ),
                child: const Icon(Icons.bar_chart_rounded, color: Colors.black, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Progress',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.6,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          size: 15,
                          color: engagement.currentStreak > 0 ? const Color(0xFFF97316) : colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          engagement.currentStreak == 0
                              ? 'Solve a puzzle today to start your streak.'
                              : '${engagement.currentStreak} day streak · Best ${engagement.bestStreak}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  side: const BorderSide(color: Colors.black, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.share_rounded, size: 20, color: Colors.black),
                tooltip: 'Share Statistics',
                onPressed: () async {
                  final text = '''
Puzzlebox Statistics 🧩
• Completed Puzzles: ${engagement.totalCompleted}
• Current Streak: ${engagement.currentStreak} Days 🔥
• Best Streak: ${engagement.bestStreak} Days 🏆
• Total Play Time: ${_time(engagement.totalSeconds)} ⏱️

https://github.com/Sinxn-coder/puzzlebox
'''.trim();
                  await Clipboard.setData(ClipboardData(text: text));
                  try {
                    await Share.share(text);
                  } catch (_) {}
                  if (context.mounted) {
                    NeoToast.show(
                      context,
                      'Statistics copied to clipboard!',
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF4ADE80),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Neo Summary Metric Strip
          Row(
            children: [
              Expanded(
                child: _NeoMetricCard(
                  title: 'Solved',
                  value: '${engagement.totalCompleted}',
                  icon: Icons.check_circle_rounded,
                  color: AppTheme.getAccentColor(const Color(0xFF4ADE80), settings.palette),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NeoMetricCard(
                  title: 'Streak',
                  value: '${engagement.currentStreak}',
                  icon: Icons.local_fire_department_rounded,
                  color: AppTheme.getAccentColor(const Color(0xFFFACC15), settings.palette),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NeoMetricCard(
                  title: 'Play Time',
                  value: _time(engagement.totalSeconds),
                  icon: Icons.timer_rounded,
                  color: AppTheme.getAccentColor(const Color(0xFF38BDF8), settings.palette),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Achievements Section
          Text(
            'ACHIEVEMENTS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _NeoBadge(
                icon: Icons.flag_rounded,
                title: 'First Win',
                unlocked: engagement.totalCompleted >= 1,
                color: AppTheme.getAccentColor(const Color(0xFF4ADE80), settings.palette),
              ),
              _NeoBadge(
                icon: Icons.workspace_premium_rounded,
                title: 'Ten Solved',
                unlocked: engagement.totalCompleted >= 10,
                color: AppTheme.getAccentColor(const Color(0xFFFACC15), settings.palette),
              ),
              _NeoBadge(
                icon: Icons.local_fire_department_rounded,
                title: '7-Day Streak',
                unlocked: engagement.bestStreak >= 7,
                color: AppTheme.getAccentColor(const Color(0xFFF43F5E), settings.palette),
              ),
              _NeoBadge(
                icon: Icons.psychology_rounded,
                title: 'Hard Earned',
                unlocked: engagement.hardWins >= 1,
                color: AppTheme.getAccentColor(const Color(0xFFC084FC), settings.palette),
              ),
            ],
          ),
          if (engagement.history.isNotEmpty) ...[
            const SizedBox(height: 32),
            Text(
              'RECENT WINS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            ...engagement.history.reversed.take(5).map((item) {
              final game = games
                  .cast<Map<String, Object>>()
                  .where((g) => g['type'] == item['game'])
                  .firstOrNull;
              final seconds = item['seconds'] as int? ?? 0;
              final gameColor = AppTheme.getAccentColor((game?['color'] as Color?) ?? const Color(0xFF4ADE80), settings.palette);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black, width: 2.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black, offset: Offset(3.5, 3.5), blurRadius: 0),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: gameColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.black, size: 18),
                    ),
                    title: Text(
                      (game?['name'] as String?) ?? item['game'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                    subtitle: Text(
                      '${item['difficulty']} • ${seconds > 0 ? '${seconds}s' : 'Completed'}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.onSurfaceVariant),
                    ),
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 32),

          // Game Breakdown
          Text(
            'GAME BREAKDOWN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 14),

          ...games.map((g) {
            final st = statsService.loadStats(g['type'] as String);
            final gameColor = AppTheme.getAccentColor(g['color'] as Color, settings.palette);
            final winPct = st.winPercentage.round();

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black, width: 2.2),
                boxShadow: const [
                  BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
                ],
              ),
              child: Row(
                children: [
                  // Minimal icon container with subtle pastel background and 1.5px black border
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: gameColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black, width: 1.8),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      g['icon'] as IconData,
                      color: isDark ? Colors.white : Colors.black,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g['name'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14.5,
                            letterSpacing: -.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Daily ${st.gamesPlayed}  •  Unlimited ${practice.getSolvedCount(g['type'] as String)}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Minimal sleek percentage badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: winPct > 0
                          ? gameColor
                          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: Text(
                      '$winPct%',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: winPct > 0 ? Colors.black : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );

    if (embedded) return SafeArea(child: content);
    return AppScaffold(
      title: 'Statistics',
      showBackButton: true,
      body: content,
    );
  }
}

class _NeoMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _NeoMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black, width: 2.5),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(3.5, 3.5), blurRadius: 0),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Icon(icon, color: Colors.black, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF525252),
            ),
          ),
        ],
      ),
    );
  }
}

class _NeoBadge extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool unlocked;
  final Color color;

  const _NeoBadge({
    required this.icon,
    required this.title,
    required this.unlocked,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedOpacity(
      opacity: unlocked ? 1 : .4,
      duration: const Duration(milliseconds: 250),
      child: Container(
        width: 104,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: unlocked ? color : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black, width: 2.5),
          boxShadow: unlocked
              ? const [BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, size: 26, color: unlocked ? Colors.black : (isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11.5,
                color: unlocked ? Colors.black : (isDark ? Colors.white : Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _time(int seconds) {
  if (seconds < 60) return '${seconds}s';
  final minutes = seconds ~/ 60;
  return minutes < 60 ? '${minutes}m' : '${minutes ~/ 60}h ${minutes % 60}m';
}
