
package com.multicounter.multicounter

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.app.PendingIntent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import android.content.pm.PackageManager

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "multicounter/widget_config"
        private const val EXTRA_COUNTER_ID = "counter_id"
        private const val EXTRA_WIDGET_ID = "widget_id"
        private const val PENDING_CONFIG_KEY = "pending_widget_config"
    }

    private var widgetChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        widgetChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )

        widgetChannel?.setMethodCallHandler { call, result ->
            when (call.method) {

                "getPendingWidgetNavigation" -> {
                    result.success(readWidgetNavigation(intent, clear = true))
                }

                "getWidgetIds" -> {
                    try {
                        val manager = AppWidgetManager.getInstance(this)
                        val provider = ComponentName(
                            this,
                            MultiCounterWidgetProvider::class.java
                        )

                        result.success(manager.getAppWidgetIds(provider).toList())
                    } catch (error: Exception) {
                        result.error("GET_WIDGET_IDS_FAILED", error.message, null)
                    }
                }

                "saveWidgetConfig" -> {
                    try {
                        val widgetId =
                            call.argument<Number>("widgetId")?.toInt()
                        val config =
                            call.argument<Map<String, Any>>("config")

                        if (widgetId == null || config == null) {
                            result.error(
                                "INVALID_ARGS",
                                "Widget ID or configuration is missing",
                                null
                            )
                            return@setMethodCallHandler
                        }

                        val manager = AppWidgetManager.getInstance(this)
                        val provider = ComponentName(
                            this,
                            MultiCounterWidgetProvider::class.java
                        )

                        if (widgetId !in manager.getAppWidgetIds(provider)) {
                            result.error(
                                "WIDGET_NOT_FOUND",
                                "Widget $widgetId is not installed",
                                null
                            )
                            return@setMethodCallHandler
                        }

                        val saved = getSharedPreferences(
                            MultiCounterWidgetProvider.PREFS_NAME,
                            Context.MODE_PRIVATE
                        ).edit()
                            .putString(
                                MultiCounterWidgetProvider.configKey(widgetId),
                                JSONObject(config).toString()
                            )
                            .commit()

                        if (!saved) {
                            result.error(
                                "SAVE_FAILED",
                                "Could not save widget configuration",
                                null
                            )
                            return@setMethodCallHandler
                        }

                        MultiCounterWidgetProvider.updateWidget(this, widgetId)
                        result.success(true)

                    } catch (error: Exception) {
                        result.error("SAVE_WIDGET_FAILED", error.message, null)
                    }
                }

                "syncCounter" -> {
                    try {
                        val counterId = call.argument<String>("counterId")

                        if (counterId.isNullOrBlank()) {
                            result.error(
                                "INVALID_ARGS",
                                "Counter ID is missing",
                                null
                            )
                            return@setMethodCallHandler
                        }

                        val manager = AppWidgetManager.getInstance(this)
                        val provider = ComponentName(
                            this,
                            MultiCounterWidgetProvider::class.java
                        )

                        val ids = manager.getAppWidgetIds(provider)

                        val prefs = getSharedPreferences(
                            MultiCounterWidgetProvider.PREFS_NAME,
                            Context.MODE_PRIVATE
                        )

                        val editor = prefs.edit()
                        var changed = false

                        for (id in ids) {
                            val key = MultiCounterWidgetProvider.configKey(id)
                            val raw = prefs.getString(key, null) ?: continue
                            val config = JSONObject(raw)

                            if (config.optString("counterId") != counterId) {
                                continue
                            }

                            config.put(
                                "title",
                                call.argument<String>("title")
                                    ?: config.optString("title")
                            )

                            config.put(
                                "type",
                                call.argument<String>("type")
                                    ?: config.optString("type")
                            )

                            config.put(
                                "targetEpoch",
                                call.argument<Number>("targetEpoch")?.toLong()
                                    ?: config.optLong("targetEpoch")
                            )

                            config.put(
                                "createdEpoch",
                                call.argument<Number>("createdEpoch")?.toLong()
                                    ?: config.optLong("createdEpoch")
                            )

                            config.put(
                                "currentValue",
                                call.argument<Number>("currentValue")?.toInt()
                                    ?: config.optInt("currentValue")
                            )

                            config.put(
                                "targetValue",
                                call.argument<Number>("targetValue")?.toLong()
                                    ?: config.optLong("targetValue")
                            )

                            val newAccent = call.argument<Number>("accent")?.toLong()?.toInt()
                            if (newAccent != null) {
                                config.put("accent", newAccent)
                            }

                            val newEmoji = call.argument<String>("iconEmoji")
                            if (newEmoji != null) {
                                config.put("iconEmoji", newEmoji)
                            }

                            editor.putString(key, config.toString())
                            changed = true
                        }

                        if (changed && !editor.commit()) {
                            result.error(
                                "SAVE_FAILED",
                                "Could not refresh widget configurations",
                                null
                            )
                            return@setMethodCallHandler
                        }

                        if (changed) {
                            MultiCounterWidgetProvider.updateAllWidgets(this)
                        }

                        result.success(true)

                    } catch (error: Exception) {
                        result.error("SYNC_COUNTER_FAILED", error.message, null)
                    }
                }

                "requestPinWidget" -> {
                    try {
                        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                            result.success(false)
                            return@setMethodCallHandler
                        }

                        val config =
                            call.argument<Map<String, Any>>("config")

                        val counterId = config?.get("counterId")?.toString()

                        if (config == null || counterId.isNullOrBlank()) {
                            result.error(
                                "INVALID_CONFIG",
                                "Counter configuration is missing",
                                null
                            )
                            return@setMethodCallHandler
                        }

                        val manager = AppWidgetManager.getInstance(this)

                        if (!manager.isRequestPinAppWidgetSupported) {
                            result.success(false)
                            return@setMethodCallHandler
                        }

                        val provider = ComponentName(
                            this,
                            MultiCounterWidgetProvider::class.java
                        )

                        val configJson = JSONObject(config).toString()

                        android.util.Log.d(
    "MultiCounterWidget",
    "Pin request config=$configJson"
)

                        val savedPending = getSharedPreferences(
                            MultiCounterWidgetProvider.PREFS_NAME,
                            Context.MODE_PRIVATE
                        ).edit()
                            .putString(PENDING_CONFIG_KEY, configJson)
                            .commit()

                        if (!savedPending) {
                            result.error(
                                "SAVE_PENDING_FAILED",
                                "Could not stage widget configuration",
                                null
                            )
                            return@setMethodCallHandler
                        }

                        val extras = Bundle().apply {
                            putString("widget_config", configJson)
                        }

                        android.util.Log.d(
                                "MultiCounterWidget",
                                "Pin supported=${manager.isRequestPinAppWidgetSupported}, " +
                                    "Provider=$provider, WidgetConfigure=" +
                                    context.packageManager.getActivityInfo(
                                        ComponentName(context, WidgetConfigureActivity::class.java),
                                        PackageManager.GET_META_DATA
                                    ).name
                            )

                        val callbackIntent = Intent(
                                this,
                                MultiCounterWidgetProvider::class.java
                            ).apply {
                                action = MultiCounterWidgetProvider.ACTION_WIDGET_PINNED
                            }
                            
                            val callback = PendingIntent.getBroadcast(
                                this,
                                9001,
                                callbackIntent,
                                PendingIntent.FLAG_UPDATE_CURRENT or
                                    PendingIntent.FLAG_MUTABLE
                            )
                            
                            val accepted = manager.requestPinAppWidget(
                                provider,
                                extras,
                                callback
                            )
                            
                            android.util.Log.d(
                                "MultiCounterWidget",
                                "Pin request accepted=$accepted"
                            )
                        if (!accepted) {
                            getSharedPreferences(
                                MultiCounterWidgetProvider.PREFS_NAME,
                                Context.MODE_PRIVATE
                            ).edit()
                                .remove(PENDING_CONFIG_KEY)
                                .apply()
                        }

                        result.success(accepted)

                    } catch (error: Exception) {
                        result.error("PIN_WIDGET_FAILED", error.message, null)
                    }
                }

                "updateAllWidgetDesigns" -> {
                    try {
                        val design = call.argument<Map<String, Any>>("design")
                        if (design == null) {
                            result.error("INVALID_ARGS", "Design options are missing", null)
                            return@setMethodCallHandler
                        }

                        val manager = AppWidgetManager.getInstance(this)
                        val provider = ComponentName(
                            this,
                            MultiCounterWidgetProvider::class.java
                        )
                        val ids = manager.getAppWidgetIds(provider)

                        val prefs = getSharedPreferences(
                            MultiCounterWidgetProvider.PREFS_NAME,
                            Context.MODE_PRIVATE
                        )
                        val editor = prefs.edit()
                        var changed = false

                        val targetWidgetId = call.argument<Number>("widgetId")?.toInt()
                        val targetIds = if (targetWidgetId != null && targetWidgetId in ids) {
                            intArrayOf(targetWidgetId)
                        } else {
                            ids
                        }

                        for (id in targetIds) {
                            val key = MultiCounterWidgetProvider.configKey(id)
                            val raw = prefs.getString(key, null)
                            val config = if (!raw.isNullOrBlank()) {
                                try {
                                    JSONObject(raw)
                                } catch (_: Exception) {
                                    JSONObject()
                                }
                            } else {
                                JSONObject()
                            }

                            // If updating widget's assigned counter directly
                            val assignCounterId = call.argument<String>("assignCounterId") ?: design["counterId"]?.toString()
                            val shouldAssignCounter = !assignCounterId.isNullOrBlank() && (
                                targetWidgetId != null ||
                                config.optString("counterId").isBlank() ||
                                config.optString("counterId") == "null"
                            )

                            if (shouldAssignCounter) {
                                config.put("counterId", assignCounterId)
                                if (call.argument<String>("assignTitle") != null) config.put("title", call.argument<String>("assignTitle"))
                                else if (design.containsKey("title")) config.put("title", design["title"]?.toString() ?: "")

                                if (call.argument<String>("assignType") != null) config.put("type", call.argument<String>("assignType"))
                                else if (design.containsKey("type")) config.put("type", design["type"]?.toString() ?: "countdown")

                                if (call.argument<Number>("assignTargetEpoch") != null) config.put("targetEpoch", call.argument<Number>("assignTargetEpoch")?.toLong() ?: 0L)
                                else if (design.containsKey("targetEpoch")) config.put("targetEpoch", (design["targetEpoch"] as? Number)?.toLong() ?: 0L)

                                if (call.argument<Number>("assignCreatedEpoch") != null) config.put("createdEpoch", call.argument<Number>("assignCreatedEpoch")?.toLong() ?: 0L)
                                else if (design.containsKey("createdEpoch")) config.put("createdEpoch", (design["createdEpoch"] as? Number)?.toLong() ?: 0L)

                                if (call.argument<Number>("assignCurrentValue") != null) config.put("currentValue", call.argument<Number>("assignCurrentValue")?.toInt() ?: 0)
                                else if (design.containsKey("currentValue")) config.put("currentValue", (design["currentValue"] as? Number)?.toInt() ?: 0)

                                if (call.argument<String>("assignIconEmoji") != null) config.put("iconEmoji", call.argument<String>("assignIconEmoji"))
                            } else if (config.optString("counterId").isBlank() || config.optString("counterId") == "null") {
                                // If this widget has no counter assigned yet, use fallback if provided
                                val fallbackId = call.argument<String>("fallbackCounterId")
                                if (!fallbackId.isNullOrBlank()) {
                                    config.put("counterId", fallbackId)
                                    config.put("title", call.argument<String>("fallbackTitle") ?: "MultiCounter")
                                    config.put("type", call.argument<String>("fallbackType") ?: "countdown")
                                    config.put("targetEpoch", call.argument<Number>("fallbackTargetEpoch")?.toLong() ?: 0L)
                                    config.put("createdEpoch", call.argument<Number>("fallbackCreatedEpoch")?.toLong() ?: 0L)
                                    config.put("currentValue", call.argument<Number>("fallbackCurrentValue")?.toInt() ?: 0)
                                    val fallbackAccent = call.argument<Number>("fallbackAccent")?.toLong()?.toInt()
                                    if (fallbackAccent != null) {
                                        config.put("accent", fallbackAccent)
                                    }
                                    val fallbackEmoji = call.argument<String>("fallbackIconEmoji")
                                    if (fallbackEmoji != null) {
                                        config.put("iconEmoji", fallbackEmoji)
                                    }
                                }
                            }

                            // Apply design properties
                            if (design.containsKey("layout")) {
                                config.put("layout", design["layout"]?.toString() ?: "Classic")
                            }
                            if (design.containsKey("size")) {
                                config.put("size", design["size"]?.toString() ?: "Medium")
                            }
                            if (design.containsKey("background")) {
                                val bg = (design["background"] as? Number)?.toLong()?.toInt()
                                if (bg != null) config.put("background", bg)
                            }
                            if (design.containsKey("accent")) {
                                val acc = (design["accent"] as? Number)?.toLong()?.toInt()
                                if (acc != null) config.put("accent", acc)
                            }
                            if (design.containsKey("fontSize")) {
                                val fs = (design["fontSize"] as? Number)?.toDouble() ?: 25.0
                                config.put("fontSize", fs)
                            }
                            if (design.containsKey("showTitle")) {
                                config.put("showTitle", design["showTitle"] as? Boolean ?: true)
                            }
                            if (design.containsKey("showDays")) {
                                config.put("showDays", design["showDays"] as? Boolean ?: true)
                            }
                            if (design.containsKey("showHours")) {
                                config.put("showHours", design["showHours"] as? Boolean ?: true)
                            }
                            if (design.containsKey("showMinutes")) {
                                config.put("showMinutes", design["showMinutes"] as? Boolean ?: true)
                            }
                            if (design.containsKey("showSeconds")) {
                                config.put("showSeconds", design["showSeconds"] as? Boolean ?: true)
                            }
                            if (design.containsKey("showLabels")) {
                                config.put("showLabels", design["showLabels"] as? Boolean ?: true)
                            }

                            editor.putString(key, config.toString())
                            changed = true
                        }

                        // Also save to FlutterSharedPreferences so future widgets created from native
                        // launcher configure activity will use this updated design as their default!
                        try {
                            getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                                .edit()
                                .putString("flutter.multicounter.widget_studio.v1", JSONObject(design).toString())
                                .apply()
                        } catch (_: Exception) {}

                        if (changed) {
                            editor.commit()

                            if (targetWidgetId != null && targetWidgetId in ids) {
                                MultiCounterWidgetProvider.updateWidget(this, targetWidgetId)
                            } else {
                                MultiCounterWidgetProvider.updateAllWidgets(this)
                            }
                        }

                        result.success(true)
                    } catch (error: Exception) {
                        result.error("UPDATE_ALL_DESIGNS_FAILED", error.message, null)
                    }
                }

                "getInstalledWidgetsInfo" -> {
                    try {
                        val manager = AppWidgetManager.getInstance(this)
                        val provider = ComponentName(
                            this,
                            MultiCounterWidgetProvider::class.java
                        )
                        val ids = manager.getAppWidgetIds(provider)

                        val prefs = getSharedPreferences(
                            MultiCounterWidgetProvider.PREFS_NAME,
                            Context.MODE_PRIVATE
                        )
                        val list = mutableListOf<Map<String, Any?>>()
                        for (id in ids) {
                            val key = MultiCounterWidgetProvider.configKey(id)
                            val raw = prefs.getString(key, null)
                            val config = if (!raw.isNullOrBlank()) {
                                try { JSONObject(raw) } catch (_: Exception) { JSONObject() }
                            } else {
                                JSONObject()
                            }
                            val item = mapOf<String, Any?>(
                                "widgetId" to id,
                                "counterId" to config.optString("counterId", ""),
                                "title" to config.optString("title", "MultiCounter"),
                                "type" to config.optString("type", "countdown"),
                                "targetEpoch" to config.optLong("targetEpoch", 0L),
                                "createdEpoch" to config.optLong("createdEpoch", 0L),
                                "currentValue" to config.optLong("currentValue", 0L),
                                "layout" to config.optString("layout", "Classic"),
                                "size" to config.optString("size", "Medium"),
                                "accent" to config.opt("accent"),
                                "background" to config.opt("background"),
                                "fontSize" to config.optDouble("fontSize", 25.0),
                                "showTitle" to config.optBoolean("showTitle", true),
                                "showDays" to config.optBoolean("showDays", true),
                                "showHours" to config.optBoolean("showHours", true),
                                "showMinutes" to config.optBoolean("showMinutes", true),
                                "showSeconds" to config.optBoolean("showSeconds", true),
                                "showLabels" to config.optBoolean("showLabels", true)
                            )
                            list.add(item)
                        }
                        result.success(list)
                    } catch (error: Exception) {
                        result.error("GET_INSTALLED_INFO_FAILED", error.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
    super.onNewIntent(intent)
    setIntent(intent)

    val channel = widgetChannel ?: return

    // Read without clearing so navigation isn't lost.
    val navigation = readWidgetNavigation(
        intent,
        clear = false
    ) ?: return

    channel.invokeMethod(
        "openCounterFromWidget",
        navigation,
        object : MethodChannel.Result {
            override fun success(result: Any?) {
                // Clear extras only after Flutter receives the call.
                intent.removeExtra(EXTRA_COUNTER_ID)
                intent.removeExtra(EXTRA_WIDGET_ID)
            }

            override fun error(
                errorCode: String,
                errorMessage: String?,
                errorDetails: Any?
            ) {
                // Keep extras so navigation can be retried.
            }

            override fun notImplemented() {
                // Keep extras for getPendingWidgetNavigation().
            }
        }
    )
}

    private fun readWidgetNavigation(
        source: Intent?,
        clear: Boolean
    ): Map<String, Any>? {

        if (source == null) return null

        val counterId = source.getStringExtra(EXTRA_COUNTER_ID)

        if (counterId.isNullOrBlank()) return null

        val widgetId = source.getIntExtra(
            EXTRA_WIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        )

        if (clear) {
            source.removeExtra(EXTRA_COUNTER_ID)
            source.removeExtra(EXTRA_WIDGET_ID)
        }

        return mapOf(
            "counterId" to counterId,
            "widgetId" to widgetId
        )
    }
}
