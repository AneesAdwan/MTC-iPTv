import React, { useMemo, useRef, useState, useEffect } from 'react';
import { View, Text, TextInput, Pressable, Image, FlatList, StyleSheet, Animated, Dimensions } from 'react-native';
import Icon from '../ui/Icon';
import { rs } from '../ui/responsive';
import { C } from '../theme';

const { width } = Dimensions.get('window');

// قائمة القنوات — تنزلق من اليسار (كالتلفاز). بحث + تمييز القناة الحالية. تُستخدم بالوضعين.
export default function ChannelListDrawer({ channels, currentId, onPick, onClose, fullscreen }) {
  const [q, setQ] = useState('');
  const x = useRef(new Animated.Value(-1)).current;
  const W = fullscreen ? Math.min(360, width * 0.42) : Math.min(340, width * 0.86);

  useEffect(() => { Animated.spring(x, { toValue: 0, friction: 9, tension: 60, useNativeDriver: true }).start(); }, [x]);
  const close = () => Animated.timing(x, { toValue: -1, duration: 220, useNativeDriver: true }).start(onClose);

  const data = useMemo(() => {
    const t = q.trim().toLowerCase();
    const list = t
      ? channels.filter(c => c.name?.toLowerCase().includes(t) || String(c.number) === t || String(c.number).startsWith(t))
      : channels;
    return list.slice(0, 400);
  }, [q, channels]);

  const tx = x.interpolate({ inputRange: [-1, 0], outputRange: [-W - 10, 0] });

  return (
    <View style={styles.overlay}>
      <Pressable style={StyleSheet.absoluteFill} onPress={close} />
      <Animated.View style={[styles.panel, { width: W, transform: [{ translateX: tx }] }]}>
        <View style={styles.head}>
          <Text style={styles.title}>قائمة القنوات</Text>
          <Pressable onPress={close} style={styles.x}><Icon name="x" size={rs(18)} color={C.mut} /></Pressable>
        </View>
        <View style={styles.searchBox}>
          <Icon name="search" size={rs(15)} color={C.dim} />
          <TextInput style={styles.search} value={q} onChangeText={setQ} placeholder="ابحث بالاسم أو الرقم…"
            placeholderTextColor={C.dim} textAlign="right" />
        </View>
        <FlatList
          data={data}
          keyExtractor={c => String(c.id)}
          initialNumToRender={20}
          windowSize={10}
          renderItem={({ item }) => {
            const on = item.id === currentId;
            const logo = /^https:/i.test(item.logo_url || '') ? item.logo_url : null;
            return (
              <Pressable onPress={() => onPick(item)} style={[styles.row, on && styles.rowOn]}>
                <Text style={[styles.num, on && { color: '#fff' }]}>{item.number}</Text>
                <View style={styles.logo}>
                  {logo ? <Image source={{ uri: logo }} style={{ width: '82%', height: '82%' }} resizeMode="contain" />
                    : <Text style={styles.init}>{(item.name || '•')[0]}</Text>}
                </View>
                <View style={{ flex: 1 }}>
                  <Text numberOfLines={1} style={[styles.name, on && { color: '#fff' }]}>{item.name}</Text>
                  <Text numberOfLines={1} style={styles.sub}>{[item.country_name, item.category_name].filter(Boolean).join(' · ')}</Text>
                </View>
                {on && <View style={styles.playing}><Icon name="play" size={rs(13)} color={C.ac} /></View>}
              </Pressable>
            );
          }}
        />
      </Animated.View>
    </View>
  );
}

const styles = StyleSheet.create({
  overlay: { ...StyleSheet.absoluteFillObject, zIndex: 60, flexDirection: 'row' },
  panel: { height: '100%', backgroundColor: 'rgba(12,12,18,0.98)', borderRightWidth: 1, borderRightColor: C.line2 },
  head: { flexDirection: 'row-reverse', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 14, paddingTop: 16, paddingBottom: 10 },
  title: { color: '#fff', fontSize: rs(17), fontWeight: '800' },
  x: { padding: 4 },
  searchBox: { flexDirection: 'row-reverse', alignItems: 'center', gap: 8, marginHorizontal: 12, marginBottom: 8, paddingHorizontal: 12, height: 42, borderRadius: 10, backgroundColor: C.surface, borderWidth: 1, borderColor: C.line },
  search: { flex: 1, color: C.txt, fontSize: rs(14) },
  row: { flexDirection: 'row-reverse', alignItems: 'center', gap: 10, paddingHorizontal: 12, paddingVertical: 8, borderBottomWidth: 1, borderBottomColor: 'rgba(255,255,255,0.05)' },
  rowOn: { backgroundColor: 'rgba(255,45,85,0.14)' },
  num: { width: 34, textAlign: 'center', color: C.dim, fontSize: rs(13), fontWeight: '800' },
  logo: { width: rs(40), height: rs(40), borderRadius: 8, backgroundColor: C.surface2, alignItems: 'center', justifyContent: 'center', overflow: 'hidden' },
  init: { color: C.mut, fontSize: rs(16), fontWeight: '800' },
  name: { color: C.txt, fontSize: rs(14), fontWeight: '700', textAlign: 'right' },
  sub: { color: C.dim, fontSize: rs(11), marginTop: 1, textAlign: 'right' },
  playing: { width: 22, height: 22, borderRadius: 11, backgroundColor: 'rgba(255,45,85,0.18)', alignItems: 'center', justifyContent: 'center' },
});
