// إشعارات Push عبر Firebase Cloud Messaging.
// الأجهزة تشترك في موضوع «all» — فنرسل إشعارًا واحدًا للموضوع يصل الجميع (بلا قاعدة أجهزة).
import { Platform, PermissionsAndroid } from 'react-native';
import messaging from '@react-native-firebase/messaging';

export async function initPush() {
  try {
    // صلاحية الإشعارات على أندرويد 13+
    if (Platform.OS === 'android' && Platform.Version >= 33) {
      await PermissionsAndroid.request(PermissionsAndroid.PERMISSIONS.POST_NOTIFICATIONS).catch(() => {});
    }
    await messaging().requestPermission().catch(() => {});
    // الاشتراك في الموضوع العام — كل إشعار يُرسل إليه يصل كل الأجهزة
    await messaging().subscribeToTopic('all').catch(() => {});
  } catch {}
}

// معالج الرسائل والتطبيق في الخلفية/مغلق (يُسجَّل في index.js)
export function setBackgroundHandler() {
  messaging().setBackgroundMessageHandler(async () => {});
}
