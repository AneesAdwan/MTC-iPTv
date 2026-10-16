package com.mtciptv.mtc_iptv

import android.app.UiModeManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Configuration
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
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        linkOf(intent)?.let { channel?.invokeMethod("args", it) }
    }

    private fun linkOf(i: Intent?): String? =
        i?.data?.takeIf { i.action == Intent.ACTION_VIEW && it.scheme == "mtciptv" }?.toString()
}
