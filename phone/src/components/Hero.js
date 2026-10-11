import React from 'react';
import { View, Text, Image, Pressable, StyleSheet } from 'react-native';
import LinearGradient from 'react-native-linear-gradient';
import Icon from '../ui/Icon';
import { C, GRAD2 } from '../theme';

// «يُعرض الآن» — البطاقة الكبيرة أعلى الرئيسية (مثل الموقع): القناة المختارة من اللوحة أو قناة مميزة.
export default function Hero({ channel, onPlay }) {
  if (!channel) return null;
  const logo = /^https:/i.test(channel.logo_url || '') ? channel.logo_url : null;
  const meta = [channel.country_name, channel.category_name, channel.quality].filter(Boolean).join(' · ');
  return (
    <View style={s.wrap}>
      <LinearGradient colors={['#1a1020', '#241018', C.bg]} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={s.card}>
        {/* توهّج خلفي */}
        <LinearGradient colors={['rgba(255,45,85,0.35)', 'transparent']} style={s.glow} start={{ x: 1, y: 0 }} end={{ x: 0, y: 1 }} />

        <View style={s.badge}><View style={s.dot} /><Text style={s.badgeT}>يُعرض الآن · مباشر</Text></View>

        <View style={s.body}>
          <View style={s.logoBox}>
            {logo ? <Image source={{ uri: logo }} style={s.logo} resizeMode="contain" />
              : <Text style={s.init}>{(channel.name || '•')[0]}</Text>}
          </View>
          <View style={s.info}>
            <Text numberOfLines={2} style={s.name}>{channel.name}</Text>
            <Text numberOfLines={1} style={s.meta}>{meta}</Text>
          </View>
        </View>

        <Pressable onPress={() => onPlay(channel)} style={({ pressed }) => [pressed && { opacity: 0.85 }]} hasTVPreferredFocus>
          <LinearGradient colors={GRAD2} start={{ x: 0, y: 0 }} end={{ x: 1, y: 0 }} style={s.btn}>
            <Icon name="play" size={18} color="#fff" />
            <Text style={s.btnT}>شاهد الآن</Text>
          </LinearGradient>
        </Pressable>
      </LinearGradient>
    </View>
  );
}

const s = StyleSheet.create({
  wrap: { paddingHorizontal: 14, marginBottom: 22 },
  card: { borderRadius: 20, padding: 18, overflow: 'hidden', borderWidth: 1, borderColor: C.line },
  glow: { position: 'absolute', top: 0, right: 0, width: 220, height: 160 },
  badge: { flexDirection: 'row-reverse', alignSelf: 'flex-end', alignItems: 'center', gap: 6, backgroundColor: 'rgba(0,0,0,0.3)', borderRadius: 999, paddingHorizontal: 11, paddingVertical: 5 },
  dot: { width: 7, height: 7, borderRadius: 4, backgroundColor: C.ac },
  badgeT: { color: '#fff', fontSize: 12, fontWeight: '700' },
  body: { flexDirection: 'row-reverse', alignItems: 'center', gap: 14, marginTop: 16, marginBottom: 18 },
  logoBox: { width: 84, height: 84, borderRadius: 18, backgroundColor: 'rgba(255,255,255,0.06)', alignItems: 'center', justifyContent: 'center', borderWidth: 1, borderColor: C.line },
  logo: { width: '78%', height: '78%' },
  init: { color: C.mut, fontSize: 38, fontWeight: '900' },
  info: { flex: 1 },
  name: { color: '#fff', fontSize: 24, fontWeight: '900', textAlign: 'right' },
  meta: { color: C.mut, fontSize: 13.5, marginTop: 5, textAlign: 'right' },
  btn: { flexDirection: 'row-reverse', alignItems: 'center', justifyContent: 'center', gap: 8, height: 50, borderRadius: 14 },
  btnT: { color: '#fff', fontSize: 16, fontWeight: '800' },
});
