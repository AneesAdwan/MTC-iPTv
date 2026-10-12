import React, { useState } from 'react';
import { Modal, View, Text, Pressable, StyleSheet, ActivityIndicator } from 'react-native';
import LinearGradient from 'react-native-linear-gradient';
import Icon from '../ui/Icon';
import { downloadAndInstall } from '../lib/installer';
import { rs } from '../ui/responsive';
import { C, GRAD2 } from '../theme';

// نافذة تحديث: تنزّل الـ APK داخل التطبيق مع شريط تقدّم، ثم تفتح المثبّت (يحدّث فوق القديم بلا حذف).
export default function UpdateModal({ update, onClose }) {
  const [pct, setPct] = useState(-1);   // -1 لم يبدأ · 0..100 ينزّل · 101 يفتح المثبّت
  const [err, setErr] = useState('');

  const start = async () => {
    setErr(''); setPct(0);
    try {
      await downloadAndInstall(update.url, p => setPct(p));
      setPct(101);
    } catch (e) {
      setErr('تعذّر التنزيل. تأكد من الاتصال وحاول مجددًا.');
      setPct(-1);
    }
  };

  const busy = pct >= 0 && pct <= 100;
  return (
    <Modal transparent animationType="fade" onRequestClose={busy ? undefined : onClose}>
      <View style={s.backdrop}>
        <View style={s.card}>
          <View style={s.iconWrap}><Icon name="download" size={rs(26)} color={C.ac2} /></View>
          <Text style={s.title}>تحديث جديد {update.version}</Text>
          <Text style={s.sub}>
            {pct === 101 ? 'جارٍ فتح المثبّت… وافق على التثبيت لإكمال التحديث.'
              : busy ? `جارٍ التنزيل… ${pct}%`
              : 'ينزّل داخل التطبيق ويُثبّت فوق النسخة الحالية — دون فقدان بياناتك.'}
          </Text>

          {busy && (
            <View style={s.track}><View style={[s.fill, { width: `${pct}%` }]} /></View>
          )}
          {pct === 101 && <ActivityIndicator color={C.ac} style={{ marginTop: 14 }} />}
          {!!err && <Text style={s.err}>{err}</Text>}

          {!busy && pct !== 101 && (
            <View style={s.actions}>
              <Pressable style={s.ghost} onPress={onClose}><Text style={s.ghostT}>لاحقًا</Text></Pressable>
              <Pressable style={s.pri} onPress={start}>
                <LinearGradient colors={GRAD2} start={{ x: 0, y: 0 }} end={{ x: 1, y: 0 }} style={s.priIn}>
                  <Icon name="download" size={rs(17)} color="#fff" /><Text style={s.priT}>تحديث الآن</Text>
                </LinearGradient>
              </Pressable>
            </View>
          )}
        </View>
      </View>
    </Modal>
  );
}

const s = StyleSheet.create({
  backdrop: { flex: 1, backgroundColor: 'rgba(0,0,0,0.6)', alignItems: 'center', justifyContent: 'center', padding: 24 },
  card: { width: '100%', maxWidth: 400, backgroundColor: C.surface, borderRadius: 20, padding: 22, alignItems: 'center', borderWidth: 1, borderColor: C.line2 },
  iconWrap: { width: 56, height: 56, borderRadius: 16, backgroundColor: 'rgba(255,122,26,0.12)', alignItems: 'center', justifyContent: 'center' },
  title: { color: '#fff', fontSize: rs(18), fontWeight: '900', marginTop: 14 },
  sub: { color: C.mut, fontSize: rs(13.5), textAlign: 'center', marginTop: 8, lineHeight: 20 },
  track: { width: '100%', height: 6, borderRadius: 6, backgroundColor: C.surface2, overflow: 'hidden', marginTop: 16 },
  fill: { height: '100%', backgroundColor: C.ac, borderRadius: 6 },
  err: { color: C.bad, fontSize: 13, marginTop: 12, textAlign: 'center' },
  actions: { flexDirection: 'row-reverse', gap: 10, marginTop: 20, width: '100%' },
  ghost: { flex: 1, alignItems: 'center', justifyContent: 'center', height: 48, borderRadius: 12, backgroundColor: C.surface2 },
  ghostT: { color: C.txt, fontSize: 15, fontWeight: '700' },
  pri: { flex: 1.4, borderRadius: 12, overflow: 'hidden' },
  priIn: { flexDirection: 'row-reverse', alignItems: 'center', justifyContent: 'center', gap: 8, height: 48 },
  priT: { color: '#fff', fontSize: 15, fontWeight: '800' },
});
