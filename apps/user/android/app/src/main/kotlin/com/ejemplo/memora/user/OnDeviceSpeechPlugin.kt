package com.ejemplo.memora.user

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/**
 * On-device-only speech recognition for Memora Slice 9.
 *
 * Never creates a network [SpeechRecognizer]. If on-device recognition is
 * unavailable, reports unavailable / languagePackMissing and stops.
 */
class OnDeviceSpeechPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    ActivityAware,
    PluginRegistry.RequestPermissionsResultListener {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var recognizer: SpeechRecognizer? = null
    private var listenResult: MethodChannel.Result? = null
    private var permissionResult: MethodChannel.Result? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private var timeoutRunnable: Runnable? = null
    private var permissionAsked = false

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        releaseInternal()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activity = null
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        releaseInternal()
        activity = null
        activityBinding = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkAvailability" -> result.success(checkAvailability())
            "permissionStatus" -> result.success(permissionStatus())
            "requestPermission" -> requestPermission(result)
            "listen" -> {
                val timeoutMs = call.argument<Int>("timeoutMs") ?: 8000
                val onDeviceOnly = call.argument<Boolean>("onDeviceOnly") ?: true
                if (!onDeviceOnly) {
                    // Refuse any caller that asks for network fallback.
                    result.success(
                        mapOf(
                            "kind" to "unavailable",
                            "availability" to "unavailable",
                        ),
                    )
                    return
                }
                listen(timeoutMs.toLong(), result)
            }
            "cancel" -> {
                cancelInternal()
                result.success(null)
            }
            "release" -> {
                releaseInternal()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun checkAvailability(): String {
        val act = activity ?: return "unavailable"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return if (SpeechRecognizer.isOnDeviceRecognitionAvailable(act)) {
                "availableOnDevice"
            } else if (SpeechRecognizer.isRecognitionAvailable(act)) {
                // Network recognizer may exist — we still refuse it.
                "languagePackMissing"
            } else {
                "unavailable"
            }
        }
        // Pre-API 31: cannot guarantee on-device without silent network fallback.
        return "unavailable"
    }

    private fun permissionStatus(): String {
        val act = activity ?: return "denied"
        val granted =
            ContextCompat.checkSelfPermission(act, Manifest.permission.RECORD_AUDIO) ==
                PackageManager.PERMISSION_GRANTED
        if (granted) {
            return "granted"
        }
        if (!permissionAsked) {
            return "notDetermined"
        }
        val showRationale =
            ActivityCompat.shouldShowRequestPermissionRationale(
                act,
                Manifest.permission.RECORD_AUDIO,
            )
        return if (showRationale) "denied" else "permanentlyDenied"
    }

    private fun requestPermission(result: MethodChannel.Result) {
        val act = activity
        if (act == null) {
            result.success("denied")
            return
        }
        if (permissionStatus() == "granted") {
            result.success("granted")
            return
        }
        if (permissionResult != null) {
            result.success("denied")
            return
        }
        permissionAsked = true
        permissionResult = result
        ActivityCompat.requestPermissions(
            act,
            arrayOf(Manifest.permission.RECORD_AUDIO),
            REQUEST_RECORD_AUDIO,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != REQUEST_RECORD_AUDIO) {
            return false
        }
        val pending = permissionResult ?: return false
        permissionResult = null
        pending.success(permissionStatus())
        return true
    }

    private fun listen(timeoutMs: Long, result: MethodChannel.Result) {
        val act = activity
        if (act == null) {
            result.success(mapOf("kind" to "unavailable", "availability" to "unavailable"))
            return
        }
        if (checkAvailability() != "availableOnDevice") {
            result.success(
                mapOf(
                    "kind" to "unavailable",
                    "availability" to checkAvailability(),
                ),
            )
            return
        }
        if (permissionStatus() != "granted") {
            result.success(
                mapOf(
                    "kind" to "permissionDenied",
                    "permanent" to (permissionStatus() == "permanentlyDenied"),
                ),
            )
            return
        }
        if (listenResult != null) {
            result.success(mapOf("kind" to "error", "code" to "already_listening"))
            return
        }

        listenResult = result
        releaseRecognizerOnly()

        val created =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                SpeechRecognizer.createOnDeviceSpeechRecognizer(act)
            } else {
                null
            }
        if (created == null) {
            finishListen(mapOf("kind" to "unavailable", "availability" to "unavailable"))
            return
        }
        recognizer = created
        created.setRecognitionListener(
            object : RecognitionListener {
                override fun onReadyForSpeech(params: Bundle?) {}

                override fun onBeginningOfSpeech() {
                    cancelTimeout()
                }

                override fun onRmsChanged(rmsdB: Float) {}

                override fun onBufferReceived(buffer: ByteArray?) {}

                override fun onEndOfSpeech() {}

                override fun onError(error: Int) {
                    val kind =
                        when (error) {
                            SpeechRecognizer.ERROR_NO_MATCH,
                            SpeechRecognizer.ERROR_SPEECH_TIMEOUT,
                            -> "silence"
                            SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "permissionDenied"
                            SpeechRecognizer.ERROR_CLIENT,
                            SpeechRecognizer.ERROR_RECOGNIZER_BUSY,
                            -> "cancelled"
                            else -> "error"
                        }
                    val payload = mutableMapOf<String, Any?>("kind" to kind)
                    if (kind == "error") {
                        payload["code"] = "android_$error"
                    }
                    if (kind == "permissionDenied") {
                        payload["permanent"] = false
                    }
                    finishListen(payload)
                }

                override fun onResults(results: Bundle?) {
                    val texts =
                        results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    val text = texts?.firstOrNull()?.trim().orEmpty()
                    if (text.isEmpty()) {
                        finishListen(mapOf("kind" to "silence"))
                    } else {
                        // Ephemeral transcript for Dart classification only.
                        finishListen(mapOf("kind" to "recognized", "text" to text))
                    }
                }

                override fun onPartialResults(partialResults: Bundle?) {}

                override fun onEvent(eventType: Int, params: Bundle?) {}
            },
        )

        val intent =
            Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(
                    RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                    RecognizerIntent.LANGUAGE_MODEL_FREE_FORM,
                )
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, "es-ES")
                putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, false)
                // Prefer offline; createOnDeviceSpeechRecognizer already binds on-device.
                putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
            }

        scheduleTimeout(timeoutMs)
        try {
            created.startListening(intent)
        } catch (error: Exception) {
            finishListen(mapOf("kind" to "error", "code" to "start_failed"))
        }
    }

    private fun scheduleTimeout(timeoutMs: Long) {
        cancelTimeout()
        val runnable =
            Runnable {
                finishListen(mapOf("kind" to "timeout"))
            }
        timeoutRunnable = runnable
        mainHandler.postDelayed(runnable, timeoutMs)
    }

    private fun cancelTimeout() {
        timeoutRunnable?.let { mainHandler.removeCallbacks(it) }
        timeoutRunnable = null
    }

    private fun cancelInternal() {
        cancelTimeout()
        try {
            recognizer?.cancel()
        } catch (_: Exception) {
        }
        if (listenResult != null) {
            finishListen(mapOf("kind" to "cancelled"))
        } else {
            releaseRecognizerOnly()
        }
    }

    private fun releaseInternal() {
        cancelTimeout()
        if (listenResult != null) {
            finishListen(mapOf("kind" to "cancelled"))
        }
        releaseRecognizerOnly()
    }

    private fun releaseRecognizerOnly() {
        try {
            recognizer?.stopListening()
        } catch (_: Exception) {
        }
        try {
            recognizer?.destroy()
        } catch (_: Exception) {
        }
        recognizer = null
    }

    private fun finishListen(payload: Map<String, Any?>) {
        cancelTimeout()
        val pending = listenResult
        listenResult = null
        releaseRecognizerOnly()
        pending?.success(payload)
    }

    companion object {
        const val CHANNEL = "com.ejemplo.memora.user/on_device_speech"
        private const val REQUEST_RECORD_AUDIO = 9109
    }
}
