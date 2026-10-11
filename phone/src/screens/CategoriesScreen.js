import React, { useMemo, useState } from 'react';
import { View, Text, Pressable, FlatList, StyleSheet } from 'react-native';
import ChannelGrid from '../components/ChannelGrid';
import { C } from '../theme';

// الفئات: قائمة بكل فئة وعدد قنواتها → الضغط يفتح قنوات تلك الفئة.
export default function CategoriesScreen({ channels, onPick }) {
  const [sel, setSel] = useState(null);

  const list = useMemo(() => {
    const m = new Map();
    for (const c of channels) {
      const k = c.category_name || 'عامة';
      if (!m.has(k)) m.set(k, { name: k, items: [] });
      m.get(k).items.push(c);
    }
    return [...m.values()].sort((a, b) => b.items.length - a.items.length);
  }, [channels]);

  if (sel) {
    const chs = sel.items.slice().sort((a, b) => a.number - b.number);
    return (
      <View style={s.wrap}>
        <Pressable style={s.back} onPress={() => setSel(null)}><Text style={s.backT}>‹ كل الفئات</Text></Pressable>
        <ChannelGrid data={chs} onPick={onPick} header={<Text style={s.h}>{sel.name} · {chs.length} قناة</Text>} />
      </View>
    );
  }

  return (
    <FlatList
      style={s.wrap}
      data={list}
      keyExtractor={g => g.name}
      contentContainerStyle={{ padding: 12, paddingBottom: 90 }}
      renderItem={({ item }) => (
        <Pressable style={s.row} onPress={() => setSel(item)}>
          <Text style={s.name}>{item.name}</Text>
          <Text style={s.n}>{item.items.length}</Text>
        </Pressable>
      )}
    />
  );
}

const s = StyleSheet.create({
  wrap: { flex: 1, backgroundColor: C.bg },
  row: { flexDirection: 'row-reverse', alignItems: 'center', paddingVertical: 14, paddingHorizontal: 14, borderBottomWidth: 1, borderBottomColor: C.line },
  name: { flex: 1, color: C.txt, fontSize: 16, textAlign: 'right' },
  n: { color: C.mut, fontSize: 14, fontWeight: '700' },
  back: { padding: 14 },
  backT: { color: C.ac, fontSize: 16, fontWeight: '700' },
  h: { color: C.txt, fontSize: 18, fontWeight: '800', paddingHorizontal: 6, paddingBottom: 12, textAlign: 'right' },
});
