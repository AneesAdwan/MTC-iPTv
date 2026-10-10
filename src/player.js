// ════════════════════════════════════════════════════════════════════════════
// مشغّل MTC-iPTv — مشغّل بث مباشر بأسلوب يوتيوب مبني على hls.js
//
// createPlayer(host, opts) → { load(item), setTheater(bool), osd(text), destroy() }
//   item : { streams:[{url, server, quality}], title, subtitle, logo, number, startIndex }
//   opts : { onNext, onPrev, onTheater, onReport, onDigit, onKey, channels }   (كلها اختيارية)
//   channels : { modes:[[k, label]], list(mode) → [{id, number, name, logo, sub}], current() → id, pick(id) }
//              قائمة القنوات الجانبية داخل المشغّل (تفتح من اليسار في ملء الشاشة) للتنقل دون الخروج
//
// الميزات: شريط تقدّم للبث (DVR) مع معاينة الوقت، الجودة/السرعة/الصوت/الترجمة/السيرفر من قائمة
// الإعدادات، تبديل تلقائي للسيرفر عند التعطل، إحصاءات للمهتمين، اختصارات لوحة مفاتيح يوتيوب،
// إيماءات اللمس، قائمة الزر الأيمن، صورة داخل صورة، وضع المسرح، ملء الشاشة، وحفظ تفضيلات الصوت والجودة.
// ════════════════════════════════════════════════════════════════════════════

const I = {
  play: 'M8 5v14l11-7z',
  pause: 'M6 5h4v14H6zM14 5h4v14h-4z',
  prev: 'M6 6h2v12H6zM9.5 12L18 18V6z',
  next: 'M16 6h2v12h-2zM6 18l8.5-6L6 6z',
  vol: 'M3 9v6h4l5 5V4L7 9H3zm13.5 3A4.5 4.5 0 0014 8v8a4.5 4.5 0 002.5-4zM14 3.2v2.1a7 7 0 010 13.4v2.1a9 9 0 000-17.6z',
  volLow: 'M3 9v6h4l5 5V4L7 9H3zm13.5 3A4.5 4.5 0 0014 8v8a4.5 4.5 0 002.5-4z',
  mute: 'M16.5 12A4.5 4.5 0 0014 8v2.2l2.5 2.5V12zM19 12c0 .9-.2 1.8-.5 2.6l1.5 1.5A8.8 8.8 0 0021 12a9 9 0 00-7-8.8v2.1a7 7 0 015 6.7zM4.3 3L3 4.3 7.7 9H3v6h4l5 5v-6.7l4.3 4.3c-.7.5-1.4.9-2.3 1.2v2.1a9 9 0 003.7-1.8l2 2 1.3-1.3L4.3 3zM12 4L9.9 6.1 12 8.2V4z',
  gear: 'M19.4 13a7.5 7.5 0 000-2l2.1-1.6a.5.5 0 00.1-.6l-2-3.5a.5.5 0 00-.6-.2l-2.5 1a7.3 7.3 0 00-1.7-1l-.4-2.6a.5.5 0 00-.5-.5h-4a.5.5 0 00-.5.4l-.4 2.7a7.3 7.3 0 00-1.7 1l-2.5-1a.5.5 0 00-.6.2l-2 3.5a.5.5 0 00.1.6L4.6 11a7.5 7.5 0 000 2l-2.1 1.6a.5.5 0 00-.1.6l2 3.5a.5.5 0 00.6.2l2.5-1c.5.4 1.1.7 1.7 1l.4 2.6a.5.5 0 00.5.5h4a.5.5 0 00.5-.4l.4-2.7c.6-.3 1.2-.6 1.7-1l2.5 1a.5.5 0 00.6-.2l2-3.5a.5.5 0 00-.1-.6L19.4 13zM12 15.5a3.5 3.5 0 110-7 3.5 3.5 0 010 7z',
  cc: 'M19 4H5a2 2 0 00-2 2v12a2 2 0 002 2h14a2 2 0 002-2V6a2 2 0 00-2-2zm-8 7H9.5v-.5h-2v3h2V13H11v1a1 1 0 01-1 1H7a1 1 0 01-1-1v-4a1 1 0 011-1h3a1 1 0 011 1v1zm7 0h-1.5v-.5h-2v3h2V13H18v1a1 1 0 01-1 1h-3a1 1 0 01-1-1v-4a1 1 0 011-1h3a1 1 0 011 1v1z',
  pip: 'M19 11h-8v6h8v-6zm4 8V5a2 2 0 00-2-2H3a2 2 0 00-2 2v14a2 2 0 002 2h18a2 2 0 002-2zm-2 0H3V5h18v14z',
  theater: 'M19 6H5a2 2 0 00-2 2v8a2 2 0 002 2h14a2 2 0 002-2V8a2 2 0 00-2-2zm0 10H5V8h14v8z',
  theaterOn: 'M21 7H3v10h18V7zm-2 8H5V9h14v6z',
  fs: 'M7 14H5v5h5v-2H7v-3zm-2-4h2V7h3V5H5v5zm12 7h-3v2h5v-5h-2v3zM14 5v2h3v3h2V5h-5z',
  fsExit: 'M5 16h3v3h2v-5H5v2zm3-8H5v2h5V5H8v3zm6 11h2v-3h3v-2h-5v5zm2-11V5h-2v5h5V8h-3z',
  check: 'M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4z',
  chev: 'M10 6L8.6 7.4 13.2 12l-4.6 4.6L10 18l6-6z',
  chevL: 'M15.4 7.4L14 6l-6 6 6 6 1.4-1.4L10.8 12z',
  alert: 'M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z',
  replay: 'M12 5V1L7 6l5 5V7a6 6 0 11-6 6H4a8 8 0 108-8z',
  flag: 'M14.4 6L14 4H5v17h2v-7h5.6l.4 2h7V6z',
  server: 'M20 3H4v7h16V3zM7 7.5a1.5 1.5 0 110-3 1.5 1.5 0 010 3zM20 14H4v7h16v-7zM7 18.5a1.5 1.5 0 110-3 1.5 1.5 0 010 3z',
  speed: 'M20.4 8.6l-1.2 1.8a8 8 0 01-.2 7.6H5A8 8 0 0115.6 6.8l1.8-1.2A10 10 0 003.3 19a2 2 0 001.7 1h14a2 2 0 001.7-1 10 10 0 00-.3-10.4zM10.6 15.4a2 2 0 002.8 0l5.7-8.5-8.5 5.7a2 2 0 000 2.8z',
  tune: 'M3 17v2h6v-2H3zM3 5v2h10V5H3zm10 16v-2h8v-2h-8v-2h-2v6h2zM7 9v2H3v2h4v2h2V9H7zm14 4v-2H11v2h10zm-6-4h2V7h4V5h-4V3h-2v6z',
  audio: 'M12 3v10.6A4 4 0 1014 17V7h4V3h-6z',
  stats: 'M11 7h2v2h-2zm0 4h2v6h-2zm1-9a10 10 0 100 20 10 10 0 000-20zm0 18a8 8 0 110-16 8 8 0 010 16z',
  keyboard: 'M20 5H4a2 2 0 00-2 2v10a2 2 0 002 2h16a2 2 0 002-2V7a2 2 0 00-2-2zm-9 3h2v2h-2V8zm0 3h2v2h-2v-2zM8 8h2v2H8V8zm0 3h2v2H8v-2zm-1 2H5v-2h2v2zm0-3H5V8h2v2zm9 7H8v-2h8v2zm0-4h-2v-2h2v2zm0-3h-2V8h2v2zm3 3h-2v-2h2v2zm0-3h-2V8h2v2z',
  link: 'M3.9 12a3.1 3.1 0 013.1-3.1h4V7H7a5 5 0 000 10h4v-1.9H7A3.1 3.1 0 013.9 12zM8 13h8v-2H8v2zm9-6h-4v1.9h4a3.1 3.1 0 010 6.2h-4V17h4a5 5 0 000-10z',
  close: 'M19 6.4L17.6 5 12 10.6 6.4 5 5 6.4 10.6 12 5 17.6 6.4 19 12 13.4 17.6 19 19 17.6 13.4 12z',
  rew: 'M11 18V6l-8.5 6 8.5 6zm.5-6l8.5 6V6l-8.5 6z',
  fwd: 'M4 18l8.5-6L4 6v12zm9-12v12l8.5-6L13 6z',
  list: 'M3 13h2v-2H3v2zm0 4h2v-2H3v2zm0-8h2V7H3v2zm4 4h14v-2H7v2zm0 4h14v-2H7v2zM7 7v2h14V7H7z',
  search: 'M15.5 14h-.79l-.28-.27A6.47 6.47 0 0016 9.5 6.5 6.5 0 109.5 16c1.61 0 3.09-.59 4.23-1.57l.27.28v.79l5 4.99L20.49 19l-4.99-5zm-6 0C7.01 14 5 11.99 5 9.5S7.01 5 9.5 5 14 7.01 14 9.5 11.99 14 9.5 14z'
};
const pi = n => `<svg viewBox="0 0 24 24" class="pi" aria-hidden="true"><path d="${I[n]}"/></svg>`;
const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const fmt = s => { s = Math.max(0, Math.round(s)); const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60), x = String(s % 60).padStart(2, '0'); return h ? `${h}:${String(m).padStart(2, '0')}:${x}` : `${m}:${x}`; };
const qLabel = h => h >= 2160 ? '4K' : h >= 1440 ? 'QHD' : h >= 720 ? 'HD' : '';
const PREF_KEY = 'mtc-player';
const loadPrefs = () => { try { return { volume: 1, muted: false, quality: 0, ...JSON.parse(localStorage.getItem(PREF_KEY) || '{}') }; } catch { return { volume: 1, muted: false, quality: 0 }; } };
const savePrefs = p => { try { localStorage.setItem(PREF_KEY, JSON.stringify(p)); } catch { /* ignore */ } };
const SPEEDS = [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2];
const SHORTCUTS = [
  ['K / مسافة', 'تشغيل / إيقاف'], ['M', 'كتم الصوت'], ['F', 'ملء الشاشة'], ['T', 'وضع المسرح'], ['I', 'صورة داخل صورة'],
  ['C', 'الترجمة'], ['← / →', 'رجوع / تقديم 5 ثوانٍ'], ['J / L', 'رجوع / تقديم 10 ثوانٍ'], ['↑ / ↓', 'رفع / خفض الصوت'],
  ['End', 'العودة للبث المباشر'], ['Shift + N / P', 'القناة التالية / السابقة'], ['PageUp / PageDown', 'القناة السابقة / التالية'],
  ['0 – 9', 'إدخال رقم قناة'], ['G', 'قائمة القنوات (ملء الشاشة)'], ['< / >', 'خفض / رفع السرعة'], ['?', 'عرض الاختصارات']
];

// مكتبة hls.js تُحمَّل عند أول تشغيل فقط (لا تؤخر فتح الموقع)
const HLS_URL = 'https://cdn.jsdelivr.net/npm/hls.js@1.6.13/dist/hls.min.js';
let hlsReady;
export const loadHls = () => window.Hls ? Promise.resolve() : (hlsReady ||= new Promise(res => {
  const s = document.createElement('script');
  s.src = HLS_URL; s.onload = res; s.onerror = res; // عند الفشل نكمل بالتشغيل الأصلي إن أمكن
  document.head.appendChild(s);
}));

export function createPlayer(host, opts = {}) {
  const prefs = loadPrefs();
  host.innerHTML = `<div class="yt paused" tabindex="0" dir="ltr">
    <video playsinline preload="auto"></video>
    <div class="yt-shade"></div>
    <div class="yt-top" dir="rtl"><div class="yt-tlogo"></div><div class="yt-ttext"><b></b><small></small></div></div>
    <div class="yt-bezel"></div>
    <div class="yt-osd"></div>
    <div class="yt-pill"></div>
    <div class="yt-spin" hidden><i></i></div>
    <button class="yt-big" aria-label="تشغيل">${pi('play')}</button>
    <button class="yt-unmute" hidden dir="rtl">${pi('mute')}<span>اضغط لتشغيل الصوت</span></button>
    <div class="yt-ripple l"><span>${pi('rew')}<b>10 ثوانٍ</b></span></div><div class="yt-ripple r"><span>${pi('fwd')}<b>10 ثوانٍ</b></span></div>
    <div class="yt-err" hidden dir="rtl"><div class="yt-err-in">${pi('alert')}<h4></h4><p></p>
      <div class="yt-err-act"><button data-e="retry">${pi('replay')} إعادة المحاولة</button><button data-e="server">${pi('server')} سيرفر آخر</button><button data-e="next">${pi('next')} القناة التالية</button><button data-e="report">${pi('flag')} إبلاغ</button></div></div></div>
    <div class="yt-stats" hidden><button class="yt-x" data-x="stats" aria-label="إغلاق">${pi('close')}</button><table></table></div>
    <div class="yt-help" hidden dir="rtl"><div class="yt-help-in"><header><b>اختصارات لوحة المفاتيح</b><button class="yt-x" data-x="help">${pi('close')}</button></header>
      <dl>${SHORTCUTS.map(([k, d]) => `<dt><kbd>${k}</kbd></dt><dd>${d}</dd>`).join('')}</dl></div></div>
    <div class="yt-ctx" hidden dir="rtl"></div>
    <button class="yt-side l" data-a="prev" title="القناة السابقة" hidden>${pi('chevL')}</button>
    <button class="yt-side r" data-a="next" title="القناة التالية" hidden>${pi('chev')}</button>
    <aside class="yt-chl" hidden dir="rtl" aria-label="قائمة القنوات">
      <header><b>${pi('list')} القنوات <em class="yt-chl-n"></em></b><button class="yt-x" data-x="chl" aria-label="إغلاق">${pi('close')}</button></header>
      <label class="yt-chl-q">${pi('search')}<input type="search" placeholder="ابحث بالاسم أو الرقم…" autocomplete="off"></label>
      <div class="yt-chl-tabs"></div>
      <div class="yt-chl-list" tabindex="-1"></div>
      <footer>↑ ↓ للتنقل · Enter للتشغيل · G للإغلاق</footer>
    </aside>
    <div class="yt-menu" hidden dir="rtl"><div class="yt-panel"></div></div>
    <div class="yt-bottom">
      <div class="yt-prog"><div class="yt-track"><i class="yt-buf"></i><i class="yt-hov"></i><i class="yt-play"></i></div><span class="yt-scrub"></span><div class="yt-tip"></div></div>
      <div class="yt-bar">
        <button data-a="prev" class="yt-zap" title="القناة السابقة (Shift+P)">${pi('prev')}</button>
        <button data-a="play" title="تشغيل (k)">${pi('play')}</button>
        <button data-a="next" class="yt-zap" title="القناة التالية (Shift+N)">${pi('next')}</button>
        <div class="yt-volw"><button data-a="mute" title="كتم الصوت (m)">${pi('vol')}</button><div class="yt-vol"><input type="range" min="0" max="1" step="0.01" aria-label="مستوى الصوت"><i></i></div></div>
        <button data-a="live" class="yt-live" title="الانتقال إلى البث المباشر"><i></i><span>مباشر</span></button>
        <span class="yt-time"></span>
        <span class="yt-sp"></span>
        <button data-a="cc" class="yt-cc" hidden title="الترجمة (c)">${pi('cc')}</button>
        <button data-a="channels" class="yt-chb" title="قائمة القنوات (g)" hidden>${pi('list')}</button>
        <button data-a="settings" class="yt-gear" title="الإعدادات">${pi('gear')}<em></em></button>
        <button data-a="pip" title="صورة داخل صورة (i)">${pi('pip')}</button>
        <button data-a="theater" class="yt-th" title="وضع المسرح (t)">${pi('theater')}</button>
        <button data-a="fs" title="ملء الشاشة (f)">${pi('fs')}</button>
      </div>
    </div>
  </div>`;

  const root = host.firstElementChild, $ = s => root.querySelector(s);
  const v = $('video'), spin = $('.yt-spin'), errBox = $('.yt-err'), menu = $('.yt-menu'), panel = $('.yt-panel');
  const prog = $('.yt-prog'), tip = $('.yt-tip'), volIn = $('.yt-vol input'), ctx = $('.yt-ctx');
  let hls = null, item = null, si = 0, tries = 0, destroyed = false, hideT = 0, watchdog = 0, osdT = 0, pillT = 0, bezelT = 0, statsT = 0;
  let clickT = 0, scrubbing = false, failed = new Set(), mutedByAutoplay = false;

  /* ───── أدوات عامة ───── */
  const setBtn = (a, icon, title) => { const b = $(`[data-a=${a}]`); b.innerHTML = pi(icon) + (a === 'settings' ? '<em></em>' : ''); if (title) b.title = title; };
  const osd = (html, ms = 1400) => { const o = $('.yt-osd'); o.innerHTML = html; o.classList.add('on'); clearTimeout(osdT); osdT = setTimeout(() => o.classList.remove('on'), ms); };
  const pill = text => { const p = $('.yt-pill'); p.textContent = text; p.classList.add('on'); clearTimeout(pillT); pillT = setTimeout(() => p.classList.remove('on'), 900); };
  const bezel = icon => { const b = $('.yt-bezel'); b.innerHTML = pi(icon); b.classList.remove('on'); void b.offsetWidth; b.classList.add('on'); clearTimeout(bezelT); bezelT = setTimeout(() => b.classList.remove('on'), 600); };
  const wake = () => {
    root.classList.add('show'); clearTimeout(hideT);
    hideT = setTimeout(() => { if (!v.paused && menu.hidden && !scrubbing) root.classList.remove('show'); }, 3000);
  };
  const range = () => {
    if (hls?.liveSyncPosition && v.seekable.length) return [v.seekable.start(0), v.seekable.end(v.seekable.length - 1)];
    return v.seekable.length ? [v.seekable.start(0), v.seekable.end(v.seekable.length - 1)] : [0, 0];
  };
  const liveEdge = () => hls?.liveSyncPosition ?? range()[1];
  const dvr = () => { const [a, b] = range(); return b - a > 45; };
  const behind = () => Math.max(0, liveEdge() - v.currentTime);
  const atLive = () => behind() < 12;

  /* ───── التشغيل ───── */
  const play = () => v.play().catch(() => { v.muted = true; mutedByAutoplay = true; $('.yt-unmute').hidden = false; v.play().catch(() => {}); });
  const toggle = () => { if (v.paused) { play(); bezel('play'); } else { v.pause(); bezel('pause'); } };
  const goLive = () => { const e = liveEdge(); if (e) v.currentTime = e; v.playbackRate = 1; play(); };
  const seekBy = s => { if (!dvr()) return; const [a] = range(); v.currentTime = Math.min(liveEdge(), Math.max(a, v.currentTime + s)); pill(`${s > 0 ? '+' : '−'}${Math.abs(s)} ث`); };
  const setVolume = (val, show = true) => {
    v.volume = Math.min(1, Math.max(0, val)); v.muted = v.volume === 0;
    if (show) pill(`${Math.round(v.volume * 100)}%`);
  };
  const toggleMute = () => { v.muted = !v.muted; if (!v.muted && v.volume === 0) v.volume = .5; mutedByAutoplay = false; $('.yt-unmute').hidden = true; bezel(v.muted ? 'mute' : 'vol'); };
  const fsEl = () => document.fullscreenElement || document.webkitFullscreenElement;
  const toggleFs = () => fsEl() ? (document.exitFullscreen || document.webkitExitFullscreen).call(document) : (root.requestFullscreen?.() || root.webkitRequestFullscreen?.() || v.webkitEnterFullscreen?.());
  const togglePip = () => document.pictureInPictureElement ? document.exitPictureInPicture() : v.requestPictureInPicture?.().catch(() => {});

  /* ───── تحميل البث والتبديل بين السيرفرات ───── */
  function fail(title, msg) {
    if (destroyed) return;
    clearTimeout(watchdog); spin.hidden = true;
    errBox.hidden = false;
    errBox.querySelector('h4').textContent = title;
    errBox.querySelector('p').textContent = msg;
    errBox.querySelector('[data-e=server]').hidden = !item || item.streams.length < 2;
    errBox.querySelector('[data-e=next]').hidden = !opts.onNext;
    errBox.querySelector('[data-e=report]').hidden = !opts.onReport;
  }

  /** ينتقل إلى السيرفر التالي الذي لم يفشل بعد؛ يرجع false إذا انتهت الخيارات */
  function failover(reason) {
    failed.add(si);
    const n = item.streams.length;
    for (let k = 1; k < n; k++) {
      const j = (si + k) % n;
      if (!failed.has(j)) { osd(`${pi('server')}<span>${esc(reason)} — جارٍ التبديل إلى السيرفر ${j + 1}</span>`, 2200); start(j); return true; }
    }
    return false;
  }

  function start(index) {
    clearTimeout(watchdog);
    try { hls?.destroy(); } catch { /* ignore */ }
    hls = null; tries = 0; si = index;
    errBox.hidden = true; menu.hidden = true;
    const s = item.streams[si];
    if (!s?.url) return fail('لا يوجد رابط بث', 'لم يتم العثور على رابط بث لهذه القناة.');
    if (location.protocol === 'https:' && s.url.startsWith('http:')) {
      if (!failover('رابط غير آمن')) fail('تعذّر التشغيل', 'روابط هذه القناة غير آمنة (http) ولا يسمح المتصفح بتشغيلها على موقع آمن.');
      return;
    }
    spin.hidden = false;
    watchdog = setTimeout(() => { if (!v.currentTime || v.readyState < 3) { if (!failover('السيرفر لا يستجيب')) fail('تعذّر بدء البث', 'قد يكون مصدر القناة متوقفًا أو محجوبًا في منطقتك. جرّب لاحقًا أو اختر قناة أخرى.'); } }, 16000);

    if (window.Hls?.isSupported()) {
      hls = new Hls({ lowLatencyMode: true, backBufferLength: 90, liveSyncDurationCount: 3, manifestLoadingMaxRetry: 1, manifestLoadingTimeOut: 10000, levelLoadingTimeOut: 10000, fragLoadingTimeOut: 15000, capLevelToPlayerSize: false });
      hls.on(Hls.Events.MANIFEST_PARSED, () => {
        const pref = prefs.quality;
        if (pref) {
          const ok = hls.levels.map((l, i) => [i, l.height]).filter(([, h]) => h && h <= pref).sort((a, b) => b[1] - a[1])[0];
          if (ok) hls.currentLevel = ok[0];
        }
        hls.subtitleDisplay = false;
        play(); syncUi();
      });
      hls.on(Hls.Events.LEVEL_SWITCHED, syncUi);
      hls.on(Hls.Events.SUBTITLE_TRACKS_UPDATED, syncUi);
      hls.on(Hls.Events.AUDIO_TRACKS_UPDATED, syncUi);
      hls.on(Hls.Events.ERROR, (_, d) => {
        if (!d.fatal) return;
        if (d.type === Hls.ErrorTypes.MEDIA_ERROR && tries++ < 2) { hls.recoverMediaError(); return; }
        if (d.type === Hls.ErrorTypes.NETWORK_ERROR && tries++ < 1) { setTimeout(() => hls?.startLoad(), 1500); return; }
        if (!failover('تعذّر الاتصال بالسيرفر')) fail('تعذّر تشغيل القناة', 'جميع سيرفرات هذه القناة لا تستجيب حاليًا. قد يكون البث متوقفًا مؤقتًا.');
      });
      hls.loadSource(s.url);
      hls.attachMedia(v);
    } else if (v.canPlayType('application/vnd.apple.mpegurl')) {
      v.src = s.url;
      v.onerror = () => { if (!failover('تعذّر الاتصال بالسيرفر')) fail('تعذّر تشغيل القناة', 'جميع سيرفرات هذه القناة لا تستجيب حاليًا.'); };
      play();
    } else {
      fail('المتصفح غير مدعوم', 'المتصفح لا يدعم تشغيل البث المباشر (HLS). استخدم متصفحًا حديثًا.');
    }
    syncUi();
  }

  /* ───── تحديث الواجهة ───── */
  function syncUi() {
    if (destroyed) return;
    setBtn('play', v.paused ? 'play' : 'pause', v.paused ? 'تشغيل (k)' : 'إيقاف مؤقت (k)');
    setBtn('mute', v.muted || !v.volume ? 'mute' : v.volume < .5 ? 'volLow' : 'vol', v.muted ? 'إلغاء الكتم (m)' : 'كتم الصوت (m)');
    root.classList.toggle('paused', v.paused);
    volIn.value = v.muted ? 0 : v.volume;
    $('.yt-vol i').style.width = `${(v.muted ? 0 : v.volume) * 100}%`;
    setBtn('fs', fsEl() ? 'fsExit' : 'fs', fsEl() ? 'إنهاء ملء الشاشة (f)' : 'ملء الشاشة (f)');
    root.classList.toggle('fs', !!fsEl());
    $('[data-a=pip]').hidden = !document.pictureInPictureEnabled;
    $('[data-a=theater]').hidden = !opts.onTheater || !!fsEl();
    root.querySelectorAll('.yt-zap').forEach(b => { b.hidden = !(b.dataset.a === 'next' ? opts.onNext : opts.onPrev); });
    root.querySelectorAll('.yt-side').forEach(b => { b.hidden = !fsEl() || !(b.dataset.a === 'next' ? opts.onNext : opts.onPrev); });
    $('[data-a=channels]').hidden = !opts.channels || !fsEl();
    if (!fsEl() && chlOpen()) toggleChl(false);
    const h = hls && hls.currentLevel >= 0 ? hls.levels[hls.currentLevel]?.height : (hls?.levels?.[hls.loadLevel]?.height || v.videoHeight);
    $('.yt-gear em').textContent = qLabel(h || 0);
    const cc = $('[data-a=cc]');
    cc.hidden = !hls?.subtitleTracks?.length;
    cc.classList.toggle('on', !!hls && hls.subtitleTrack >= 0 && hls.subtitleDisplay);
  }

  function tick() {
    if (destroyed || scrubbing) return;
    const [a, b] = range(), span = b - a, isDvr = dvr();
    root.classList.toggle('dvr', isDvr);
    const live = $('.yt-live');
    live.classList.toggle('on', atLive());
    live.title = atLive() ? 'أنت تشاهد البث المباشر' : 'الانتقال إلى البث المباشر (End)';
    $('.yt-time').textContent = isDvr && !atLive() ? `−${fmt(behind())}` : '';
    const played = isDvr ? Math.min(1, (v.currentTime - a) / span) : 1;
    $('.yt-play').style.width = `${played * 100}%`;
    $('.yt-scrub').style.left = `${played * 100}%`;
    let buf = 0;
    for (let i = 0; i < v.buffered.length; i++) if (v.buffered.start(i) <= v.currentTime + 1) buf = Math.max(buf, v.buffered.end(i));
    $('.yt-buf').style.width = `${isDvr ? Math.min(1, (buf - a) / span) * 100 : 100}%`;
  }

  /* ───── شريط التقدّم ───── */
  const ratioAt = e => { const r = prog.getBoundingClientRect(); return Math.min(1, Math.max(0, ((e.touches?.[0] || e).clientX - r.left) / r.width)); };
  prog.addEventListener('pointermove', e => {
    if (!dvr()) return;
    const x = ratioAt(e), [a, b] = range(), t = a + x * (b - a), back = liveEdge() - t;
    tip.textContent = back < 12 ? 'مباشر' : `−${fmt(back)}`;
    tip.style.left = `${x * 100}%`;
    $('.yt-hov').style.width = `${x * 100}%`;
    if (scrubbing) { v.currentTime = t; $('.yt-play').style.width = $('.yt-scrub').style.left = `${x * 100}%`; }
  });
  prog.addEventListener('pointerdown', e => {
    if (!dvr()) return;
    scrubbing = true; prog.setPointerCapture(e.pointerId); root.classList.add('scrub');
    const [a, b] = range(); v.currentTime = a + ratioAt(e) * (b - a);
  });
  const endScrub = () => { if (!scrubbing) return; scrubbing = false; root.classList.remove('scrub'); tick(); };
  prog.addEventListener('pointerup', endScrub);
  prog.addEventListener('pointercancel', endScrub);
  prog.addEventListener('pointerleave', () => { $('.yt-hov').style.width = '0'; });

  /* ───── قائمة الإعدادات ───── */
  function openMenu(view = 'main') {
    menu.hidden = false; root.classList.add('menu-open');
    const row = (k, icon, label, value) => `<button class="yt-mi" data-m="${k}">${pi(icon)}<span>${label}</span><em>${esc(value)}</em>${pi('chevL')}</button>`;
    const head = t => `<button class="yt-mh" data-m="main">${pi('chev')}<span>${t}</span></button>`;
    const opt = (k, val, label, on, extra = '') => `<button class="yt-mo ${on ? 'on' : ''}" data-m="${k}" data-v="${val}">${on ? pi('check') : '<i></i>'}<span>${label}</span>${extra}</button>`;
    let html = '';
    if (view === 'main') {
      const lv = hls?.levels || [], auto = !hls || hls.autoLevelEnabled;
      const curH = lv[hls?.currentLevel]?.height || lv[hls?.loadLevel]?.height || v.videoHeight;
      html = (lv.length > 1 ? row('quality', 'tune', 'الجودة', auto ? `تلقائي${curH ? ` (${curH}p)` : ''}` : `${curH}p`) : row('quality', 'tune', 'الجودة', v.videoHeight ? `${v.videoHeight}p` : 'تلقائي'))
        + (dvr() ? row('speed', 'speed', 'سرعة التشغيل', v.playbackRate === 1 ? 'عادي' : `${v.playbackRate}×`) : '')
        + ((hls?.audioTracks?.length || 0) > 1 ? row('audio', 'audio', 'المسار الصوتي', hls.audioTracks[hls.audioTrack]?.name || '—') : '')
        + (hls?.subtitleTracks?.length ? row('subs', 'cc', 'الترجمة', hls.subtitleDisplay && hls.subtitleTrack >= 0 ? hls.subtitleTracks[hls.subtitleTrack]?.name : 'إيقاف') : '')
        + (item.streams.length > 1 ? row('server', 'server', 'السيرفر', `${si + 1} / ${item.streams.length}`) : '')
        + `<button class="yt-mi" data-m="stats">${pi('stats')}<span>إحصاءات للمهتمين</span><em></em></button>`
        + `<button class="yt-mi" data-m="help">${pi('keyboard')}<span>اختصارات لوحة المفاتيح</span><em></em></button>`;
    } else if (view === 'quality') {
      const lv = hls ? hls.levels.map((l, i) => [i, l.height, l.bitrate]).filter(x => x[1]).sort((a, b) => b[1] - a[1]) : [];
      const autoH = hls?.levels[hls.loadLevel]?.height;
      html = head('الجودة') + lv.map(([i, h, br]) => opt('setq', i, `${h}p`, hls && !hls.autoLevelEnabled && hls.currentLevel === i,
        `${qLabel(h) ? `<sup>${qLabel(h)}</sup>` : ''}<small>${(br / 1e6).toFixed(1)} Mbps</small>`)).join('')
        + opt('setq', -1, `تلقائي${autoH ? ` <small>(${autoH}p)</small>` : ''}`, !hls || hls.autoLevelEnabled);
    } else if (view === 'speed') {
      html = head('سرعة التشغيل') + SPEEDS.map(s => opt('setspeed', s, s === 1 ? 'عادي' : `${s}×`, v.playbackRate === s)).join('');
    } else if (view === 'audio') {
      html = head('المسار الصوتي') + hls.audioTracks.map((t, i) => opt('setaudio', i, esc(t.name || t.lang || `مسار ${i + 1}`), hls.audioTrack === i)).join('');
    } else if (view === 'subs') {
      html = head('الترجمة') + opt('setsub', -1, 'إيقاف', !hls.subtitleDisplay || hls.subtitleTrack < 0)
        + hls.subtitleTracks.map((t, i) => opt('setsub', i, esc(t.name || t.lang || `ترجمة ${i + 1}`), hls.subtitleDisplay && hls.subtitleTrack === i)).join('');
    } else if (view === 'server') {
      html = head('السيرفر') + item.streams.map((s, i) => opt('setserver', i, `السيرفر ${i + 1}`, si === i,
        `<small>${esc(s.server || '')}${s.quality ? ` · ${esc(s.quality)}` : ''}${failed.has(i) && si !== i ? ' · لا يعمل' : ''}</small>`)).join('');
    }
    panel.innerHTML = html;
    panel.dataset.view = view;
  }
  const closeMenu = () => { menu.hidden = true; root.classList.remove('menu-open'); };

  panel.addEventListener('click', e => {
    e.stopPropagation(); // المحتوى يُستبدل أثناء التنقل بين القوائم، فلا نتركه يصل لمعالج الإغلاق
    const b = e.target.closest('[data-m]');
    if (!b) return;
    const m = b.dataset.m, val = +b.dataset.v;
    if (['main', 'quality', 'speed', 'audio', 'subs', 'server'].includes(m)) return openMenu(m);
    if (m === 'stats') { closeMenu(); return toggleStats(true); }
    if (m === 'help') { closeMenu(); return toggleHelp(true); }
    if (m === 'setq' && hls) {
      hls.currentLevel = val; // تبديل فوري للدقة من نفس البث
      prefs.quality = val < 0 ? 0 : hls.levels[val].height; savePrefs(prefs);
      osd(`<b>${val < 0 ? 'تلقائي' : `${hls.levels[val].height}p`}</b>`);
    }
    if (m === 'setspeed') { v.playbackRate = val; pill(val === 1 ? 'عادي' : `${val}×`); }
    if (m === 'setaudio') hls.audioTrack = val;
    if (m === 'setsub') { if (val < 0) hls.subtitleDisplay = false; else { hls.subtitleTrack = val; hls.subtitleDisplay = true; } }
    if (m === 'setserver') { failed.clear(); start(val); osd(`${pi('server')}<span>السيرفر ${val + 1}</span>`); }
    closeMenu(); syncUi();
  });

  /* ───── قائمة القنوات الجانبية ───── */
  const chl = $('.yt-chl'), chlList = $('.yt-chl-list'), chlQ = $('.yt-chl-q input');
  let chlMode = opts.channels?.modes?.[0]?.[0] || 'all', chlItems = [], chlSel = -1;
  const chlOpen = () => !chl.hidden;
  const chlMark = (i, scroll = true) => {
    chlSel = Math.max(0, Math.min(chlItems.length - 1, i));
    chlList.querySelectorAll('.sel').forEach(x => x.classList.remove('sel'));
    const el = chlList.children[chlSel];
    if (el) { el.classList.add('sel'); if (scroll) chlList.scrollTop = el.offsetTop - chlList.clientHeight / 2 + el.clientHeight / 2; }
  };
  function drawChl() {
    if (!opts.channels) return;
    const q = chlQ.value.trim().toLowerCase(), cur = opts.channels.current();
    chlItems = opts.channels.list(chlMode).filter(x => !q || String(x.number) === q || x.name.toLowerCase().includes(q) || (x.sub || '').toLowerCase().includes(q));
    $('.yt-chl-n').textContent = chlItems.length;
    $('.yt-chl-tabs').innerHTML = (opts.channels.modes || []).map(([k, label]) => `<button class="${k === chlMode ? 'on' : ''}" data-cm="${k}">${esc(label)}</button>`).join('');
    chlList.innerHTML = chlItems.map((x, i) => `<button class="yt-ch ${x.id === cur ? 'on' : ''}" data-ci="${i}"><span class="n">${x.number}</span>
      <span class="lg">${x.logo ? `<img src="${esc(x.logo)}" alt="" loading="lazy" referrerpolicy="no-referrer">` : esc([...x.name][0] || '•')}</span>
      <span class="t"><b>${esc(x.name)}</b><small>${esc(x.sub || '')}</small></span>${x.id === cur ? '<i class="eq"><b></b><b></b><b></b></i>' : ''}</button>`).join('')
      || '<p class="yt-chl-empty">لا توجد قنوات مطابقة.</p>';
    chlMark(Math.max(0, chlItems.findIndex(x => x.id === cur)));
  }
  function toggleChl(on = !chlOpen()) {
    if (!opts.channels) return;
    chl.hidden = !on; root.classList.toggle('chl-open', on);
    if (on) { closeMenu(); drawChl(); chlList.focus({ preventScroll: true }); } else root.focus({ preventScroll: true });
  }
  const chlPick = i => { const x = chlItems[i]; if (x) opts.channels.pick(x.id); };
  chl.addEventListener('click', e => {
    e.stopPropagation();
    const m = e.target.closest('[data-cm]')?.dataset.cm;
    if (m) { chlMode = m; chlQ.value = ''; drawChl(); return; }
    const i = e.target.closest('[data-ci]')?.dataset.ci;
    if (i != null) chlPick(+i);
    if (e.target.closest('[data-x=chl]')) toggleChl(false);
  });
  /** مفاتيح القائمة المفتوحة: ترجع true إذا عالجت المفتاح */
  const chlKey = e => {
    const k = e.key, inQ = e.target === chlQ;
    if (k === 'ArrowDown') chlMark(chlSel + 1);
    else if (k === 'ArrowUp') chlMark(chlSel - 1);
    else if (k === 'PageDown' && !inQ) chlMark(chlSel + 10);
    else if (k === 'PageUp' && !inQ) chlMark(chlSel - 10);
    else if (k === 'Enter') chlPick(chlSel);
    else if (k === 'Escape' || (!inQ && k.toLowerCase() === 'g')) toggleChl(false);
    else return false;
    e.preventDefault(); return true;
  };
  chlQ.addEventListener('input', drawChl);
  chlQ.addEventListener('keydown', e => { if (chlKey(e)) e.stopPropagation(); });

  /* ───── الإحصاءات والاختصارات وقائمة الزر الأيمن ───── */
  function toggleStats(on) {
    const box = $('.yt-stats');
    box.hidden = !on; clearInterval(statsT);
    if (!on) return;
    const draw = () => {
      const q = v.getVideoPlaybackQuality?.(), lv = hls?.levels?.[hls.currentLevel >= 0 ? hls.currentLevel : hls.loadLevel];
      let buf = 0; for (let i = 0; i < v.buffered.length; i++) if (v.buffered.start(i) <= v.currentTime && v.buffered.end(i) >= v.currentTime) buf = v.buffered.end(i) - v.currentTime;
      const s = item?.streams[si] || {};
      const rows = [
        ['القناة', item?.title], ['السيرفر', `${si + 1} / ${item?.streams.length || 0} · ${s.server || new URL(s.url || location.href).host}`],
        ['الدقة الحالية', `${v.videoWidth}×${v.videoHeight}${lv ? ` · المستوى ${(hls.levels.indexOf(lv) + 1)}/${hls.levels.length}` : ''}`],
        ['حجم العرض', `${root.clientWidth}×${root.clientHeight} · ${devicePixelRatio}x`],
        ['الإطارات المفقودة', q ? `${q.droppedVideoFrames} من ${q.totalVideoFrames}` : '—'],
        ['معدّل البت', lv?.bitrate ? `${(lv.bitrate / 1e6).toFixed(2)} Mbps` : '—'],
        ['سرعة الاتصال', hls?.bandwidthEstimate ? `${(hls.bandwidthEstimate / 1e6).toFixed(2)} Mbps` : '—'],
        ['صحة المخزن المؤقت', `${buf.toFixed(1)} ث`],
        ['التأخير عن البث', hls?.latency ? `${hls.latency.toFixed(1)} ث` : `${behind().toFixed(1)} ث`],
        ['الترميز', lv ? `${lv.videoCodec || '?'} / ${lv.audioCodec || '?'}` : '—'],
        ['المحرّك', hls ? `hls.js ${Hls.version}` : 'Native HLS'],
        ['الحجم', `${Math.round(v.volume * 100)}%${v.muted ? ' (مكتوم)' : ''}`]
      ];
      box.querySelector('table').innerHTML = rows.map(([k, val]) => `<tr><th>${k}</th><td>${esc(val)}</td></tr>`).join('');
    };
    draw(); statsT = setInterval(draw, 700);
  }
  const toggleHelp = on => { $('.yt-help').hidden = !on; };

  root.addEventListener('contextmenu', e => {
    e.preventDefault();
    const r = root.getBoundingClientRect();
    ctx.innerHTML = [
      ['copyurl', 'link', 'نسخ رابط الصفحة'], ['copystream', 'link', 'نسخ رابط البث'],
      ['stats', 'stats', 'إحصاءات للمهتمين'], ['help', 'keyboard', 'اختصارات لوحة المفاتيح'],
      ...(opts.onReport ? [['report', 'flag', 'الإبلاغ عن مشكلة']] : [])
    ].map(([k, i, t]) => `<button data-c="${k}">${pi(i)}<span>${t}</span></button>`).join('');
    ctx.hidden = false;
    ctx.style.left = `${Math.min(e.clientX - r.left, r.width - 240)}px`;
    ctx.style.top = `${Math.min(e.clientY - r.top, r.height - ctx.offsetHeight - 8)}px`;
  });
  ctx.addEventListener('click', e => {
    const k = e.target.closest('[data-c]')?.dataset.c;
    ctx.hidden = true;
    if (k === 'copyurl') navigator.clipboard?.writeText(location.href).then(() => osd('<span>تم نسخ رابط الصفحة</span>'));
    if (k === 'copystream') navigator.clipboard?.writeText(item?.streams[si]?.url || '').then(() => osd('<span>تم نسخ رابط البث</span>'));
    if (k === 'stats') toggleStats(true);
    if (k === 'help') toggleHelp(true);
    if (k === 'report') opts.onReport?.(item?.streams[si]);
  });

  /* ───── الأزرار والفأرة ───── */
  const actions = {
    play: toggle, mute: toggleMute, live: goLive, fs: toggleFs, pip: togglePip,
    prev: () => opts.onPrev?.(), next: () => opts.onNext?.(), theater: () => opts.onTheater?.(),
    settings: () => (menu.hidden ? openMenu() : closeMenu()),
    channels: () => toggleChl(),
    cc: () => { if (!hls?.subtitleTracks?.length) return; const on = !(hls.subtitleDisplay && hls.subtitleTrack >= 0); if (on && hls.subtitleTrack < 0) hls.subtitleTrack = 0; hls.subtitleDisplay = on; osd(`<span>الترجمة: ${on ? 'تشغيل' : 'إيقاف'}</span>`); syncUi(); }
  };
  root.addEventListener('click', e => {
    if (!e.target.closest('.yt-ctx')) ctx.hidden = true;
    const a = e.target.closest('[data-a]')?.dataset.a;
    if (a) { actions[a](); wake(); return; }
    const x = e.target.closest('[data-x]')?.dataset.x;
    if (x === 'stats') return toggleStats(false);
    if (x === 'help') return toggleHelp(false);
    const er = e.target.closest('[data-e]')?.dataset.e;
    if (er === 'retry') { failed.clear(); return start(si); }
    if (er === 'server') { failed.clear(); return start((si + 1) % item.streams.length); }
    if (er === 'next') return opts.onNext?.();
    if (er === 'report') return opts.onReport?.(item?.streams[si]);
    if (e.target.closest('.yt-unmute')) { toggleMute(); return; }
    if (e.target.closest('.yt-menu, .yt-bottom, .yt-stats, .yt-help, .yt-err, .yt-chl')) return;
    if (!menu.hidden) { closeMenu(); return; }
    if (e.pointerType === 'touch') return; // اللمس يُعالج في touchend
    clearTimeout(clickT);
    clickT = setTimeout(toggle, 220); // ننتظر لتمييز النقر المزدوج
  });
  root.addEventListener('dblclick', e => {
    if (e.target.closest('.yt-bottom, .yt-menu, .yt-err, .yt-stats, .yt-help, .yt-chl, .yt-side')) return;
    clearTimeout(clickT); toggleFs();
  });
  root.addEventListener('mousemove', wake);
  root.addEventListener('mouseleave', () => { if (!v.paused) root.classList.remove('show'); });
  volIn.addEventListener('input', () => { v.muted = false; mutedByAutoplay = false; $('.yt-unmute').hidden = true; setVolume(+volIn.value, false); });

  /* ───── اللمس: نقرة = إظهار التحكم، نقرتان على الجانب = تقديم/رجوع، سحب عمودي = تغيير القناة ───── */
  let t0 = null, lastTap = 0;
  root.addEventListener('touchstart', e => { if (e.touches.length === 1) t0 = { x: e.touches[0].clientX, y: e.touches[0].clientY, t: Date.now() }; }, { passive: true });
  root.addEventListener('touchend', e => {
    if (!t0 || e.target.closest('.yt-bottom, .yt-menu, .yt-err, .yt-stats, .yt-help, .yt-unmute, .yt-big, .yt-chl, .yt-side')) { t0 = null; return; }
    const p = e.changedTouches[0], dx = p.clientX - t0.x, dy = p.clientY - t0.y, dt = Date.now() - t0.t;
    const fromEdge = t0.x - root.getBoundingClientRect().left < 40;
    t0 = null;
    if (fsEl() && opts.channels && fromEdge && dx > 60 && Math.abs(dy) < dx) { toggleChl(true); return; }
    if (Math.abs(dy) > 70 && Math.abs(dy) > Math.abs(dx) * 1.5 && dt < 600) { (dy < 0 ? opts.onNext : opts.onPrev)?.(); return; }
    if (Math.abs(dx) > 12 || Math.abs(dy) > 12) return;
    const now = Date.now(), r = root.getBoundingClientRect(), side = (p.clientX - r.left) / r.width;
    if (now - lastTap < 300 && dvr() && (side < .35 || side > .65)) {
      const fwd = side > .65; seekBy(fwd ? 10 : -10);
      const rp = $(`.yt-ripple.${fwd ? 'r' : 'l'}`); rp.classList.remove('on'); void rp.offsetWidth; rp.classList.add('on');
      lastTap = 0; return;
    }
    lastTap = now;
    if (!menu.hidden) { closeMenu(); return; }
    root.classList.contains('show') && !v.paused ? root.classList.remove('show') : wake();
  });

  /* ───── لوحة المفاتيح ───── */
  const onKey = e => {
    if (destroyed || e.ctrlKey || e.metaKey || e.altKey) return;
    if (/INPUT|TEXTAREA|SELECT/.test(e.target.tagName) && e.target !== volIn) return;
    if (e.target.isContentEditable) return;
    const k = e.key, low = k.toLowerCase();
    const handled = () => { e.preventDefault(); wake(); };
    if (chlOpen() && chlKey(e)) return wake();
    if (low === 'g' && fsEl() && opts.channels && !e.shiftKey) { toggleChl(true); return handled(); }
    if (k === 'Escape') { if (!menu.hidden) { closeMenu(); return handled(); } if (!$('.yt-help').hidden) { toggleHelp(false); return handled(); } if (!ctx.hidden) { ctx.hidden = true; return handled(); } return; }
    if (e.shiftKey && low === 'n') { opts.onNext?.(); return handled(); }
    if (e.shiftKey && low === 'p') { opts.onPrev?.(); return handled(); }
    if (k === 'PageDown' || k === 'ChannelDown' || k === 'MediaTrackNext') { opts.onNext?.(); return handled(); }
    if (k === 'PageUp' || k === 'ChannelUp' || k === 'MediaTrackPrevious') { opts.onPrev?.(); return handled(); }
    if (/^[0-9]$/.test(k) && opts.onDigit) { opts.onDigit(+k); return handled(); }
    if (k === '?' || (e.shiftKey && k === '/')) { toggleHelp($('.yt-help').hidden); return handled(); }
    if (k === '<' || (e.shiftKey && k === ',')) { if (dvr()) { const i = Math.max(0, SPEEDS.indexOf(v.playbackRate) - 1); v.playbackRate = SPEEDS[i]; pill(`${SPEEDS[i]}×`); } return handled(); }
    if (k === '>' || (e.shiftKey && k === '.')) { if (dvr()) { const i = Math.min(SPEEDS.length - 1, SPEEDS.indexOf(v.playbackRate) + 1); v.playbackRate = SPEEDS[i]; pill(`${SPEEDS[i]}×`); } return handled(); }
    switch (low) {
      case ' ': if (e.target.tagName === 'BUTTON') return; // eslint-disable-line no-fallthrough
      case 'k': case 'mediaplaypause': toggle(); return handled();
      case 'm': toggleMute(); return handled();
      case 'f': toggleFs(); return handled();
      case 't': opts.onTheater?.(); return handled();
      case 'i': togglePip(); return handled();
      case 'c': actions.cc(); return handled();
      case 'arrowleft': seekBy(-5); return handled();
      case 'arrowright': seekBy(5); return handled();
      case 'j': seekBy(-10); return handled();
      case 'l': seekBy(10); return handled();
      case 'arrowup': v.muted = false; setVolume(v.volume + .05); return handled();
      case 'arrowdown': setVolume(v.volume - .05); return handled();
      case 'end': goLive(); pill('مباشر'); return handled();
      case 'home': if (dvr()) { v.currentTime = range()[0]; } return handled();
    }
    if (opts.onKey?.(e)) handled();
  };
  document.addEventListener('keydown', onKey);

  /* ───── أحداث الفيديو ───── */
  ['play', 'pause', 'volumechange', 'ratechange'].forEach(t => v.addEventListener(t, () => {
    syncUi(); wake();
    if (t === 'volumechange' && !mutedByAutoplay) { prefs.volume = v.volume; prefs.muted = v.muted; savePrefs(prefs); }
  }));
  ['waiting', 'stalled', 'seeking'].forEach(t => v.addEventListener(t, () => { if (!destroyed && !v.paused) spin.hidden = false; }));
  ['playing', 'canplay', 'seeked'].forEach(t => v.addEventListener(t, () => {
    if (destroyed) return;
    if (t !== 'seeked') { clearTimeout(watchdog); errBox.hidden = true; tries = 0; }
    spin.hidden = true; root.classList.add('started'); syncUi();
  }));
  v.addEventListener('timeupdate', tick);
  v.addEventListener('progress', tick);
  v.addEventListener('resize', syncUi);
  const onFs = () => { syncUi(); wake(); };
  document.addEventListener('fullscreenchange', onFs);
  document.addEventListener('webkitfullscreenchange', onFs);
  const outside = e => { if (!root.contains(e.target)) { closeMenu(); ctx.hidden = true; } };
  document.addEventListener('pointerdown', outside);

  v.volume = prefs.volume; v.muted = prefs.muted;
  syncUi();

  return {
    load(it) {
      item = { ...it, streams: (it.streams || []).filter(s => s?.url) };
      failed = new Set();
      root.classList.remove('started');
      $('.yt-tlogo').innerHTML = it.logo ? `<img src="${esc(it.logo)}" alt="" referrerpolicy="no-referrer">` : '';
      $('.yt-ttext b').textContent = `${it.number ? `${it.number} · ` : ''}${it.title || ''}`;
      $('.yt-ttext small').textContent = it.subtitle || '';
      if (chlOpen()) drawChl();
      if (!item.streams.length) return fail('لا توجد روابط', 'لا توجد روابط بث متاحة لهذه القناة حاليًا.');
      spin.hidden = false;
      const token = item;
      loadHls().then(() => { if (!destroyed && item === token) start(Math.min(it.startIndex || 0, item.streams.length - 1)); });
      wake();
    },
    setTheater(on) { setBtn('theater', on ? 'theaterOn' : 'theater', on ? 'العرض الافتراضي (t)' : 'وضع المسرح (t)'); },
    osd: (html, ms) => osd(html, ms),
    focus: () => root.focus({ preventScroll: true }),
    get current() { return item?.streams[si]; },
    destroy() {
      destroyed = true;
      [watchdog, hideT, osdT, pillT, bezelT, clickT].forEach(clearTimeout); clearInterval(statsT);
      document.removeEventListener('keydown', onKey);
      document.removeEventListener('fullscreenchange', onFs);
      document.removeEventListener('webkitfullscreenchange', onFs);
      document.removeEventListener('pointerdown', outside);
      try { hls?.destroy(); } catch { /* ignore */ }
      hls = null;
      v.removeAttribute('src'); v.load();
      host.innerHTML = '';
    }
  };
}
