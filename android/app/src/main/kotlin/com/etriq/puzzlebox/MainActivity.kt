package com.etriq.puzzlebox

import android.content.Context
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.etriq.puzzlebox/feedback"
    private var toneGenerator: ToneGenerator? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        try {
            toneGenerator = ToneGenerator(AudioManager.STREAM_MUSIC, 80)
        } catch (e: Exception) {
            e.printStackTrace()
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "vibrate" -> {
                    val pattern = call.argument<List<Int>>("pattern")
                    if (pattern != null && pattern.isNotEmpty()) {
                        vibratePattern(pattern)
                    } else {
                        vibrateOneShot(30, 255)
                    }
                    result.success(true)
                }
                "playTone" -> {
                    val type = call.argument<String>("type") ?: "tap"
                    playNativeTone(type)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun vibrateOneShot(milliseconds: Long, amplitude: Int) {
        val vibrator = getVibrator()
        if (vibrator != null && vibrator.hasVibrator()) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val amp = if (amplitude in 1..255) amplitude else VibrationEffect.DEFAULT_AMPLITUDE
                vibrator.vibrate(VibrationEffect.createOneShot(milliseconds, amp))
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(milliseconds)
            }
        }
    }

    private fun vibratePattern(timings: List<Int>) {
        val vibrator = getVibrator()
        if (vibrator != null && vibrator.hasVibrator()) {
            val longTimings = LongArray(timings.size) { i -> timings[i].toLong() }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(VibrationEffect.createWaveform(longTimings, -1))
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(longTimings, -1)
            }
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

    private fun playNativeTone(type: String) {
        try {
            val tg = toneGenerator ?: ToneGenerator(AudioManager.STREAM_MUSIC, 80).also { toneGenerator = it }
            when (type) {
                "tap" -> tg.startTone(ToneGenerator.TONE_PROP_BEEP, 35)
                "success" -> tg.startTone(ToneGenerator.TONE_PROP_ACK, 120)
                "heartbeat" -> tg.startTone(ToneGenerator.TONE_PROP_BEEP2, 50)
                "error" -> tg.startTone(ToneGenerator.TONE_PROP_NACK, 150)
                else -> tg.startTone(ToneGenerator.TONE_PROP_BEEP, 35)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
