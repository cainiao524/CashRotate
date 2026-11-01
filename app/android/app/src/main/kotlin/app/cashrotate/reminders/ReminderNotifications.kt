package app.cashrotate.reminders

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import app.cashrotate.MainActivity
import app.cashrotate.R
import org.json.JSONObject

/** Posts reminder notifications with "Paid" and "Later" actions. */
object ReminderNotifications {
    const val CHANNEL_ID = "reminders"

    fun ensureChannel(context: Context) {
        val labels = ReminderStore(context).labels
        val manager = context.getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(
            CHANNEL_ID,
            labels["channelName"] ?: "Reminders",
            NotificationManager.IMPORTANCE_DEFAULT,
        )
        channel.description = labels["channelDescription"]
        manager.createNotificationChannel(channel)
    }

    /** Shows [reminder] and records the delivery time. */
    fun show(context: Context, reminder: Reminder) {
        val store = ReminderStore(context)
        val labels = store.labels
        ensureChannel(context)
        val tag = reminder.id
        val open = PendingIntent.getActivity(
            context,
            tag.hashCode(),
            Intent(context, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                .putExtra(MainActivity.EXTRA_OPEN_ITEM, reminder.itemId),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_reminder)
            .setContentTitle(reminder.title)
            .setContentText(reminder.body)
            .setStyle(Notification.BigTextStyle().bigText(reminder.body))
            .setContentIntent(open)
            .setAutoCancel(true)
            .setCategory(Notification.CATEGORY_REMINDER)
        if (reminder.occurrenceId != null) {
            builder.addAction(
                Notification.Action.Builder(
                    null,
                    labels["paid"] ?: "Paid",
                    actionIntent(context, reminder, ReminderActionReceiver.ACTION_PAID),
                ).build(),
            )
        }
        builder.addAction(
            Notification.Action.Builder(
                null,
                labels["snooze"] ?: "Later",
                actionIntent(context, reminder, ReminderActionReceiver.ACTION_SNOOZE),
            ).build(),
        )
        context.getSystemService(NotificationManager::class.java)
            .notify(tag, NOTIFICATION_ID, builder.build())

        store.delivered = store.delivered + reminder.id
        store.addEvent(
            JSONObject()
                .put("type", "delivered")
                .put("id", reminder.id)
                .put("itemId", reminder.itemId)
                .put("occurrenceId", reminder.occurrenceId ?: JSONObject.NULL)
                .put("kind", reminder.kind)
                .put("scheduledAt", reminder.at)
                .put("at", System.currentTimeMillis()),
        )
    }

    fun cancel(context: Context, reminderId: String) {
        context.getSystemService(NotificationManager::class.java).cancel(reminderId, NOTIFICATION_ID)
    }

    /** One id for all; the reminder id is the tag. */
    const val NOTIFICATION_ID = 1

    private fun actionIntent(context: Context, reminder: Reminder, action: String): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            (reminder.id + action).hashCode(),
            Intent(context, ReminderActionReceiver::class.java)
                .setAction(action)
                .putExtra(ReminderReceiver.EXTRA_ID, reminder.id),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
}
