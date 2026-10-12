import React, { useEffect, useState, useCallback, useRef } from 'react';
import { View, Text, StyleSheet, I18nManager, StatusBar, Animated } from 'react-native';
import { fetchChannels, fetchSettings, fetchCountries } from './src/lib/catalog';
import { loadFavorites, saveFavorites } from './src/lib/favorites';
import { num } from './src/lib/format';
import Splash from './src/screens/SplashScreen';
import HomeScreen from './src/screens/HomeScreen';
import SearchScreen from './src/screens/SearchScreen';
import CountriesScreen from './src/screens/CountriesScreen';
import CategoriesScreen from './src/screens/CategoriesScreen';
import FavoritesScreen from './src/screens/FavoritesScreen';
import WatchScreen from './src/screens/WatchScreen';
import AboutScreen from './src/screens/AboutScreen';
import BottomNav from './src/components/BottomNav';
import Notice from './src/components/Notice';
import UpdateModal from './src/components/UpdateModal';
import { checkUpdate } from './src/lib/update';
import { initPush } from './src/lib/push';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { C } from './src/theme';

try { I18nManager.allowRTL(true); I18nManager.forceRTL(true); } catch {}

const MIN_SPLASH = 3900; // مشهد الشركة الأم (~2.1ث) + مشهد العلامة والتحميل

export default function App() {
  const [channels, setChannels] = useState(null);
  const [countries, setCountries] = useState([]);
  const [settings, setSettings] = useState({});
  const [favorites, setFavorites] = useState(new Set());
  const [err, setErr] = useState(null);
  const [ready, setReady] = useState(false);     // انتهى التحميل + مهلة البداية
  const [status, setStatus] = useState('جارٍ الاتصال…');
  const [tab, setTab] = useState('home');
  const [watchId, setWatchId] = useState(null);
  const [update, setUpdate] = useState(null);     // تحديث جديد متوفّر
  const [showUpdate, setShowUpdate] = useState(false); // نافذة التحديث الداخلي
  const [freshCount, setFreshCount] = useState(0); // قنوات جديدة منذ آخر زيارة
  const fade = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    const t0 = Date.now();
    setStatus('جارٍ تحميل القنوات…');
    Promise.all([fetchChannels(), fetchSettings(), fetchCountries()])
      .then(([ch, st, co]) => {
        setChannels(ch); setSettings(st); setCountries(co);
        setStatus(`${num(ch.length)} قناة جاهزة`);
        const wait = Math.max(0, MIN_SPLASH - (Date.now() - t0));
        setTimeout(() => {
          setReady(true);
          Animated.timing(fade, { toValue: 1, duration: 450, useNativeDriver: true }).start();
        }, wait);
      })
      .catch(e => setErr(e.message || 'تعذّر الاتصال بقاعدة البيانات'));
    loadFavorites().then(setFavorites);
    // إشعار بوجود تحديث جديد
    checkUpdate().then(u => u && setUpdate(u));
    // تفعيل إشعارات Push (الاشتراك في الموضوع العام)
    initPush();
  }, [fade]);

  // إشعار بالقنوات الجديدة منذ آخر زيارة
  useEffect(() => {
    if (!channels) return;
    (async () => {
      try {
        const last = +(await AsyncStorage.getItem('mtc-last-seen')) || 0;
        const newest = channels.reduce((m, c) => Math.max(m, c.published_at ? Date.parse(c.published_at) : 0), 0);
        if (last) {
          const n = channels.filter(c => c.published_at && Date.parse(c.published_at) > last).length;
          if (n > 0) setFreshCount(n);
        }
        await AsyncStorage.setItem('mtc-last-seen', String(newest || Date.now()));
      } catch {}
    })();
  }, [channels]);

  const current = watchId && channels ? channels.find(c => c.id === watchId) : null;

  const toggleFav = useCallback((id) => {
    setFavorites(prev => { const n = new Set(prev); n.has(id) ? n.delete(id) : n.add(id); saveFavorites(n); return n; });
  }, []);
  const zap = useCallback((dir) => {
    if (!channels || !current) return;
    const i = channels.findIndex(c => c.id === current.id);
    setWatchId(channels[(i + dir + channels.length) % channels.length].id);
  }, [channels, current]);

  if (!ready && !err) {
    return <View style={st.app}><StatusBar hidden /><Splash status={status} /></View>;
  }
  if (err) {
    return <View style={st.center}><StatusBar hidden /><Text style={st.err}>{err}</Text></View>;
  }

  if (current) {
    return (
      <View style={st.app}>
        <StatusBar hidden />
        <WatchScreen channel={current} channels={channels} settings={settings}
          isFav={favorites.has(current.id)} onToggleFav={() => toggleFav(current.id)}
          onBack={() => setWatchId(null)} onZap={zap} onPick={c => setWatchId(c.id)} />
      </View>
    );
  }

  const onPick = c => setWatchId(c.id);
  return (
    <Animated.View style={[st.app, { opacity: fade }]}>
      <StatusBar barStyle="light-content" backgroundColor={C.bg} />
      <Notice update={update} freshCount={update ? 0 : freshCount}
        onDismiss={() => { setUpdate(null); setFreshCount(0); }}
        onUpdate={() => setShowUpdate(true)}
        onShowFresh={() => setTab('home')} />
      {showUpdate && update && <UpdateModal update={update} onClose={() => setShowUpdate(false)} />}
      <View style={{ flex: 1 }}>
        {tab === 'home' && <HomeScreen channels={channels} settings={settings} onPick={onPick} />}
        {tab === 'search' && <SearchScreen channels={channels} onPick={onPick} />}
        {tab === 'countries' && <CountriesScreen channels={channels} countries={countries} onPick={onPick} />}
        {tab === 'categories' && <CategoriesScreen channels={channels} onPick={onPick} />}
        {tab === 'favorites' && <FavoritesScreen channels={channels} favorites={favorites} onPick={onPick} />}
        {tab === 'about' && <AboutScreen onBack={() => setTab('home')} />}
      </View>
      <BottomNav tab={tab} onChange={setTab} />
    </Animated.View>
  );
}

const st = StyleSheet.create({
  app: { flex: 1, backgroundColor: C.bg },
  center: { flex: 1, backgroundColor: C.bg, alignItems: 'center', justifyContent: 'center' },
  err: { color: C.bad, fontSize: 16, padding: 24, textAlign: 'center' },
});
