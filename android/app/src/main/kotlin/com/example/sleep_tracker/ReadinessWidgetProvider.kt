package com.example.sleep_tracker

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews

class ReadinessWidgetProvider : AppWidgetProvider() {
    companion object {
        const val PREFS_NAME = "sleep_tracker_widget_prefs"
        const val ACTION_UPDATE = "com.example.sleep_tracker.ACTION_UPDATE_WIDGET"
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_UPDATE || intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(ComponentName(context, ReadinessWidgetProvider::class.java))
            for (id in ids) updateAppWidget(context, mgr, id)
        }
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val duration = prefs.getString("readiness_countdown", "--") ?: "--"
        val target = prefs.getString("readiness_target_goal", "--") ?: "--"
        val lastWake = prefs.getString("readiness_last_wake", "--") ?: "--"
        val streak = prefs.getString("readiness_sleep_streak", "--") ?: "--"

        val views = RemoteViews(context.packageName, R.layout.widget_readiness)
        views.setTextViewText(R.id.readiness_time, duration)
        views.setTextViewText(
            R.id.readiness_subtitle,
            "Last sleep session duration"
        )
        views.setTextViewText(R.id.readiness_target, target)
        views.setTextViewText(R.id.readiness_last_wake, lastWake)
        views.setTextViewText(R.id.readiness_streak, streak)

        // Launch main activity when the user taps widget
        val intent = Intent(context, MainActivity::class.java)
        val pi = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_IMMUTABLE)
        views.setOnClickPendingIntent(R.id.widget_root, pi)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
