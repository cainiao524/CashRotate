package app.cashrotate

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.plugin.common.EventChannel

/**
 * Gravity in the screen's plane, for the pearl sheen on the home total card:
 * [x, y] from -1 to 1, about 30 times a second. Runs only while the app
 * listens (the home page is showing and motion is allowed).
 */
class TiltStream(context: Context) : EventChannel.StreamHandler, SensorEventListener {
    private val sensors = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val sensor: Sensor? =
        sensors.getDefaultSensor(Sensor.TYPE_GRAVITY)
            ?: sensors.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    private var sink: EventChannel.EventSink? = null
    private var lastSent = 0L

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        val s = sensor ?: return
        sink = events
        sensors.registerListener(this, s, SensorManager.SENSOR_DELAY_UI)
    }

    override fun onCancel(arguments: Any?) {
        sensors.unregisterListener(this)
        sink = null
    }

    override fun onSensorChanged(event: SensorEvent) {
        val now = System.currentTimeMillis()
        if (now - lastSent < 33) return
        lastSent = now
        val g = SensorManager.GRAVITY_EARTH
        // Screen x to the right, y up; the sheen moves the way the light would.
        val x = (event.values[0] / g).coerceIn(-1f, 1f)
        val y = (event.values[1] / g).coerceIn(-1f, 1f)
        sink?.success(listOf(x.toDouble(), y.toDouble()))
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
}
