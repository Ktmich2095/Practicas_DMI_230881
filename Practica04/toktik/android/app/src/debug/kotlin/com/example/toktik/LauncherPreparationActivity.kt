package com.example.toktik

import android.app.Activity
import android.os.Bundle

/** Debug APK only. Android 17 restricts shell pm operations; the app manages
 * its own components through its normal PackageManager API before flutter run.
 * No preference, credential or user content is changed.
 */
class LauncherPreparationActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        LauncherIcons.apply(this, "normal")
        finish()
    }
}
