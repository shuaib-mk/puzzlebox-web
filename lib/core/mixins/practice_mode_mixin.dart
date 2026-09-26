import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/game_mode_toggle.dart';
import '../widgets/neo_toast.dart';
import '../widgets/neo_difficulty_bar.dart';
import '../services/app_feedback_service.dart';
import '../services/practice_service.dart';
import '../services/puzzle_progression.dart';
import '../services/date_service.dart';
import '../providers/settings_provider.dart';
import '../services/engagement_service.dart';
import '../services/stats_service.dart';
import '../widgets/celebration_burst.dart';

mixin PracticeModeMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  String get gameType;
  GameMode _mode = GameMode.practice;
  String _dayKey = DateService.todayKey();
  String get dailyDateKey => _dayKey;
  GameMode get mode => _mode;
  int _practiceSolvedCount = 0;
  int get practiceSolvedCount => _practiceSolvedCount;
  String difficulty = 'Medium';
  int _generation = 0;
  bool _finishing = false;
  bool _transitioning = false;
  bool _advanceReserved = false;
  Timer? _advanceTimer;
  Timer? _saveTimer;
  final Stopwatch _sessionWatch = Stopwatch();
  SharedPreferences? _prefs;
  String? _sessionKey;
  String? _sessionId;
  String? _sessionMode;
  Map<String, dynamic> captureProgress() => {};
  void restoreProgress(Map<String, dynamic> data) {}
  void startSession() {
    _sessionWatch
      ..reset()
      ..start();
    _saveTimer?.cancel();
    _prefs = ref.read(sharedPreferencesProvider);
    _sessionKey = 'session_v2_${gameType}_${mode.name}_$difficulty';
    _sessionId = puzzleRequest.id;
    _sessionMode = mode.name;
    try {
      final raw =
          _prefs!.getString(_sessionKey!) ??
          _prefs!.getString('session_v1_$gameType');
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        if (data['id'] == puzzleRequest.id && data['mode'] == mode.name) {
          restoreProgress(Map<String, dynamic>.from(data['progress']));
        }
      }
    } catch (_) {
      /* An invalid older save must not prevent play. */
    }
    _prefs!.remove('session_v1_$gameType');
    _saveTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _saveSession(),
    );
  }

  void _saveSession() {
    if (!mounted) return;
    if (_sessionWatch.isRunning) {
      final elapsed = _sessionWatch.elapsed.inSeconds;
      if (elapsed > 0) {
        ref.read(engagementServiceProvider).addPlayTime(elapsed);
        _sessionWatch.reset();
        _sessionWatch.start();
        ref.read(engagementRevisionProvider.notifier).state++;
      }
    }
    if (_prefs == null || _sessionKey == null || _finishing) return;
    final data = captureProgress();
    if (data.isEmpty) return;
    _prefs!.setString(
      _sessionKey!,
      jsonEncode({'id': _sessionId, 'mode': _sessionMode, 'progress': data}),
    );
  }

  String get _progressionKey => '$gameType:$difficulty';

  int puzzleSeed() => mode == GameMode.daily
      ? stableSeed('$gameType:$_dayKey:$difficulty')
      : stableSeed(
          '${ref.read(puzzleProgressionProvider).seed(gameType, progressionKey: _progressionKey)}:$difficulty',
        );
  PuzzleRequest get puzzleRequest => PuzzleRequest(
    gameType,
    puzzleSeed(),
    PuzzleDifficulty.values.byName(difficulty.toLowerCase()),
  );
  void onPracticeModeChanged(GameMode mode) {}
  void loadDailyPuzzle() {}
  void loadPracticePuzzle() {}
  Future<void> initPracticeMode() async {
    _practiceSolvedCount = ref
        .read(practiceServiceProvider)
        .getSolvedCount(gameType);
    difficulty =
        ref.read(sharedPreferencesProvider).getString('difficulty_$gameType') ??
        ref.read(settingsProvider).defaultDifficulty;
    if (!['Easy', 'Medium', 'Hard'].contains(difficulty)) difficulty = 'Medium';
    final prefs = ref.read(sharedPreferencesProvider);
    for (final level in ['Easy', 'Medium', 'Hard']) {
      final key = 'progress_v1_$gameType:$level';
      if (!prefs.containsKey(key)) {
        prefs.setInt(key, ref.read(puzzleProgressionProvider).index(gameType));
      }
    }
  }

  Future<void> recordPracticeWin() async => finishPuzzle();
  void recordPracticeLoss() => finishPuzzle(won: false);
  Future<void> finishPuzzle({bool won = true, String? explanation}) async {
    if (_finishing || _transitioning || !mounted) return;
    _finishing = true;
    _saveTimer?.cancel();
    if (_sessionKey != null) _prefs?.remove(_sessionKey!);
    final generation = _generation;

    try {
      if (mode == GameMode.practice && won) {
        final count = await ref
            .read(practiceServiceProvider)
            .recordSolved(gameType, puzzleRequest.id);
        if (!mounted || generation != _generation) return;
        setState(() => _practiceSolvedCount = count);
      }
      if (won) {
        await ref
            .read(engagementServiceProvider)
            .recordCompletion(
              game: gameType,
              difficulty: difficulty,
              seconds: _sessionWatch.elapsed.inSeconds,
            );
        await ref
            .read(statsServiceProvider)
            .recordResult(
              gameType: gameType,
              todayKey: DateService.todayKey(),
              won: true,
              isPractice: mode == GameMode.practice,
            );
        ref.read(engagementRevisionProvider.notifier).state++;
        if (mounted) showCelebrationBurst(context);
      }
      if (!mounted || generation != _generation) return;
      await ref.read(puzzleProgressionProvider).advance(_progressionKey);
      _advanceReserved = true;
      if (!mounted || generation != _generation) return;
      if (explanation != null) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(won ? 'Nicely solved!' : 'Here are the connections'),
            content: SingleChildScrollView(child: Text(explanation)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Next puzzle'),
              ),
            ],
          ),
        );
        if (mounted && generation == _generation) await nextPuzzle();
        return;
      }
      if (won) {
        AppFeedbackService.victory(ref);
      } else {
        AppFeedbackService.heartbeat(ref);
      }
      NeoToast.show(
        context,
        won
            ? 'Nicely solved. Next puzzle coming up!'
            : 'Fresh puzzle coming up.',
        icon: won ? Icons.check_circle_rounded : Icons.auto_awesome_rounded,
        color: won ? const Color(0xFF4ADE80) : const Color(0xFF38BDF8),
        duration: const Duration(milliseconds: 2000),
      );
      _advanceTimer?.cancel();
      _advanceTimer = Timer(const Duration(milliseconds: 1400), () {
        if (mounted && generation == _generation) nextPuzzle();
      });
    } catch (_) {
      _finishing = false;
      if (mounted) {
        showPuzzleHint('Your save could not be written. Use Next to retry.');
      }
    }
  }

  Future<void> nextPuzzle() async {
    if (_transitioning || (_finishing && !_advanceReserved)) return;
    _transitioning = true;
    _advanceTimer?.cancel();
    _saveTimer?.cancel();
    final generation = ++_generation;
    try {
      if (!_advanceReserved) {
        await ref.read(puzzleProgressionProvider).advance(_progressionKey);
      }
      _advanceReserved = false;
      if (!mounted || generation != _generation) return;
      setState(() {
        _mode = GameMode.practice;
        _finishing = false;
        onPracticeModeChanged(_mode);
      });
    } catch (_) {
      if (mounted) {
        showPuzzleHint('Unable to save. Your current puzzle is still here.');
      }
    } finally {
      _transitioning = false;
    }
  }

  bool shouldShowNextButton(bool isSolved) => isSolved;
  void showPuzzleHint(String message) {
    NeoToast.show(
      context,
      message,
      icon: Icons.lightbulb_rounded,
      color: const Color(0xFFFACC15),
    );
  }

  Widget buildPracticeModeToggle() => Column(
    children: [
      GameModeToggle(
        mode: mode,
        practiceSolvedCount: practiceSolvedCount,
        onModeChanged: (value) {
          if (value == mode || _transitioning || _finishing) return;
          _saveSession();
          _saveTimer?.cancel();
          _advanceTimer?.cancel();
          _generation++;
          _advanceReserved = false;
          setState(() {
            _dayKey = DateService.todayKey();
            _mode = value;
            _finishing = false;
            onPracticeModeChanged(value);
          });
        },
      ),
      NeoDifficultyBar(
        currentDifficulty: difficulty,
        onDifficultyChanged: (value) {
          if (value == difficulty || _transitioning || _finishing) return;
          _saveSession();
          _saveTimer?.cancel();
          _advanceTimer?.cancel();
          _generation++;
          _advanceReserved = false;
          ref
              .read(sharedPreferencesProvider)
              .setString('difficulty_$gameType', value);
          setState(() {
            difficulty = value;
            _finishing = false;
            onPracticeModeChanged(mode);
          });
        },
        onNextPressed: nextPuzzle,
      ),
    ],
  );
  @override
  void dispose() {
    _saveSession();
    _saveTimer?.cancel();
    _advanceTimer?.cancel();
    super.dispose();
  }
}
