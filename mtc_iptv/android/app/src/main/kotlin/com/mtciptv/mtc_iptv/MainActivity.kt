package com.mtciptv.mtc_iptv

import android.Manifest
import android.app.PictureInPictureParams
import android.app.UiModeManager
import android.util.Rational
import androidx.annotation.RequiresApi
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import java.io.File
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
                    // صورة داخل صورة (§7.6، R2): شاشة المشاهدة تسمح بها أثناء التشغيل، والدخول تلقائي عند مغادرة التطبيق
                    "setPip" -> {
                        pipAllowed = call.arguments as? Boolean ?: false
                        if (Build.VERSION.SDK_INT >= 31) setPictureInPictureParams(pipParams())
                        result.success(null)
                    }
                    "enterPip" -> result.success(enterPip())
                    // التحديث داخل التطبيق (طلب المالك 2026-10-17: «على طول ينزل» بدل صفحة GitHub)
                    "abis" -> result.success(Build.SUPPORTED_ABIS.toList())
                    "canInstall" -> result.success(Build.VERSION.SDK_INT < 26 || packageManager.canRequestPackageInstalls())
                    "openInstallSettings" -> {
                        if (Build.VERSION.SDK_INT >= 26) {
                            startActivity(Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:$packageName")))
                        }
                        result.success(null)
                    }
                    "installApk" -> {
                        val f = File(call.arguments as String)
                        val uri = FileProvider.getUriForFile(this, "$packageName.updates", f)
                        startActivity(
                            Intent(Intent.ACTION_VIEW).setDataAndType(uri, "application/vnd.android.package-archive")
                                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    private var pipAllowed = false

    @RequiresApi(26)
    private fun pipParams(): PictureInPictureParams {
        val b = PictureInPictureParams.Builder().setAspectRatio(Rational(16, 9))
        if (Build.VERSION.SDK_INT >= 31) b.setAutoEnterEnabled(pipAllowed).setSeamlessResizeEnabled(true)
        return b.build()
    }

    private fun enterPip(): Boolean {
        if (Build.VERSION.SDK_INT < 26 || !packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)) return false
        return try {
            enterPictureInPictureMode(pipParams())
        } catch (e: IllegalStateException) {
            false
        }
    }

    // Android 8–11: لا دخول تلقائي في النظام، فندخل عند زر الرئيسية/المغادرة (Android 12+ يتكفّل به setAutoEnterEnabled)
    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (pipAllowed && Build.VERSION.SDK_INT in 26..30) enterPip()
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: Configuration) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        channel?.invokeMethod("pip", isInPictureInPictureMode)
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
