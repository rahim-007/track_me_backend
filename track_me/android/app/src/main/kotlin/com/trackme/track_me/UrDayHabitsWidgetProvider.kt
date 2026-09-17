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
        const val EXTRA_HABIT_ID = "extra_habit_id"
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
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val action = intent.action
        if (action == ACTION_TOGGLE_HABIT) {
            val habitId = intent.getStringExtra(EXTRA_HABIT_ID)
                ?: intent.data?.getQueryParameter("toggle")
                ?: intent.data?.getQueryParameter("id")
            if (!habitId.isNullOrEmpty()) {
                handleHabitToggle(context, habitId)
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
            var completedCount = prefs.getInt("completed_count", 0)
            val totalCount = prefs.getInt("total_count", items.length())

            for (i in 0 until items.length()) {
                val item = items.getJSONObject(i)
                if (item.optString("id") == habitId) {
                    val wasCompleted = item.optBoolean("is_completed", false)
                    newCompletedState = !wasCompleted
                    item.put("is_completed", newCompletedState)

                    val streak = item.optInt("streak", 0)
                    item.put("streak", if (newCompletedState) streak + 1 else maxOf(0, streak - 1))

                    if (newCompletedState) {
                        completedCount++
                    } else {
                        completedCount = maxOf(0, completedCount - 1)
                    }
                    toggled = true
                    break
                }
            }

            if (!toggled) return

            val percent = if (totalCount > 0) (completedCount * 100 / totalCount) else 0
            val ratio = "$completedCount/$totalCount"

            // Compute live overall streak: if all scheduled habits are completed, increment base streak by 1
            val baseStreak = prefs.getInt("base_streak_count", prefs.getInt("streak_count", 0))
            val newStreak = if (totalCount > 0 && completedCount == totalCount) {
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
                putInt("completed_count", completedCount)
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
            val minHeight = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0) ?: 0

            // Show compact horizontal habit widget for 1-cell height (<= 105dp or uninitialized 0)
            val isCompact = minHeight == 0 || minHeight <= 105
            val isMedium = !isCompact && minWidth in 1..279
            val isLarge = !isCompact && !isMedium

            val views = RemoteViews(context.packageName, R.layout.widget_today_habits).apply {
                val ratio = prefs.getString("progress_ratio", "0/0") ?: "0/0"
                val percent = prefs.getInt("progress_percent", 0)
                val habitsJson = prefs.getString("habits_json", "[]") ?: "[]"

                // 1. Header: Dynamic title based on responsive mode
                val headerTitle = if (isLarge) "UrDay · Today's Habits" else "UrDay"
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

                val rowIds = intArrayOf(
                    R.id.row_habit_1,
                    R.id.row_habit_2,
                    R.id.row_habit_3,
                    R.id.row_habit_4,
                    R.id.row_habit_5
                )
                val dividerIds = intArrayOf(
                    R.id.divider_1,
                    R.id.divider_2,
                    R.id.divider_3,
                    R.id.divider_4
                )
                val titleIds = intArrayOf(
                    R.id.tv_title_1,
                    R.id.tv_title_2,
                    R.id.tv_title_3,
                    R.id.tv_title_4,
                    R.id.tv_title_5
                )
                val emojiIds = intArrayOf(
                    R.id.tv_emoji_1,
                    R.id.tv_emoji_2,
                    R.id.tv_emoji_3,
                    R.id.tv_emoji_4,
                    R.id.tv_emoji_5
                )
                val streakIds = intArrayOf(
                    R.id.tv_streak_1,
                    R.id.tv_streak_2,
                    R.id.tv_streak_3,
                    R.id.tv_streak_4,
                    R.id.tv_streak_5
                )
                val checkIds = intArrayOf(
                    R.id.iv_check_1,
                    R.id.iv_check_2,
                    R.id.iv_check_3,
                    R.id.iv_check_4,
                    R.id.iv_check_5
                )
                val btnCheckIds = intArrayOf(
                    R.id.btn_check_1,
                    R.id.btn_check_2,
                    R.id.btn_check_3,
                    R.id.btn_check_4,
                    R.id.btn_check_5
                )

                // Compact columns
                val compactColIds = intArrayOf(
                    R.id.col_compact_1,
                    R.id.col_compact_2,
                    R.id.col_compact_3,
                    R.id.col_compact_4,
                    R.id.col_compact_5
                )
                val compactFrameEmojiIds = intArrayOf(
                    R.id.frame_compact_emoji_1,
                    R.id.frame_compact_emoji_2,
                    R.id.frame_compact_emoji_3,
                    R.id.frame_compact_emoji_4,
                    R.id.frame_compact_emoji_5
                )
                val compactEmojiIds = intArrayOf(
                    R.id.tv_compact_emoji_1,
                    R.id.tv_compact_emoji_2,
                    R.id.tv_compact_emoji_3,
                    R.id.tv_compact_emoji_4,
                    R.id.tv_compact_emoji_5
                )
                val compactCheckIds = intArrayOf(
                    R.id.iv_compact_check_1,
                    R.id.iv_compact_check_2,
                    R.id.iv_compact_check_3,
                    R.id.iv_compact_check_4,
                    R.id.iv_compact_check_5
                )
                val compactBtnCheckIds = intArrayOf(
                    R.id.btn_compact_check_1,
                    R.id.btn_compact_check_2,
                    R.id.btn_compact_check_3,
                    R.id.btn_compact_check_4,
                    R.id.btn_compact_check_5
                )

                if (items.length() > 0) {
                    setViewVisibility(R.id.tv_empty_habits, View.GONE)

                    if (isCompact) {
                        // ─── Compact Mode (Horizontal Grid matching reference design) ──
                        setViewVisibility(R.id.layout_habits_compact, View.VISIBLE)
                        setViewVisibility(R.id.layout_habits_list, View.GONE)
                        setViewVisibility(R.id.tv_more_habits, View.GONE)

                        val count = minOf(5, items.length())
                        for (i in 0 until 5) {
                            if (i < count) {
                                val item = items.getJSONObject(i)
                                val id = item.optString("id", "")
                                val rawEmoji = item.optString("emoji", "⚡")
                                val emoji = if (rawEmoji.isNullOrBlank() || rawEmoji == "null") "⚡" else rawEmoji.trim()
                                val isCompleted = item.optBoolean("is_completed", false)

                                setViewVisibility(compactColIds[i], View.VISIBLE)
                                setTextViewText(compactEmojiIds[i], emoji)
                                setImageViewResource(
                                    compactCheckIds[i],
                                    if (isCompleted) R.drawable.ic_widget_check else R.drawable.ic_widget_uncheck
                                )

                                // In-place toggle broadcast: DO NOT open the app when tick is clicked
                                val tickIntent = Intent(context, UrDayHabitsWidgetProvider::class.java).apply {
                                    action = ACTION_TOGGLE_HABIT
                                    putExtra(EXTRA_HABIT_ID, id)
                                    data = Uri.parse("urday://toggle_habit?id=$id")
                                }
                                val flags = if (Build.VERSION.SDK_INT >= 23) {
                                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                                } else {
                                    PendingIntent.FLAG_UPDATE_CURRENT
                                }
                                val tickPendingIntent = PendingIntent.getBroadcast(
                                    context,
                                    id.hashCode(),
                                    tickIntent,
                                    flags
                                )

                                val rowLaunchIntent = HomeWidgetLaunchIntent.getActivity(
                                    context,
                                    MainActivity::class.java,
                                    Uri.parse("urday://habits")
                                )
                                setOnClickPendingIntent(compactColIds[i], rowLaunchIntent)
                                setOnClickPendingIntent(compactFrameEmojiIds[i], rowLaunchIntent)
                                setOnClickPendingIntent(compactEmojiIds[i], rowLaunchIntent)
                                setOnClickPendingIntent(compactBtnCheckIds[i], tickPendingIntent)
                                setOnClickPendingIntent(compactCheckIds[i], tickPendingIntent)
                            } else {
                                setViewVisibility(compactColIds[i], View.GONE)
                            }
                        }
                    } else {
                        // ─── Medium & Large Mode (Vertical Rows with Dividers) ──
                        setViewVisibility(R.id.layout_habits_list, View.VISIBLE)
                        setViewVisibility(R.id.layout_habits_compact, View.GONE)

                        val count = minOf(5, items.length())
                        for (i in 0 until 5) {
                            if (i < count) {
                                val item = items.getJSONObject(i)
                                val id = item.optString("id", "")
                                val name = item.optString("name", "Habit")
                                val rawEmoji = item.optString("emoji", "⚡")
                                val emoji = if (rawEmoji.isNullOrBlank() || rawEmoji == "null") "⚡" else rawEmoji.trim()
                                val streak = item.optInt("streak", 0)
                                val isCompleted = item.optBoolean("is_completed", false)

                                setViewVisibility(rowIds[i], View.VISIBLE)
                                setTextViewText(titleIds[i], name)
                                setTextViewText(emojiIds[i], emoji)
                                setTextViewText(streakIds[i], "🔥 $streak")
                                setImageViewResource(
                                    checkIds[i],
                                    if (isCompleted) R.drawable.ic_widget_check else R.drawable.ic_widget_uncheck
                                )

                                // In-place toggle broadcast: DO NOT open the app when tick is clicked
                                val tickIntent = Intent(context, UrDayHabitsWidgetProvider::class.java).apply {
                                    action = ACTION_TOGGLE_HABIT
                                    putExtra(EXTRA_HABIT_ID, id)
                                    data = Uri.parse("urday://toggle_habit?id=$id")
                                }
                                val flags = if (Build.VERSION.SDK_INT >= 23) {
                                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                                } else {
                                    PendingIntent.FLAG_UPDATE_CURRENT
                                }
                                val tickPendingIntent = PendingIntent.getBroadcast(
                                    context,
                                    id.hashCode(),
                                    tickIntent,
                                    flags
                                )

                                val rowLaunchIntent = HomeWidgetLaunchIntent.getActivity(
                                    context,
                                    MainActivity::class.java,
                                    Uri.parse("urday://habits")
                                )
                                setOnClickPendingIntent(rowIds[i], rowLaunchIntent)
                                setOnClickPendingIntent(btnCheckIds[i], tickPendingIntent)
                                setOnClickPendingIntent(checkIds[i], tickPendingIntent)

                                // Dividers between rows
                                if (i < 4) {
                                    setViewVisibility(dividerIds[i], if (i < count - 1) View.VISIBLE else View.GONE)
                                }
                            } else {
                                setViewVisibility(rowIds[i], View.GONE)
                                if (i < 4) {
                                    setViewVisibility(dividerIds[i], View.GONE)
                                }
                            }
                        }

                        // Show "+X more habits in UrDay →" footer if there are more than 5
                        if (items.length() > 5) {
                            val extra = items.length() - 5
                            setViewVisibility(R.id.tv_more_habits, View.VISIBLE)
                            setTextViewText(R.id.tv_more_habits, "+$extra more habits in UrDay →")
                            val moreIntent = HomeWidgetLaunchIntent.getActivity(
                                context,
                                MainActivity::class.java,
                                Uri.parse("urday://habits")
                            )
                            setOnClickPendingIntent(R.id.tv_more_habits, moreIntent)
                        } else {
                            setViewVisibility(R.id.tv_more_habits, View.GONE)
                        }
                    }
                } else {
                    // Empty state
                    setViewVisibility(R.id.tv_empty_habits, View.VISIBLE)
                    setViewVisibility(R.id.layout_habits_list, View.GONE)
                    setViewVisibility(R.id.layout_habits_compact, View.GONE)
                    setViewVisibility(R.id.tv_more_habits, View.GONE)
                }
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        } catch (e: Throwable) {
            Log.e("UrDayHabitsWidget", "Error updating habits widget", e)
        }
    }
}
