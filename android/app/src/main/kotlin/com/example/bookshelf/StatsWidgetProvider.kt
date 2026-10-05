package com.example.bookshelf

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home screen widget for the statistics: books read this year against the
 * goal and, when wide enough, the streak and the pages read. Opens the
 * statistics page. Data from stats_widget_data.dart.
 */
class StatsWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            val size = WidgetSupport.size(appWidgetManager, id)
            appWidgetManager.updateAppWidget(id, render(context, widgetData, size))
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        val views = render(context, HomeWidgetPlugin.getData(context), WidgetSupport.size(newOptions))
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun render(
        context: Context,
        data: SharedPreferences,
        size: WidgetSupport.Size,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.stats_widget)
        val wide = size.width == 0 || size.width >= 230

        fun text(key: String) = data.getString(key, "").orEmpty()

        views.setTextViewText(R.id.stat_year, text("stat_label_year"))
        views.setTextViewText(R.id.stat_books, data.getInt("stat_books_year", 0).toString())
        views.setTextViewText(R.id.stat_books_label, text("stat_label_books"))
        val goal = data.getInt("stat_goal_progress", -1)
        views.setViewVisibility(R.id.stat_goal_bar, if (goal < 0) View.GONE else View.VISIBLE)
        views.setProgressBar(R.id.stat_goal_bar, 100, goal.coerceIn(0, 100), false)
        views.setTextViewText(R.id.stat_goal, text("stat_label_goal"))

        views.setViewVisibility(R.id.stat_side, if (wide) View.VISIBLE else View.GONE)
        views.setTextViewText(R.id.stat_streak, WidgetSupport.streakCount(data).toString())
        views.setTextViewText(R.id.stat_streak_label, text("stat_label_streak"))
        views.setTextViewText(R.id.stat_month, data.getInt("stat_pages_month", 0).toString())
        views.setTextViewText(R.id.stat_month_label, text("stat_label_month"))
        views.setTextViewText(R.id.stat_avg, data.getInt("stat_avg_pages", 0).toString())
        views.setTextViewText(R.id.stat_avg_label, text("stat_label_avg"))

        views.setOnClickPendingIntent(R.id.stat_root, WidgetSupport.open(context, "/stats"))
        return views
    }
}
