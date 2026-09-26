import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import 'js_eval/js_eval.dart';

/// App-wide Rhythmic Haptic Feedback Service.
abstract final class AppFeedbackService {
  static const MethodChannel _channel = MethodChannel('com.etriq.puzzlebox/feedback');

  /// Light key tap feedback
  static Future<void> tap(WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    if (settings.hapticsEnabled) {
      _nativeVibrate('tap');
      await HapticFeedback.selectionClick();
      _callJSVibrate([25]);
    }
  }

  /// Rhythmic Heartbeat pulse feedback
  static Future<void> heartbeat(WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    if (settings.hapticsEnabled) {
      _nativeVibrate('heartbeat');
      await HapticFeedback.mediumImpact();
      _callJSVibrate([40, 70, 60]);
    }
  }

  /// Celebratory victory fanfare rhythm (for solved puzzles & game complete)
  static Future<void> victory(WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    if (settings.hapticsEnabled) {
      _nativeVibrate('victory');
      await HapticFeedback.heavyImpact();
      _callJSVibrate([120, 60, 150, 60, 220]);
    }
  }

  /// Error / Invalid input double buzz feedback
  static Future<void> error(WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    if (settings.hapticsEnabled) {
      _nativeVibrate('error');
      await HapticFeedback.heavyImpact();
      _callJSVibrate([90, 70, 140]);
    }
  }

  /// Test feedback triggered when turning toggle ON in settings sheet
  static Future<void> testHaptic() async {
    _nativeVibrate('victory');
    await HapticFeedback.heavyImpact();
    _callJSVibrate([120, 60, 150, 60, 220]);
  }

  static void _nativeVibrate(String type) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        _channel.invokeMethod('vibrate', {'type': type});
      } catch (_) {}
    }
  }

  static void _callJSVibrate(List<int> pattern) {
    if (kIsWeb) {
      evalJS('if (window.PuzzleboxAudio) window.PuzzleboxAudio.vibratePattern(${pattern.toString()})');
    }
  }
}
