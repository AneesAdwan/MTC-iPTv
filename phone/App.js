import React, { useEffect, useState, useCallback, useRef } from 'react';
import { View, Text, StyleSheet, I18nManager, StatusBar, Animated } from 'react-native';
import { fetchChannels, fetchSettings, fetchCountries } from './src/lib/catalog';
import { loadFavorites, saveFavorites } from './src/lib/favorites';
import Splash from './src/screens/SplashScreen';
import HomeScreen from './src/screens/HomeScreen';
import SearchScreen from './src/screens/SearchScreen';
import CountriesScreen from './src/screens/CountriesScreen';
import CategoriesScreen from './src/screens/CategoriesScreen';
import FavoritesScreen from './src/screens/FavoritesScreen';
import WatchScreen from './src/screens/WatchScreen';
import BottomNav from './src/components/BottomNav';
import { C } from './src/theme';

try { I18nManager.allowRTL(true); I18nManager.forceRTL(true); } catch {}

const MIN_SPLASH = 2400; // ليُرى الأنيميشن حتى لو حمّلت البيانات بسرعة

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
  const fade = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    const t0 = Date.now();
    setStatus('جارٍ تحميل القنوات…');
    Promise.all([fetchChannels(), fetchSettings(), fetchCountries()])
      .then(([ch, st, co]) => {
        setChannels(ch); setSettings(st); setCountries(co);
        setStatus(`${ch.length.toLocaleString('ar-EG')} قناة جاهزة`);
        const wait = Math.max(0, MIN_SPLASH - (Date.now() - t0));
        setTimeout(() => {
          setReady(true);
          Animated.timing(fade, { toValue: 1, duration: 450, useNativeDriver: true }).start();
        }, wait);
      })
      .catch(e => setErr(e.message || 'تعذّر الاتصال بقاعدة البيانات'));
    loadFavorites().then(setFavorites);
  }, [fade]);

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
        <WatchScreen channel={current} settings={settings}
          isFav={favorites.has(current.id)} onToggleFav={() => toggleFav(current.id)}
          onBack={() => setWatchId(null)} onZap={zap} />
      </View>
    );
  }

  const onPick = c => setWatchId(c.id);
  return (
    <Animated.View style={[st.app, { opacity: fade }]}>
      <StatusBar barStyle="light-content" backgroundColor={C.bg} />
      <View style={{ flex: 1 }}>
        {tab === 'home' && <HomeScreen channels={channels} settings={settings} onPick={onPick} />}
        {tab === 'search' && <SearchScreen channels={channels} onPick={onPick} />}
        {tab === 'countries' && <CountriesScreen channels={channels} countries={countries} onPick={onPick} />}
        {tab === 'categories' && <CategoriesScreen channels={channels} onPick={onPick} />}
        {tab === 'favorites' && <FavoritesScreen channels={channels} favorites={favorites} onPick={onPick} />}
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
