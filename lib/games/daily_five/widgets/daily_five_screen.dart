import 'dart:async';
import '../../../core/providers/settings_provider.dart';
import '../models/letter_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/date_service.dart';
import '../../../core/services/practice_service.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../models/daily_five_state.dart';
import '../providers/daily_five_provider.dart';
import 'game_board.dart';
import 'keyboard_widget.dart';
import 'result_modal.dart';

import '../../../core/widgets/game_mode_toggle.dart';
import '../../../core/widgets/neo_toast.dart';
import '../../../core/widgets/neo_difficulty_bar.dart';
import '../../../core/services/app_feedback_service.dart';

/// Main screen for the Daily Five word-guessing game.
class DailyFiveScreen extends ConsumerStatefulWidget {
  const DailyFiveScreen({super.key});

  @override
  ConsumerState<DailyFiveScreen> createState() => _DailyFiveScreenState();
}

class _DailyFiveScreenState extends ConsumerState<DailyFiveScreen> {
  bool _modalShown = false;
  GameMode _mode = GameMode.practice;
  Timer? _nextTimer;
  String _difficulty = 'Medium';
  int _practiceSolvedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPracticeCount();
    _difficulty =
        ref
            .read(sharedPreferencesProvider)
            .getString('difficulty_daily_five') ??
        'Medium';
  }

  Future<void> _loadPracticeCount() async {
    final service = ref.read(practiceServiceProvider);
    setState(() {
      _practiceSolvedCount = service.getSolvedCount('daily_five');
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(dailyFiveProvider(_mode));

    if (game.isComplete && !game.isAnimating && !_modalShown) {
      _modalShown = true;
      if (_mode == GameMode.practice && game.phase == GamePhase.won) {
        _practiceSolvedCount++;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (game.phase == GamePhase.won) {
          AppFeedbackService.victory(ref);
        } else {
          AppFeedbackService.error(ref);
        }
        NeoToast.show(
          context,
          game.phase == GamePhase.won
              ? 'Solved! A fresh word is next.'
              : 'The word was ${game.answer}. Try the next one.',
          icon: game.phase == GamePhase.won ? Icons.check_circle_rounded : Icons.info_rounded,
          color: game.phase == GamePhase.won ? const Color(0xFF4ADE80) : const Color(0xFF38BDF8),
        );
        _nextTimer?.cancel();
        _nextTimer = Timer(
          Duration(seconds: game.phase == GamePhase.won ? 2 : 4),
          () {
            if (mounted) _next();
          },
        );
      });
    }

    final dateKey = DateService.todayKey();

    return AppScaffold(
      title: _mode == GameMode.daily
          ? 'Daily Five #${game.puzzleNumber}'
          : 'Daily Five — Unlimited',
      showBackButton: true,
      actions: [
        AppBarIconButton(
          icon: Icons.lightbulb_outline_rounded,
          tooltip: 'In-App Hints',
          onTap: () => _showHints(context, dateKey),
        ),
        AppBarIconButton(
          icon: Icons.bar_chart_rounded,
          tooltip: 'Stats',
          onTap: () => _showResultModal(context),
        ),
        AppBarIconButton(
          icon: Icons.settings_outlined,
          tooltip: 'Settings',
          onTap: () => _showSettings(context),
        ),
      ],
      body: Column(
        children: [
          GameModeToggle(
            mode: _mode,
            practiceSolvedCount: _practiceSolvedCount,
            onModeChanged: (m) => _onModeChanged(m),
          ),
          Divider(height: 1),
          NeoDifficultyBar(
            currentDifficulty: _difficulty,
            onDifficultyChanged: (d) async {
              await ref
                  .read(sharedPreferencesProvider)
                  .setString('difficulty_daily_five', d);
              if (!mounted) return;
              setState(() => _difficulty = d);
              _next();
            },
            onNextPressed: _next,
          ),
          _ToastBar(mode: _mode),
          SizedBox(height: 12),
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: GameBoard(mode: _mode),
              ),
            ),
          ),
          SizedBox(height: 8),
          KeyboardWidget(mode: _mode),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  void _onModeChanged(GameMode newMode) {
    _nextTimer?.cancel();
    setState(() {
      _mode = newMode;
      _modalShown = false;
    });
    if (newMode == GameMode.practice) {
      _loadPracticeCount();
    }
  }

  void _showResultModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => Padding(
        padding: EdgeInsets.only(top: 80),
        child: ResultModal(mode: _mode),
      ),
    );
  }

  Future<void> _next() async {
    _nextTimer?.cancel();
    await ref.read(dailyFiveProvider(GameMode.practice).notifier).nextPuzzle();
    if (!mounted) return;
    setState(() {
      _mode = GameMode.practice;
      _modalShown = false;
    });
    _loadPracticeCount();
  }

  @override
  void dispose() {
    _nextTimer?.cancel();
    super.dispose();
  }

  void _showHints(BuildContext context, String dateKey) {
    final game = ref.read(dailyFiveProvider(_mode));
    var position = 0;
    for (var i = 0; i < 5; i++) {
      if (!game.board
          .take(game.currentRow)
          .any((r) => r[i].state == LetterState.correct)) {
        position = i;
        break;
      }
    }
    NeoToast.show(
      context,
      'Letter ${position + 1} is ${game.answer[position]}. Use it in your next guess.',
      icon: Icons.lightbulb_rounded,
      color: const Color(0xFFFACC15),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SettingsSheet(),
    );
  }
}

/// Transient error/warning handler for Daily Five.
class _ToastBar extends ConsumerStatefulWidget {
  final GameMode mode;

  const _ToastBar({required this.mode});

  @override
  ConsumerState<_ToastBar> createState() => _ToastBarState();
}

class _ToastBarState extends ConsumerState<_ToastBar> {
  int _lastShake = 0;

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(dailyFiveProvider(widget.mode));

    if (game.shakeCount > _lastShake) {
      _lastShake = game.shakeCount;
      final message = game.currentInput.length < DailyFiveState.wordLength
          ? 'Not enough letters'
          : 'Check the word and any hard-mode clues';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AppFeedbackService.error(ref);
        NeoToast.show(
          context,
          message,
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFF43F5E),
          duration: const Duration(seconds: 2),
        );
      });
    }

    return const SizedBox.shrink();
  }
}
