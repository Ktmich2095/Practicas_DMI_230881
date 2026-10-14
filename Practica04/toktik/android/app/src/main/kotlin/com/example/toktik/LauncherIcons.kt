package com.example.toktik

import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build

/** MainActivity remains enabled; only these launcher entry components change. */
object LauncherIcons {
    private val entries = linkedMapOf(
        "normal" to "LauncherActivity",
        "halloween" to "HalloweenAlias",
        "christmas" to "ChristmasAlias",
        "valentine" to "ValentineAlias"
    )

    fun states(context: Context): Map<String, Boolean> = entries.mapValues { (season, name) ->
        val component = ComponentName(context.packageName, "${context.packageName}.$name")
        when (context.packageManager.getComponentEnabledSetting(component)) {
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED -> true
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED -> false
            else -> season == "normal" // Manifest defaults.
        }
    }

    fun apply(context: Context, season: String) {
        require(entries.containsKey(season)) { "Unknown season" }
        val manager = context.packageManager
        val before = states(context)
        if (before[season] == true && before.values.count { it } == 1) return
        val flags = PackageManager.DONT_KILL_APP
        if (Build.VERSION.SDK_INT >= 33) {
            // Atomic batch: no interval with zero active launcher entries.
            manager.setComponentEnabledSettings(entries.map { (key, name) ->
                PackageManager.ComponentEnabledSetting(
                    ComponentName(context.packageName, "${context.packageName}.$name"),
                    if (key == season) PackageManager.COMPONENT_ENABLED_STATE_ENABLED
                    else PackageManager.COMPONENT_ENABLED_STATE_DISABLED, flags)
            })
        } else {
            // On older Android, enable the destination before disabling others.
            val target = ComponentName(context.packageName, "${context.packageName}.${entries.getValue(season)}")
            manager.setComponentEnabledSetting(target, PackageManager.COMPONENT_ENABLED_STATE_ENABLED, flags)
            for ((key, name) in entries) {
                if (key != season) manager.setComponentEnabledSetting(
                    ComponentName(context.packageName, "${context.packageName}.$name"),
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED, flags)
            }
        }
        check(states(context).values.count { it } == 1) { "Launcher state not synchronized" }
    }

    fun ensureEntry(context: Context) {
        if (states(context).values.none { it }) apply(context, "normal")
    }
}
