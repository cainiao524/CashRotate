package app.cashrotate

import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import app.cashrotate.keystore.DatabaseKeyStore
import app.cashrotate.reminders.ReminderActionReceiver
import app.cashrotate.reminders.ReminderChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val background = Executors.newSingleThreadExecutor()
    private var remindersChannel: MethodChannel? = null
    private var pendingPermission: ((Boolean) -> Unit)? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        val keys = DatabaseKeyStore(applicationContext)

        MethodChannel(messenger, KEYSTORE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Keystore operations can block; keep them off the UI thread.
                    "databaseKey" -> background.execute {
                        try {
                            val key = keys.getOrCreate()
                            runOnUiThread { result.success(key) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("KEYSTORE", e.message, null) }
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        val reminders = MethodChannel(messenger, REMINDERS_CHANNEL)
        val handler = ReminderChannel(this, ::requestNotificationPermission)
        reminders.setMethodCallHandler { call, result ->
            when (call.method) {
                // The item a tapped notification is about, once.
                "takeOpenedItem" -> {
                    result.success(openedItem)
                    openedItem = null
                }
                else -> handler.onMethodCall(call, result)
            }
        }
        remindersChannel = reminders
        openedItem = intent?.getStringExtra(EXTRA_OPEN_ITEM)
        // "Paid" tapped while the app is open: let Dart apply it now.
        ReminderActionReceiver.onAction = {
            runOnUiThread { remindersChannel?.invokeMethod("eventsAvailable", null) }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val item = intent.getStringExtra(EXTRA_OPEN_ITEM) ?: return
        openedItem = item
        remindersChannel?.invokeMethod("itemOpened", null)
    }

    private fun requestNotificationPermission(onResult: (Boolean) -> Unit) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            onResult(true)
            return
        }
        pendingPermission = onResult
        requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), PERMISSION_REQUEST)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != PERMISSION_REQUEST) return
        pendingPermission?.invoke(grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED)
        pendingPermission = null
    }

    override fun onDestroy() {
        ReminderActionReceiver.onAction = null
        background.shutdown()
        super.onDestroy()
    }

    private var openedItem: String? = null

    companion object {
        const val EXTRA_OPEN_ITEM = "app.cashrotate.OPEN_ITEM"
        private const val KEYSTORE_CHANNEL = "app.cashrotate/keystore"
        private const val REMINDERS_CHANNEL = "app.cashrotate/reminders"
        private const val PERMISSION_REQUEST = 41
    }
}
