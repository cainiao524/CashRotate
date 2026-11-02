package app.cashrotate.notices

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

/**
 * `app.cashrotate/notices`: notification access, the apps to read, and the
 * queued notices. Parsing and matching happen in Dart.
 */
class NoticeChannel(private val activity: Activity) : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val store = NoticeStore(activity)
        when (call.method) {
            "accessGranted" -> result.success(ChargeListenerService.accessGranted(activity))
            "openAccessSettings" -> result.success(
                try {
                    activity.startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                    true
                } catch (_: ActivityNotFoundException) {
                    false
                },
            )
            "setConfig" -> {
                store.enabled = call.argument<Boolean>("enabled") ?: false
                store.allowed = call.argument<List<String>>("packages")?.toSet() ?: emptySet()
                result.success(null)
            }
            "takeNotices" -> result.success(JSONArray(store.take()).toString())
            // Launchable apps (bank and wallet apps are), with how often each
            // posted something that looked like a charge.
            "apps" -> {
                val pm = activity.packageManager
                val counts = store.candidates()
                val launcher = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
                val apps = pm.queryIntentActivities(launcher, PackageManager.MATCH_ALL)
                    .map { it.activityInfo.packageName }
                    .distinct()
                    .filter { it != activity.packageName }
                    .map { pkg ->
                        JSONObject()
                            .put("package", pkg)
                            .put(
                                "label",
                                try {
                                    pm.getApplicationLabel(pm.getApplicationInfo(pkg, 0)).toString()
                                } catch (_: PackageManager.NameNotFoundException) {
                                    pkg
                                },
                            )
                            .put("charges", counts[pkg] ?: 0)
                    }
                result.success(JSONArray(apps).toString())
            }
            else -> result.notImplemented()
        }
    }
}
