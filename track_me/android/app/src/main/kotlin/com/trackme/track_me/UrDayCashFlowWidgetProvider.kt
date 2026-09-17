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
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RadialGradient
import android.graphics.Shader
import android.net.Uri
import android.os.Bundle
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class UrDayCashFlowWidgetProvider : HomeWidgetProvider() {

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
                val thisWidget = ComponentName(context, UrDayCashFlowWidgetProvider::class.java)
                val allWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
                val widgetData = getWidgetData(context)
                for (id in allWidgetIds) {
                    updateSingleWidget(context, appWidgetManager, id, widgetData)
                }
            } catch (e: Throwable) {
                Log.e("UrDayCashFlowWidget", "Error on configuration change update", e)
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
        if (homeWidgetPrefs.contains("cashflow_net") || homeWidgetPrefs.contains("cashflow_has_data")) {
            return homeWidgetPrefs
        }
        if (fallback != null && (fallback.contains("cashflow_net") || fallback.contains("cashflow_has_data"))) {
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

            // Dynamic theme detection
            val isSystemDark = (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
            val isDark = if (prefs.contains("app_is_dark_mode")) {
                prefs.getBoolean("app_is_dark_mode", isSystemDark)
            } else {
                isSystemDark
            }

            val rawNet = prefs.getString("cashflow_net", "+₹0") ?: "+₹0"
            val netVal = prefs.getFloat("cashflow_net_val", 0f).toDouble()
            val isPositive = prefs.getBoolean("cashflow_is_positive", netVal >= 0)
            val income = prefs.getString("cashflow_income", "₹0") ?: "₹0"
            val outflow = prefs.getString("cashflow_outflow", "₹0") ?: "₹0"
            val bank = prefs.getString("cashflow_bank", "₹0") ?: "₹0"
            val cash = prefs.getString("cashflow_cash", "₹0") ?: "₹0"
            val card = prefs.getString("cashflow_card", "₹0") ?: "₹0"

            val views = RemoteViews(context.packageName, R.layout.widget_cash_flow).apply {
                // 1. Subtle wavy background lines matching CashFlowHeroCard._WaveBackgroundPainter
                val density = context.resources.displayMetrics.density
                val waveWidthPx = (180 * density).toInt().coerceAtLeast(360)
                val waveHeightPx = (180 * density).toInt().coerceAtLeast(360)
                val waveBitmap = createWaveDecorationBitmap(waveWidthPx, waveHeightPx, isDark)
                setImageViewBitmap(R.id.iv_cashflow_wave, waveBitmap)

                // 2. Net Cash Flow Main Amount
                setTextViewText(R.id.tv_net_amount, rawNet)

                // 3. Dynamic Status Pill (Positive / Deficit / Neutral)
                if (netVal > 0 || (netVal == 0.0 && isPositive)) {
                    setTextViewText(R.id.tv_status_text, "↗ Positive")
                    setTextColor(R.id.tv_status_text, Color.WHITE)
                } else if (netVal < 0) {
                    setTextViewText(R.id.tv_status_text, "↘ Deficit")
                    setTextColor(R.id.tv_status_text, Color.WHITE)
                } else {
                    setTextViewText(R.id.tv_status_text, "• Neutral")
                    setTextColor(R.id.tv_status_text, Color.WHITE)
                }

                // 4. Income & Outflow Compact Chips
                // Prefix with arrows matching the signature card (↙ for Income, ↗ for Outflow)
                val safeIncome = if (income.startsWith("+") || income.startsWith("↙")) income else "+$income"
                val safeOutflow = if (outflow.startsWith("-") || outflow.startsWith("↗")) outflow else "-$outflow"
                setTextViewText(R.id.tv_income_amount, "↙ $safeIncome")
                setTextViewText(R.id.tv_outflow_amount, "↗ $safeOutflow")

                // 5. Balance Breakdown Values inside Translucent Container
                setTextViewText(R.id.tv_bank_amount, bank)
                setTextViewText(R.id.tv_cash_amount, cash)
                setTextViewText(R.id.tv_card_amount, card)

                // 6. Navigation Deep Links
                val cashFlowPendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("urday://cashflow")
                )
                setOnClickPendingIntent(R.id.widget_cashflow_root, cashFlowPendingIntent)
                setOnClickPendingIntent(R.id.layout_balances_box, cashFlowPendingIntent)
                setOnClickPendingIntent(R.id.layout_bank_pocket, cashFlowPendingIntent)
                setOnClickPendingIntent(R.id.layout_cash_pocket, cashFlowPendingIntent)
                setOnClickPendingIntent(R.id.layout_card_pocket, cashFlowPendingIntent)

                // Quick Action Deep Links on flow chips
                val incomePendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("urday://cashflow?action=income")
                )
                setOnClickPendingIntent(R.id.layout_income_chip, incomePendingIntent)

                val outflowPendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("urday://cashflow?action=outflow")
                )
                setOnClickPendingIntent(R.id.layout_outflow_chip, outflowPendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        } catch (e: Throwable) {
            Log.e("UrDayCashFlowWidget", "Error updating cashflow widget", e)
        }
    }

    /**
     * Recreates the exact subtle flowing wave lines from CashFlowHeroCard._WaveBackgroundPainter
     */
    private fun createWaveDecorationBitmap(widthPx: Int, heightPx: Int, isDark: Boolean): Bitmap {
        val bitmap = Bitmap.createBitmap(widthPx, heightPx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val w = widthPx.toFloat()
        val h = heightPx.toFloat()

        // 1. Subtle soft radial aura in the top-right corner
        val auraPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = RadialGradient(
                w * 0.85f, h * 0.15f, w * 0.65f,
                intArrayOf(Color.argb(30, 255, 255, 255), Color.TRANSPARENT),
                floatArrayOf(0f, 1f),
                Shader.TileMode.CLAMP
            )
        }
        canvas.drawCircle(w * 0.85f, h * 0.15f, w * 0.65f, auraPaint)

        // 2. Wave stroke paint matching Flutter white with opacity 0.14
        val wavePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.argb(36, 255, 255, 255)
            style = Paint.Style.STROKE
            strokeWidth = 2.8f * (widthPx / 360f).coerceAtLeast(2.0f)
            strokeCap = Paint.Cap.ROUND
        }

        // Wave 1: cubicTo(w * 0.25, h * 0.1, w * 0.65, h * 0.7, w, h * 0.3)
        val path1 = Path().apply {
            moveTo(0f, h * 0.35f)
            cubicTo(
                w * 0.25f, h * 0.10f,
                w * 0.65f, h * 0.70f,
                w, h * 0.30f
            )
        }
        canvas.drawPath(path1, wavePaint)

        // Wave 2: cubicTo(w * 0.35, h * 0.3, w * 0.75, h * 0.95, w, h * 0.55)
        val path2 = Path().apply {
            moveTo(0f, h * 0.65f)
            cubicTo(
                w * 0.35f, h * 0.30f,
                w * 0.75f, h * 0.95f,
                w, h * 0.55f
            )
        }
        canvas.drawPath(path2, wavePaint)

        return bitmap
    }
}
