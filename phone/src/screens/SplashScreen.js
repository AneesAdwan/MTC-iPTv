import React, { useEffect, useRef } from 'react';
import { View, Text, Animated, Easing, StyleSheet, Dimensions } from 'react-native';
import LinearGradient from 'react-native-linear-gradient';
import LogoMark from '../ui/LogoMark';
import Wordmark from '../ui/Wordmark';
import { APP_VERSION } from '../appVersion';
import { C } from '../theme';

const { width } = Dimensions.get('window');

// شاشة البداية الفخمة: توهّج متدرّج + شعار يكبر ويظهر + الاسم يصعد + نص التحميل.
export default function Splash({ status }) {
  const logo = useRef(new Animated.Value(0)).current;
  const word = useRef(new Animated.Value(0)).current;
  const glow = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    Animated.sequence([
      Animated.spring(logo, { toValue: 1, friction: 6, tension: 60, useNativeDriver: true }),
      Animated.timing(word, { toValue: 1, duration: 500, easing: Easing.out(Easing.cubic), useNativeDriver: true }),
    ]).start();
    Animated.loop(Animated.sequence([
      Animated.timing(glow, { toValue: 1, duration: 1800, easing: Easing.inOut(Easing.ease), useNativeDriver: true }),
      Animated.timing(glow, { toValue: 0, duration: 1800, easing: Easing.inOut(Easing.ease), useNativeDriver: true }),
    ])).start();
  }, [logo, word, glow]);

  const logoStyle = {
    opacity: logo,
    transform: [{ scale: logo.interpolate({ inputRange: [0, 1], outputRange: [0.5, 1] }) }],
  };
  const wordStyle = {
    opacity: word,
    transform: [{ translateY: word.interpolate({ inputRange: [0, 1], outputRange: [16, 0] }) }],
  };
  const glowStyle = { opacity: glow.interpolate({ inputRange: [0, 1], outputRange: [0.25, 0.55] }) };

  return (
    <View style={s.wrap}>
      <Animated.View style={[s.glow, glowStyle]}>
        <LinearGradient colors={['rgba(255,45,85,0.5)', 'rgba(255,122,26,0.15)', 'transparent']}
          style={s.glowInner} start={{ x: 0.5, y: 0.2 }} end={{ x: 0.5, y: 1 }} />
      </Animated.View>

      <Animated.View style={logoStyle}><LogoMark size={128} /></Animated.View>
      <Animated.View style={[wordStyle, { marginTop: 22 }]}><Wordmark size={34} /></Animated.View>
      <Animated.Text style={[s.tag, wordStyle]}>بثّ مباشر من كل العالم</Animated.Text>

      <View style={s.bottom}>
        <View style={s.bar}><Animated.View style={[s.barFill, { opacity: glow }]} /></View>
        <Text style={s.status}>{status || 'جارٍ التحميل…'}</Text>
      </View>
      <Text style={s.ver}>الإصدار {APP_VERSION}</Text>
    </View>
  );
}

const s = StyleSheet.create({
  wrap: { flex: 1, backgroundColor: C.bg, alignItems: 'center', justifyContent: 'center' },
  glow: { position: 'absolute', top: 0, width, height: '70%' },
  glowInner: { flex: 1 },
  tag: { color: C.mut, fontSize: 14, marginTop: 10 },
  bottom: { position: 'absolute', bottom: 60, alignItems: 'center', gap: 12 },
  bar: { width: 140, height: 3, borderRadius: 3, backgroundColor: C.surface2, overflow: 'hidden' },
  barFill: { width: '60%', height: '100%', backgroundColor: C.ac, borderRadius: 3 },
  status: { color: C.dim, fontSize: 13 },
  ver: { position: 'absolute', bottom: 22, color: C.dim, fontSize: 11.5 },
});
