import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import 'js_eval/js_eval.dart';

/// App-wide Audio & Rhythmic Haptic Feedback Service.
abstract final class AppFeedbackService {
  static const MethodChannel _channel = MethodChannel('com.etriq.puzzlebox/feedback');

  /// Light key tap feedback
  static Future<void> tap(WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    if (settings.hapticsEnabled) {
      _nativeVibratePattern([0, 25]);
      await HapticFeedback.selectionClick();
      _callJSVibrate([25]);
    }
    if (settings.soundEnabled) {
      _nativePlayTone('tap');
      _callJSAudio('playTap');
      await SystemSound.play(SystemSoundType.click);
    }
  }

  /// Rhythmic Heartbeat pulse feedback (for winning pace, combo streaks, intense moments)
  static Future<void> heartbeat(WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    if (settings.hapticsEnabled) {
      _nativeVibratePattern([0, 40, 60, 50]);
      await HapticFeedback.mediumImpact();
      _callJSVibrate([40, 70, 60]);
    }
    if (settings.soundEnabled) {
      _nativePlayTone('heartbeat');
      _callJSAudio('playHeartbeat');
    }
  }

  /// Celebratory victory fanfare rhythm (for solved puzzles & game complete)
  static Future<void> victory(WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    if (settings.hapticsEnabled) {
      _nativeVibratePattern([0, 40, 40, 50, 40, 70]);
      await HapticFeedback.heavyImpact();
      _callJSVibrate([30, 50, 40, 50, 50]);
    }
    if (settings.soundEnabled) {
      _nativePlayTone('success');
      _callJSAudio('playSuccess');
    }
  }

  /// Error / Invalid input double buzz feedback
  static Future<void> error(WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    if (settings.hapticsEnabled) {
      _nativeVibratePattern([0, 70, 50, 90]);
      await HapticFeedback.heavyImpact();
      _callJSVibrate([80, 60, 120]);
    }
    if (settings.soundEnabled) {
      _nativePlayTone('error');
      _callJSAudio('playError');
    }
  }

  /// Test feedback triggered when turning toggles ON in settings sheet
  static Future<void> testHaptic() async {
    _nativeVibratePattern([0, 35, 50, 50]);
    await HapticFeedback.mediumImpact();
    _callJSVibrate([40, 70, 60, 120, 40]);
  }

  static Future<void> testSound() async {
    _nativePlayTone('success');
    _callJSAudio('playSuccess');
    await SystemSound.play(SystemSoundType.click);
  }

  static void _nativeVibratePattern(List<int> pattern) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        _channel.invokeMethod('vibrate', {'pattern': pattern});
      } catch (_) {}
    }
  }

  static void _nativePlayTone(String type) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        _channel.invokeMethod('playTone', {'type': type});
      } catch (_) {}
    }
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
