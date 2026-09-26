import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/settings_provider.dart';

final engagementServiceProvider = Provider(
  (ref) => EngagementService(ref.watch(sharedPreferencesProvider)),
);
final engagementRevisionProvider = StateProvider<int>((ref) => 0);

class EngagementSnapshot {
  final int currentStreak;
  final int bestStreak;
  final int totalCompleted;
  final List<String> playDays;
  final List<Map<String, dynamic>> history;
  final int storedPlaytimeSeconds;

  const EngagementSnapshot(
    this.currentStreak,
    this.bestStreak,
    this.totalCompleted,
    this.playDays,
    this.history, {
    this.storedPlaytimeSeconds = 0,
  });

  int get totalSeconds {
    final historySeconds = history.fold(0, (sum, item) => sum + (item['seconds'] as int? ?? 0));
    return storedPlaytimeSeconds > historySeconds ? storedPlaytimeSeconds : historySeconds;
  }

  int completedFor(String game) =>
      history.where((item) => item['game'] == game).length;

  int? bestSecondsFor(String game) {
    final times = history
        .where(
          (item) => item['game'] == game && (item['seconds'] as int? ?? 0) > 0,
        )
        .map((item) => item['seconds'] as int)
        .toList();
    return times.isEmpty ? null : times.reduce((a, b) => a < b ? a : b);
  }

  int get hardWins =>
      history.where((item) => item['difficulty'] == 'Hard').length;
}

class EngagementService {
  final SharedPreferences prefs;
  EngagementService(this.prefs);
  static const _key = 'engagement_v1';

  EngagementSnapshot load({DateTime? now}) {
    final todayStr = _day(now ?? DateTime.now());
    try {
      final data =
          jsonDecode(prefs.getString(_key) ?? '{}') as Map<String, dynamic>;
      final days = List<String>.from(
        data['days'] ?? const <String>[],
      ).toSet().toList()..sort();
      var streak = 0;
      final todayDt = _parseDay(todayStr);
      final yesterdayStr = _day(_prevDay(todayDt));

      if (days.contains(todayStr)) {
        var cursor = todayDt;
        while (days.contains(_day(cursor))) {
          streak++;
          cursor = _prevDay(cursor);
        }
      } else if (days.contains(yesterdayStr)) {
        var cursor = _prevDay(todayDt);
        while (days.contains(_day(cursor))) {
          streak++;
          cursor = _prevDay(cursor);
        }
      } else {
        streak = 0;
      }
      return EngagementSnapshot(
        streak,
        data['best'] as int? ?? 0,
        data['total'] as int? ?? 0,
        days,
        List<Map<String, dynamic>>.from(
          (data['history'] as List? ?? const []).map(
            (e) => Map<String, dynamic>.from(e as Map),
          ),
        ),
        storedPlaytimeSeconds: data['playtime_seconds'] as int? ?? 0,
      );
    } catch (_) {
      return const EngagementSnapshot(0, 0, 0, [], []);
    }
  }

  Future<void> addPlayTime(int seconds) async {
    if (seconds <= 0) return;
    try {
      final raw = prefs.getString(_key) ?? '{}';
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final currentSeconds = data['playtime_seconds'] as int? ?? 0;
      data['playtime_seconds'] = currentSeconds + seconds;
      await prefs.setString(_key, jsonEncode(data));
    } catch (_) {}
  }

  Future<EngagementSnapshot> recordCompletion({
    required String game,
    required String difficulty,
    int seconds = 0,
    DateTime? now,
  }) async {
    final current = load(now: now);
    final today = _day(now ?? DateTime.now());
    final days = {...current.playDays, today}.toList()..sort();
    final history = [
      ...current.history,
      {
        'game': game,
        'difficulty': difficulty,
        'seconds': seconds,
        'at': (now ?? DateTime.now()).toIso8601String(),
      },
    ];
    final currentStreak = _streakFor(days, today);
    final newBest = current.bestStreak > currentStreak
        ? current.bestStreak
        : currentStreak;
    final newPlaytime = (current.storedPlaytimeSeconds) + seconds;

    await prefs.setString(
      _key,
      jsonEncode({
        'days': days.takeLast(400),
        'best': newBest,
        'total': current.totalCompleted + 1,
        'history': history.takeLast(200),
        'playtime_seconds': newPlaytime,
      }),
    );
    return load(now: now);
  }

  static String _day(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  static DateTime _parseDay(String dayStr) {
    final parts = dayStr.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2]);
  }

  static DateTime _prevDay(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day - 1);
  }

  static int _streakFor(List<String> days, String todayStr) {
    var streak = 0;
    var cursor = _parseDay(todayStr);
    while (days.contains(_day(cursor))) {
      streak++;
      cursor = _prevDay(cursor);
    }
    return streak;
  }
}

extension<T> on List<T> {
  List<T> takeLast(int count) =>
      skip(length > count ? length - count : 0).toList();
}

