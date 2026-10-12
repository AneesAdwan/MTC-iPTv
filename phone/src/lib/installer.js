// تنزيل وتثبيت تحديث التطبيق (APK) من داخل التطبيق — بلا فتح المتصفح.
// يحمّل الملف إلى ذاكرة مؤقتة ثم يفتح مثبّت أندرويد (يحدّث فوق القديم ويحفظ البيانات).
import { Platform } from 'react-native';
import ReactNativeBlobUtil from 'react-native-blob-util';

/**
 * @param {string} url رابط الـ APK
 * @param {(pct:number)=>void} onProgress نسبة التنزيل 0..100
 * @returns {Promise<void>}
 */
export async function downloadAndInstall(url, onProgress) {
  if (Platform.OS !== 'android') throw new Error('التثبيت الداخلي متاح على أندرويد فقط');
  const { dirs } = ReactNativeBlobUtil.fs;
  const path = `${dirs.CacheDir}/MTC-iPTv-update.apk`;

  const task = ReactNativeBlobUtil.config({
    path,
    overwrite: true,
    trusty: true,
    addAndroidDownloads: { useDownloadManager: false, notification: false },
  }).fetch('GET', url);

  task.progress({ interval: 250 }, (received, total) => {
    if (total > 0 && onProgress) onProgress(Math.round((received / total) * 100));
  });

  const res = await task;
  const file = res.path();
  // يفتح مثبّت الحزم الأصلي
  await ReactNativeBlobUtil.android.actionViewIntent(file, 'application/vnd.android.package-archive');
}
