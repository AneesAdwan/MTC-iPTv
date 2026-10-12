import React from 'react';
import { FlatList, Text, StyleSheet, Dimensions } from 'react-native';
import ChannelCard from './ChannelCard';
import { gridCols } from '../ui/responsive';
import { C } from '../theme';

// شبكة رأسية متجاوبة (عدد الأعمدة حسب حجم الشاشة).
export default function ChannelGrid({ data, onPick, empty, header }) {
  const cols = gridCols;
  const cardW = (Dimensions.get('window').width - 20 - cols * 12) / cols;
  if (!data?.length) return <Text style={s.empty}>{empty || 'لا توجد قنوات.'}</Text>;
  return (
    <FlatList
      data={data}
      key={cols}
      numColumns={cols}
      keyExtractor={c => String(c.id)}
      ListHeaderComponent={header}
      columnWrapperStyle={s.rowWrap}
      contentContainerStyle={s.list}
      removeClippedSubviews
      initialNumToRender={cols * 6}
      windowSize={7}
      renderItem={({ item }) => <ChannelCard channel={item} onPress={onPick} width={cardW} />}
    />
  );
}

const s = StyleSheet.create({
  list: { padding: 10, paddingBottom: 90 },
  rowWrap: { justifyContent: 'flex-start', marginBottom: 16 },
  empty: { color: C.mut, textAlign: 'center', marginTop: 50, fontSize: 15 },
});
