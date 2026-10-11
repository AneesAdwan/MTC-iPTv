import React, { useMemo } from 'react';
import { View, Text, ScrollView, StyleSheet, Image } from 'react-native';
import ChannelRow from '../components/ChannelRow';
import { C } from '../theme';

// الصفحة الرئيسية: صفوف شبيهة بالموقع (مميزة، مضافة حديثًا، حسب الفئة والدولة).
export default function HomeScreen({ channels, onPick }) {
  const rows = useMemo(() => build(channels), [channels]);
  return (
    <ScrollView style={s.wrap} contentContainerStyle={{ paddingBottom: 40 }}>
      <View style={s.head}>
        <Text style={s.brand}>MTC-iPTv</Text>
        <Text style={s.count}>{channels.length.toLocaleString('ar-EG')} قناة مباشرة</Text>
      </View>
      {rows.map((r, i) => (
        <ChannelRow key={r.key} title={r.title} data={r.items} onPick={onPick} firstFocus={i === 0} />
      ))}
    </ScrollView>
  );
}

function build(ch) {
  const out = [];
  const featured = ch.filter(c => c.is_featured);
  if (featured.length) out.push({ key: 'feat', title: '★ قنوات مميزة', items: featured.slice(0, 30) });

  const since = Date.now() - 30 * 864e5;
  const fresh = ch.filter(c => c.published_at && Date.parse(c.published_at) > since)
    .sort((a, b) => Date.parse(b.published_at) - Date.parse(a.published_at)).slice(0, 30);
  if (fresh.length) out.push({ key: 'fresh', title: '+ مضافة حديثًا', items: fresh });

  const byCat = groupBy(ch, c => c.category_name || 'عامة');
  for (const g of byCat.slice(0, 12)) out.push({ key: 'cat:' + g.name, title: g.name, items: g.items.slice(0, 30) });
  return out;
}
function groupBy(list, keyFn) {
  const m = new Map();
  for (const c of list) { const k = keyFn(c); if (!m.has(k)) m.set(k, { name: k, items: [] }); m.get(k).items.push(c); }
  return [...m.values()].sort((a, b) => b.items.length - a.items.length);
}

const s = StyleSheet.create({
  wrap: { flex: 1, backgroundColor: C.bg },
  head: { paddingHorizontal: 16, paddingTop: 18, paddingBottom: 14, flexDirection: 'row-reverse', alignItems: 'baseline', gap: 12 },
  brand: { color: C.ac, fontSize: 26, fontWeight: '900' },
  count: { color: C.mut, fontSize: 13 },
});
