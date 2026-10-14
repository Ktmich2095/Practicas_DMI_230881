package com.example.toktik

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** An update resets the default entry so flutter run can launch its APK again.
 * Flutter then restores the persisted season. This never runs periodically.
 */
class LauncherUpdateReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_MY_PACKAGE_REPLACED) LauncherIcons.apply(context, "normal")
    }
}
