import React from 'react';
import { View, Text, Pressable, StyleSheet, Platform } from 'react-native';
import { C } from '../theme';

const TABS = [
  { k: 'home', label: 'الرئيسية', icon: '⌂' },
  { k: 'search', label: 'بحث', icon: '🔍' },
  { k: 'countries', label: 'الدول', icon: '🌍' },
  { k: 'categories', label: 'الفئات', icon: '▦' },
  { k: 'favorites', label: 'المفضلة', icon: '♥' },
];

// شريط تنقّل سفلي بسيط (يختفي في وضع المشاهدة).
export default function BottomNav({ tab, onChange }) {
  return (
    <View style={s.bar}>
      {TABS.map(t => {
        const on = tab === t.k;
        return (
          <Pressable key={t.k} style={s.item} onPress={() => onChange(t.k)}>
            <Text style={[s.icon, on && s.onC]}>{t.icon}</Text>
            <Text style={[s.label, on && s.onC]}>{t.label}</Text>
          </Pressable>
        );
      })}
    </View>
  );
}

const s = StyleSheet.create({
  bar: {
    flexDirection: 'row-reverse', backgroundColor: C.bg2, borderTopWidth: 1, borderTopColor: C.line,
    paddingBottom: Platform.OS === 'ios' ? 22 : 8, paddingTop: 8,
  },
  item: { flex: 1, alignItems: 'center', gap: 3 },
  icon: { fontSize: 20, color: C.dim },
  label: { fontSize: 11, color: C.dim },
  onC: { color: C.ac },
});
