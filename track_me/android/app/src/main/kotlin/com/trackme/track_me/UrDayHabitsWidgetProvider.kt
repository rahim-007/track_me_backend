package com.trackme.track_me

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundWorker
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import io.flutter.FlutterInjector
import org.json.JSONArray
import org.json.JSONObject

class UrDayHabitsWidgetProvider : HomeWidgetProvider() {

    companion object {
        const val ACTION_TOGGLE_HABIT = "com.trackme.track_me.ACTION_TOGGLE_HABIT"
        const val ACTION_LIST_CLICK = "com.trackme.track_me.ACTION_LIST_CLICK"
        const val EXTRA_HABIT_ID = "extra_habit_id"
        const val EXTRA_ACTION_TYPE = "extra_action_type"
        const val ACTION_TOGGLE = "toggle"
        const val ACTION_OPEN_APP = "open_app"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val prefs = getWidgetData(context, widgetData)
        for (appWidgetId in appWidgetIds) {
            updateSingleWidget(context, appWidgetManager, appWidgetId, prefs)
        }
        try {
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetIds, R.id.lv_habits)
        } catch (_: Throwable) {}
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val action = intent.action
        if (action == ACTION_LIST_CLICK || action == ACTION_TOGGLE_HABIT) {
            val actionType = intent.getStringExtra(EXTRA_ACTION_TYPE) ?: ACTION_TOGGLE
            val habitId = intent.getStringExtra(EXTRA_HABIT_ID)
                ?: intent.data?.getQueryParameter("toggle")
                ?: intent.data?.getQueryParameter("id")
                ?: ""

            if (actionType == ACTION_OPEN_APP) {
                val launchIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("urday://habits")
                )
                try {
                    launchIntent.send()
                } catch (_: Throwable) {
                    val fallback = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
                        this.action = Intent.ACTION_VIEW
                        this.data = Uri.parse("urday://habits")
                        this.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    }
                    if (fallback != null) context.startActivity(fallback)
                }
            } else {
                if (habitId.isNotEmpty()) {
                    handleHabitToggle(context, habitId)
                }
            }
        } else if (action == Intent.ACTION_CONFIGURATION_CHANGED || action == Intent.ACTION_LOCALE_CHANGED) {
            try {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val thisWidget = ComponentName(context, UrDayHabitsWidgetProvider::class.java)
                val allWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
                val widgetData = getWidgetData(context)
                for (id in allWidgetIds) {
                    updateSingleWidget(context, appWidgetManager, id, widgetData)
                }
                appWidgetManager.notifyAppWidgetViewDataChanged(allWidgetIds, R.id.lv_habits)
            } catch (e: Throwable) {
                Log.e("UrDayHabitsWidget", "Error on configuration change update", e)
            }
        }
    }

    private fun handleHabitToggle(context: Context, habitId: String) {
        try {
            val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            val habitsJson = prefs.getString("habits_json", "[]") ?: "[]"
            val items = try { JSONArray(habitsJson) } catch (_: Throwable) { JSONArray() }

            var toggled = false
            var newCompletedState = false

            for (i in 0 until items.length()) {
                val item = items.getJSONObject(i)
                if (item.optString("id") == habitId) {
                    val wasCompleted = item.optBoolean("is_completed", false)
                    newCompletedState = !wasCompleted
                    item.put("is_completed", newCompletedState)

                    val streak = item.optInt("streak", 0)
                    item.put("streak", if (newCompletedState) streak + 1 else maxOf(0, streak - 1))
                    toggled = true
                    break
                }
            }

            if (!toggled) return

            var completedCount = 0
            for (i in 0 until items.length()) {
                if (items.getJSONObject(i).optBoolean("is_completed", false)) {
                    completedCount++
                }
            }

            val totalCount = maxOf(items.length(), prefs.getInt("total_count", items.length()))
            val safeCompletedCount = if (totalCount > 0) completedCount.coerceIn(0, totalCount) else 0
            val percent = if (totalCount > 0) ((safeCompletedCount * 100 / totalCount)).coerceIn(0, 100) else 0
            val ratio = "$safeCompletedCount/$totalCount"

            // Compute live overall streak: if all scheduled habits are completed, increment base streak by 1
            val baseStreak = prefs.getInt("base_streak_count", prefs.getInt("streak_count", 0))
            val newStreak = if (totalCount > 0 && safeCompletedCount == totalCount) {
                baseStreak + 1
            } else {
                baseStreak
            }

            // Save pending toggle for Flutter consumption
            val pendingTogglesJson = prefs.getString("pending_widget_toggles", "[]") ?: "[]"
            val pendingArray = try { JSONArray(pendingTogglesJson) } catch (_: Throwable) { JSONArray() }
            val toggleObj = JSONObject().apply {
                put("id", habitId)
                put("completed", newCompletedState)
                put("timestamp", System.currentTimeMillis())
            }
            pendingArray.put(toggleObj)

            prefs.edit().apply {
                putString("habits_json", items.toString())
                putInt("completed_count", safeCompletedCount)
                putInt("progress_percent", percent)
                putString("progress_ratio", ratio)
                putInt("streak_count", newStreak)
                putString("pending_widget_toggles", pendingArray.toString())
            }.commit()

            // 1. Immediately update all Habits widget instances (zero latency!)
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val habitsComponent = ComponentName(context, UrDayHabitsWidgetProvider::class.java)
            val habitWidgetIds = appWidgetManager.getAppWidgetIds(habitsComponent)
            for (id in habitWidgetIds) {
                updateSingleWidget(context, appWidgetManager, id, prefs)
            }
            // Instantly notify ListView data changed so checkbox flips immediately
            appWidgetManager.notifyAppWidgetViewDataChanged(habitWidgetIds, R.id.lv_habits)

            // 2. Immediately notify UrDayProgressWidgetProvider instances so the circular widget matches
            try {
                val progressComponent = ComponentName(context, UrDayProgressWidgetProvider::class.java)
                val progressWidgetIds = appWidgetManager.getAppWidgetIds(progressComponent)
                if (progressWidgetIds.isNotEmpty()) {
                    val progressProvider = UrDayProgressWidgetProvider()
                    progressProvider.onUpdate(context, appWidgetManager, progressWidgetIds, prefs)
                }
            } catch (e: Throwable) {
                Log.e("UrDayHabitsWidget", "Failed to update progress widget", e)
            }

            // 3. Enqueue background work for Flutter engine with initialized FlutterLoader
            try {
                val flutterLoader = FlutterInjector.instance().flutterLoader()
                flutterLoader.startInitialization(context)
                flutterLoader.ensureInitializationComplete(context, null)
                val workIntent = Intent().apply {
                    data = Uri.parse("urday://habits?toggle=$habitId&completed=$newCompletedState")
                }
                HomeWidgetBackgroundWorker.enqueueWork(context, workIntent)
            } catch (e: Throwable) {
                Log.e("UrDayHabitsWidget", "Failed to enqueue background work", e)
            }
        } catch (e: Throwable) {
            Log.e("UrDayHabitsWidget", "Error handling habit toggle", e)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle?
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        val widgetData = getWidgetData(context)
        updateSingleWidget(context, appWidgetManager, appWidgetId, widgetData)
        try {
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.lv_habits)
        } catch (_: Throwable) {}
    }

    private fun getWidgetData(context: Context, fallback: SharedPreferences? = null): SharedPreferences {
        val homeWidgetPrefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        if (homeWidgetPrefs.contains("habits_json") || homeWidgetPrefs.contains("progress_ratio")) {
            return homeWidgetPrefs
        }
        if (fallback != null && (fallback.contains("habits_json") || fallback.contains("progress_ratio"))) {
            return fallback
        }
        return homeWidgetPrefs
    }

    private fun updateSingleWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        widgetData: SharedPreferences
    ) {
        try {
            val prefs = getWidgetData(context, widgetData)
            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val minWidth = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0) ?: 0

            val views = RemoteViews(context.packageName, R.layout.widget_today_habits).apply {
                val ratio = prefs.getString("progress_ratio", "0/0") ?: "0/0"
                val percent = prefs.getInt("progress_percent", 0).coerceIn(0, 100)
                val habitsJson = prefs.getString("habits_json", "[]") ?: "[]"

                // 1. Header: Dynamic title based on width
                val isNarrow = minWidth in 1..219
                val headerTitle = if (isNarrow) "UrDay" else "UrDay · Today's Habits"
                setTextViewText(R.id.tv_habits_title, headerTitle)
                setTextViewText(R.id.tv_habits_progress_badge, "$ratio ($percent%)")

                // 2. Click intents for header and quick add button
                val headerIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("urday://dashboard")
                )
                setOnClickPendingIntent(R.id.btn_header_title, headerIntent)

                val quickAddIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("urday://habits")
                )
                setOnClickPendingIntent(R.id.btn_quick_add, quickAddIntent)

                // 3. Parse habits data
                val items = try {
                    JSONArray(habitsJson)
                } catch (_: Throwable) {
                    JSONArray()
                }

                // 4. Scrollable ListView (Swipes up & down for ALL habits across all widget sizes)
                val serviceIntent = Intent(context, UrDayHabitsWidgetService::class.java).apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    data = Uri.parse("urday://widget/habits_service/$appWidgetId")
                }
                setRemoteAdapter(R.id.lv_habits, serviceIntent)
                setEmptyView(R.id.lv_habits, R.id.tv_empty_habits)

                // Set PendingIntent template for item clicks (toggles checkbox & row launch)
                val listClickIntent = Intent(context, UrDayHabitsWidgetProvider::class.java).apply {
                    action = ACTION_LIST_CLICK
                }
                val flags = if (Build.VERSION.SDK_INT >= 31) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
                val listClickPendingIntent = PendingIntent.getBroadcast(
                    context,
                    0,
                    listClickIntent,
                    flags
                )
                setPendingIntentTemplate(R.id.lv_habits, listClickPendingIntent)

                if (items.length() > 0) {
                    setViewVisibility(R.id.lv_habits, View.VISIBLE)
                    setViewVisibility(R.id.tv_empty_habits, View.GONE)
                } else {
                    setViewVisibility(R.id.lv_habits, View.GONE)
                    setViewVisibility(R.id.tv_empty_habits, View.VISIBLE)
                }
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        } catch (e: Throwable) {
            Log.e("UrDayHabitsWidget", "Error updating widget $appWidgetId", e)
        }
    }
}
