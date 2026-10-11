import React, { useEffect, useRef } from 'react';
import { Animated, Easing } from 'react-native';
import Svg, { Defs, LinearGradient, Stop, Circle, Path, G } from 'react-native-svg';

// شعار MTC-iPTv — منقول من هوية الموقع: دائرة متدرّجة + مثلّث تشغيل + موجتا صوت + مدار منقّط بنقطة دوّارة.
const AG = Animated.createAnimatedComponent(G);

export default function LogoMark({ size = 96, spin = true }) {
  const rot = useRef(new Animated.Value(0)).current;
  const pulse = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    if (spin) Animated.loop(Animated.timing(rot, { toValue: 1, duration: 6000, easing: Easing.linear, useNativeDriver: true })).start();
    Animated.loop(Animated.sequence([
      Animated.timing(pulse, { toValue: 1, duration: 1400, easing: Easing.inOut(Easing.ease), useNativeDriver: true }),
      Animated.timing(pulse, { toValue: 0, duration: 1400, easing: Easing.inOut(Easing.ease), useNativeDriver: true }),
    ])).start();
  }, [spin, rot, pulse]);

  const spinDeg = rot.interpolate({ inputRange: [0, 1], outputRange: ['0deg', '360deg'] });
  const ripScale = pulse.interpolate({ inputRange: [0, 1], outputRange: [1, 1.18] });
  const ripOpacity = pulse.interpolate({ inputRange: [0, 1], outputRange: [0.9, 0.2] });

  return (
    <Svg width={size} height={size} viewBox="0 0 64 64">
      <Defs>
        <LinearGradient id="mg" gradientUnits="userSpaceOnUse" x1="8" y1="8" x2="56" y2="56">
          <Stop offset="0" stopColor="#ff2d55" />
          <Stop offset="0.5" stopColor="#ff5a36" />
          <Stop offset="1" stopColor="#ffb02e" />
        </LinearGradient>
      </Defs>

      {/* حلقة نابضة */}
      <AnimatedCircle cx="32" cy="32" r="11" fill="none" stroke="url(#mg)" strokeWidth="2"
        style={{ transform: [{ scale: ripScale }], opacity: ripOpacity, transformOrigin: '32px 32px' }} />

      {/* القرص المتدرّج + مثلّث التشغيل */}
      <Circle cx="32" cy="32" r="12.5" fill="url(#mg)" />
      <Path d="M28.5 25.5L38.5 32 28.5 38.5Z" fill="#fff" stroke="#fff" strokeWidth="3" strokeLinejoin="round" />

      {/* موجتا الصوت */}
      <G fill="none" stroke="url(#mg)" strokeWidth="3.8" strokeLinecap="round">
        <Path d="M44.26 21.72A16 16 0 0 1 44.26 42.28M19.74 42.28A16 16 0 0 1 19.74 21.72" />
        <Path d="M51.15 15.93A25 25 0 0 1 51.15 48.07M12.85 48.07A25 25 0 0 1 12.85 15.93" />
      </G>

      {/* المدار المنقّط + النقطة الدوّارة */}
      <Circle cx="32" cy="32" r="27.5" fill="none" stroke="#ff7a1a" strokeOpacity="0.25" strokeWidth="1" strokeDasharray="1.5 3" />
      <AG style={{ transform: [{ rotate: spinDeg }], transformOrigin: '32px 32px' }}>
        <Circle cx="32" cy="4.5" r="2.6" fill="#fff" />
      </AG>
    </Svg>
  );
}

const AnimatedCircle = Animated.createAnimatedComponent(Circle);
