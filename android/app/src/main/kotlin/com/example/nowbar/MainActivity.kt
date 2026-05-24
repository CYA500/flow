package com.example.nowbar

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "NowBarMainActivity"
        private const val OVERLAY_PERMISSION_REQUEST_CODE = 1001
        private const val CHANNEL = "com.example.nowbar/overlay"
    }

    private lateinit var methodChannel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkOverlayPermission" -> {
                    result.success(canDrawOverlays())
                }
                "requestOverlayPermission" -> {
                    requestOverlayPermission()
                    result.success(null)
                }
                "startNowBarService" -> {
                    startNowBarService()
                    result.success(null)
                }
                "stopNowBarService" -> {
                    stopNowBarService()
                    result.success(null)
                }
                "isNowBarRunning" -> {
                    result.success(NowBarService.isRunning)
                }
                "sendMediaCommand" -> {
                    val action = call.argument<String>("action")
                    if (action != null) {
                        sendMediaCommand(action)
                        result.success(null)
                    } else {
                        result.error("INVALID_ACTION", "Media action is null", null)
                    }
                }
                "getActiveMediaSession" -> {
                    val session = NowBarOverlayManager.getInstance(this).getActiveMediaSessionInfo()
                    result.success(session)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Show when locked
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
    }

    private fun canDrawOverlays(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !canDrawOverlays()) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            )
            startActivityForResult(intent, OVERLAY_PERMISSION_REQUEST_CODE)
        }
    }

    private fun startNowBarService() {
        Log.d(TAG, "Starting NowBarService")
        val intent = Intent(this, NowBarService::class.java)
        intent.action = NowBarService.ACTION_START
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            ContextCompat.startForegroundService(this, intent)
        } else {
            startService(intent)
        }
    }

    private fun stopNowBarService() {
        Log.d(TAG, "Stopping NowBarService")
        val intent = Intent(this, NowBarService::class.java)
        intent.action = NowBarService.ACTION_STOP
        startService(intent)
    }

    private fun sendMediaCommand(action: String) {
        val intent = Intent(this, NowBarService::class.java).apply {
            this.action = NowBarService.ACTION_MEDIA_COMMAND
            putExtra("media_action", action)
        }
        startService(intent)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == OVERLAY_PERMISSION_REQUEST_CODE) {
            val granted = canDrawOverlays()
            methodChannel.invokeMethod("onOverlayPermissionResult", granted)
        }
    }
}