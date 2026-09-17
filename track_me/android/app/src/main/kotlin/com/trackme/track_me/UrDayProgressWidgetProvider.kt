package com.trackme.track_me

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
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

class UrDayProgressWidgetProvider : HomeWidgetProvider() {

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
        if (action == Intent.ACTION_CONFIGURATION_CHANGED || action == Intent.ACTION_LOCALE_CHANGED) {
            try {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val thisWidget = ComponentName(context, UrDayProgressWidgetProvider::class.java)
                val allWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
                val widgetData = getWidgetData(context)
                for (id in allWidgetIds) {
                    updateSingleWidget(context, appWidgetManager, id, widgetData)
                }
            } catch (e: Throwable) {
                Log.e("UrDayWidget", "Error on configuration change update", e)
            }
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
        if (homeWidgetPrefs.contains("progress_percent") || homeWidgetPrefs.contains("streak_count")) {
            return homeWidgetPrefs
        }
        if (fallback != null && (fallback.contains("progress_percent") || fallback.contains("streak_count"))) {
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
            val isCompact = (minWidth > 0 && minWidth < 200) || (minHeight > 0 && minHeight < 115)

            // Dynamic theme detection: respects app preference or falls back to system mode
            val isSystemDark = (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
            val isDark = if (prefs.contains("app_is_dark_mode")) {
                prefs.getBoolean("app_is_dark_mode", isSystemDark)
            } else {
                isSystemDark
            }

            val views = RemoteViews(context.packageName, R.layout.widget_daily_progress).apply {
                val percent = prefs.getInt("progress_percent", 0)
                val ratio = prefs.getString("progress_ratio", "0/0") ?: "0/0"
                val streak = prefs.getInt("streak_count", 0)
                val quote = prefs.getString(
                    "daily_quote",
                    "Small healthy choices become a strong life."
                ) ?: "Small healthy choices become a strong life."

                // 1. Dynamic Circular Progress Ring Bitmap with Theme Awareness
                val density = context.resources.displayMetrics.density
                val baseDp = if (isCompact) 115 else 130
                val ringSizePx = (baseDp * density).toInt().coerceAtLeast(260)
                val ringBitmap = createProgressRingBitmap(percent, ringSizePx, isDark, isCompact)
                setImageViewBitmap(R.id.iv_progress_ring, ringBitmap)

                // 2. Center Progress Percentage & "Today"
                setTextViewText(R.id.tv_progress_percent, "$percent%")
                setTextViewText(R.id.tv_progress_subtext, "Today")

                // 3. Dynamic Streak: single line format ("🔥 +2 Streak")
                val accentHex = if (isDark) "#A78BFA" else "#6E49E6"
                val streakLabel = if (streak > 0) "+$streak Streak" else "0 Streak"
                val streakText = "🔥 <font color='$accentHex'>$streakLabel</font>"

                @Suppress("DEPRECATION")
                val formattedStreak = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    Html.fromHtml(streakText, Html.FROM_HTML_MODE_LEGACY)
                } else {
                    Html.fromHtml(streakText)
                }
                setTextViewText(R.id.tv_streak_count, formattedStreak)

                // 4. Secondary Circle: Day ("Tue") & Date ("Sep 16")
                val savedDayName = prefs.getString("date_day_name", null)
                val savedDateStr = prefs.getString("date_formatted", null)

                val cal = Calendar.getInstance()
                val dayName = savedDayName ?: SimpleDateFormat("EEE", Locale.getDefault()).format(cal.time)
                val dateStr = savedDateStr ?: SimpleDateFormat("MMM d", Locale.getDefault()).format(cal.time)

                setTextViewText(R.id.tv_date_day, dayName)
                setTextViewText(R.id.tv_date_day_num, dateStr)

                // 5. Preserved legacy views (hidden in layout for 100% backward safety)
                setTextViewText(R.id.tv_progress_ratio, "$ratio Done")
                setProgressBar(R.id.pb_daily_progress, 100, percent, false)
                setTextViewText(R.id.tv_daily_quote, quote)

                // 6. Launch UrDay dashboard on tap
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("urday://dashboard")
                )
                setOnClickPendingIntent(R.id.widget_progress_root, pendingIntent)
                setOnClickPendingIntent(R.id.main_circle_container, pendingIntent)
                setOnClickPendingIntent(R.id.secondary_circle_container, pendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        } catch (e: Throwable) {
            Log.e("UrDayWidget", "Error updating progress widget", e)
        }
    }

    /**
     * Dynamically generates a high-resolution, anti-aliased circular progress ring
     * with theme-aware gradient and rounded caps.
     */
    private fun createProgressRingBitmap(
        percent: Int,
        sizePx: Int,
        isDark: Boolean,
        isCompact: Boolean
    ): Bitmap {
        val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        val strokeRatio = if (isCompact) 0.060f else 0.065f
        val strokeWidth = sizePx * strokeRatio
        val padding = strokeWidth / 2f + 2f
        val rect = RectF(padding, padding, sizePx - padding, sizePx - padding)

        // 1. Inactive background track ring
        val trackColor = if (isDark) Color.parseColor("#1C1B30") else Color.parseColor("#ECECF2")
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

            // Soft ambient glow layer behind the active stroke
            val glowColor = if (isDark) Color.parseColor("#2E8B5CF6") else Color.parseColor("#1A7C3AED")
            val glowPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                this.strokeWidth = strokeWidth * 1.30f
                color = glowColor
                strokeCap = Paint.Cap.ROUND
            }
            canvas.drawArc(rect, -90f, sweepAngle, false, glowPaint)

            // Main smooth purple-to-violet gradient arc
            val progressPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                this.strokeWidth = strokeWidth
                strokeCap = Paint.Cap.ROUND

                val colors = if (isDark) {
                    intArrayOf(
                        Color.parseColor("#7C3AED"),
                        Color.parseColor("#8B5CF6"),
                        Color.parseColor("#A78BFA"),
                        Color.parseColor("#7C3AED")
                    )
                } else {
                    intArrayOf(
                        Color.parseColor("#6D28D9"),
                        Color.parseColor("#7C3AED"),
                        Color.parseColor("#8B5CF6"),
                        Color.parseColor("#6D28D9")
                    )
                }
                val positions = floatArrayOf(0f, 0.45f, 0.9f, 1f)
                val sweepGradient = SweepGradient(sizePx / 2f, sizePx / 2f, colors, positions)
                val matrix = Matrix()
                matrix.postRotate(-90f, sizePx / 2f, sizePx / 2f)
                sweepGradient.setLocalMatrix(matrix)
                shader = sweepGradient
            }
            canvas.drawArc(rect, -90f, sweepAngle, false, progressPaint)
        }

        return bitmap
    }
}
