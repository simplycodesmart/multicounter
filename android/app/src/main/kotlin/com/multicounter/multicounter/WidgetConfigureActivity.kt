
package com.multicounter.multicounter

import android.app.Activity
import android.app.AlertDialog
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.time.Instant
import java.util.Locale
import java.util.TimeZone

class WidgetConfigureActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        android.util.Log.d(
            "MultiCounterWidget",
            "WidgetConfigureActivity launched. Intent=$intent"
        )

        val widgetId = intent.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        )

        if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finishWithCancel()
            return
        }

        val widgetPrefs = getSharedPreferences(
            MultiCounterWidgetProvider.PREFS_NAME,
            Context.MODE_PRIVATE
        )

        val configJson =
            intent.getStringExtra("widget_config")
                ?: intent.getBundleExtra(
                    AppWidgetManager.EXTRA_APPWIDGET_OPTIONS
                )?.getString("widget_config")
                ?: widgetPrefs.getString(
                    "pending_widget_config",
                    null
                )

        android.util.Log.d(
            "MultiCounterWidget",
            "Widget ID=$widgetId, received config=$configJson"
        )

        if (!configJson.isNullOrBlank()) {
            saveAndFinish(widgetId, configJson)
            return
        }

        showCounterSelection(widgetId)
    }

    private fun showCounterSelection(widgetId: Int) {
        val flutterPrefs = getSharedPreferences(
            "FlutterSharedPreferences",
            Context.MODE_PRIVATE
        )

        val countersRaw = flutterPrefs.getString(
            "flutter.multicounter.counters.v1",
            null
        )

        val studioRaw = flutterPrefs.getString(
            "flutter.multicounter.widget_studio.v1",
            null
        )

        if (countersRaw.isNullOrBlank()) {
            AlertDialog.Builder(this)
                .setTitle("No Counters Found")
                .setMessage(
                    "Open MultiCounter and create a counter before adding a widget."
                )
                .setPositiveButton("Open App") { _, _ ->
                    startActivity(
                        Intent(this, MainActivity::class.java)
                    )
                    finishWithCancel()
                }
                .setNegativeButton("Cancel") { _, _ ->
                    finishWithCancel()
                }
                .setOnCancelListener {
                    finishWithCancel()
                }
                .show()
            return
        }

        try {
            val counters = JSONArray(countersRaw)

            if (counters.length() == 0) {
                finishWithCancel()
                return
            }

            val titles = Array(counters.length()) { index ->
                val counter = counters.getJSONObject(index)
                val title = counter.optString("title", "Counter")
                val type = counter.optString(
                    "type",
                    "countdown"
                ).uppercase()

                "$title ($type)"
            }

            AlertDialog.Builder(this)
                .setTitle("Select Counter for Widget")
                .setItems(titles) { _, selectedIndex ->
                    try {
                        val counter = counters.getJSONObject(selectedIndex)

                        val studio = if (!studioRaw.isNullOrBlank()) {
                            JSONObject(studioRaw)
                        } else {
                            JSONObject()
                        }

                        val config = createConfig(counter, studio)

                        saveAndFinish(
                            widgetId,
                            config.toString()
                        )
                    } catch (error: Exception) {
                        error.printStackTrace()
                        finishWithCancel()
                    }
                }
                .setNegativeButton("Cancel") { _, _ ->
                    finishWithCancel()
                }
                .setOnCancelListener {
                    finishWithCancel()
                }
                .show()

        } catch (error: Exception) {
            error.printStackTrace()
            finishWithCancel()
        }
    }

    private fun createConfig(
        counter: JSONObject,
        studio: JSONObject
    ): JSONObject {

        val counterId = counter.optString("id", "")
        val title = counter.optString("title", "MultiCounter")
        val type = counter.optString("type", "countdown")

        val targetEpoch = readEpoch(
            counter.opt("targetDate")
        )

        val startDate = counter.opt("startDate")
        val createdEpoch = if (startDate != null && startDate != JSONObject.NULL) {
                                    readEpoch(startDate).takeIf { it > 0L } ?: readEpoch(counter.opt("createdAt"))
                            } else {
                                readEpoch(counter.opt("createdAt"))
                            }
        val colorValue = MultiCounterWidgetProvider.parseColor(
            counter,
            "colorValue",
            0xFFFFD400.toInt()
        )

        return JSONObject().apply {
            put("counterId", counterId)
            put("title", title)
            put("type", type)

            put("targetEpoch", targetEpoch)
            put("createdEpoch", createdEpoch)
            put(
                "currentValue",
                counter.optLong("currentValue", 0L)
            )

            put(
                "background",
                MultiCounterWidgetProvider.parseColor(
                    studio,
                    "background",
                    0xFF171717.toInt()
                )
            )

            put("accent", colorValue)

            put(
                "fontSize",
                studio.optDouble("fontSize", 25.0)
            )

            put("showTitle", studio.optBoolean("showTitle", true))
            put("showDays", studio.optBoolean("showDays", true))
            put("showHours", studio.optBoolean("showHours", true))
            put("showMinutes", studio.optBoolean("showMinutes", true))
            put("showSeconds", studio.optBoolean("showSeconds", true))
            put("showLabels", studio.optBoolean("showLabels", true))

            put(
                "layout",
                studio.optString("layout", "Classic")
            )

            put(
                "size",
                studio.optString("size", "Medium")
            )
        }
    }

    private fun readEpoch(value: Any?): Long {
        if (value == null || value == JSONObject.NULL) {
            return 0L
        }

        // Support numeric timestamps.
        if (value is Number) {
            return value.toLong()
        }

        val dateString = value.toString().trim()

        if (dateString.isBlank()) return 0L

        // ISO-8601 timestamps.
        try {
            return Instant.parse(dateString).toEpochMilli()
        } catch (_: Exception) {
            // Continue with local date parsing.
        }

        val formats = listOf(
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd"
        )

        for (pattern in formats) {
            try {
                val formatter = SimpleDateFormat(
                    pattern,
                    Locale.US
                )
                formatter.isLenient = false
                formatter.timeZone = TimeZone.getDefault()

                val parsed = formatter.parse(dateString)

                if (parsed != null) {
                    return parsed.time
                }
            } catch (_: Exception) {
                // Try the next format.
            }
        }

        return 0L
    }

    private fun saveAndFinish(
    widgetId: Int,
    configJson: String
): Boolean {
    try {
        val config = JSONObject(configJson)

        val counterId = config.optString("counterId", "")

        if (counterId.isBlank() || counterId == "null") {
            finishWithCancel()
            return true
        }

        val prefs = getSharedPreferences(
            MultiCounterWidgetProvider.PREFS_NAME,
            Context.MODE_PRIVATE
        )

        // Save configuration against this specific Android widget ID.
        val saved = prefs.edit()
            .putString(
                MultiCounterWidgetProvider.configKey(widgetId),
                config.toString()
            )
            .commit()

            android.util.Log.d(
    "MultiCounterWidget",
    "Saved config for widget $widgetId: $configJson, success=$saved"
)

        if (!saved) {
            finishWithCancel()
            android.util.Log.d(
            "MultiCounterWidget",
            "Saved  failed config for widget $widgetId: ${config.toString()}"
            )
            return true
        }

        android.util.Log.d(
            "MultiCounterWidget",
            "Saved config for widget $widgetId: ${config}"
        )

        // Clear one-time pending configuration after successful save.
        prefs.edit()
            .remove("pending_widget_config")
            .apply()

        // Refresh this specific widget.
        MultiCounterWidgetProvider.updateWidget(
            this,
            widgetId
        )

        // Tell Android that widget configuration completed successfully.
        setResult(
            RESULT_OK,
            Intent().putExtra(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                widgetId
            )
        )

        finish()
        return true

    } catch (error: Exception) {
        error.printStackTrace()
        finishWithCancel()
        return true
    }
}

    private fun finishWithCancel() {
        setResult(RESULT_CANCELED)
        finish()
    }
}
