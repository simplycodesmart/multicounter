
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

                            val newAccent = call.argument<Number>("accent")?.toLong()?.toInt()
                            if (newAccent != null) {
                                config.put("accent", newAccent)
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
