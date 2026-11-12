
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
import android.os.Bundle
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

                val alarmManager = context.getSystemService(
                    Context.ALARM_SERVICE
                ) as AlarmManager

                if (requestedInterval < MINUTE) {
                    // Sub-minute live updates (e.g. 1 sec live ticker)
                    val safeInterval = max(1_000L, requestedInterval)
                    try {
                        alarmManager.setExactAndAllowWhileIdle(
                            AlarmManager.ELAPSED_REALTIME,
                            SystemClock.elapsedRealtime() + safeInterval,
                            refreshPendingIntent(context, widgetId)
                        )
                    } catch (_: SecurityException) {
                        alarmManager.set(
                            AlarmManager.ELAPSED_REALTIME,
                            SystemClock.elapsedRealtime() + safeInterval,
                            refreshPendingIntent(context, widgetId)
                        )
                    }
                } else {
                    alarmManager.setInexactRepeating(
                        AlarmManager.ELAPSED_REALTIME,
                        SystemClock.elapsedRealtime() + requestedInterval,
                        requestedInterval,
                        refreshPendingIntent(context, widgetId)
                    )
                }
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

        try {
            val manager = AppWidgetManager.getInstance(context)
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val raw = prefs.getString(configKey(widgetId), null)
            val config = if (!raw.isNullOrBlank()) JSONObject(raw) else JSONObject()
            val instance = MultiCounterWidgetProvider()
            instance.renderWidget(context, manager, widgetId, config)
        } catch (e: Exception) {
            android.util.Log.e("MultiCounterWidget", "Direct updateWidget failed", e)
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

            try {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val instance = MultiCounterWidgetProvider()
                ids.forEach { widgetId ->
                    val raw = prefs.getString(configKey(widgetId), null)
                    val config = if (!raw.isNullOrBlank()) JSONObject(raw) else JSONObject()
                    instance.renderWidget(context, manager, widgetId, config)
                }
            } catch (e: Exception) {
                android.util.Log.e("MultiCounterWidget", "Direct updateAllWidgets failed", e)
            }

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

                    // If widget uses sub-minute updates, schedule next exact tick
                    try {
                        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                        val raw = prefs.getString(configKey(widgetId), null)
                        if (!raw.isNullOrBlank()) {
                            val config = JSONObject(raw)
                            val req = config.optLong("refreshIntervalMs", DEFAULT_REFRESH_INTERVAL)
                            if (req in 1 until MINUTE) {
                                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                                val safeInterval = max(1_000L, req)
                                try {
                                    alarmManager.setExactAndAllowWhileIdle(
                                        AlarmManager.ELAPSED_REALTIME,
                                        SystemClock.elapsedRealtime() + safeInterval,
                                        refreshPendingIntent(context, widgetId)
                                    )
                                } catch (_: SecurityException) {
                                    alarmManager.set(
                                        AlarmManager.ELAPSED_REALTIME,
                                        SystemClock.elapsedRealtime() + safeInterval,
                                        refreshPendingIntent(context, widgetId)
                                    )
                                }
                            }
                        }
                    } catch (_: Exception) {}
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

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        refreshWidgetNow(context, appWidgetId)
    }

    fun renderWidget(
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
            config.optString("title", "")
        } else {
            ""
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

        // Background, event icon, and title
        views.setInt(
            R.id.widget_root,
            "setBackgroundColor",
            background
        )

        val iconEmoji = config.optString("iconEmoji", "").ifBlank {
            when {
                title.contains("wedding", ignoreCase = true) || title.contains("marry", ignoreCase = true) -> "💍"
                title.contains("baby", ignoreCase = true) || title.contains("birth", ignoreCase = true) -> "👶"
                title.contains("work", ignoreCase = true) -> "💼"
                title.contains("anniversary", ignoreCase = true) -> "🥂"
                title.contains("birthday", ignoreCase = true) -> "🎂"
                title.contains("graduat", ignoreCase = true) -> "🎓"
                title.contains("vacation", ignoreCase = true) || title.contains("trip", ignoreCase = true) -> "🏖️"
                isTally -> "🎯"
                isCountUp -> "📈"
                else -> "⏱️"
            }
        }

        val readableColor = readableTextColor(background)

        // Only show header if showTitle is enabled AND counter has a real custom title (not default app name)
        val isDefaultAppTitle = title.isBlank() || title.equals("MultiCounter", ignoreCase = true)
        val shouldShowHeader = showTitle && hasConfig && !isDefaultAppTitle

        views.setViewVisibility(
            R.id.widget_header,
            if (shouldShowHeader) View.VISIBLE else View.GONE
        )

        views.setTextViewText(R.id.widget_title, title)
        views.setTextColor(R.id.widget_title, readableColor)
        views.setTextViewText(R.id.widget_event_icon, iconEmoji)
        views.setViewVisibility(R.id.widget_icon, View.GONE)

        // Status banner: expired countdown or target reached differentiation
        val targetValue = config.optLong("targetValue", 0L)
        val now = System.currentTimeMillis()
        val isExpired = isCountdown && target > 0L && now >= target
        val isTargetReached = isTally && targetValue > 0L && currentValue >= targetValue

        if (isExpired) {
            views.setViewVisibility(R.id.widget_status_banner, View.VISIBLE)
            views.setTextViewText(R.id.widget_status_banner, "EVENT ARRIVED! 🎉")
            views.setTextColor(R.id.widget_status_banner, accent)
        } else if (isTargetReached) {
            views.setViewVisibility(R.id.widget_status_banner, View.VISIBLE)
            views.setTextViewText(R.id.widget_status_banner, "GOAL REACHED! 🎉 ($currentValue/$targetValue)")
            views.setTextColor(R.id.widget_status_banner, accent)
        } else {
            views.setViewVisibility(R.id.widget_status_banner, View.GONE)
        }

        // Dynamic responsive font size based on actual launcher widget bounds and orientation
        val options = manager.getAppWidgetOptions(widgetId)
        val minW = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH) ?: 0
        val maxW = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH) ?: 0
        val minH = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT) ?: 0
        val maxH = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT) ?: 0

        val isPortrait = context.resources.configuration.orientation == android.content.res.Configuration.ORIENTATION_PORTRAIT

        val effectiveW = if (isPortrait) {
            if (minW > 0) minW else (if (maxW > 0) maxW else 240)
        } else {
            if (maxW > 0) maxW else (if (minW > 0) minW else 320)
        }

        val effectiveH = if (isPortrait) {
            if (maxH > 0) maxH else (if (minH > 0) minH else 120)
        } else {
            if (minH > 0) minH else (if (maxH > 0) maxH else 90)
        }

        val visibleUnitsCount = if (isTally) 1 else (
            (if (showDays) 1 else 0) +
            (if (showHours) 1 else 0) +
            (if (showMinutes) 1 else 0) +
            (if (showSeconds) 1 else 0)
        ).coerceAtLeast(1)

        val headerHeight = if (showTitle) 28f else 0f
        val bannerHeight = if (isExpired || isTargetReached) 22f else 0f
        val labelHeight = if (showLabels) 14f else 0f
        val totalVerticalChrome = headerHeight + bannerHeight + labelHeight + (verticalPadding * 2 / density)
        val availableDigitHeight = (effectiveH - totalVerticalChrome).coerceAtLeast(16f)

        val colWidth = (effectiveW.toFloat() - (horizontalPadding * 2 / density)) / visibleUnitsCount
        val maxFromHeight = (availableDigitHeight * 0.88f).coerceIn(12f, 72f)
        val maxFromWidth = if (isTally) {
            (colWidth * 0.45f).coerceIn(14f, 75f)
        } else {
            (colWidth * 0.52f).coerceIn(12f, 64f)
        }

        val responsiveBaseSp = minOf(maxFromHeight, maxFromWidth)
        val userScale = (fontSize / 25f) * sizeScale * layoutScale
        val dynamicSp = (responsiveBaseSp * userScale).coerceIn(12f, 65f)

        // Apply dynamic responsive font size only to main numbers (labels remain static 9sp)
        val mainNumberIds = if (isTally) {
            listOf(R.id.widget_tally)
        } else {
            listOf(
                R.id.widget_days,
                R.id.widget_hours,
                R.id.widget_minutes,
                R.id.widget_seconds
            )
        }
        mainNumberIds.forEach { id ->
            views.setTextViewTextSize(id, TypedValue.COMPLEX_UNIT_SP, dynamicSp)
        }

        // Main time numbers styling (autoSizeTextType in XML auto-adjusts based on widget size)
        val valueIds = listOf(
            R.id.widget_days,
            R.id.widget_hours,
            R.id.widget_minutes,
            R.id.widget_seconds
        )

        valueIds.forEach { id ->
            views.setTextColor(id, accent)
        }

        // Colons and separator styling in Row 1 (dynamically scales with main digits)
        val colonSize = (dynamicSp * 0.85f).coerceIn(12f, 52f)
        val dotSize = (dynamicSp * 0.55f).coerceIn(10f, 26f)

        views.setTextColor(R.id.widget_sep_days, accent)
        views.setTextViewTextSize(R.id.widget_sep_days, TypedValue.COMPLEX_UNIT_SP, dotSize)

        views.setTextColor(R.id.widget_colon_hm, accent)
        views.setTextViewTextSize(R.id.widget_colon_hm, TypedValue.COMPLEX_UNIT_SP, colonSize)

        views.setTextColor(R.id.widget_colon_ms, accent)
        views.setTextViewTextSize(R.id.widget_colon_ms, TypedValue.COMPLEX_UNIT_SP, colonSize)

        // Label styling in Row 2 (scaled proportionally with digits, no spacer interference)
        val labelSp = (dynamicSp * 0.32f).coerceIn(9f, 13f)
        val labelIds = listOf(
            R.id.widget_days_label,
            R.id.widget_hours_label,
            R.id.widget_minutes_label,
            R.id.widget_seconds_label
        )

        labelIds.forEach { id ->
            views.setTextColor(id, readableColor)
            views.setTextViewTextSize(id, TypedValue.COMPLEX_UNIT_SP, labelSp)
        }

        // Main tally number styling (autoSizeTextType in XML auto-adjusts based on widget size)
        views.setTextColor(
            R.id.widget_tally,
            accent
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

        // Digits visibility
        views.setViewVisibility(
            R.id.widget_days,
            if (daysVisible) View.VISIBLE else View.GONE
        )

        views.setViewVisibility(
            R.id.widget_hours,
            if (hoursVisible) View.VISIBLE else View.GONE
        )

        views.setViewVisibility(
            R.id.widget_minutes,
            if (minutesVisible) View.VISIBLE else View.GONE
        )

        views.setViewVisibility(
            R.id.widget_seconds,
            if (secondsVisible) View.VISIBLE else View.GONE
        )

        // Labels visibility
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

        // Colons and Days separator visibility
        val sepDaysVisible = daysVisible && (hoursVisible || minutesVisible || secondsVisible)
        val colonHmVisible = hoursVisible && (minutesVisible || secondsVisible)
        val colonMsVisible = minutesVisible && secondsVisible

        views.setViewVisibility(
            R.id.widget_sep_days,
            if (sepDaysVisible) View.VISIBLE else View.GONE
        )
        views.setViewVisibility(
            R.id.widget_sep_days_spacer,
            if (sepDaysVisible && showLabels) View.INVISIBLE else View.GONE
        )

        views.setViewVisibility(
            R.id.widget_colon_hm,
            if (colonHmVisible) View.VISIBLE else View.GONE
        )
        views.setViewVisibility(
            R.id.widget_colon_hm_spacer,
            if (colonHmVisible && showLabels) View.INVISIBLE else View.GONE
        )

        views.setViewVisibility(
            R.id.widget_colon_ms,
            if (colonMsVisible) View.VISIBLE else View.GONE
        )
        views.setViewVisibility(
            R.id.widget_colon_ms_spacer,
            if (colonMsVisible && showLabels) View.INVISIBLE else View.GONE
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

        views.setViewVisibility(
            R.id.widget_labels_container,
            if (anyTimeUnitVisible && showLabels) View.VISIBLE else View.GONE
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
        // Transparent or semi-transparent background (alpha < 140) needs white text for readability against launchers/wallpapers
        if (Color.alpha(color) < 140) {
            return Color.WHITE
        }

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
