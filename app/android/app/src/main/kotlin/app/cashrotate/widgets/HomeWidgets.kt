package app.cashrotate.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import app.cashrotate.MainActivity
import app.cashrotate.R
import org.json.JSONObject
import java.time.LocalDate
import java.time.temporal.ChronoUnit

/**
 * What the widgets show, written by the app (Dart builds it, already
 * localised and formatted; amounts are masked in hidden-amounts mode). Days
 * left are worked out here so the widgets stay right after midnight.
 */
object WidgetStore {
    private const val PREFS = "home_widgets"
    private const val KEY = "snapshot"

    fun save(context: Context, json: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(KEY, json).apply()
    }

    fun load(context: Context): JSONObject? =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, null)
            ?.let { runCatching { JSONObject(it) }.getOrNull() }
}

/** The three sizes in the widget picker. */
abstract class HomeWidget(
    private val layout: Int,
    private val rows: Int,
    private val summary: Boolean,
    private val progress: Boolean,
) : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val views = WidgetRenderer.render(context, layout, rows, summary, progress)
        ids.forEach { manager.updateAppWidget(it, views) }
    }
}

class SmallWidget : HomeWidget(R.layout.widget_small, rows = 1, summary = false, progress = false)

class MediumWidget : HomeWidget(R.layout.widget_medium, rows = 3, summary = true, progress = false)

class LargeWidget : HomeWidget(R.layout.widget_large, rows = 6, summary = true, progress = true)

object WidgetRenderer {
    private val providers = listOf(
        SmallWidget::class.java,
        MediumWidget::class.java,
        LargeWidget::class.java,
    )

    /** Redraws every placed widget (after the app's data changed, or daily). */
    fun refreshAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        for (provider in providers) {
            val ids = manager.getAppWidgetIds(ComponentName(context, provider))
            if (ids.isEmpty()) continue
            context.sendBroadcast(
                Intent(context, provider)
                    .setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE)
                    .putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids),
            )
        }
    }

    fun render(
        context: Context,
        layout: Int,
        rows: Int,
        summary: Boolean,
        progress: Boolean,
        today: LocalDate = LocalDate.now(),
    ): RemoteViews {
        val views = RemoteViews(context.packageName, layout)
        views.setOnClickPendingIntent(R.id.widget_root, openApp(context, null))
        views.removeAllViews(R.id.widget_rows)
        val snapshot = WidgetStore.load(context)
        if (snapshot == null) {
            views.setTextViewText(R.id.widget_title, "")
            views.setTextViewText(R.id.widget_total, "")
            showEmpty(views, context.getString(R.string.widget_open_app))
            return views
        }

        views.setTextViewText(R.id.widget_title, snapshot.optString("title"))
        views.setTextViewText(R.id.widget_total, snapshot.optString("total"))
        if (summary) views.setTextViewText(R.id.widget_summary, snapshot.optString("summary"))
        if (progress) {
            views.setProgressBar(R.id.widget_progress, 1000, (snapshot.optDouble("paidShare", 0.0) * 1000).toInt(), false)
        }

        val labels = snapshot.optJSONObject("labels") ?: JSONObject()
        val items = snapshot.optJSONArray("items")
        val count = minOf(rows, items?.length() ?: 0)
        if (count == 0) {
            showEmpty(views, snapshot.optString("empty"))
            return views
        }
        views.setViewVisibility(R.id.widget_empty, View.GONE)
        for (i in 0 until count) {
            val item = items!!.getJSONObject(i)
            val row = RemoteViews(context.packageName, R.layout.widget_row)
            row.setTextViewText(R.id.row_badge, item.optString("letter"))
            row.setTextViewText(R.id.row_name, item.optString("name"))
            row.setTextViewText(R.id.row_amount, item.optString("amount"))
            val days = runCatching {
                ChronoUnit.DAYS.between(today, LocalDate.parse(item.getString("dueOn"))).toInt()
            }.getOrDefault(0)
            val overdue = days < 0
            val due = when {
                overdue -> labels.optString("overdue").replace("{n}", "${-days}")
                days == 0 -> labels.optString("today")
                days == 1 -> labels.optString("tomorrow")
                else -> labels.optString("inDays").replace("{n}", "$days")
            }
            row.setTextViewText(if (overdue) R.id.row_overdue else R.id.row_due, due)
            row.setViewVisibility(R.id.row_overdue, if (overdue) View.VISIBLE else View.GONE)
            row.setViewVisibility(R.id.row_due, if (overdue) View.GONE else View.VISIBLE)
            row.setOnClickPendingIntent(R.id.row, openApp(context, item.optString("id")))
            views.addView(R.id.widget_rows, row)
        }
        return views
    }

    private fun showEmpty(views: RemoteViews, text: String) {
        views.setTextViewText(R.id.widget_empty, text)
        views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
    }

    /** Opens the app, on [itemId] when given. */
    private fun openApp(context: Context, itemId: String?): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        if (itemId != null) intent.putExtra(MainActivity.EXTRA_OPEN_ITEM, itemId)
        return PendingIntent.getActivity(
            context,
            ("widget:" + (itemId ?: "")).hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
