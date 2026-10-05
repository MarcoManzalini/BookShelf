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
 * Home screen widget for the library: the books being read and, the taller
 * it is, the books on each shelf, the next ones to read and the custom
 * shelves. Tapping a book opens it. Data from library_widget_data.dart.
 */
class LibraryWidgetProvider : HomeWidgetProvider() {
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

    private class Row(val root: Int, val title: Int, val sub: Int, val progress: Int)

    private val readingRows = listOf(
        Row(R.id.lib_r_0, R.id.lib_r_0_title, R.id.lib_r_0_sub, R.id.lib_r_0_progress),
        Row(R.id.lib_r_1, R.id.lib_r_1_title, R.id.lib_r_1_sub, R.id.lib_r_1_progress),
        Row(R.id.lib_r_2, R.id.lib_r_2_title, R.id.lib_r_2_sub, R.id.lib_r_2_progress),
    )
    private val wantRows = listOf(
        Row(R.id.lib_w_0, R.id.lib_w_0_title, R.id.lib_w_0_sub, 0),
        Row(R.id.lib_w_1, R.id.lib_w_1_title, R.id.lib_w_1_sub, 0),
        Row(R.id.lib_w_2, R.id.lib_w_2_title, R.id.lib_w_2_sub, 0),
    )

    private fun render(
        context: Context,
        data: SharedPreferences,
        size: WidgetSupport.Size,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.library_widget)
        // Up to 180dp: two books being read. Taller: the shelf counts and a
        // third book. From 280dp: the next books and the custom shelves too.
        val height = if (size.height == 0) 200 else size.height
        val withCounts = height >= 180
        val withWant = height >= 280

        fun label(key: String, fallback: Int) =
            data.getString(key, null) ?: context.getString(fallback)

        views.setViewVisibility(R.id.lib_counts, if (withCounts) View.VISIBLE else View.GONE)
        views.setTextViewText(R.id.lib_reading_count, data.getInt("lib_reading_count", 0).toString())
        views.setTextViewText(R.id.lib_want_count, data.getInt("lib_want_count", 0).toString())
        views.setTextViewText(R.id.lib_read_count, data.getInt("lib_read_count", 0).toString())
        views.setTextViewText(R.id.lib_reading_label, label("lib_label_reading", R.string.widget_reading))
        views.setTextViewText(R.id.lib_want_label, label("lib_label_want", R.string.widget_want))
        views.setTextViewText(R.id.lib_read_label, label("lib_label_read", R.string.widget_read))

        views.setTextViewText(R.id.lib_reading_header, label("lib_label_reading", R.string.widget_reading))
        val shownReading = fill(context, views, data, "lib_r", readingRows, if (withCounts) 3 else 2)
        showEmpty(views, R.id.lib_reading_empty, shownReading, label("lib_label_empty", R.string.widget_empty))

        views.setViewVisibility(R.id.lib_want_section, if (withWant) View.VISIBLE else View.GONE)
        views.setTextViewText(R.id.lib_want_header, label("lib_label_want", R.string.widget_want))
        val shownWant = fill(context, views, data, "lib_w", wantRows, if (withWant) 3 else 0)
        showEmpty(views, R.id.lib_want_empty, shownWant, label("lib_label_empty", R.string.widget_empty))

        val shelves = data.getString("lib_shelves", "").orEmpty()
        views.setTextViewText(
            R.id.lib_shelves,
            "${label("lib_label_shelves", R.string.widget_shelves)}: $shelves",
        )
        views.setViewVisibility(
            R.id.lib_shelves,
            if (withWant && shelves.isNotEmpty()) View.VISIBLE else View.GONE,
        )

        views.setOnClickPendingIntent(R.id.lib_root, WidgetSupport.open(context, "/library"))
        return views
    }

    /** Shows up to [max] saved books in [rows]; returns how many. */
    private fun fill(
        context: Context,
        views: RemoteViews,
        data: SharedPreferences,
        prefix: String,
        rows: List<Row>,
        max: Int,
    ): Int {
        var shown = 0
        rows.forEachIndexed { i, row ->
            val title = data.getString("${prefix}_${i}_title", "").orEmpty()
            if (i >= max || title.isEmpty()) {
                views.setViewVisibility(row.root, View.GONE)
                return@forEachIndexed
            }
            shown++
            views.setViewVisibility(row.root, View.VISIBLE)
            views.setTextViewText(row.title, title)
            val sub = data.getString("${prefix}_${i}_sub", "").orEmpty()
            views.setTextViewText(row.sub, sub)
            views.setViewVisibility(row.sub, if (sub.isEmpty()) View.GONE else View.VISIBLE)
            if (row.progress != 0) {
                val progress = data.getInt("${prefix}_${i}_progress", -1)
                views.setViewVisibility(row.progress, if (progress < 0) View.GONE else View.VISIBLE)
                views.setProgressBar(row.progress, 100, progress.coerceIn(0, 100), false)
            }
            views.setOnClickPendingIntent(
                row.root,
                WidgetSupport.openBook(context, data.getString("${prefix}_${i}_id", "").orEmpty()),
            )
        }
        return shown
    }

    private fun showEmpty(views: RemoteViews, id: Int, shown: Int, text: String) {
        views.setTextViewText(id, text)
        views.setViewVisibility(id, if (shown == 0) View.VISIBLE else View.GONE)
    }
}
