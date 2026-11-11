package app.cashrotate.reminders

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Typeface
import android.graphics.drawable.Icon
import android.net.Uri
import app.cashrotate.MainActivity
import app.cashrotate.R
import org.json.JSONObject

/**
 * Posts reminder notifications with "Paid" and "Later" actions, and "Go
 * cancel" on trials and renewals. The large icon is the item's badge: its
 * chosen line icon or initial, as on the home tile; the small icon stays
 * monochrome.
 */
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
        reminder.badge?.let { badge ->
            runCatching { badgeBitmap(context, badge, reminder.itemId) }.getOrNull()?.let {
                builder.setLargeIcon(Icon.createWithBitmap(it))
            }
        }
        // A paired watch mirrors the notification (it is not local-only) and
        // shows these two actions; both run on the phone. "Go cancel" opens
        // a web page, so it stays on the phone.
        val watch = Notification.WearableExtender()
        if (reminder.occurrenceId != null) {
            val paid = Notification.Action.Builder(
                null,
                labels["paid"] ?: "Paid",
                actionIntent(context, reminder, ReminderActionReceiver.ACTION_PAID),
            ).build()
            builder.addAction(paid)
            watch.addAction(paid)
        }
        val snooze = Notification.Action.Builder(
            null,
            labels["snooze"] ?: "Later",
            actionIntent(context, reminder, ReminderActionReceiver.ACTION_SNOOZE),
        ).build()
        builder.addAction(snooze)
        watch.addAction(snooze)
        builder.extend(watch)
        val cancelUri = reminder.cancelUrl?.let(Uri::parse)
        if (cancelUri != null && (cancelUri.scheme == "https" || cancelUri.scheme == "http")) {
            builder.addAction(
                Notification.Action.Builder(
                    null,
                    labels["goCancel"] ?: "Go cancel",
                    PendingIntent.getActivity(
                        context,
                        (reminder.id + "cancel").hashCode(),
                        Intent(Intent.ACTION_VIEW, cancelUri)
                            .addCategory(Intent.CATEGORY_BROWSABLE)
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                    ),
                ).build(),
            )
        }
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

    private const val BADGE_SIZE = 128

    /** The Material Icons font Flutter bundles (holds the tile icons). */
    private var iconFont: Typeface? = null

    private fun iconTypeface(context: Context): Typeface? = iconFont ?: runCatching {
        Typeface.createFromAsset(context.assets, "flutter_assets/fonts/MaterialIcons-Regular.otf")
    }.getOrNull()?.also { iconFont = it }

    /** A round badge with the item's line icon, or else its initial. */
    /** Where the user's pictures for large icons are kept. */
    fun badgeDir(context: Context): java.io.File =
        java.io.File(context.filesDir, "badges").apply { mkdirs() }

    /** A safe file name for an item id. */
    fun badgeFileName(itemId: String): String =
        itemId.replace(Regex("[^A-Za-z0-9_-]"), "_") + ".png"

    /** The user's picture for [itemId], cut to a circle, if there is one. */
    fun pictureBitmap(context: Context, itemId: String): Bitmap? {
        val file = java.io.File(badgeDir(context), badgeFileName(itemId))
        if (!file.exists()) return null
        val picture = android.graphics.BitmapFactory.decodeFile(file.path) ?: return null
        val bitmap = Bitmap.createBitmap(BADGE_SIZE, BADGE_SIZE, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        canvas.drawCircle(BADGE_SIZE / 2f, BADGE_SIZE / 2f, BADGE_SIZE / 2f, paint)
        paint.xfermode = android.graphics.PorterDuffXfermode(android.graphics.PorterDuff.Mode.SRC_IN)
        canvas.drawBitmap(
            picture,
            null,
            android.graphics.Rect(0, 0, BADGE_SIZE, BADGE_SIZE),
            paint,
        )
        return bitmap
    }

    /** The user's picture, else a round badge with the line icon or initial. */
    private fun badgeBitmap(context: Context, badge: JSONObject, itemId: String): Bitmap {
        pictureBitmap(context, itemId)?.let { return it }
        val bitmap = Bitmap.createBitmap(BADGE_SIZE, BADGE_SIZE, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val half = BADGE_SIZE / 2f
        val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = badge.getInt("background") }
        canvas.drawCircle(half, half, half, fill)

        val codePoint = if (badge.isNull("icon")) null else badge.getInt("icon")
        val font = codePoint?.let { iconTypeface(context) }
        val glyph = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = badge.getInt("foreground")
            textAlign = Paint.Align.CENTER
        }
        val text = if (codePoint != null && font != null) {
            glyph.typeface = font
            glyph.textSize = BADGE_SIZE * 0.56f
            String(Character.toChars(codePoint))
        } else {
            glyph.typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            glyph.textSize = BADGE_SIZE * 0.46f
            badge.optString("letter", "?")
        }
        // Centre the glyph box vertically.
        val metrics = glyph.fontMetrics
        canvas.drawText(text, half, half - (metrics.ascent + metrics.descent) / 2, glyph)
        return bitmap
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
