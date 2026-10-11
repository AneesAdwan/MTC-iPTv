import React, { useEffect, useState, useCallback } from 'react';
import { View, Text, ActivityIndicator, StyleSheet, I18nManager, StatusBar } from 'react-native';
import { fetchChannels, fetchSettings, fetchCountries } from './src/lib/catalog';
import { loadFavorites, saveFavorites } from './src/lib/favorites';
import HomeScreen from './src/screens/HomeScreen';
import SearchScreen from './src/screens/SearchScreen';
import CountriesScreen from './src/screens/CountriesScreen';
import CategoriesScreen from './src/screens/CategoriesScreen';
import FavoritesScreen from './src/screens/FavoritesScreen';
import WatchScreen from './src/screens/WatchScreen';
import BottomNav from './src/components/BottomNav';
import { C } from './src/theme';

try { I18nManager.allowRTL(true); I18nManager.forceRTL(true); } catch {}

export default function App() {
  const [channels, setChannels] = useState(null);
  const [countries, setCountries] = useState([]);
  const [settings, setSettings] = useState({});
  const [favorites, setFavorites] = useState(new Set());
  const [err, setErr] = useState(null);
  const [tab, setTab] = useState('home');
  const [watchId, setWatchId] = useState(null);

  useEffect(() => {
    Promise.all([fetchChannels(), fetchSettings(), fetchCountries()])
      .then(([ch, st, co]) => { setChannels(ch); setSettings(st); setCountries(co); })
      .catch(e => setErr(e.message || 'تعذّر الاتصال بقاعدة البيانات'));
    loadFavorites().then(setFavorites);
  }, []);

  const current = watchId && channels ? channels.find(c => c.id === watchId) : null;

  const toggleFav = useCallback((id) => {
    setFavorites(prev => {
      const n = new Set(prev);
      n.has(id) ? n.delete(id) : n.add(id);
      saveFavorites(n);
      return n;
    });
  }, []);

  const zap = useCallback((dir) => {
    if (!channels || !current) return;
    const i = channels.findIndex(c => c.id === current.id);
    setWatchId(channels[(i + dir + channels.length) % channels.length].id);
  }, [channels, current]);

  if (err) return <Center><Text style={st.err}>{err}</Text></Center>;
  if (!channels) return <Center><ActivityIndicator size="large" color={C.ac} /><Text style={st.loading}>جارٍ تحميل القنوات…</Text></Center>;

  if (current) {
    return (
      <View style={st.app}>
        <StatusBar hidden />
        <WatchScreen
          channel={current} settings={settings}
          isFav={favorites.has(current.id)} onToggleFav={() => toggleFav(current.id)}
          onBack={() => setWatchId(null)} onZap={zap}
        />
      </View>
    );
  }

  const onPick = c => setWatchId(c.id);
  return (
    <View style={st.app}>
      <StatusBar barStyle="light-content" backgroundColor={C.bg} />
      <View style={{ flex: 1 }}>
        {tab === 'home' && <HomeScreen channels={channels} onPick={onPick} />}
        {tab === 'search' && <SearchScreen channels={channels} onPick={onPick} />}
        {tab === 'countries' && <CountriesScreen channels={channels} countries={countries} onPick={onPick} />}
        {tab === 'categories' && <CategoriesScreen channels={channels} onPick={onPick} />}
        {tab === 'favorites' && <FavoritesScreen channels={channels} favorites={favorites} onPick={onPick} />}
      </View>
      <BottomNav tab={tab} onChange={setTab} />
    </View>
  );
}

const Center = ({ children }) => <View style={st.center}>{children}</View>;
const st = StyleSheet.create({
  app: { flex: 1, backgroundColor: C.bg },
  center: { flex: 1, backgroundColor: C.bg, alignItems: 'center', justifyContent: 'center', gap: 14 },
  loading: { color: C.mut, fontSize: 15 },
  err: { color: C.bad, fontSize: 16, padding: 24, textAlign: 'center' },
});
