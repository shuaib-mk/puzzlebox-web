import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import 'js_eval/js_eval.dart';

/// App-wide Audio & Rhythmic Haptic Feedback Service.
abstract final class AppFeedbackService {
  /// Light key tap feedback
  static Future<void> tap(WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    if (settings.hapticsEnabled) {
      await HapticFeedback.lightImpact();
      _callJSVibrate([15]);
    }
    if (settings.soundEnabled) {
      _callJSAudio('playTap');
      await SystemSound.play(SystemSoundType.click);
    }
  }

  static Future<void> _delay(int ms) async {
    if (Zone.current[#flutter.binding] != null) return;
    await Future.delayed(Duration(milliseconds: ms));
  }

  /// Rhythmic Heartbeat pulse feedback (for winning pace, combo streaks, intense moments)
  static Future<void> heartbeat(WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    if (settings.hapticsEnabled) {
      _callJSVibrate([40, 70, 60, 120, 40]);
      await HapticFeedback.mediumImpact();
      await _delay(110);
      await HapticFeedback.heavyImpact();
    }
    if (settings.soundEnabled) {
      _callJSAudio('playHeartbeat');
    }
  }

  /// Celebratory victory fanfare rhythm (for solved puzzles & game complete)
  static Future<void> victory(WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    if (settings.hapticsEnabled) {
      _callJSVibrate([30, 50, 40, 50, 50, 50, 120]);
      await HapticFeedback.mediumImpact();
      await _delay(80);
      await HapticFeedback.heavyImpact();
      await _delay(100);
      await HapticFeedback.mediumImpact();
    }
    if (settings.soundEnabled) {
      _callJSAudio('playSuccess');
    }
  }

  /// Error / Invalid input double buzz feedback
  static Future<void> error(WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    if (settings.hapticsEnabled) {
      _callJSVibrate([80, 60, 120]);
      await HapticFeedback.heavyImpact();
      await _delay(100);
      await HapticFeedback.vibrate();
    }
    if (settings.soundEnabled) {
      _callJSAudio('playError');
    }
  }

  /// Test feedback triggered when turning toggles ON in settings sheet
  static Future<void> testHaptic() async {
    _callJSVibrate([40, 70, 60, 120, 40]);
    await HapticFeedback.mediumImpact();
    await _delay(100);
    await HapticFeedback.heavyImpact();
  }

  static Future<void> testSound() async {
    _callJSAudio('playSuccess');
    await SystemSound.play(SystemSoundType.click);
  }

  static void _callJSVibrate(List<int> pattern) {
    if (kIsWeb) {
      evalJS('if (window.PuzzleboxAudio) window.PuzzleboxAudio.vibratePattern(${pattern.toString()})');
    }
  }

  static void _callJSAudio(String methodName) {
    if (kIsWeb) {
      evalJS('if (window.PuzzleboxAudio) window.PuzzleboxAudio.$methodName()');
    }
  }
}

