import React, { useState } from 'react';
import { View, Text, Pressable, ScrollView, StyleSheet, Linking, Image } from 'react-native';
import LinearGradient from 'react-native-linear-gradient';
import LogoMark from '../ui/LogoMark';
import Wordmark from '../ui/Wordmark';
import Icon from '../ui/Icon';
import { APP_VERSION, COMPANY } from '../appVersion';
import { checkUpdate } from '../lib/update';
import { rs } from '../ui/responsive';
import { C, GRAD2 } from '../theme';

const GITHUB = 'https://github.com/AneesAdwan/MTC-iPTv';
const EMBLEM = require('../assets/mtc-group-emblem.png');

// صفحة «حول»: بيانات التطبيق، الشركة الأم، المطوّر، الإصدار، رابط GitHub، فحص التحديث.
export default function AboutScreen({ onBack }) {
  const [upd, setUpd] = useState('');

  const check = async () => {
    setUpd('…');
    const u = await checkUpdate();
    setUpd(u ? `تحديث ${u.version} متوفّر` : 'أنت على أحدث إصدار');
  };

  return (
    <View style={s.wrap}>
      <View style={s.top}>
        <Pressable style={s.back} onPress={onBack}><Icon name="back" size={rs(22)} color="#fff" /></Pressable>
        <Text style={s.topT}>حول التطبيق</Text>
        <View style={{ width: rs(40) }} />
      </View>

      <ScrollView contentContainerStyle={{ padding: 20, paddingBottom: 40, alignItems: 'center' }} showsVerticalScrollIndicator={false}>
        <LogoMark size={rs(96)} />
        <View style={{ marginTop: 14 }}><Wordmark size={rs(28)} /></View>
        <Text style={s.tag}>بثّ مباشر · آلاف القنوات من حول العالم</Text>
        <View style={s.verPill}><Text style={s.verT}>الإصدار {APP_VERSION}</Text></View>

        {/* فحص التحديث */}
        <Pressable style={s.updBtn} onPress={check}>
          <LinearGradient colors={GRAD2} start={{ x: 0, y: 0 }} end={{ x: 1, y: 0 }} style={s.updIn}>
            <Icon name="refresh" size={rs(17)} color="#fff" /><Text style={s.updBtnT}>تحقّق من التحديثات</Text>
          </LinearGradient>
        </Pressable>
        {!!upd && <Text style={s.updMsg}>{upd}</Text>}

        {/* الشركة الأم */}
        <View style={s.card}>
          <Text style={s.cardCap}>إحدى شركات</Text>
          <Image source={EMBLEM} style={s.emblem} resizeMode="contain" />
          <Text style={s.group}>MTC<Text style={{ color: C.ac2 }}>-Group</Text></Text>
          <Text style={s.companyAr}>{COMPANY.ar}</Text>
          <Text style={s.companyEn}>{COMPANY.en}</Text>
        </View>

        {/* المطوّر */}
        <View style={s.card}>
          <Text style={s.cardCap}>برمجة وتطوير</Text>
          <View style={s.devRow}>
            <View style={s.devAvatar}><Text style={s.devInit}>أ</Text></View>
            <View>
              <Text style={s.devName}>أنيس عدوان</Text>
              <Text style={s.devNameEn}>Anees Adwan</Text>
            </View>
          </View>
        </View>

        {/* روابط */}
        <Row icon="server" label="مستودع المشروع (GitHub)" onPress={() => Linking.openURL(GITHUB)} />
        <Row icon="download" label="تحميل أحدث إصدار" onPress={() => Linking.openURL(`${GITHUB}/releases/latest`)} />

        <Text style={s.copy}>© {new Date().getFullYear()} MTC-iPTv · جميع الحقوق محفوظة</Text>
        <Text style={s.note}>القنوات من روابط بث عامة ومجانية — المنصّة لا تستضيف أي محتوى.</Text>
      </ScrollView>
    </View>
  );
}

function Row({ icon, label, onPress }) {
  return (
    <Pressable style={s.linkRow} onPress={onPress}>
      <View style={s.linkIc}><Icon name={icon} size={rs(18)} color={C.ac2} /></View>
      <Text style={s.linkT}>{label}</Text>
      <Icon name="back" size={rs(16)} color={C.dim} />
    </Pressable>
  );
}

const s = StyleSheet.create({
  wrap: { flex: 1, backgroundColor: C.bg },
  top: { flexDirection: 'row-reverse', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 12, paddingVertical: 12, borderBottomWidth: 1, borderBottomColor: C.line },
  back: { width: rs(40), height: rs(40), borderRadius: rs(20), alignItems: 'center', justifyContent: 'center', backgroundColor: C.surface },
  topT: { color: '#fff', fontSize: rs(17), fontWeight: '800' },
  tag: { color: C.mut, fontSize: rs(13), marginTop: 10, textAlign: 'center' },
  verPill: { marginTop: 12, backgroundColor: C.surface, borderWidth: 1, borderColor: C.line, borderRadius: 999, paddingHorizontal: 14, paddingVertical: 6 },
  verT: { color: C.txt, fontSize: rs(13), fontWeight: '700' },
  updBtn: { marginTop: 18, borderRadius: 12, overflow: 'hidden', width: '100%', maxWidth: 320 },
  updIn: { flexDirection: 'row-reverse', alignItems: 'center', justifyContent: 'center', gap: 8, height: 48 },
  updBtnT: { color: '#fff', fontSize: rs(15), fontWeight: '800' },
  updMsg: { color: C.ok, fontSize: rs(13), marginTop: 10 },
  card: { width: '100%', maxWidth: 420, backgroundColor: C.surface, borderRadius: 18, padding: 18, marginTop: 18, alignItems: 'center', borderWidth: 1, borderColor: C.line },
  cardCap: { color: C.dim, fontSize: rs(12), letterSpacing: 0.5 },
  emblem: { width: rs(72), height: rs(72), marginTop: 10 },
  group: { color: '#fff', fontSize: rs(22), fontWeight: '900', marginTop: 10, writingDirection: 'ltr' },
  companyAr: { color: C.mut, fontSize: rs(13), marginTop: 6, textAlign: 'center' },
  companyEn: { color: C.dim, fontSize: rs(11), marginTop: 3, textAlign: 'center', writingDirection: 'ltr' },
  devRow: { flexDirection: 'row-reverse', alignItems: 'center', gap: 12, marginTop: 10 },
  devAvatar: { width: rs(48), height: rs(48), borderRadius: rs(24), backgroundColor: C.ac, alignItems: 'center', justifyContent: 'center' },
  devInit: { color: '#fff', fontSize: rs(22), fontWeight: '900' },
  devName: { color: '#fff', fontSize: rs(16), fontWeight: '800', textAlign: 'right' },
  devNameEn: { color: C.mut, fontSize: rs(12.5), writingDirection: 'ltr', textAlign: 'right' },
  linkRow: { width: '100%', maxWidth: 420, flexDirection: 'row-reverse', alignItems: 'center', gap: 12, backgroundColor: C.surface, borderRadius: 12, paddingHorizontal: 14, paddingVertical: 14, marginTop: 10, borderWidth: 1, borderColor: C.line },
  linkIc: { width: rs(34), height: rs(34), borderRadius: 9, backgroundColor: 'rgba(255,122,26,0.12)', alignItems: 'center', justifyContent: 'center' },
  linkT: { flex: 1, color: C.txt, fontSize: rs(14.5), fontWeight: '700', textAlign: 'right' },
  copy: { color: C.mut, fontSize: rs(12), marginTop: 24, textAlign: 'center' },
  note: { color: C.dim, fontSize: rs(11), marginTop: 6, textAlign: 'center', lineHeight: 18 },
});
