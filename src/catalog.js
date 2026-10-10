// أدوات مشتركة بين واجهة المشاهدة ولوحة الإدارة.

/** رقم ثابت من نص (لتلوين البطاقات بلون مميز لكل قناة) */
export function hash(s) {
  let h = 0;
  for (const ch of String(s)) h = (h * 31 + ch.codePointAt(0)) >>> 0;
  return h;
}

// معرّفات الفئات في قاعدة البيانات (جدول categories) — مطابقة لتصنيفات iptv-org
export const CATEGORY_SLUGS = ['news', 'sports', 'movies', 'series', 'kids', 'animation', 'entertainment', 'comedy', 'music',
  'documentary', 'science', 'religious', 'education', 'culture', 'business', 'weather', 'lifestyle', 'cooking', 'travel',
  'outdoor', 'auto', 'shop', 'classic', 'family', 'relax', 'legislative', 'public', 'general'];
const ARABIC_HINTS = [['أخبار', 'news'], ['رياض', 'sports'], ['أفلام', 'movies'], ['مسلسل', 'series'], ['دراما', 'series'],
  ['أطفال', 'kids'], ['كرتون', 'animation'], ['موسيق', 'music'], ['أغاني', 'music'], ['دين', 'religious'], ['قرآن', 'religious'],
  ['وثائق', 'documentary'], ['طبخ', 'cooking'], ['اقتصاد', 'business'], ['تعليم', 'education'], ['ترفيه', 'entertainment']];

/** group-title من ملف M3U (مثل "Movies;Series") → معرّف فئة */
export function categorySlug(groupTitle) {
  const parts = String(groupTitle || '').toLowerCase().split(/[;,/|]/).map(s => s.trim()).filter(Boolean);
  const hit = parts.find(p => CATEGORY_SLUGS.includes(p) && p !== 'general') || parts.find(p => CATEGORY_SLUGS.includes(p));
  if (hit) return hit;
  for (const p of parts) for (const [w, slug] of ARABIC_HINTS) if (p.includes(w)) return slug;
  return 'general';
}

/** اسم مطبّع للمقارنة: "Al Jazeera (1080p) HD" → "aljazeera" */
export const normName = n => String(n || '').toLowerCase()
  .replace(/\s*[([][^)\]]*[)\]]/g, '')
  .replace(/\b(hd|fhd|sd|uhd|4k|tv)\b/g, '')
  .replace(/[\s\-_.:'"!?&*/\\|،]+/g, ''); // نُبقي + لأن ATV و ATV+ قناتان مختلفتان

const STOP = new Set(['al', 'el', 'the', 'tv', 'channel', 'radio', 'la', 'le', 'de', 'canal', 'rede', 'tele', 'télé', 'قناة', 'تلفزيون']);
/** مفاتيح «عائلة» القناة: الشبكة + أول كلمة مميزة في الاسم (MBC 1 / MBC Drama → mbc) */
export function familyKeys(c) {
  const keys = [];
  if (c.network) keys.push('n:' + c.network.toLowerCase().trim());
  const word = String(c.name || '').toLowerCase().replace(/[^\p{L}\p{N}\s]/gu, ' ').split(/\s+/).find(w => w.length >= 2 && !STOP.has(w) && !/^\d+$/.test(w));
  if (word) keys.push('w:' + word);
  return keys;
}
