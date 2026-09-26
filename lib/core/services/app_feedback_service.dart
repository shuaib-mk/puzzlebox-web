import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import 'js_eval/js_eval.dart';

/// App-wide Rhythmic Haptic Feedback Service.
abstract final class AppFeedbackService {
  static const MethodChannel _channel = MethodChannel('com.etriq.puzzlebox/feedback');

  static bool _isEnabled([dynamic refOrContext]) {
    if (refOrContext is WidgetRef) {
      try { return refOrContext.read(settingsProvider).hapticsEnabled; } catch (_) { return true; }
    } else if (refOrContext is Ref) {
      try { return refOrContext.read(settingsProvider).hapticsEnabled; } catch (_) { return true; }
    } else if (refOrContext is BuildContext) {
      try {
        return ProviderScope.containerOf(refOrContext, listen: false)
            .read(settingsProvider)
            .hapticsEnabled;
      } catch (_) { return true; }
    }
    return true;
  }

  /// Light key tap feedback
  static Future<void> tap([dynamic refOrContext]) async {
    if (_isEnabled(refOrContext)) {
      _nativeVibrate('tap');
      await HapticFeedback.selectionClick();
      _callJSVibrate([25]);
    }
  }

  /// Rhythmic Heartbeat pulse feedback
  static Future<void> heartbeat([dynamic refOrContext]) async {
    if (_isEnabled(refOrContext)) {
      _nativeVibrate('heartbeat');
      await HapticFeedback.mediumImpact();
      _callJSVibrate([40, 70, 60]);
    }
  }

  /// Celebratory victory fanfare rhythm (for solved puzzles & game complete)
  static Future<void> victory([dynamic refOrContext]) async {
    if (_isEnabled(refOrContext)) {
      _nativeVibrate('victory');
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.vibrate();
      await Future.delayed(const Duration(milliseconds: 150));
      await HapticFeedback.heavyImpact();
      _callJSVibrate([120, 60, 150, 60, 220]);
    }
  }

  /// Error / Invalid input double buzz feedback
  static Future<void> error([dynamic refOrContext]) async {
    if (_isEnabled(refOrContext)) {
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

