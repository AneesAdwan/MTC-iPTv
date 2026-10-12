import React, { useState } from 'react';
import { Pressable, View, Text, Image, StyleSheet } from 'react-native';
import LinearGradient from 'react-native-linear-gradient';
import Icon from '../ui/Icon';
import { cardW, rs, isTV } from '../ui/responsive';
import { C, GRAD2 } from '../theme';

// بطاقة قناة متجاوبة — غلاف متدرّج خلف الشعار، شارات أنيقة، تكبّر وتتوهّج عند التركيز.
export default function ChannelCard({ channel, onPress, hasTVPreferredFocus, width }) {
  const [focused, setFocused] = useState(false);
  const W = width || cardW;
  const logo = /^https:/i.test(channel.logo_url || '') ? channel.logo_url : null;
  const hue = (hashStr(channel.name || '?') % 360);
  return (
    <Pressable
      onPress={() => onPress(channel)}
      onFocus={() => setFocused(true)} onBlur={() => setFocused(false)}
      hasTVPreferredFocus={hasTVPreferredFocus}
      style={({ pressed }) => [{ width: W, marginHorizontal: 6 }, (focused || pressed) && s.on]}>
      <View style={[s.thumb, { width: W, height: W * 9 / 16 }, focused && s.thumbOn]}>
        <LinearGradient colors={[`hsl(${hue},45%,22%)`, `hsl(${hue},40%,12%)`]} style={StyleSheet.absoluteFill} />
        {logo
          ? <Image source={{ uri: logo }} style={s.logo} resizeMode="contain" />
          : <Text style={s.init}>{(channel.name || '•')[0]}</Text>}
        <View style={s.live}><View style={s.dot} /><Text style={s.liveT}>مباشر</Text></View>
        {!!channel.quality && <View style={s.q}><Text style={s.qT}>{channel.quality}</Text></View>}
        {!!channel.prefer_app && (
          <LinearGradient colors={GRAD2} style={s.app}><Icon name="download" size={12} color="#fff" /></LinearGradient>
        )}
        <View style={s.num}><Text style={s.numT}>{channel.number || '—'}</Text></View>
      </View>
      <Text numberOfLines={1} style={s.name}>{channel.name}</Text>
      <Text numberOfLines={1} style={s.sub}>{[channel.country_name, channel.category_name].filter(Boolean).join(' · ')}</Text>
    </Pressable>
  );
}

function hashStr(str) { let h = 0; for (let i = 0; i < str.length; i++) h = (h * 31 + str.charCodeAt(i)) | 0; return Math.abs(h); }

const s = StyleSheet.create({
  on: { transform: [{ scale: isTV ? 1.09 : 1.03 }] },
  thumb: { borderRadius: 12, alignItems: 'center', justifyContent: 'center', overflow: 'hidden', borderWidth: 2, borderColor: 'transparent' },
  thumbOn: { borderColor: C.ac },
  logo: { width: '78%', height: '70%' },
  init: { color: '#fff', fontSize: rs(30), fontWeight: '900', opacity: 0.85 },
  live: { position: 'absolute', top: 6, right: 6, flexDirection: 'row-reverse', alignItems: 'center', gap: 4, backgroundColor: 'rgba(225,29,72,0.92)', borderRadius: 5, paddingHorizontal: 6, paddingVertical: 2 },
  dot: { width: 5, height: 5, borderRadius: 3, backgroundColor: '#fff' },
  liveT: { color: '#fff', fontSize: 9, fontWeight: '800' },
  q: { position: 'absolute', top: 6, left: 6, backgroundColor: 'rgba(0,0,0,0.55)', borderRadius: 4, paddingHorizontal: 5, paddingVertical: 1 },
  qT: { color: '#fff', fontWeight: '700', fontSize: 10 },
  app: { position: 'absolute', bottom: 6, left: 6, width: 22, height: 22, borderRadius: 6, alignItems: 'center', justifyContent: 'center' },
  num: { position: 'absolute', bottom: 6, right: 6, backgroundColor: 'rgba(0,0,0,0.6)', borderRadius: 5, paddingHorizontal: 6, paddingVertical: 2 },
  numT: { color: '#eee', fontWeight: '800', fontSize: 11 },
  name: { color: C.txt, fontSize: rs(13.5), fontWeight: '700', marginTop: 7, textAlign: 'right' },
  sub: { color: C.dim, fontSize: rs(11.5), marginTop: 2, textAlign: 'right' },
});
