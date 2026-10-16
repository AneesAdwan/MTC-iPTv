package com.mtciptv.mtc_iptv

import android.Manifest
import android.app.UiModeManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.firebase.messaging.FirebaseMessaging
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// الروابط العميقة mtciptv://watch/<id> (§23): نفس القناة "mtc/instance" المستعملة على Windows.
//   initialLink ← الرابط الذي فُتح به التطبيق (إن وجد)
//   args        ← رابط جديد والتطبيق يعمل (singleTop ← onNewIntent)
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "mtc/instance").also {
            it.setMethodCallHandler { call, result ->
                when (call.method) {
                    "initialLink" -> result.success(linkOf(intent))
                    // Android TV / Google TV: وضع التلفاز أو ميزة leanback (§6.5 نمط tv)
                    "isTv" -> {
                        val ui = getSystemService(Context.UI_MODE_SERVICE) as UiModeManager
                        result.success(
                            ui.currentModeType == Configuration.UI_MODE_TYPE_TELEVISION ||
                                packageManager.hasSystemFeature(PackageManager.FEATURE_LEANBACK)
                        )
                    }
                    // Push (§14): إذن الإشعارات (Android 13+) + الاشتراك في «all» + الرمز (null إن لم يُعدّ Firebase)
                    "pushInit" -> pushInit(result)
                    else -> result.notImplemented()
                }
            }
        }
    }

    private fun pushInit(result: MethodChannel.Result) {
        if (!Push.available(this)) {
            result.success(null)
            return
        }
        Push.ensureChannel(this)
        if (Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.POST_NOTIFICATIONS), 7101)
        }
        val fm = FirebaseMessaging.getInstance()
        fm.subscribeToTopic("all")
        fm.token.addOnCompleteListener { t -> result.success(if (t.isSuccessful) t.result else null) }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        linkOf(intent)?.let { channel?.invokeMethod("args", it) }
    }

    // الرابط من Intent عادي (mtciptv://…) أو من إشعار عرضه النظام والتطبيق في الخلفية (البيانات في extras: url)
    private fun linkOf(i: Intent?): String? =
        i?.data?.takeIf { i.action == Intent.ACTION_VIEW && it.scheme == "mtciptv" }?.toString()
            ?: i?.getStringExtra("url")?.takeIf { it.startsWith("mtciptv://") }
}
