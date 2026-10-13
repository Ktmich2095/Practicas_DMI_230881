package com.example.toktik

import android.app.Activity
import android.content.Intent
import android.os.Bundle

/** Normal launcher entry. Flutter always runs in the never-disabled MainActivity.
 * A separate task base prevents disabling this entry from replacing the engine.
 */
class LauncherActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val launch = Intent(intent).setClass(this, MainActivity::class.java)
        launch.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        startActivity(launch)
        finish()
    }
}
