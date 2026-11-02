package app.cashrotate.reminders

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/** One reminder as planned by Dart: when to show it and what it says. */
data class Reminder(
    val id: String,
    val at: Long,
    val title: String,
    val body: String,
    val itemId: String,
    val occurrenceId: String?,
    val kind: String,
    /** Large icon: {letter, background, foreground, icon?}. */
    val badge: JSONObject? = null,
    /** "Go cancel" opens this page (trials and renewals). */
    val cancelUrl: String? = null,
) {
    fun toJson(): JSONObject = JSONObject()
        .put("id", id)
        .put("at", at)
        .put("title", title)
        .put("body", body)
        .put("itemId", itemId)
        .put("occurrenceId", occurrenceId ?: JSONObject.NULL)
        .put("kind", kind)
        .put("badge", badge ?: JSONObject.NULL)
        .put("cancelUrl", cancelUrl ?: JSONObject.NULL)

    companion object {
        fun fromJson(o: JSONObject) = Reminder(
            id = o.getString("id"),
            at = o.getLong("at"),
            title = o.getString("title"),
            body = o.getString("body"),
            itemId = o.getString("itemId"),
            occurrenceId = if (o.isNull("occurrenceId")) null else o.getString("occurrenceId"),
            kind = o.optString("kind", "charge"),
            badge = o.optJSONObject("badge"),
            cancelUrl = if (o.isNull("cancelUrl")) null else o.optString("cancelUrl"),
        )
    }
}

/**
 * Plain-text state the native side keeps between app launches: the planned
 * reminders, which were delivered, what the user did from a notification,
 * and the action labels in the user's language. Never backed up (backup is
 * off for the whole app). Reminder text names items and amounts, nothing
 * more.
 */
class ReminderStore(context: Context) {
    private val prefs = context.applicationContext
        .getSharedPreferences("reminders", Context.MODE_PRIVATE)

    var reminders: List<Reminder>
        get() = readArray(KEY_REMINDERS).map { Reminder.fromJson(it) }
        set(value) = writeArray(KEY_REMINDERS, value.map { it.toJson() })

    var labels: Map<String, String>
        get() {
            val o = JSONObject(prefs.getString(KEY_LABELS, "{}")!!)
            return o.keys().asSequence().associateWith { o.getString(it) }
        }
        set(value) = prefs.edit().putString(KEY_LABELS, JSONObject(value).toString()).apply()

    /** Ids handed to AlarmManager, so stale ones can be cancelled. */
    var armed: Set<String>
        get() = prefs.getStringSet(KEY_ARMED, emptySet())!!.toSet()
        set(value) = prefs.edit().putStringSet(KEY_ARMED, value).apply()

    /** Ids already shown, so a late re-check never shows one twice. */
    var delivered: Set<String>
        get() = prefs.getStringSet(KEY_DELIVERED, emptySet())!!.toSet()
        set(value) = prefs.edit().putStringSet(KEY_DELIVERED, value).apply()

    /** Delivery and action events waiting for Dart to copy into ReminderLog. */
    @Synchronized
    fun addEvent(event: JSONObject) {
        val events = readArray(KEY_EVENTS).toMutableList()
        events.add(event)
        // Bounded: if the app is not opened for months, keep the newest.
        writeArray(KEY_EVENTS, events.takeLast(MAX_EVENTS))
    }

    @Synchronized
    fun takeEvents(): List<JSONObject> {
        val events = readArray(KEY_EVENTS)
        writeArray(KEY_EVENTS, emptyList())
        return events
    }

    private fun readArray(key: String): List<JSONObject> {
        val array = JSONArray(prefs.getString(key, "[]"))
        return (0 until array.length()).map { array.getJSONObject(it) }
    }

    private fun writeArray(key: String, items: List<JSONObject>) {
        prefs.edit().putString(key, JSONArray(items).toString()).apply()
    }

    private companion object {
        const val KEY_REMINDERS = "reminders"
        const val KEY_LABELS = "labels"
        const val KEY_ARMED = "armed"
        const val KEY_DELIVERED = "delivered"
        const val KEY_EVENTS = "events"
        const val MAX_EVENTS = 500
    }
}
