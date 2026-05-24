package com.example.nowbar

import android.app.*
import android.content.*
import android.content.pm.ServiceInfo
import android.os.*
import android.util.Log
import androidx.core.app.NotificationCompat

class NowBarService : Service() {

    companion object {
        private const val TAG = "NowBarService"
        private const val NOTIFICATION_CHANNEL_ID = "nowbar_channel"
        private const val NOTIFICATION_ID = 1001
        
        const val ACTION_START = "com.example.nowbar.ACTION_START"
        const val ACTION_STOP = "com.example.nowbar.ACTION_STOP"
        const val ACTION_SCREEN_ON = "com.example.nowbar.ACTION_SCREEN_ON"
        const val ACTION_SCREEN_OFF = "com.example.nowbar.ACTION_SCREEN_OFF"
        const val ACTION_MEDIA_COMMAND = "com.example.nowbar.ACTION_MEDIA_COMMAND"
        
        @Volatile
        var isRunning = false
            private set
    }

    private lateinit var overlayManager: NowBarOverlayManager
    private lateinit var wakeLock: PowerManager.WakeLock
    private var screenStateReceiver: BroadcastReceiver? = null

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "NowBarService onCreate")
        overlayManager = NowBarOverlayManager.getInstance(this)
        createNotificationChannel()
        acquireWakeLock()
        registerScreenStateReceiver()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action ?: ACTION_START
        Log.d(TAG, "onStartCommand: $action")

        when (action) {
            ACTION_START -> {
                startForegroundService()
                if (isScreenOn()) {
                    overlayManager.showOverlay()
                }
            }
            ACTION_STOP -> {
                stopService()
                return START_NOT_STICKY
            }
            ACTION_SCREEN_ON -> {
                if (isRunning) {
                    overlayManager.showOverlay()
                }
            }
            ACTION_SCREEN_OFF -> {
                overlayManager.hideOverlay()
            }
            ACTION_MEDIA_COMMAND -> {
                val mediaAction = intent.getStringExtra("media_action")
                handleMediaCommand(mediaAction)
            }
        }

        return START_STICKY
    }

    private fun startForegroundService() {
        if (isRunning) return

        val notification = createNotification()
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        isRunning = true
        Log.d(TAG, "NowBarService started in foreground")
    }

    private fun stopService() {
        Log.d(TAG, "Stopping NowBarService")
        isRunning = false
        overlayManager.hideOverlay()
        releaseWakeLock()
        unregisterScreenStateReceiver()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Now Bar Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps Now Bar active on lock screen"
                setShowBadge(false)
                enableLights(false)
                enableVibration(false)
                lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val stopIntent = Intent(this, NowBarService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 0, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val contentIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val contentPendingIntent = PendingIntent.getActivity(
            this, 0, contentIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("Now Bar")
            .setContentText("Active on lock screen")
            .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
            .setOngoing(true)
            .setSilent(true)
            .setContentIntent(contentPendingIntent)
            .addAction(android.R.drawable.ic_media_pause, "Stop", stopPendingIntent)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }

    private fun acquireWakeLock() {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "NowBar::WakeLock"
        )
        if (!wakeLock.isHeld) {
            wakeLock.acquire(10*60*1000L) // 10 minutes timeout
        }
    }

    private fun releaseWakeLock() {
        if (::wakeLock.isInitialized && wakeLock.isHeld) {
            wakeLock.release()
        }
    }

    private fun isScreenOn(): Boolean {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        return powerManager.isInteractive
    }

    private fun handleMediaCommand(action: String?) {
        when (action) {
            "play_pause" -> overlayManager.dispatchMediaKeyEvent(android.view.KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE)
            "next" -> overlayManager.dispatchMediaKeyEvent(android.view.KeyEvent.KEYCODE_MEDIA_NEXT)
            "previous" -> overlayManager.dispatchMediaKeyEvent(android.view.KeyEvent.KEYCODE_MEDIA_PREVIOUS)
            "play" -> overlayManager.dispatchMediaKeyEvent(android.view.KeyEvent.KEYCODE_MEDIA_PLAY)
            "pause" -> overlayManager.dispatchMediaKeyEvent(android.view.KeyEvent.KEYCODE_MEDIA_PAUSE)
        }
    }

    private fun registerScreenStateReceiver() {
        screenStateReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                when (intent?.action) {
                    Intent.ACTION_SCREEN_ON -> {
                        if (isRunning) {
                            overlayManager.showOverlay()
                        }
                    }
                    Intent.ACTION_SCREEN_OFF -> {
                        overlayManager.hideOverlay()
                    }
                    Intent.ACTION_USER_PRESENT -> {
                        // User unlocked, optionally hide
                        // overlayManager.hideOverlay()
                    }
                }
            }
        }

        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_USER_PRESENT)
        }
        registerReceiver(screenStateReceiver, filter)
    }

    private fun unregisterScreenStateReceiver() {
        try {
            screenStateReceiver?.let { unregisterReceiver(it) }
        } catch (e: IllegalArgumentException) {
            Log.w(TAG, "Receiver not registered")
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "NowBarService destroyed")
        isRunning = false
        releaseWakeLock()
        unregisterScreenStateReceiver()
    }
}