package com.example.nowbar

import android.content.ComponentName
import android.media.session.MediaSessionManager
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

class NowBarNotificationListener : NotificationListenerService() {

    companion object {
        private const val TAG = "NowBarNotificationListener"
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "Notification listener connected")
        
        // Grant media session control
        try {
            val mediaSessionManager = getSystemService(MEDIA_SESSION_SERVICE) as MediaSessionManager
            mediaSessionManager.addOnActiveSessionsChangedListener(
                { sessions ->
                    Log.d(TAG, "Active media sessions changed: ${sessions?.size ?: 0}")
                    sessions?.firstOrNull()?.let { controller ->
                        val intent = android.content.Intent(this, NowBarService::class.java).apply {
                            action = NowBarService.ACTION_START
                        }
                        startService(intent)
                    }
                },
                ComponentName(this, NowBarNotificationListener::class.java)
            )
        } catch (e: SecurityException) {
            Log.e(TAG, "Failed to add media session listener", e)
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        // Handle media notifications
        sbn?.let {
            if (isMediaNotification(it)) {
                Log.d(TAG, "Media notification posted: ${it.packageName}")
            }
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
        Log.d(TAG, "Notification removed: ${sbn?.packageName}")
    }

    private fun isMediaNotification(sbn: StatusBarNotification): Boolean {
        val mediaPackages = listOf(
            "com.spotify.music",
            "com.google.android.apps.youtube.music",
            "com.apple.android.music",
            "com.deezer.android.app",
            "com.soundcloud.android",
            "com.amazon.mp3",
            "com.samsung.android.app.music.chn",
            "com.sec.android.app.music"
        )
        return sbn.packageName in mediaPackages || 
               sbn.notification?.category == android.app.Notification.CATEGORY_TRANSPORT
    }
}