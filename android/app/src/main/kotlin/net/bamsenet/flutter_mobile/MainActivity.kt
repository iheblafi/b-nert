package net.bamsenet.flutter_mobile

import android.app.Activity
import android.app.KeyguardManager
import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FragmentActivity is required by local_auth (biometric prompt).
class MainActivity : FlutterFragmentActivity() {
    private var pendingConfirm: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Fallback for phones where the biometric prompt offers no PIN
        // (some Xiaomi builds report "device credential not supported"
        // although a PIN is set): Android's own "confirm your screen lock"
        // screen, which every phone with a PIN, pattern or password has.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "confirm") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val keyguard = getSystemService(KeyguardManager::class.java)
                if (keyguard == null || !keyguard.isDeviceSecure) {
                    result.success(false)
                    return@setMethodCallHandler
                }
                if (pendingConfirm != null) {
                    result.error("busy", "A confirmation is already open", null)
                    return@setMethodCallHandler
                }
                @Suppress("DEPRECATION")
                val intent = keyguard.createConfirmDeviceCredentialIntent(
                    call.argument<String>("title"),
                    call.argument<String>("description"),
                )
                if (intent == null) {
                    result.success(false)
                    return@setMethodCallHandler
                }
                pendingConfirm = result
                @Suppress("DEPRECATION")
                startActivityForResult(intent, REQUEST_CONFIRM)
            }
    }

    @Deprecated("Uses the platform result API on purpose; see above.")
    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CONFIRM) {
            pendingConfirm?.success(resultCode == Activity.RESULT_OK)
            pendingConfirm = null
        }
    }

    companion object {
        private const val CHANNEL = "bamsenet/device_credential"
        private const val REQUEST_CONFIRM = 4711
    }
}
