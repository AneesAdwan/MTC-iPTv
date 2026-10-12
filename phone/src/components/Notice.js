import React, { useEffect, useRef } from 'react';
import { Animated, View, Text, Pressable, StyleSheet } from 'react-native';
import LinearGradient from 'react-native-linear-gradient';
import Icon from '../ui/Icon';
import { rs } from '../ui/responsive';
import { C, GRAD2 } from '../theme';

// شريط إشعار علوي: تحديث جديد متوفّر، أو قنوات جديدة أُضيفت. يظهر بنعومة ويُغلق.
export default function Notice({ update, freshCount, onDismiss, onShowFresh, onUpdate }) {
  const slide = useRef(new Animated.Value(0)).current;
  useEffect(() => { Animated.spring(slide, { toValue: 1, friction: 8, tension: 50, useNativeDriver: true }).start(); }, [slide]);
  if (!update && !freshCount) return null;

  const close = () => Animated.timing(slide, { toValue: 0, duration: 250, useNativeDriver: true }).start(onDismiss);
  const style = { transform: [{ translateY: slide.interpolate({ inputRange: [0, 1], outputRange: [-70, 0] }) }], opacity: slide };

  const isUpd = !!update;
  return (
    <Animated.View style={[s.wrap, style]}>
      <LinearGradient colors={isUpd ? GRAD2 : [C.surface2, C.surface]} start={{ x: 0, y: 0 }} end={{ x: 1, y: 0 }} style={s.card}>
        <Icon name={isUpd ? 'download' : 'zap'} size={rs(20)} color={isUpd ? '#fff' : C.ac2} />
        <Text style={[s.txt, { color: isUpd ? '#fff' : C.txt }]} numberOfLines={1}>
          {isUpd ? `تحديث جديد ${update.version} متوفّر` : `${freshCount} قناة جديدة أُضيفت`}
        </Text>
        <Pressable style={[s.btn, isUpd ? s.btnW : s.btnA]} onPress={() => { isUpd ? onUpdate?.() : onShowFresh?.(); close(); }}>
          <Text style={[s.btnT, { color: isUpd ? C.ac : '#fff' }]}>{isUpd ? 'تحديث' : 'عرض'}</Text>
        </Pressable>
        <Pressable onPress={close} style={s.x}><Icon name="x" size={16} color={isUpd ? '#fff' : C.mut} /></Pressable>
      </LinearGradient>
    </Animated.View>
  );
}

const s = StyleSheet.create({
  wrap: { position: 'absolute', top: 0, left: 0, right: 0, zIndex: 50, paddingHorizontal: 12, paddingTop: 10 },
  card: { flexDirection: 'row-reverse', alignItems: 'center', gap: 10, borderRadius: 14, paddingHorizontal: 14, paddingVertical: 12, borderWidth: 1, borderColor: C.line },
  txt: { flex: 1, fontSize: rs(14), fontWeight: '700', textAlign: 'right' },
  btn: { borderRadius: 999, paddingHorizontal: 16, paddingVertical: 7 },
  btnW: { backgroundColor: '#fff' },
  btnA: { backgroundColor: C.ac },
  btnT: { fontSize: 13.5, fontWeight: '800' },
  x: { padding: 4 },
});
