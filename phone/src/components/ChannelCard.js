import React, { useState } from 'react';
import { Pressable, View, Text, Image, StyleSheet, Platform } from 'react-native';
import LinearGradient from 'react-native-linear-gradient';
import Icon from '../ui/Icon';
import { C, GRAD2 } from '../theme';

// بطاقة قناة فخمة — شعار، رقم، جودة، شارة مباشر، وإطار متوهّج عند التركيز (ريموت التلفاز).
export default function ChannelCard({ channel, onPress, hasTVPreferredFocus }) {
  const [focused, setFocused] = useState(false);
  const logo = /^https:/i.test(channel.logo_url || '') ? channel.logo_url : null;
  return (
    <Pressable
      onPress={() => onPress(channel)}
      onFocus={() => setFocused(true)}
      onBlur={() => setFocused(false)}
      hasTVPreferredFocus={hasTVPreferredFocus}
      style={({ pressed }) => [s.card, (focused || pressed) && s.cardOn]}>
      <View style={[s.thumb, focused && s.thumbOn]}>
        {logo
          ? <Image source={{ uri: logo }} style={s.logo} resizeMode="contain" />
          : <Text style={s.init}>{(channel.name || '•')[0]}</Text>}
        {/* شارة مباشر */}
        <View style={s.live}><View style={s.dot} /><Text style={s.liveT}>مباشر</Text></View>
        {!!channel.quality && <View style={s.q}><Text style={s.qT}>{channel.quality}</Text></View>}
        {!!channel.prefer_app && (
          <LinearGradient colors={GRAD2} style={s.app}><Icon name="download" size={12} color="#fff" /></LinearGradient>
        )}
        <View style={s.num}><Text style={s.numT}>{channel.number || '—'}</Text></View>
      </View>
      <Text numberOfLines={1} style={s.name}>{channel.name}</Text>
      <Text numberOfLines={1} style={s.sub}>
        {[channel.country_name, channel.category_name].filter(Boolean).join(' · ')}
      </Text>
    </Pressable>
  );
}

const W = Platform.isTV ? 240 : 148;
const s = StyleSheet.create({
  card: { width: W, marginHorizontal: 6 },
  cardOn: { transform: [{ scale: Platform.isTV ? 1.08 : 1.02 }] },
  thumb: {
    width: W, height: W * 9 / 16, borderRadius: 12, backgroundColor: C.surface2,
    alignItems: 'center', justifyContent: 'center', overflow: 'hidden',
    borderWidth: 2, borderColor: 'transparent',
  },
  thumbOn: { borderColor: C.ac },
  logo: { width: '80%', height: '70%' },
  init: { color: C.mut, fontSize: 32, fontWeight: '800' },
  live: { position: 'absolute', top: 6, right: 6, flexDirection: 'row-reverse', alignItems: 'center', gap: 4, backgroundColor: 'rgba(225,29,72,0.92)', borderRadius: 5, paddingHorizontal: 6, paddingVertical: 2 },
  dot: { width: 5, height: 5, borderRadius: 3, backgroundColor: '#fff' },
  liveT: { color: '#fff', fontSize: 9, fontWeight: '800' },
  q: { position: 'absolute', top: 6, left: 6, backgroundColor: 'rgba(0,0,0,0.6)', borderRadius: 4, paddingHorizontal: 5, paddingVertical: 1 },
  qT: { color: '#fff', fontWeight: '700', fontSize: 10 },
  app: { position: 'absolute', bottom: 6, left: 6, width: 22, height: 22, borderRadius: 6, alignItems: 'center', justifyContent: 'center' },
  num: { position: 'absolute', bottom: 6, right: 6, backgroundColor: 'rgba(0,0,0,0.65)', borderRadius: 5, paddingHorizontal: 6, paddingVertical: 2 },
  numT: { color: '#eee', fontWeight: '800', fontSize: 11 },
  name: { color: C.txt, fontSize: 13.5, fontWeight: '700', marginTop: 7, textAlign: 'right' },
  sub: { color: C.dim, fontSize: 11.5, marginTop: 2, textAlign: 'right' },
});
