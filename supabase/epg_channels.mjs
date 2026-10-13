// ════════════════════════════════════════════════════════════════════════════
// يولّد channels.xml لـ grabber مشروع iptv-org/epg، يحوي قنواتنا فقط.
// لكل uid (= xmltv_id) يبحث في ملفات sites/**/*.channels.xml عن المصادر المتاحة.
//
// البيئة: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, EPG_DIR (مجلد مستودع iptv-org/epg المستنسخ)
// الإخراج: <EPG_DIR>/channels.xml
// ════════════════════════════════════════════════════════════════════════════
import fs from 'node:fs';
import path from 'node:path';

const URL = process.env.SUPABASE_URL?.replace(/\/$/, '');
const KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const EPG_DIR = process.env.EPG_DIR || 'epg';
const MAX_SITES = 2; // أقصى عدد مصادر لكل قناة (لتحديد حجم الجلب)
if (!URL || !KEY) { console.error('✗ SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY مطلوبة'); process.exit(1); }

const sitesDir = path.join(EPG_DIR, 'sites');
if (!fs.existsSync(sitesDir)) { console.error(`✗ لا يوجد ${sitesDir} — تأكد من استنساخ iptv-org/epg`); process.exit(1); }

// 1) قنواتنا المنشورة: المعرّف = epg_id وإلا uid (بعد حذف @…)
const res = await fetch(`${URL}/rest/v1/channels?select=uid,epg_id&is_published=eq.true`, {
  headers: { apikey: KEY, Authorization: `Bearer ${KEY}` },
});
if (!res.ok) { console.error('✗ تعذّر جلب القنوات:', res.status); process.exit(1); }
const chans = await res.json();
const wanted = new Set(chans.map(c => (c.epg_id || c.uid || '').replace(/@.*/, '')).filter(Boolean));
console.log(`قنواتنا: ${wanted.size} معرّف`);

// 2) امسح كل ملفات *.channels.xml واجمع أسطر القنوات المطابقة
const found = new Map(); // xmltv_id → [سطر <channel>…]
function walk(dir) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p);
    else if (e.name.endsWith('.channels.xml')) scan(p);
  }
}
function scan(file) {
  const xml = fs.readFileSync(file, 'utf8');
  for (const m of xml.matchAll(/<channel\b[^>]*>[\s\S]*?<\/channel>/g)) {
    const line = m[0];
    const id = (line.match(/xmltv_id="([^"]+)"/) || [])[1];
    if (!id || !wanted.has(id)) continue;
    if (!found.has(id)) found.set(id, []);
    const arr = found.get(id);
    if (arr.length < MAX_SITES) arr.push(line.trim());
  }
}
walk(sitesDir);

// 3) اكتب channels.xml
const lines = [...found.values()].flat();
const out = `<?xml version="1.0" encoding="UTF-8"?>\n<channels>\n${lines.join('\n')}\n</channels>\n`;
fs.writeFileSync(path.join(EPG_DIR, 'channels.xml'), out);
console.log(`✓ channels.xml: ${found.size} قناة لها مصدر · ${lines.length} سطر جلب`);
