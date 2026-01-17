package com.example.chrono_snap.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.example.chrono_snap.MainActivity

class CaptureForegroundService : Service() {

    companion object {
        const val CHANNEL_ID = "chrono_snap_capture_channel"
        const val NOTIFICATION_ID = 1001
        const val ACTION_START = "com.example.chrono_snap.START_CAPTURE"
        const val ACTION_STOP = "com.example.chrono_snap.STOP_CAPTURE"
        const val EXTRA_PROJECT_NAME = "project_name"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val projectName = intent.getStringExtra(EXTRA_PROJECT_NAME) ?: "Unknown"
                startForeground(NOTIFICATION_ID, createNotification(projectName))
            }
            ACTION_STOP -> {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "ChronoSnap Capture",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Foreground service for time-lapse capture"
            setShowBadge(false)
        }

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.createNotificationChannel(channel)
    }

    private fun createNotification(projectName: String): Notification {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val stopIntent = Intent(this, CaptureForegroundService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this,
            1,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("ChronoSnap - $projectName")
            .setContentText("Capturing time-lapse photos")
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .setContentIntent(pendingIntent)
            .addAction(android.R.drawable.ic_media_pause, "Stop", stopPendingIntent)
            .setOngoing(true)

        return builder.build()
    }

    fun updateNotification(projectName: String, progress: String) {
        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("ChronoSnap - $projectName")
            .setContentText(progress)
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .setOngoing(true)

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, builder.build())
    }
}
