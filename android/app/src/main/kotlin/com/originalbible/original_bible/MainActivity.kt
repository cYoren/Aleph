package com.originalbible.original_bible

import android.content.ActivityNotFoundException
import android.content.Intent
import android.os.Bundle
import androidx.core.view.WindowCompat
import android.speech.tts.TextToSpeech
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Bridges the one part of recitation that Dart cannot reach: taking the user
 * straight to the screen where a speech voice is installed.
 *
 * Android gives an app no way to install a voice on the user's behalf, so the
 * most an app can do is remove the search. Left to itself, the only honest
 * instruction is "open Settings, then Accessibility, then Text-to-speech
 * output, then Install voice data, then find Hebrew" — which is roughly where
 * everyone gives up, and the recitation feature quietly stops existing for
 * them.
 */
class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.enableEdgeToEdge(window)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openVoiceDownload" -> result.success(openVoiceDownload())
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Opens the speech engine's own voice installer, falling back to the
     * system text-to-speech settings for engines that do not offer one.
     *
     * Returns false when neither screen can be reached, so the caller can say
     * so rather than leave a button that appears to do nothing when tapped.
     */
    private fun openVoiceDownload(): Boolean {
        val destinations = listOf(
            Intent(TextToSpeech.Engine.ACTION_INSTALL_TTS_DATA),
            Intent(SYSTEM_TTS_SETTINGS),
        )

        for (intent in destinations) {
            try {
                startActivity(intent)
                return true
            } catch (e: ActivityNotFoundException) {
                // Expected: not every engine ships an installer, and not every
                // build exposes the settings screen. Fall through and try the
                // next destination.
            }
        }
        return false
    }

    private companion object {
        const val CHANNEL = "aleph/voice_setup"
        const val SYSTEM_TTS_SETTINGS = "com.android.settings.TTS_SETTINGS"
    }
}
