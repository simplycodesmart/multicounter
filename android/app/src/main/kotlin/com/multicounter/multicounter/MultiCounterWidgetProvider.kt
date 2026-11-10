
package com.multicounter.multicounter

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.os.SystemClock
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject
import kotlin.math.max

class MultiCounterWidgetProvider : AppWidgetProvider() {

    companion object {
        const val PREFS_NAME = "multicounter_widget_configs"
        const val CONFIG_PREFIX = "widget_"
        const val ACTION_WIDGET_PINNED =    "com.multicounter.multicounter.WIDGET_PINNED"

        fun parseColor(config: JSONObject, key: String, defaultColor: Int): Int {
            val value = config.opt(key) ?: return defaultColor
            return when (value) {
                is Number -> value.toLong().toInt()
                is String -> {
                    try {
                        if (value.startsWith("#")) {
                            Color.parseColor(value)
                        } else {
                            value.toLong().toInt()
                        }
                    } catch (_: Exception) {
                        defaultColor
                    }
                }
                else -> defaultColor
            }
        }
        private const val SECOND = 1_000L
        private const val MINUTE = 60L * SECOND
        private const val HOUR = 60L * MINUTE
        private const val DAY = 24L * HOUR

        private const val ACTION_WIDGET_REFRESH =
            "com.multicounter.multicounter.WIDGET_REFRESH"

        private const val EXTRA_REFRESH_WIDGET_ID = "refresh_widget_id"

        private const val DEFAULT_REFRESH_INTERVAL = MINUTE
        private const val MIN_REFRESH_INTERVAL = MINUTE

        fun configKey(widgetId: Int): String =
            "$CONFIG_PREFIX$widgetId"

        private fun refreshPendingIntent(
            context: Context,
            widgetId: Int
        ): PendingIntent {
            val intent = Intent(
                context,
                MultiCounterWidgetProvider::class.java
            ).apply {
                action = ACTION_WIDGET_REFRESH
                putExtra(EXTRA_REFRESH_WIDGET_ID, widgetId)
                data = Uri.parse("multicounter://widget-refresh/$widgetId")
            }

            return PendingIntent.getBroadcast(
                context,
                widgetId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or
                    PendingIntent.FLAG_IMMUTABLE
            )
        }

        /**
         * Schedule a separate alarm for every configured widget.
         * Android may delay inexact alarms because of Doze and
         * battery optimization.
         */
        fun scheduleWidgetRefresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val provider = ComponentName(
                context,
                MultiCounterWidgetProvider::class.java
            )

            val widgetIds = manager.getAppWidgetIds(provider)
            val prefs = context.getSharedPreferences(
                PREFS_NAME,
                Context.MODE_PRIVATE
            )

            widgetIds.forEach { widgetId ->
                val raw = prefs.getString(configKey(widgetId), null)

                if (raw.isNullOrBlank()) {
                    cancelWidgetRefresh(context, widgetId)
                    return@forEach
                }

                val config = try {
                    JSONObject(raw)
                } catch (_: Exception) {
                    cancelWidgetRefresh(context, widgetId)
                    return@forEach
                }

                val requestedInterval = config.optLong(
                    "refreshIntervalMs",
                    DEFAULT_REFRESH_INTERVAL
                )

                // Zero or negative means manual refresh only.
                if (requestedInterval <= 0L) {
                    cancelWidgetRefresh(context, widgetId)
                    return@forEach
                }

                // This implementation uses a 1-minute minimum.
                val interval = max(
                    MIN_REFRESH_INTERVAL,
                    requestedInterval
                )

                val alarmManager = context.getSystemService(
                    Context.ALARM_SERVICE
                ) as AlarmManager

                alarmManager.setInexactRepeating(
                    AlarmManager.ELAPSED_REALTIME,
                    SystemClock.elapsedRealtime() + interval,
                    interval,
                    refreshPendingIntent(context, widgetId)
                )
            }
        }

        fun cancelWidgetRefresh(
            context: Context,
            widgetId: Int
        ) {
            val alarmManager = context.getSystemService(
                Context.ALARM_SERVICE
            ) as AlarmManager

            alarmManager.cancel(
                refreshPendingIntent(context, widgetId)
            )
        }

            
    fun updateWidget(
        context: Context,
        widgetId: Int
    ) {
        if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            return
        }
    
        val intent = Intent(
            context,
            MultiCounterWidgetProvider::class.java
        ).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(
                AppWidgetManager.EXTRA_APPWIDGET_IDS,
                intArrayOf(widgetId)
            )
        }
    
        context.sendBroadcast(intent)
        scheduleWidgetRefresh(context)
    }
    

        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val provider = ComponentName(
                context,
                MultiCounterWidgetProvider::class.java
            )

            val ids = manager.getAppWidgetIds(provider)

            if (ids.isEmpty()) return

            val intent = Intent(
                context,
                MultiCounterWidgetProvider::class.java
            ).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(
                    AppWidgetManager.EXTRA_APPWIDGET_IDS,
                    ids
                )
            }

            context.sendBroadcast(intent)
            scheduleWidgetRefresh(context)
        }
    }

    /**
     * Handles scheduled refresh alarms.
     * Refreshes only the widget whose alarm fired.
     */
    override fun onReceive(
            context: Context,
            intent: Intent
        ) {
            // Android confirms that the widget has been pinned.
            if (intent.action == ACTION_WIDGET_PINNED) {
            
                val widgetId = intent.getIntExtra(
                    AppWidgetManager.EXTRA_APPWIDGET_ID,
                    AppWidgetManager.INVALID_APPWIDGET_ID
                )
            
                if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
                    android.util.Log.e(
                        "MultiCounterWidget",
                        "Pin callback received without a valid widget ID"
                    )
                    return
                }
            
                val prefs = context.getSharedPreferences(
                    PREFS_NAME,
                    Context.MODE_PRIVATE
                )
            
                val configJson = prefs.getString(
                    "pending_widget_config",
                    null
                )
            
                if (configJson.isNullOrBlank()) {
                    android.util.Log.e(
                        "MultiCounterWidget",
                        "No pending configuration for widget $widgetId"
                    )
                    return
                }
            
                try {
                    val config = JSONObject(configJson)
                    val counterId = config.optString("counterId", "")
                
                    if (counterId.isBlank() || counterId == "null") {
                        android.util.Log.e(
                            "MultiCounterWidget",
                            "Invalid counter configuration for widget $widgetId"
                        )
                        return
                    }
                
                    val saved = prefs.edit()
                        .putString(configKey(widgetId), config.toString())
                        .remove("pending_widget_config")
                        .commit()
                
                    android.util.Log.d(
                        "MultiCounterWidget",
                        "Pin callback: widget=$widgetId, counter=$counterId, saved=$saved"
                    )
                
                    if (saved) {
                        updateWidget(context, widgetId)
                    }
                
                } catch (error: Exception) {
                    android.util.Log.e(
                        "MultiCounterWidget",
                        "Failed to save pinned widget configuration",
                        error
                    )
                }
            
                return
            }
        
            // Existing scheduled refresh handling.
            if (intent.action == ACTION_WIDGET_REFRESH) {
                val widgetId = intent.getIntExtra(
                    EXTRA_REFRESH_WIDGET_ID,
                    AppWidgetManager.INVALID_APPWIDGET_ID
                )
            
                if (widgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                    refreshWidgetNow(context, widgetId)
                }
            
                return
            }
        
            super.onReceive(context, intent)
        }

    private fun refreshWidgetNow(
        context: Context,
        widgetId: Int
    ) {
        val manager = AppWidgetManager.getInstance(context)
        val provider = ComponentName(
            context,
            MultiCounterWidgetProvider::class.java
        )

        if (widgetId !in manager.getAppWidgetIds(provider)) {
            cancelWidgetRefresh(context, widgetId)
            return
        }

        val prefs = context.getSharedPreferences(
            PREFS_NAME,
            Context.MODE_PRIVATE
        )

        val raw = prefs.getString(configKey(widgetId), null)

        if (raw.isNullOrBlank()) {
            cancelWidgetRefresh(context, widgetId)
            return
        }

        val config = try {
            JSONObject(raw)
        } catch (_: Exception) {
            JSONObject()
        }

        renderWidget(
            context,
            manager,
            widgetId,
            config
        )
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences(
            PREFS_NAME,
            Context.MODE_PRIVATE
        )

        appWidgetIds.forEach { widgetId ->
            val json = prefs.getString(configKey(widgetId), null)

            val config = try {
                if (!json.isNullOrBlank()) {
                    JSONObject(json)
                } else {
                    JSONObject()
                }
            } catch (_: Exception) {
                JSONObject()
            }

            renderWidget(
                context,
                appWidgetManager,
                widgetId,
                config
            )
        }

        scheduleWidgetRefresh(context)
    }

    private fun renderWidget(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
        config: JSONObject
    ) {
        
        val views = RemoteViews(
            context.packageName,
            R.layout.multicounter_widget
        )

        // Counter configuration
        val counterId = config.optString("counterId", "")
        val hasConfig = counterId.isNotBlank() &&
            counterId != "null"

            android.util.Log.d(
                "MultiCounterWidget",
                "Rendering widget $widgetId, counterId=$counterId, config=$config"
            )

        val title = if (hasConfig) {
            config.optString("title", "MultiCounter")
                .ifBlank { "MultiCounter" }
        } else {
            "Open MultiCounter to connect a counter"
        }

        val type = config.optString("type", "countdown")
            .lowercase()
            .replace("_", "")
            .replace("-", "")
            .replace(" ", "")

        val isTally = type == "tally"
        val isCountdown = type == "countdown"
        val isCountUp = type == "countup"

        val target = config.optLong("targetEpoch", 0L)
        val created = config.optLong("createdEpoch", 0L)
        val currentValue = config.optLong("currentValue", 0L)

        val background = parseColor(
            config,
            "background",
            Color.rgb(23, 23, 23)
        )

        val accent = parseColor(
            config,
            "accent",
            Color.rgb(255, 212, 0)
        )

        val fontSize = config.optDouble(
            "fontSize",
            25.0
        ).toFloat().coerceIn(10f, 60f)

        android.util.Log.d(
    "MultiCounterWidget",
    "ACCENT CHECK widget=$widgetId " +
        "color=#${accent.toUInt().toString(16).uppercase()} " +
        "raw=${config.opt("accent")}"
)

        val showTitle = config.optBoolean("showTitle", true)
        val showDays = config.optBoolean("showDays", true)
        val showHours = config.optBoolean("showHours", true)
        val showMinutes = config.optBoolean("showMinutes", true)
        val showSeconds = config.optBoolean("showSeconds", true)
        val showLabels = config.optBoolean("showLabels", true)

            val layout = config.optString("layout", "Classic")
    val size = config.optString("size", "Medium")

    val density = context.resources.displayMetrics.density

    val sizeScale = when (size) {
        "Small" -> 0.82f
        "Large" -> 1.18f
        else -> 1.0f
    }

    val layoutScale = when (layout) {
        "Bold" -> 1.15f
        "Minimal" -> 0.95f
        else -> 1.0f
    }

    val finalFontSize = (fontSize * sizeScale * layoutScale)
        .coerceIn(10f, 48f)

    val horizontalPadding = when (size) {
        "Small" -> (8 * density).toInt()
        "Large" -> (16 * density).toInt()
        else -> (12 * density).toInt()
    }

    val verticalPadding = when (size) {
        "Small" -> (6 * density).toInt()
        "Large" -> (14 * density).toInt()
        else -> (10 * density).toInt()
    }

    views.setViewPadding(
        R.id.widget_root,
        horizontalPadding,
        verticalPadding,
        horizontalPadding,
        verticalPadding
    )

    android.util.Log.d(
        "MultiCounterWidget",
        "DESIGN widget=$widgetId background=$background accent=$accent " +
            "font=$fontSize layout=$layout size=$size"
    )

        val validTime = when {
            !hasConfig -> false
            isCountdown -> target > 0L
            isCountUp -> created > 0L
            else -> false
        }

        // Background and title
        views.setInt(
            R.id.widget_root,
            "setBackgroundColor",
            background
        )

        views.setTextViewText(
            R.id.widget_title,
            title
        )

        val readableColor = readableTextColor(background)

        views.setTextColor(
            R.id.widget_title,
            readableColor
        )

        views.setViewVisibility(
            R.id.widget_title,
            if (showTitle) View.VISIBLE else View.GONE
        )

        // Time value styling
        val valueIds = listOf(
            R.id.widget_days,
            R.id.widget_hours,
            R.id.widget_minutes,
            R.id.widget_seconds
        )

        valueIds.forEach { id ->
            views.setTextColor(id, accent)
            views.setTextViewTextSize(
                id,
                TypedValue.COMPLEX_UNIT_SP,
                finalFontSize
            )
        }

        // Label styling
        val labelIds = listOf(
            R.id.widget_days_label,
            R.id.widget_hours_label,
            R.id.widget_minutes_label,
            R.id.widget_seconds_label
        )

        labelIds.forEach { id ->
            views.setTextColor(id, readableColor)
        }

        views.setTextColor(
            R.id.widget_tally,
            accent
        )

        views.setTextViewTextSize(
            R.id.widget_tally,
            TypedValue.COMPLEX_UNIT_SP,
            fontSize
        )

        // Calculate counter duration
        var days = 0L
        var hours = 0L
        var minutes = 0L
        var seconds = 0L

        if (validTime) {
            val now = System.currentTimeMillis()

            val duration = if (isCountdown) {
                max(0L, target - now)
            } else {
                max(0L, now - created)
            }

            days = duration / DAY
            hours = (duration % DAY) / HOUR
            minutes = (duration % HOUR) / MINUTE
            seconds = (duration % MINUTE) / SECOND
        }

        // Display time values
        views.setTextViewText(
            R.id.widget_days,
            days.toString()
        )

        views.setTextViewText(
            R.id.widget_hours,
            hours.toString().padStart(2, '0')
        )

        views.setTextViewText(
            R.id.widget_minutes,
            minutes.toString().padStart(2, '0')
        )

        views.setTextViewText(
            R.id.widget_seconds,
            seconds.toString().padStart(2, '0')
        )

        // Individual visibility settings
        val daysVisible = validTime && showDays
        val hoursVisible = validTime && showHours
        val minutesVisible = validTime && showMinutes
        val secondsVisible = validTime && showSeconds

        views.setViewVisibility(
            R.id.days_group,
            if (daysVisible) View.VISIBLE else View.GONE
        )

        views.setViewVisibility(
            R.id.hours_group,
            if (hoursVisible) View.VISIBLE else View.GONE
        )

        views.setViewVisibility(
            R.id.minutes_group,
            if (minutesVisible) View.VISIBLE else View.GONE
        )

        views.setViewVisibility(
            R.id.seconds_group,
            if (secondsVisible) View.VISIBLE else View.GONE
        )

        views.setViewVisibility(
            R.id.widget_days_label,
            if (daysVisible && showLabels) View.VISIBLE else View.GONE
        )

        views.setViewVisibility(
            R.id.widget_hours_label,
            if (hoursVisible && showLabels) View.VISIBLE else View.GONE
        )

        views.setViewVisibility(
            R.id.widget_minutes_label,
            if (minutesVisible && showLabels) View.VISIBLE else View.GONE
        )

        views.setViewVisibility(
            R.id.widget_seconds_label,
            if (secondsVisible && showLabels) View.VISIBLE else View.GONE
        )

        val anyTimeUnitVisible =
            daysVisible ||
                hoursVisible ||
                minutesVisible ||
                secondsVisible

        views.setViewVisibility(
            R.id.widget_time_container,
            if (anyTimeUnitVisible) View.VISIBLE else View.GONE
        )

        // Tally counter
        views.setTextViewText(
            R.id.widget_tally,
            currentValue.toString()
        )

        views.setViewVisibility(
            R.id.widget_tally,
            if (hasConfig && isTally) View.VISIBLE else View.GONE
        )

        // Clicking opens the app with this widget's own counter ID.
        val launchIntent = Intent(
            context,
            MainActivity::class.java
        ).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
        
            putExtra("widget_id", widgetId)
            putExtra("counter_id", counterId)
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            widgetId,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                PendingIntent.FLAG_IMMUTABLE
        )

        views.setOnClickPendingIntent(
            R.id.widget_root,
            pendingIntent
        )

        manager.updateAppWidget(widgetId, views)
    }

    override fun onDeleted(
        context: Context,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { widgetId ->
            cancelWidgetRefresh(context, widgetId)
        }

        val prefs = context.getSharedPreferences(
            PREFS_NAME,
            Context.MODE_PRIVATE
        )

        prefs.edit().apply {
            appWidgetIds.forEach { widgetId ->
                remove(configKey(widgetId))
            }
            commit()
        }

        // Re-schedule remaining widgets with their own intervals.
        scheduleWidgetRefresh(context)
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        scheduleWidgetRefresh(context)
    }

    override fun onDisabled(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val provider = ComponentName(
            context,
            MultiCounterWidgetProvider::class.java
        )

        manager.getAppWidgetIds(provider).forEach { widgetId ->
            cancelWidgetRefresh(context, widgetId)
        }

        super.onDisabled(context)
    }

    private fun readableTextColor(color: Int): Int {
        val luminance = (
            0.2126 * Color.red(color) +
                0.7152 * Color.green(color) +
                0.0722 * Color.blue(color)
            ) / 255.0

        return if (luminance > 0.58) {
            Color.BLACK
        } else {
            Color.WHITE
        }
    }
}
