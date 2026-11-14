package com.wrongturn.accrue

import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val shareChannel = "habit_tracker/share"
    private val focusChannel = "habit_tracker/focus"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, shareChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "shareText" -> shareText(call, result)
                    else -> result.notImplemented()
                }
            }

        MethodChannel(messenger, focusChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "supported" -> result.success(true)
                    "isEnabled" -> result.success(isFocusServiceEnabled())
                    "openSettings" -> {
                        try {
                            startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                            result.success(null)
                        } catch (error: Exception) {
                            result.error("unavailable", error.message, null)
                        }
                    }
                    "installedApps" -> result.success(installedApps())
                    "startFocus" -> {
                        val habit = call.argument<String>("habit") ?: "Focus"
                        val endsAt = call.argument<Number>("endsAt")?.toLong() ?: 0L
                        val packages = call.argument<List<String>>("packages")
                            ?: emptyList()
                        FocusAccessibilityService.prefs(this).edit()
                            .putBoolean(FocusAccessibilityService.KEY_ACTIVE, true)
                            .putString(FocusAccessibilityService.KEY_HABIT, habit)
                            .putLong(FocusAccessibilityService.KEY_ENDS, endsAt)
                            .putStringSet(
                                FocusAccessibilityService.KEY_PACKAGES,
                                packages.toSet(),
                            )
                            .apply()
                        FocusAccessibilityService.refresh()
                        result.success(null)
                    }
                    "stopFocus" -> {
                        FocusAccessibilityService.prefs(this).edit()
                            .putBoolean(FocusAccessibilityService.KEY_ACTIVE, false)
                            .apply()
                        FocusAccessibilityService.refresh()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun shareText(
        call: io.flutter.plugin.common.MethodCall,
        result: MethodChannel.Result,
    ) {
        val text = call.argument<String>("text")
        val subject = call.argument<String>("subject")
        if (text.isNullOrBlank()) {
            result.error("empty", "Nothing to share", null)
            return
        }
        try {
            val send = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_TEXT, text)
                subject?.let { putExtra(Intent.EXTRA_SUBJECT, it) }
            }
            val chooser = Intent.createChooser(send, subject ?: "Share")
            startActivity(chooser)
            result.success(true)
        } catch (error: Exception) {
            result.error("unavailable", error.message, null)
        }
    }

    private fun isFocusServiceEnabled(): Boolean {
        val enabled = Settings.Secure.getInt(
            contentResolver,
            Settings.Secure.ACCESSIBILITY_ENABLED,
            0,
        ) == 1
        if (!enabled) return false
        val services = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
        ) ?: return false
        val expected = ComponentName(
            this,
            FocusAccessibilityService::class.java,
        ).flattenToString()
        return services.split(':').any { it.equals(expected, ignoreCase = true) }
    }

    /** Launchable apps, one row per package, sorted by label. */
    private fun installedApps(): List<Map<String, String>> {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val manager = packageManager
        val resolved = try {
            manager.queryIntentActivities(intent, PackageManager.MATCH_ALL)
        } catch (error: Exception) {
            emptyList()
        }
        val rows = LinkedHashMap<String, String>()
        for (info in resolved) {
            val packageName = info.activityInfo?.packageName ?: continue
            if (packageName == this.packageName) continue
            val label = info.loadLabel(manager).toString().ifBlank { packageName }
            val existing = rows[packageName]
            if (existing == null || label.length < existing.length) {
                rows[packageName] = label
            }
        }
        return rows.entries
            .sortedBy { it.value.lowercase() }
            .map { mapOf("package" to it.key, "label" to it.value) }
    }
}
