import React, { useState } from 'react';
import { View, Text, Image, Pressable, StyleSheet } from 'react-native';
import LinearGradient from 'react-native-linear-gradient';
import Icon from '../ui/Icon';
import { rs, isBig } from '../ui/responsive';
import { C, GRAD2 } from '../theme';

// «يُعرض الآن» — بطاقة سينمائية: خلفية الشعار معتّمة + تدرّج + معلومات وزر كبير. متجاوبة.
export default function Hero({ channel, onPlay }) {
  const [focused, setFocused] = useState(false);
  if (!channel) return null;
  const logo = /^https:/i.test(channel.logo_url || '') ? channel.logo_url : null;
  const meta = [channel.country_name, channel.category_name, channel.quality].filter(Boolean).join('  ·  ');

  return (
    <View style={s.wrap}>
      <Pressable onPress={() => onPlay(channel)} onFocus={() => setFocused(true)} onBlur={() => setFocused(false)}
        hasTVPreferredFocus style={[s.card, focused && s.cardOn]}>
        {/* خلفية: شعار القناة معتّم وكبير */}
        {logo && <Image source={{ uri: logo }} style={s.bg} resizeMode="contain" blurRadius={isBig ? 8 : 4} />}
        <LinearGradient colors={['rgba(8,8,12,0.55)', 'rgba(8,8,12,0.88)', '#0b0b12']}
          start={{ x: 0, y: 0 }} end={{ x: 0, y: 1 }} style={StyleSheet.absoluteFill} />
        <LinearGradient colors={['rgba(255,45,85,0.28)', 'transparent']} start={{ x: 1, y: 0 }} end={{ x: 0, y: 0.8 }}
          style={s.tint} />

        <View style={s.content}>
          <View style={s.badge}><View style={s.dot} /><Text style={s.badgeT}>يُعرض الآن</Text></View>

          <View style={s.main}>
            <View style={s.logoBox}>
              {logo ? <Image source={{ uri: logo }} style={s.logo} resizeMode="contain" />
                : <Text style={s.init}>{(channel.name || '•')[0]}</Text>}
            </View>
            <View style={{ flex: 1 }}>
              <Text numberOfLines={2} style={s.name}>{channel.name}</Text>
              <Text numberOfLines={1} style={s.meta}>{meta}</Text>
            </View>
          </View>

          <View style={[s.btn, focused && s.btnOn]}>
            <LinearGradient colors={GRAD2} start={{ x: 0, y: 0 }} end={{ x: 1, y: 0 }} style={s.btnIn}>
              <Icon name="play" size={rs(18)} color="#fff" />
              <Text style={s.btnT}>شاهد الآن</Text>
            </LinearGradient>
          </View>
        </View>
      </Pressable>
    </View>
  );
}

const s = StyleSheet.create({
  wrap: { paddingHorizontal: 14, marginBottom: 24 },
  card: { borderRadius: rs(22), overflow: 'hidden', borderWidth: 1, borderColor: C.line, minHeight: rs(200) },
  cardOn: { borderColor: C.ac, transform: [{ scale: 1.01 }] },
  bg: { position: 'absolute', top: '-20%', right: '-10%', width: '70%', height: '140%', opacity: 0.4 },
  tint: { position: 'absolute', top: 0, right: 0, left: 0, height: rs(120) },
  content: { padding: rs(18) },
  badge: { flexDirection: 'row-reverse', alignSelf: 'flex-end', alignItems: 'center', gap: 6, backgroundColor: 'rgba(225,29,72,0.9)', borderRadius: 999, paddingHorizontal: rs(11), paddingVertical: rs(5) },
  dot: { width: 7, height: 7, borderRadius: 4, backgroundColor: '#fff' },
  badgeT: { color: '#fff', fontSize: rs(12), fontWeight: '800' },
  main: { flexDirection: 'row-reverse', alignItems: 'center', gap: rs(14), marginTop: rs(18), marginBottom: rs(18) },
  logoBox: { width: rs(80), height: rs(80), borderRadius: rs(18), backgroundColor: 'rgba(255,255,255,0.08)', alignItems: 'center', justifyContent: 'center', borderWidth: 1, borderColor: C.line2 },
  logo: { width: '76%', height: '76%' },
  init: { color: '#fff', fontSize: rs(36), fontWeight: '900' },
  name: { color: '#fff', fontSize: rs(25), fontWeight: '900', textAlign: 'right' },
  meta: { color: 'rgba(255,255,255,0.75)', fontSize: rs(13.5), marginTop: rs(6), textAlign: 'right' },
  btn: { borderRadius: rs(14), overflow: 'hidden' },
  btnOn: { shadowColor: C.ac, shadowOpacity: 0.6, shadowRadius: 12, elevation: 8 },
  btnIn: { flexDirection: 'row-reverse', alignItems: 'center', justifyContent: 'center', gap: 8, height: rs(50) },
  btnT: { color: '#fff', fontSize: rs(16), fontWeight: '800' },
});
