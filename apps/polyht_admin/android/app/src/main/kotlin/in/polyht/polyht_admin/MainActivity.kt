package `in`.polyht.polyht_admin

import android.content.res.Configuration
import android.os.Build
import android.view.View
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "polyht/exam_security"
    private var channel: MethodChannel? = null
    private var examMode = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "enterExamMode" -> {
                    examMode = true
                    applyExamMode()
                    startPinnedMode()
                    result.success(null)
                }
                "reassertExamMode" -> {
                    if (examMode) applyExamMode()
                    result.success(null)
                }
                "exitExamMode" -> {
                    examMode = false
                    clearExamMode()
                    stopPinnedMode()
                    result.success(null)
                }
                "isInMultiWindowMode" -> result.success(isInMultiWindowOrPip())
                else -> result.notImplemented()
            }
        }
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (!examMode) return
        applyExamMode()
        channel?.invokeMethod("windowFocusChanged", hasFocus)
    }

    override fun onMultiWindowModeChanged(isInMultiWindowMode: Boolean) {
        super.onMultiWindowModeChanged(isInMultiWindowMode)
        if (examMode) {
            channel?.invokeMethod("multiWindowModeChanged", isInMultiWindowMode)
        }
    }

    override fun onMultiWindowModeChanged(isInMultiWindowMode: Boolean, newConfig: Configuration) {
        super.onMultiWindowModeChanged(isInMultiWindowMode, newConfig)
        if (examMode) {
            channel?.invokeMethod("multiWindowModeChanged", isInMultiWindowMode)
        }
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode)
        if (examMode) {
            channel?.invokeMethod("pictureInPictureModeChanged", isInPictureInPictureMode)
        }
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: Configuration) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        if (examMode) {
            channel?.invokeMethod("pictureInPictureModeChanged", isInPictureInPictureMode)
        }
    }

    @Suppress("DEPRECATION")
    private fun applyExamMode() {
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        window.decorView.systemUiVisibility =
            View.SYSTEM_UI_FLAG_FULLSCREEN or
                View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE
    }

    @Suppress("DEPRECATION")
    private fun clearExamMode() {
        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_LAYOUT_STABLE
    }

    private fun startPinnedMode() {
        try {
            startLockTask()
        } catch (_: Exception) {
        }
    }

    private fun stopPinnedMode() {
        try {
            stopLockTask()
        } catch (_: Exception) {
        }
    }

    private fun isInMultiWindowOrPip(): Boolean {
        val multiWindow = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) isInMultiWindowMode else false
        val pip = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) isInPictureInPictureMode else false
        return multiWindow || pip
    }
}
