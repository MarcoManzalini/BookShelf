package com.example.bookshelf

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.app.PendingIntent
import android.os.Bundle
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import java.time.LocalDate

/** What the home screen widgets share: the streak, their size, the taps. */
object WidgetSupport {
    /** Width and height of a placed widget, in dp (portrait). */
    data class Size(val width: Int, val height: Int)

    fun size(manager: AppWidgetManager, id: Int): Size = size(manager.getAppWidgetOptions(id))

    fun size(options: Bundle): Size = Size(
        options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0),
        options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0),
    )

    private enum class Streak { TODAY, ALIVE, NONE }

    private fun streakState(data: SharedPreferences): Streak {
        val last = data.getString("last_read_day", "").orEmpty()
        val today = LocalDate.now()
        return when (last) {
            today.toString() -> Streak.TODAY
            today.minusDays(1).toString() -> Streak.ALIVE
            else -> Streak.NONE
        }
    }

    /** "12 days in a row · Read today", "12 days in a row" or "Start a streak". */
    fun streakLine(data: SharedPreferences): String {
        val key = when (streakState(data)) {
            Streak.TODAY -> "streak_today"
            Streak.ALIVE -> "streak_alive"
            Streak.NONE -> "streak_none"
        }
        return data.getString(key, "").orEmpty()
    }

    /** Days in a row, 0 once a whole day went by without reading. */
    fun streakCount(data: SharedPreferences): Int =
        if (streakState(data) == Streak.NONE) 0 else data.getInt("streak_count", 0)

    /**
     * Opens the app on [path] (a route of the app, e.g. "/book/<id>").
     * Flutter's deep linking hands the path to the router.
     */
    fun open(context: Context, path: String? = null): PendingIntent =
        HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            path?.let { Uri.parse("bookshelf://widget$it") },
        )

    fun openBook(context: Context, id: String): PendingIntent =
        open(context, if (id.isEmpty()) null else "/book/${Uri.encode(id)}")
}
