import React, { useEffect, useMemo, useRef, useState } from 'react';
import { View, Text, Pressable, StyleSheet, ActivityIndicator, Image, Animated, StatusBar, BackHandler, Dimensions } from 'react-native';
import Video from 'react-native-video';
import LinearGradient from 'react-native-linear-gradient';
import Icon from '../ui/Icon';
import LogoMark from '../ui/LogoMark';
import ChannelListDrawer from '../components/ChannelListDrawer';
import { SW, SH, videoH, rs } from '../ui/responsive';
import { fetchStreams, proxied } from '../lib/catalog';
import { C } from '../theme';

// مشغّل كامل: أزرار (تشغيل/إيقاف، تكبير/تصغير، التالي/السابق، المفضلة، قائمة القنوات)،
// شريط اسم القناة عند الفتح (كالتلفاز)، لوجو الشركة، وقائمة قنوات تنزلق من اليسار في وضع التكبير.
export default function WatchScreen({ channel, channels, settings, onBack, onZap, onPick, isFav, onToggleFav }) {
  const [streams, setStreams] = useState(null);
  const [si, setSi] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);
  const [paused, setPaused] = useState(false);
  const [fs, setFs] = useState(false);          // وضع التكبير (ملء الشاشة)
  const [listOpen, setListOpen] = useState(false);
  const [ctl, setCtl] = useState(true);         // ظهور أزرار التحكم
  const banner = useRef(new Animated.Value(0)).current;
  const ctlT = useRef(null);
  const bannerT = useRef(null);

  useEffect(() => {
    let alive = true;
    setStreams(null); setSi(0); setLoading(true); setError(false); setPaused(false);
    fetchStreams(channel.id).then(l => { if (alive) { setStreams(l); if (!l.length) setError(true); } }).catch(() => alive && setError(true));
    showBanner(); flashCtl();
    return () => { alive = false; clearTimeout(bannerT.current); clearTimeout(ctlT.current); };
  }, [channel.id]);

  useEffect(() => {
    const sub = BackHandler.addEventListener('hardwareBackPress', () => {
      if (listOpen) { setListOpen(false); return true; }
      if (fs) { setFs(false); return true; }
      onBack(); return true;
    });
    return () => sub.remove();
  }, [fs, listOpen, onBack]);

  const showBanner = () => {
    Animated.timing(banner, { toValue: 1, duration: 320, useNativeDriver: true }).start();
    clearTimeout(bannerT.current);
    bannerT.current = setTimeout(() => Animated.timing(banner, { toValue: 0, duration: 400, useNativeDriver: true }).start(), 6000);
  };
  const flashCtl = () => {
    setCtl(true); clearTimeout(ctlT.current);
    ctlT.current = setTimeout(() => setCtl(false), 4000);
  };

  const src = useMemo(() => { const st = streams?.[si]; return st ? proxied(st.url, settings?.proxy) : null; }, [streams, si, settings]);
  const onVideoError = () => { if (streams && si + 1 < streams.length) setSi(si + 1); else setError(true); };

  const logo = /^https:/i.test(channel.logo_url || '') ? channel.logo_url : null;
  const tags = [channel.country_name, channel.category_name, channel.quality].filter(Boolean);
  const bStyle = { opacity: banner, transform: [{ translateY: banner.interpolate({ inputRange: [0, 1], outputRange: [20, 0] }) }] };
  const stageStyle = fs ? styles.stageFs : { width: SW, height: videoH };
  const WM = Math.max(26, Math.round((fs ? SH * 0.14 : videoH * 0.13)));

  const zap = (d) => { onZap(d); };

  return (
    <View style={[styles.wrap, fs && styles.wrapFs]}>
      <StatusBar hidden={fs} />
      {/* المسرح */}
      <Pressable style={stageStyle} onPress={() => { flashCtl(); }}>
        {src && !error && (
          <Video source={{ uri: src }} style={StyleSheet.absoluteFill} resizeMode="contain"
            paused={paused} onLoad={() => setLoading(false)} onError={onVideoError}
            onBuffer={({ isBuffering }) => setLoading(isBuffering)} ignoreSilentSwitch="ignore" />
        )}
        {loading && !error && <ActivityIndicator size="large" color={C.ac} style={StyleSheet.absoluteFill} />}
        {error && (
          <View style={[StyleSheet.absoluteFill, styles.center]}>
            <Text style={styles.errT}>تعذّر تشغيل هذه القناة</Text>
            <Pressable style={styles.retry} onPress={() => { setError(false); setSi(0); }}>
              <Icon name="refresh" size={16} color="#fff" /><Text style={styles.retryT}>إعادة المحاولة</Text>
            </Pressable>
          </View>
        )}

        {/* لوجو الشركة */}
        <View style={[styles.wm, { top: rs(10), left: rs(12) }]} pointerEvents="none"><LogoMark size={WM} spin={false} /></View>

        {/* أزرار التحكم */}
        {ctl && !error && (
          <>
            <LinearGradient colors={['rgba(0,0,0,0.5)', 'transparent', 'rgba(0,0,0,0.55)']} style={StyleSheet.absoluteFill} pointerEvents="none" />
            {/* علوي */}
            <View style={styles.ctlTop}>
              <Pressable style={styles.cBtn} onPress={() => (fs ? setFs(false) : onBack())}><Icon name="back" size={rs(20)} color="#fff" /></Pressable>
              <Text numberOfLines={1} style={styles.ctlName}>{channel.number} · {channel.name}</Text>
              <Pressable style={styles.cBtn} onPress={() => setFs(!fs)}><Icon name={fs ? 'grid' : 'tv'} size={rs(19)} color="#fff" /></Pressable>
            </View>
            {/* وسط: تشغيل/إيقاف + تنقّل */}
            <View style={styles.ctlMid} pointerEvents="box-none">
              <Pressable style={styles.midBtn} onPress={() => zap(-1)}><Icon name="next" size={rs(24)} color="#fff" /></Pressable>
              <Pressable style={styles.playBtn} onPress={() => { setPaused(!paused); flashCtl(); }}>
                <Icon name={paused ? 'play' : 'pause'} size={rs(30)} color="#fff" />
              </Pressable>
              <Pressable style={styles.midBtn} onPress={() => zap(1)}><Icon name="back" size={rs(24)} color="#fff" /></Pressable>
            </View>
            {/* سفلي: مباشر + قائمة + مفضلة */}
            <View style={styles.ctlBot}>
              <View style={styles.liveTag}><View style={styles.dot} /><Text style={styles.liveT}>مباشر</Text></View>
              <View style={styles.liveBar}><View style={styles.liveFill} /></View>
              <Pressable style={styles.cBtn} onPress={() => setListOpen(true)}><Icon name="list" size={rs(19)} color="#fff" /></Pressable>
              <Pressable style={styles.cBtn} onPress={onToggleFav}><Icon name="heart" size={rs(19)} color={isFav ? C.ac : '#fff'} /></Pressable>
            </View>
          </>
        )}

        {/* شريط اسم القناة (كالتلفاز) */}
        <Animated.View style={[styles.banner, bStyle]} pointerEvents="none">
          <LinearGradient colors={['transparent', 'rgba(0,0,0,0.85)']} style={StyleSheet.absoluteFill} />
          <View style={styles.bannerIn}>
            <View style={styles.bNum}><Text style={styles.bNumT}>{channel.number}</Text></View>
            {logo ? <Image source={{ uri: logo }} style={styles.bLogo} resizeMode="contain" /> : null}
            <View style={{ flex: 1 }}>
              <Text numberOfLines={1} style={styles.bName}>{channel.name}</Text>
              <Text numberOfLines={1} style={styles.bMeta}>{tags.join('  ·  ')}</Text>
            </View>
          </View>
        </Animated.View>
      </Pressable>

      {/* الوضع العادي: معلومات + أزرار (بلا «المزيد من») */}
      {!fs && (
        <View style={styles.info}>
          <View style={styles.infoHead}>
            <View style={styles.logoBox}>
              {logo ? <Image source={{ uri: logo }} style={{ width: '78%', height: '78%' }} resizeMode="contain" /> : <Text style={styles.init}>{(channel.name || '•')[0]}</Text>}
            </View>
            <View style={{ flex: 1 }}>
              <Text numberOfLines={2} style={styles.title}>{channel.name}</Text>
              <View style={styles.tags}>{tags.map((t, i) => <Text key={i} style={styles.tag}>{t}</Text>)}</View>
            </View>
          </View>
          <View style={styles.actions}>
            <Act icon="list" label="قائمة القنوات" onPress={() => setListOpen(true)} />
            <Act icon="heart" label={isFav ? 'في المفضلة' : 'المفضلة'} active={isFav} onPress={onToggleFav} />
            <Act icon="tv" label="تكبير" onPress={() => setFs(true)} />
          </View>
        </View>
      )}

      {/* قائمة القنوات */}
      {listOpen && (
        <ChannelListDrawer channels={channels || []} currentId={channel.id} fullscreen={fs}
          onPick={(c) => { setListOpen(false); onPick(c); }} onClose={() => setListOpen(false)} />
      )}
    </View>
  );
}

function Act({ icon, label, onPress, active }) {
  return (
    <Pressable onPress={onPress} style={({ pressed }) => [styles.act, active && styles.actOn, pressed && { opacity: 0.7 }]}>
      <Icon name={icon} size={rs(18)} color={active ? '#fff' : C.txt} />
      <Text style={[styles.actT, active && { color: '#fff' }]}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  wrap: { flex: 1, backgroundColor: C.bg },
  wrapFs: { backgroundColor: '#000' },
  stageFs: { position: 'absolute', top: 0, left: 0, width: SW, height: SH, backgroundColor: '#000', zIndex: 20 },
  center: { alignItems: 'center', justifyContent: 'center', gap: 14 },
  errT: { color: C.txt, fontSize: rs(15) },
  retry: { flexDirection: 'row-reverse', alignItems: 'center', gap: 7, backgroundColor: C.ac, borderRadius: 10, paddingHorizontal: 18, paddingVertical: 10 },
  retryT: { color: '#fff', fontSize: 14, fontWeight: '700' },
  wm: { position: 'absolute', opacity: 0.85, zIndex: 5 },
  // controls
  ctlTop: { position: 'absolute', top: 0, left: 0, right: 0, flexDirection: 'row-reverse', alignItems: 'center', gap: 10, padding: rs(10) },
  ctlName: { flex: 1, color: '#fff', fontSize: rs(14), fontWeight: '700', textAlign: 'right' },
  ctlMid: { ...StyleSheet.absoluteFillObject, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: rs(26) },
  midBtn: { width: rs(48), height: rs(48), borderRadius: rs(24), backgroundColor: 'rgba(0,0,0,0.35)', alignItems: 'center', justifyContent: 'center' },
  playBtn: { width: rs(64), height: rs(64), borderRadius: rs(32), backgroundColor: 'rgba(255,45,85,0.92)', alignItems: 'center', justifyContent: 'center' },
  ctlBot: { position: 'absolute', bottom: 0, left: 0, right: 0, flexDirection: 'row-reverse', alignItems: 'center', gap: 10, padding: rs(10) },
  liveTag: { flexDirection: 'row-reverse', alignItems: 'center', gap: 4, backgroundColor: '#e11d48', borderRadius: 5, paddingHorizontal: 8, paddingVertical: 3 },
  dot: { width: 5, height: 5, borderRadius: 3, backgroundColor: '#fff' },
  liveT: { color: '#fff', fontSize: rs(10), fontWeight: '800' },
  liveBar: { flex: 1, height: 3, borderRadius: 3, backgroundColor: 'rgba(255,255,255,0.25)' },
  liveFill: { width: '100%', height: '100%', borderRadius: 3, backgroundColor: C.ac },
  cBtn: { width: rs(40), height: rs(40), borderRadius: rs(20), backgroundColor: 'rgba(0,0,0,0.4)', alignItems: 'center', justifyContent: 'center' },
  // banner
  banner: { position: 'absolute', left: 0, right: 0, bottom: 0, paddingTop: rs(30) },
  bannerIn: { flexDirection: 'row-reverse', alignItems: 'center', gap: rs(10), padding: rs(12) },
  bNum: { backgroundColor: C.ac, borderRadius: rs(8), paddingHorizontal: rs(10), paddingVertical: rs(4) },
  bNumT: { color: '#fff', fontSize: rs(18), fontWeight: '900' },
  bLogo: { width: rs(40), height: rs(40) },
  bName: { color: '#fff', fontSize: rs(18), fontWeight: '900', textAlign: 'right' },
  bMeta: { color: 'rgba(255,255,255,0.75)', fontSize: rs(12.5), marginTop: rs(3), textAlign: 'right' },
  // normal info
  info: { flex: 1, padding: 16 },
  infoHead: { flexDirection: 'row-reverse', gap: 14, alignItems: 'center' },
  logoBox: { width: rs(72), height: rs(72), borderRadius: 16, backgroundColor: C.surface2, alignItems: 'center', justifyContent: 'center', borderWidth: 1, borderColor: C.line, overflow: 'hidden' },
  init: { color: C.mut, fontSize: rs(30), fontWeight: '900' },
  title: { color: '#fff', fontSize: rs(20), fontWeight: '900', textAlign: 'right' },
  tags: { flexDirection: 'row-reverse', flexWrap: 'wrap', gap: 6, marginTop: 8 },
  tag: { color: C.mut, fontSize: rs(12.5), backgroundColor: C.surface, borderRadius: 7, paddingHorizontal: 9, paddingVertical: 4, overflow: 'hidden' },
  actions: { flexDirection: 'row-reverse', gap: 10, marginTop: 18 },
  act: { flex: 1, flexDirection: 'row-reverse', alignItems: 'center', justifyContent: 'center', gap: 7, backgroundColor: C.surface, borderRadius: 12, paddingVertical: rs(13), borderWidth: 1, borderColor: C.line },
  actOn: { backgroundColor: C.ac, borderColor: C.ac },
  actT: { color: C.txt, fontSize: rs(13.5), fontWeight: '700' },
});
