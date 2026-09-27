package com.example.bookshelf

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.time.LocalDate

/**
 * Home screen widget: the book being read, its progress and the streak.
 * The app writes the texts (see reading_widget_sync.dart); the widget only
 * picks the streak line for today, so it stays right after midnight.
 */
class ReadingWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, render(context, widgetData))
        }
    }

    private fun render(context: Context, data: SharedPreferences): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.reading_widget)
        val hasBook = data.getBoolean("has_book", false)

        views.setTextViewText(
            R.id.widget_label,
            data.getString("label_reading", null) ?: context.getString(R.string.widget_reading),
        )
        if (hasBook) {
            views.setTextViewText(R.id.widget_title, data.getString("title", ""))
            val author = data.getString("author", "").orEmpty()
            views.setTextViewText(R.id.widget_author, author)
            views.setViewVisibility(R.id.widget_author, if (author.isEmpty()) View.GONE else View.VISIBLE)
            val progress = data.getInt("progress", -1)
            views.setViewVisibility(R.id.widget_progress, if (progress < 0) View.GONE else View.VISIBLE)
            views.setProgressBar(R.id.widget_progress, 100, progress.coerceIn(0, 100), false)
            views.setTextViewText(R.id.widget_progress_label, data.getString("progress_label", ""))
            views.setViewVisibility(R.id.widget_progress_label, View.VISIBLE)
        } else {
            views.setTextViewText(
                R.id.widget_title,
                data.getString("label_no_book", null) ?: context.getString(R.string.widget_no_book),
            )
            views.setViewVisibility(R.id.widget_author, View.GONE)
            views.setViewVisibility(R.id.widget_progress, View.GONE)
            views.setViewVisibility(R.id.widget_progress_label, View.GONE)
        }

        views.setTextViewText(R.id.widget_streak, streakLine(data))
        views.setOnClickPendingIntent(
            R.id.widget_root,
            HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
        )
        return views
    }

    /** "12 days in a row · Read today", "12 days in a row" or "Start a streak". */
    private fun streakLine(data: SharedPreferences): String {
        val last = data.getString("last_read_day", "").orEmpty()
        val today = LocalDate.now()
        val key = when (last) {
            today.toString() -> "streak_today"
            today.minusDays(1).toString() -> "streak_alive"
            else -> "streak_none"
        }
        return data.getString(key, "").orEmpty()
    }
}
