package app.cashrotate.reminders

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

/**
 * Hands planned reminders to AlarmManager as inexact, Doze-tolerant alarms
 * (setAndAllowWhileIdle). No exact alarms: CashRotate is not an alarm
 * clock, and Google Play only allows those permissions for one.
 */
object ReminderScheduler {
    /** Alarms kept armed at once; the daily check arms the next ones. */
    private const val MAX_ARMED = 64

    /** A reminder whose time passed unseen is still shown this late. */
    const val LATE_LIMIT_MS = 24 * 60 * 60 * 1000L

    /** Re-arms every alarm from the stored plan and shows any just missed. */
    @Synchronized
    fun rescheduleAll(context: Context) {
        val store = ReminderStore(context)
        val alarms = context.getSystemService(AlarmManager::class.java)
        val now = System.currentTimeMillis()
        val delivered = store.delivered

        // Missed while the phone was off or the app was stopped: show now if
        // still recent; the log records how late it was.
        for (r in store.reminders) {
            if (r.at <= now && r.at > now - LATE_LIMIT_MS && r.id !in delivered &&
                ReminderReceiver.canNotify(context)
            ) {
                ReminderNotifications.show(context, r)
            }
        }

        val upcoming = store.reminders
            .filter { it.at > now && it.id !in delivered }
            .sortedBy { it.at }
            .take(MAX_ARMED)
        val wanted = upcoming.map { it.id }.toSet()
        for (id in store.armed - wanted) {
            alarms.cancel(alarmIntent(context, id))
        }
        for (r in upcoming) {
            alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, r.at, alarmIntent(context, r.id))
        }
        store.armed = wanted

        // Forget deliveries that are no longer planned (keeps the set small).
        val planned = store.reminders.map { it.id }.toSet()
        store.delivered = store.delivered.intersect(planned)
        ensureDailyCheck(context)
    }

    /** Shows [reminder] again after [delayMs] ("remind me later"). */
    fun snooze(context: Context, reminder: Reminder, delayMs: Long) {
        val store = ReminderStore(context)
        val later = reminder.copy(
            id = "${reminder.id}#${System.currentTimeMillis()}",
            at = System.currentTimeMillis() + delayMs,
        )
        store.reminders = store.reminders + later
        rescheduleAll(context)
    }

    fun ensureDailyCheck(context: Context) {
        val request = PeriodicWorkRequestBuilder<DailyCheckWorker>(1, TimeUnit.DAYS).build()
        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            DailyCheckWorker.NAME,
            ExistingPeriodicWorkPolicy.KEEP,
            request,
        )
    }

    private fun alarmIntent(context: Context, id: String): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            id.hashCode(),
            Intent(context, ReminderReceiver::class.java)
                .setAction(ReminderReceiver.ACTION_SHOW)
                .putExtra(ReminderReceiver.EXTRA_ID, id),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
}
