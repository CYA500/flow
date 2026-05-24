package com.example.nowbar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat

class ScreenStateReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "NowBarScreenStateReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return

        Log.d(TAG, "Screen state changed: $action")

        val serviceIntent = Intent(context, NowBarService::class.java).apply {
            when (action) {
                Intent.ACTION_SCREEN_ON -> {
                    this.action = NowBarService.ACTION_SCREEN_ON
                }
                Intent.ACTION_SCREEN_OFF -> {
                    this.action = NowBarService.ACTION_SCREEN_OFF
                }
                Intent.ACTION_USER_PRESENT -> {
                    this.action = NowBarService.ACTION_SCREEN_ON
                }
            }
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                ContextCompat.startForegroundService(context, serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start service", e)
        }
    }
}