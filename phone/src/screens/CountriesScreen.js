import React, { useMemo, useState } from 'react';
import { View, Text, Pressable, Image, FlatList, StyleSheet } from 'react-native';
import ChannelGrid from '../components/ChannelGrid';
import { C } from '../theme';

// الدول: قائمة بكل دولة وعدد قنواتها → الضغط يفتح قنوات تلك الدولة.
export default function CountriesScreen({ channels, countries, onPick }) {
  const [sel, setSel] = useState(null);

  const counts = useMemo(() => {
    const m = new Map();
    for (const c of channels) m.set(c.country_code, (m.get(c.country_code) || 0) + 1);
    return m;
  }, [channels]);

  const list = useMemo(() =>
    (countries || [])
      .map(co => ({ ...co, n: counts.get(co.code) || 0 }))
      .filter(co => co.n > 0)
      .sort((a, b) => (b.is_arab - a.is_arab) || (a.sort_order - b.sort_order)),
    [countries, counts]);

  if (sel) {
    const chs = channels.filter(c => c.country_code === sel.code).sort((a, b) => a.number - b.number);
    return (
      <View style={s.wrap}>
        <Pressable style={s.back} onPress={() => setSel(null)}>
          <Text style={s.backT}>‹ كل الدول</Text>
        </Pressable>
        <ChannelGrid data={chs} onPick={onPick}
          header={<Text style={s.h}>{sel.name_ar} · {chs.length} قناة</Text>} />
      </View>
    );
  }

  return (
    <FlatList
      style={s.wrap}
      data={list}
      keyExtractor={co => co.code}
      contentContainerStyle={{ padding: 12, paddingBottom: 90 }}
      renderItem={({ item }) => (
        <Pressable style={s.row} onPress={() => setSel(item)}>
          {!!item.flag_url && <Image source={{ uri: item.flag_url }} style={s.flag} />}
          <Text style={s.name}>{item.name_ar}</Text>
          <Text style={s.n}>{item.n}</Text>
        </Pressable>
      )}
    />
  );
}

const s = StyleSheet.create({
  wrap: { flex: 1, backgroundColor: C.bg },
  row: {
    flexDirection: 'row-reverse', alignItems: 'center', gap: 12, paddingVertical: 12, paddingHorizontal: 14,
    borderBottomWidth: 1, borderBottomColor: C.line,
  },
  flag: { width: 30, height: 20, borderRadius: 3 },
  name: { flex: 1, color: C.txt, fontSize: 16, textAlign: 'right' },
  n: { color: C.mut, fontSize: 14, fontWeight: '700' },
  back: { padding: 14 },
  backT: { color: C.ac, fontSize: 16, fontWeight: '700' },
  h: { color: C.txt, fontSize: 18, fontWeight: '800', paddingHorizontal: 6, paddingBottom: 12, textAlign: 'right' },
});
