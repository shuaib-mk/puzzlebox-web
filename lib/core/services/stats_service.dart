import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_stats.dart';
import '../providers/settings_provider.dart';

final statsServiceProvider = Provider<StatsService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StatsService(prefs);
});

/// Reads and writes per-game statistics to SharedPreferences.
///
/// Keys are namespaced by [gameType], e.g. "daily_five_stats".
class StatsService {
  final SharedPreferences _prefs;

  StatsService(this._prefs);

  static String _key(String gameType) => '${gameType}_stats';

  GameStats loadStats(String gameType) {
    final raw = _prefs.getString(_key(gameType));
    if (raw == null) return const GameStats();
    try {
      return GameStats.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const GameStats();
    }
  }

  Future<void> saveStats(String gameType, GameStats stats) async {
    await _prefs.setString(_key(gameType), jsonEncode(stats.toJson()));
  }

  /// Records the outcome of a completed game.
  ///
  /// [guessCount] is how many guesses it took (null = lost).
  /// [maxGuesses] is the max allowed guesses.
  Future<GameStats> recordResult({
    required String gameType,
    required String todayKey,
    required bool won,
    int? guessCount,
    bool isPractice = false,
  }) async {
    final lastPlayed = getLastPlayedDate(gameType);

    GameStats current = loadStats(gameType);

    // Prevent double-counting same day in daily mode
    if (!isPractice && lastPlayed == todayKey) return current;

    int newStreak = current.currentStreak;
    if (won) {
      final today = DateTime.tryParse(todayKey);
      final previous = lastPlayed == null
          ? null
          : DateTime.tryParse(lastPlayed);
      final consecutive =
          today != null &&
          previous != null &&
          today.difference(previous).inDays == 1;
      newStreak = (consecutive || isPractice) ? current.currentStreak + 1 : 1;
    } else {
      newStreak = 0;
    }

    final newMax = newStreak > current.maxStreak
        ? newStreak
        : current.maxStreak;

    final newDist = Map<int, int>.from(current.distribution);
    if (won && guessCount != null) {
      newDist[guessCount] = (newDist[guessCount] ?? 0) + 1;
    }

    final updated = GameStats(
      gamesPlayed: current.gamesPlayed + 1,
      gamesWon: current.gamesWon + (won ? 1 : 0),
      currentStreak: newStreak,
      maxStreak: newMax,
      distribution: newDist,
    );

    await _prefs.setString(
      _key(gameType),
      jsonEncode({...updated.toJson(), 'lastPlayed': todayKey}),
    );
    return updated;
  }

  String? getLastPlayedDate(String gameType) {
    try {
      final raw = _prefs.getString(_key(gameType));
      if (raw != null) {
        final date = (jsonDecode(raw) as Map)['lastPlayed'];
        if (date is String) return date;
      }
    } catch (_) {}
    return _prefs.getString('${gameType}_last_played');
  }

  bool playedToday(String gameType, String todayKey) =>
      getLastPlayedDate(gameType) == todayKey;
}
