import React, { useEffect, useRef, useState } from 'react';
import { View, Text, Image, Animated, Easing, StyleSheet } from 'react-native';
import Svg, { Defs, RadialGradient, Stop, Rect } from 'react-native-svg';
import LogoMark from '../ui/LogoMark';
import Wordmark from '../ui/Wordmark';
import { APP_VERSION, COMPANY } from '../appVersion';
import { rs, isBig } from '../ui/responsive';
import { C } from '../theme';

const EMBLEM = require('../assets/mtc-group-emblem.png');
const GROUP_MS = 2100; // مدة عرض الشركة الأم قبل التحميل

// مقدمة الدخول: (1) الشركة الأم MTC-Group، ثم (2) شعار MTC-iPTv والتحميل.
export default function Splash({ status }) {
  const [phase, setPhase] = useState('group'); // 'group' ثم 'brand'
  useEffect(() => { const t = setTimeout(() => setPhase('brand'), GROUP_MS); return () => clearTimeout(t); }, []);
  return (
    <View style={s.wrap}>
      {phase === 'group' ? <GroupIntro /> : <BrandIntro status={status} />}
    </View>
  );
}

/* ───────── المشهد الأول: الشركة الأم ───────── */
function GroupIntro() {
  const a = useRef(new Animated.Value(0)).current;
  const halo = useRef(new Animated.Value(0)).current;
  useEffect(() => {
    Animated.timing(a, { toValue: 1, duration: 700, easing: Easing.out(Easing.cubic), useNativeDriver: true }).start();
    Animated.loop(Animated.sequence([
      Animated.timing(halo, { toValue: 1, duration: 1300, easing: Easing.inOut(Easing.ease), useNativeDriver: true }),
      Animated.timing(halo, { toValue: 0, duration: 1300, easing: Easing.inOut(Easing.ease), useNativeDriver: true }),
    ])).start();
  }, [a, halo]);
  const up = (d) => ({ opacity: a, transform: [{ translateY: a.interpolate({ inputRange: [0, 1], outputRange: [d, 0] }) }] });
  const haloStyle = { opacity: halo.interpolate({ inputRange: [0, 1], outputRange: [0.3, 0.7] }), transform: [{ scale: halo.interpolate({ inputRange: [0, 1], outputRange: [0.95, 1.1] }) }] };
  return (
    <View style={s.center}>
      <Animated.Text style={[s.present, up(10)]}>تقدّم · إحدى شركات</Animated.Text>
      <View style={s.emblemWrap}>
        <Animated.View style={[s.emblemHalo, haloStyle]}>
          <Svg width="100%" height="100%"><Defs><RadialGradient id="g" cx="50%" cy="50%" r="50%">
            <Stop offset="0" stopColor="#ff7a1a" stopOpacity="0.5" /><Stop offset="1" stopColor="#08080c" stopOpacity="0" />
          </RadialGradient></Defs><Rect width="100%" height="100%" fill="url(#g)" /></Svg>
        </Animated.View>
        <Animated.Image source={EMBLEM} style={[s.emblem, { opacity: a, transform: [{ scale: a.interpolate({ inputRange: [0, 1], outputRange: [0.7, 1] }) }] }]} resizeMode="contain" />
      </View>
      <Animated.Text style={[s.group, up(12)]}>MTC<Text style={{ color: C.ac2 }}>-Group</Text></Animated.Text>
      <Animated.Text style={[s.groupAr, up(14)]}>{COMPANY.ar}</Animated.Text>
      <Animated.View style={[s.rule, { opacity: a }]} />
      <Animated.Text style={[s.groupEn, up(14)]}>{COMPANY.en}</Animated.Text>
    </View>
  );
}

/* ───────── المشهد الثاني: العلامة والتحميل ───────── */
function BrandIntro({ status }) {
  const logo = useRef(new Animated.Value(0)).current;
  const word = useRef(new Animated.Value(0)).current;
  const halo = useRef(new Animated.Value(0)).current;
  const prog = useRef(new Animated.Value(0)).current;
  useEffect(() => {
    Animated.stagger(150, [
      Animated.spring(logo, { toValue: 1, friction: 7, tension: 55, useNativeDriver: true }),
      Animated.timing(word, { toValue: 1, duration: 500, easing: Easing.out(Easing.cubic), useNativeDriver: true }),
    ]).start();
    Animated.loop(Animated.sequence([
      Animated.timing(halo, { toValue: 1, duration: 1500, easing: Easing.inOut(Easing.ease), useNativeDriver: true }),
      Animated.timing(halo, { toValue: 0, duration: 1500, easing: Easing.inOut(Easing.ease), useNativeDriver: true }),
    ])).start();
    Animated.timing(prog, { toValue: 1, duration: 1600, easing: Easing.inOut(Easing.cubic), useNativeDriver: false }).start();
  }, [logo, word, halo, prog]);
  const logoStyle = { opacity: logo, transform: [{ scale: logo.interpolate({ inputRange: [0, 1], outputRange: [0.6, 1] }) }] };
  const wordStyle = { opacity: word, transform: [{ translateY: word.interpolate({ inputRange: [0, 1], outputRange: [14, 0] }) }] };
  const haloStyle = { opacity: halo.interpolate({ inputRange: [0, 1], outputRange: [0.45, 0.85] }), transform: [{ scale: halo.interpolate({ inputRange: [0, 1], outputRange: [0.92, 1.08] }) }] };
  const progW = prog.interpolate({ inputRange: [0, 1], outputRange: ['6%', '100%'] });
  return (
    <>
      <Animated.View style={[s.brandHalo, haloStyle]}>
        <Svg width="100%" height="100%"><Defs><RadialGradient id="b" cx="50%" cy="50%" r="50%">
          <Stop offset="0" stopColor="#ff2d55" stopOpacity="0.55" /><Stop offset="0.5" stopColor="#ff7a1a" stopOpacity="0.15" /><Stop offset="1" stopColor="#08080c" stopOpacity="0" />
        </RadialGradient></Defs><Rect width="100%" height="100%" fill="url(#b)" /></Svg>
      </Animated.View>
      <View style={s.center}>
        <Animated.View style={logoStyle}><LogoMark size={rs(120)} /></Animated.View>
        <Animated.View style={[wordStyle, { marginTop: rs(24) }]}><Wordmark size={rs(32)} /></Animated.View>
        <Animated.Text style={[s.tag, wordStyle]}>بثّ مباشر · آلاف القنوات من حول العالم</Animated.Text>
      </View>
      <View style={s.bottom}>
        <View style={s.track}><Animated.View style={[s.fill, { width: progW }]} /></View>
        <Text style={s.status}>{status || 'جارٍ التحميل…'}</Text>
      </View>
      <Text style={s.ver}>الإصدار {APP_VERSION}</Text>
    </>
  );
}

const s = StyleSheet.create({
  wrap: { flex: 1, backgroundColor: C.bg, alignItems: 'center', justifyContent: 'center' },
  center: { alignItems: 'center', paddingHorizontal: 30 },
  // الشركة الأم
  present: { color: C.dim, fontSize: rs(13), letterSpacing: 1, marginBottom: rs(18) },
  emblemWrap: { width: rs(140), height: rs(140), alignItems: 'center', justifyContent: 'center' },
  emblemHalo: { position: 'absolute', width: '160%', height: '160%' },
  emblem: { width: '100%', height: '100%' },
  group: { color: '#fff', fontSize: rs(30), fontWeight: '900', marginTop: rs(18), writingDirection: 'ltr' },
  groupAr: { color: C.mut, fontSize: rs(14), marginTop: rs(10), textAlign: 'center' },
  rule: { width: rs(60), height: 2, borderRadius: 2, backgroundColor: C.ac, opacity: 0.6, marginVertical: rs(12) },
  groupEn: { color: C.dim, fontSize: rs(11.5), letterSpacing: 0.5, writingDirection: 'ltr', textAlign: 'center' },
  // العلامة
  brandHalo: { position: 'absolute', width: 420, height: 420, top: '18%' },
  tag: { color: C.mut, fontSize: rs(13.5), marginTop: rs(12), textAlign: 'center' },
  bottom: { position: 'absolute', bottom: rs(64), alignItems: 'center', gap: 12, width: 200 },
  track: { width: '100%', height: 3, borderRadius: 3, backgroundColor: C.surface2, overflow: 'hidden' },
  fill: { height: '100%', backgroundColor: C.ac, borderRadius: 3 },
  status: { color: C.dim, fontSize: 13 },
  ver: { position: 'absolute', bottom: 22, color: C.dim, fontSize: 11.5 },
});
