package com.example.sleep_tracker

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.RemoteViews

class RemindersWidgetProvider : AppWidgetProvider() {
    companion object {
        const val PREFS_NAME = "sleep_tracker_widget_prefs"
        const val ACTION_UPDATE = "com.example.sleep_tracker.ACTION_UPDATE_WIDGET"
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        Log.d("WidgetDebug", "RemindersWidgetProvider.onUpdate ids=${appWidgetIds.joinToString()}")
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        Log.d("WidgetDebug", "RemindersWidgetProvider.onReceive action=${intent.action}")
        if (intent.action == ACTION_UPDATE || intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(ComponentName(context, RemindersWidgetProvider::class.java))
            Log.d("WidgetDebug", "RemindersWidgetProvider matched action, ids=${ids.joinToString()}")
            for (id in ids) updateAppWidget(context, mgr, id)
        }
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val bedtime = prefs.getString("reminders_bedtime", "Off") ?: "Off"
        val wake = prefs.getString("reminders_wake", "Off") ?: "Off"
        val eye = prefs.getString("reminders_eye_comfort", "Off") ?: "Off"
        Log.d("WidgetDebug", "updateAppWidget id=$appWidgetId bedtime=$bedtime wake=$wake eye=$eye")

        val views = RemoteViews(context.packageName, R.layout.widget_reminders)
        // Labels (static) — ensure the user understands the purpose of each time
        views.setTextViewText(R.id.label_bedtime, "Bedtime")
        views.setTextViewText(R.id.label_wake, "Wake-Up")
        views.setTextViewText(R.id.label_eye, "Eye Comfort")
        // Values (dynamic)
        views.setTextViewText(R.id.reminder_bedtime, bedtime)
        views.setTextViewText(R.id.reminder_wake, wake)
        views.setTextViewText(R.id.reminder_eye, eye)

        val intent = Intent(context, MainActivity::class.java)
        val pi = PendingIntent.getActivity(context, 1, intent, PendingIntent.FLAG_IMMUTABLE)
        views.setOnClickPendingIntent(R.id.widget_root_reminders, pi)

        appWidgetManager.updateAppWidget(appWidgetId, views)
        Log.d("WidgetDebug", "updateAppWidget id=$appWidgetId done")
    }
}