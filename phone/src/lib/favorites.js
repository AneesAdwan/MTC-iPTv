// المفضلة محفوظة على الجهاز (AsyncStorage) — تبقى بعد إغلاق التطبيق.
import AsyncStorage from '@react-native-async-storage/async-storage';

const KEY = 'mtc-favorites';

export async function loadFavorites() {
  try { const raw = await AsyncStorage.getItem(KEY); return new Set(JSON.parse(raw || '[]')); }
  catch { return new Set(); }
}

export async function saveFavorites(set) {
  try { await AsyncStorage.setItem(KEY, JSON.stringify([...set])); } catch {}
}
