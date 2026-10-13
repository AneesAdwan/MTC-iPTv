// ════════════════════════════════════════════════════════════════════════════
// MTC-iPTv — مزامنة جدول البث (EPG) من مصادر XMLTV عامة إلى Supabase.
// يعمل تلقائيًا عبر GitHub Actions (.github/workflows/epg.yml) كل 12 ساعة.
//
// البيئة المطلوبة (من GitHub Secrets — لا تُكتب في المستودع):
//   SUPABASE_URL                عنوان مشروع Supabase
//   SUPABASE_SERVICE_ROLE_KEY   مفتاح الخدمة (للكتابة فقط عبر هذا السكربت)
//
// التشغيل محليًا للتجربة:
//   SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... node supabase/epg_sync.mjs
// Node 20+ (fetch مدمج). لا مكتبات خارجية.
// ════════════════════════════════════════════════════════════════════════════
import zlib from 'node:zlib';

const URL = process.env.SUPABASE_URL?.replace(/\/$/, '');
const KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!URL || !KEY) { console.error('✗ SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY مطلوبة'); process.exit(1); }

// مصادر XMLTV بالترتيب — كل مصدر يُكمّل الناقص. سهلة التعديل.
const SOURCES = [
  { name: 'epgshare01-AR', url: 'https://epgshare01.online/epgshare01/epg_ripper_AR1.xml.gz' },
  { name: 'epgshare01-SA', url: 'https://epgshare01.online/epgshare01/epg_ripper_SA1.xml.gz' },
  { name: 'epgshare01-AE', url: 'https://epgshare01.online/epgshare01/epg_ripper_AE1.xml.gz' },
  { name: 'epgshare01-QA', url: 'https://epgshare01.online/epgshare01/epg_ripper_QA1.xml.gz' },
  { name: 'epgshare01-EG', url: 'https://epgshare01.online/epgshare01/epg_ripper_EG1.xml.gz' },
];

const normName = n => String(n || '').toLowerCase()
  .replace(/\s*[([][^)\]]*[)\]]/g, '')
  .replace(/\b(hd|fhd|sd|uhd|4k|tv)\b/g, '')
  .replace(/[\s\-_.:'"!?&*/\\|،]+/g, '');

const rest = async (path, opts = {}) => {
  const r = await fetch(`${URL}/rest/v1/${path}`, {
    ...opts,
    headers: { apikey: KEY, Authorization: `Bearer ${KEY}`, 'Content-Type': 'application/json', ...(opts.headers || {}) },
  });
  if (!r.ok) throw new Error(`${r.status} ${await r.text()}`);
  return r.status === 204 ? null : r.json();
};
const rpc = (fn, body = {}) => rest(`rpc/${fn}`, { method: 'POST', body: JSON.stringify(body) });

// فكّ كيانات XML الأساسية
const unesc = s => String(s || '').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&amp;/g, '&').replace(/&quot;/g, '"').replace(/&apos;/g, "'").trim();
// وقت XMLTV: 20261013180000 +0300 → Date (UTC)
function parseXmltvTime(s) {
  const m = String(s).match(/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(?:\s*([+-]\d{4}))?/);
  if (!m) return null;
  const [, Y, Mo, D, H, Mi, S, tz] = m;
  const off = tz ? (tz[0] === '-' ? 1 : -1) * (parseInt(tz.slice(1, 3)) * 60 + parseInt(tz.slice(3, 5))) : 0;
  return new Date(Date.UTC(+Y, +Mo - 1, +D, +H, +Mi, +S) + off * 60000);
}

async function fetchXml(src) {
  const r = await fetch(src.url, { headers: { 'User-Agent': 'MTC-iPTv-EPG/1.0' } });
  if (!r.ok) throw new Error(`${r.status}`);
  const buf = Buffer.from(await r.arrayBuffer());
  return src.url.endsWith('.gz') ? zlib.gunzipSync(buf).toString('utf8') : buf.toString('utf8');
}

// يحلّل XMLTV: يرجّع { byId: Map(channelId → [prog]), names: Map(normName → channelId) }
function parseXmltv(xml) {
  const byId = new Map();
  const names = new Map();
  // أسماء القنوات
  for (const m of xml.matchAll(/<channel\s+id="([^"]+)"[^>]*>([\s\S]*?)<\/channel>/g)) {
    const id = m[1];
    for (const dn of m[2].matchAll(/<display-name[^>]*>([\s\S]*?)<\/display-name>/g)) {
      const nn = normName(unesc(dn[1])); if (nn) names.set(nn, id);
    }
  }
  // البرامج
  for (const m of xml.matchAll(/<programme\s+([^>]*?)>([\s\S]*?)<\/programme>/g)) {
    const attrs = m[1], body = m[2];
    const ch = (attrs.match(/channel="([^"]+)"/) || [])[1];
    const start = (attrs.match(/start="([^"]+)"/) || [])[1];
    const stop = (attrs.match(/stop="([^"]+)"/) || [])[1];
    if (!ch || !start) continue;
    const s = parseXmltvTime(start), e = stop ? parseXmltvTime(stop) : null;
    if (!s) continue;
    const title = unesc((body.match(/<title[^>]*>([\s\S]*?)<\/title>/) || [])[1]);
    const desc = unesc((body.match(/<desc[^>]*>([\s\S]*?)<\/desc>/) || [])[1]);
    const cat = unesc((body.match(/<category[^>]*>([\s\S]*?)<\/category>/) || [])[1]);
    const icon = (body.match(/<icon[^>]*src="([^"]+)"/) || [])[1] || null;
    if (!title) continue;
    if (!byId.has(ch)) byId.set(ch, []);
    byId.get(ch).push({ start_at: s, end_at: e, title, description: desc || null, category: cat || null, icon_url: icon });
  }
  return { byId, names };
}

async function main() {
  const t0 = Date.now();
  const channels = await rest('channels?select=uid,epg_id,name,alt_names&is_published=eq.true');
  console.log(`قنوات منشورة: ${channels.length}`);

  const now = Date.now();
  const from = now - 36 * 3600e3;       // من أمس
  const to = now + 3 * 24 * 3600e3;     // حتى 3 أيام
  const collected = new Map();          // channel_uid → [prog]
  const errors = [];
  const usedSource = new Set();

  for (const src of SOURCES) {
    // القنوات التي ما زالت بلا بيانات
    const pending = channels.filter(c => !collected.has(c.uid));
    if (!pending.length) break;
    try {
      console.log(`↓ ${src.name} …`);
      const { byId, names } = parseXmltv(await fetchXml(src));
      let hit = 0;
      for (const c of pending) {
        const key = (c.epg_id || c.uid || '').replace(/@.*/, '');
        let progs = byId.get(key) || byId.get(c.uid);
        if (!progs) { // مطابقة بالاسم بعد التطبيع
          const alts = [c.name, ...(c.alt_names || [])];
          for (const a of alts) { const id = names.get(normName(a)); if (id && byId.get(id)) { progs = byId.get(id); break; } }
        }
        if (!progs?.length) continue;
        const rows = progs
          .filter(p => p.end_at && +p.end_at > from && +p.start_at < to)
          .map(p => ({ channel_uid: c.uid, start_at: p.start_at.toISOString(), end_at: p.end_at.toISOString(), title: p.title, description: p.description, category: p.category, icon_url: p.icon_url, source: src.name }));
        if (rows.length) { collected.set(c.uid, rows); hit++; usedSource.add(src.name); }
      }
      console.log(`  طابق ${hit} قناة`);
    } catch (e) {
      console.warn(`  ✗ ${src.name}: ${e.message}`);
      errors.push(`${src.name}: ${e.message}`);
    }
  }

  // رفع على دفعات
  let total = 0;
  const all = [...collected.values()].flat();
  for (let i = 0; i < all.length; i += 500) {
    const batch = all.slice(i, i + 500);
    try {
      await rest('epg_programmes?on_conflict=channel_uid,start_at', {
        method: 'POST',
        headers: { Prefer: 'resolution=merge-duplicates,return=minimal' },
        body: JSON.stringify(batch),
      });
      total += batch.length;
    } catch (e) { errors.push(`upsert: ${e.message}`); }
  }

  let cleaned = 0;
  try { cleaned = await rpc('epg_cleanup'); } catch (e) { errors.push(`cleanup: ${e.message}`); }

  await rest('epg_runs', { method: 'POST', headers: { Prefer: 'return=minimal' }, body: JSON.stringify({
    source: [...usedSource].join(', ') || 'none', channels_ok: collected.size, programmes: total, errors: errors.join(' | ') || null,
  }) }).catch(() => {});

  const cov = channels.length ? Math.round((collected.size / channels.length) * 100) : 0;
  console.log(`\n✓ تم: ${collected.size}/${channels.length} قناة (${cov}%) · ${total} برنامج · حُذف ${cleaned} · ${((Date.now() - t0) / 1000).toFixed(1)}s`);
  if (errors.length) console.log('أخطاء:', errors.join(' | '));
}

main().catch(e => { console.error('✗', e); process.exit(1); });
