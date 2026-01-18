package com.example.chrono_snap

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Boot receiver - restarts foreground service when device boots
 * if there are running projects
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d(TAG, "Boot completed, checking for running projects...")

            // In a full implementation, we would:
            // 1. Load running projects from local storage
            // 2. Restart the foreground service for each running project
            // 3. Reschedule alarms if needed

            // For now, we just log the event
            // The actual restart logic should be handled by the main app
        }
    }

    companion object {
        private const val TAG = "BootReceiver"
    }
}
