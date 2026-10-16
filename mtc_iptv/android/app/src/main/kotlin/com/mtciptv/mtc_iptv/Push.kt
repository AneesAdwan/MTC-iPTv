package com.mtciptv.mtc_iptv

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.google.firebase.FirebaseApp
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

// إشعارات Push (§14، R2): نفس قناة تطبيق React Native — الموضوع «all» من الدالة send-push.
//  • التطبيق في الخلفية أو مغلق: النظام يعرض الإشعار بنفسه، والضغط يفتح MainActivity ومعه بيانات الرسالة (url).
//  • التطبيق مفتوح: النظام لا يعرض رسائل notification، فنعرضها هنا.
object Push {
    const val CHANNEL = "general"

    /** Firebase مُهيّأ؟ (نسخ المعاينة تُبنى بلا إعداده، انظر build.gradle.kts) */
    fun available(ctx: Context): Boolean = FirebaseApp.getApps(ctx).isNotEmpty()

    fun ensureChannel(ctx: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = ctx.getSystemService(NotificationManager::class.java)
        if (nm.getNotificationChannel(CHANNEL) == null) {
            nm.createNotificationChannel(NotificationChannel(CHANNEL, "إشعارات MTC-iPTv", NotificationManager.IMPORTANCE_HIGH))
        }
    }

    fun show(ctx: Context, title: String, body: String, url: String?) {
        if (Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(ctx, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) return
        ensureChannel(ctx)
        val open = Intent(ctx, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            if (url != null && url.startsWith("mtciptv://")) {
                action = Intent.ACTION_VIEW
                data = Uri.parse(url)
            }
        }
        val pi = PendingIntent.getActivity(ctx, (System.currentTimeMillis() % Int.MAX_VALUE).toInt(), open,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val n = NotificationCompat.Builder(ctx, CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_notify)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pi)
            .build()
        NotificationManagerCompat.from(ctx).notify((System.currentTimeMillis() % Int.MAX_VALUE).toInt(), n)
    }
}

class MtcMessagingService : FirebaseMessagingService() {
    override fun onNewToken(token: String) {
        getSharedPreferences("mtc_push", MODE_PRIVATE).edit().putString("token", token).apply()
    }

    override fun onMessageReceived(m: RemoteMessage) {
        val title = m.notification?.title ?: m.data["title"] ?: return
        val body = m.notification?.body ?: m.data["body"] ?: ""
        Push.show(this, title, body, m.data["url"])
    }
}
