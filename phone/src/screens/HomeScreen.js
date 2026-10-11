import React, { useMemo } from 'react';
import { View, Text, ScrollView, StyleSheet } from 'react-native';
import ChannelRow from '../components/ChannelRow';
import Hero from '../components/Hero';
import LogoMark from '../ui/LogoMark';
import Wordmark from '../ui/Wordmark';
import { C } from '../theme';

export default function HomeScreen({ channels, settings, onPick }) {
  const rows = useMemo(() => build(channels), [channels]);
  const hero = useMemo(() => pickHero(channels, settings), [channels, settings]);
  return (
    <ScrollView style={s.wrap} contentContainerStyle={{ paddingBottom: 30 }} showsVerticalScrollIndicator={false}>
      <View style={s.head}>
        <View style={s.brand}>
          <LogoMark size={40} spin={false} />
          <Wordmark size={22} />
        </View>
        <View style={s.live}><View style={s.dot} /><Text style={s.liveT}>{channels.length.toLocaleString('ar-EG')} قناة</Text></View>
      </View>
      <Hero channel={hero} onPlay={onPick} />
      {rows.map((r, i) => (
        <ChannelRow key={r.key} title={r.title} icon={r.icon} data={r.items} onPick={onPick} firstFocus={i === 0} />
      ))}
    </ScrollView>
  );
}

function build(ch) {
  const out = [];
  const featured = ch.filter(c => c.is_featured);
  if (featured.length) out.push({ key: 'feat', title: 'قنوات مميزة', icon: 'star', items: featured.slice(0, 30) });

  const since = Date.now() - 30 * 864e5;
  const fresh = ch.filter(c => c.published_at && Date.parse(c.published_at) > since)
    .sort((a, b) => Date.parse(b.published_at) - Date.parse(a.published_at)).slice(0, 30);
  if (fresh.length) out.push({ key: 'fresh', title: 'مضافة حديثًا', icon: 'download', items: fresh });

  const byCat = groupBy(ch, c => c.category_name || 'عامة');
  for (const g of byCat.slice(0, 14)) out.push({ key: 'cat:' + g.name, title: g.name, icon: 'tv', items: g.items.slice(0, 30) });
  return out;
}
// قناة «يُعرض الآن»: المختارة من لوحة التحكم (settings.hero.channel_id)، وإلا قناة مميزة عشوائية.
function pickHero(ch, settings) {
  if (!ch?.length) return null;
  const chosen = settings?.hero?.channel_id && ch.find(c => c.id === settings.hero.channel_id);
  if (chosen) return chosen;
  const pool = ch.filter(c => c.is_featured && /^https:/i.test(c.logo_url || ''));
  const from = pool.length ? pool : ch.filter(c => /^https:/i.test(c.logo_url || ''));
  return from[Math.floor(Math.random() * from.length)] || ch[0];
}
function groupBy(list, keyFn) {
  const m = new Map();
  for (const c of list) { const k = keyFn(c); if (!m.has(k)) m.set(k, { name: k, items: [] }); m.get(k).items.push(c); }
  return [...m.values()].sort((a, b) => b.items.length - a.items.length);
}

const s = StyleSheet.create({
  wrap: { flex: 1, backgroundColor: C.bg },
  head: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 16, paddingTop: 16, paddingBottom: 16 },
  brand: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  live: { flexDirection: 'row-reverse', alignItems: 'center', gap: 6, backgroundColor: C.surface, borderRadius: 999, paddingHorizontal: 12, paddingVertical: 6, borderWidth: 1, borderColor: C.line },
  dot: { width: 7, height: 7, borderRadius: 4, backgroundColor: C.ac },
  liveT: { color: C.mut, fontSize: 12.5, fontWeight: '700' },
});
