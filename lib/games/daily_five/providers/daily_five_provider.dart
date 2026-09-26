import 'dart:math';
import '../../../core/services/puzzle_progression.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/game_stats.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/services/date_service.dart';
import '../../../core/services/stats_service.dart';
import '../../../core/services/practice_service.dart';
import '../../../core/services/engagement_service.dart';
import '../../../core/widgets/game_mode_toggle.dart';
import '../logic/daily_five_logic.dart';
import '../logic/word_list.dart';
import '../models/daily_five_state.dart';
import '../models/letter_state.dart';

const _gameType = 'daily_five';

final statsServiceProvider = Provider<StatsService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StatsService(prefs);
});

final dailyFiveStatsProvider = Provider<GameStats>((ref) {
  return ref.watch(statsServiceProvider).loadStats(_gameType);
});

final dailyFiveProvider =
    NotifierProvider.family<DailyFiveNotifier, DailyFiveState, GameMode>(
      DailyFiveNotifier.new,
    );

class DailyFiveNotifier extends FamilyNotifier<DailyFiveState, GameMode> {
  static const _dailySavePrefix = '${_gameType}_board_';
  static const _practiceSavePrefix = '${_gameType}_practice_board_';

  int _revision = 0;
  bool _disposed = false;
  bool _advancing = false;
  String _answer() {
    final difficulty =
        ref
            .read(sharedPreferencesProvider)
            .getString('difficulty_daily_five') ??
        'Medium';
    final pool = WordList.answers
        .where(
          (w) => difficulty == 'Easy'
              ? w.split('').toSet().length == 5
              : difficulty == 'Hard'
              ? w.split('').toSet().length < 5
              : true,
        )
        .toList();
    return pool[Random(
      ref.read(puzzleProgressionProvider).seed(_gameType),
    ).nextInt(pool.length)];
  }

  Future<void> nextPuzzle() async {
    if (_advancing || _disposed) return;
    _advancing = true;
    _revision++;
    try {
      await ref.read(puzzleProgressionProvider).advance(_gameType);
      if (_disposed) return;
      state = DailyFiveState.initial(answer: _answer(), puzzleNumber: -1);
      await _saveState();
    } finally {
      _advancing = false;
    }
  }

  @override
  DailyFiveState build(GameMode mode) {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _revision++;
    });
    if (mode == GameMode.daily) {
      final puzzleNum = DateService.puzzleNumber();
      final answer = WordList.answerForPuzzle(puzzleNum);
      final saved = _loadSaved(puzzleNum, isPractice: false);
      return saved ??
          DailyFiveState.initial(answer: answer, puzzleNumber: puzzleNum);
    } else {
      return _loadSaved(-1, isPractice: true) ??
          DailyFiveState.initial(answer: _answer(), puzzleNumber: -1);
    }
  }

  void addLetter(String letter) {
    if (!RegExp(r'^[a-zA-Z]$').hasMatch(letter)) return;
    if (_advancing || state.phase != GamePhase.playing) return;
    if (state.isAnimating) return;
    if (state.currentInput.length >= DailyFiveState.wordLength) return;

    state = state.copyWith(
      currentInput: [...state.currentInput, letter.toUpperCase()],
    );
    _reflectInputOnBoard();
  }

  void deleteLetter() {
    if (_advancing || state.phase != GamePhase.playing) return;
    if (state.isAnimating) return;
    if (state.currentInput.isEmpty) return;

    final newInput = [...state.currentInput]..removeLast();
    state = state.copyWith(currentInput: newInput);
    _reflectInputOnBoard();
  }

  Future<void> submitGuess() async {
    if (_advancing || state.phase != GamePhase.playing) return;
    if (state.isAnimating) return;
    if (state.currentInput.length < DailyFiveState.wordLength) {
      _triggerShake();
      return;
    }

    final guess = state.currentInput.join();

    if (!WordList.isValidGuess(guess)) {
      _triggerShake();
      return;
    }

    if (ref.read(settingsProvider).hardModeEnabled) {
      for (final row in state.board.take(state.currentRow)) {
        final counts = <String, int>{};
        for (var i = 0; i < 5; i++) {
          if (row[i].state == LetterState.correct &&
              guess[i] != row[i].letter) {
            _triggerShake();
            return;
          }
          if (row[i].state == LetterState.correct ||
              row[i].state == LetterState.present) {
            counts[row[i].letter] = (counts[row[i].letter] ?? 0) + 1;
          }
        }
        if (counts.entries.any(
          (e) => e.key.allMatches(guess).length < e.value,
        )) {
          _triggerShake();
          return;
        }
      }
    }
    final revision = _revision;
    final evaluated = DailyFiveLogic.evaluate(guess, state.answer);
    final newKeyStates = DailyFiveLogic.mergeKeyStates(
      state.keyStates,
      evaluated,
    );

    final newBoard = _copyBoard();
    newBoard[state.currentRow] = evaluated;

    final won = guess == state.answer;
    final nextRow = state.currentRow + 1;
    final lost = !won && nextRow >= DailyFiveState.maxGuesses;
    final newPhase = won
        ? GamePhase.won
        : lost
        ? GamePhase.lost
        : GamePhase.playing;

    state = state.copyWith(
      board: newBoard,
      currentRow: nextRow,
      currentInput: [],
      keyStates: newKeyStates,
      phase: newPhase,
      isAnimating: true,
    );

    if (newPhase != GamePhase.playing) {
      await _recordStats(won: won, guessCount: won ? nextRow : null);
      if (won && arg == GameMode.practice) {
        final practiceService = ref.read(practiceServiceProvider);
        await practiceService.recordSolved(
          _gameType,
          '${ref.read(puzzleProgressionProvider).index(_gameType)}:${state.answer}',
        );
      }
    }
    if (won) {
      final difficulty =
          ref
              .read(sharedPreferencesProvider)
              .getString('difficulty_daily_five') ??
          ref.read(settingsProvider).defaultDifficulty;
      await ref
          .read(engagementServiceProvider)
          .recordCompletion(game: _gameType, difficulty: difficulty);
      ref.read(engagementRevisionProvider.notifier).state++;
    }

    await _saveState();
    await Future.delayed(const Duration(milliseconds: 850));
    if (_disposed || revision != _revision) return;
    state = state.copyWith(isAnimating: false);

    _saveState();
  }

  String buildShareString() {
    final completedRows = state.phase == GamePhase.playing
        ? state.currentRow
        : state.phase == GamePhase.won
        ? state.currentRow
        : DailyFiveState.maxGuesses;

    return DailyFiveLogic.buildShareString(
      board: state.board,
      completedRows: completedRows,
      puzzleNumber: state.puzzleNumber,
      won: state.phase == GamePhase.won,
      maxGuesses: DailyFiveState.maxGuesses,
    );
  }

  void _reflectInputOnBoard() {
    final newBoard = _copyBoard();
    final row = List<TileData>.generate(
      DailyFiveState.wordLength,
      (i) => i < state.currentInput.length
          ? TileData(letter: state.currentInput[i], state: LetterState.filled)
          : const TileData(),
    );
    newBoard[state.currentRow] = row;
    state = state.copyWith(board: newBoard);
    _saveState();
  }

  void _triggerShake() {
    state = state.copyWith(shakeCount: state.shakeCount + 1);
  }

  List<List<TileData>> _copyBoard() =>
      state.board.map((row) => List<TileData>.from(row)).toList();

  Future<void> _saveState() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final isPractice = arg == GameMode.practice;
    final savePrefix = isPractice ? _practiceSavePrefix : _dailySavePrefix;
    final key = '$savePrefix${state.puzzleNumber}';
    final encoded = jsonEncode({
      'answer': state.answer,
      'board': state.board
          .map(
            (row) =>
                row.map((t) => {'l': t.letter, 's': t.state.index}).toList(),
          )
          .toList(),
      'currentRow': state.currentRow,
      'input': state.currentInput,
      'keyStates': state.keyStates.map((k, v) => MapEntry(k, v.index)),
      'phase': state.phase.index,
    });
    await prefs.setString(key, encoded);
  }

  DailyFiveState? _loadSaved(int puzzleNum, {required bool isPractice}) {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final savePrefix = isPractice ? _practiceSavePrefix : _dailySavePrefix;
      final key = '$savePrefix$puzzleNum';
      final raw = prefs.getString(key);
      if (raw == null) return null;

      final json = jsonDecode(raw) as Map<String, dynamic>;
      final boardJson = json['board'] as List;
      final board = boardJson
          .map(
            (row) => (row as List)
                .map(
                  (t) => TileData(
                    letter: t['l'] as String,
                    state: LetterState.values[t['s'] as int],
                  ),
                )
                .toList(),
          )
          .toList();

      final keyStatesJson = json['keyStates'] as Map<String, dynamic>;
      final keyStates = keyStatesJson.map(
        (k, v) => MapEntry(k, LetterState.values[v as int]),
      );

      final answer = isPractice
          ? (json['answer'] as String)
          : WordList.answerForPuzzle(puzzleNum);

      final row = json['currentRow'] as int;
      final phase = GamePhase.values[json['phase'] as int];
      final input = List<String>.from(json['input'] ?? []);
      if (board.length != 6 ||
          board.any((r) => r.length != 5) ||
          row < 0 ||
          row > 6 ||
          (phase == GamePhase.playing && row == 6) ||
          !RegExp(r'^[A-Z]{5}$').hasMatch(answer) ||
          input.length > 5 ||
          input.any((c) => !RegExp(r'^[A-Z]$').hasMatch(c))) {
        return null;
      }
      return DailyFiveState(
        board: board,
        currentRow: row,
        currentInput: input,
        keyStates: keyStates,
        answer: answer,
        phase: GamePhase.values[json['phase'] as int],
        puzzleNumber: puzzleNum,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _recordStats({required bool won, int? guessCount}) async {
    final service = ref.read(statsServiceProvider);
    await service.recordResult(
      gameType: _gameType,
      todayKey: DateService.dateKey(
        DateTime.utc(2025, 1, 1).add(Duration(days: state.puzzleNumber)),
      ),
      won: won,
      guessCount: guessCount,
      isPractice: arg == GameMode.practice,
    );
    ref.invalidate(dailyFiveStatsProvider);
  }
}
