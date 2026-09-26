import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/models/game_stats.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/game_mode_toggle.dart';
import '../models/daily_five_state.dart';
import '../providers/daily_five_provider.dart';

/// Win/Lose result modal shown after game completion.
class ResultModal extends ConsumerWidget {
  final GameMode mode;

  const ResultModal({super.key, required this.mode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(dailyFiveProvider(mode));
    final stats = ref.watch(dailyFiveStatsProvider);
    final settings = ref.watch(settingsProvider);
    final won = game.phase == GamePhase.won;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = AppTheme.getAccentColor(const Color(0xFFFACC15), settings.palette);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 2.5),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Text(
              game.isComplete
                  ? (won ? 'Brilliant!' : 'Another word awaits')
                  : 'Daily Five statistics',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            if (game.phase == GamePhase.lost) ...[
              const SizedBox(height: 6),
              Text(
                'The word was ${game.answer.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFF43F5E),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // ── Stats Row ────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatChip(label: 'Played', value: '${stats.gamesPlayed}', accentColor: accentColor),
                _StatChip(
                  label: 'Win %',
                  value: '${stats.winPercentage.round()}%',
                  accentColor: accentColor,
                ),
                _StatChip(
                  label: 'Streak',
                  value: '${stats.currentStreak}',
                  icon: stats.currentStreak > 0 ? '🔥' : null,
                  accentColor: accentColor,
                ),
                _StatChip(label: 'Best', value: '${stats.maxStreak}', accentColor: accentColor),
              ],
            ),
            const SizedBox(height: 24),

            // ── Distribution ─────────────────────────────────────────────
            _DistributionChart(
              stats: stats,
              lastGuess: won ? game.currentRow : null,
              accentColor: accentColor,
            ),
            const SizedBox(height: 24),

            // ── Actions ──────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Share Result', style: TextStyle(fontWeight: FontWeight.w900)),
                    onPressed: !game.isComplete
                        ? null
                        : () {
                            final text = ref
                                .read(dailyFiveProvider(mode).notifier)
                                .buildShareString();
                            Share.share(text);
                          },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final String? icon;
  final Color accentColor;

  const _StatChip({
    required this.label,
    required this.value,
    this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Text(icon!, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 2),
            ],
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF525252),
          ),
        ),
      ],
    );
  }
}

class _DistributionChart extends StatelessWidget {
  final GameStats stats;
  final int? lastGuess;
  final Color accentColor;

  const _DistributionChart({
    required this.stats,
    this.lastGuess,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxVal = stats.distribution.values.fold(0, (a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GUESS DISTRIBUTION',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        ...List.generate(DailyFiveState.maxGuesses, (i) {
          final count = stats.distribution[i + 1] ?? 0;
          final isHighlight = lastGuess == i + 1;
          final fraction = maxVal == 0 ? 0.0 : count / maxVal;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final barWidth = (fraction * constraints.maxWidth).clamp(
                        32.0,
                        constraints.maxWidth,
                      );
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                        width: barWidth,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isHighlight
                              ? const Color(0xFF4ADE80)
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
