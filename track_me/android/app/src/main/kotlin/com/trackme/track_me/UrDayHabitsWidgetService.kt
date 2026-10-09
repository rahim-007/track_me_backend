package com.trackme.track_me

import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray
import org.json.JSONObject

class UrDayHabitsWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return UrDayHabitsRemoteViewsFactory(this.applicationContext, intent)
    }
}

class UrDayHabitsRemoteViewsFactory(
    private val context: Context,
    private val intent: Intent
) : RemoteViewsService.RemoteViewsFactory {

    private val habitsList = mutableListOf<JSONObject>()

    override fun onCreate() {
        loadData()
    }

    override fun onDataSetChanged() {
        loadData()
    }

    private fun loadData() {
        habitsList.clear()
        try {
            val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            val habitsJson = prefs.getString("habits_json", "[]") ?: "[]"
            val array = JSONArray(habitsJson)
            for (i in 0 until array.length()) {
                habitsList.add(array.getJSONObject(i))
            }
        } catch (_: Throwable) {
        }
    }

    override fun onDestroy() {
        habitsList.clear()
    }

    override fun getCount(): Int = habitsList.size

    override fun getViewAt(position: Int): RemoteViews? {
        if (position < 0 || position >= habitsList.size) return null

        val item = habitsList[position]
        val id = item.optString("id", "")
        val name = item.optString("name", "Habit")
        val rawEmoji = item.optString("emoji", "⚡")
        val emoji = if (rawEmoji.isNullOrBlank() || rawEmoji == "null") "⚡" else rawEmoji.trim()
        val streak = item.optInt("streak", 0)
        val isCompleted = item.optBoolean("is_completed", false)

        val views = RemoteViews(context.packageName, R.layout.widget_habit_item)
        views.setTextViewText(R.id.tv_title, name)
        views.setTextViewText(R.id.tv_emoji, emoji)
        views.setTextViewText(R.id.tv_streak, "🔥 $streak")
        views.setImageViewResource(
            R.id.iv_check,
            if (isCompleted) R.drawable.ic_widget_check else R.drawable.ic_widget_uncheck
        )

        // 1. Tapping checkmark toggles habit in-place without opening app
        val toggleFillInIntent = Intent().apply {
            putExtra(UrDayHabitsWidgetProvider.EXTRA_ACTION_TYPE, UrDayHabitsWidgetProvider.ACTION_TOGGLE)
            putExtra(UrDayHabitsWidgetProvider.EXTRA_HABIT_ID, id)
        }
        views.setOnClickFillInIntent(R.id.btn_check, toggleFillInIntent)
        views.setOnClickFillInIntent(R.id.iv_check, toggleFillInIntent)

        // 2. Tapping habit row opens UrDay app to habits
        val openAppFillInIntent = Intent().apply {
            putExtra(UrDayHabitsWidgetProvider.EXTRA_ACTION_TYPE, UrDayHabitsWidgetProvider.ACTION_OPEN_APP)
            putExtra(UrDayHabitsWidgetProvider.EXTRA_HABIT_ID, id)
        }
        views.setOnClickFillInIntent(R.id.row_habit, openAppFillInIntent)

        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = false
}
