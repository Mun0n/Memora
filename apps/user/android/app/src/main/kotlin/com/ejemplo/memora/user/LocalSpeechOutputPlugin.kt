package com.ejemplo.memora.user

import android.content.Context
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.speech.tts.Voice
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale
import java.util.UUID

/**
 * Local Spanish speech output for Memora Slice 10.
 *
 * Selects an installed Spanish [Voice] whose platform metadata says it does
 * **not** require a network connection. Never silently falls back to a
 * network-required voice. Utterance completion uses real TTS callbacks —
 * never text-length or fixed-timer guesses. Audio is ephemeral platform
 * output only (no files written).
 */
class LocalSpeechOutputPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    TextToSpeech.OnInitListener {

    private lateinit var channel: MethodChannel
    private var appContext: Context? = null
    private var tts: TextToSpeech? = null
    private var ttsReady = false
    private var speakResult: MethodChannel.Result? = null
    private var activeUtteranceId: String? = null
    private var initPending: MutableList<() -> Unit> = mutableListOf()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
        ensureTts()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        releaseInternal()
        appContext = null
    }

    override fun onInit(status: Int) {
        ttsReady = status == TextToSpeech.SUCCESS
        val pending = initPending.toList()
        initPending.clear()
        for (action in pending) {
            action()
        }
        if (!ttsReady) {
            failSpeak("init_failed")
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkAvailability" -> withReadyTts {
                result.success(checkAvailability())
            }
            "speak" -> {
                val text = call.argument<String>("text") ?: ""
                val speechRate = (call.argument<Double>("speechRate") ?: 0.90).toFloat()
                val localOnly = call.argument<Boolean>("localOnly") ?: true
                if (!localOnly) {
                    result.success(
                        mapOf(
                            "kind" to "unavailable",
                            "availability" to "unavailable",
                        ),
                    )
                    return
                }
                withReadyTts {
                    speak(text, speechRate, result)
                }
            }
            "stop" -> {
                stopInternal()
                result.success(null)
            }
            "release" -> {
                releaseInternal()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun ensureTts() {
        if (tts != null) {
            return
        }
        val ctx = appContext ?: return
        tts = TextToSpeech(ctx, this)
    }

    private fun withReadyTts(action: () -> Unit) {
        ensureTts()
        if (ttsReady) {
            action()
        } else {
            initPending.add(action)
        }
    }

    private fun checkAvailability(): String {
        val engine = tts ?: return "unavailable"
        if (!ttsReady) {
            return "unavailable"
        }
        val voices = engine.voices ?: emptySet()
        val spanish = voices.filter { voice -> isSpanish(voice.locale) }
        if (spanish.isEmpty()) {
            return "unavailable"
        }
        val local = spanish.filter { voice -> !voice.isNetworkConnectionRequired }
        if (local.isNotEmpty()) {
            return "availableOnDevice"
        }
        return "networkOnlyVoices"
    }

    private fun selectLocalSpanishVoice(): Voice? {
        val engine = tts ?: return null
        val voices = engine.voices ?: return null
        return voices
            .filter { voice -> isSpanish(voice.locale) && !voice.isNetworkConnectionRequired }
            .sortedWith(
                compareByDescending<Voice> { it.locale.country.equals("ES", ignoreCase = true) }
                    .thenByDescending { it.quality }
                    .thenBy { it.name },
            )
            .firstOrNull()
    }

    private fun isSpanish(locale: Locale): Boolean {
        return locale.language.equals("es", ignoreCase = true)
    }

    private fun speak(text: String, speechRate: Float, result: MethodChannel.Result) {
        val engine = tts
        if (engine == null || !ttsReady) {
            result.success(
                mapOf(
                    "kind" to "unavailable",
                    "availability" to "unavailable",
                ),
            )
            return
        }

        val availability = checkAvailability()
        if (availability != "availableOnDevice") {
            result.success(
                mapOf(
                    "kind" to "unavailable",
                    "availability" to availability,
                ),
            )
            return
        }

        val voice = selectLocalSpanishVoice()
        if (voice == null) {
            result.success(
                mapOf(
                    "kind" to "unavailable",
                    "availability" to "unavailable",
                ),
            )
            return
        }

        // Cancel any in-flight utterance before starting a new one.
        stopInternal(completeAsCancelled = true)

        engine.voice = voice
        engine.setSpeechRate(speechRate.coerceIn(0.5f, 1.5f))
        engine.setOnUtteranceProgressListener(
            object : UtteranceProgressListener() {
                override fun onStart(utteranceId: String?) {}

                override fun onDone(utteranceId: String?) {
                    mainHandler.post {
                        if (utteranceId != activeUtteranceId) {
                            return@post
                        }
                        completeSpeak(mapOf("kind" to "completed"))
                    }
                }

                @Deprecated("Deprecated in Java")
                override fun onError(utteranceId: String?) {
                    mainHandler.post {
                        if (utteranceId != activeUtteranceId) {
                            return@post
                        }
                        completeSpeak(
                            mapOf(
                                "kind" to "error",
                                "code" to "utterance_error",
                            ),
                        )
                    }
                }

                override fun onError(utteranceId: String?, errorCode: Int) {
                    mainHandler.post {
                        if (utteranceId != activeUtteranceId) {
                            return@post
                        }
                        completeSpeak(
                            mapOf(
                                "kind" to "error",
                                "code" to "utterance_error_$errorCode",
                            ),
                        )
                    }
                }

                override fun onStop(utteranceId: String?, interrupted: Boolean) {
                    mainHandler.post {
                        if (utteranceId != activeUtteranceId) {
                            return@post
                        }
                        completeSpeak(mapOf("kind" to "cancelled"))
                    }
                }
            },
        )

        val utteranceId = UUID.randomUUID().toString()
        activeUtteranceId = utteranceId
        speakResult = result
        val params = Bundle()
        val status = engine.speak(text, TextToSpeech.QUEUE_FLUSH, params, utteranceId)
        if (status != TextToSpeech.SUCCESS) {
            activeUtteranceId = null
            speakResult = null
            result.success(
                mapOf(
                    "kind" to "error",
                    "code" to "speak_failed",
                ),
            )
        }
    }

    private fun stopInternal(completeAsCancelled: Boolean = true) {
        val engine = tts
        engine?.stop()
        if (completeAsCancelled) {
            completeSpeak(mapOf("kind" to "cancelled"))
        } else {
            speakResult = null
            activeUtteranceId = null
        }
    }

    private fun releaseInternal() {
        stopInternal(completeAsCancelled = true)
        tts?.setOnUtteranceProgressListener(null)
        tts?.shutdown()
        tts = null
        ttsReady = false
        initPending.clear()
    }

    private fun failSpeak(code: String) {
        completeSpeak(
            mapOf(
                "kind" to "error",
                "code" to code,
            ),
        )
    }

    private fun completeSpeak(payload: Map<String, Any?>) {
        val pending = speakResult ?: return
        speakResult = null
        activeUtteranceId = null
        pending.success(payload)
    }

    companion object {
        const val CHANNEL = "com.ejemplo.memora.user/local_speech_output"
    }
}
