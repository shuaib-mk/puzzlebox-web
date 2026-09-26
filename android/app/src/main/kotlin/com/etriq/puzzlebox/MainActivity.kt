package com.etriq.puzzlebox

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.etriq.puzzlebox/feedback"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "vibrate" -> {
                    val type = call.argument<String>("type") ?: "tap"
                    triggerVibration(type)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun triggerVibration(type: String) {
        val vibrator = getVibrator() ?: return
        if (!vibrator.hasVibrator()) return

        when (type) {
            "tap" -> {
                vibrateOneShot(vibrator, 35, 255)
            }
            "victory" -> {
                val timings = longArrayOf(0, 120, 60, 150, 60, 220)
                val amplitudes = intArrayOf(0, 255, 0, 255, 0, 255)
                vibrateWaveform(vibrator, timings, amplitudes)
            }
            "heartbeat" -> {
                val timings = longArrayOf(0, 80, 70, 100)
                val amplitudes = intArrayOf(0, 255, 0, 255)
                vibrateWaveform(vibrator, timings, amplitudes)
            }
            "error" -> {
                val timings = longArrayOf(0, 90, 70, 140)
                val amplitudes = intArrayOf(0, 255, 0, 255)
                vibrateWaveform(vibrator, timings, amplitudes)
            }
            else -> {
                vibrateOneShot(vibrator, 40, 255)
            }
        }
    }

    private fun vibrateOneShot(vibrator: Vibrator, ms: Long, amplitude: Int) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createOneShot(ms, amplitude))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(ms)
        }
    }

    private fun vibrateWaveform(vibrator: Vibrator, timings: LongArray, amplitudes: IntArray) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createWaveform(timings, amplitudes, -1))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(timings, -1)
        }
    }

    private fun getVibrator(): Vibrator? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
            vibratorManager?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }
}
