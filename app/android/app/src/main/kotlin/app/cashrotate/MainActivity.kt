package app.cashrotate

import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.drawable.Icon
import android.os.Build
import app.cashrotate.keystore.DatabaseKeyStore
import app.cashrotate.notices.ChargeListenerService
import app.cashrotate.notices.NoticeChannel
import app.cashrotate.reminders.ReminderActionReceiver
import app.cashrotate.reminders.ReminderChannel
import app.cashrotate.widgets.WidgetRenderer
import app.cashrotate.widgets.WidgetStore
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

// FragmentActivity: local_auth (biometric unlock) needs it.
class MainActivity : FlutterFragmentActivity() {
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

        val notices = MethodChannel(messenger, NOTICES_CHANNEL)
        val noticeHandler = NoticeChannel(this)
        notices.setMethodCallHandler { call, result ->
            when (call.method) {
                // Text shared into the app (a bank SMS), once.
                "takeSharedText" -> {
                    result.success(sharedText)
                    sharedText = null
                }
                else -> noticeHandler.onMethodCall(call, result)
            }
        }
        noticesChannel = notices
        sharedText = sharedTextOf(intent)
        ChargeListenerService.onNotice = {
            runOnUiThread { noticesChannel?.invokeMethod("noticesAvailable", null) }
        }

        // App lock on: keep the content out of the recent-apps list. Android
        // 13+ can blank just the thumbnail; older versions need FLAG_SECURE,
        // which also blocks screenshots.
        MethodChannel(messenger, PRIVACY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setHiddenInRecents" -> {
                    val hidden = call.argument<Boolean>("hidden") == true
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        setRecentsScreenshotEnabled(!hidden)
                    } else if (hidden) {
                        window.addFlags(android.view.WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(android.view.WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Launcher shortcuts, labelled by the app in its current language.
        val shortcuts = MethodChannel(messenger, SHORTCUTS_CHANNEL)
        shortcuts.setMethodCallHandler { call, result ->
            when (call.method) {
                "set" -> {
                    val list = call.arguments as List<*>
                    val manager = getSystemService(ShortcutManager::class.java)
                    manager.dynamicShortcuts = list.mapNotNull { entry ->
                        val map = entry as? Map<*, *> ?: return@mapNotNull null
                        val id = map["id"] as? String ?: return@mapNotNull null
                        val label = map["label"] as? String ?: return@mapNotNull null
                        ShortcutInfo.Builder(this, id)
                            .setShortLabel(label)
                            .setLongLabel(label)
                            .setIcon(
                                Icon.createWithResource(
                                    this,
                                    if (id == "pay") R.drawable.ic_shortcut_pay else R.drawable.ic_shortcut_add,
                                ),
                            )
                            .setIntent(
                                Intent(this, MainActivity::class.java)
                                    .setAction(Intent.ACTION_VIEW)
                                    .putExtra(EXTRA_SHORTCUT, id),
                            )
                            .build()
                    }
                    result.success(null)
                }
                "takeOpened" -> {
                    result.success(openedShortcut)
                    openedShortcut = null
                }
                else -> result.notImplemented()
            }
        }
        shortcutsChannel = shortcuts
        openedShortcut = intent?.getStringExtra(EXTRA_SHORTCUT)

        // Home-screen widgets: the app hands over what they show.
        MethodChannel(messenger, WIDGETS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "update" -> {
                    WidgetStore.save(this, call.arguments as String)
                    WidgetRenderer.refreshAll(this)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // "Go cancel": the service's cancel page in the browser. Web links only.
        MethodChannel(messenger, LINKS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openUrl" -> {
                    val uri = android.net.Uri.parse(call.argument<String>("url").orEmpty())
                    if (uri.scheme != "https" && uri.scheme != "http") {
                        result.success(false)
                    } else {
                        try {
                            startActivity(
                                Intent(Intent.ACTION_VIEW, uri)
                                    .addCategory(Intent.CATEGORY_BROWSABLE),
                            )
                            result.success(true)
                        } catch (e: android.content.ActivityNotFoundException) {
                            result.success(false)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Exported backups: the system picker chooses where (Downloads, a
        // cloud drive …); no storage permission is needed.
        MethodChannel(messenger, FILES_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveFile" -> {
                    pendingSave = call.argument<ByteArray>("bytes")
                    pendingFileResult = result
                    startActivityForResult(
                        Intent(Intent.ACTION_CREATE_DOCUMENT)
                            .addCategory(Intent.CATEGORY_OPENABLE)
                            .setType(
                                if (call.argument<String>("name").orEmpty().endsWith(".csv")) {
                                    "text/csv"
                                } else {
                                    "application/octet-stream"
                                },
                            )
                            .putExtra(Intent.EXTRA_TITLE, call.argument<String>("name")),
                        SAVE_REQUEST,
                    )
                }
                "openFile" -> {
                    pendingFileResult = result
                    startActivityForResult(
                        Intent(Intent.ACTION_OPEN_DOCUMENT)
                            .addCategory(Intent.CATEGORY_OPENABLE)
                            .setType(call.argument<String>("type") ?: "*/*"),
                        OPEN_REQUEST,
                    )
                }
                else -> result.notImplemented()
            }
        }
        openedItem = intent?.getStringExtra(EXTRA_OPEN_ITEM)
        // "Paid" tapped while the app is open: let Dart apply it now.
        ReminderActionReceiver.onAction = {
            runOnUiThread { remindersChannel?.invokeMethod("eventsAvailable", null) }
        }
    }

    private var pendingSave: ByteArray? = null
    private var pendingFileResult: MethodChannel.Result? = null

    @Deprecated("Activity result API; fine for two one-off pickers")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != SAVE_REQUEST && requestCode != OPEN_REQUEST) return
        val result = pendingFileResult ?: return
        pendingFileResult = null
        val uri = data?.data
        if (resultCode != RESULT_OK || uri == null) {
            result.success(null)
            return
        }
        background.execute {
            try {
                if (requestCode == SAVE_REQUEST) {
                    contentResolver.openOutputStream(uri, "wt")!!.use { it.write(pendingSave) }
                    pendingSave = null
                    runOnUiThread { result.success(true) }
                } else {
                    val bytes = contentResolver.openInputStream(uri)!!.use { it.readBytes() }
                    runOnUiThread { result.success(bytes) }
                }
            } catch (e: Exception) {
                runOnUiThread { result.error("FILE", e.message, null) }
            }
        }
    }

    private var noticesChannel: MethodChannel? = null
    private var sharedText: String? = null

    private fun sharedTextOf(intent: Intent?): String? =
        if (intent?.action == Intent.ACTION_SEND && intent.type == "text/plain") {
            intent.getStringExtra(Intent.EXTRA_TEXT)
        } else {
            null
        }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        sharedTextOf(intent)?.let {
            sharedText = it
            noticesChannel?.invokeMethod("noticesAvailable", null)
        }
        intent.getStringExtra(EXTRA_SHORTCUT)?.let {
            openedShortcut = it
            shortcutsChannel?.invokeMethod("shortcutOpened", null)
        }
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
        ChargeListenerService.onNotice = null
        background.shutdown()
        super.onDestroy()
    }

    private var openedItem: String? = null
    private var openedShortcut: String? = null
    private var shortcutsChannel: MethodChannel? = null

    companion object {
        const val EXTRA_OPEN_ITEM = "app.cashrotate.OPEN_ITEM"
        const val EXTRA_SHORTCUT = "app.cashrotate.SHORTCUT"
        private const val SHORTCUTS_CHANNEL = "app.cashrotate/shortcuts"
        private const val PRIVACY_CHANNEL = "app.cashrotate/privacy"
        private const val KEYSTORE_CHANNEL = "app.cashrotate/keystore"
        private const val REMINDERS_CHANNEL = "app.cashrotate/reminders"
        private const val PERMISSION_REQUEST = 41
        private const val FILES_CHANNEL = "app.cashrotate/files"
        private const val LINKS_CHANNEL = "app.cashrotate/links"
        private const val WIDGETS_CHANNEL = "app.cashrotate/widgets"
        private const val NOTICES_CHANNEL = "app.cashrotate/notices"
        private const val SAVE_REQUEST = 42
        private const val OPEN_REQUEST = 43
    }
}
