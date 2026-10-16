package com.mtciptv.mtc_iptv

import android.content.Intent
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
                if (call.method == "initialLink") result.success(linkOf(intent)) else result.notImplemented()
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
