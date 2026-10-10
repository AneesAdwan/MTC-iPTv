// ════════════════════════════════════════════════════════════════════════════
// MTC-iPTv — عامل الخدمة: يجعل الموقع قابلًا للتثبيت كتطبيق، ويفتح الواجهة حتى لو انقطع الاتصال.
// الاستراتيجية: «الشبكة أولًا» لملفات الموقع (تصل التحديثات فورًا)، والنسخة المحفوظة عند انقطاع الاتصال.
// لا يتدخل أبدًا في البث المباشر أو قاعدة البيانات أو لوحة الإدارة.
// ════════════════════════════════════════════════════════════════════════════
const CACHE = 'mtc-shell-v1';
const SHELL = ['./', 'index.html', 'config.js', 'manifest.webmanifest', 'src/app.js', 'src/player.js', 'src/supabase.js', 'src/icons.js',
  'src/catalog.js', 'src/social.js', 'src/version.js', 'src/install.js', 'src/styles.css', 'img/mtc-iptv-icon.svg', 'img/mtc-group-emblem.svg',
  'img/app-icon-192.png', 'img/app-icon-512.png'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(SHELL)).catch(() => {}));
  self.skipWaiting();
});
self.addEventListener('activate', e => {
  e.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))).then(() => self.clients.claim()));
});
self.addEventListener('fetch', e => {
  const req = e.request, url = new URL(req.url);
  // فقط ملفات الموقع نفسه (GET) — بدون البث وSupabase واللوحة وملف الديمو الكبير
  if (req.method !== 'GET' || url.origin !== location.origin || /\/asadmin\/|\/data\/|\.m3u8?$/i.test(url.pathname)) return;
  e.respondWith(fetch(req).then(res => {
    if (res.ok && res.type === 'basic') { const copy = res.clone(); caches.open(CACHE).then(c => c.put(req, copy)); }
    return res;
  }).catch(() => caches.match(req, { ignoreSearch: true }).then(r => r || caches.match('index.html'))));
});
