import React, { useMemo } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import ChannelGrid from '../components/ChannelGrid';
import { C } from '../theme';

// المفضلة: القنوات التي حفظها المستخدم (محفوظة على الجهاز).
export default function FavoritesScreen({ channels, favorites, onPick }) {
  const data = useMemo(
    () => channels.filter(c => favorites.has(c.id)).sort((a, b) => a.number - b.number),
    [channels, favorites]);
  return (
    <View style={s.wrap}>
      <Text style={s.h}>♥ المفضلة</Text>
      <ChannelGrid data={data} onPick={onPick}
        empty="لم تضف أي قناة للمفضلة بعد. افتح قناة واضغط ♥ لإضافتها." />
    </View>
  );
}

const s = StyleSheet.create({
  wrap: { flex: 1, backgroundColor: C.bg },
  h: { color: C.txt, fontSize: 20, fontWeight: '800', padding: 16, paddingBottom: 4, textAlign: 'right' },
});
