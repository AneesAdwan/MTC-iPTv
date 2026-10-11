import React from 'react';
import { View, Text, Pressable, StyleSheet, Platform } from 'react-native';
import LinearGradient from 'react-native-linear-gradient';
import Icon from '../ui/Icon';
import { C, GRAD2 } from '../theme';

const TABS = [
  { k: 'home', label: 'الرئيسية', icon: 'home' },
  { k: 'search', label: 'بحث', icon: 'search' },
  { k: 'countries', label: 'الدول', icon: 'globe' },
  { k: 'categories', label: 'الفئات', icon: 'grid' },
  { k: 'favorites', label: 'المفضلة', icon: 'heart' },
];

// شريط تنقّل سفلي فخم: الأيقونة النشطة داخل حبّة متدرّجة.
export default function BottomNav({ tab, onChange }) {
  return (
    <View style={s.bar}>
      {TABS.map(t => {
        const on = tab === t.k;
        return (
          <Pressable key={t.k} style={s.item} onPress={() => onChange(t.k)}>
            {on ? (
              <LinearGradient colors={GRAD2} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={s.pill}>
                <Icon name={t.icon} size={21} color="#fff" />
              </LinearGradient>
            ) : (
              <View style={s.pill}><Icon name={t.icon} size={21} color={C.dim} /></View>
            )}
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
    paddingBottom: Platform.OS === 'ios' ? 24 : 10, paddingTop: 8, paddingHorizontal: 6,
  },
  item: { flex: 1, alignItems: 'center', gap: 4 },
  pill: { width: 46, height: 32, borderRadius: 999, alignItems: 'center', justifyContent: 'center' },
  label: { fontSize: 11, color: C.dim, fontWeight: '600' },
  onC: { color: C.ac },
});
