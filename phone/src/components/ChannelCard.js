import React, { useState } from 'react';
import { Pressable, View, Text, Image, StyleSheet, Platform } from 'react-native';
import { C } from '../theme';

// بطاقة قناة — قابلة للتركيز بالريموت على التلفاز (يكبر الإطار عند التركيز).
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
      <View style={s.thumb}>
        {logo
          ? <Image source={{ uri: logo }} style={s.logo} resizeMode="contain" />
          : <Text style={s.init}>{(channel.name || '•')[0]}</Text>}
        <View style={s.badge}><Text style={s.badgeT}>{channel.number || '—'}</Text></View>
        {!!channel.quality && <View style={s.q}><Text style={s.qT}>{channel.quality}</Text></View>}
      </View>
      <Text numberOfLines={1} style={s.name}>{channel.name}</Text>
      <Text numberOfLines={1} style={s.sub}>
        {[channel.country_name, channel.category_name].filter(Boolean).join(' · ')}
      </Text>
    </Pressable>
  );
}

const W = Platform.isTV ? 240 : 150;
const s = StyleSheet.create({
  card: { width: W, marginHorizontal: 6 },
  cardOn: { transform: [{ scale: Platform.isTV ? 1.08 : 1.03 }] },
  thumb: {
    width: W, height: W * 9 / 16, borderRadius: 10, backgroundColor: C.surface2,
    alignItems: 'center', justifyContent: 'center', overflow: 'hidden',
    borderWidth: 2, borderColor: 'transparent',
  },
  logo: { width: '82%', height: '72%' },
  init: { color: C.mut, fontSize: 34, fontWeight: '800' },
  badge: { position: 'absolute', bottom: 6, right: 6, backgroundColor: 'rgba(0,0,0,0.65)', borderRadius: 5, paddingHorizontal: 6, paddingVertical: 2 },
  badgeT: { color: '#ddd', fontWeight: '800', fontSize: 11 },
  q: { position: 'absolute', top: 6, left: 6, backgroundColor: 'rgba(0,0,0,0.6)', borderRadius: 4, paddingHorizontal: 5, paddingVertical: 1 },
  qT: { color: '#fff', fontWeight: '700', fontSize: 10 },
  name: { color: C.txt, fontSize: 13.5, fontWeight: '700', marginTop: 7, textAlign: 'right' },
  sub: { color: C.dim, fontSize: 11.5, marginTop: 2, textAlign: 'right' },
});
