package app.cashrotate

import app.cashrotate.keystore.DatabaseKeyStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val background = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val keys = DatabaseKeyStore(applicationContext)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, KEYSTORE_CHANNEL)
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
    }

    override fun onDestroy() {
        background.shutdown()
        super.onDestroy()
    }

    private companion object {
        const val KEYSTORE_CHANNEL = "app.cashrotate/keystore"
    }
}
