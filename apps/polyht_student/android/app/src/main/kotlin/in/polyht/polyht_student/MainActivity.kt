package `in`.polyht.polyht_student

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.view.WindowManager

class MainActivity : FlutterActivity() {
    private val channelName = "polyht/exam_security"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "enterExamMode" -> {
                    window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    try {
                        startLockTask()
                    } catch (_: Exception) {
                    }
                    result.success(null)
                }
                "exitExamMode" -> {
                    try {
                        stopLockTask()
                    } catch (_: Exception) {
                    }
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
