package app.cashrotate.notices

import android.app.Notification
import android.content.ComponentName
import android.content.Context
import android.provider.Settings
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import org.json.JSONArray
import org.json.JSONObject

/**
 * What the listener keeps between app launches (plain prefs, never backed
 * up): whether detection is on, which apps the user picked, notices from
 * those apps waiting for Dart to parse, and, for other apps, only a count
 * of notifications that looked like charges (no text), to suggest them.
 */
class NoticeStore(context: Context) {
    private val prefs = context.applicationContext
        .getSharedPreferences("notices", Context.MODE_PRIVATE)

    var enabled: Boolean
        get() = prefs.getBoolean(KEY_ENABLED, false)
        set(v) = prefs.edit().putBoolean(KEY_ENABLED, v).apply()

    var allowed: Set<String>
        get() = prefs.getStringSet(KEY_ALLOWED, emptySet())!!.toSet()
        set(v) = prefs.edit().putStringSet(KEY_ALLOWED, v).apply()

    @Synchronized
    fun add(pkg: String, title: String, text: String, postedAt: Long) {
        val queue = read(KEY_QUEUE)
        queue.add(
            JSONObject()
                .put("package", pkg)
                .put("title", title)
                .put("text", text)
                .put("postedAt", postedAt),
        )
        write(KEY_QUEUE, queue.takeLast(MAX_QUEUE))
    }

    @Synchronized
    fun take(): List<JSONObject> {
        val queue = read(KEY_QUEUE)
        write(KEY_QUEUE, emptyList())
        return queue
    }

    @Synchronized
    fun countCandidate(pkg: String) {
        val o = JSONObject(prefs.getString(KEY_CANDIDATES, "{}")!!)
        o.put(pkg, o.optInt(pkg) + 1)
        prefs.edit().putString(KEY_CANDIDATES, o.toString()).apply()
    }

    fun candidates(): Map<String, Int> {
        val o = JSONObject(prefs.getString(KEY_CANDIDATES, "{}")!!)
        return o.keys().asSequence().associateWith { o.getInt(it) }
    }

    private fun read(key: String): MutableList<JSONObject> {
        val a = JSONArray(prefs.getString(key, "[]"))
        return (0 until a.length()).map { a.getJSONObject(it) }.toMutableList()
    }

    private fun write(key: String, items: List<JSONObject>) {
        prefs.edit().putString(key, JSONArray(items).toString()).apply()
    }

    private companion object {
        const val KEY_ENABLED = "enabled"
        const val KEY_ALLOWED = "allowed"
        const val KEY_QUEUE = "queue"
        const val KEY_CANDIDATES = "candidates"
        const val MAX_QUEUE = 200
    }
}

/**
 * Reads bank and payment app notifications for automatic charge detection
 * (ADR 0010). Only apps the user picked are read; their text goes to a
 * local queue that the app parses on the phone. Nothing leaves the device.
 */
class ChargeListenerService : NotificationListenerService() {
    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val store = NoticeStore(this)
        if (!store.enabled || sbn.packageName == packageName) return
        val extras = sbn.notification.extras
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString().orEmpty()
        val text = (
            extras.getCharSequence(Notification.EXTRA_BIG_TEXT)
                ?: extras.getCharSequence(Notification.EXTRA_TEXT)
            )?.toString().orEmpty()
        if (sbn.packageName in store.allowed) {
            store.add(sbn.packageName, title, text, sbn.postTime)
            onNotice?.invoke()
        } else if (MONEY.containsMatchIn("$title $text")) {
            store.countCandidate(sbn.packageName)
        }
    }

    companion object {
        /** Set while the app is open, so new notices are parsed right away. */
        @Volatile
        var onNotice: (() -> Unit)? = null

        /** A currency next to digits: enough to suggest an app, not to read it. */
        private val MONEY = Regex(
            """(NT\$|US\$|HK\$|\$|¥|€|元|NTD|TWD|USD|HKD)\s?\d|\d\s?(元|NTD|TWD)""",
        )

        fun accessGranted(context: Context): Boolean {
            val flat = Settings.Secure.getString(
                context.contentResolver,
                "enabled_notification_listeners",
            ) ?: return false
            val me = ComponentName(context, ChargeListenerService::class.java)
            return flat.split(':').any { ComponentName.unflattenFromString(it) == me }
        }
    }
}
