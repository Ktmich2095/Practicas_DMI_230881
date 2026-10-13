package com.example.toktik

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

open class MainActivity : FlutterActivity() {
    private val iconExecutor = Executors.newSingleThreadExecutor()
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        LauncherIcons.ensureEntry(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "toktik/season_identity")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getStates" -> result.success(LauncherIcons.states(this))
                    "setSeason" -> {
                        val season = call.argument<String>("season")
                        if (season == null) { result.error("INVALID_SEASON", "Missing season", null) }
                        else iconExecutor.execute {
                            try {
                                LauncherIcons.apply(this, season)
                                runOnUiThread { result.success(null) }
                            } catch (_: Exception) {
                                runOnUiThread { result.error("ICON_UPDATE_FAILED", "Launcher could not apply season", null) }
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
    override fun onDestroy() { iconExecutor.shutdown(); super.onDestroy() }
}
