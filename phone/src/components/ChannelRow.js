import React from 'react';
import { View, Text, FlatList, StyleSheet } from 'react-native';
import ChannelCard from './ChannelCard';
import { C } from '../theme';

// صف أفقي من القنوات (مثل صفوف الموقع): عنوان + تمرير جانبي.
export default function ChannelRow({ title, data, onPick, firstFocus }) {
  if (!data?.length) return null;
  return (
    <View style={s.row}>
      <Text style={s.title}>{title}</Text>
      <FlatList
        horizontal
        inverted                 // RTL: يبدأ من اليمين
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
  title: { color: C.txt, fontSize: 17, fontWeight: '800', marginBottom: 10, paddingHorizontal: 16, textAlign: 'right' },
  list: { paddingHorizontal: 10 },
});
