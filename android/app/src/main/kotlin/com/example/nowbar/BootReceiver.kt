package com.example.nowbar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat

class BootReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "NowBarBootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_QUICKBOOT_POWERON,
            Intent.ACTION_USER_PRESENT -> {
                Log.d(TAG, "Boot completed, starting NowBarService")
                startNowBarService(context)
            }
        }
    }

    private fun startNowBarService(context: Context) {
        val serviceIntent = Intent(context, NowBarService::class.java).apply {
            action = NowBarService.ACTION_START
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            ContextCompat.startForegroundService(context, serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }
}