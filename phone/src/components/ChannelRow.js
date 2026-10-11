import React from 'react';
import { View, Text, FlatList, StyleSheet } from 'react-native';
import ChannelCard from './ChannelCard';
import Icon from '../ui/Icon';
import { C } from '../theme';

// صف أفقي بعنوان وأيقونة ملوّنة وشريط صغير متدرّج (مثل صفوف الموقع).
export default function ChannelRow({ title, icon, data, onPick, firstFocus }) {
  if (!data?.length) return null;
  return (
    <View style={s.row}>
      <View style={s.head}>
        <View style={s.accent} />
        {!!icon && <Icon name={icon} size={17} color={C.ac2} />}
        <Text style={s.title}>{title}</Text>
      </View>
      <FlatList
        horizontal
        inverted
        data={data}
        keyExtractor={c => String(c.id)}
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={s.list}
        renderItem={({ item, index }) => (
          <ChannelCard channel={item} onPress={onPick} hasTVPreferredFocus={firstFocus && index === 0} />
        )}
      />
    </View>
  );
}

const s = StyleSheet.create({
  row: { marginBottom: 22 },
  head: { flexDirection: 'row-reverse', alignItems: 'center', gap: 8, marginBottom: 10, paddingHorizontal: 16 },
  accent: { width: 4, height: 18, borderRadius: 2, backgroundColor: C.ac },
  title: { color: C.txt, fontSize: 17, fontWeight: '800' },
  list: { paddingHorizontal: 10 },
});
