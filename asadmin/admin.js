// ════════════════════════════════════════════════════════════════════════════
// MTC-iPTv — لوحة الإدارة: التحكم الكامل بالقنوات وروابط البث والمصادر والتقسيمات.
// تعتمد على الجداول والدوال المعرّفة في supabase/01_schema.sql.
// ════════════════════════════════════════════════════════════════════════════
import { login, logout, getSession, rest, restAll, configured } from '../src/supabase.js';
import { ic, logo, logoMark } from '../src/icons.js';
import { hash } from '../src/catalog.js';
import { createPlayer, loadHls } from '../src/player.js';
import { SOCIAL, socialIcon, socialLinks, cleanHandle } from '../src/social.js';
import { parseM3U } from './m3u.js';
import { VERSION } from '../src/version.js';

const app = document.getElementById('app');
const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const enc = encodeURIComponent;
const num = n => (n ?? 0).toLocaleString('en-US');
const date = d => d ? new Date(d).toLocaleString('ar', { dateStyle: 'medium', timeStyle: 'short' }) : '—';
const ago = d => { if (!d) return 'لم يُفحص'; const m = Math.round((Date.now() - new Date(d)) / 60000); return m < 60 ? `قبل ${m} د` : m < 1440 ? `قبل ${Math.round(m / 60)} س` : `قبل ${Math.round(m / 1440)} يوم`; };
const flag = url => url ? `<img class="flag" src="${esc(url)}" alt="">` : '';
const rpc = (fn, body = {}) => rest(`rpc/${fn}`, { method: 'POST', auth: true, body }).then(r => r.data);
const chunk = (a, n) => Array.from({ length: Math.ceil(a.length / n) }, (_, i) => a.slice(i * n, i * n + n));

const SUGGESTED = [
  { n: 'القنوات العربية', d: 'قنوات الدول العربية', u: 'https://iptv-org.github.io/iptv/regions/arab.m3u', i: 'globe', h: 150 },
  { n: 'قنوات الأخبار', d: 'أخبار عالمية وعربية', u: 'https://iptv-org.github.io/iptv/categories/news.m3u', i: 'live', h: 0 },
  { n: 'القنوات الرياضية', d: 'رياضة من حول العالم', u: 'https://iptv-org.github.io/iptv/categories/sports.m3u', i: 'ball', h: 140 },
  { n: 'قنوات الأطفال', d: 'كرتون وبرامج أطفال', u: 'https://iptv-org.github.io/iptv/categories/kids.m3u', i: 'star', h: 45 },
  { n: 'قنوات الأفلام', d: 'أفلام على مدار الساعة', u: 'https://iptv-org.github.io/iptv/categories/movies.m3u', i: 'film', h: 280 },
  { n: 'جميع القنوات', d: 'أكثر من 10,000 رابط (ضخم)', u: 'https://iptv-org.github.io/iptv/index.m3u', i: 'db', h: 220 }
];
const STATUS = { ready: ['ok', 'جاهز'], processing: ['warn', 'قيد المعالجة'], failed: ['bad', 'فشل'], pending: ['off', 'بانتظار الاستيراد'] };
const SSTATUS = { online: ['ok', 'يعمل'], offline: ['bad', 'معطّل'], unknown: ['off', 'لم يُفحص'] };
const REASONS = { not_working: 'لا تعمل', bad_quality: 'جودة سيئة', wrong_info: 'معلومات خاطئة', other: 'أخرى' };
const ICONS = ['tv', 'live', 'ball', 'film', 'star', 'play', 'heart', 'music', 'globe', 'zap', 'book', 'chart', 'sun', 'fork', 'car', 'bag', 'user', 'shield', 'grid', 'lang'];

const TABS = [
  { k: 'overview', i: 'chart', t: 'نظرة عامة', sec: 'الإدارة' },
  { k: 'review', i: 'shield', t: 'قيد المراجعة', badge: 'pending', warn: true },
  { k: 'channels', i: 'tv', t: 'القنوات', badge: 'channels' },
  { k: 'health', i: 'zap', t: 'فحص الروابط', badge: 'offline', warn: true },
  { k: 'duplicates', i: 'layers', t: 'القنوات المكررة', badge: 'duplicates', warn: true },
  { k: 'reports', i: 'flag', t: 'بلاغات المشاهدين', badge: 'reports', warn: true },
  { k: 'sources', i: 'link', t: 'مصادر البث', badge: 'sources', sec: 'المحتوى' },
  { k: 'sections', i: 'grid', t: 'التقسيمات' },
  { k: 'settings', i: 'edit', t: 'الإعدادات العامة', sec: 'النظام' },
  { k: 'maintenance', i: 'settings', t: 'النسخ الاحتياطي والصيانة' }
];

const S = {
  tab: location.hash.slice(1) || 'overview',
  stats: {}, sources: [], cats: [], countries: [], langs: [],
  filter: { q: '', status: '', category: '', country: '', language: '', source: '' },
  page: 0, size: 50, total: 0, rows: [], selected: new Set(),
  health: { running: false, stop: false }
};
const freshFilter = (k, v) => ({ q: '', status: '', category: '', country: '', language: '', source: '', ...(k ? { [k]: v } : {}) });

/* ═══════════════════ أدوات الواجهة ═══════════════════ */
function toast(msg, type = 'info') {
  const t = document.createElement('div');
  t.className = `toast ${type}`;
  t.innerHTML = `<span class="t-ic">${ic(type === 'error' ? 'alert' : type === 'success' ? 'check' : 'info')}</span><p>${esc(msg)}</p>`;
  document.getElementById('toasts').appendChild(t);
  setTimeout(() => { t.classList.add('out'); setTimeout(() => t.remove(), 300); }, 4200);
}

/** نافذة تأكيد/نموذج. ترجع FormData عند التأكيد أو null عند الإلغاء. */
function modal({ title, body = '', ok = 'تأكيد', danger = false, confirmWord = '', icon = danger ? 'trash' : 'info' }) {
  return new Promise(resolve => {
    const d = document.createElement('dialog');
    d.className = `modal ${danger ? 'is-danger' : ''}`;
    d.innerHTML = `<form method="dialog">
      <div class="m-ic">${ic(icon)}</div>
      <h3>${esc(title)}</h3><div class="m-body">${body}</div>
      ${confirmWord ? `<label class="fld"><span>للتأكيد اكتب <b>${esc(confirmWord)}</b></span><input name="__confirm" autocomplete="off" required></label>` : ''}
      <div class="m-act"><button type="button" class="btn2 ghost" value="cancel">إلغاء</button><button class="btn2 ${danger ? 'danger' : 'primary'}" value="ok">${esc(ok)}</button></div>
    </form>`;
    document.body.appendChild(d);
    const f = d.querySelector('form'), okBtn = d.querySelector('[value=ok]'), cw = d.querySelector('[name=__confirm]');
    if (cw) { okBtn.disabled = true; cw.oninput = () => { okBtn.disabled = cw.value.trim() !== confirmWord; }; }
    let result = null;
    d.querySelector('[value=cancel]').onclick = () => d.close();
    f.onsubmit = () => { result = new FormData(f); };
    d.onclose = () => { d.remove(); resolve(result); };
    d.showModal();
  });
}

async function busy(btn, fn) {
  const html = btn?.innerHTML;
  if (btn) { btn.disabled = true; btn.innerHTML = '<i class="spin"></i>'; }
  try { return (await fn()) ?? true; }
  catch (e) { toast(e.message || 'حدث خطأ غير متوقع', 'error'); return null; }
  finally { if (btn?.isConnected) { btn.disabled = false; btn.innerHTML = html; } }
}

const sw = (checked, attrs = '') => `<label class="sw"><input type="checkbox" ${checked ? 'checked' : ''} ${attrs}><i></i></label>`;
const chip = (tone, text) => `<span class="chip2 ${tone}"><i></i>${esc(text)}</span>`;
const empty = (icon, title, text, action = '') => `<div class="empty2"><div class="e-ic">${ic(icon)}</div><h3>${title}</h3><p>${text}</p>${action}</div>`;
const thumb = c => `<div class="thumb" style="--h:${hash(c.name || '?') % 360}">${/^https:/i.test(c.logo_url || '') ? `<img src="${esc(c.logo_url)}" alt="" referrerpolicy="no-referrer">` : ''}<span class="init">${esc([...(c.name || '؟')][0])}</span>${c.quality ? `<em class="badge-q">${esc(c.quality)}</em>` : ''}</div>`;
const pageHead = (title, sub, actions = '') => `<header class="p-head"><div><h2>${title}</h2><p>${sub}</p></div><div class="p-act">${actions}</div></header>`;
const opts = (list, val, key, label, all) => `${all ? `<option value="">${all}</option>` : ''}${list.map(x => `<option value="${esc(x[key])}" ${String(val) === String(x[key]) ? 'selected' : ''}>${esc(label(x))}</option>`).join('')}`;
document.addEventListener('error', e => { if (e.target.tagName === 'IMG') e.target.remove(); }, true);

/* ═══════════════════ الفحص من المتصفح ═══════════════════ */
/** يفحص رابط البث كما يراه المشاهد: يجب أن يرجع M3U8 صالحًا ويسمح بالوصول (CORS) */
async function probeStream(url) {
  const t0 = performance.now(), ctl = new AbortController(), to = setTimeout(() => ctl.abort(), 10000);
  try {
    if (location.protocol === 'https:' && url.startsWith('http:')) return { ok: false, status: 0, ms: 0, err: 'http غير آمن' };
    const r = await fetch(url, { signal: ctl.signal, cache: 'no-store' });
    const txt = (await r.text()).slice(0, 4096);
    const ok = r.ok && txt.trimStart().startsWith('#EXTM3U');
    return { ok, status: r.status, ms: Math.round(performance.now() - t0), err: ok ? '' : r.ok ? 'ليس M3U8' : `HTTP ${r.status}` };
  } catch (e) {
    return { ok: false, status: 0, ms: Math.round(performance.now() - t0), err: e.name === 'AbortError' ? 'انتهت المهلة' : 'CORS / شبكة' };
  } finally { clearTimeout(to); }
}
function probeLogo(url) {
  return new Promise(res => {
    if (!/^https:/i.test(url || '')) return res(false);
    const img = new Image(), to = setTimeout(() => { img.src = ''; res(false); }, 8000);
    img.referrerPolicy = 'no-referrer';
    img.onload = () => { clearTimeout(to); res(img.naturalWidth > 0); };
    img.onerror = () => { clearTimeout(to); res(false); };
    img.src = url;
  });
}
async function pool(items, n, fn, onEach) {
  let i = 0;
  await Promise.all(Array.from({ length: n }, async () => {
    while (i < items.length && !S.health.stop) { const k = i++; items[k].res = await fn(items[k]); onEach?.(items[k], k); }
  }));
}

/* ═══════════════════ البيانات المشتركة ═══════════════════ */
async function loadLookups(force = false) {
  if (S.cats.length && !force) return;
  const [cats, cos, langs] = await Promise.all([
    rest('categories?select=*&order=sort_order', { auth: true }).then(r => r.data || []),
    rest('countries?select=*&order=sort_order,name_ar', { auth: true }).then(r => r.data || []),
    rest('languages?select=*&order=sort_order,name_ar', { auth: true }).then(r => r.data || [])
  ]);
  S.cats = cats; S.countries = cos; S.langs = langs;
}
async function refreshStats() {
  S.stats = await rpc('admin_stats');
  app.querySelectorAll('[data-badge]').forEach(b => { const v = S.stats[b.dataset.badge] || 0; b.textContent = num(v); b.hidden = !v && b.dataset.warn === '1'; });
  return S.stats;
}
const loadSources = async () => { S.sources = (await rest('playlist_sources?select=*&order=created_at.desc', { auth: true })).data || []; return S.sources; };

/** حذف قنوات مطابقة لفلتر — دفعة واحدة، أو مجزّأً إذا تجاوز مهلة الخادم */
async function deleteChannels(filter) {
  try { await rest(`channels?${filter}`, { method: 'DELETE', auth: true }); return; } catch { /* نكمل مجزّأً */ }
  for (;;) {
    const { data } = await rest(`channels?select=id&${filter}&limit=200`, { auth: true });
    if (!data?.length) return;
    await rest(`channels?id=in.(${data.map(r => r.id).join(',')})`, { method: 'DELETE', auth: true });
  }
}

/** استيراد/تحديث مصدر M3U عبر دوال قاعدة البيانات */
async function importSource({ id, name, url, publish, skipHttp, skipGeo }, progress) {
  progress('تحميل ملف القائمة من الرابط', 5);
  let text;
  try {
    const r = await fetch(url, { cache: 'no-store' });
    if (!r.ok) throw new Error(`HTTP ${r.status}`);
    text = await r.text();
  } catch (e) { throw new Error(`تعذّر تحميل الرابط (${e.message}). تأكد أن الرابط صحيح ويسمح بالوصول من المتصفح.`); }
  if (!/#EXTM3U|#EXTINF/i.test(text.slice(0, 5000))) throw new Error('الرابط لا يحتوي على قائمة M3U صالحة.');
  progress('تحليل القنوات وتصنيفها', 10);
  const { items, skipped } = parseM3U(text, { skipHttp, skipGeo });
  if (!items.length) throw new Error('لم يتم العثور على روابط صالحة في هذه القائمة.');
  if (!id) id = (await rest('playlist_sources', { method: 'POST', auth: true, prefer: 'return=representation', body: { name, url, status: 'processing', auto_publish: publish } })).data[0].id;
  else await rest(`playlist_sources?id=eq.${enc(id)}`, { method: 'PATCH', auth: true, body: { status: 'processing', last_error: null } });
  try {
    let done = 0;
    for (const part of chunk(items, 400)) {
      await rpc('admin_import', { p_source: id, p_items: part, p_publish: publish });
      done += part.length;
      progress(`حفظ القنوات والروابط (${num(done)} / ${num(items.length)})`, 12 + 80 * done / items.length);
    }
    progress('حذف الروابط التي أُزيلت من المصدر', 94);
    const fin = await rpc('admin_finish_import', { p_source: id, p_urls: items.map(x => x.url) });
    progress('اكتمل الاستيراد', 100);
    return { total: items.length, skipped, ...fin };
  } catch (e) {
    await rest(`playlist_sources?id=eq.${enc(id)}`, { method: 'PATCH', auth: true, body: { status: 'failed', last_error: String(e.message).slice(0, 500) } }).catch(() => {});
    throw e;
  }
}

/* ═══════════════════ تسجيل الدخول ═══════════════════ */
async function isAdmin() {
  const uid = getSession()?.user?.id;
  if (!uid) return false;
  try { return ((await rest(`admin_users?select=user_id&user_id=eq.${uid}`, { auth: true })).data || []).length > 0; }
  catch { return false; }
}

function renderLogin() {
  app.className = '';
  app.innerHTML = `<div class="login">
    <div class="login-art"><div class="art-in">${logo()}
      <h2>لوحة تحكم<br><span>البث المباشر</span></h2>
      <ul><li>${ic('upload')} استيراد القنوات من روابط M3U</li><li>${ic('zap')} فحص الروابط المعطلة وحذفها</li><li>${ic('layers')} كشف القنوات المكررة ودمجها</li><li>${ic('grid')} إدارة الدول والفئات واللغات</li></ul>
    </div></div>
    <form class="login-card" id="lf">
      <div class="lc-mark">${logoMark(52)}</div>
      <h1>تسجيل الدخول</h1><p>خاص بمشرفي منصة MTC-iPTv</p>
      ${configured() ? '' : `<div class="alert2 bad">${ic('alert')}<div>لم يتم إعداد config.js بعد.</div></div>`}
      <label class="fld"><span>البريد الإلكتروني</span><div class="inp">${ic('user')}<input name="email" type="email" required autocomplete="username" dir="ltr"></div></label>
      <label class="fld"><span>كلمة المرور</span><div class="inp">${ic('shield')}<input name="password" type="password" required autocomplete="current-password" dir="ltr"></div></label>
      <button class="btn2 primary lg">دخول إلى اللوحة</button>
      <a class="back" href="../">${ic('back')} العودة إلى الموقع</a>
    </form></div>`;
  const f = document.getElementById('lf');
  f.onsubmit = e => {
    e.preventDefault();
    busy(f.querySelector('button'), async () => {
      await login(f.email.value.trim(), f.password.value);
      if (!await isAdmin()) { logout(); throw new Error('هذا الحساب لا يملك صلاحيات الإدارة.'); }
      renderShell();
    });
  };
}

/* ═══════════════════ الهيكل العام ═══════════════════ */
function renderShell() {
  const email = getSession()?.user?.email || '';
  app.className = 'shell';
  app.innerHTML = `<aside class="side" id="side">
    <a class="side-brand" href="../" target="_blank" title="فتح الموقع">${logo(`لوحة التحكم · v${VERSION}`)}</a>
    <nav class="side-nav">
      ${TABS.map(t => `${t.sec ? `<span class="side-sec">${t.sec}</span>` : ''}<button data-tab="${t.k}"><span class="n-ic">${ic(t.i)}</span><span class="n-t">${t.t}</span>${t.badge ? `<em data-badge="${t.badge}" data-warn="${t.warn ? 1 : 0}" class="${t.warn ? 'warn' : ''}" hidden></em>` : ''}</button>`).join('')}
      <span class="side-sec">روابط</span>
      <a href="../" target="_blank"><span class="n-ic">${ic('external')}</span><span class="n-t">فتح الموقع</span></a>
    </nav>
    <div class="side-user"><span class="avatar">${esc(email[0]?.toUpperCase() || 'A')}</span><div><b>مشرف</b><small dir="ltr">${esc(email)}</small></div>
      <button id="logout" class="icon2" title="تسجيل الخروج">${ic('logout')}</button></div>
  </aside>
  <div class="side-backdrop" id="backdrop"></div>
  <div class="main2">
    <header class="topbar">
      <button class="icon2 menu-btn" id="menu" aria-label="القائمة">${ic('menu')}</button>
      <div class="crumbs"><small>لوحة التحكم</small><h1 id="tb-title"></h1></div>
      <label class="tb-search">${ic('search')}<input id="tb-q" type="search" placeholder="ابحث عن قناة بالاسم أو الرقم… (Enter)"></label>
      <a class="btn2 ghost sm hide-sm" href="../" target="_blank">${ic('external')} الموقع</a>
    </header>
    <section class="content2" id="content"></section>
  </div>`;
  app.querySelectorAll('[data-tab]').forEach(b => b.onclick = () => go(b.dataset.tab));
  document.getElementById('logout').onclick = async () => { if (await modal({ title: 'تسجيل الخروج', body: '<p>هل تريد الخروج من لوحة التحكم؟</p>', ok: 'خروج', icon: 'logout' })) { logout(); renderLogin(); } };
  document.getElementById('menu').onclick = () => app.classList.add('menu-open');
  document.getElementById('backdrop').onclick = () => app.classList.remove('menu-open');
  document.getElementById('tb-q').onkeydown = e => { if (e.key === 'Enter') { S.filter = freshFilter('q', e.target.value); S.page = 0; e.target.value = ''; go('channels'); } };
  refreshStats().catch(() => {});
  go(S.tab);
}

function go(tab) {
  if (S.health.running && tab !== (S.health.tab || 'health')) S.health.stop = true; // مغادرة صفحة الفحص الجاري توقفه
  const t = TABS.find(x => x.k === tab) || TABS[0];
  S.tab = t.k;
  history.replaceState(null, '', '#' + t.k);
  app.classList.remove('menu-open');
  app.querySelectorAll('[data-tab]').forEach(b => b.classList.toggle('on', b.dataset.tab === t.k));
  document.getElementById('tb-title').textContent = t.t;
  document.title = `${t.t} — لوحة تحكم MTC-iPTv`;
  const c = document.getElementById('content');
  c.innerHTML = '<div class="loading2"><i class="spin"></i><span>جارٍ التحميل…</span></div>';
  ({ overview, review, channels, health, duplicates, reports, sources, sections, settings, maintenance })[t.k](c).catch(e => {
    const old = /admin_stats|does not exist|schema cache|function/i.test(e.message);
    c.innerHTML = `<div class="alert2 ${old ? 'warn' : 'bad'}">${ic('alert')}<div><b>${old ? 'قاعدة البيانات تحتاج تحديثًا' : 'تعذّر تحميل الصفحة'}</b><p>${old ? 'شغّل أحدث نسخة من supabase/01_schema.sql ثم supabase/02_data.sql في Supabase ← SQL Editor.' : ''} ${esc(e.message)}</p></div></div>`;
    if (/الجلسة/.test(e.message)) renderLogin();
  });
}

/* ═══════════════════ نظرة عامة ═══════════════════ */
async function overview(c) {
  const [st] = await Promise.all([refreshStats(), loadLookups(), loadSources()]);
  const catName = s => S.cats.find(x => x.slug === s)?.name_ar || s || 'بدون';
  const co = code => S.countries.find(x => x.code === code);
  const maxCat = Math.max(1, ...st.by_category.map(x => x.n));
  const pubPct = st.channels ? Math.round(st.published / st.channels * 100) : 0;
  const onPct = st.streams ? Math.round(st.online / st.streams * 100) : 0;
  const alerts = [
    st.pending && [`${num(st.pending)} قناة بانتظار المراجعة — لن تظهر للمشاهدين قبل موافقتك`, 'review', 'shield'],
    st.offline && [`${num(st.offline)} رابط معطّل`, 'health', 'zap'],
    st.unchecked && [`${num(st.unchecked)} رابط لم يُفحص بعد`, 'health', 'zap'],
    st.duplicates && [`${num(st.duplicates)} مجموعة قنوات مكررة`, 'duplicates', 'layers'],
    st.reports && [`${num(st.reports)} بلاغ مفتوح من المشاهدين`, 'reports', 'flag'],
    st.no_stream && [`${num(st.no_stream)} قناة بلا رابط شغّال`, 'health', 'alert'],
    st.broken_logos && [`${num(st.broken_logos)} شعار لا يعمل`, 'health', 'eyeoff']
  ].filter(Boolean);
  const hour = new Date().getHours();
  c.innerHTML = `<section class="welcome">
      <div><small>${hour < 12 ? 'صباح الخير' : 'مساء الخير'} 👋</small><h2>أهلًا بك في لوحة تحكم MTC-iPTv</h2><p>${st.channels ? `${num(st.published)} قناة منشورة من أصل ${num(st.channels)} · ${num(st.online)} رابط يعمل من أصل ${num(st.streams)}` : 'قاعدة البيانات فارغة — ابدأ بإضافة أول مصدر بث.'}</p></div>
      <div class="w-act"><button class="btn2 light" data-go="sources">${ic('plus')} مصدر بث</button><button class="btn2 glass" data-go="health">${ic('zap')} فحص الروابط</button></div>
    </section>
    ${alerts.length ? `<section class="alerts">${alerts.map(([t, g, i]) => `<button class="al" data-go="${g}">${ic(i)}<span>${t}</span>${ic('next')}</button>`).join('')}</section>` : ''}
    <section class="kpis">
      ${kpi('القنوات', st.channels, 'tv', 220, `<div class="meter"><i style="width:${pubPct}%"></i></div><small>${pubPct}% منشورة</small>`, 'channels')}
      ${kpi('روابط البث', st.streams, 'link', 145, `<div class="meter"><i style="width:${onPct}%"></i></div><small>${onPct}% تعمل</small>`, 'health')}
      ${kpi('مخفية', st.hidden, 'eyeoff', 35, '', 'channels:hid')}
      ${kpi('مميزة', st.featured, 'star', 45, '', 'channels:feat')}
      ${kpi('الدول', st.countries, 'globe', 190, '', 'sections')}
      ${kpi('المصادر', st.sources, 'db', 280, '', 'sources')}
    </section>
    ${st.channels ? `<section class="grid2">
      <div class="panel"><div class="panel-h"><h3>${ic('grid')} القنوات حسب الفئة</h3><small>اضغط لعرض القنوات</small></div>
        <div class="bars2">${st.by_category.map(x => { const cat = S.cats.find(k => k.slug === x.slug); return `<button class="bar2" data-f="category" data-v="${esc(x.slug || '')}" style="--h:${cat?.hue ?? 220}"><span>${cat ? ic(cat.icon) : ''}${esc(catName(x.slug))}</span><i><b style="width:${x.n / maxCat * 100}%"></b></i><em>${num(x.n)}</em></button>`; }).join('')}</div></div>
      <div class="panel"><div class="panel-h"><h3>${ic('globe')} أكثر الدول</h3><small>${num(st.countries)} دولة</small></div>
        <div class="toplist">${st.by_country.map((x, i) => { const k = co(x.code); return `<button class="tl-row" data-f="country" data-v="${esc(x.code || '')}"><span class="rank">${i + 1}</span>${flag(k?.flag_url)}<b>${esc(k?.name_ar || 'بدون دولة')}</b><em>${num(x.n)}</em></button>`; }).join('')}</div></div>
    </section>` : `<section class="panel steps"><div class="panel-h"><h3>${ic('zap')} ابدأ في 3 خطوات</h3></div>
      <ol><li><b>شغّل ملفات قاعدة البيانات</b><span>01_schema.sql ثم 02_data.sql في Supabase SQL Editor.</span></li><li><b>أو أضف مصدر بث</b><span>ألصق رابط M3U أو اختر من المصادر المقترحة.</span></li><li><b>افحص الروابط</b><span>احذف المعطّل وأخفِ المكرر لتبقى المكتبة نظيفة.</span></li></ol>
      <button class="btn2 primary" data-go="sources">${ic('plus')} إضافة أول مصدر</button></section>`}`;
  c.querySelectorAll('[data-go]').forEach(b => b.onclick = () => go(b.dataset.go));
  c.querySelectorAll('[data-kpi]').forEach(b => b.onclick = () => { const [tab, status = ''] = b.dataset.kpi.split(':'); if (tab === 'channels') { S.filter = freshFilter('status', status); S.page = 0; } go(tab); });
  c.querySelectorAll('[data-f]').forEach(b => b.onclick = () => { S.filter = freshFilter(b.dataset.f, b.dataset.v); S.page = 0; go('channels'); });
}
const kpi = (label, v, i, h, extra, target) => `<button class="kpi" style="--h:${h}" data-kpi="${target}"><span class="k-ic">${ic(i)}</span><small>${label}</small><b>${num(v)}</b>${extra}</button>`;

/* ═══════════════════ القنوات ═══════════════════ */
function channelQuery({ withStatus = true } = {}) {
  const f = S.filter, p = [];
  const q = f.q.trim();
  if (q) p.push(/^\d+$/.test(q) ? `number=eq.${q}` : `name=ilike.${enc(`*${q.replace(/[*,()]/g, ' ')}*`)}`);
  if (withStatus) {
    if (f.status === 'pub') p.push('is_published=eq.true');
    if (f.status === 'hid') p.push('is_published=eq.false');
    if (f.status === 'feat') p.push('is_featured=eq.true');
    if (f.status === 'manual') p.push('is_manual=eq.true');
    if (f.status === 'nologo') p.push('logo_url=is.null');
    if (f.status === 'duplicate') p.push('hidden_reason=eq.duplicate');
    if (f.status === 'pending') p.push('hidden_reason=eq.pending');
  }
  if (f.category) p.push(`category_slug=eq.${enc(f.category)}`);
  if (f.country) p.push(f.country === '-' ? 'country_code=is.null' : `country_code=eq.${enc(f.country)}`);
  if (f.language) p.push(`language_code=eq.${enc(f.language)}`);
  if (f.source) p.push(`src.source_id=eq.${enc(f.source)}`);
  return p;
}
const SEL = 'id,number,name,uid,logo_url,logo_status,quality,is_published,is_featured,is_manual,hidden_reason,category_slug,country_code,language_code';

async function channels(c) {
  await Promise.all([loadLookups(), S.sources.length ? 0 : loadSources()]);
  const base = channelQuery(), noStatus = channelQuery({ withStatus: false });
  const embed = S.filter.source ? ',src:streams!inner(source_id)' : '';
  const cnt = extra => rest(`channels?select=id${embed}&${[...noStatus, ...extra].join('&')}`, { auth: true, prefer: 'count=exact', range: '0-0' }).then(r => r.total ?? 0).catch(() => 0);
  const [res, cAll, cPub, cHid, cFeat] = await Promise.all([
    rest(`channels?select=${SEL},streams(id,status)${embed}&${base.join('&')}&order=number.asc.nullslast`, { auth: true, prefer: 'count=exact', range: `${S.page * S.size}-${S.page * S.size + S.size - 1}` }),
    cnt([]), cnt(['is_published=eq.true']), cnt(['is_published=eq.false']), cnt(['is_featured=eq.true'])
  ]);
  S.rows = res.data || []; S.total = res.total ?? S.rows.length; S.selected.clear();
  const pages = Math.max(1, Math.ceil(S.total / S.size)), f = S.filter;
  const cat = slug => S.cats.find(x => x.slug === slug), co = code => S.countries.find(x => x.code === code), lang = code => S.langs.find(x => x.code === code);
  const seg = (k, label, n) => `<button class="${f.status === k ? 'on' : ''}" data-status="${k}">${label}${n != null ? `<em>${num(n)}</em>` : ''}</button>`;

  c.innerHTML = pageHead('القنوات', 'كل قناة لها رقم ثابت وروابط بث (سيرفرات). المنشورة فقط تظهر للمشاهدين.',
    `<button class="btn2 ghost" id="renumber">${ic('sort')} إعادة الترقيم</button><button class="btn2 primary" id="add">${ic('plus')} إضافة قناة</button>`)
    + `<div class="seg">${seg('', 'الكل', cAll)}${seg('pub', 'منشورة', cPub)}${seg('hid', 'مخفية', cHid)}${seg('feat', 'مميزة', cFeat)}${seg('manual', 'يدوية')}${seg('nologo', 'بلا شعار')}${seg('duplicate', 'مكررة مخفية')}${seg('pending', 'بانتظار المراجعة')}</div>
    <div class="filters">
      <label class="search2">${ic('search')}<input id="fq" type="search" placeholder="ابحث بالاسم أو رقم القناة…" value="${esc(f.q)}"></label>
      <div class="sel2">${ic('grid')}<select data-f="category">${opts(S.cats, f.category, 'slug', x => x.name_ar, 'كل الفئات')}</select></div>
      <div class="sel2">${ic('globe')}<select data-f="country"><option value="">كل الدول</option><option value="-" ${f.country === '-' ? 'selected' : ''}>بدون دولة</option>${opts(S.countries, f.country, 'code', x => `${x.flag_emoji || ''} ${x.name_ar}`)}</select></div>
      <div class="sel2">${ic('lang')}<select data-f="language">${opts(S.langs, f.language, 'code', x => x.name_ar, 'كل اللغات')}</select></div>
      <div class="sel2">${ic('link')}<select data-f="source">${opts(S.sources, f.source, 'id', x => x.name, 'كل المصادر')}</select></div>
    </div>
    <div class="panel tbl-panel">
      <div class="tbl-top">
        <label class="chk2"><input type="checkbox" id="all"><i></i> تحديد الصفحة</label>
        <span class="muted">${num(S.total)} نتيجة</span><span class="sp"></span>
        <details class="menu2"><summary class="btn2 ghost sm">${ic('dots')} إجراءات على كل النتائج</summary>
          <div class="menu2-list">
            <button data-all="pub" ${S.total ? '' : 'disabled'}>${ic('eye')} نشر كل النتائج (${num(S.total)})</button>
            <button data-all="hide" ${S.total ? '' : 'disabled'}>${ic('eyeoff')} إخفاء كل النتائج</button>
            <button data-all="move" ${S.total ? '' : 'disabled'}>${ic('grid')} نقل كل النتائج إلى فئة/دولة</button>
            <button data-all="del" class="bad" ${S.total ? '' : 'disabled'}>${ic('trash')} حذف كل النتائج</button>
          </div></details>
      </div>
      ${S.rows.length ? `<div class="tbl-scroll"><table class="tbl2">
        <thead><tr><th></th><th>#</th><th>القناة</th><th>الفئة</th><th>الدولة / اللغة</th><th>الروابط</th><th>الظهور</th><th></th></tr></thead>
        <tbody>${S.rows.map(r => {
          const k = cat(r.category_slug), on = r.streams.filter(s => s.status === 'online').length, off = r.streams.filter(s => s.status === 'offline').length;
          return `<tr data-id="${r.id}">
          <td><label class="chk2"><input type="checkbox" class="sel" value="${r.id}"><i></i></label></td>
          <td class="num2">${r.number ?? '—'}</td>
          <td><div class="ch2">${thumb(r)}<div><b>${esc(r.name)}${r.is_manual ? ' <span class="tag-s">يدوية</span>' : ''}${r.hidden_reason ? ` <span class="tag-s warn">${{ duplicate: 'مكررة', offline: 'معطلة', manual: 'مخفية', reported: 'مُبلّغ عنها', pending: 'بانتظار المراجعة' }[r.hidden_reason]}</span>` : ''}</b><small class="muted" dir="ltr">${esc(r.uid)}</small></div></div></td>
          <td>${k ? `<span class="cat2" style="--h:${k.hue}">${ic(k.icon)}${esc(k.name_ar)}</span>` : '—'}</td>
          <td><div class="cl">${flag(co(r.country_code)?.flag_url)}<span>${esc(co(r.country_code)?.name_ar || '—')}</span></div><small class="muted">${esc(lang(r.language_code)?.name_ar || '')}</small></td>
          <td><button class="streams-b" data-act="edit" title="إدارة الروابط"><b class="ok">${on}</b>${off ? `<b class="bad">${off}</b>` : ''}<span>/ ${r.streams.length}</span></button></td>
          <td>${sw(r.is_published, 'data-act="toggle"')}</td>
          <td class="acts2">
            <button class="icon2 star ${r.is_featured ? 'on' : ''}" data-act="feat" title="مميزة في الرئيسية">${ic('star')}</button>
            <a class="icon2" href="../#/watch/${r.id}" target="_blank" title="مشاهدة">${ic('play')}</a>
            <button class="icon2" data-act="edit" title="تعديل">${ic('edit')}</button>
            <button class="icon2 bad" data-act="del" title="حذف">${ic('trash')}</button>
          </td></tr>`; }).join('')}</tbody></table></div>`
        : empty('tv', 'لا توجد قنوات', S.stats.channels ? 'لا توجد قنوات مطابقة للبحث أو الفلاتر الحالية.' : 'أضف مصدر بث أو شغّل ملف 02_data.sql.', `<button class="btn2 primary" data-go="sources">${ic('plus')} إضافة مصدر بث</button>`)}
      <div class="pager2"><div class="sel2 sm"><select id="psize">${[25, 50, 100, 200].map(n => `<option ${S.size === n ? 'selected' : ''}>${n}</option>`).join('')}</select></div><span class="sp"></span>${pager(S.page, pages)}</div>
    </div>
    <div class="bulkbar" id="bulkbar" hidden>
      <b id="selc"></b>
      <button data-bulk="pub">${ic('eye')} نشر</button><button data-bulk="hide">${ic('eyeoff')} إخفاء</button>
      <button data-bulk="feat">${ic('star')} تمييز</button><button data-bulk="unfeat">${ic('star')} إلغاء التمييز</button>
      <button data-bulk="move">${ic('grid')} نقل</button><button data-bulk="del" class="bad">${ic('trash')} حذف</button>
      <button data-bulk="clear" class="x" title="إلغاء التحديد">${ic('x')}</button>
    </div>`;

  const reload = () => go('channels');
  const setF = (k, v) => { S.filter[k] = v; S.page = 0; reload(); };
  let t; c.querySelector('#fq').oninput = e => { clearTimeout(t); t = setTimeout(() => setF('q', e.target.value), 450); };
  if (f.q) { const q = c.querySelector('#fq'); q.focus(); q.setSelectionRange(q.value.length, q.value.length); }
  c.querySelectorAll('select[data-f]').forEach(s => s.onchange = () => setF(s.dataset.f, s.value));
  c.querySelectorAll('[data-status]').forEach(b => b.onclick = () => setF('status', b.dataset.status));
  c.querySelector('#psize').onchange = e => { S.size = +e.target.value; S.page = 0; reload(); };
  c.querySelectorAll('[data-page]').forEach(b => b.onclick = () => { S.page = +b.dataset.page; reload(); });
  c.querySelector('#add').onclick = () => editChannel(null);
  c.querySelector('[data-go]')?.addEventListener('click', () => go('sources'));
  c.querySelector('#renumber').onclick = async e => {
    if (!await modal({ title: 'إعادة ترقيم القنوات', icon: 'sort', ok: 'إعادة الترقيم', body: '<p>سيُعاد ترقيم كل القنوات من 1: القنوات العربية أولًا ثم حسب الدولة والترتيب والاسم. أرقام القنوات الحالية ستتغيّر.</p>' })) return;
    busy(e.currentTarget, async () => { const n = await rpc('admin_renumber'); toast(`تم ترقيم ${num(n)} قناة`, 'success'); reload(); });
  };

  const bar = c.querySelector('#bulkbar');
  const updSel = () => { bar.hidden = !S.selected.size; c.querySelector('#selc').textContent = `${num(S.selected.size)} محددة`; };
  c.querySelector('#all').onchange = e => { c.querySelectorAll('.sel').forEach(x => { x.checked = e.target.checked; x.checked ? S.selected.add(x.value) : S.selected.delete(x.value); }); updSel(); };
  c.querySelectorAll('[data-bulk]').forEach(b => b.onclick = () => {
    if (b.dataset.bulk === 'clear') { S.selected.clear(); c.querySelectorAll('.sel, #all').forEach(x => { x.checked = false; }); updSel(); return; }
    bulk(b, b.dataset.bulk, `id=in.(${[...S.selected].join(',')})`, S.selected.size);
  });
  c.querySelectorAll('[data-all]').forEach(b => b.onclick = async () => {
    b.closest('details').open = false;
    let filter = base.join('&') || 'id=not.is.null';
    if (S.filter.source) { // التصفية حسب المصدر تحتاج معرفات القنوات
      const ids = (await restAll(`channels?select=id,src:streams!inner(source_id)&${base.join('&')}`, { auth: true })).map(r => r.id);
      filter = `id=in.(${ids.join(',')})`;
    }
    bulk(b, b.dataset.all, filter, S.total);
  });

  const tbody = c.querySelector('tbody');
  if (!tbody) return;
  tbody.addEventListener('change', async e => {
    const el = e.target, id = el.closest('tr').dataset.id, r = S.rows.find(x => x.id === id);
    if (el.classList.contains('sel')) { el.checked ? S.selected.add(id) : S.selected.delete(id); updSel(); return; }
    if (el.dataset.act === 'toggle') {
      el.disabled = true;
      const ok = await busy(null, () => rest(`channels?id=eq.${id}`, { method: 'PATCH', auth: true, body: { is_published: el.checked, hidden_reason: el.checked ? null : 'manual' } }));
      el.disabled = false;
      if (ok) { r.is_published = el.checked; toast(el.checked ? `«${r.name}» ظاهرة للمشاهدين` : `تم إخفاء «${r.name}»`, 'success'); refreshStats(); } else el.checked = !el.checked;
    }
  });
  tbody.addEventListener('click', async e => {
    const b = e.target.closest('[data-act]');
    if (!b || b.tagName === 'INPUT') return;
    const id = b.closest('tr').dataset.id, r = S.rows.find(x => x.id === id), a = b.dataset.act;
    if (a === 'feat' && await busy(b, () => rest(`channels?id=eq.${id}`, { method: 'PATCH', auth: true, body: { is_featured: !r.is_featured } }))) { r.is_featured = !r.is_featured; b.classList.toggle('on', r.is_featured); }
    if (a === 'edit') editChannel(r.id);
    if (a === 'del' && await modal({ title: 'حذف القناة', danger: true, ok: 'حذف نهائي', body: `<p>سيتم حذف «<b>${esc(r.name)}</b>» وجميع روابط بثها (${r.streams.length}) نهائيًا من قاعدة البيانات.</p>` })) {
      await busy(b, async () => { await rest(`channels?id=eq.${id}`, { method: 'DELETE', auth: true }); toast('تم حذف القناة', 'success'); refreshStats(); reload(); });
    }
  });
}

function pager(page, pages) {
  if (pages <= 1) return '';
  const list = [...new Set([0, pages - 1, page - 1, page, page + 1].filter(p => p >= 0 && p < pages))].sort((a, b) => a - b);
  let out = `<button class="pg" data-page="${page - 1}" ${page ? '' : 'disabled'}>${ic('back')}</button>`;
  list.forEach((p, i) => { if (i && p - list[i - 1] > 1) out += '<span class="pg-gap">…</span>'; out += `<button class="pg ${p === page ? 'on' : ''}" data-page="${p}">${p + 1}</button>`; });
  return out + `<button class="pg" data-page="${page + 1}" ${page + 1 < pages ? '' : 'disabled'}>${ic('next')}</button>`;
}

async function bulk(btn, action, filter, count) {
  if (!count) return;
  if (action === 'move') {
    const f = await modal({ title: `نقل ${num(count)} قناة`, icon: 'grid', ok: 'تطبيق', body: `<p>اختر ما تريد تغييره (اترك الحقل كما هو لعدم تغييره):</p>
      <label class="fld"><span>الفئة</span><select name="category_slug">${opts(S.cats, '', 'slug', x => x.name_ar, '— بدون تغيير —')}</select></label>
      <label class="fld"><span>الدولة</span><select name="country_code">${opts(S.countries, '', 'code', x => `${x.flag_emoji || ''} ${x.name_ar}`, '— بدون تغيير —')}</select></label>
      <label class="fld"><span>اللغة</span><select name="language_code">${opts(S.langs, '', 'code', x => x.name_ar, '— بدون تغيير —')}</select></label>` });
    if (!f) return;
    const body = Object.fromEntries([...f.entries()].filter(([k, v]) => v && k !== '__confirm'));
    if (!Object.keys(body).length) return;
    return busy(btn, async () => { await rest(`channels?${filter}`, { method: 'PATCH', auth: true, body }); toast(`تم تحديث ${num(count)} قناة`, 'success'); go('channels'); });
  }
  const label = { pub: 'نشر', hide: 'إخفاء', feat: 'تمييز', unfeat: 'إلغاء تمييز', del: 'حذف' }[action];
  const ok = await modal({
    title: `${label} ${num(count)} قناة`, icon: { pub: 'eye', hide: 'eyeoff', feat: 'star', unfeat: 'star', del: 'trash' }[action],
    body: action === 'del' ? `<p>سيتم حذف <b>${num(count)} قناة</b> وجميع روابط بثها نهائيًا من قاعدة البيانات. لا يمكن التراجع.</p>` : `<p>هل تريد ${label} <b>${num(count)} قناة</b>؟</p>`,
    ok: label, danger: action === 'del', confirmWord: action === 'del' && count > 50 ? 'حذف' : ''
  });
  if (!ok) return;
  await busy(btn, async () => {
    if (action === 'del') await deleteChannels(filter);
    else await rest(`channels?${filter}`, { method: 'PATCH', auth: true, body: { pub: { is_published: true, hidden_reason: null }, hide: { is_published: false, hidden_reason: 'manual' }, feat: { is_featured: true }, unfeat: { is_featured: false } }[action] });
    toast(`تم ${label} ${num(count)} قناة`, 'success');
    refreshStats(); go('channels');
  });
}

/* ═══════════════════ درج تعديل القناة + إدارة روابطها ═══════════════════ */
async function editChannel(id) {
  await Promise.all([loadLookups(), S.sources.length ? 0 : loadSources()]);
  const v = id ? (await rest(`channels?id=eq.${id}&select=*`, { auth: true })).data[0] : { is_published: true, category_slug: 'general', sort_order: 0, is_manual: true };
  let streams = id ? (await rest(`streams?channel_id=eq.${id}&select=*&order=priority.asc`, { auth: true })).data || [] : [];
  const d = document.createElement('dialog');
  d.className = 'drawer';
  d.innerHTML = `<form>
    <header class="dr-h"><div><small>${id ? `تعديل القناة ${v.number ? `#${v.number}` : ''}` : 'قناة جديدة'}</small><h3>${id ? esc(v.name) : 'إضافة قناة يدويًا'}</h3></div><button type="button" class="icon2" data-close>${ic('x')}</button></header>
    <div class="dr-tabs"><button type="button" data-dt="info" class="on">${ic('edit')} المعلومات</button><button type="button" data-dt="streams">${ic('server')} الروابط <em>${streams.length}</em></button></div>
    <div class="dr-body" data-dp="info">
      <div class="dr-preview"><div class="dr-stage"><div class="dr-card">${thumb(v)}</div><div class="dr-pl" hidden></div></div>
        <div class="dr-meta"><b id="pv-name">${esc(v.name || 'اسم القناة')}</b><small>${v.uid ? `<span dir="ltr">${esc(v.uid)}</span>` : 'معرّف تلقائي'}</small></div>
        <div class="dr-pa"><button type="button" class="btn2 ghost sm" id="test-logo">${ic('eye')} فحص الشعار</button>${streams.length ? `<button type="button" class="btn2 ghost sm" id="play-first">${ic('play')} تشغيل</button>` : ''}</div></div>
      <fieldset><legend>المعلومات الأساسية</legend>
        <div class="two"><label class="fld"><span>اسم القناة *</span><input name="name" required maxlength="250" value="${esc(v.name)}"></label>
        <label class="fld"><span>رقم القناة</span><input name="number" type="number" min="1" value="${v.number ?? ''}" placeholder="تلقائي"></label></div>
        <label class="fld"><span>رابط الشعار ${v.logo_status === 'broken' ? '<b class="badtxt">(لا يعمل)</b>' : v.logo_status === 'ok' ? '<b class="oktxt">(يعمل)</b>' : ''}</span><input name="logo_url" type="url" dir="ltr" value="${esc(v.logo_url)}" placeholder="https://…/logo.png"></label>
        <div class="two"><label class="fld"><span>الشبكة</span><input name="network" maxlength="100" value="${esc(v.network)}" placeholder="مثال: MBC"></label>
        <label class="fld"><span>الموقع الرسمي</span><input name="website" type="url" dir="ltr" value="${esc(v.website)}"></label></div>
        <label class="fld"><span>وصف مختصر</span><textarea name="description" rows="2" maxlength="1000">${esc(v.description)}</textarea></label>
      </fieldset>
      <fieldset><legend>التقسيمات</legend><div class="two">
        <label class="fld"><span>الفئة</span><select name="category_slug">${opts(S.cats, v.category_slug, 'slug', x => x.name_ar)}</select></label>
        <label class="fld"><span>الدولة</span><select name="country_code"><option value="">— بدون —</option>${opts(S.countries, v.country_code, 'code', x => `${x.flag_emoji || ''} ${x.name_ar}`)}</select></label>
        <label class="fld"><span>اللغة</span><select name="language_code"><option value="">— بدون —</option>${opts(S.langs, v.language_code, 'code', x => x.name_ar)}</select></label>
        <label class="fld"><span>الجودة</span><select name="quality">${['', 'SD', 'HD', 'FHD', '4K'].map(q => `<option value="${q}" ${(v.quality || '') === q ? 'selected' : ''}>${q || 'غير محددة'}</option>`).join('')}</select></label>
        <label class="fld"><span>ترتيب الظهور</span><input name="sort_order" type="number" value="${v.sort_order ?? 0}"></label>
      </div></fieldset>
      <fieldset><legend>الظهور</legend>
        <label class="row-sw"><div><b>منشورة</b><small>تظهر للمشاهدين في الموقع</small></div>${sw(v.is_published, 'name="is_published"')}</label>
        <label class="row-sw"><div><b>مميزة</b><small>تظهر في أعلى الصفحة الرئيسية</small></div>${sw(v.is_featured, 'name="is_featured"')}</label>
      </fieldset>
      ${id ? '' : `<fieldset><legend>رابط البث الأول</legend><label class="fld"><span>رابط m3u8 *</span><input name="first_url" type="url" required dir="ltr" placeholder="https://…/index.m3u8"></label></fieldset>`}
    </div>
    <div class="dr-body" data-dp="streams" hidden>
      <p class="muted sm">السيرفرات تُجرَّب بالترتيب: إذا تعطّل الأول ينتقل المشغّل تلقائيًا للتالي. الروابط المعطّلة لا تظهر للمشاهدين.</p>
      <div class="st-list" id="st-list"></div>
      <div class="st-add"><input id="st-new" type="url" dir="ltr" placeholder="أضف رابط بث جديد https://…m3u8"><button type="button" class="btn2 primary sm" id="st-add">${ic('plus')} إضافة</button></div>
      <button type="button" class="btn2 ghost sm" id="st-check-all">${ic('zap')} فحص كل الروابط</button>
    </div>
    <footer class="dr-f">${id ? `<button type="button" class="btn2 danger-ghost" data-del>${ic('trash')} حذف القناة</button>` : ''}<span class="sp"></span>
      <button type="button" class="btn2 ghost" data-close>إلغاء</button><button class="btn2 primary">${ic('check')} حفظ</button></footer>
  </form>`;
  document.body.appendChild(d);
  const f = d.querySelector('form'), E = f.elements;
  let player = null;
  const close = () => { player?.destroy(); d.close(); };
  d.onclose = () => { player?.destroy(); d.remove(); };
  d.querySelectorAll('[data-close]').forEach(b => b.onclick = close);
  d.addEventListener('click', e => { if (e.target === d) close(); });
  d.querySelectorAll('[data-dt]').forEach(b => b.onclick = () => { d.querySelectorAll('[data-dt]').forEach(x => x.classList.toggle('on', x === b)); d.querySelectorAll('[data-dp]').forEach(p => { p.hidden = p.dataset.dp !== b.dataset.dt; }); });
  ['name', 'logo_url', 'quality'].forEach(n => E[n].addEventListener('input', () => {
    d.querySelector('.dr-card').innerHTML = thumb({ name: E.name.value, logo_url: E.logo_url.value, quality: E.quality.value });
    d.querySelector('#pv-name').textContent = E.name.value || 'اسم القناة';
  }));
  d.querySelector('#test-logo').onclick = async e => {
    const ok = await busy(e.currentTarget, () => probeLogo(E.logo_url.value.trim()));
    toast(ok ? 'الشعار يعمل' : 'الشعار لا يعمل أو الرابط غير صالح', ok ? 'success' : 'error');
    if (id) rpc('admin_record_logos', { p_results: [{ id, ok: !!ok }] }).catch(() => {});
  };
  const playStreams = (list, i = 0) => {
    const host = d.querySelector('.dr-pl');
    player?.destroy(); host.hidden = false; d.querySelector('.dr-card').hidden = true;
    player = createPlayer(host);
    player.load({ streams: list.map(s => ({ url: s.url, server: s.host || '', id: s.id })), title: E.name.value, startIndex: i });
    d.querySelector('[data-dt=info]').click();
  };
  d.querySelector('#play-first')?.addEventListener('click', () => playStreams(streams));

  /* ── إدارة الروابط ── */
  const drawStreams = () => {
    d.querySelector('[data-dt=streams] em').textContent = streams.length;
    d.querySelector('#st-list').innerHTML = streams.length ? streams.map((s, i) => {
      const [tone, label] = SSTATUS[s.status] || SSTATUS.unknown;
      const src = S.sources.find(x => x.id === s.source_id);
      return `<div class="st-row ${s.is_active ? '' : 'off'}" data-sid="${s.id}">
        <div class="st-ord"><button type="button" class="icon2 xs" data-s="up" ${i ? '' : 'disabled'} title="أعلى">${ic('back')}</button><b>${i + 1}</b><button type="button" class="icon2 xs" data-s="down" ${i < streams.length - 1 ? '' : 'disabled'} title="أسفل">${ic('next')}</button></div>
        <div class="st-main"><div class="st-top">${chip(tone, label)}<b>${esc(s.label || s.host)}</b>${s.quality ? `<span class="tag-s">${esc(s.quality)}</span>` : ''}${s.response_ms ? `<small>${s.response_ms} ms</small>` : ''}</div>
          <button type="button" class="url2" data-s="copy" dir="ltr">${ic('copy')}<span>${esc(s.url)}</span></button>
          <small class="muted">${src ? `المصدر: ${esc(src.name)}` : 'رابط يدوي'} · ${ago(s.last_checked_at)}${s.last_error ? ` · <span class="badtxt">${esc(s.last_error)}</span>` : ''}</small></div>
        <div class="st-act">${sw(s.is_active, 'data-s="active" title="مفعّل"')}<button type="button" class="icon2" data-s="check" title="فحص">${ic('zap')}</button><button type="button" class="icon2" data-s="play" title="تشغيل">${ic('play')}</button><button type="button" class="icon2 bad" data-s="del" title="حذف">${ic('trash')}</button></div>
      </div>`;
    }).join('') : `<p class="muted">لا توجد روابط لهذه القناة.</p>`;
  };
  const checkStream = async s => {
    const r = await probeStream(s.url);
    await rpc('admin_record_checks', { p_results: [{ id: s.id, ...r }] });
    Object.assign(s, { status: r.ok ? 'online' : 'offline', response_ms: r.ms, last_error: r.err || null, last_checked_at: new Date().toISOString() });
    return r;
  };
  drawStreams();
  const list = d.querySelector('#st-list');
  list.addEventListener('change', async e => {
    const row = e.target.closest('[data-sid]'), s = streams.find(x => x.id === row.dataset.sid);
    if (e.target.dataset.s === 'active' && await busy(null, () => rest(`streams?id=eq.${s.id}`, { method: 'PATCH', auth: true, body: { is_active: e.target.checked } }))) { s.is_active = e.target.checked; drawStreams(); }
  });
  list.addEventListener('click', async e => {
    const b = e.target.closest('[data-s]'); if (!b || b.tagName === 'INPUT') return;
    const row = b.closest('[data-sid]'), i = streams.findIndex(x => x.id === row.dataset.sid), s = streams[i], a = b.dataset.s;
    if (a === 'copy') navigator.clipboard?.writeText(s.url).then(() => toast('تم نسخ الرابط', 'success'));
    if (a === 'play') playStreams(streams, i);
    if (a === 'check') { const r = await busy(b, () => checkStream(s)); if (r) { toast(r.ok ? `الرابط يعمل (${r.ms} ms)` : `الرابط معطّل: ${r.err}`, r.ok ? 'success' : 'error'); drawStreams(); } }
    if (a === 'up' || a === 'down') {
      const j = a === 'up' ? i - 1 : i + 1;
      [streams[i], streams[j]] = [streams[j], streams[i]];
      await busy(null, () => Promise.all(streams.map((x, k) => x.priority === k ? 0 : rest(`streams?id=eq.${x.id}`, { method: 'PATCH', auth: true, body: { priority: k } }).then(() => { x.priority = k; }))));
      drawStreams();
    }
    if (a === 'del' && await modal({ title: 'حذف الرابط', danger: true, ok: 'حذف', body: `<p dir="ltr" class="mono">${esc(s.url)}</p>${streams.length === 1 ? '<p class="warn-t">هذا آخر رابط للقناة — لن تظهر للمشاهدين بدون روابط.</p>' : ''}` })) {
      if (await busy(b, () => rest(`streams?id=eq.${s.id}`, { method: 'DELETE', auth: true }))) { streams.splice(i, 1); drawStreams(); toast('تم حذف الرابط', 'success'); }
    }
  });
  d.querySelector('#st-add').onclick = async e => {
    const url = d.querySelector('#st-new').value.trim();
    if (!/^https?:\/\/.+/i.test(url)) return toast('أدخل رابطًا صالحًا يبدأ بـ https://', 'error');
    if (!id) return toast('احفظ القناة أولًا ثم أضف روابط إضافية', 'error');
    const r = await busy(e.currentTarget, () => rest('streams', { method: 'POST', auth: true, prefer: 'return=representation', body: { channel_id: id, url, priority: streams.length } }));
    if (r?.data?.[0]) { streams.push(r.data[0]); d.querySelector('#st-new').value = ''; drawStreams(); checkStream(r.data[0]).then(drawStreams).catch(() => {}); toast('تمت إضافة الرابط', 'success'); }
  };
  d.querySelector('#st-check-all').onclick = e => busy(e.currentTarget, async () => { await Promise.all(streams.map(checkStream)); drawStreams(); toast('اكتمل الفحص', 'success'); });

  d.querySelector('[data-del]')?.addEventListener('click', async e => {
    if (!await modal({ title: 'حذف القناة', danger: true, ok: 'حذف نهائي', body: `<p>سيتم حذف «<b>${esc(v.name)}</b>» وروابطها (${streams.length}) نهائيًا.</p>` })) return;
    await busy(e.currentTarget, async () => { await rest(`channels?id=eq.${id}`, { method: 'DELETE', auth: true }); toast('تم حذف القناة', 'success'); close(); refreshStats(); if (S.tab === 'channels') go('channels'); });
  });

  f.onsubmit = e => {
    e.preventDefault();
    const g = n => (E[n]?.value ?? '').trim();
    const body = {
      name: g('name'), logo_url: g('logo_url') || null, network: g('network') || null, website: g('website') || null, description: g('description') || null,
      category_slug: g('category_slug') || null, country_code: g('country_code') || null, language_code: g('language_code') || null,
      quality: g('quality') || null, sort_order: +g('sort_order') || 0, number: g('number') ? +g('number') : null,
      is_published: E.is_published.checked, is_featured: E.is_featured.checked
    };
    if (body.logo_url !== (v.logo_url || null)) body.logo_status = 'unknown';
    if (body.is_published) body.hidden_reason = null;
    busy(f.querySelector('.dr-f .btn2.primary'), async () => {
      if (id) await rest(`channels?id=eq.${id}`, { method: 'PATCH', auth: true, body });
      else {
        // القناة اليدوية يدخلها المدير بنفسه، فتُنشر مباشرة (admin_create_channel يتجاوز بوابة المراجعة)
        await rpc('admin_create_channel', { p_channel: body, p_url: g('first_url') });
      }
      toast(id ? 'تم حفظ التعديلات' : 'تمت إضافة القناة', 'success');
      close(); refreshStats();
      if (!id) S.filter = freshFilter('status', 'manual');
      go('channels');
    });
  };
  d.showModal();
}

/* ═══════════════════ فحص الروابط ═══════════════════ */
async function health(c) {
  const st = await refreshStats();
  const H = S.health;
  c.innerHTML = pageHead('فحص الروابط', 'يفحص روابط البث من متصفحك تمامًا كما يراها المشاهد (ملف M3U8 صالح + السماح بالتشغيل من الموقع). الرابط الذي يفشل هنا لن يعمل على الموقع.')
    + `<section class="kpis k4">
      ${kpi('كل الروابط', st.streams, 'link', 220, '', 'health')}
      ${kpi('تعمل', st.online, 'check', 145, `<div class="meter"><i style="width:${st.streams ? st.online / st.streams * 100 : 0}%"></i></div>`, 'health')}
      ${kpi('معطّلة', st.offline, 'alert', 0, '', 'health')}
      ${kpi('لم تُفحص', st.unchecked, 'info', 45, '', 'health')}
    </section>
    <section class="panel hc">
      <div class="panel-h"><h3>${ic('zap')} تشغيل الفحص</h3><small>يمكنك الاستمرار في استخدام اللوحة أثناء الفحص في هذه الصفحة</small></div>
      <div class="hc-opts">
        <label class="fld"><span>ماذا نفحص؟</span><select id="h-scope"><option value="unknown">الروابط التي لم تُفحص (${num(st.unchecked)})</option><option value="offline">الروابط المعطّلة — إعادة فحص (${num(st.offline)})</option><option value="online">الروابط التي تعمل — تأكيد (${num(st.online)})</option><option value="all">كل الروابط (${num(st.streams)})</option></select></label>
        <label class="fld"><span>الحد الأقصى</span><select id="h-limit">${[100, 500, 1000, 2500, 5000, 20000].map(n => `<option value="${n}" ${n === 500 ? 'selected' : ''}>${num(n)} رابط</option>`).join('')}</select></label>
        <label class="fld"><span>فحوصات متزامنة</span><select id="h-par">${[4, 8, 16, 24].map(n => `<option ${n === 8 ? 'selected' : ''}>${n}</option>`).join('')}</select></label>
        <label class="row-sw"><div><b>فحص الشعارات أيضًا</b><small>للقنوات المرتبطة بالروابط المفحوصة</small></div>${sw(true, 'id="h-logos"')}</label>
      </div>
      <div class="hc-run"><button class="btn2 primary" id="h-start">${ic('play')} بدء الفحص</button><button class="btn2 danger-ghost" id="h-stop" hidden>${ic('x')} إيقاف</button></div>
      <div class="prog2" id="h-prog" hidden><div class="prog2-t"><span></span><b></b></div><div class="prog2-b"><i></i></div>
        <div class="hc-live"><span class="ok">${ic('check')} <b id="h-ok">0</b> تعمل</span><span class="bad">${ic('alert')} <b id="h-bad">0</b> معطّلة</span><span>${ic('eye')} <b id="h-logo">0</b> شعار معطّل</span></div></div>
    </section>
    <section class="panel">
      <div class="panel-h"><h3>${ic('trash')} تنظيف بعد الفحص</h3></div>
      <div class="clean-grid">
        ${cleanBtn('delete_offline_streams', 'trash', 'حذف الروابط المعطّلة', `${num(st.offline)} رابط من قاعدة البيانات`, st.offline)}
        ${cleanBtn('hide_dead_channels', 'eyeoff', 'إخفاء القنوات بلا روابط تعمل', `${num(st.no_stream)} قناة (تبقى في القاعدة)`, st.no_stream)}
        ${cleanBtn('delete_dead_channels', 'trash', 'حذف القنوات بلا روابط تعمل', `${num(st.no_stream)} قناة نهائيًا`, st.no_stream, true)}
        ${cleanBtn('clear_broken_logos', 'eyeoff', 'إزالة الشعارات المعطّلة', `${num(st.broken_logos)} شعار`, st.broken_logos)}
        ${cleanBtn('reset_checks', 'refresh', 'إعادة ضبط نتائج الفحص', 'كل الروابط تصبح «لم تُفحص»', st.streams)}
      </div>
    </section>
    <section class="panel tbl-panel"><div class="tbl-top"><h3>${ic('alert')} آخر الروابط المعطّلة</h3><span class="sp"></span><button class="btn2 ghost sm" id="h-reload">${ic('refresh')} تحديث</button></div><div id="h-dead"></div></section>`;

  const drawDead = async () => {
    const rows = (await rest('streams?select=id,url,host,last_error,http_status,last_checked_at,fail_count,channels(id,name,number)&status=eq.offline&order=last_checked_at.desc.nullslast&limit=100', { auth: true })).data || [];
    c.querySelector('#h-dead').innerHTML = rows.length ? `<div class="tbl-scroll"><table class="tbl2"><thead><tr><th>القناة</th><th>الرابط</th><th>الخطأ</th><th>آخر فحص</th><th></th></tr></thead><tbody>${rows.map(r => `<tr data-sid="${r.id}">
      <td><b>${r.channels?.number ? `${r.channels.number}. ` : ''}${esc(r.channels?.name || '—')}</b></td>
      <td><button class="url2" data-h="copy" dir="ltr" data-u="${esc(r.url)}">${ic('copy')}<span>${esc(r.url)}</span></button></td>
      <td><span class="chip2 bad"><i></i>${esc(r.last_error || 'معطّل')}</span>${r.fail_count > 1 ? `<small class="muted"> ×${r.fail_count}</small>` : ''}</td>
      <td><small class="muted">${ago(r.last_checked_at)}</small></td>
      <td class="acts2"><button class="icon2" data-h="edit" data-cid="${r.channels?.id}" title="فتح القناة">${ic('edit')}</button><button class="icon2 bad" data-h="del" title="حذف الرابط">${ic('trash')}</button></td></tr>`).join('')}</tbody></table></div>`
      : empty('check', 'لا توجد روابط معطّلة', 'كل الروابط المفحوصة تعمل. شغّل فحصًا جديدًا للتأكد.');
  };
  drawDead();
  c.querySelector('#h-reload').onclick = drawDead;
  c.querySelector('#h-dead').addEventListener('click', async e => {
    const b = e.target.closest('[data-h]'); if (!b) return;
    if (b.dataset.h === 'copy') navigator.clipboard?.writeText(b.dataset.u).then(() => toast('تم نسخ الرابط', 'success'));
    if (b.dataset.h === 'edit') editChannel(b.dataset.cid);
    if (b.dataset.h === 'del' && await busy(b, () => rest(`streams?id=eq.${b.closest('tr').dataset.sid}`, { method: 'DELETE', auth: true }))) { b.closest('tr').remove(); refreshStats(); }
  });
  c.querySelectorAll('[data-clean]').forEach(b => b.onclick = async () => {
    const card = b.closest('.clean');
    const danger = b.dataset.danger === '1';
    if (!await modal({ title: card.querySelector('b').textContent, danger, icon: b.dataset.icon, ok: 'تنفيذ', confirmWord: danger ? 'حذف' : '', body: `<p>${card.querySelector('small').textContent}</p>` })) return;
    busy(b, async () => { const n = await rpc('admin_cleanup', { p_action: b.dataset.clean }); toast(`تم التنفيذ (${num(n)})`, 'success'); go('health'); });
  });

  const start = c.querySelector('#h-start'), stop = c.querySelector('#h-stop'), prog = c.querySelector('#h-prog');
  stop.onclick = () => { H.stop = true; stop.disabled = true; };
  start.onclick = async () => {
    const scope = c.querySelector('#h-scope').value, limit = +c.querySelector('#h-limit').value, par = +c.querySelector('#h-par').value, logos = c.querySelector('#h-logos').checked;
    H.running = true; H.stop = false; H.tab = 'health'; start.hidden = true; stop.hidden = false; stop.disabled = false; prog.hidden = false;
    const setP = (t, p) => { prog.querySelector('span').textContent = t; prog.querySelector('b').textContent = `${Math.round(p)}%`; prog.querySelector('i').style.width = `${p}%`; };
    let okN = 0, badN = 0, logoBad = 0;
    try {
      setP('جلب قائمة الروابط…', 1);
      const filter = scope === 'all' ? '' : `&status=eq.${scope}`;
      const items = [];
      for (let from = 0; items.length < limit; from += 1000) {
        const { data } = await rest(`streams?select=id,url,channel_id${filter}&order=last_checked_at.asc.nullsfirst`, { auth: true, range: `${from}-${from + Math.min(999, limit - items.length - 1)}` });
        items.push(...(data || [])); if (!data || data.length < 1000) break;
      }
      if (!items.length) { toast('لا توجد روابط في هذا النطاق', 'info'); return; }
      let pending = [], done = 0;
      const flush = async () => { if (!pending.length) return; const part = pending; pending = []; await rpc('admin_record_checks', { p_results: part }); };
      await pool(items, par, s => probeStream(s.url), async s => {
        done++; s.res.ok ? okN++ : badN++;
        pending.push({ id: s.id, ...s.res });
        if (pending.length >= 50) flush().catch(() => {});
        c.querySelector('#h-ok').textContent = num(okN); c.querySelector('#h-bad').textContent = num(badN);
        setP(`فحص الروابط ${num(done)} / ${num(items.length)}`, done / items.length * (logos ? 80 : 100));
      });
      await flush();
      if (logos && !H.stop) {
        const ids = [...new Set(items.map(s => s.channel_id))];
        const chans = [];
        for (const part of chunk(ids, 150)) chans.push(...((await rest(`channels?select=id,logo_url&id=in.(${part.join(',')})&logo_url=not.is.null`, { auth: true })).data || []));
        let ld = 0; const results = [];
        await pool(chans, 12, ch => probeLogo(ch.logo_url), ch => { ld++; results.push({ id: ch.id, ok: ch.res }); if (!ch.res) logoBad++; c.querySelector('#h-logo').textContent = num(logoBad); setP(`فحص الشعارات ${num(ld)} / ${num(chans.length)}`, 80 + ld / chans.length * 20); });
        for (const part of chunk(results, 200)) await rpc('admin_record_logos', { p_results: part });
      }
      setP(H.stop ? 'تم إيقاف الفحص' : 'اكتمل الفحص', 100);
      toast(`اكتمل الفحص: ${num(okN)} تعمل، ${num(badN)} معطّلة`, badN ? 'info' : 'success');
    } catch (e) { toast(e.message, 'error'); }
    finally {
      H.running = false;
      if (start.isConnected) { start.hidden = false; stop.hidden = true; await refreshStats(); drawDead(); }
    }
  };
}
const cleanBtn = (k, i, t, s, n, danger) => `<div class="clean ${danger ? 'danger' : ''}"><span class="cl-ic">${ic(i)}</span><div><b>${t}</b><small>${s}</small></div><button class="btn2 ${danger ? 'danger' : 'ghost'} sm" data-clean="${k}" data-icon="${i}" data-danger="${danger ? 1 : 0}" ${n ? '' : 'disabled'}>تنفيذ</button></div>`;

/* ═══════════════════ القنوات المكررة ═══════════════════ */
async function duplicates(c) {
  const [groups] = await Promise.all([rpc('admin_duplicates'), loadLookups()]);
  const co = code => S.countries.find(x => x.code === code);
  c.innerHTML = pageHead('القنوات المكررة', 'قنوات بنفس الاسم (بعد تجاهل الجودة والرموز) في نفس الدولة. اختر القناة التي تريد الإبقاء عليها ثم ادمج أو أخفِ أو احذف البقية.',
    groups.length ? `<button class="btn2 ghost" id="d-hide-all">${ic('eyeoff')} إخفاء كل المكررات</button><button class="btn2 primary" id="d-merge-all">${ic('layers')} دمج الكل تلقائيًا</button>` : '')
    + (groups.length ? `<p class="muted">${num(groups.length)} مجموعة · الدمج ينقل روابط المكررات إلى القناة المختارة (سيرفرات إضافية) ثم يحذفها.</p>
    <section class="dup-grid">${groups.map((g, gi) => `<article class="dup" data-g="${gi}">
      <header>${flag(co(g.country)?.flag_url)}<h4>${esc(g.name)}</h4><span class="muted">${esc(co(g.country)?.name_ar || 'بدون دولة')}</span><em>${g.channels.length}</em></header>
      ${g.channels.map((x, i) => `<label class="dup-row"><input type="radio" name="keep${gi}" value="${x.id}" ${i ? '' : 'checked'}>
        ${thumb(x)}<div><b>${x.number ? `${x.number}. ` : ''}${esc(x.name)}</b><small class="muted" dir="ltr">${esc(x.uid)}</small>
        <div class="dup-tags">${x.is_published ? chip('ok', 'منشورة') : chip('off', 'مخفية')}<span class="tag-s">${x.online}/${x.streams} روابط تعمل</span>${x.quality ? `<span class="tag-s">${x.quality}</span>` : ''}</div></div></label>`).join('')}
      <footer><button class="btn2 ghost sm" data-d="compare">${ic('compare')} مقارنة</button><button class="btn2 primary sm" data-d="merge">${ic('layers')} دمج</button><button class="btn2 ghost sm" data-d="hide">${ic('eyeoff')} إخفاء البقية</button><button class="btn2 danger-ghost sm" data-d="del">${ic('trash')} حذف البقية</button></footer>
    </article>`).join('')}</section>` : `<div class="panel">${empty('check', 'لا توجد قنوات مكررة', 'كل القنوات فريدة. ممتاز!')}</div>`);

  const pick = gi => { const g = groups[gi], keep = c.querySelector(`[name=keep${gi}]:checked`).value; return { keep, rest: g.channels.map(x => x.id).filter(id => id !== keep) }; };
  c.querySelectorAll('[data-d]').forEach(b => b.onclick = async () => {
    const card = b.closest('.dup'), gi = +card.dataset.g, { keep, rest: others } = pick(gi), a = b.dataset.d;
    if (a === 'compare') return compareChannels([keep, ...others], { onDone: () => go('duplicates') });
    if (a === 'del' && !await modal({ title: 'حذف المكررات', danger: true, ok: 'حذف', body: `<p>سيتم حذف ${others.length} قناة وروابطها نهائيًا والإبقاء على القناة المختارة.</p>` })) return;
    const ok = await busy(b, async () => {
      if (a === 'merge') await rpc('admin_merge', { p_keep: keep, p_remove: others });
      if (a === 'hide') await rpc('admin_hide_duplicates', { p_keep: keep, p_hide: others });
      if (a === 'del') await rest(`channels?id=in.(${others.join(',')})`, { method: 'DELETE', auth: true });
    });
    if (ok) { card.classList.add('done'); card.querySelector('footer').innerHTML = chip('ok', { merge: 'تم الدمج', hide: 'تم الإخفاء', del: 'تم الحذف' }[a]); refreshStats(); }
  });
  const all = async (btn, kind) => {
    if (!await modal({ title: kind === 'merge' ? 'دمج كل المكررات' : 'إخفاء كل المكررات', icon: 'layers', ok: 'تنفيذ', body: `<p>سيتم ${kind === 'merge' ? 'دمج' : 'إخفاء'} ${num(groups.length)} مجموعة مع الإبقاء على القناة المختارة في كل مجموعة (الأولى افتراضيًا: المنشورة صاحبة الرقم الأصغر).</p>` })) return;
    busy(btn, async () => {
      for (let gi = 0; gi < groups.length; gi++) {
        const { keep, rest: others } = pick(gi);
        if (kind === 'merge') await rpc('admin_merge', { p_keep: keep, p_remove: others }); else await rpc('admin_hide_duplicates', { p_keep: keep, p_hide: others });
      }
      toast('تم تنفيذ العملية على كل المجموعات', 'success'); refreshStats(); go('duplicates');
    });
  };
  c.querySelector('#d-merge-all')?.addEventListener('click', e => all(e.currentTarget, 'merge'));
  c.querySelector('#d-hide-all')?.addEventListener('click', e => all(e.currentTarget, 'hide'));
}

/* ═══════════════════ قيد المراجعة ═══════════════════
   أي قناة تُضاف لقاعدة البيانات (ملف، استيراد، استعادة، ديمو) تدخل هنا ولا تظهر في الموقع
   حتى يفحصها المدير ويوافق عليها. التصنيف يأتي من الواجهة review_queue في قاعدة البيانات. */
const BUCKETS = [
  { k: 'unchecked', i: 'info', t: 'لم تُفحص', d: 'روابطها لم تُفحص بعد — شغّل الفحص لتُصنَّف تلقائيًا.', h: 45 },
  { k: 'ready', i: 'check', t: 'جاهزة للنشر', d: 'روابطها تعمل وغير مكررة. راجعها ثم وافق عليها.', h: 145 },
  { k: 'duplicate', i: 'layers', t: 'مكررة', d: 'نسخة أخرى من قناة موجودة. قارن بينهما ثم ادمج أو احذف.', h: 35 },
  { k: 'offline', i: 'alert', t: 'لا تعمل', d: 'لا يوجد رابط يعمل لهذه القنوات حاليًا.', h: 0 },
  { k: 'logo', i: 'eyeoff', t: 'شعار معطّل', d: 'القناة تعمل لكن شعارها لا يظهر. يمكنك تعديله أو نشرها بدونه.', h: 280 },
  { k: 'incomplete', i: 'edit', t: 'ناقصة', d: 'قنوات تعمل لكن بدون دولة. عدّلها قبل النشر.', h: 200 }
];
const RV = { bucket: '', page: 0, size: 50, q: '', sel: new Set(), autoCheck: false };

async function review(c) {
  const [st] = await Promise.all([refreshStats(), loadLookups()]);
  const counts = st.review || {};
  if (!RV.bucket || (!counts[RV.bucket] && st.pending)) RV.bucket = BUCKETS.find(b => counts[b.k])?.k || 'ready';
  const B = BUCKETS.find(b => b.k === RV.bucket);
  const p = [`bucket=eq.${RV.bucket}`];
  const q = RV.q.trim();
  if (q) p.push(/^\d+$/.test(q) ? `number=eq.${q}` : `name=ilike.${enc(`*${q.replace(/[*,()]/g, ' ')}*`)}`);
  const res = st.pending ? await rest(`review_queue?select=*&${p.join('&')}&order=number.asc.nullslast`, { auth: true, prefer: 'count=exact', range: `${RV.page * RV.size}-${RV.page * RV.size + RV.size - 1}` }) : { data: [], total: 0 };
  const rows = res.data || [], total = res.total ?? rows.length, pages = Math.max(1, Math.ceil(total / RV.size));
  RV.sel.clear();
  // القناة الأصلية لكل مكررة
  const keepers = new Map();
  const kIds = [...new Set(rows.map(r => r.duplicate_of).filter(Boolean))];
  if (kIds.length) ((await rest(`channels?select=id,name,number,is_published,logo_url&id=in.(${kIds.join(',')})`, { auth: true })).data || []).forEach(k => keepers.set(k.id, k));
  const cat = slug => S.cats.find(x => x.slug === slug), co = code => S.countries.find(x => x.code === code);

  c.innerHTML = pageHead('قيد المراجعة', 'القنوات المضافة حديثًا — من أي مصدر — لا تظهر للمشاهدين حتى توافق عليها. افحص الروابط أولًا لتُصنَّف تلقائيًا إلى جاهزة ومكررة ومعطّلة.',
    st.pending ? `<button class="btn2 primary" id="rv-check">${ic('zap')} فحص القنوات المعلّقة</button>` : '')
    + (st.pending ? `<section class="rv-tabs">${BUCKETS.map(b => `<button class="rv-tab ${b.k === RV.bucket ? 'on' : ''}" data-b="${b.k}" style="--h:${b.h}" ${counts[b.k] ? '' : 'data-zero'}>
        <span class="rv-ic">${ic(b.i)}</span><span><b>${num(counts[b.k] || 0)}</b><small>${b.t}</small></span></button>`).join('')}</section>
      <div class="prog2" id="rv-prog" hidden><div class="prog2-t"><span></span><b></b></div><div class="prog2-b"><i></i></div>
        <div class="hc-live"><span class="ok">${ic('check')} <b id="rv-ok">0</b> تعمل</span><span class="bad">${ic('alert')} <b id="rv-bad">0</b> معطّلة</span><span>${ic('eye')} <b id="rv-logo">0</b> شعار معطّل</span><button class="btn2 danger-ghost sm" id="rv-stop">${ic('x')} إيقاف</button></div></div>
      <div class="rv-head"><div><h3>${ic(B.i)} ${B.t} <em>${num(total)}</em></h3><p class="muted">${B.d}</p></div>
        <label class="search2 sm">${ic('search')}<input id="rv-q" type="search" placeholder="بحث بالاسم أو الرقم…" value="${esc(RV.q)}"></label>
        ${total ? `<details class="menu2"><summary class="btn2 ghost sm">${ic('dots')} على كل «${B.t}» (${num(total)})</summary><div class="menu2-list">
          ${RV.bucket !== 'offline' && RV.bucket !== 'unchecked' ? `<button data-allrv="approve">${ic('check')} موافقة ونشر الكل</button>` : ''}
          ${RV.bucket === 'duplicate' ? `<button data-allrv="merge">${ic('layers')} دمج الكل في القنوات الأصلية</button>` : ''}
          <button data-allrv="reject" class="bad">${ic('trash')} رفض وحذف الكل</button></div></details>` : ''}
      </div>
      <div class="panel tbl-panel">${rows.length ? `<div class="tbl-scroll"><table class="tbl2 rv-tbl">
        <thead><tr><th><label class="chk2"><input type="checkbox" id="rv-all"><i></i></label></th><th>#</th><th>القناة</th><th>الفئة / الدولة</th><th>الروابط</th>${RV.bucket === 'duplicate' ? '<th>الأصلية</th>' : ''}<th></th></tr></thead>
        <tbody>${rows.map(r => { const k = cat(r.category_slug), cc = co(r.country_code), kp = keepers.get(r.duplicate_of); return `<tr data-id="${r.id}">
          <td><label class="chk2"><input type="checkbox" class="rv-sel" value="${r.id}"><i></i></label></td>
          <td class="num2">${r.number ?? '—'}</td>
          <td><div class="ch2">${thumb(r)}<div><b>${esc(r.name)}${r.logo_status === 'broken' ? ' <span class="tag-s warn">شعار معطّل</span>' : ''}</b><small class="muted" dir="ltr">${esc(r.uid)}</small></div></div></td>
          <td>${k ? `<span class="cat2" style="--h:${k.hue}">${ic(k.icon)}${esc(k.name_ar)}</span>` : '—'}<div class="cl">${flag(cc?.flag_url)}<small class="muted">${esc(cc?.name_ar || 'بدون دولة')}</small></div></td>
          <td><span class="streams-b"><b class="ok">${r.online}</b>${r.total - r.online - r.unchecked ? `<b class="bad">${r.total - r.online - r.unchecked}</b>` : ''}${r.unchecked ? `<b class="off">${r.unchecked}</b>` : ''}<span>/ ${r.total}</span></span></td>
          ${RV.bucket === 'duplicate' ? `<td>${kp ? `<div class="ch2 sm">${thumb(kp)}<div><b>${kp.number ? `${kp.number}. ` : ''}${esc(kp.name)}</b><small>${kp.is_published ? chip('ok', 'منشورة') : chip('warn', 'معلّقة')}</small></div></div>` : '—'}</td>` : ''}
          <td class="acts2">
            ${RV.bucket === 'duplicate' && kp ? `<button class="btn2 ghost sm" data-rv="compare" data-k="${kp.id}">${ic('compare')} مقارنة</button><button class="icon2" data-rv="merge" title="دمج في الأصلية">${ic('layers')}</button>` : ''}
            <button class="icon2" data-rv="play" title="تشغيل">${ic('play')}</button>
            <button class="icon2" data-rv="edit" title="تعديل">${ic('edit')}</button>
            ${RV.bucket !== 'offline' && RV.bucket !== 'unchecked' ? `<button class="icon2 ok" data-rv="approve" title="موافقة ونشر">${ic('check')}</button>` : ''}
            <button class="icon2 bad" data-rv="reject" title="رفض وحذف">${ic('trash')}</button>
          </td></tr>`; }).join('')}</tbody></table></div>`
        : empty(B.i, `لا توجد قنوات «${B.t}»`, q ? 'لا توجد نتائج مطابقة للبحث.' : 'اختر تبويبًا آخر من الأعلى.')}
        <div class="pager2"><span class="sp"></span>${pager(RV.page, pages)}</div></div>
      <div class="bulkbar" id="rv-bar" hidden><b id="rv-selc"></b>
        ${RV.bucket !== 'offline' && RV.bucket !== 'unchecked' ? `<button data-rvb="approve">${ic('check')} موافقة ونشر</button>` : ''}
        ${RV.bucket === 'duplicate' ? `<button data-rvb="merge">${ic('layers')} دمج في الأصلية</button>` : ''}
        <button data-rvb="reject" class="bad">${ic('trash')} رفض وحذف</button>
        <button data-rvb="clear" class="x" title="إلغاء التحديد">${ic('x')}</button></div>`
    : `<div class="panel">${empty('check', 'لا توجد قنوات بانتظار المراجعة', 'كل القنوات تمت مراجعتها. أي قناة جديدة — من استيراد مصدر أو ملف SQL أو استعادة نسخة — ستظهر هنا أولًا.', `<button class="btn2 ghost" data-go="maintenance">${ic('history')} استعادة نسخة الديمو</button>`)}</div>`);

  c.querySelector('[data-go]')?.addEventListener('click', () => go('maintenance'));
  c.querySelectorAll('[data-b]').forEach(b => b.onclick = () => { RV.bucket = b.dataset.b; RV.page = 0; go('review'); });
  c.querySelectorAll('[data-page]').forEach(b => b.onclick = () => { RV.page = +b.dataset.page; go('review'); });
  let t; c.querySelector('#rv-q')?.addEventListener('input', e => { clearTimeout(t); t = setTimeout(() => { RV.q = e.target.value; RV.page = 0; go('review'); }, 450); });
  if (RV.q) { const el = c.querySelector('#rv-q'); el?.focus(); el?.setSelectionRange(el.value.length, el.value.length); }

  const apply = async (action, ids, btn) => {
    if (!ids.length) return;
    const label = { approve: 'موافقة ونشر', reject: 'رفض وحذف', merge: 'دمج في الأصلية' }[action];
    if (action !== 'approve' && !await modal({ title: `${label} ${num(ids.length)} قناة`, danger: action === 'reject', icon: action === 'merge' ? 'layers' : 'trash', ok: label, confirmWord: action === 'reject' && ids.length > 50 ? 'حذف' : '',
      body: action === 'reject' ? `<p>سيتم حذف <b>${num(ids.length)} قناة</b> وروابطها نهائيًا من قاعدة البيانات.</p>` : `<p>ستنتقل روابط ${num(ids.length)} قناة مكررة إلى قنواتها الأصلية كسيرفرات إضافية، ثم تُحذف المكررات.</p>` })) return;
    await busy(btn, async () => {
      let n = 0;
      for (const part of chunk(ids, 400)) n += await rpc('admin_review_apply', { p_action: action, p_ids: part });
      toast(`${label}: ${num(n)} قناة`, 'success');
      go('review');
    });
  };
  const bar = c.querySelector('#rv-bar');
  const upd = () => { if (!bar) return; bar.hidden = !RV.sel.size; c.querySelector('#rv-selc').textContent = `${num(RV.sel.size)} محددة`; };
  c.querySelector('#rv-all')?.addEventListener('change', e => { c.querySelectorAll('.rv-sel').forEach(x => { x.checked = e.target.checked; x.checked ? RV.sel.add(x.value) : RV.sel.delete(x.value); }); upd(); });
  c.querySelectorAll('[data-rvb]').forEach(b => b.onclick = () => {
    if (b.dataset.rvb === 'clear') { RV.sel.clear(); c.querySelectorAll('.rv-sel, #rv-all').forEach(x => { x.checked = false; }); upd(); return; }
    apply(b.dataset.rvb, [...RV.sel], b);
  });
  c.querySelectorAll('[data-allrv]').forEach(b => b.onclick = async () => {
    b.closest('details').open = false;
    const ids = (await restAll(`review_queue?select=id&bucket=eq.${RV.bucket}`, { auth: true })).map(r => r.id);
    apply(b.dataset.allrv, ids, b);
  });
  const tbody = c.querySelector('.rv-tbl tbody');
  tbody?.addEventListener('change', e => { if (e.target.classList.contains('rv-sel')) { e.target.checked ? RV.sel.add(e.target.value) : RV.sel.delete(e.target.value); upd(); } });
  tbody?.addEventListener('click', async e => {
    const b = e.target.closest('[data-rv]'); if (!b) return;
    const id = b.closest('tr').dataset.id, r = rows.find(x => x.id === id), a = b.dataset.rv;
    if (a === 'play') previewChannel(id, r.name);
    if (a === 'edit') editChannel(id);
    if (a === 'compare') compareChannels([b.dataset.k, id], { onDone: () => go('review') });
    if (a === 'approve' || a === 'reject' || a === 'merge') apply(a, [id], b);
  });

  // الفحص: روابط القنوات المعلّقة التي لم تُفحص (أو كلها عند الطلب)
  const runCheck = async scope => {
    const H = S.health, prog = c.querySelector('#rv-prog'), btn = c.querySelector('#rv-check');
    if (H.running) return toast('يوجد فحص قيد التشغيل بالفعل', 'info');
    H.running = true; H.stop = false; H.tab = 'review'; prog.hidden = false; btn.disabled = true;
    const setP = (tx, pc) => { prog.querySelector('span').textContent = tx; prog.querySelector('b').textContent = `${Math.round(pc)}%`; prog.querySelector('i').style.width = `${pc}%`; };
    c.querySelector('#rv-stop').onclick = () => { H.stop = true; };
    let okN = 0, badN = 0, logoBad = 0;
    try {
      setP('جلب روابط القنوات المعلّقة…', 1);
      const items = await restAll(`streams?select=id,url,channel_id,channels!inner(hidden_reason)&channels.hidden_reason=eq.pending${scope === 'all' ? '' : '&status=eq.unknown'}&is_active=eq.true`, { auth: true });
      if (!items.length) { toast('لا توجد روابط تحتاج فحصًا', 'info'); return; }
      let pending = [], done = 0;
      const flush = async () => { if (!pending.length) return; const part = pending; pending = []; await rpc('admin_record_checks', { p_results: part }); };
      await pool(items, 16, s => probeStream(s.url), s => {
        done++; s.res.ok ? okN++ : badN++;
        pending.push({ id: s.id, ...s.res });
        if (pending.length >= 50) flush().catch(() => {});
        c.querySelector('#rv-ok').textContent = num(okN); c.querySelector('#rv-bad').textContent = num(badN);
        setP(`فحص الروابط ${num(done)} / ${num(items.length)}`, done / items.length * 85);
      });
      await flush();
      if (!H.stop) {
        const ids = [...new Set(items.map(s => s.channel_id))], chans = [];
        for (const part of chunk(ids, 150)) chans.push(...((await rest(`channels?select=id,logo_url&id=in.(${part.join(',')})&logo_url=not.is.null`, { auth: true })).data || []));
        let ld = 0; const results = [];
        await pool(chans, 12, ch => probeLogo(ch.logo_url), ch => { ld++; results.push({ id: ch.id, ok: ch.res }); if (!ch.res) logoBad++; c.querySelector('#rv-logo').textContent = num(logoBad); setP(`فحص الشعارات ${num(ld)} / ${num(chans.length)}`, 85 + ld / Math.max(1, chans.length) * 15); });
        for (const part of chunk(results, 200)) await rpc('admin_record_logos', { p_results: part });
      }
      setP(H.stop ? 'تم إيقاف الفحص' : 'اكتمل الفحص', 100);
      toast(`اكتمل الفحص: ${num(okN)} رابط يعمل، ${num(badN)} معطّل`, 'success');
    } catch (e) { toast(e.message, 'error'); }
    finally { H.running = false; if (c.isConnected && S.tab === 'review') { RV.bucket = ''; go('review'); } }
  };
  c.querySelector('#rv-check')?.addEventListener('click', async () => {
    const f = await modal({ title: 'فحص القنوات المعلّقة', icon: 'zap', ok: 'بدء الفحص', body: `<p>يفحص روابط البث والشعارات من متصفحك تمامًا كما يراها المشاهد، ثم تُصنَّف القنوات تلقائيًا.</p>
      <label class="fld"><span>ماذا نفحص؟</span><select name="scope"><option value="unknown">الروابط التي لم تُفحص بعد</option><option value="all">كل روابط القنوات المعلّقة (إعادة فحص)</option></select></label>
      <p class="muted sm">يمكنك إيقاف الفحص في أي وقت ومتابعته لاحقًا — الروابط المفحوصة تُحفظ أولًا بأول.</p>` });
    if (f) runCheck(f.get('scope'));
  });
  if (RV.autoCheck && st.pending) { RV.autoCheck = false; runCheck('unknown'); }
}

/* ═══════════════════ تشغيل قناة للمعاينة ═══════════════════ */
async function previewChannel(id, name) {
  const list = (await rest(`streams?channel_id=eq.${id}&select=id,url,host,status,priority,quality,is_active&order=priority.asc`, { auth: true })).data || [];
  const d = document.createElement('dialog');
  d.className = 'modal wide pv-dlg';
  d.innerHTML = `<div class="pv-h"><h3>${ic('play')} ${esc(name || 'معاينة')}</h3><button class="icon2" data-x>${ic('x')}</button></div>
    <div class="pv-stage"><div id="pv-pl"></div></div>
    <div class="pv-list">${list.map((s, i) => `<button class="pv-s" data-i="${i}">${chip(...(SSTATUS[s.status] || SSTATUS.unknown))}<b>السيرفر ${i + 1}</b><small dir="ltr">${esc(s.host || '')}</small>${s.quality ? `<span class="tag-s">${esc(s.quality)}</span>` : ''}</button>`).join('') || '<p class="muted">لا توجد روابط.</p>'}</div>`;
  document.body.appendChild(d);
  const player = createPlayer(d.querySelector('#pv-pl'));
  const load = i => player.load({ streams: list.map(s => ({ url: s.url, server: s.host, quality: s.quality })), title: name, startIndex: i });
  if (list.length) load(0);
  d.querySelectorAll('[data-i]').forEach(b => b.onclick = () => load(+b.dataset.i));
  d.querySelector('[data-x]').onclick = () => d.close();
  d.addEventListener('click', e => { if (e.target === d) d.close(); });
  d.onclose = () => { player.destroy(); d.remove(); };
  d.showModal();
}

/* ═══════════════════ مقارنة القنوات المكررة ═══════════════════
   يشغّل القنوات جنبًا إلى جنب ويقيس جودة البث وصحته فعليًا من المتصفح:
   الدقة، معدل البت، سرعة البدء، التقطيع، الأخطاء، الإطارات المفقودة — ثم يرشّح الأفضل. */
async function compareChannels(ids, { onDone } = {}) {
  await loadHls();
  const chans = ((await rest(`channels?id=in.(${ids.join(',')})&select=id,name,number,uid,logo_url,quality,is_published,hidden_reason,streams(id,url,host,status,priority,is_active)`, { auth: true })).data || [])
    .sort((a, b) => ids.indexOf(a.id) - ids.indexOf(b.id));
  if (chans.length < 2) return toast('تحتاج قناتين على الأقل للمقارنة', 'error');
  chans.forEach(ch => { ch.streams = ch.streams.filter(s => s.is_active).sort((a, b) => (b.status === 'online') - (a.status === 'online') || a.priority - b.priority); });
  const d = document.createElement('dialog');
  d.className = 'modal cmp-dlg';
  d.innerHTML = `<div class="pv-h"><h3>${ic('compare')} مقارنة جودة البث</h3><small class="muted">تُشغَّل القنوات معًا وتُقاس جودة كل بث مباشرة. الصوت لقناة واحدة فقط — اضغط ${ic('vol')} للتبديل.</small><button class="icon2" data-x>${ic('x')}</button></div>
    <div class="cmp-grid" style="--n:${Math.min(chans.length, 3)}">${chans.map((ch, i) => `<article class="cmp" data-i="${i}">
      <header>${thumb(ch)}<div><b>${ch.number ? `${ch.number}. ` : ''}${esc(ch.name)}</b><small dir="ltr" class="muted">${esc(ch.uid)}</small></div>${ch.is_published ? chip('ok', 'منشورة') : ch.hidden_reason === 'pending' ? chip('warn', 'معلّقة') : chip('off', 'مخفية')}</header>
      <div class="cmp-v"><video playsinline muted></video><span class="cmp-badge">${ic('star')} الأفضل</span><span class="cmp-st">جارٍ الاتصال…</span>
        <button class="cmp-aud icon2" title="الصوت">${ic('mute')}</button></div>
      <div class="cmp-srv"><div class="sel2 sm">${ic('server')}<select>${ch.streams.map((s, k) => `<option value="${k}">السيرفر ${k + 1} · ${esc(s.host || '')} ${s.status === 'online' ? '✓' : s.status === 'offline' ? '✕' : ''}</option>`).join('') || '<option>لا توجد روابط</option>'}</select></div><em>${ch.streams.filter(s => s.status === 'online').length}/${ch.streams.length} تعمل</em></div>
      <table class="cmp-m"></table>
      <label class="cmp-keep"><input type="radio" name="keep" value="${ch.id}" ${i ? '' : 'checked'}><span>${ic('check')} أبقِ هذه القناة</span></label>
    </article>`).join('')}</div>
    <footer class="cmp-f"><span class="muted" id="cmp-hint">يتم القياس… انتظر 10 ثوانٍ تقريبًا ليتضح الفرق.</span><span class="sp"></span>
      <button class="btn2 primary" data-c="merge">${ic('layers')} دمج البقية في المختارة</button>
      <button class="btn2 ghost" data-c="hide">${ic('eyeoff')} إخفاء البقية</button>
      <button class="btn2 danger-ghost" data-c="del">${ic('trash')} حذف البقية</button></footer>`;
  document.body.appendChild(d);
  const tiles = chans.map((ch, i) => ({ ch, el: d.querySelector(`.cmp[data-i="${i}"]`), hls: null, m: null, timer: 0 }));
  const metric = t => {
    const v = t.el.querySelector('video'), m = t.m, h = t.hls, lv = h?.levels?.[h.currentLevel >= 0 ? h.currentLevel : h.loadLevel];
    let buf = 0; for (let i = 0; i < v.buffered.length; i++) if (v.buffered.start(i) <= v.currentTime + .5) buf = Math.max(buf, v.buffered.end(i) - v.currentTime);
    const q = v.getVideoPlaybackQuality?.();
    m.w = v.videoWidth; m.h = v.videoHeight; m.br = lv?.bitrate || m.br; m.bw = h?.bandwidthEstimate || 0; m.buf = buf;
    m.drop = q ? q.droppedVideoFrames : 0; m.frames = q ? q.totalVideoFrames : 0; m.levels = h?.levels?.length || 0;
    m.maxH = Math.max(m.maxH || 0, ...(h?.levels || []).map(l => l.height || 0));
    const rows = [
      ['الحالة', m.failed ? `<span class="badtxt">${esc(m.failed)}</span>` : m.ttff ? '<span class="oktxt">يعمل</span>' : 'جارٍ التحميل…'],
      ['الدقة', m.h ? `${m.w}×${m.h}${m.maxH > m.h ? ` <small>(حتى ${m.maxH}p)</small>` : ''}` : '—'],
      ['معدّل البت', m.br ? `${(m.br / 1e6).toFixed(2)} Mbps` : '—'],
      ['سرعة البدء', m.ttff ? `${(m.ttff / 1000).toFixed(1)} ث` : '—'],
      ['التقطيع', `${m.stalls} مرة`], ['الأخطاء', `${m.errors}`],
      ['المخزن المؤقت', `${buf.toFixed(1)} ث`], ['الإطارات المفقودة', m.frames ? `${m.drop} من ${m.frames}` : '—'],
      ['الجودات المتاحة', m.levels ? `${m.levels}` : '—']
    ];
    t.el.querySelector('.cmp-m').innerHTML = rows.map(([k, val]) => `<tr><th>${k}</th><td>${val}</td></tr>`).join('');
    t.el.querySelector('.cmp-st').textContent = m.failed ? 'لا يعمل' : m.ttff ? `${m.h ? `${m.h}p` : ''}` : 'جارٍ الاتصال…';
    t.el.classList.toggle('bad', !!m.failed);
  };
  const score = t => { const m = t.m; if (!m || m.failed || !m.ttff) return -1; return Math.min(m.h || 0, 2160) / 10 + Math.min(m.br || 0, 8e6) / 2e5 - m.stalls * 15 - m.errors * 5 - m.ttff / 400 + t.ch.streams.filter(s => s.status === 'online').length * 3; };
  const rank = () => {
    const best = tiles.reduce((a, b) => score(b) > score(a) ? b : a);
    tiles.forEach(t => t.el.classList.toggle('best', t === best && score(t) >= 0));
    if (score(best) >= 0) { d.querySelector('#cmp-hint').textContent = `الترشيح: «${best.ch.name}» — يمكنك اختيار غيرها.`; if (!d.dataset.picked) d.querySelector(`[name=keep][value="${best.ch.id}"]`).checked = true; }
  };
  const start = (t, k = 0) => {
    try { t.hls?.destroy(); } catch { /* ignore */ }
    clearInterval(t.timer);
    const v = t.el.querySelector('video'), s = t.ch.streams[k];
    t.m = { stalls: 0, errors: 0, ttff: 0, t0: performance.now(), failed: s ? '' : 'لا توجد روابط' };
    if (!s) return metric(t);
    if (location.protocol === 'https:' && s.url.startsWith('http:')) { t.m.failed = 'رابط http غير آمن'; return metric(t); }
    v.onplaying = () => { if (!t.m.ttff) t.m.ttff = performance.now() - t.m.t0; };
    v.onwaiting = () => { if (t.m.ttff) t.m.stalls++; };
    if (window.Hls?.isSupported()) {
      const h = t.hls = new Hls({ lowLatencyMode: true, manifestLoadingMaxRetry: 1, capLevelToPlayerSize: false });
      h.on(Hls.Events.MANIFEST_PARSED, () => { h.currentLevel = h.levels.length - 1; h.nextLevel = -1; v.play().catch(() => {}); }); // نبدأ بأعلى جودة ثم التكيف التلقائي
      h.on(Hls.Events.ERROR, (_, e) => { t.m.errors++; if (e.fatal) { t.m.failed = e.type === Hls.ErrorTypes.NETWORK_ERROR ? 'تعذّر الاتصال بالسيرفر' : 'خطأ في البث'; try { h.destroy(); } catch { /* ignore */ } } });
      h.loadSource(s.url); h.attachMedia(v);
    } else { v.src = s.url; v.onerror = () => { t.m.failed = 'تعذّر التشغيل'; }; v.play().catch(() => {}); }
    setTimeout(() => { if (!t.m.ttff && !t.m.failed) t.m.failed = 'لا يستجيب'; }, 16000);
    t.timer = setInterval(() => { metric(t); rank(); }, 1000);
  };
  tiles.forEach(t => {
    start(t);
    t.el.querySelector('select').onchange = e => start(t, +e.target.value);
    t.el.querySelector('.cmp-aud').onclick = () => tiles.forEach(o => {
      const v = o.el.querySelector('video'), on = o === t && v.muted;
      v.muted = !on; o.el.querySelector('.cmp-aud').innerHTML = ic(on ? 'vol' : 'mute'); o.el.classList.toggle('aud', on);
    });
  });
  d.querySelectorAll('[name=keep]').forEach(r => r.onchange = () => { d.dataset.picked = '1'; });
  const close = () => d.close();
  d.querySelector('[data-x]').onclick = close;
  d.onclose = () => { tiles.forEach(t => { clearInterval(t.timer); try { t.hls?.destroy(); } catch { /* ignore */ } }); d.remove(); };
  d.querySelectorAll('[data-c]').forEach(b => b.onclick = async () => {
    const keep = d.querySelector('[name=keep]:checked').value, others = chans.map(x => x.id).filter(x => x !== keep), kept = chans.find(x => x.id === keep), a = b.dataset.c;
    const label = { merge: 'دمج', hide: 'إخفاء', del: 'حذف' }[a];
    if (a === 'del' && !await modal({ title: 'حذف البقية', danger: true, ok: 'حذف', body: `<p>سيتم حذف ${others.length} قناة وروابطها نهائيًا والإبقاء على «${esc(kept.name)}».</p>` })) return;
    const ok = await busy(b, async () => {
      if (a === 'merge') await rpc('admin_merge', { p_keep: keep, p_remove: others });
      if (a === 'hide') await rpc('admin_hide_duplicates', { p_keep: keep, p_hide: others });
      if (a === 'del') await rest(`channels?id=in.(${others.join(',')})`, { method: 'DELETE', auth: true });
      if (kept.hidden_reason === 'pending') await rpc('admin_review_apply', { p_action: 'approve', p_ids: [keep] }); // المختارة معلّقة: الاختيار هنا موافقة عليها
    });
    if (ok) { toast(`تم ${label} البقية والإبقاء على «${kept.name}»`, 'success'); close(); refreshStats(); onDone?.(); }
  });
  d.showModal();
}

/* ═══════════════════ الإعدادات العامة ═══════════════════ */
const getSetting = async key => (await rest(`site_settings?select=value&key=eq.${key}`, { auth: true })).data?.[0]?.value ?? null;
const saveSetting = (key, value, isPublic = true) => rest('site_settings', { method: 'POST', auth: true, prefer: 'resolution=merge-duplicates,return=minimal', body: { key, value, is_public: isPublic } });

async function settings(c) {
  const [hero, dev] = await Promise.all([getSetting('hero'), getSetting('developer')]);
  let heroId = hero?.channel_id || null;
  const heroCh = heroId ? (await rest(`channels?id=eq.${heroId}&select=id,name,number,logo_url,quality,is_published`, { auth: true })).data?.[0] : null;
  const D = { name_ar: '', name_en: '', social: {}, ...(dev || {}) };
  const heroCard = ch => ch ? `<div class="hero-pick">${thumb(ch)}<div><small>يعرض الآن في الرئيسية</small><b>${ch.number ? `${ch.number}. ` : ''}${esc(ch.name)}</b>${ch.is_published ? '' : `<span class="tag-s warn">غير منشورة — لن تظهر حتى تنشرها</span>`}</div>
      <button class="btn2 ghost sm" id="hp-clear">${ic('x')} إلغاء الاختيار</button></div>`
    : `<div class="hero-pick empty">${ic('star')}<div><b>اختيار تلقائي</b><small>تُعرض قناة مميزة عشوائية في كل زيارة.</small></div></div>`;

  c.innerHTML = pageHead('الإعدادات العامة', 'إعدادات تظهر في الموقع للمشاهدين: قناة الواجهة الرئيسية، وبيانات المطوّر وحسابات التواصل في التذييل.')
    + `<section class="panel"><div class="panel-h"><h3>${ic('live')} قناة «يعرض الآن» في الرئيسية</h3><small>تظهر في الواجهة الكبيرة أعلى الصفحة الرئيسية مع اسمها</small></div>
      <div id="hp-cur">${heroCard(heroCh)}</div>
      <label class="search2 hp-search">${ic('search')}<input id="hp-q" type="search" placeholder="ابحث عن قناة منشورة بالاسم أو الرقم لاختيارها…" autocomplete="off"></label>
      <div class="hp-res" id="hp-res"></div></section>
    <form class="panel" id="dev-f"><div class="panel-h"><h3>${ic('user')} برمجة وتطوير — التذييل</h3><small>يظهر في أسفل كل صفحات الموقع</small></div>
      <div class="two"><label class="fld"><span>الاسم بالعربية</span><input name="name_ar" maxlength="80" value="${esc(D.name_ar)}"></label>
        <label class="fld"><span>الاسم بالإنجليزية</span><input name="name_en" maxlength="80" dir="ltr" value="${esc(D.name_en)}"></label></div>
      <p class="muted sm">${ic('info')} اكتب <b>اسم المستخدم فقط</b> لكل حساب (أو رقم الهاتف بصيغة دولية لواتساب وتيليجرام). اترك الحقل فارغًا لإخفاء الأيقونة.</p>
      <div class="soc-grid">${SOCIAL.map(s => `<label class="soc-f" style="--c:${s.color}"><span class="soc-ic">${socialIcon(s, 18)}</span><span class="soc-n">${s.ar}</span>
        <input name="s_${s.key}" dir="ltr" maxlength="80" value="${esc(D.social?.[s.key] || '')}" placeholder="${s.key === 'whatsapp' || s.key === 'telegram' ? '+970599273296' : 'username'}"><a class="soc-go" target="_blank" rel="noopener" title="فتح الرابط">${ic('external')}</a></label>`).join('')}</div>
      <div class="dev-prev"><small class="muted">معاينة التذييل:</small><div class="ft-dev-prev" id="dev-prev"></div></div>
      <div class="f-act"><button class="btn2 primary">${ic('check')} حفظ</button></div></form>`;

  // اختيار قناة الواجهة
  const setHero = async (id, btn) => busy(btn, async () => {
    await saveSetting('hero', { channel_id: id });
    toast(id ? 'تم اختيار قناة «يعرض الآن»' : 'عادت الواجهة للاختيار التلقائي', 'success');
    go('settings');
  });
  c.querySelector('#hp-clear')?.addEventListener('click', e => setHero(null, e.currentTarget));
  let tq; c.querySelector('#hp-q').oninput = e => {
    clearTimeout(tq);
    tq = setTimeout(async () => {
      const q = e.target.value.trim(), box = c.querySelector('#hp-res');
      if (!q) { box.innerHTML = ''; return; }
      const filter = /^\d+$/.test(q) ? `number=eq.${q}` : `name=ilike.${enc(`*${q.replace(/[*,()]/g, ' ')}*`)}`;
      const list = (await rest(`channels?select=id,name,number,logo_url,quality,country_code,is_published&is_published=eq.true&${filter}&order=number.asc&limit=12`, { auth: true })).data || [];
      box.innerHTML = list.length ? list.map(x => `<button class="hp-row ${x.id === heroId ? 'on' : ''}" data-id="${x.id}">${thumb(x)}<span><b>${x.number ? `${x.number}. ` : ''}${esc(x.name)}</b><small>${flag(S.countries.find(k => k.code === x.country_code)?.flag_url)}</small></span>${ic('check')}</button>`).join('')
        : '<p class="muted sm">لا توجد قنوات منشورة مطابقة.</p>';
      box.querySelectorAll('[data-id]').forEach(b => b.onclick = () => setHero(b.dataset.id, b));
    }, 300);
  };
  await loadLookups();

  // حسابات المطوّر
  const f = c.querySelector('#dev-f');
  const read = () => ({ name_ar: f.name_ar.value.trim(), name_en: f.name_en.value.trim(), social: Object.fromEntries(SOCIAL.map(s => [s.key, cleanHandle(f[`s_${s.key}`].value)]).filter(([, v]) => v)) });
  const preview = () => {
    const v = read(), links = socialLinks(v.social);
    c.querySelector('#dev-prev').innerHTML = `${v.name_ar ? `<p>برمجة وتطوير: <b>${esc(v.name_ar)}</b></p>` : ''}${v.name_en ? `<p dir="ltr" class="en">Developed by <b>${esc(v.name_en)}</b></p>` : ''}
      <div class="soc-row">${links.map(s => `<a href="${esc(s.href)}" target="_blank" rel="noopener" style="--c:${s.color}" title="${esc(s.href)}">${socialIcon(s, 16)}</a>`).join('')}</div>`;
    SOCIAL.forEach(s => { const h = cleanHandle(f[`s_${s.key}`].value), a = f.querySelector(`[name=s_${s.key}]`).nextElementSibling; a.hidden = !h; if (h) a.href = s.url(h); });
  };
  f.addEventListener('input', preview); preview();
  f.onsubmit = e => {
    e.preventDefault();
    busy(f.querySelector('.btn2.primary'), async () => {
      const v = read();
      await saveSetting('developer', v);
      SOCIAL.forEach(x => { f[`s_${x.key}`].value = v.social[x.key] || ''; }); // نعرض اليوزر المنظّف بدل الرابط الكامل
      toast('تم حفظ بيانات المطوّر — تظهر في تذييل الموقع', 'success');
    });
  };
}

/* ═══════════════════ النسخ الاحتياطي والاستعادة ═══════════════════ */
const BACKUP_TABLES = [['languages', 'code'], ['countries', 'code'], ['categories', 'slug'], ['site_settings', 'key'], ['playlist_sources', 'created_at'], ['channels', 'number'], ['streams', 'id'], ['reports', 'id']];
const TABLE_AR = { languages: 'اللغات', countries: 'الدول', categories: 'الفئات', site_settings: 'الإعدادات', playlist_sources: 'المصادر', channels: 'القنوات', streams: 'روابط البث', reports: 'البلاغات' };

/** نافذة تقدّم لا تُغلق أثناء العمل */
function progressDialog(title) {
  const d = document.createElement('dialog');
  d.className = 'modal prog-dlg';
  d.innerHTML = `<div class="m-ic">${ic('db')}</div><h3>${esc(title)}</h3><div class="prog2"><div class="prog2-t"><span>جارٍ التحضير…</span><b>0%</b></div><div class="prog2-b"><i></i></div><ul class="log"></ul></div><div class="m-act" hidden><button class="btn2 primary">إغلاق</button></div>`;
  d.addEventListener('cancel', e => { if (!d.dataset.done) e.preventDefault(); });
  document.body.appendChild(d); d.showModal();
  let last = '';
  const api = {
    set(t, p) {
      d.querySelector('.prog2-t span').textContent = t; d.querySelector('.prog2-t b').textContent = `${Math.round(p)}%`; d.querySelector('.prog2-b i').style.width = `${p}%`;
      const step = t.replace(/\s*\(.*\)$/, '').replace(/\s*\d[\d,]*\s*\/\s*\d[\d,]*.*$/, '');
      if (step !== last) { d.querySelector('.log li:last-child')?.classList.add('done'); d.querySelector('.log').insertAdjacentHTML('beforeend', `<li>${esc(step)}</li>`); last = step; }
    },
    finish(msg, ok = true) {
      d.dataset.done = '1'; d.querySelector('.log li:last-child')?.classList.add(ok ? 'done' : 'bad');
      d.querySelector('.prog2-t span').textContent = msg; if (!ok) d.querySelector('.prog2-b i').style.background = 'var(--bad)';
      const act = d.querySelector('.m-act'); act.hidden = false;
      return new Promise(res => { act.querySelector('button').onclick = () => { d.close(); d.remove(); res(); }; });
    }
  };
  return api;
}
const stamp = () => new Date().toISOString().slice(0, 16).replace(/[:T]/g, '-');
function downloadJson(obj, name) {
  const a = document.createElement('a');
  a.href = URL.createObjectURL(new Blob([JSON.stringify(obj)], { type: 'application/json' }));
  a.download = name; document.body.appendChild(a); a.click();
  setTimeout(() => { URL.revokeObjectURL(a.href); a.remove(); }, 1500);
}
async function makeBackup(set = () => {}) {
  const out = { app: 'MTC-iPTv', kind: 'backup', format: 1, app_version: VERSION, created_at: new Date().toISOString(),
    project: new URL(window.MTC_CONFIG.supabaseUrl).hostname.split('.')[0], tables: {} };
  for (const [i, [t, order]] of BACKUP_TABLES.entries()) {
    set(`نسخ ${TABLE_AR[t]}`, 5 + i / BACKUP_TABLES.length * 90);
    out.tables[t] = await restAll(`${t}?select=*&order=${order}.asc`, { auth: true });
  }
  return out;
}
const backupCounts = b => BACKUP_TABLES.map(([t]) => [t, b.tables?.[t]?.length ?? null]).filter(([, n]) => n != null);

/** إدخال صفوف على دفعات عبر admin_restore_rows */
async function restoreRows(table, rows, set, from, to) {
  let done = 0;
  for (const part of chunk(rows, table === 'streams' || table === 'channels' ? 400 : 500)) {
    await rpc('admin_restore_rows', { p_table: table, p_rows: part });
    done += part.length;
    set(`استعادة ${TABLE_AR[table]} (${num(done)} / ${num(rows.length)})`, from + (to - from) * done / Math.max(1, rows.length));
  }
}
async function restoreBackup(b, refs, set) {
  set('تفريغ البيانات الحالية', 12);
  await rpc('admin_restore_reset', { p_refs: refs });
  const order = [...(refs ? ['languages', 'countries', 'categories'] : []), 'site_settings', 'playlist_sources', 'channels', 'streams', 'reports'];
  const total = order.reduce((n, t) => n + (b.tables[t]?.length || 0), 0) || 1;
  let acc = 0;
  for (const t of order) {
    const rows = (b.tables[t] || []).map(r => { if (t !== 'channels') return r; const { duplicate_of, ...x } = r; return x; });
    const from = 15 + acc / total * 80; acc += rows.length;
    await restoreRows(t, rows, set, from, 15 + acc / total * 80);
  }
  const links = (b.tables.channels || []).filter(c => c.duplicate_of).map(c => ({ id: c.id, duplicate_of: c.duplicate_of }));
  if (links.length) { set('ربط القنوات المكررة', 96); for (const part of chunk(links, 500)) await rpc('admin_restore_links', { p_links: part }); }
}
/** نسخة الديمو: data/demo.json (نفس محتوى supabase/02_data.sql) */
async function restoreDemo(demo, set) {
  set('تفريغ القنوات والمصادر الحالية', 10);
  await rpc('admin_restore_reset', { p_refs: false });
  const now = new Date().toISOString();
  const sources = demo.sources.map(s => ({ id: crypto.randomUUID(), name: s.name, url: s.url, status: 'ready', last_import_at: now }));
  const srcByUrl = new Map(sources.map(s => [s.url, s.id]));
  const codes = new Set(S.countries.map(x => x.code)), cats = new Set(S.cats.map(x => x.slug)), langs = new Set(S.langs.map(x => x.code));
  const channels = [], streams = [];
  for (const r of demo.channels) {
    const id = crypto.randomUUID(), country = codes.has(r.country) ? r.country : null;
    channels.push({ id, uid: r.uid, number: r.number, name: r.name, alt_names: r.alt || [], network: r.network || null, logo_url: r.logo || null,
      country_code: country, category_slug: cats.has(r.category) ? r.category : 'general', extra_categories: (r.extra || []).filter(x => cats.has(x)),
      language_code: langs.has(r.language) ? r.language : null, quality: r.quality || null, website: r.website || null, is_featured: !!r.featured, is_published: true });
    r.streams.forEach((s, i) => streams.push({ id: crypto.randomUUID(), channel_id: id, url: s.url, quality: s.quality || null, priority: i,
      source_id: s.manual || !country ? null : srcByUrl.get(`https://iptv-org.github.io/iptv/countries/${country.toLowerCase()}.m3u`) || null }));
  }
  await restoreRows('playlist_sources', sources, set, 12, 16);
  await restoreRows('channels', channels, set, 16, 55);
  await restoreRows('streams', streams, set, 55, 95);
  set('تحديث عدّادات المصادر', 97);
  await rest('rpc/admin_cleanup', { method: 'POST', auth: true, body: { p_action: 'refresh_counts' } }).catch(() => {});
  return { channels: channels.length, streams: streams.length, sources: sources.length };
}

function backupSection(st) {
  return `<div class="sec-h"><h3>${ic('history')} النسخ الاحتياطي والاستعادة</h3><small>حسابات المشرفين لا تدخل في النسخ ولا تُمسح أبدًا</small></div>
    <section class="bk-grid">
      <div class="bk"><span class="bk-ic">${ic('download')}</span><div><b>تنزيل نسخة احتياطية</b><small>ملف واحد فيه كل شيء: ${num(st.channels)} قناة، ${num(st.streams)} رابط، ${num(st.sources)} مصدر، الدول والفئات واللغات والإعدادات والبلاغات.</small></div>
        <button class="btn2 primary" id="bk-down">${ic('download')} تنزيل النسخة</button></div>
      <div class="bk"><span class="bk-ic">${ic('upload')}</span><div><b>استعادة نسخة احتياطية</b><small>يستبدل البيانات الحالية بمحتوى ملف النسخة. تُنزَّل نسخة من الوضع الحالي تلقائيًا قبل البدء. القنوات المستعادة تدخل «قيد المراجعة».</small></div>
        <label class="btn2 ghost">${ic('upload')} اختيار ملف…<input type="file" id="bk-file" accept=".json,application/json" hidden></label></div>
      <div class="bk demo"><span class="bk-ic">${ic('tv')}</span><div><b>استعادة نسخة الديمو</b><small>يحمّل مكتبة القنوات الجاهزة (نفس ملف 02_data.sql): آلاف القنوات من iptv-org. تدخل كلها «قيد المراجعة» ويبدأ فحص كامل لروابطها فورًا، ثم توافق على ما تريد نشره.</small></div>
        <button class="btn2 ghost" id="bk-demo">${ic('history')} استعادة الديمو</button></div>
    </section>`;
}
function bindBackup(c) {
  c.querySelector('#bk-down').onclick = e => busy(e.currentTarget, async () => {
    const b = await makeBackup();
    downloadJson(b, `mtc-backup-${stamp()}.json`);
    toast(`تم تنزيل النسخة: ${num(b.tables.channels.length)} قناة و${num(b.tables.streams.length)} رابط`, 'success');
  });
  c.querySelector('#bk-file').onchange = async e => {
    const file = e.target.files[0]; e.target.value = '';
    if (!file) return;
    let b;
    try { b = JSON.parse(await file.text()); } catch { return toast('الملف ليس JSON صالحًا', 'error'); }
    if (b?.app !== 'MTC-iPTv' || b.kind !== 'backup' || !b.tables) return toast('هذا الملف ليس نسخة احتياطية من MTC-iPTv', 'error');
    const counts = backupCounts(b), hasRefs = ['languages', 'countries', 'categories'].every(t => b.tables[t]?.length);
    const f = await modal({ title: 'استعادة نسخة احتياطية', danger: true, icon: 'upload', ok: 'استعادة', confirmWord: 'استعادة',
      body: `<p>ملف النسخة: <b dir="ltr">${esc(file.name)}</b><br><small class="muted">أُنشئت ${date(b.created_at)}${b.project ? ` · المشروع ${esc(b.project)}` : ''}${b.app_version ? ` · الإصدار ${esc(b.app_version)}` : ''}</small></p>
        <div class="bk-counts">${counts.map(([t, n]) => `<span><b>${num(n)}</b>${TABLE_AR[t]}</span>`).join('')}</div>
        ${hasRefs ? `<label class="row-sw"><div><b>استعادة الدول واللغات والفئات أيضًا</b><small>تستبدل التعديلات الحالية عليها بما في النسخة</small></div>${sw(true, 'name="refs"')}</label>` : ''}
        <p class="warn-t">${ic('alert')} ستُحذف كل القنوات والروابط والمصادر والبلاغات الحالية ويحل محلها محتوى النسخة. ستُنزَّل نسخة من الوضع الحالي أولًا للأمان.</p>
        <p class="muted sm">${ic('info')} القنوات المنشورة في النسخة تدخل «قيد المراجعة» — راجعها ووافق عليها لتظهر من جديد.</p>` });
    if (!f) return;
    const P = progressDialog('استعادة نسخة احتياطية');
    try {
      P.set('حفظ نسخة من الوضع الحالي', 2);
      downloadJson(await makeBackup((t, p) => P.set(`حفظ نسخة من الوضع الحالي — ${t}`, p * .1)), `mtc-backup-before-restore-${stamp()}.json`);
      await restoreBackup(b, hasRefs && f.get('refs') === 'on', P.set);
      P.set('اكتملت الاستعادة', 100);
      await P.finish('اكتملت الاستعادة بنجاح — القنوات الآن في «قيد المراجعة».');
      S.cats = []; S.sources = []; RV.bucket = ''; go('review');
    } catch (err) { await P.finish(`فشلت الاستعادة: ${err.message}. لديك نسخة من الوضع السابق في التنزيلات.`, false); go('maintenance'); }
  };
  c.querySelector('#bk-demo').onclick = async e => {
    const demo = await busy(e.currentTarget, async () => { const r = await fetch('../data/demo.json', { cache: 'no-store' }); if (!r.ok) throw new Error(`تعذّر تحميل data/demo.json (HTTP ${r.status})`); return r.json(); });
    if (!demo?.channels) return;
    const nStreams = demo.channels.reduce((n, r) => n + r.streams.length, 0), st = S.stats;
    const f = await modal({ title: 'استعادة نسخة الديمو', danger: true, icon: 'history', ok: 'استعادة الديمو', confirmWord: 'ديمو',
      body: `<div class="bk-counts"><span><b>${num(demo.channels.length)}</b>قناة</span><span><b>${num(nStreams)}</b>رابط بث</span><span><b>${num(demo.sources.length)}</b>مصدر</span></div>
        <p>ما سيحدث بالترتيب:</p><ol class="bk-steps"><li>تنزيل نسخة احتياطية من الوضع الحالي تلقائيًا.</li><li>حذف القنوات (${num(st.channels)}) والروابط (${num(st.streams)}) والمصادر (${num(st.sources)}) الحالية.</li>
          <li>إضافة قنوات الديمو <b>بانتظار المراجعة</b> — لن يظهر شيء في الموقع.</li><li>فحص كامل لكل الروابط والشعارات، ثم فصل القنوات إلى: جاهزة، مكررة، لا تعمل، شعار معطّل، ناقصة.</li><li>تراجع وتوافق على ما تريد نشره.</li></ol>
        <p class="muted sm">الدول واللغات والفئات والإعدادات لا تتغيّر.</p>` });
    if (!f) return;
    const P = progressDialog('استعادة نسخة الديمو');
    try {
      await loadLookups(true);
      if (st.channels) downloadJson(await makeBackup((t, p) => P.set(`حفظ نسخة من الوضع الحالي — ${t}`, p * .1)), `mtc-backup-before-demo-${stamp()}.json`);
      const r = await restoreDemo(demo, P.set);
      P.set('اكتملت الاستعادة', 100);
      await P.finish(`تمت إضافة ${num(r.channels)} قناة و${num(r.streams)} رابط بانتظار المراجعة. سيبدأ الفحص الآن.`);
      S.sources = []; RV.bucket = 'unchecked'; RV.autoCheck = true; go('review');
    } catch (err) { await P.finish(`فشلت الاستعادة: ${err.message}`, false); go('maintenance'); }
  };
}

/* ═══════════════════ بلاغات المشاهدين ═══════════════════ */
async function reports(c) {
  const status = S.reportStatus || 'open';
  const rows = (await rest(`reports?select=id,reason,note,status,created_at,stream_id,channels(id,name,number,logo_url,is_published),streams(url,host)&status=eq.${status}&order=created_at.desc&limit=200`, { auth: true })).data || [];
  const byChannel = new Map();
  rows.forEach(r => { const k = r.channels?.id; if (!byChannel.has(k)) byChannel.set(k, { ch: r.channels, items: [] }); byChannel.get(k).items.push(r); });
  c.innerHTML = pageHead('بلاغات المشاهدين', 'مشاكل يبلّغ عنها المشاهدون من صفحة المشاهدة. افتح القناة لفحص روابطها أو أخفِها ثم علّم البلاغ كمحلول.',
    `<button class="btn2 ghost" id="r-clear">${ic('trash')} حذف المحلولة</button>`)
    + `<div class="seg"><button data-rs="open" class="${status === 'open' ? 'on' : ''}">مفتوحة</button><button data-rs="resolved" class="${status === 'resolved' ? 'on' : ''}">محلولة</button></div>`
    + (rows.length ? `<section class="rep-list">${[...byChannel.values()].map(({ ch, items }) => `<article class="rep" data-cid="${ch?.id}">
      <div class="rep-h">${thumb(ch || {})}<div><b>${ch?.number ? `${ch.number}. ` : ''}${esc(ch?.name || 'قناة محذوفة')}</b><small class="muted">${items.length} بلاغ · آخرها ${ago(items[0].created_at)}</small></div>
        <div class="rep-act">${ch ? `<button class="btn2 ghost sm" data-r="edit">${ic('edit')} فتح القناة</button>${ch.is_published ? `<button class="btn2 ghost sm" data-r="hide">${ic('eyeoff')} إخفاء</button>` : ''}` : ''}${status === 'open' ? `<button class="btn2 primary sm" data-r="resolve">${ic('check')} تم الحل</button>` : ''}<button class="icon2 bad" data-r="del" title="حذف البلاغات">${ic('trash')}</button></div></div>
      <ul>${items.map(r => `<li><span class="chip2 ${r.reason === 'not_working' ? 'bad' : 'warn'}"><i></i>${REASONS[r.reason]}</span>${r.note ? `<p>${esc(r.note)}</p>` : ''}${r.streams?.host ? `<small class="muted" dir="ltr">${esc(r.streams.host)}</small>` : ''}<small class="muted">${date(r.created_at)}</small></li>`).join('')}</ul>
    </article>`).join('')}</section>` : `<div class="panel">${empty('flag', status === 'open' ? 'لا توجد بلاغات مفتوحة' : 'لا توجد بلاغات محلولة', 'عندما يبلّغ المشاهدون عن مشكلة في قناة ستظهر هنا.')}</div>`);
  c.querySelectorAll('[data-rs]').forEach(b => b.onclick = () => { S.reportStatus = b.dataset.rs; go('reports'); });
  c.querySelector('#r-clear').onclick = e => busy(e.currentTarget, async () => { await rpc('admin_cleanup', { p_action: 'clear_reports' }); toast('تم حذف البلاغات المحلولة', 'success'); go('reports'); });
  c.querySelectorAll('.rep').forEach(card => card.addEventListener('click', async e => {
    const b = e.target.closest('[data-r]'); if (!b) return;
    const cid = card.dataset.cid, ids = byChannel.get(cid === 'undefined' ? undefined : cid).items.map(r => r.id);
    if (b.dataset.r === 'edit') editChannel(cid);
    if (b.dataset.r === 'hide' && await busy(b, () => rest(`channels?id=eq.${cid}`, { method: 'PATCH', auth: true, body: { is_published: false, hidden_reason: 'reported' } }))) { b.remove(); toast('تم إخفاء القناة', 'success'); }
    if (b.dataset.r === 'resolve' && await busy(b, () => rest(`reports?id=in.(${ids.join(',')})`, { method: 'PATCH', auth: true, body: { status: 'resolved' } }))) { card.remove(); refreshStats(); }
    if (b.dataset.r === 'del' && await busy(b, () => rest(`reports?id=in.(${ids.join(',')})`, { method: 'DELETE', auth: true }))) { card.remove(); refreshStats(); }
  }));
}

/* ═══════════════════ مصادر البث ═══════════════════ */
async function sources(c) {
  await loadSources();
  c.innerHTML = pageHead('مصادر البث', 'المصدر رابط لقائمة M3U تُستورد منها القنوات وروابطها. التحديث يزامن الروابط، والحذف يزيل روابط المصدر والقنوات التي لم يبقَ لها روابط.',
    S.sources.length ? `<button class="btn2 ghost" id="sync-all">${ic('refresh')} تحديث كل المصادر النشطة</button>` : '')
    + `<section class="panel add-src">
      <form id="sf" class="as-form">
        <div class="panel-h"><h3>${ic('upload')} استيراد مصدر جديد</h3></div>
        <label class="fld"><span>رابط القائمة (M3U)</span><div class="inp">${ic('link')}<input name="url" type="url" required pattern="https://.*" dir="ltr" placeholder="https://iptv-org.github.io/iptv/regions/arab.m3u"></div></label>
        <label class="fld"><span>اسم المصدر</span><div class="inp">${ic('edit')}<input name="name" required maxlength="150" placeholder="مثال: القنوات العربية"></div></label>
        <div class="opts2">
          <label class="row-sw"><div><b>تجاهل روابط http</b><small>لا تعمل على المواقع الآمنة (GitHub Pages)</small></div>${sw(true, 'name="skipHttp"')}</label>
          <label class="row-sw"><div><b>تجاهل المحجوبة جغرافيًا</b><small>القنوات الموسومة Geo-blocked</small></div>${sw(true, 'name="skipGeo"')}</label>
        </div>
        <p class="muted sm">${ic('shield')} القنوات الجديدة تدخل «قيد المراجعة» ولا تظهر للمشاهدين حتى توافق عليها.</p>
        <div class="prog2" hidden><div class="prog2-t"><span></span><b></b></div><div class="prog2-b"><i></i></div><ul class="log"></ul></div>
        <button class="btn2 primary lg">${ic('db')} بدء الاستيراد</button>
      </form>
      <div class="as-sugg"><div class="panel-h"><h3>${ic('zap')} مصادر مقترحة</h3><small>من مستودع iptv-org المفتوح</small></div>
        <div class="sugg2">${SUGGESTED.map(s => { const used = S.sources.some(x => x.url === s.u); return `<button type="button" class="sg" style="--h:${s.h}" data-n="${esc(s.n)}" data-u="${esc(s.u)}" ${used ? 'disabled' : ''}><span class="sg-ic">${ic(s.i)}</span><b>${esc(s.n)}</b><small>${used ? 'مضاف مسبقًا' : esc(s.d)}</small></button>`; }).join('')}</div></div>
    </section>
    <div class="sec-h"><h3>المصادر المحفوظة</h3><em>${num(S.sources.length)}</em><label class="search2 sm">${ic('search')}<input id="src-q" type="search" placeholder="بحث في المصادر…"></label></div>
    ${S.sources.length ? `<section class="src-grid" id="src-grid">${S.sources.map(s => {
      const [tone, label] = STATUS[s.status] || STATUS.pending;
      return `<article class="src-card" data-id="${s.id}" data-name="${esc(s.name.toLowerCase())} ${esc(s.url.toLowerCase())}" style="--h:${hash(s.name) % 360}">
        <header><span class="sc-ic">${ic('link')}</span><div><h4>${esc(s.name)}</h4><button class="url2" data-act="copy" dir="ltr">${ic('copy')}<span>${esc(s.url)}</span></button></div>${chip(tone, label)}</header>
        <div class="sc-stats"><div><small>القنوات</small><b>${num(s.channel_count)}</b></div><div><small>الروابط</small><b>${num(s.stream_count)}</b></div><div><small>آخر تحديث</small><b class="sm">${ago(s.last_import_at)}</b></div></div>
        ${s.last_error ? `<div class="alert2 bad sm">${ic('alert')}<div>${esc(s.last_error)}</div></div>` : ''}
        <div class="sc-sw"><label>${sw(s.is_active, 'data-sw="is_active"')}<span>نشط</span></label></div>
        <footer><button class="btn2 ghost sm" data-act="view">${ic('tv')} القنوات</button><button class="btn2 ghost sm" data-act="refresh">${ic('refresh')} تحديث</button><span class="sp"></span><button class="icon2 bad" data-act="del" title="حذف المصدر">${ic('trash')}</button></footer>
        <div class="sc-prog" hidden><i></i><span></span></div>
      </article>`;
    }).join('')}</section>` : `<div class="panel">${empty('link', 'لا توجد مصادر بعد', 'أضف رابط قائمة M3U أعلاه، أو شغّل ملف 02_data.sql لإضافة مصادر iptv-org لكل الدول.')}</div>`}`;

  const form = c.querySelector('#sf'), el = form.elements, prog = form.querySelector('.prog2'), log = prog.querySelector('.log');
  let last = '';
  const progress = (t, p) => {
    prog.hidden = false; prog.querySelector('span').textContent = t; prog.querySelector('b').textContent = `${Math.round(p)}%`; prog.querySelector('i').style.width = `${p}%`;
    const step = t.replace(/\s*\(.*\)$/, '');
    if (step !== last) { log.querySelector('li:last-child')?.classList.add('done'); log.insertAdjacentHTML('beforeend', `<li>${esc(step)}</li>`); last = step; }
    if (p >= 100) log.querySelector('li:last-child')?.classList.add('done');
  };
  c.querySelectorAll('.sg').forEach(b => b.onclick = () => { c.querySelectorAll('.sg').forEach(x => x.classList.toggle('on', x === b)); el.name.value = b.dataset.n; el.url.value = b.dataset.u; });
  form.onsubmit = e => {
    e.preventDefault();
    const url = el.url.value.trim();
    if (S.sources.some(s => s.url === url)) { toast('هذا الرابط مضاف مسبقًا، استخدم زر «تحديث» في بطاقته.', 'error'); return; }
    log.innerHTML = ''; last = '';
    busy(form.querySelector('.btn2.primary'), async () => {
      const r = await importSource({ name: el.name.value.trim(), url, publish: false, skipHttp: el.skipHttp.checked, skipGeo: el.skipGeo.checked }, progress);
      toast(`تم استيراد ${num(r.total)} رابط (تم تجاهل ${num(r.skipped)})`, 'success');
      await refreshStats(); setTimeout(() => go('sources'), 900);
    }).then(ok => { if (!ok && form.isConnected) prog.querySelector('.prog2-b i').style.background = 'var(--bad)'; });
  };
  c.querySelector('#src-q')?.addEventListener('input', e => { const q = e.target.value.toLowerCase(); c.querySelectorAll('.src-card').forEach(x => { x.hidden = q && !x.dataset.name.includes(q); }); });
  c.querySelector('#sync-all')?.addEventListener('click', async e => {
    const act = S.sources.filter(s => s.is_active);
    if (!await modal({ title: 'تحديث كل المصادر النشطة', icon: 'refresh', ok: 'بدء التحديث', body: `<p>سيُعاد تحميل ${num(act.length)} مصدر واحدًا تلو الآخر. قد يستغرق ذلك عدة دقائق.</p>` })) return;
    busy(e.currentTarget, async () => {
      let i = 0, fails = 0;
      for (const s of act) {
        i++; e.currentTarget && (c.querySelector('#sync-all').textContent = `${i} / ${act.length}`);
        try { await importSource({ id: s.id, url: s.url, publish: s.auto_publish, skipHttp: true, skipGeo: true }, () => {}); } catch { fails++; }
      }
      toast(`اكتمل التحديث${fails ? ` (فشل ${fails})` : ''}`, fails ? 'info' : 'success'); await refreshStats(); go('sources');
    });
  });
  c.querySelectorAll('.src-card').forEach(card => {
    card.addEventListener('change', async e => {
      const k = e.target.dataset.sw; if (!k) return;
      if (!await busy(null, () => rest(`playlist_sources?id=eq.${card.dataset.id}`, { method: 'PATCH', auth: true, body: { [k]: e.target.checked } }))) e.target.checked = !e.target.checked;
    });
    card.addEventListener('click', async e => {
      const b = e.target.closest('[data-act]'); if (!b) return;
      const s = S.sources.find(x => x.id === card.dataset.id), a = b.dataset.act;
      if (a === 'copy') navigator.clipboard?.writeText(s.url).then(() => toast('تم نسخ الرابط', 'success'));
      if (a === 'view') { S.filter = freshFilter('source', s.id); S.page = 0; go('channels'); }
      if (a === 'refresh') {
        const pg = card.querySelector('.sc-prog'); pg.hidden = false;
        await busy(b, async () => {
          const r = await importSource({ id: s.id, url: s.url, publish: s.auto_publish, skipHttp: true, skipGeo: true }, (t, p) => { pg.querySelector('i').style.width = `${p}%`; pg.querySelector('span').textContent = t; });
          toast(`تم التحديث: ${num(r.total)} رابط، وحُذف ${num(r.removed_streams)} رابط قديم`, 'success'); await refreshStats(); go('sources');
        });
        pg.hidden = true;
      }
      if (a === 'del' && await modal({ title: 'حذف مصدر البث', danger: true, ok: 'حذف المصدر', confirmWord: s.stream_count > 50 ? 'حذف' : '',
        body: `<p>سيتم حذف المصدر «<b>${esc(s.name)}</b>» و<b>${num(s.stream_count)} رابط</b> تابع له. القنوات التي لا يبقى لها أي رابط من مصدر آخر ستُحذف أيضًا.</p>` })) {
        card.classList.add('removing');
        const ok = await busy(b, async () => { const r = await rpc('admin_delete_source', { p_source: s.id }); toast(`تم الحذف: ${num(r.streams)} رابط و${num(r.channels)} قناة`, 'success'); await refreshStats(); go('sources'); });
        if (!ok) card.classList.remove('removing');
      }
    });
  });
}

/* ═══════════════════ التقسيمات: الفئات والدول واللغات ═══════════════════ */
async function sections(c) {
  await loadLookups(true);
  const tab = S.secTab || 'categories';
  const counts = {};
  const col = { categories: 'category_slug', countries: 'country_code', languages: 'language_code' }[tab];
  (await restAll(`channels?select=${col}`, { auth: true })).forEach(r => { counts[r[col]] = (counts[r[col]] || 0) + 1; });
  const list = { categories: S.cats, countries: S.countries, languages: S.langs }[tab];
  const key = tab === 'categories' ? 'slug' : 'code';
  const onlyUsed = S.secUsed ?? (tab !== 'categories');
  const shown = list.filter(x => !onlyUsed || counts[x[key]]);
  c.innerHTML = pageHead('التقسيمات', 'تحكّم في أسماء وترتيب وظهور الفئات والدول واللغات كما تظهر للمشاهدين. إخفاء تقسيم يخفيه من صفحات التصفح فقط.',
    tab === 'categories' ? `<button class="btn2 primary" id="add-cat">${ic('plus')} فئة جديدة</button>` : '')
    + `<div class="seg"><button data-st="categories" class="${tab === 'categories' ? 'on' : ''}">${ic('grid')} الفئات <em>${S.cats.length}</em></button><button data-st="countries" class="${tab === 'countries' ? 'on' : ''}">${ic('globe')} الدول <em>${S.countries.length}</em></button><button data-st="languages" class="${tab === 'languages' ? 'on' : ''}">${ic('lang')} اللغات <em>${S.langs.length}</em></button></div>
    <div class="filters"><label class="search2">${ic('search')}<input id="sec-q" type="search" placeholder="بحث…"></label>
      <label class="row-sw slim"><div><b>المستخدمة فقط</b></div>${sw(onlyUsed, 'id="sec-used"')}</label></div>
    <div class="panel tbl-panel"><div class="tbl-scroll"><table class="tbl2 sec-t"><thead><tr>
      ${tab === 'categories' ? '<th>الأيقونة</th><th>المعرّف</th>' : tab === 'countries' ? '<th>العلم</th><th>الرمز</th>' : '<th>الرمز</th>'}
      <th>الاسم بالعربية</th><th>الاسم بالإنجليزية</th>${tab === 'categories' ? '<th>اللون</th>' : ''}${tab === 'countries' ? '<th>عربية</th>' : ''}<th>الترتيب</th><th>القنوات</th><th>ظاهر</th><th></th></tr></thead>
      <tbody>${shown.map(x => `<tr data-k="${esc(x[key])}" data-s="${esc(`${x[key]} ${x.name_ar} ${x.name_en}`.toLowerCase())}">
        ${tab === 'categories' ? `<td><select class="ic-sel" data-e="icon">${ICONS.map(i => `<option ${x.icon === i ? 'selected' : ''}>${i}</option>`).join('')}</select><span class="ic-prev" style="--h:${x.hue}">${ic(x.icon)}</span></td><td><code>${esc(x.slug)}</code></td>`
          : tab === 'countries' ? `<td>${flag(x.flag_url)}</td><td><code>${esc(x.code)}</code></td>` : `<td><code>${esc(x.code)}</code></td>`}
        <td><input class="cell" data-e="name_ar" value="${esc(x.name_ar)}"></td>
        <td><input class="cell" data-e="name_en" dir="ltr" value="${esc(x.name_en)}"></td>
        ${tab === 'categories' ? `<td><input class="cell hue" type="range" min="0" max="360" data-e="hue" value="${x.hue}" style="--h:${x.hue}"></td>` : ''}
        ${tab === 'countries' ? `<td>${sw(x.is_arab, 'data-e="is_arab"')}</td>` : ''}
        <td><input class="cell num" type="number" data-e="sort_order" value="${x.sort_order}"></td>
        <td><button class="link2" data-view="${esc(x[key])}">${num(counts[x[key]] || 0)}</button></td>
        <td>${sw(x.is_visible, 'data-e="is_visible"')}</td>
        <td class="acts2">${tab === 'categories' && !counts[x[key]] && x.slug !== 'general' ? `<button class="icon2 bad" data-del title="حذف">${ic('trash')}</button>` : ''}</td>
      </tr>`).join('')}</tbody></table></div></div>`;

  c.querySelectorAll('[data-st]').forEach(b => b.onclick = () => { S.secTab = b.dataset.st; S.secUsed = undefined; go('sections'); });
  c.querySelector('#sec-used').onchange = e => { S.secUsed = e.target.checked; go('sections'); };
  c.querySelector('#sec-q').oninput = e => { const q = e.target.value.toLowerCase(); c.querySelectorAll('tbody tr').forEach(r => { r.hidden = q && !r.dataset.s.includes(q); }); };
  const save = async (row, field, value) => {
    const ok = await busy(null, () => rest(`${tab}?${key}=eq.${enc(row.dataset.k)}`, { method: 'PATCH', auth: true, body: { [field]: value } }));
    if (ok) { row.classList.add('saved'); setTimeout(() => row.classList.remove('saved'), 900); }
  };
  c.querySelector('tbody').addEventListener('change', e => {
    const el = e.target, row = el.closest('tr'), f = el.dataset.e; if (!f) return;
    const val = el.type === 'checkbox' ? el.checked : el.type === 'number' || el.type === 'range' ? +el.value : el.value.trim();
    if (f === 'icon') row.querySelector('.ic-prev').innerHTML = ic(val);
    if (f === 'hue') { row.querySelector('.ic-prev').style.setProperty('--h', val); el.style.setProperty('--h', val); }
    save(row, f, val);
  });
  c.querySelector('tbody').addEventListener('click', async e => {
    const v = e.target.closest('[data-view]');
    if (v) { S.filter = freshFilter({ categories: 'category', countries: 'country', languages: 'language' }[tab], v.dataset.view); S.page = 0; go('channels'); }
    const d = e.target.closest('[data-del]');
    if (d && await modal({ title: 'حذف الفئة', danger: true, ok: 'حذف', body: '<p>هذه الفئة لا تحتوي على قنوات. هل تريد حذفها؟</p>' })) {
      const row = d.closest('tr');
      if (await busy(d, () => rest(`categories?slug=eq.${enc(row.dataset.k)}`, { method: 'DELETE', auth: true }))) row.remove();
    }
  });
  c.querySelector('#add-cat')?.addEventListener('click', async () => {
    const f = await modal({ title: 'فئة جديدة', icon: 'grid', ok: 'إضافة', body: `<label class="fld"><span>المعرّف (إنجليزي بدون مسافات)</span><input name="slug" required pattern="[a-z0-9-]+" dir="ltr" placeholder="ramadan"></label>
      <label class="fld"><span>الاسم بالعربية</span><input name="name_ar" required></label><label class="fld"><span>الاسم بالإنجليزية</span><input name="name_en" required dir="ltr"></label>` });
    if (!f) return;
    busy(null, async () => { await rest('categories', { method: 'POST', auth: true, prefer: 'return=minimal', body: { slug: f.get('slug').trim().toLowerCase(), name_ar: f.get('name_ar').trim(), name_en: f.get('name_en').trim(), sort_order: S.cats.length + 1 } }); toast('تمت إضافة الفئة', 'success'); go('sections'); });
  });
}

/* ═══════════════════ الإعداد والصيانة ═══════════════════ */
async function maintenance(c) {
  const t0 = performance.now();
  const st = await refreshStats();
  const ping = Math.round(performance.now() - t0);
  const step = (done, title, text) => `<li class="${done ? 'done' : ''}"><span class="st-ic">${ic(done ? 'check' : 'info')}</span><div><b>${title}</b><small>${text}</small></div></li>`;
  c.innerHTML = pageHead('النسخ الاحتياطي والصيانة', 'حالة الاتصال بقاعدة البيانات، النسخ الاحتياطي والاستعادة ونسخة الديمو، وأدوات الحذف الشامل.')
    + `<section class="status-grid">
      ${statusCard('db', 'قاعدة البيانات', `متصلة · ${ping} ms`, 'ok')}
      ${statusCard('grid', 'مخطط الجداول', 'الإصدار 2 (القنوات + الروابط)', 'ok')}
      ${statusCard('user', 'الحساب', getSession()?.user?.email || '—', 'ok', true)}
      ${statusCard('globe', 'المشروع', new URL(window.MTC_CONFIG.supabaseUrl).hostname.split('.')[0], 'ok', true)}
    </section>
    <section class="panel"><div class="panel-h"><h3>${ic('check')} قائمة التحقق</h3></div><ul class="checklist">
      ${step(st.sources > 0, 'إضافة مصادر البث', `${num(st.sources)} مصدر محفوظ.`)}
      ${step(!st.pending, 'مراجعة القنوات الجديدة', st.pending ? `${num(st.pending)} قناة بانتظار المراجعة — افتح «قيد المراجعة».` : 'لا توجد قنوات معلّقة.')}
      ${step(st.published > 0, 'نشر القنوات', `${num(st.published)} قناة ظاهرة للمشاهدين.`)}
      ${step(st.streams && !st.unchecked, 'فحص كل الروابط', st.unchecked ? `${num(st.unchecked)} رابط لم يُفحص — افتح «فحص الروابط».` : 'كل الروابط مفحوصة.')}
      ${step(!st.offline, 'تنظيف الروابط المعطّلة', st.offline ? `${num(st.offline)} رابط معطّل.` : 'لا توجد روابط معطّلة.')}
      ${step(!st.duplicates, 'معالجة القنوات المكررة', st.duplicates ? `${num(st.duplicates)} مجموعة مكررة.` : 'لا توجد مكررات.')}
      ${step(st.featured > 0, 'تمييز قنوات للرئيسية', `${num(st.featured)} قناة مميزة.`)}
      ${step(false, 'إيقاف التسجيل العام (يدوي)', 'Supabase ← Authentication ← عطّل «Allow new users to sign up».')}
    </ul></section>
    ${backupSection(st)}
    <div class="sec-h danger"><h3>${ic('alert')} منطقة الحذف</h3><small>جميع العمليات نهائية ولا يمكن التراجع عنها</small></div>
    <section class="dz-grid">
      ${dz('delete_pending', 'shield', 'حذف القنوات المعلّقة', 'كل القنوات بانتظار المراجعة مع روابطها', st.pending)}
      ${dz('delete_hidden', 'eyeoff', 'حذف القنوات المخفية', 'القنوات غير المنشورة (ومنها المعلّقة) مع روابطها', st.hidden)}
      ${dz('delete_manual', 'edit', 'حذف القنوات اليدوية', 'القنوات المضافة بدون مصدر', st.manual)}
      ${dz('delete_all_channels', 'tv', 'حذف جميع القنوات', 'كل القنوات والروابط مع الإبقاء على المصادر', st.channels)}
      ${dz('reset_all', 'trash', 'تصفير كامل', `كل القنوات (${num(st.channels)}) والروابط (${num(st.streams)}) والمصادر (${num(st.sources)}) والبلاغات`, st.channels + st.sources, true)}
    </section>`;
  bindBackup(c);
  c.querySelectorAll('[data-dz]').forEach(b => b.onclick = async () => {
    const card = b.closest('.dz2');
    if (!await modal({ title: card.querySelector('b').textContent, danger: true, ok: 'تنفيذ الحذف', confirmWord: 'حذف',
      body: `<p>سيتم حذف: <b>${card.querySelector('small').textContent}</b> (${card.querySelector('em').textContent}).</p><p class="warn-t">${ic('alert')} هذه العملية نهائية.</p>` })) return;
    await busy(b, async () => { const n = await rpc('admin_cleanup', { p_action: b.dataset.dz }); toast(`تم الحذف (${num(n)})`, 'success'); S.sources = []; go('maintenance'); });
  });
}
const statusCard = (i, title, value, tone, ltr) => `<div class="stc ${tone}"><span class="stc-ic">${ic(i)}</span><div><small>${title}</small><b ${ltr ? 'dir="ltr"' : ''}>${esc(value)}</b></div><i class="stc-dot"></i></div>`;
const dz = (k, i, title, text, n, strong) => `<div class="dz2 ${strong ? 'strong' : ''}"><span class="dz-ic">${ic(i)}</span><div><b>${title}</b><small>${text}</small></div><em>${num(n)}</em><button class="btn2 ${strong ? 'danger' : 'danger-ghost'} sm" data-dz="${k}" ${n ? '' : 'disabled'}>${ic('trash')} حذف</button></div>`;

/* ═══════════════════ الإقلاع ═══════════════════ */
// أزرار الرجوع/التقدّم في المتصفح وتغيير # في العنوان
addEventListener('hashchange', () => { const t = location.hash.slice(1); if (app.classList.contains('shell') && t && t !== S.tab) go(t); });
(async () => {
  app.innerHTML = '<div class="loading2 full"><i class="spin"></i></div>';
  if (getSession() && await isAdmin()) renderShell();
  else renderLogin();
})();
