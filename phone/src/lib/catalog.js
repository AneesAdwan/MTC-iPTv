// طبقة البيانات: تقرأ نفس واجهات العرض التي يستخدمها موقع الويب (catalog / catalog_streams / countries / site_settings).
import { supabase } from './supabase';

const CH_COLS = 'id,number,name,network,logo_url,quality,is_featured,description,country_code,country_name,flag_url,is_arab,continent,category_slug,category_name,language_code,language_name,server,published_at';

/** كل القنوات المنشورة (مرتبة برقم القناة). الواجهة catalog لا تُرجع إلا ما له رابط يعمل. */
export async function fetchChannels() {
  const all = [];
  const step = 1000;
  for (let from = 0; ; from += step) {
    const { data, error } = await supabase
      .from('catalog').select(CH_COLS).order('number', { ascending: true }).range(from, from + step - 1);
    if (error) throw error;
    all.push(...(data || []));
    if (!data || data.length < step) break;
  }
  return all.map(c => ({ ...c, number: c.number || 0 }));
}

/** روابط البث لقناة واحدة (تُطلب عند فتح المشاهدة فقط). */
export async function fetchStreams(channelId) {
  const { data, error } = await supabase
    .from('catalog_streams').select('id,url,server,quality,status,priority')
    .eq('channel_id', channelId).order('priority', { ascending: true });
  if (error) throw error;
  return (data || []).sort((a, b) => (b.status === 'online') - (a.status === 'online') || a.priority - b.priority);
}

/** إعدادات الموقع العامة (الوسيط، قناة الواجهة...). */
export async function fetchSettings() {
  const { data } = await supabase.from('site_settings').select('key,value');
  return Object.fromEntries((data || []).map(x => [x.key, x.value]));
}

export async function fetchCountries() {
  const { data } = await supabase
    .from('countries').select('code,name_ar,flag_url,is_arab,continent,sort_order')
    .order('sort_order', { ascending: true }).order('name_ar', { ascending: true });
  return data || [];
}

/** يلفّ الرابط عبر وسيطك الخاص إذا كان نطاقه ضمن القائمة (نفس منطق الويب). */
export function proxied(url, proxy) {
  if (!proxy?.url || !Array.isArray(proxy.hosts) || !proxy.hosts.length || !/^https?:\/\//i.test(url || '')) return url;
  try {
    const host = new URL(url).hostname.toLowerCase();
    const hit = proxy.hosts.some(h => {
      h = String(h).trim().toLowerCase().replace(/^https?:\/\//, '').replace(/\/.*$/, '');
      return h && (host === h || host.endsWith('.' + h));
    });
    return hit ? proxy.url.replace(/\/+$/, '') + '/?url=' + encodeURIComponent(url) : url;
  } catch { return url; }
}
