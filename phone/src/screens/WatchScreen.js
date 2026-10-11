import React, { useEffect, useMemo, useRef, useState } from 'react';
import { View, Text, Pressable, StyleSheet, ActivityIndicator, Platform, BackHandler } from 'react-native';
import Video from 'react-native-video';
import { fetchStreams, proxied } from '../lib/catalog';
import { C } from '../theme';

// شاشة المشاهدة: مشغّل HLS أصلي (ExoPlayer على أندرويد، AVPlayer على iOS/الأجهزة)،
// مع تبديل تلقائي بين السيرفرات عند الفشل، وأزرار القناة التالية/السابقة.
export default function WatchScreen({ channel, settings, onBack, onZap, isFav, onToggleFav }) {
  const [streams, setStreams] = useState(null);
  const [si, setSi] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);
  const [showInfo, setShowInfo] = useState(true);
  const infoT = useRef(null);

  useEffect(() => {
    let alive = true;
    setStreams(null); setSi(0); setLoading(true); setError(false); flashInfo();
    fetchStreams(channel.id)
      .then(list => { if (alive) { setStreams(list); if (!list.length) setError(true); } })
      .catch(() => alive && setError(true));
    return () => { alive = false; };
  }, [channel.id]);

  // زر الرجوع في الريموت/الجهاز يغلق المشاهدة
  useEffect(() => {
    const sub = BackHandler.addEventListener('hardwareBackPress', () => { onBack(); return true; });
    return () => sub.remove();
  }, [onBack]);

  const flashInfo = () => {
    setShowInfo(true);
    clearTimeout(infoT.current);
    infoT.current = setTimeout(() => setShowInfo(false), 6000); // شريط القناة يختفي بعد 6 ثوانٍ
  };

  const src = useMemo(() => {
    const s = streams?.[si];
    return s ? proxied(s.url, settings?.proxy) : null;
  }, [streams, si, settings]);

  const onVideoError = () => {
    if (streams && si + 1 < streams.length) setSi(si + 1); // جرّب السيرفر التالي
    else setError(true);
  };

  return (
    <View style={s.wrap}>
      {src && !error && (
        <Video
          source={{ uri: src }}
          style={StyleSheet.absoluteFill}
          resizeMode="contain"
          paused={false}
          playInBackground={false}
          onLoad={() => setLoading(false)}
          onError={onVideoError}
          onBuffer={({ isBuffering }) => setLoading(isBuffering)}
          ignoreSilentSwitch="ignore"
        />
      )}

      {loading && !error && <ActivityIndicator size="large" color={C.ac} style={StyleSheet.absoluteFill} />}

      {error && (
        <View style={[StyleSheet.absoluteFill, s.center]}>
          <Text style={s.errT}>تعذّر تشغيل هذه القناة حاليًا</Text>
          <Pressable style={s.btn} onPress={() => { setError(false); setSi(0); }} hasTVPreferredFocus>
            <Text style={s.btnT}>إعادة المحاولة</Text>
          </Pressable>
        </View>
      )}

      {/* طبقة لمس/تركيز لإظهار المعلومات والتحكم */}
      <Pressable style={StyleSheet.absoluteFill} onPress={flashInfo} focusable={false} />

      {showInfo && (
        <View style={s.bar} pointerEvents="box-none">
          <View style={s.info}>
            <View style={s.num}><Text style={s.numT}>{channel.number}</Text></View>
            <View style={{ flex: 1 }}>
              <Text style={s.title} numberOfLines={1}>{channel.name}</Text>
              <Text style={s.meta} numberOfLines={1}>
                {[channel.country_name, channel.category_name, channel.quality].filter(Boolean).join(' · ')}
                {streams?.length > 1 ? `  ·  سيرفر ${si + 1}/${streams.length}` : ''}
              </Text>
            </View>
          </View>
          <View style={s.ctrls}>
            <Ctrl label="‹ السابقة" onPress={() => onZap(-1)} />
            <Ctrl label={isFav ? '♥ في المفضلة' : '♡ المفضلة'} onPress={onToggleFav} />
            <Ctrl label="رجوع" onPress={onBack} />
            <Ctrl label="التالية ›" onPress={() => onZap(1)} focus />
          </View>
        </View>
      )}
    </View>
  );
}

function Ctrl({ label, onPress, focus }) {
  const [f, setF] = useState(false);
  return (
    <Pressable onPress={onPress} onFocus={() => setF(true)} onBlur={() => setF(false)}
      hasTVPreferredFocus={focus} style={[s.ctrl, f && s.ctrlOn]}>
      <Text style={s.ctrlT}>{label}</Text>
    </Pressable>
  );
}

const s = StyleSheet.create({
  wrap: { flex: 1, backgroundColor: '#000' },
  center: { alignItems: 'center', justifyContent: 'center', gap: 16 },
  errT: { color: C.txt, fontSize: 18 },
  bar: { position: 'absolute', left: 0, right: 0, bottom: 0, padding: 20, backgroundColor: 'rgba(0,0,0,0.55)' },
  info: { flexDirection: 'row-reverse', alignItems: 'center', gap: 14 },
  num: { backgroundColor: C.ac, borderRadius: 10, paddingHorizontal: 14, paddingVertical: 8 },
  numT: { color: '#fff', fontSize: 24, fontWeight: '900' },
  title: { color: '#fff', fontSize: 22, fontWeight: '800', textAlign: 'right' },
  meta: { color: 'rgba(255,255,255,0.75)', fontSize: 14, marginTop: 3, textAlign: 'right' },
  ctrls: { flexDirection: 'row-reverse', gap: 12, marginTop: 16 },
  ctrl: { backgroundColor: 'rgba(255,255,255,0.12)', borderRadius: 10, paddingHorizontal: 20, paddingVertical: 12, borderWidth: 2, borderColor: 'transparent' },
  ctrlOn: { borderColor: '#fff', backgroundColor: C.ac },
  ctrlT: { color: '#fff', fontSize: 16, fontWeight: '700' },
  btn: { backgroundColor: C.ac, borderRadius: 12, paddingHorizontal: 28, paddingVertical: 14 },
  btnT: { color: '#fff', fontSize: 16, fontWeight: '800' },
});
