package com.example.nowbar

import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.graphics.drawable.ColorDrawable
import android.media.AudioManager
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.*
import android.view.KeyEvent
import android.widget.FrameLayout
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class NowBarOverlayManager private constructor(private val context: Context) {

    companion object {
        private const val TAG = "NowBarOverlayManager"
        private const val CHANNEL = "com.example.nowbar/overlay"
        private const val FLUTTER_ENGINE_ID = "nowbar_engine"
        private const val OVERLAY_FLAGS_KEY = "overlay_data"
        
        @Volatile
        private var instance: NowBarOverlayManager? = null

        fun getInstance(context: Context): NowBarOverlayManager {
            return instance ?: synchronized(this) {
                instance ?: NowBarOverlayManager(context.applicationContext).also {
                    instance = it
                }
            }
        }
    }

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var flutterEngine: FlutterEngine? = null
    private var flutterView: FlutterView? = null
    private var methodChannel: MethodChannel? = null
    private var isShowing = false
    
    private val handler = Handler(Looper.getMainLooper())
    private var mediaSessionManager: MediaSessionManager? = null
    private var audioManager: AudioManager? = null

    init {
        windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        mediaSessionManager = context.getSystemService(Context.MEDIA_SESSION_SERVICE) as MediaSessionManager?
        audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager?
        initFlutterEngine()
    }

    private fun initFlutterEngine() {
        if (FlutterEngineCache.getInstance().contains(FLUTTER_ENGINE_ID)) {
            flutterEngine = FlutterEngineCache.getInstance().get(FLUTTER_ENGINE_ID)
            return
        }

        flutterEngine = FlutterEngine(context).apply {
            navigationChannel.setInitialRoute("/overlay")
            dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault()
            )
        }

        // Setup method channel for overlay communication
        methodChannel = MethodChannel(
            flutterEngine!!.dartExecutor.binaryMessenger,
            CHANNEL
        )

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getOverlayContext" -> {
                    val contextData = buildOverlayContext()
                    result.success(contextData)
                }
                "hideOverlay" -> {
                    hideOverlay()
                    result.success(null)
                }
                "onCapsuleChanged" -> {
                    val capsuleType = call.argument<String>("type")
                    Log.d(TAG, "Capsule changed: $capsuleType")
                    result.success(null)
                }
                "requestMediaInfo" -> {
                    val mediaInfo = getActiveMediaSessionInfo()
                    result.success(mediaInfo)
                }
                else -> result.notImplemented()
            }
        }

        FlutterEngineCache.getInstance().put(FLUTTER_ENGINE_ID, flutterEngine)
    }

    fun showOverlay() {
        if (isShowing) {
            Log.d(TAG, "Overlay already showing")
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!android.provider.Settings.canDrawOverlays(context)) {
                Log.w(TAG, "Cannot draw overlays - permission not granted")
                return
            }
        }

        handler.post {
            try {
                createOverlayView()
                isShowing = true
                Log.d(TAG, "Overlay shown")
            } catch (e: Exception) {
                Log.e(TAG, "Error showing overlay", e)
            }
        }
    }

    fun hideOverlay() {
        if (!isShowing) return

        handler.post {
            try {
                if (overlayView != null && windowManager != null) {
                    windowManager?.removeView(overlayView)
                    overlayView = null
                    flutterView = null
                }
                isShowing = false
                Log.d(TAG, "Overlay hidden")
            } catch (e: Exception) {
                Log.e(TAG, "Error hiding overlay", e)
            }
        }
    }

    private fun createOverlayView() {
        val params = WindowManager.LayoutParams().apply {
            width = WindowManager.LayoutParams.MATCH_PARENT
            height = WindowManager.LayoutParams.MATCH_PARENT
            type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                WindowManager.LayoutParams.TYPE_PHONE
            }
            flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED or
                    WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH
            format = PixelFormat.TRANSLUCENT
            gravity = Gravity.TOP or Gravity.START
            softInputMode = WindowManager.LayoutParams.SOFT_INPUT_ADJUST_NOTHING
        }

        // Create container view
        val container = FrameLayout(context).apply {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
            // Semi-transparent background
            background = ColorDrawable(0x00000000)
        }

        // Create FlutterView
        flutterView = FlutterView(context).apply {
            layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        }

        flutterEngine?.let { engine ->
            flutterView?.attachToFlutterEngine(engine)
        }

        // Add touch handling for swipe gestures
        container.setOnTouchListener { _, event ->
            flutterView?.dispatchTouchEvent(event) ?: false
        }

        container.addView(flutterView)
        overlayView = container
        windowManager?.addView(overlayView, params)

        // Send initial context data
        sendOverlayContextToFlutter()
    }

    private fun sendOverlayContextToFlutter() {
        val contextData = buildOverlayContext()
        handler.postDelayed({
            methodChannel?.invokeMethod("onOverlayContext", contextData)
        }, 500) // Small delay to ensure Flutter is ready
    }

    private fun buildOverlayContext(): String {
        val json = JSONObject().apply {
            put("type", "lock_screen")
            put("time", System.currentTimeMillis())
            put("isCharging", isDeviceCharging())
            put("batteryLevel", getBatteryLevel())
            put("hasMedia", hasActiveMediaSession())
            put("isPlaying", isMediaPlaying())
        }
        return json.toString()
    }

    private fun isDeviceCharging(): Boolean {
        val intent = context.registerReceiver(null, android.content.IntentFilter(android.content.Intent.ACTION_BATTERY_CHANGED))
        val status = intent?.getIntExtra(android.os.BatteryManager.EXTRA_STATUS, -1) ?: -1
        return status == android.os.BatteryManager.BATTERY_STATUS_CHARGING ||
                status == android.os.BatteryManager.BATTERY_STATUS_FULL
    }

    private fun getBatteryLevel(): Int {
        val intent = context.registerReceiver(null, android.content.IntentFilter(android.content.Intent.ACTION_BATTERY_CHANGED))
        val level = intent?.getIntExtra(android.os.BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale = intent?.getIntExtra(android.os.BatteryManager.EXTRA_SCALE, -1) ?: -1
        return if (level >= 0 && scale > 0) (level * 100 / scale) else -1
    }

    private fun hasActiveMediaSession(): Boolean {
        return try {
            val sessions = mediaSessionManager?.getActiveSessions(
                android.content.ComponentName(context, NowBarNotificationListener::class.java)
            )
            !sessions.isNullOrEmpty()
        } catch (e: SecurityException) {
            false
        }
    }

    private fun isMediaPlaying(): Boolean {
        return try {
            val sessions = mediaSessionManager?.getActiveSessions(
                android.content.ComponentName(context, NowBarNotificationListener::class.java)
            )
            sessions?.any { it.playbackState?.state == PlaybackState.STATE_PLAYING } == true
        } catch (e: SecurityException) {
            false
        }
    }

    fun getActiveMediaSessionInfo(): String {
        return try {
            val sessions = mediaSessionManager?.getActiveSessions(
                android.content.ComponentName(context, NowBarNotificationListener::class.java)
            )
            
            val controller = sessions?.firstOrNull()
            if (controller != null) {
                val metadata = controller.metadata
                val playbackState = controller.playbackState?.state ?: PlaybackState.STATE_NONE
                
                val json = JSONObject().apply {
                    put("title", metadata?.getString(android.media.MediaMetadata.METADATA_KEY_TITLE) ?: "Unknown")
                    put("artist", metadata?.getString(android.media.MediaMetadata.METADATA_KEY_ARTIST) ?: "Unknown Artist")
                    put("album", metadata?.getString(android.media.MediaMetadata.METADATA_KEY_ALBUM) ?: "")
                    put("duration", metadata?.getLong(android.media.MediaMetadata.METADATA_KEY_DURATION) ?: 0)
                    put("isPlaying", playbackState == PlaybackState.STATE_PLAYING)
                    put("packageName", controller.packageName)
                }
                json.toString()
            } else {
                "{}"
            }
        } catch (e: SecurityException) {
            "{}"
        } catch (e: Exception) {
            Log.e(TAG, "Error getting media info", e)
            "{}"
        }
    }

    fun dispatchMediaKeyEvent(keyCode: Int) {
        try {
            audioManager?.let { am ->
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                    val eventDown = KeyEvent(KeyEvent.ACTION_DOWN, keyCode)
                    val eventUp = KeyEvent(KeyEvent.ACTION_UP, keyCode)
                    am.dispatchMediaKeyEvent(eventDown)
                    am.dispatchMediaKeyEvent(eventUp)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error dispatching media key event", e)
        }
    }

    fun isOverlayShowing(): Boolean = isShowing

    fun destroy() {
        hideOverlay()
        try {
            FlutterEngineCache.getInstance().remove(FLUTTER_ENGINE_ID)
            flutterEngine?.destroy()
            flutterEngine = null
        } catch (e: Exception) {
            Log.e(TAG, "Error destroying FlutterEngine", e)
        }
        instance = null
    }
}