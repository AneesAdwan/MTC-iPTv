import React from 'react';
import { FlatList, Text, StyleSheet, Platform } from 'react-native';
import ChannelCard from './ChannelCard';
import { C } from '../theme';

// شبكة رأسية من القنوات (للبحث والدول والفئات والمفضلة).
export default function ChannelGrid({ data, onPick, empty, header }) {
  const cols = Platform.isTV ? 6 : 3;
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
      initialNumToRender={18}
      windowSize={7}
      renderItem={({ item }) => <ChannelCard channel={item} onPress={onPick} />}
    />
  );
}

const s = StyleSheet.create({
  list: { padding: 10, paddingBottom: 90 },
  rowWrap: { justifyContent: 'flex-start', gap: 4, marginBottom: 14 },
  empty: { color: C.mut, textAlign: 'center', marginTop: 50, fontSize: 15 },
});
