package app.cashrotate.reminders

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.work.Worker
import androidx.work.WorkerParameters
import org.json.JSONObject

/** An alarm went off: show its reminder. */
class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_SHOW) return
        val id = intent.getStringExtra(EXTRA_ID) ?: return
        val store = ReminderStore(context)
        if (id in store.delivered) return
        val reminder = store.reminders.firstOrNull { it.id == id } ?: return
        if (canNotify(context)) ReminderNotifications.show(context, reminder)
    }

    companion object {
        const val ACTION_SHOW = "app.cashrotate.reminders.SHOW"
        const val EXTRA_ID = "id"

        fun canNotify(context: Context): Boolean =
            Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
                context.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) ==
                PackageManager.PERMISSION_GRANTED
    }
}

/**
 * "Paid" and "Later" on a notification. Later is handled here; Paid is
 * queued and applied to the database by Dart the next time the app runs
 * (immediately, if it is open).
 */
class ReminderActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getStringExtra(ReminderReceiver.EXTRA_ID) ?: return
        val store = ReminderStore(context)
        val reminder = store.reminders.firstOrNull { it.id == id } ?: return
        ReminderNotifications.cancel(context, id)
        val action = when (intent.action) {
            ACTION_PAID -> "paid"
            ACTION_SNOOZE -> {
                ReminderScheduler.snooze(context, reminder, SNOOZE_MS)
                "snoozed"
            }
            else -> return
        }
        store.addEvent(
            JSONObject()
                .put("type", action)
                .put("id", reminder.id)
                .put("itemId", reminder.itemId)
                .put("occurrenceId", reminder.occurrenceId ?: JSONObject.NULL)
                .put("kind", reminder.kind)
                .put("scheduledAt", reminder.at)
                .put("at", System.currentTimeMillis()),
        )
        onAction?.invoke()
    }

    companion object {
        const val ACTION_PAID = "app.cashrotate.reminders.PAID"
        const val ACTION_SNOOZE = "app.cashrotate.reminders.SNOOZE"

        /** "Later" shows the reminder again a day later. */
        const val SNOOZE_MS = 24 * 60 * 60 * 1000L

        /** Set while the app is open, so Dart applies "Paid" right away. */
        @Volatile
        var onAction: (() -> Unit)? = null
    }
}

/** After a reboot or an app update, alarms are gone: arm them again. */
class RescheduleReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIME_CHANGED,
            -> ReminderScheduler.rescheduleAll(context)
        }
    }
}

/**
 * Daily safety net: re-arms alarms (some phones drop them) and shows any
 * reminder that was missed in the last day.
 */
class DailyCheckWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    override fun doWork(): Result {
        ReminderScheduler.rescheduleAll(applicationContext)
        return Result.success()
    }

    companion object {
        const val NAME = "reminders-daily-check"
    }
}
