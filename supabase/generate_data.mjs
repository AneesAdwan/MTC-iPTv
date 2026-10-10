// ════════════════════════════════════════════════════════════════════════════
// MTC-iPTv — مولّد البيانات من مستودع iptv-org المفتوح
//
//   node supabase/generate_data.mjs            → تنزيل + فحص الروابط + توليد الملفات
//   node supabase/generate_data.mjs --no-check → بدون فحص (أسرع، روابط غير مؤكدة)
//
// يكتب:
//   • البيانات المرجعية (الدول/اللغات/الفئات) داخل 01_schema.sql بين العلامتين @@REFERENCE_DATA
//   • 02_data.sql : مصادر البث + القنوات + روابطها (الشغّالة فقط عند الفحص)، ملف واحد مرتب حسب الدولة
//
// الفحص يحاكي المتصفح: الرابط يجب أن يرجع ملف M3U8 صالحًا ويسمح بالتشغيل من موقع آخر (CORS)،
// وإلا فلن يعمل على GitHub Pages مهما كان شغّالًا في VLC.
// ════════════════════════════════════════════════════════════════════════════
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const DIR = path.dirname(fileURLToPath(import.meta.url));
const CACHE = path.join(DIR, '.cache');
const API = 'https://iptv-org.github.io/api/';
const CHECK = !process.argv.includes('--no-check');
const ORIGIN = 'https://mtc-iptv.github.io';

/* ───────── ثوابت التصنيف ───────── */
const CATEGORIES = [
  ['news', 'أخبار', 'News', 'live', 0], ['sports', 'رياضة', 'Sports', 'ball', 140], ['movies', 'أفلام', 'Movies', 'film', 280],
  ['series', 'مسلسلات', 'Series', 'tv', 320], ['kids', 'أطفال', 'Kids', 'star', 45], ['animation', 'رسوم متحركة', 'Animation', 'star', 30],
  ['entertainment', 'ترفيه', 'Entertainment', 'play', 25], ['comedy', 'كوميديا', 'Comedy', 'heart', 50], ['music', 'موسيقى', 'Music', 'music', 200],
  ['documentary', 'وثائقي', 'Documentary', 'globe', 95], ['science', 'علوم', 'Science', 'zap', 185], ['religious', 'دينية', 'Religious', 'book', 165],
  ['education', 'تعليم', 'Education', 'book', 220], ['culture', 'ثقافة', 'Culture', 'book', 260], ['business', 'اقتصاد وأعمال', 'Business', 'chart', 55],
  ['weather', 'طقس', 'Weather', 'sun', 195], ['lifestyle', 'أسلوب حياة', 'Lifestyle', 'heart', 340], ['cooking', 'طبخ', 'Cooking', 'fork', 15],
  ['travel', 'سفر', 'Travel', 'globe', 175], ['outdoor', 'مغامرات', 'Outdoor', 'sun', 110], ['auto', 'سيارات', 'Auto', 'car', 5],
  ['shop', 'تسوّق', 'Shop', 'bag', 300], ['classic', 'كلاسيك', 'Classic', 'film', 35], ['family', 'عائلة', 'Family', 'user', 20],
  ['relax', 'استرخاء', 'Relax', 'heart', 160], ['legislative', 'برلمانية', 'Legislative', 'shield', 210], ['public', 'حكومية', 'Public', 'shield', 230],
  ['general', 'عامة', 'General', 'tv', 240]
];
const ARAB_ORDER = ['SA', 'EG', 'AE', 'QA', 'KW', 'BH', 'OM', 'JO', 'PS', 'LB', 'SY', 'IQ', 'YE', 'SD', 'LY', 'TN', 'DZ', 'MA', 'MR', 'SO', 'DJ', 'KM'];
const SHORT_AR = { SA: 'السعودية', AE: 'الإمارات', PS: 'فلسطين', US: 'أمريكا', GB: 'بريطانيا', KR: 'كوريا الجنوبية', KP: 'كوريا الشمالية', CD: 'الكونغو الديمقراطية', CG: 'الكونغو', VA: 'الفاتيكان', MK: 'مقدونيا الشمالية', CZ: 'التشيك', BA: 'البوسنة والهرسك', VN: 'فيتنام' };
const FEATURED = ['AlJazeera.qa', 'AlArabiya.ae', 'AlJazeeraEnglish.qa', 'SkyNewsArabia.ae', 'AlHadath.ae', 'AlMamlaka.jo', 'AlEkhbariya.sa', 'France24Arabic.fr', 'DWArabic.de', 'BBCArabic.uk', 'Asharq.sa', 'RTArabic.ru', 'MBC1.ae', 'SaudiSports.sa', 'Spacetoon.ae', 'QuranTV.sa'];
const CONTINENT = [['AFR', 'africa'], ['EUR', 'europe'], ['ASIA', 'asia'], ['AMER', 'americas'], ['OCE', 'oceania']];
const QUALITY = q => { const h = parseInt(q) || 0; return h >= 2160 ? '4K' : h >= 1080 ? 'FHD' : h >= 720 ? 'HD' : h ? 'SD' : null; };
const RANK = { '4K': 4, FHD: 3, HD: 2, SD: 1 };

/* ───────── أدوات ───────── */
const sq = s => s == null ? 'null' : `'${String(s).replace(/'/g, "''")}'`;
const arLang = new Intl.DisplayNames(['ar'], { type: 'language' });
const arRegion = new Intl.DisplayNames(['ar'], { type: 'region' });
const safe = (fn, fb) => { try { const v = fn(); return v && v.length > 1 ? v : fb; } catch { return fb; } };

async function load(name) {
  fs.mkdirSync(CACHE, { recursive: true });
  const file = path.join(CACHE, `${name}.json`);
  if (!fs.existsSync(file) || Date.now() - fs.statSync(file).mtimeMs > 6 * 3600e3) {
    process.stdout.write(`تنزيل ${name}.json… `);
    fs.writeFileSync(file, await (await fetch(API + name + '.json')).text());
    console.log('✓');
  }
  return JSON.parse(fs.readFileSync(file, 'utf8'));
}

async function probe(url, kind) {
  const t0 = Date.now(), ctl = new AbortController(), to = setTimeout(() => ctl.abort(), 12000);
  try {
    const res = await fetch(url, { headers: { Origin: ORIGIN, 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/130 Safari/537.36' }, signal: ctl.signal });
    const acao = res.headers.get('access-control-allow-origin');
    let ok = res.ok, err = res.ok ? '' : `HTTP ${res.status}`;
    if (kind === 'stream') {
      const reader = res.body.getReader(); let txt = '';
      while (txt.length < 2048) { const { done, value } = await reader.read(); if (done) break; txt += new TextDecoder().decode(value); }
      reader.cancel().catch(() => {});
      if (ok && !txt.trimStart().startsWith('#EXTM3U')) { ok = false; err = 'not m3u8'; }
      if (ok && !(acao === '*' || acao === ORIGIN)) { ok = false; err = 'no CORS'; }
    } else {
      res.body?.cancel().catch(() => {});
      if (ok && !/^image\//.test(res.headers.get('content-type') || '')) { ok = false; err = 'not image'; }
    }
    return { ok, status: res.status, ms: Date.now() - t0, err };
  } catch (e) {
    return { ok: false, status: 0, ms: Date.now() - t0, err: e.name === 'AbortError' ? 'timeout' : String(e.cause?.code || e.message).slice(0, 60) };
  } finally { clearTimeout(to); }
}
async function pool(items, n, fn, label) {
  let i = 0, done = 0;
  await Promise.all(Array.from({ length: n }, async () => {
    while (i < items.length) { const k = i++; items[k].res = await fn(items[k]); if (++done % 500 === 0) console.log(`  ${label}: ${done} / ${items.length}`); }
  }));
}

/* ───────── التحميل والتصفية ───────── */
const [channels, feeds, streams, logos, countries, languages, regions, blocklist] = await Promise.all(
  ['channels', 'feeds', 'streams', 'logos', 'countries', 'languages', 'regions', 'blocklist'].map(load));
const chMap = new Map(channels.map(c => [c.id, c]));
const blocked = new Set(blocklist.map(b => b.channel));

let usable = streams.filter(s => s.channel && chMap.has(s.channel) && !blocked.has(s.channel)
  && !chMap.get(s.channel).is_nsfw && !chMap.get(s.channel).closed
  && s.url.startsWith('https:') && s.url.length <= 2000 && !s.user_agent && !s.referrer && !s.labels.includes('Geo-blocked'));
console.log(`روابط صالحة للفحص: ${usable.length}`);

// أفضل شعار لكل قناة
const bestLogo = new Map();
for (const l of logos) {
  if (!l.url.startsWith('https:')) continue;
  const score = (l.feed ? 0 : 4) + (l.in_use ? 2 : 0) + (/PNG|SVG/i.test(l.format || '') ? 1 : 0);
  if (!bestLogo.has(l.channel) || score > bestLogo.get(l.channel).score) bestLogo.set(l.channel, { url: l.url, score });
}

// --results=file.json : إعادة استخدام نتائج فحص سابق بدل الفحص من جديد
const logoVerified = new Set();
const resultsArg = process.argv.find(a => a.startsWith('--results='));
const previous = resultsArg ? JSON.parse(fs.readFileSync(resultsArg.slice(10), 'utf8')) : null;
const checkedAt = previous?.at || new Date().toISOString();
if (previous) {
  const byUrl = new Map(previous.streams.map(s => [s.url, s]));
  const logoOk = new Map(previous.logos.map(l => [l.url, l.ok]));
  usable.forEach(s => { s.res = byUrl.get(s.url) || { ok: false }; });
  usable = usable.filter(s => s.res.ok);
  for (const [id, l] of bestLogo) { if (logoOk.get(l.url) === false) bestLogo.delete(id); else if (logoOk.get(l.url)) logoVerified.add(id); }
  console.log(`نتائج فحص سابق (${checkedAt}): ${usable.length} رابط شغّال`);
} else if (CHECK) {
  console.log('فحص روابط البث (قد يستغرق عدة دقائق)…');
  await pool(usable, 60, s => probe(s.url, 'stream'), 'روابط');
  usable = usable.filter(s => s.res.ok);
  console.log(`روابط شغّالة: ${usable.length}`);
  const logoJobs = [...new Set(usable.map(s => s.channel))].filter(id => bestLogo.has(id)).map(id => ({ id, url: bestLogo.get(id).url }));
  console.log('فحص الشعارات…');
  await pool(logoJobs, 60, j => probe(j.url, 'logo'), 'شعارات');
  for (const j of logoJobs) j.res.ok ? logoVerified.add(j.id) : bestLogo.delete(j.id);
}

/* ───────── البيانات المرجعية ───────── */
const continentOf = code => (CONTINENT.find(([r]) => regions.find(x => x.code === r)?.countries.includes(code)) || [])[1] || null;
const usedLangs = new Set();
const mainFeedLang = new Map();
for (const f of feeds) if (f.is_main && f.languages?.length) mainFeedLang.set(f.channel, f.languages[0]);
countries.forEach(c => c.languages?.[0] && usedLangs.add(c.languages[0]));
usable.forEach(s => mainFeedLang.has(s.channel) && usedLangs.add(mainFeedLang.get(s.channel)));
const langRows = languages.filter(l => usedLangs.has(l.code)).map(l => ({
  code: l.code, en: l.name, ar: safe(() => arLang.of(l.code), l.name),
  sort: l.code === 'ara' ? 1 : l.code === 'eng' ? 2 : l.code === 'fra' ? 3 : 100
}));
const langSet = new Set(langRows.map(l => l.code));

const countryRows = countries.map(c => ({
  code: c.code, en: c.name, ar: SHORT_AR[c.code] || safe(() => arRegion.of(c.code), c.name), flag: c.flag,
  continent: continentOf(c.code), arab: ARAB_ORDER.includes(c.code),
  lang: langSet.has(c.languages?.[0]) ? c.languages[0] : null,
  sort: ARAB_ORDER.includes(c.code) ? ARAB_ORDER.indexOf(c.code) + 1 : 100
}));
const countryMap = new Map(countryRows.map(c => [c.code, c]));

const reference = [
  '-- اللغات',
  'insert into public.languages (code, name_ar, name_en, sort_order) values',
  langRows.map(l => `  (${sq(l.code)}, ${sq(l.ar)}, ${sq(l.en)}, ${l.sort})`).join(',\n') + ';',
  '',
  '-- الدول',
  'insert into public.countries (code, name_ar, name_en, flag_emoji, continent, is_arab, language_code, sort_order) values',
  countryRows.map(c => `  (${sq(c.code)}, ${sq(c.ar)}, ${sq(c.en)}, ${sq(c.flag)}, ${sq(c.continent)}, ${c.arab}, ${sq(c.lang)}, ${c.sort})`).join(',\n') + ';',
  '',
  '-- الفئات',
  'insert into public.categories (slug, name_ar, name_en, icon, hue, sort_order) values',
  CATEGORIES.map(([s, ar, en, icon, hue], i) => `  (${sq(s)}, ${sq(ar)}, ${sq(en)}, ${sq(icon)}, ${hue}, ${i + 1})`).join(',\n') + ';'
].join('\n');

const schemaFile = path.join(DIR, '01_schema.sql');
const schema = fs.readFileSync(schemaFile, 'utf8').replace(
  /-- @@REFERENCE_DATA_START[\s\S]*?-- @@REFERENCE_DATA_END/,
  `-- @@REFERENCE_DATA_START\n${reference}\n-- @@REFERENCE_DATA_END`);
fs.writeFileSync(schemaFile, schema);
console.log(`01_schema.sql: ${countryRows.length} دولة، ${langRows.length} لغة، ${CATEGORIES.length} فئة`);

/* ───────── القنوات والروابط ───────── */
const catSet = new Set(CATEGORIES.map(c => c[0]));
const byChannel = new Map();
for (const s of usable) (byChannel.get(s.channel) || byChannel.set(s.channel, []).get(s.channel)).push(s);

const rows = [...byChannel.entries()].map(([id, list]) => {
  const c = chMap.get(id);
  const cats = (c.categories || []).filter(x => catSet.has(x));
  const primary = cats.find(x => x !== 'general') || cats[0] || 'general';
  const q = list.map(s => QUALITY(s.quality)).filter(Boolean).sort((a, b) => RANK[b] - RANK[a])[0] || null;
  const country = countryMap.get(c.country);
  return {
    uid: id, name: c.name, alt: c.alt_names || [], network: c.network || null,
    logo: bestLogo.get(id)?.url || null, logo_ok: logoVerified.has(id),
    country: country ? c.country : null,
    category: primary, extra: cats.filter(x => x !== primary),
    language: langSet.has(mainFeedLang.get(id)) ? mainFeedLang.get(id) : (country?.lang || null),
    quality: q, website: c.website || null, featured: FEATURED.includes(id),
    streams: list.sort((a, b) => (a.res?.ms ?? 0) - (b.res?.ms ?? 0)).map((s, i) => ({
      url: s.url, quality: QUALITY(s.quality), priority: i, ms: s.res?.ms ?? null, status: s.res?.status ?? null
    })),
    _arab: country?.arab ? 0 : 1, _sort: country?.sort ?? 999, _cname: country?.ar || 'ي'
  };
}).sort((a, b) => a._arab - b._arab || a._sort - b._sort || a._cname.localeCompare(b._cname, 'ar') || (b.featured - a.featured) || a.name.localeCompare(b.name));
rows.forEach((r, i) => { r.number = i + 1; delete r._arab; delete r._sort; delete r._cname; });

// المصادر: قائمة iptv-org لكل دولة (يمكن تحديثها لاحقًا من لوحة الإدارة)
const sourceCodes = [...new Set(rows.map(r => r.country).filter(Boolean))];
const sources = sourceCodes.map(code => ({
  code, name: `iptv-org — ${countryMap.get(code).ar}`, url: `https://iptv-org.github.io/iptv/countries/${code.toLowerCase()}.m3u`
}));
// ملف واحد مرتب (تُحذف الأجزاء القديمة 02_data_N.sql إن وُجدت)
for (const old of fs.readdirSync(DIR).filter(n => /^02_data(_\d+)?\.sql$/.test(n))) fs.unlinkSync(path.join(DIR, old));
const dataSql = buildDataSql({ rows, sources, checkedAt, checked: CHECK, cname: code => countryMap.get(code)?.ar || code });
fs.writeFileSync(path.join(DIR, '02_data.sql'), dataSql);
writeDemoJson({ rows, sources, checkedAt });
console.log(`02_data.sql: ${rows.length} قناة، ${(dataSql.length / 1048576).toFixed(2)} MB`);

// ملف بيانات واحد مقروء: صف لكل قناة ولكل رابط، مقسّم حسب الدولة
function buildDataSql({ rows, sources, checkedAt, checked, cname }) {
  const arr = a => a?.length ? `array[${a.map(sq).join(', ')}]` : `'{}'`;
  const groups = [];
  for (const r of rows) { const k = r.country || ''; if (groups.at(-1)?.k !== k) groups.push({ k, rows: [] }); groups.at(-1).rows.push(r); }
  const title = g => g.k ? `${cname(g.k)} (${g.k})` : 'دولية — بدون دولة';
  // يجمع الأسطر مع فاصلة بعد كل صف عدا الأخير، وعنوان لكل دولة
  const block = (rowOf, count) => {
    const out = []; let left = groups.reduce((n, g) => n + count(g), 0);
    for (const g of groups) {
      const lines = g.rows.flatMap(rowOf);
      if (!lines.length) continue;
      out.push(`  -- ━━━ ${title(g)} · ${lines.length} ━━━`);
      for (const l of lines) out.push(`  ${l}${--left ? ',' : ''}`);
    }
    return out.join('\n');
  };
  const channelRow = r => [`(${sq(r.uid)}, ${r.number}, ${sq(r.name)}, ${arr(r.alt)}, ${sq(r.network)}, ${sq(r.logo)}, ${!!(r.logo && r.logo_ok)}, ${sq(r.country)}, ${sq(r.category)}, ${arr(r.extra)}, ${sq(r.language)}, ${sq(r.quality)}, ${sq(r.website)}, ${!!r.featured})`];
  // manual = رابط أُضيف من ملف خارجي: لا يرتبط بمصدر iptv-org فلا يُحذف عند تحديث المصادر
  const streamRows = manual => r => r.streams.filter(s => !!s.manual === manual).map(s => `(${sq(r.uid)}, ${s.priority}, ${sq(s.url)}, ${sq(s.quality)})`);
  const countOf = manual => g => g.rows.reduce((n, r) => n + r.streams.filter(s => !!s.manual === manual).length, 0);
  const nStreams = rows.reduce((n, r) => n + r.streams.length, 0);
  const nManual = groups.reduce((n, g) => n + countOf(true)(g), 0);
  const countries = groups.filter(g => g.k).length;

  return `-- ════════════════════════════════════════════════════════════════════════════
-- MTC-iPTv — 02_data.sql : القنوات وروابط البث ومصادرها
-- مولّد تلقائيًا بواسطة supabase/generate_data.mjs بتاريخ ${checkedAt.slice(0, 10)}
-- المصدر: https://github.com/iptv-org/iptv (روابط عامة ومتاحة مجانًا)
--
--   ${rows.length} قناة · ${nStreams} رابط بث · ${sources.length} مصدر · ${countries} دولة
--   ${checked ? `فُحصت كل الروابط وقت التوليد (${checkedAt.slice(0, 10)})، وتُضاف «غير مفحوصة» ليُعاد فحصها قبل النشر.` : 'الروابط لم تُفحص وقت التوليد.'}
--
-- شغّله بعد 01_schema.sql (Supabase → SQL Editor → New query → الصق → Run).
-- آمن لإعادة التشغيل: يتجاهل الموجود مسبقًا ولا يكرره.
--
-- ⚠️ القنوات لا تظهر في الموقع فورًا: تدخل «بانتظار المراجعة». افتح لوحة التحكم ← «قيد المراجعة»
--    ← افحص الروابط ← وافق على القنوات الجاهزة (المكررة والمعطّلة مفصولة في تبويبات خاصة).
--
-- المحتوى:
--   1) مصادر البث     — قائمة iptv-org لكل دولة
--   2) القنوات         — صف لكل قناة، مرتبة حسب رقمها (الدول العربية أولًا) ومقسّمة حسب الدولة (تدخل بانتظار المراجعة)
--   3) روابط البث      — صف لكل رابط (السيرفرات)، الأولوية 0 تُجرَّب أولًا${nManual ? `
--   3ب) روابط يدوية    — ${nManual} رابط من قوائم خارجية، بلا مصدر` : ''}
--   4) تحديث عدّادات المصادر
-- ════════════════════════════════════════════════════════════════════════════
begin;

-- ─── 1) مصادر البث ──────────────────────────────────────────────────────────
insert into public.playlist_sources (name, url, status, last_import_at) values
${sources.map((s, i) => `  (${sq(s.name)}, ${sq(s.url)}, 'ready', ${sq(checkedAt)})${i < sources.length - 1 ? ',' : ''}`).join('\n')}
on conflict (url) do nothing;

-- ─── 2) القنوات ─────────────────────────────────────────────────────────────
-- الأعمدة: المعرّف، الرقم، الاسم، أسماء بديلة، الشبكة، الشعار، الشعار سليم، الدولة، الفئة،
--          فئات إضافية، اللغة، الجودة، الموقع، مميزة
insert into public.channels (uid, number, name, alt_names, network, logo_url, logo_status, country_code, category_slug,
                             extra_categories, language_code, quality, website, is_featured, is_published)
select v.uid, v.number, v.name, v.alt, v.network, v.logo,
       case when v.logo_ok then 'ok' else 'unknown' end,
       co.code, coalesce(cat.slug, 'general'), v.extra, l.code, v.quality, v.website, v.featured, true
from (values
${block(channelRow, g => g.rows.length)}
) as v(uid, number, name, alt, network, logo, logo_ok, country, category, extra, language, quality, website, featured)
left join public.countries  co  on co.code  = v.country
left join public.categories cat on cat.slug = v.category
left join public.languages  l   on l.code   = v.language
on conflict (uid) do nothing;

-- ─── 3) روابط البث ──────────────────────────────────────────────────────────
-- الأعمدة: معرّف القناة، الأولوية (0 تُجرَّب أولًا)، الرابط، الجودة
insert into public.streams (channel_id, source_id, url, quality, priority, status, http_status, response_ms, last_checked_at)
select c.id, s.id, v.url, v.quality, v.priority, 'unknown', null, null, null
from (values
${block(streamRows(false), countOf(false))}
) as v(uid, priority, url, quality)
join public.channels c on c.uid = v.uid
left join public.playlist_sources s on s.url = 'https://iptv-org.github.io/iptv/countries/' || lower(c.country_code) || '.m3u'
on conflict (url) do nothing;
${nManual ? `
-- ─── 3ب) روابط مضافة يدويًا (${nManual}) ─────────────────────────────────────
-- من قوائم خارجية، فُحصت مثل غيرها. بلا مصدر (source_id = null) فلا تُحذف عند تحديث المصادر.
-- الأعمدة: معرّف القناة، الأولوية (0 تُجرَّب أولًا)، الرابط، الجودة
insert into public.streams (channel_id, source_id, url, quality, priority, status, http_status, response_ms, last_checked_at)
select c.id, null, v.url, v.quality, v.priority, 'unknown', null, null, null
from (values
${block(streamRows(true), countOf(true))}
) as v(uid, priority, url, quality)
join public.channels c on c.uid = v.uid
on conflict (url) do nothing;
` : ''}
-- ─── 4) تحديث عدّادات المصادر ───────────────────────────────────────────────
update public.playlist_sources p set
  stream_count  = (select count(*) from public.streams where source_id = p.id),
  channel_count = (select count(distinct channel_id) from public.streams where source_id = p.id);

commit;

-- للتحقق (المتوقع: ${rows.length} قناة · ${nStreams} رابط · ${sources.length} مصدر):
select (select count(*) from public.channels)         as channels,
       (select count(*) from public.streams)          as streams,
       (select count(*) from public.playlist_sources) as sources;
`;
}
// @@END buildDataSql

// نسخة الديمو للوحة التحكم («استعادة نسخة الديمو»): نفس محتوى 02_data.sql بصيغة JSON مضغوطة في data/demo.json
function writeDemoJson({ rows, sources, checkedAt }) {
  const strip = o => Object.fromEntries(Object.entries(o).filter(([, v]) => v != null && v !== false && !(Array.isArray(v) && !v.length)));
  const demo = {
    app: 'MTC-iPTv', kind: 'demo', version: 1, generated_at: checkedAt,
    sources: sources.map(s => ({ name: s.name, url: s.url })),
    channels: rows.map(r => strip({ uid: r.uid, number: r.number, name: r.name, alt: r.alt, network: r.network, logo: r.logo,
      country: r.country, category: r.category, extra: r.extra, language: r.language, quality: r.quality, website: r.website, featured: r.featured,
      streams: r.streams.map(st => strip({ url: st.url, quality: st.quality, manual: st.manual })) }))
  };
  const dir = path.join(DIR, '..', 'data');
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(path.join(dir, 'demo.json'), JSON.stringify(demo));
  console.log(`data/demo.json: ${rows.length} قناة`);
}
// @@END writeDemoJson

