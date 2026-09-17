package com.trackme.track_me

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.SweepGradient
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.text.Html
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray

class UrDayGoalWidgetProvider : HomeWidgetProvider() {

    companion object {
        const val ACTION_CYCLE_GOAL = "com.trackme.track_me.ACTION_CYCLE_GOAL"
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
        if (action == ACTION_CYCLE_GOAL) {
            handleCycleGoal(context)
        } else if (action == Intent.ACTION_CONFIGURATION_CHANGED || action == Intent.ACTION_LOCALE_CHANGED) {
            try {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val thisWidget = ComponentName(context, UrDayGoalWidgetProvider::class.java)
                val allWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
                val widgetData = getWidgetData(context)
                for (id in allWidgetIds) {
                    updateSingleWidget(context, appWidgetManager, id, widgetData)
                }
            } catch (e: Throwable) {
                Log.e("UrDayGoalWidget", "Error on configuration change update", e)
            }
        }
    }

    private fun handleCycleGoal(context: Context) {
        try {
            val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            val goalsJson = prefs.getString("goals_json", "[]") ?: "[]"
            val items = try { JSONArray(goalsJson) } catch (_: Throwable) { JSONArray() }
            val total = items.length()
            if (total > 1) {
                val current = prefs.getInt("selected_goal_index", 0)
                val next = (current + 1) % total
                val nextItem = items.getJSONObject(next)

                prefs.edit().apply {
                    putInt("selected_goal_index", next)
                    putString("goal_id", nextItem.optString("id", ""))
                    putString("goal_name", nextItem.optString("name", ""))
                    putInt("goal_progress_percent", nextItem.optInt("progress_percent", 0))
                    putString("goal_current", nextItem.optString("current", "0"))
                    putString("goal_target", nextItem.optString("target", "0"))
                    putString("goal_unit", nextItem.optString("unit", ""))
                    putString("goal_category", nextItem.optString("category", "Personal"))
                    putString("goal_category_icon", nextItem.optString("category_icon", "🎯"))
                    putInt("goal_days_left", nextItem.optInt("days_left", 0))
                    putString("goal_urgency_tier", nextItem.optString("urgency_tier", "amber"))
                    putString("goal_urgency_text", nextItem.optString("urgency_text", ""))
                    commit()
                }

                val appWidgetManager = AppWidgetManager.getInstance(context)
                val thisWidget = ComponentName(context, UrDayGoalWidgetProvider::class.java)
                val allWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
                val widgetData = getWidgetData(context)
                for (id in allWidgetIds) {
                    updateSingleWidget(context, appWidgetManager, id, widgetData)
                }
            }
        } catch (e: Throwable) {
            Log.e("UrDayGoalWidget", "Error cycling goal in widget", e)
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

    /**
     * Always reads from HomeWidgetPreferences where flutter's home_widget writes data.
     */
    private fun getWidgetData(context: Context, fallback: SharedPreferences? = null): SharedPreferences {
        val homeWidgetPrefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        if (homeWidgetPrefs.contains("goal_name") || homeWidgetPrefs.contains("goal_progress_percent")) {
            return homeWidgetPrefs
        }
        if (fallback != null && (fallback.contains("goal_name") || fallback.contains("goal_progress_percent"))) {
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
            val isCompact = (minWidth in 1..150) || (minHeight in 1..150)

            val isSystemDark = (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
            val isDark = if (prefs.contains("app_is_dark_mode")) {
                prefs.getBoolean("app_is_dark_mode", isSystemDark)
            } else {
                isSystemDark
            }

            val views = RemoteViews(context.packageName, R.layout.widget_focus_goal).apply {
                val hasActiveGoal = prefs.getBoolean("has_active_goal", true)
                val goalName = prefs.getString("goal_name", "") ?: ""

                if (!hasActiveGoal || goalName.isBlank()) {
                    // 1. Show Clean Empty State
                    setViewVisibility(R.id.view_goal_content, View.GONE)
                    setViewVisibility(R.id.view_goal_empty, View.VISIBLE)

                    val addPendingIntent = HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java,
                        Uri.parse("urday://goals?action=add")
                    )
                    setOnClickPendingIntent(R.id.widget_goal_root, addPendingIntent)
                    setOnClickPendingIntent(R.id.btn_goal_empty_add, addPendingIntent)
                } else {
                    // 2. Show Active Hero Focus Goal State
                    setViewVisibility(R.id.view_goal_content, View.VISIBLE)
                    setViewVisibility(R.id.view_goal_empty, View.GONE)

                    val goalId = prefs.getString("goal_id", "") ?: ""
                    val percent = prefs.getInt("goal_progress_percent", 0).coerceIn(0, 100)
                    val currentStr = prefs.getString("goal_current", "0") ?: "0"
                    val targetStr = prefs.getString("goal_target", "0") ?: "0"
                    val unit = prefs.getString("goal_unit", "")?.trim() ?: ""
                    val categoryIcon = prefs.getString("goal_category_icon", "🏃") ?: "🏃"
                    val urgencyTier = prefs.getString("goal_urgency_tier", "amber") ?: "amber"
                    val urgencyText = prefs.getString("goal_urgency_text", "⏳ 14 days left") ?: "⏳ 14 days left"
                    val totalGoals = prefs.getInt("total_goals_count", 1)
                    val selectedIndex = prefs.getInt("selected_goal_index", 0)

                    // Circular Progress Ring with glowing arc and glowing tip dot
                    val density = context.resources.displayMetrics.density
                    val ringDp = if (isCompact) 115 else 135
                    val ringPx = (ringDp * density).toInt().coerceAtLeast(240)
                    val ringBitmap = createFocusGoalRingBitmap(percent, ringPx, isDark, isCompact)
                    setImageViewBitmap(R.id.iv_goal_ring, ringBitmap)

                    // Percentage in center of ring
                    setTextViewText(R.id.tv_goal_percent, "$percent%")

                    // Goal values: Highlighted current in purple, target in soft white
                    val unitSuffix = if (unit.isNotEmpty()) " $unit" else ""
                    val valuesHtml = "<font color='#C084FC'><b>$currentStr</b></font> <font color='#9CA3AF'>/</font> <font color='#E0E7FF'>$targetStr$unitSuffix</font>"
                    @Suppress("DEPRECATION")
                    val formattedValues = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        Html.fromHtml(valuesHtml, Html.FROM_HTML_MODE_LEGACY)
                    } else {
                        Html.fromHtml(valuesHtml)
                    }
                    setTextViewText(R.id.tv_goal_values, formattedValues)

                    // Category Icon & Goal Title
                    setTextViewText(R.id.tv_goal_category_icon, categoryIcon)
                    setTextViewText(R.id.tv_goal_title, goalName)

                    // Options / Cycle button: If multiple goals exist, show "1/3 ↻", else "•••"
                    if (totalGoals > 1) {
                        setTextViewText(R.id.tv_goal_options, "${selectedIndex + 1}/$totalGoals ↻")
                        setTextColor(R.id.tv_goal_options, Color.parseColor("#C084FC"))
                    } else {
                        setTextViewText(R.id.tv_goal_options, "•••")
                        setTextColor(R.id.tv_goal_options, Color.parseColor("#6B7280"))
                    }

                    // Cycle PendingIntent when top-right button is clicked
                    val cycleIntent = Intent(context, UrDayGoalWidgetProvider::class.java).apply {
                        action = ACTION_CYCLE_GOAL
                    }
                    val flags = PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
                    val cyclePendingIntent = PendingIntent.getBroadcast(
                        context,
                        appWidgetId * 200,
                        cycleIntent,
                        flags
                    )
                    setOnClickPendingIntent(R.id.btn_goal_cycle, cyclePendingIntent)

                    // Urgency Pill: Dynamic background and text color based on urgency tier
                    val (pillBgRes, textColor) = when (urgencyTier.lowercase()) {
                        "green" -> Pair(R.drawable.widget_goal_urgency_pill_green, Color.parseColor("#34D399"))
                        "red", "overdue" -> Pair(R.drawable.widget_goal_urgency_pill_red, Color.parseColor("#F87171"))
                        else -> Pair(R.drawable.widget_goal_urgency_pill_amber, Color.parseColor("#FBBF24"))
                    }
                    setInt(R.id.pill_urgency_container, "setBackgroundResource", pillBgRes)
                    setTextColor(R.id.tv_goal_urgency, textColor)
                    setTextViewText(R.id.tv_goal_urgency, urgencyText)

                    // Deep link to open the specific goal details
                    val deepLinkUri = if (goalId.isNotEmpty()) {
                        Uri.parse("urday://goals?id=$goalId")
                    } else {
                        Uri.parse("urday://goals")
                    }
                    val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java,
                        deepLinkUri
                    )
                    setOnClickPendingIntent(R.id.widget_goal_root, pendingIntent)
                }
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        } catch (e: Throwable) {
            Log.e("UrDayGoalWidget", "Error updating focus goal widget", e)
        }
    }

    /**
     * Dynamically generates a high-resolution, futuristic circular progress ring
     * matching the reference image:
     * - Dark translucent inactive background track
     * - Smooth purple-to-violet glowing gradient arc
     * - Rounded arc ends
     * - Glowing circular head dot at the tip of the arc
     */
    private fun createFocusGoalRingBitmap(
        percent: Int,
        sizePx: Int,
        isDark: Boolean,
        isCompact: Boolean
    ): Bitmap {
        val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        val strokeRatio = if (isCompact) 0.085f else 0.095f
        val strokeWidth = sizePx * strokeRatio
        val padding = strokeWidth * 0.9f
        val rect = RectF(padding, padding, sizePx - padding, sizePx - padding)
        val radius = (sizePx - 2 * padding) / 2f
        val center = sizePx / 2f

        // 1. Inactive background track ring
        val trackColor = if (isDark) Color.parseColor("#1F1D33") else Color.parseColor("#ECECF2")
        val trackPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            this.strokeWidth = strokeWidth
            color = trackColor
            strokeCap = Paint.Cap.ROUND
        }
        canvas.drawArc(rect, 0f, 360f, false, trackPaint)

        // 2. Active gradient progress arc
        val clampedPercent = percent.coerceIn(0, 100)
        if (clampedPercent > 0) {
            val sweepAngle = 360f * (clampedPercent / 100f)

            // Outer soft ambient neon glow layer behind the active stroke
            val glowColor = if (isDark) Color.parseColor("#4D8B5CF6") else Color.parseColor("#267C3AED")
            val glowPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                this.strokeWidth = strokeWidth * 1.45f
                color = glowColor
                strokeCap = Paint.Cap.ROUND
            }
            canvas.drawArc(rect, -90f, sweepAngle, false, glowPaint)

            // Main smooth purple-to-violet gradient arc
            val progressPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                this.strokeWidth = strokeWidth
                strokeCap = Paint.Cap.ROUND

                val colors = intArrayOf(
                    Color.parseColor("#7C3AED"), // Deep violet
                    Color.parseColor("#8B5CF6"), // Purple
                    Color.parseColor("#A855F7"), // Bright violet
                    Color.parseColor("#C084FC"), // Lavender glow
                    Color.parseColor("#7C3AED")
                )
                val positions = floatArrayOf(0f, 0.35f, 0.70f, 0.95f, 1f)
                val sweepGradient = SweepGradient(center, center, colors, positions)
                val matrix = Matrix()
                matrix.postRotate(-90f, center, center)
                sweepGradient.setLocalMatrix(matrix)
                shader = sweepGradient
            }
            canvas.drawArc(rect, -90f, sweepAngle, false, progressPaint)

            // 3. Glowing circular head indicator dot right at the end of the arc
            if (clampedPercent < 100) {
                val endAngleRad = Math.toRadians((-90f + sweepAngle).toDouble())
                val tipX = (center + radius * Math.cos(endAngleRad)).toFloat()
                val tipY = (center + radius * Math.sin(endAngleRad)).toFloat()

                // Soft glowing halo around tip dot
                val tipHaloPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    style = Paint.Style.FILL
                    color = Color.parseColor("#66C084FC")
                }
                canvas.drawCircle(tipX, tipY, strokeWidth * 0.75f, tipHaloPaint)

                // Crisp inner white indicator dot
                val tipDotPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    style = Paint.Style.FILL
                    color = Color.parseColor("#FFFFFF")
                }
                canvas.drawCircle(tipX, tipY, strokeWidth * 0.40f, tipDotPaint)
            }
        }

        return bitmap
    }
}
