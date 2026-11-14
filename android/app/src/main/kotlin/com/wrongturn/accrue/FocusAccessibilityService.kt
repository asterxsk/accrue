package com.wrongturn.accrue

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.util.TypedValue
import android.graphics.Typeface
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView

/**
 * Draws the "blocked" screen over the apps the user picked while a timed habit
 * runs.
 *
 * The service is declared with `canRetrieveWindowContent="false"`: it reads the
 * foreground package name from window-state events and nothing else. The
 * overlay is an accessibility overlay, which needs no SYSTEM_ALERT_WINDOW
 * grant, and it disappears the moment the timer stops.
 */
class FocusAccessibilityService : AccessibilityService() {

    companion object {
        const val PREFS = "habit_focus"
        const val KEY_ACTIVE = "active"
        const val KEY_HABIT = "habit"
        const val KEY_ENDS = "endsAt"
        const val KEY_PACKAGES = "packages"

        @Volatile
        var instance: FocusAccessibilityService? = null

        fun prefs(context: Context) =
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

        fun isActive(context: Context): Boolean =
            prefs(context).getBoolean(KEY_ACTIVE, false)

        /** Called by the app after it changes the config. */
        fun refresh() {
            instance?.applyConfig(null)
        }
    }

    private var overlay: View? = null
    private val main = Handler(Looper.getMainLooper())
    private val windowManager by lazy {
        getSystemService(Context.WINDOW_SERVICE) as WindowManager
    }
    private var remaining: TextView? = null
    private var shownPackage: String? = null

    private val tag = "FocusBlock"

    private val tick = object : Runnable {
        override fun run() {
            updateRemaining()
            val root = overlay
            if (root != null && !root.isAttachedToWindow) {
                // The system can tear the overlay down when the foreground
                // window changes; drop the reference so the next event
                // re-adds it.
                Log.d(tag, "overlay lost, re-arming")
                hideOverlay()
                applyConfig(null)
            }
            main.postDelayed(this, 1000)
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        applyConfig(null)
    }

    override fun onDestroy() {
        instance = null
        hideOverlay()
        main.removeCallbacks(tick)
        super.onDestroy()
    }

    override fun onInterrupt() {}

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val packageName = event.packageName?.toString() ?: return
        val className = event.className?.toString() ?: ""
        // IME and system chrome are not the user moving to an app.
        if (packageName == "com.android.systemui" ||
            className.contains("InputMethod") ||
            className.contains("Ime")
        ) {
            return
        }
        Log.d(tag, "window $packageName $className overlay=${overlay != null}")
        // The overlay is one of our own windows and reports this package too,
        // so only an actual activity of ours means the user came back.
        if (packageName == this.packageName) {
            if (className.contains("Activity")) hideOverlay()
            return
        }
        applyConfig(packageName)
    }

    /**
     * [foreground] is the package the user just moved to, or null when this is
     * a refresh from the app (the previously seen package is re-checked).
     */
    private fun applyConfig(foreground: String?) {
        val config = prefs(this)
        val active = config.getBoolean(KEY_ACTIVE, false) &&
            System.currentTimeMillis() < config.getLong(KEY_ENDS, 0L)
        val blocked = config.getStringSet(KEY_PACKAGES, emptySet()) ?: emptySet()

        if (!active || blocked.isEmpty()) {
            hideOverlay()
            return
        }
        val target = foreground ?: shownPackage ?: return
        if (blocked.contains(target)) {
            showOverlay(target, config.getString(KEY_HABIT, "Focus") ?: "Focus")
        } else {
            hideOverlay()
        }
    }

    private fun showOverlay(packageName: String, habit: String) {
        shownPackage = packageName
        if (overlay != null) {
            updateRemaining()
            return
        }
        val context = this
        val root = FrameLayout(context).apply {
            setBackgroundColor(Color.parseColor("#141413"))
        }
        val column = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(48, 0, 48, 0)
        }
        column.addView(
            TextView(context).apply {
                text = "FOCUS MODE"
                setTextColor(Color.parseColor("#D97757"))
                textSize = 12f
                letterSpacing = 0.16f
                typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
                gravity = Gravity.CENTER
            },
        )
        column.addView(
            TextView(context).apply {
                text = habit
                setTextColor(Color.parseColor("#FAF9F5"))
                textSize = 34f
                typeface = Typeface.create("serif", Typeface.NORMAL)
                gravity = Gravity.CENTER
                setPadding(0, 18, 0, 6)
            },
        )
        remaining = TextView(context).apply {
            setTextColor(Color.parseColor("#B0AEA5"))
            textSize = 15f
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 26)
        }
        column.addView(remaining)
        column.addView(
            TextView(context).apply {
                text = "Blocked while your focus timer runs."
                setTextColor(Color.parseColor("#B0AEA5"))
                textSize = 15f
                gravity = Gravity.CENTER
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                )
            },
        )
        column.addView(
            TextView(context).apply {
                text = "Open Habit Tracker"
                setTextColor(Color.parseColor("#141413"))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
                typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
                gravity = Gravity.CENTER
                background = GradientDrawable().apply {
                    setColor(Color.parseColor("#FAF9F5"))
                    cornerRadius = 999f
                }
                setPadding(56, 34, 56, 34)
                setOnClickListener { openApp() }
                val params = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                )
                params.topMargin = 34
                layoutParams = params
            },
        )
        root.addView(
            column,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.WRAP_CONTENT,
                Gravity.CENTER,
            ),
        )
        root.setOnClickListener { openApp() }

        val type = WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            type,
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            PixelFormat.TRANSLUCENT,
        )
        try {
            windowManager.addView(root, params)
            overlay = root
            updateRemaining()
            main.removeCallbacks(tick)
            main.postDelayed(tick, 1000)
        } catch (error: Exception) {
            Log.w(tag, "overlay failed", error)
            overlay = null
            remaining = null
        }
    }

    private fun updateRemaining() {
        val ends = prefs(this).getLong(KEY_ENDS, 0L)
        val left = ((ends - System.currentTimeMillis()) / 1000L).coerceAtLeast(0L)
        val label = remaining ?: return
        label.text = if (left <= 0) {
            "Goal reached"
        } else {
            val minutes = (left + 59) / 60
            if (minutes >= 60) {
                val hours = minutes / 60
                val rest = minutes % 60
                "$hours h $rest min left"
            } else {
                "$minutes min left"
            }
        }
    }

    private fun hideOverlay() {
        overlay?.let { view ->
            try {
                windowManager.removeView(view)
            } catch (_: Exception) {
            }
        }
        overlay = null
        remaining = null
        shownPackage = null
        main.removeCallbacks(tick)
    }

    private fun openApp() {
        hideOverlay()
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        startActivity(intent)
    }
}
