package app.cashrotate.reminders

import android.app.Activity
import android.app.NotificationManager
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

/**
 * `app.cashrotate/reminders`: Dart hands over the plan and reads back what
 * happened. Dart owns all wording (localised); the native side only stores,
 * schedules and shows.
 */
class ReminderChannel(
    private val activity: Activity,
    private val requestPermission: (onResult: (Boolean) -> Unit) -> Unit,
) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val context = activity.applicationContext
        val store = ReminderStore(context)
        when (call.method) {
            // {reminders: [{id, at, title, body, itemId, occurrenceId, kind}],
            //  labels: {paid, snooze, channelName, channelDescription}}
            // Pictures for notification large icons: one PNG file per item.
            "setBadgeImages" -> {
                val images = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
                val dir = ReminderNotifications.badgeDir(context)
                dir.listFiles()?.forEach { it.delete() }
                for ((id, bytes) in images) {
                    if (id is String && bytes is ByteArray) {
                        java.io.File(dir, ReminderNotifications.badgeFileName(id)).writeBytes(bytes)
                    }
                }
                app.cashrotate.widgets.WidgetRenderer.refreshAll(context)
                result.success(null)
            }
            "setReminders" -> {
                val args = JSONObject(call.arguments as String)
                val list = args.getJSONArray("reminders")
                val labels = args.getJSONObject("labels")
                store.labels = labels.keys().asSequence().associateWith { labels.getString(it) }
                val now = System.currentTimeMillis()
                val before = store.reminders
                val known = before.map { it.id }.toSet()
                // Snoozed copies live only on this side: keep them.
                val snoozed = before.filter { '#' in it.id && it.at > now }
                val planned = (0 until list.length()).map {
                    Reminder.fromJson(list.getJSONObject(it))
                }
                // A reminder that is new and already past (an item added in
                // the afternoon with a reminder that morning) is not shown
                // late; only ones planned earlier and missed are.
                store.delivered = store.delivered +
                    planned.filter { it.at <= now && it.id !in known }.map { it.id }
                store.reminders = planned + snoozed
                ReminderNotifications.ensureChannel(context)
                ReminderScheduler.rescheduleAll(context)
                result.success(null)
            }
            "takeEvents" -> result.success(JSONArray(store.takeEvents()).toString())
            "notificationsEnabled" -> result.success(
                ReminderReceiver.canNotify(context) &&
                    context.getSystemService(NotificationManager::class.java).areNotificationsEnabled(),
            )
            "requestPermission" -> requestPermission { granted -> result.success(granted) }
            "sendTest" -> {
                val args = JSONObject(call.arguments as String)
                ReminderNotifications.show(
                    context,
                    Reminder(
                        id = "test:${System.currentTimeMillis()}",
                        at = System.currentTimeMillis(),
                        title = args.getString("title"),
                        body = args.getString("body"),
                        itemId = "",
                        occurrenceId = null,
                        kind = "test",
                    ),
                )
                result.success(ReminderReceiver.canNotify(context))
            }
            "manufacturer" -> result.success(Build.MANUFACTURER.lowercase())
            "openBatterySettings" -> result.success(
                open(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)) ||
                    openAppDetails(),
            )
            "openNotificationSettings" -> result.success(
                open(
                    Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                        .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName),
                ) || openAppDetails(),
            )
            "openAppSettings" -> result.success(openAppDetails())
            else -> result.notImplemented()
        }
    }

    private fun openAppDetails(): Boolean = open(
        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            .setData(Uri.fromParts("package", activity.packageName, null)),
    )

    private fun open(intent: Intent): Boolean = try {
        activity.startActivity(intent)
        true
    } catch (_: ActivityNotFoundException) {
        false
    }
}
