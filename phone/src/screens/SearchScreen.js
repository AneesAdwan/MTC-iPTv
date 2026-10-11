import React, { useMemo, useState } from 'react';
import { View, TextInput, StyleSheet } from 'react-native';
import ChannelGrid from '../components/ChannelGrid';
import { C } from '../theme';

// البحث بالاسم أو رقم القناة (مثل الموقع).
export default function SearchScreen({ channels, onPick }) {
  const [q, setQ] = useState('');
  const results = useMemo(() => {
    const t = q.trim().toLowerCase();
    if (!t) return [];
    if (/^\d+$/.test(t)) return channels.filter(c => String(c.number) === t || String(c.number).startsWith(t)).slice(0, 120);
    return channels.filter(c =>
      c.name?.toLowerCase().includes(t) ||
      c.network?.toLowerCase().includes(t) ||
      c.country_name?.toLowerCase().includes(t)
    ).slice(0, 120);
  }, [q, channels]);

  return (
    <View style={s.wrap}>
      <TextInput
        style={s.input}
        value={q}
        onChangeText={setQ}
        placeholder="ابحث عن قناة بالاسم أو الرقم…"
        placeholderTextColor={C.dim}
        autoFocus
        textAlign="right"
      />
      <ChannelGrid data={results} onPick={onPick}
        empty={q ? 'لا توجد قنوات مطابقة.' : 'اكتب اسم قناة أو رقمها للبحث.'} />
    </View>
  );
}

const s = StyleSheet.create({
  wrap: { flex: 1, backgroundColor: C.bg },
  input: {
    margin: 14, paddingHorizontal: 16, height: 48, borderRadius: 12,
    backgroundColor: C.surface, color: C.txt, fontSize: 16, borderWidth: 1, borderColor: C.line,
  },
});
