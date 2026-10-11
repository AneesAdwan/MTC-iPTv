// ════════════════════════════════════════════════════════════════════════════
// تمرير روابط بعض النطاقات عبر وسيطك الخاص (Cloudflare Worker) لحل CORS و http و 403.
// الإعداد في لوحة الإدارة ← الإعدادات العامة ← «وسيط البث». يُحفظ في site_settings.proxy:
//   { "url": "https://<اسمك>.workers.dev/", "hosts": ["hadara.ps", "alfajertv.com"] }
// أي رابط بثّ نطاقه ضمن القائمة يُلفّ تلقائيًا في المشغّل وفي فحص الروابط. البقية تبقى مباشرة.
// الوسيط يخصّك أنت، ويُستعمل للقنوات المرخّصة لك فقط.
// ════════════════════════════════════════════════════════════════════════════

/** هل نطاق هذا الرابط ضمن قائمة الوسيط؟ */
export function needsProxy(url, cfg) {
  if (!cfg?.url || !Array.isArray(cfg.hosts) || !cfg.hosts.length || !/^https?:\/\//i.test(url || '')) return false;
  try {
    const host = new URL(url).hostname.toLowerCase();
    return cfg.hosts.some(h => { h = String(h).trim().toLowerCase().replace(/^https?:\/\//, '').replace(/\/.*$/, ''); return h && (host === h || host.endsWith('.' + h)); });
  } catch { return false; }
}

/** يلفّ الرابط عبر الوسيط إذا كان نطاقه ضمن القائمة، وإلا يعيده كما هو */
export function proxied(url, cfg) {
  return needsProxy(url, cfg) ? cfg.url.replace(/\/+$/, '') + '/?url=' + encodeURIComponent(url) : url;
}
