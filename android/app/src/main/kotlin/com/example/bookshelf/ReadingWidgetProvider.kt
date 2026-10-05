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
 * Home screen widget: the book being read, its progress and the streak.
 * Small (2x2) it keeps the essentials; tall (3 rows or more) it adds what is
 * left, the finish estimate and since when the book is read.
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
        val views = RemoteViews(context.packageName, R.layout.reading_widget)
        val small = size.width in 1 until 170
        val tall = size.height >= 190
        val hasBook = data.getBoolean("has_book", false)

        views.setTextViewText(
            R.id.widget_label,
            data.getString("label_reading", null) ?: context.getString(R.string.widget_reading),
        )
        views.setInt(R.id.widget_title, "setMaxLines", if (small) 3 else 2)
        if (hasBook) {
            views.setTextViewText(R.id.widget_title, data.getString("title", ""))
            val author = data.getString("author", "").orEmpty()
            views.setTextViewText(R.id.widget_author, author)
            views.setViewVisibility(
                R.id.widget_author,
                if (author.isEmpty() || small) View.GONE else View.VISIBLE,
            )
            val progress = data.getInt("progress", -1)
            views.setViewVisibility(R.id.widget_progress, if (progress < 0) View.GONE else View.VISIBLE)
            views.setProgressBar(R.id.widget_progress, 100, progress.coerceIn(0, 100), false)
            views.setTextViewText(R.id.widget_progress_label, data.getString("progress_label", ""))
            views.setViewVisibility(R.id.widget_progress_label, if (small) View.GONE else View.VISIBLE)
        } else {
            views.setTextViewText(
                R.id.widget_title,
                data.getString("label_no_book", null) ?: context.getString(R.string.widget_no_book),
            )
            views.setViewVisibility(R.id.widget_author, View.GONE)
            views.setViewVisibility(R.id.widget_progress, View.GONE)
            views.setViewVisibility(R.id.widget_progress_label, View.GONE)
        }

        // Large: one line per detail the app could work out.
        val info = listOf(
            R.id.widget_info_left to "info_left",
            R.id.widget_info_finish to "info_finish",
            R.id.widget_info_since to "info_since",
        )
        var anyInfo = false
        for ((viewId, key) in info) {
            val text = if (hasBook && tall && !small) data.getString(key, "").orEmpty() else ""
            views.setTextViewText(viewId, text)
            views.setViewVisibility(viewId, if (text.isEmpty()) View.GONE else View.VISIBLE)
            anyInfo = anyInfo || text.isNotEmpty()
        }
        views.setViewVisibility(R.id.widget_info, if (anyInfo) View.VISIBLE else View.GONE)

        // Small: only the number of days, next to the flame.
        views.setTextViewText(
            R.id.widget_streak,
            if (small) WidgetSupport.streakCount(data).toString() else WidgetSupport.streakLine(data),
        )
        views.setOnClickPendingIntent(
            R.id.widget_root,
            WidgetSupport.openBook(context, if (hasBook) data.getString("book_id", "").orEmpty() else ""),
        )
        return views
    }
}
