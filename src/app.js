// ════════════════════════════════════════════════════════════════════════════
// MTC-iPTv — واجهة المشاهدة (قراءة فقط): تصفّح القنوات المنشورة ومشاهدتها كأنك أمام التلفاز.
// المصدر: الواجهتان catalog و catalog_streams في Supabase.
// ════════════════════════════════════════════════════════════════════════════
import { rest, restAll, configured } from './supabase.js';
import { createPlayer } from './player.js';
import { ic, logo } from './icons.js';
import { hash, familyKeys } from './catalog.js';
import { VERSION, RELEASE_DATE, COMPANY, DEVELOPER } from './version.js';
import { socialLinks, socialIcon } from './social.js';
import { initInstall, openInstall } from './install.js';

const $ = s => document.querySelector(s);
const M = $('#main');
const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const safeImg = u => (/^https:\/\//i.test(u || '') ? u : '');
const norm = s => String(s ?? '').toLowerCase().replace(/[ً-ْ]/g, '').replace(/[أإآ]/g, 'ا').replace(/ة/g, 'ه').replace(/ى/g, 'ي');
const fmt = n => (n ?? 0).toLocaleString('ar');
const enc = encodeURIComponent;

/* ───────── الحالة والتخزين المحلي ───────── */
const S = { ch: [], byId: new Map(), byNum: new Map(), cats: new Map(), countries: [], settings: {}, q: '', lastList: null };
const store = {
  get(k, d) { try { return JSON.parse(localStorage.getItem(k)) ?? d; } catch { return d; } },
  set(k, v) { try { localStorage.setItem(k, JSON.stringify(v)); } catch { /* ignore */ } }
};
const favs = new Set(store.get('mtc-favs', []));
const isFav = id => favs.has(id);
const toggleFav = id => { favs.has(id) ? favs.delete(id) : favs.add(id); store.set('mtc-favs', [...favs]); return favs.has(id); };
const recent = () => store.get('mtc-recent', []).map(id => S.byId.get(id)).filter(Boolean);
const addRecent = id => store.set('mtc-recent', [id, ...store.get('mtc-recent', []).filter(x => x !== id)].slice(0, 24));
const prefs = Object.assign({ group: 'country', sort: 'number', view: 'grid' }, store.get('mtc-browse', {}));

/* ───────── التجميع والترتيب ───────── */
const CONTINENTS = { africa: 'أفريقيا', americas: 'الأمريكتان', asia: 'آسيا', europe: 'أوروبا', oceania: 'أوقيانوسيا', other: 'أقاليم أخرى' };
const GROUPS = {
  country: { label: 'الدولة', icon: 'globe', key: c => c.country_code || '—', name: c => c.country_name || 'دولية', route: 'country' },
  category: { label: 'الفئة', icon: 'grid', key: c => c.category_slug || '—', name: c => c.category_name || 'عامة', route: 'category' },
  language: { label: 'اللغة', icon: 'lang', key: c => c.language_code || '—', name: c => c.language_name || 'غير محددة', route: 'language' },
  server: { label: 'السيرفر', icon: 'server', key: c => c.server || '—', name: c => c.server || 'غير معروف', route: 'server' },
  network: { label: 'الشبكة', icon: 'tv', key: c => c.network || '—', name: c => c.network || 'بدون شبكة', route: 'network' }
};
const SORTS = {
  number: { label: 'رقم القناة', fn: (a, b) => a.number - b.number },
  name: { label: 'الاسم', fn: (a, b) => a.name.localeCompare(b.name) },
  country: { label: 'الدولة', fn: (a, b) => (b.is_arab - a.is_arab) || String(a.country_name).localeCompare(String(b.country_name), 'ar') || a.number - b.number }
};
const sorted = (list, sort = prefs.sort) => [...list].sort((SORTS[sort] || SORTS.number).fn);
function groupBy(list, g) {
  const G = GROUPS[g], m = new Map();
  for (const c of list) { const k = G.key(c); if (!m.has(k)) m.set(k, { key: k, name: G.name(c), flag: g === 'country' ? c.flag_url : '', items: [] }); m.get(k).items.push(c); }
  const first = x => Math.min(...x.items.map(c => c.number));
  // الدول بترتيب الأرقام (العربية أولًا كما في قاعدة البيانات)، وبقية التجميعات حسب عدد القنوات
  return [...m.values()].sort((a, b) => g === 'country' ? first(a) - first(b) : b.items.length - a.items.length);
}

/* ───────── البطاقات ───────── */
const thumb = c => {
  const img = safeImg(c.logo_url);
  return `<div class="thumb" style="--h:${hash(c.name) % 360}">${img ? `<img src="${esc(img)}" alt="" loading="lazy" referrerpolicy="no-referrer">` : ''}<span class="init">${esc([...c.name][0] || '•')}</span><em class="badge-live">مباشر</em>${c.quality ? `<em class="badge-q">${esc(c.quality)}</em>` : ''}<em class="badge-num">${c.number}</em></div>`;
};
const flagImg = (url, cls = 'flag') => url ? `<img class="${cls}" src="${esc(url)}" alt="" loading="lazy">` : '';
const card = c => `<a class="card" href="#/watch/${c.id}" data-id="${c.id}" title="${esc(c.name)}">${thumb(c)}<b>${esc(c.name)}</b><small>${flagImg(c.flag_url)}${esc([c.country_name, c.category_name].filter(Boolean).join(' · '))}</small></a>`;
const lrow = c => `<a class="lrow" href="#/watch/${c.id}" data-id="${c.id}"><span class="num">${c.number}</span><span class="lr-logo">${safeImg(c.logo_url) ? `<img src="${esc(c.logo_url)}" alt="" loading="lazy" referrerpolicy="no-referrer">` : esc([...c.name][0])}</span><span class="lr-t"><b>${esc(c.name)}</b><small>${esc([c.category_name, c.language_name].filter(Boolean).join(' · '))}</small></span><span class="lr-c">${flagImg(c.flag_url)}${esc(c.country_name || '')}</span>${c.quality ? `<em class="q">${esc(c.quality)}</em>` : ''}</a>`;

const row = (title, list, more, icon = '', cls = '') => list.length ? `<section class="row ${cls}">
  <div class="row-h"><h2>${icon}${esc(title)}</h2>${more ? `<a href="${more}">عرض الكل ${ic('next')}</a>` : ''}</div>
  <div class="rail-wrap"><button class="rail-btn prev" aria-label="السابق">${ic('back')}</button><div class="rail">${list.map(card).join('')}</div><button class="rail-btn nxt" aria-label="التالي">${ic('next')}</button></div>
</section>` : '';

/** شبكة/قائمة تُرسم تدريجيًا لتبقى سريعة مع آلاف القنوات */
function paint(list, host, view = prefs.view) {
  if (!list.length) { host.innerHTML = '<p class="empty">لا توجد قنوات مطابقة.</p>'; return; }
  host.innerHTML = `<div class="${view === 'list' ? 'llist' : 'grid'}"></div><div class="more"></div>`;
  const g = host.firstElementChild, more = host.lastElementChild, step = view === 'list' ? 80 : 60;
  let i = 0;
  const page = () => { g.insertAdjacentHTML('beforeend', list.slice(i, i + step).map(view === 'list' ? lrow : card).join('')); i += step; if (i >= list.length) io.disconnect(); };
  const io = new IntersectionObserver(e => { if (e[0].isIntersecting) page(); }, { rootMargin: '800px' });
  page();
  if (i < list.length) io.observe(more);
}
const remember = (label, list) => { S.lastList = { label, ids: list.map(c => c.id) }; };

/* ───────── الرئيسية ───────── */
function hero(c) {
  const img = safeImg(c.logo_url);
  return `<section class="hero" style="--h:${hash(c.name) % 360}">
    ${img ? `<div class="hero-bg" style="background-image:url('${esc(img)}')"></div>` : '<div class="hero-bg"></div>'}
    <div class="hero-in">
      <span class="kicker"><i class="dot"></i> يُعرض الآن مباشرة · القناة ${c.number}</span>
      <h1>${esc(c.name)}</h1>
      <p class="meta">${flagImg(c.flag_url)}${[c.country_name, c.category_name, c.language_name, c.quality].filter(Boolean).map(esc).join('<i>•</i>')}</p>
      <div class="hero-act">
        <a class="btn btn-light" href="#/watch/${c.id}">${ic('play')} شاهد الآن</a>
        <button class="btn btn-glass" data-fav="${c.id}">${ic('heart')} <span>${isFav(c.id) ? 'في المفضلة' : 'أضف للمفضلة'}</span></button>
      </div>
    </div>
    ${img ? `<div class="hero-logo"><img src="${esc(img)}" alt="" referrerpolicy="no-referrer"></div>` : ''}
  </section>`;
}
const emptyHero = () => `<section class="hero hero-empty"><div class="hero-in">
  <span class="kicker">${ic('live')} بث مباشر</span><h1>كل قنواتك المفضّلة<br>في مكان واحد</h1>
  <p>نعمل على تجهيز مكتبة القنوات. عد قريبًا لمشاهدة البث المباشر من حول العالم — ومكتبة الأفلام والمسلسلات قادمة.</p></div></section>`;

function home() {
  if (!S.ch.length) { M.innerHTML = emptyHero(); return; }
  // «يعرض الآن»: القناة التي اختارها المدير من لوحة التحكم، وإلا قناة مميزة عشوائية
  const chosen = S.byId.get(S.settings.hero?.channel_id);
  const featured = S.ch.filter(c => c.is_featured);
  const pool = featured.length ? featured : S.ch.filter(c => safeImg(c.logo_url)).slice(0, 40);
  const pick = chosen || pool[Math.floor(Math.random() * pool.length)] || S.ch[0];
  const cats = groupBy(S.ch, 'category');
  const arab = groupBy(S.ch.filter(c => c.is_arab), 'country').slice(0, 5);
  const langs = groupBy(S.ch.filter(c => c.language_code && c.language_code !== 'ara'), 'language').slice(0, 2);
  const countries = groupBy(S.ch, 'country').filter(g => g.flag).slice(0, 24);
  remember('كل القنوات', sorted(S.ch, 'number'));
  M.innerHTML = hero(pick) + '<div class="rows">'
    + row('مضافة حديثًا', S.fresh || [], '', ic('plus'), 'fresh')
    + row('تابع المشاهدة', recent(), '', ic('refresh'))
    + row('قائمتي المفضلة', S.ch.filter(c => isFav(c.id)), '#/favorites', ic('heart'))
    + row('قنوات مميزة', featured.slice(0, 30), '', ic('star'))
    + cats.slice(0, 3).map(g => row(g.name, g.items.slice(0, 30), `#/category/${enc(g.key)}`)).join('')
    + arab.map(g => row(`من ${g.name}`, sorted(g.items).slice(0, 30), `#/country/${enc(g.key)}`)).join('')
    + `<section class="row"><div class="row-h"><h2>${ic('globe')}تصفّح حسب الدولة</h2><a href="#/countries">كل الدول ${ic('next')}</a></div>
       <div class="rail flags">${countries.map(g => `<a class="ftile" href="#/country/${enc(g.key)}">${flagImg(g.flag)}<b>${esc(g.name)}</b><small>${fmt(g.items.length)}</small></a>`).join('')}</div></section>`
    + cats.slice(3, 10).map(g => row(g.name, g.items.slice(0, 30), `#/category/${enc(g.key)}`)).join('')
    + langs.map(g => row(`باللغة ${g.name}`, g.items.slice(0, 30), `#/language/${enc(g.key)}`)).join('')
    + '</div>';
}

/* ───────── صفحة القوائم مع أدوات التجميع والترتيب ───────── */
function toolbar({ group = true } = {}) {
  return `<div class="tools">
    ${group ? `<label class="tsel">${ic('layers')}<span>تجميع</span><select data-pref="group"><option value="">بدون</option>${Object.entries(GROUPS).map(([k, g]) => `<option value="${k}" ${prefs.group === k ? 'selected' : ''}>${g.label}</option>`).join('')}</select></label>` : ''}
    <label class="tsel">${ic('sort')}<span>ترتيب</span><select data-pref="sort">${Object.entries(SORTS).map(([k, s]) => `<option value="${k}" ${prefs.sort === k ? 'selected' : ''}>${s.label}</option>`).join('')}</select></label>
    <div class="vtoggle"><button data-view="grid" class="${prefs.view === 'grid' ? 'on' : ''}" title="شبكة">${ic('grid')}</button><button data-view="list" class="${prefs.view === 'list' ? 'on' : ''}" title="قائمة (مثل دليل التلفاز)">${ic('list')}</button></div>
  </div>`;
}
function bindToolbar(rerender) {
  M.querySelectorAll('[data-pref]').forEach(s => s.onchange = () => { prefs[s.dataset.pref] = s.value; store.set('mtc-browse', prefs); rerender(); });
  M.querySelectorAll('[data-view]').forEach(b => b.onclick = () => { prefs.view = b.dataset.view; store.set('mtc-browse', prefs); rerender(); });
}

function listPage(title, sub, list, { icon = '', grouping = false, chips = 'category' } = {}) {
  const render = () => {
    const all = sorted(list);
    remember(title, all);
    const chipGroups = chips ? groupBy(list, chips) : [];
    M.innerHTML = `<div class="page"><div class="page-h"><div><h1>${icon}${title}</h1><p>${sub} · ${fmt(list.length)} قناة</p></div>
      <div class="ph-act">${list.length ? `<a class="btn btn-ac" href="#/watch/${all[0].id}">${ic('play')} تشغيل من البداية</a>` : ''}</div></div>
      ${toolbar({ group: grouping })}
      ${chipGroups.length > 1 ? `<div class="chips"><button class="chip on" data-k="">الكل</button>${chipGroups.map(g => `<button class="chip" data-k="${esc(g.key)}">${esc(g.name)} <em>${fmt(g.items.length)}</em></button>`).join('')}</div>` : ''}
      <div id="list"></div></div>`;
    const host = $('#list');
    const draw = items => {
      if (grouping && prefs.group) {
        const gs = groupBy(items, prefs.group), G = GROUPS[prefs.group];
        host.innerHTML = gs.map((g, i) => `<section class="gsec"><header>${g.flag ? flagImg(g.flag) : ic(G.icon)}<h2>${esc(g.name)}</h2><em>${fmt(g.items.length)}</em>
          ${g.key !== '—' ? `<a href="#/${G.route}/${enc(g.key)}">عرض الكل ${ic('next')}</a>` : ''}</header><div data-g="${i}"></div></section>`).join('');
        gs.forEach((g, i) => paint(sorted(g.items).slice(0, prefs.view === 'list' ? 12 : 14), host.querySelector(`[data-g="${i}"]`)));
      } else paint(sorted(items), host);
    };
    draw(list);
    M.querySelectorAll('.chip').forEach(b => b.onclick = () => {
      M.querySelectorAll('.chip').forEach(x => x.classList.toggle('on', x === b));
      const items = b.dataset.k ? list.filter(c => GROUPS[chips].key(c) === b.dataset.k) : list;
      remember(title, sorted(items)); draw(items);
    });
    bindToolbar(render);
  };
  render();
}

function tilesPage(kind) {
  const conf = {
    countries: { title: 'تصفّح حسب الدولة', sub: 'قنوات من كل دول العالم', g: 'country' },
    categories: { title: 'تصفّح حسب الفئة', sub: 'أخبار، رياضة، أفلام، أطفال والمزيد', g: 'category' },
    languages: { title: 'تصفّح حسب اللغة', sub: 'اختر لغة البث', g: 'language' },
    servers: { title: 'تصفّح حسب السيرفر', sub: 'الخوادم التي تبث منها القنوات', g: 'server' }
  }[kind];
  const G = GROUPS[conf.g];
  let groups = groupBy(S.ch, conf.g).filter(g => g.key !== '—');
  if (kind === 'countries' && S.countries.length) {
    const have = new Map(groups.map(g => [g.key, g]));
    groups = S.countries.map(co => ({ key: co.code, name: co.name_ar, flag: co.flag_url, is_arab: co.is_arab, continent: co.continent || 'other', items: have.get(co.code)?.items || [] }))
      .sort((a, b) => (b.items.length > 0) - (a.items.length > 0) || (b.is_arab - a.is_arab) || (a.is_arab ? 0 : a.name.localeCompare(b.name, 'ar')));
  }
  const tile = g => {
    const cat = S.cats.get(g.key);
    const visual = g.flag ? flagImg(g.flag, 'tflag') : cat ? `<span class="tile-ic">${ic(cat.icon)}</span>` : `<span class="tile-i">${esc([...g.name][0])}</span>`;
    return `<a class="tile${g.items.length ? '' : ' tile-zero'}" href="#/${G.route}/${enc(g.key)}" style="--h:${cat?.hue ?? hash(g.key) % 360}">${visual}<b>${esc(g.name)}</b><small>${fmt(g.items.length)} قناة</small></a>`;
  };
  let body;
  if (kind === 'countries') {
    const sections = [['arab', 'الدول العربية', groups.filter(g => g.is_arab ?? g.items[0].is_arab)],
      ...Object.entries(CONTINENTS).map(([k, n]) => [k, n, groups.filter(g => !(g.is_arab ?? g.items[0].is_arab) && (g.continent ?? g.items[0].continent ?? 'other') === k)])];
    body = sections.filter(s => s[2].length).map(([, n, gs]) => `<section class="tsec"><h2>${esc(n)} <em>${fmt(gs.length)}</em></h2><div class="tiles">${gs.map(tile).join('')}</div></section>`).join('');
  } else body = `<div class="tiles">${groups.map(tile).join('')}</div>`;
  M.innerHTML = `<div class="page"><div class="page-h"><div><h1>${ic(G.icon)}${conf.title}</h1><p>${conf.sub}</p></div></div>${groups.length ? body : '<p class="empty">لا توجد قنوات بعد.</p>'}</div>`;
}

function search() {
  const raw = S.q.trim(), n = norm(raw);
  const list = n ? S.ch.filter(c => String(c.number) === raw || norm(`${c.name} ${c.country_name} ${c.category_name} ${c.language_name} ${c.network || ''}`).includes(n)) : [];
  if (n) remember(`بحث: ${raw}`, list);
  M.innerHTML = `<div class="page"><div class="page-h"><div><h1>${n ? `نتائج «${esc(raw)}»` : 'ابحث عن قناة'}</h1>
    <p>${n ? `${fmt(list.length)} نتيجة` : 'اكتب اسم القناة أو رقمها أو الدولة أو الفئة أو اللغة.'}</p></div></div>
    <label class="search search-lg"><span>${ic('search')}</span><input id="q2" type="search" placeholder="ابحث عن قناة أو رقم أو دولة…" value="${esc(S.q)}" autocomplete="off"></label>
    <div id="list"></div></div>`;
  if (n) paint(sorted(list), $('#list'));
  const q2 = $('#q2');
  q2.oninput = () => { S.q = q2.value; $('#q').value = q2.value; debounceSearch(); };
  q2.focus(); q2.setSelectionRange(q2.value.length, q2.value.length);
}
let st = 0;
const debounceSearch = () => { clearTimeout(st); st = setTimeout(() => { if (view === 'search') { const y = scrollY; search(); scrollTo(0, y); } else location.hash = '#/search'; }, 220); };

const soon = kind => {
  M.innerHTML = `<section class="hero hero-empty"><div class="hero-in"><span class="kicker">${ic(kind === 'movies' ? 'film' : 'tv')} قريبًا</span>
    <h1>${kind === 'movies' ? 'مكتبة الأفلام' : 'مكتبة المسلسلات'}<br>قادمة قريبًا</h1>
    <p>نعمل على إضافة مكتبة ${kind === 'movies' ? 'أفلام' : 'مسلسلات'} متكاملة. في الأثناء استمتع بالبث المباشر.</p>
    <div class="hero-act"><a class="btn btn-light" href="#/live">${ic('live')} شاهد البث المباشر</a></div></div></section>`;
};

/* ═══════════════ المشاهدة: وضع التلفاز ═══════════════ */
const W = { active: false, player: null, id: null, prevId: null, list: [], mode: 'ctx', sort: 'number', tab: 'family', theater: store.get('mtc-theater', false), digits: '', digitT: 0, streams: [] };
const GUIDE_MODES = { ctx: 'القائمة الحالية', all: 'كل القنوات', country: 'نفس الدولة', category: 'نفس الفئة', language: 'نفس اللغة', server: 'نفس السيرفر', family: 'نفس العائلة', favs: 'المفضلة' };

function familyOf(c) {
  const keys = new Set(familyKeys(c));
  return keys.size ? S.ch.filter(x => familyKeys(x).some(k => keys.has(k))) : [c];
}
const guideList = c => listFor(W.mode, c);
function listFor(mode, c) {
  let list;
  switch (mode) {
    case 'ctx': list = (S.lastList?.ids || []).map(id => S.byId.get(id)).filter(Boolean); if (!list.some(x => x.id === c.id)) list = S.ch; return W.sort === 'number' && S.lastList ? list : sorted(list, W.sort);
    case 'all': list = S.ch; break;
    case 'family': list = familyOf(c); break;
    case 'favs': list = S.ch.filter(x => isFav(x.id)); if (!list.length) list = [c]; break;
    default: { const G = GROUPS[mode]; list = S.ch.filter(x => G.key(x) === G.key(c)); }
  }
  return sorted(list, W.sort);
}

function buildWatch() {
  M.innerHTML = `<div class="tv ${W.theater ? 'theater' : ''}" id="tv">
    <div class="tv-main">
      <div class="stage"><div id="pl"></div></div>
      <div class="tv-info" id="tv-info"></div>
    </div>
    <aside class="tv-side" id="tv-side">
      <div class="ts-tabs"><button data-tab="family">${ic('layers')} <span>من نفس العائلة</span> <em id="fam-n"></em></button><button data-tab="guide">${ic('list')} <span>دليل القنوات</span></button></div>
      <div class="ts-pane" data-pane="family"><div class="ts-list" id="fam-list"></div></div>
      <div class="ts-pane" data-pane="guide">
        <div class="ts-tools">
          <label class="tsel sm">${ic('layers')}<select id="g-mode">${Object.entries(GUIDE_MODES).map(([k, v]) => `<option value="${k}">${v}</option>`).join('')}</select></label>
          <label class="tsel sm">${ic('sort')}<select id="g-sort">${Object.entries(SORTS).map(([k, s]) => `<option value="${k}">${s.label}</option>`).join('')}</select></label>
          <em id="g-count"></em>
        </div>
        <div class="ts-list" id="g-list"></div>
      </div>
      <p class="ts-hint">${ic('info')} PageUp / PageDown للتنقل · اكتب رقم القناة · Backspace للقناة السابقة · G لإخفاء الدليل</p>
    </aside>
  </div>`;
  W.player = createPlayer($('#pl'), {
    onNext: () => zap(1), onPrev: () => zap(-1), onTheater: toggleTheater, onDigit: digit,
    onReport: s => report(S.byId.get(W.id), s),
    // قائمة القنوات داخل المشغّل في ملء الشاشة (من اليسار) — نفس منطق دليل القنوات
    channels: {
      modes: [['ctx', 'القائمة الحالية'], ['family', 'نفس العائلة'], ['country', 'نفس الدولة'], ['category', 'نفس الفئة'], ['favs', 'المفضلة'], ['all', 'كل القنوات']],
      list: mode => listFor(mode, S.byId.get(W.id)).map(x => ({ id: x.id, number: x.number, name: x.name, logo: safeImg(x.logo_url), sub: [x.country_name, x.category_name].filter(Boolean).join(' · ') })),
      current: () => W.id,
      pick: id => open(id)
    },
    onKey: e => {
      if (e.key.toLowerCase() === 'g') { $('#tv').classList.toggle('noside'); return true; }
      if (e.key === 'Backspace' && W.prevId) { open(W.prevId); return true; }
      return false;
    }
  });
  W.player.setTheater(W.theater);
  W.active = true;
  $('#g-mode').value = W.mode = S.lastList ? 'ctx' : 'country';
  $('#g-sort').value = W.sort;
  $('#g-mode').onchange = e => { W.mode = e.target.value; drawGuide(); };
  $('#g-sort').onchange = e => { W.sort = e.target.value; drawGuide(); };
  M.querySelectorAll('[data-tab]').forEach(b => b.onclick = () => setTab(b.dataset.tab));
}
const setTab = t => { W.tab = t; M.querySelectorAll('[data-tab]').forEach(b => b.classList.toggle('on', b.dataset.tab === t)); M.querySelectorAll('[data-pane]').forEach(p => { p.hidden = p.dataset.pane !== t; }); if (t === 'guide') scrollToActive('#g-list'); };
const sideRow = (x, active) => `<a class="g-row ${active ? 'on' : ''}" href="#/watch/${x.id}" data-open="${x.id}"><span class="num">${x.number}</span><span class="lr-logo">${safeImg(x.logo_url) ? `<img src="${esc(x.logo_url)}" alt="" loading="lazy" referrerpolicy="no-referrer">` : esc([...x.name][0])}</span><span class="lr-t"><b>${esc(x.name)}</b><small>${flagImg(x.flag_url)}${esc([x.country_name, x.category_name].filter(Boolean).join(' · '))}</small></span>${active ? `<i class="eq"><b></b><b></b><b></b></i>` : x.quality ? `<em class="q">${esc(x.quality)}</em>` : ''}</a>`;
function scrollToActive(sel) { // داخل القائمة فقط دون تحريك الصفحة
  const list = $(sel), el = list?.querySelector('.g-row.on');
  if (el) list.scrollTop = el.offsetTop - list.clientHeight / 2 + el.clientHeight / 2;
}
function drawGuide() {
  const c = S.byId.get(W.id);
  W.list = guideList(c);
  $('#g-count').textContent = `${fmt(W.list.length)} قناة`;
  $('#g-list').innerHTML = W.list.map(x => sideRow(x, x.id === W.id)).join('');
  if (W.tab === 'guide') scrollToActive('#g-list');
}
function drawFamily(c) {
  const fam = sorted(familyOf(c), 'number');
  $('#fam-n').textContent = fam.length > 1 ? fmt(fam.length) : '';
  $('#fam-list').innerHTML = fam.length > 1 ? fam.map(x => sideRow(x, x.id === c.id)).join('')
    : `<div class="ts-empty">${ic('layers')}<p>لا توجد قنوات أخرى من نفس الاسم أو الشبكة.</p><button class="btn btn-glass" data-tab-go="guide">${ic('list')} افتح دليل القنوات</button></div>`;
  $('[data-tab-go]')?.addEventListener('click', () => setTab('guide'));
  if (fam.length <= 1 && W.tab === 'family') setTab('guide'); else setTab(W.tab);
}

async function switchTo(c) {
  if (W.id && W.id !== c.id) W.prevId = W.id;
  W.id = c.id;
  addRecent(c.id);
  document.title = `${c.number}. ${c.name} — MTC-iPTv`;
  const fav = isFav(c.id);
  $('#tv-info').innerHTML = `<div class="ti-logo">${thumb(c)}</div>
    <div class="ti-txt"><span class="kicker"><i class="dot"></i> مباشر الآن · القناة ${c.number}</span><h1>${esc(c.name)}</h1>
      <div class="ti-meta">
        ${c.country_code ? `<a href="#/country/${enc(c.country_code)}">${flagImg(c.flag_url)}${esc(c.country_name)}</a>` : ''}
        ${c.category_slug ? `<a href="#/category/${enc(c.category_slug)}">${ic(S.cats.get(c.category_slug)?.icon || 'grid')}${esc(c.category_name)}</a>` : ''}
        ${c.language_code ? `<a href="#/language/${enc(c.language_code)}">${ic('lang')}${esc(c.language_name)}</a>` : ''}
        ${c.server ? `<a href="#/server/${enc(c.server)}">${ic('server')}${esc(c.server)}</a>` : ''}
        ${c.network ? `<a href="#/network/${enc(c.network)}">${ic('tv')}${esc(c.network)}</a>` : ''}
        ${c.quality ? `<span class="qb">${esc(c.quality)}</span>` : ''}
      </div>${c.description ? `<p class="desc">${esc(c.description)}</p>` : ''}</div>
    <div class="ti-act">
      <button class="abtn ${fav ? 'on' : ''}" id="w-fav">${ic('heart')}<span>${fav ? 'في المفضلة' : 'المفضلة'}</span></button>
      <button class="abtn" id="w-share">${ic('share')}<span>مشاركة</span></button>
      <button class="abtn" id="w-report">${ic('flag')}<span>إبلاغ</span></button>
    </div>`;
  $('#w-fav').onclick = e => { const on = toggleFav(c.id); e.currentTarget.classList.toggle('on', on); e.currentTarget.querySelector('span').textContent = on ? 'في المفضلة' : 'المفضلة'; toast(on ? 'أُضيفت إلى المفضلة' : 'أُزيلت من المفضلة'); };
  $('#w-share').onclick = () => share(c);
  $('#w-report').onclick = () => report(c, W.player.current);
  drawFamily(c);
  drawGuide();

  W.player.osd(`<span class="osd-ch">${safeImg(c.logo_url) ? `<img src="${esc(c.logo_url)}" alt="" referrerpolicy="no-referrer">` : ''}<b>${c.number}</b><span class="osd-t"><span>${esc(c.name)}</span><small>${esc([c.country_name, c.category_name, c.quality].filter(Boolean).join(' · '))}</small></span></span>`, 2600);
  let streams = [];
  try {
    streams = (await rest(`catalog_streams?channel_id=eq.${c.id}&select=id,url,server,quality,status,priority`)).data || [];
    streams.sort((a, b) => (b.status === 'online') - (a.status === 'online') || a.priority - b.priority);
  } catch { /* سيظهر خطأ في المشغّل */ }
  if (W.id !== c.id) return;
  W.player.load({ streams, title: c.name, subtitle: [c.country_name, c.category_name].filter(Boolean).join(' · '), logo: safeImg(c.logo_url), number: c.number });
}

function open(id) {
  if (!S.byId.has(id)) return;
  history.replaceState(null, '', `#/watch/${id}`);
  switchTo(S.byId.get(id));
}
function zap(d) {
  const list = W.list.length ? W.list : S.ch;
  const i = list.findIndex(x => x.id === W.id);
  open(list[(i + d + list.length) % list.length].id);
}
function digit(n) {
  W.digits = (W.digits + n).slice(-4);
  const cand = S.byNum.get(+W.digits);
  W.player.osd(`<span class="osd-num"><b>${W.digits}</b><small>${cand ? esc(cand.name) : '…'}</small></span>`, 1800);
  clearTimeout(W.digitT);
  W.digitT = setTimeout(() => {
    const c = S.byNum.get(+W.digits);
    W.digits = '';
    if (c) open(c.id); else W.player.osd('<span>لا توجد قناة بهذا الرقم</span>');
  }, 1500);
}
function toggleTheater() {
  W.theater = !W.theater; store.set('mtc-theater', W.theater);
  $('#tv').classList.toggle('theater', W.theater);
  W.player.setTheater(W.theater);
}
function watch(id) {
  const c = S.byId.get(id);
  if (!c) { M.innerHTML = '<div class="page"><p class="empty">هذه القناة غير متاحة حاليًا.<br><a class="btn btn-light" href="#/">العودة للرئيسية</a></p></div>'; return; }
  if (!W.active) buildWatch();
  switchTo(c);
}
function leaveWatch() {
  if (!W.active) return;
  W.player?.destroy(); W.player = null; W.active = false; W.id = null;
  clearTimeout(W.digitT);
}

/* ───────── مشاركة وإبلاغ وإشعارات ───────── */
function toast(msg) {
  const t = document.createElement('div');
  t.className = 'vtoast'; t.textContent = msg;
  document.body.appendChild(t);
  setTimeout(() => { t.classList.add('out'); setTimeout(() => t.remove(), 300); }, 2400);
}
async function share(c) {
  const url = location.href.split('#')[0] + `#/watch/${c.id}`;
  try { if (navigator.share) { await navigator.share({ title: c.name, text: `شاهد ${c.name} مباشرة على MTC-iPTv`, url }); return; } } catch { return; }
  navigator.clipboard?.writeText(url).then(() => toast('تم نسخ رابط القناة'));
}
function report(c, stream) {
  if (!c) return;
  const d = document.createElement('dialog');
  d.className = 'vdialog';
  d.innerHTML = `<form method="dialog"><h3>${ic('flag')} الإبلاغ عن مشكلة</h3><p>القناة: <b>${esc(c.name)}</b>${stream?.server ? ` · السيرفر: ${esc(stream.server)}` : ''}</p>
    <div class="reasons">${[['not_working', 'القناة لا تعمل'], ['bad_quality', 'جودة سيئة أو تقطيع'], ['wrong_info', 'معلومات خاطئة (الاسم/الدولة/الفئة)'], ['other', 'سبب آخر']].map(([v, t], i) => `<label><input type="radio" name="reason" value="${v}" ${i ? '' : 'checked'}><span>${t}</span></label>`).join('')}</div>
    <textarea name="note" maxlength="500" rows="3" placeholder="ملاحظات إضافية (اختياري)"></textarea>
    <div class="vd-act"><button value="cancel" class="btn btn-glass" type="button">إلغاء</button><button class="btn btn-ac" value="ok">${ic('flag')} إرسال البلاغ</button></div></form>`;
  document.body.appendChild(d);
  d.querySelector('[value=cancel]').onclick = () => d.close();
  d.querySelector('form').onsubmit = async e => {
    e.preventDefault();
    const f = new FormData(e.target);
    try {
      await rest('reports', { method: 'POST', prefer: 'return=minimal', body: { channel_id: c.id, stream_id: stream?.id || null, reason: f.get('reason'), note: String(f.get('note') || '').trim() || null } });
      toast('شكرًا لك! وصل البلاغ إلى فريق الإدارة.');
    } catch { toast('تعذّر إرسال البلاغ، حاول لاحقًا.'); }
    d.close();
  };
  d.onclose = () => d.remove();
  d.showModal();
}

/* ───────── التوجيه ───────── */
let view = '';
function route() {
  const [a = '', ...parts] = location.hash.replace(/^#\/?/, '').split('/');
  const arg = decodeURIComponent(parts.join('/'));
  const next = a || 'home';
  if (next !== 'watch') leaveWatch();
  view = next;
  document.body.dataset.view = view;
  const navKey = { country: 'countries', category: 'categories', language: 'languages', server: 'live', network: 'live' }[view] || view;
  document.querySelectorAll('#nav a, #tabbar a').forEach(e => e.classList.toggle('on', e.dataset.v === navKey));
  if (view !== 'watch') document.title = 'MTC-iPTv — بث مباشر';
  const by = (g, v) => S.ch.filter(c => GROUPS[g].key(c) === v);
  const first = (g, v) => S.ch.find(c => GROUPS[g].key(c) === v);
  const views = {
    home,
    live: () => listPage('البث المباشر', 'كل القنوات المتاحة الآن', S.ch, { icon: ic('live'), grouping: true, chips: '' }),
    countries: () => tilesPage('countries'),
    categories: () => tilesPage('categories'),
    languages: () => tilesPage('languages'),
    servers: () => tilesPage('servers'),
    country: () => { const c = first('country', arg), co = S.countries.find(x => x.code === arg); listPage(`${flagImg(c?.flag_url || co?.flag_url, 'hflag')}${esc(c?.country_name || co?.name_ar || arg)}`, 'قنوات هذه الدولة', by('country', arg)); },
    category: () => { const c = first('category', arg); listPage(esc(c?.category_name || arg), 'قنوات هذه الفئة', by('category', arg), { icon: ic(S.cats.get(arg)?.icon || 'grid'), chips: 'country' }); },
    language: () => { const c = first('language', arg); listPage(`باللغة ${esc(c?.language_name || arg)}`, 'قنوات بهذه اللغة', by('language', arg), { icon: ic('lang') }); },
    server: () => listPage(esc(arg), 'قنوات تبث من هذا السيرفر', by('server', arg), { icon: ic('server') }),
    network: () => listPage(esc(arg), 'قنوات هذه الشبكة', by('network', arg), { icon: ic('tv') }),
    favorites: () => listPage('قائمتي المفضلة', 'القنوات التي أضفتها للمفضلة', S.ch.filter(c => isFav(c.id)), { icon: ic('heart') }),
    search,
    movies: () => soon('movies'),
    series: () => soon('series'),
    watch: () => watch(arg)
  };
  (views[view] || home)();
  if (view !== 'search' && !(view === 'watch' && W.active && W.id)) scrollTo(0, 0);
}

/* ───────── أحداث عامة ───────── */
M.addEventListener('click', e => {
  const b = e.target.closest('.rail-btn');
  if (b) { const r = b.parentElement.querySelector('.rail'); r.scrollBy({ left: (b.classList.contains('nxt') ? -1 : 1) * r.clientWidth * .85, behavior: 'smooth' }); return; }
  const f = e.target.closest('[data-fav]');
  if (f) { const on = toggleFav(f.dataset.fav); f.querySelector('span').textContent = on ? 'في المفضلة' : 'أضف للمفضلة'; toast(on ? 'أُضيفت إلى المفضلة' : 'أُزيلت من المفضلة'); return; }
  const a = e.target.closest('a[href^="#/watch/"]');
  if (a && W.active) { e.preventDefault(); open(a.getAttribute('href').split('/').pop()); scrollTo({ top: 0, behavior: 'smooth' }); }
});
document.addEventListener('error', e => { if (e.target.tagName === 'IMG') e.target.remove(); }, true);
addEventListener('scroll', () => $('#top').classList.toggle('solid', scrollY > 10), { passive: true });
addEventListener('hashchange', route);
$('#q').addEventListener('input', e => { S.q = e.target.value; debounceSearch(); });
$('#q').addEventListener('keydown', e => { if (e.key === 'Enter') location.hash = '#/search'; });
document.querySelectorAll('[data-i]').forEach(e => { e.innerHTML = ic(e.dataset.i); });
$('#brand').innerHTML = logo();
$('#foot-brand').innerHTML = logo();
$('#yr').textContent = new Date().getFullYear();

/* ───────── الترويسة: اليوم والتاريخ (ميلادي/هجري بالتناوب) والوقت ───────── */
const F = {
  time: new Intl.DateTimeFormat('ar-u-nu-latn', { hour: 'numeric', minute: '2-digit', second: '2-digit', hour12: true }),
  day: new Intl.DateTimeFormat('ar', { weekday: 'long' }),
  greg: new Intl.DateTimeFormat('ar-u-nu-latn', { day: 'numeric', month: 'long', year: 'numeric' }),
  hijri: new Intl.DateTimeFormat('ar-SA-u-ca-islamic-umalqura-nu-latn', { day: 'numeric', month: 'long', year: 'numeric' })
};
$('#clock').innerHTML = `<span class="ck-ic"><svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="9"/><path class="ck-hh" d="M12 12V8.6"/><path class="ck-mm" d="M12 12V4.6"/><circle class="c0" cx="12" cy="12" r="1.4"/></svg></span>
  <span class="ck-time" dir="ltr"><b class="ck-hm"></b><span class="ck-s"></span><em class="ck-p"></em></span>
  <span class="ck-date"><b class="ck-day"></b><span class="ck-dd"><span class="ck-g"></span><span class="ck-h"></span></span></span>`;
const CK = Object.fromEntries(['hm', 's', 'p', 'day', 'g', 'h', 'hh', 'mm'].map(k => [k, $(`#clock .ck-${k}`)]));
function tickClock() {
  const d = new Date(), part = t => F.time.formatToParts(d).find(p => p.type === t)?.value || '';
  CK.hm.textContent = `${part('hour')}:${part('minute')}`;
  CK.s.textContent = `:${part('second')}`;
  CK.p.textContent = part('dayPeriod');
  CK.day.textContent = F.day.format(d);
  CK.g.textContent = F.greg.format(d);
  CK.h.textContent = F.hijri.format(d);
  // عقارب الأيقونة تتحرك مع الوقت الحقيقي
  CK.hh.style.transform = `rotate(${(d.getHours() % 12) * 30 + d.getMinutes() / 2}deg)`;
  CK.mm.style.transform = `rotate(${d.getMinutes() * 6 + d.getSeconds() / 10}deg)`;
  // التاريخ الميلادي والهجري بالتناوب كل 6 ثوانٍ
  $('#clock').classList.toggle('hijri', Math.floor(d / 6000) % 2 === 1);
}
tickClock();
setTimeout(() => { tickClock(); setInterval(tickClock, 1000); }, 1000 - (Date.now() % 1000));

/* ───────── التذييل: بطاقة المجموعة والإصدار والإحصاءات ───────── */
// شعار MTC-Group من الملف img/mtc-group-emblem.svg (حركته الدائمة داخل الملف) — يُحمَّل عند ظهور البطاقة لتبدأ حركة دخوله أمام المشاهد
$('#ft-group').innerHTML = `<div class="fg-emblem"><img data-src="img/mtc-group-emblem.svg" alt="MTC-Group" width="96" height="96"></div>
  <div class="fg-txt"><small>${esc(COMPANY.product)} إحدى شركات</small><b dir="ltr">MTC<span>-Group</span></b><span class="fg-ar">${esc(COMPANY.groupAr)}</span><span class="fg-rule"></span><em dir="ltr">${esc(COMPANY.groupEn)}</em></div>`;
$('#to-top').innerHTML = `${ic('back')}<span>للأعلى</span>`;
$('#to-top').onclick = () => scrollTo({ top: 0, behavior: 'smooth' });
$('#ft-install').onclick = e => { e.preventDefault(); openInstall(true); };
// دخول بطاقة المجموعة بنفس أسلوب المقدمة عند الوصول إليها
const groupIO = new IntersectionObserver(es => {
  if (!es[0].isIntersecting) return;
  groupIO.disconnect();
  const g = $('#ft-group'), img = g.querySelector('img[data-src]');
  img.src = img.dataset.src;
  g.classList.add('in');
}, { threshold: .4 });
groupIO.observe($('#ft-group'));
/** «برمجة وتطوير» مع حسابات المطوّر (يحددها المدير من لوحة التحكم ← الإعدادات العامة) */
function footerCredit() {
  const d = S.settings.developer || DEVELOPER, links = socialLinks(d.social);
  const box = $('#ft-dev');
  if (!d.name_ar && !d.name_en && !links.length) { box.hidden = true; $('#ft-social').hidden = true; return; }
  const initials = (d.name_en || d.name_ar || '').split(/\s+/).filter(Boolean).slice(0, 2).map(w => [...w][0]).join('').toUpperCase();
  box.innerHTML = `<span class="fd-av" aria-hidden="true"><b dir="ltr">${esc(initials)}</b></span>
    <div class="fd-txt">${d.name_ar ? `<p>برمجة وتطوير: <b>${esc(d.name_ar)}</b></p>` : '<p>برمجة وتطوير</p>'}${d.name_en ? `<span dir="ltr">Developed by <i>${esc(d.name_en)}</i></span>` : ''}</div>`;
  box.hidden = false;
  // حسابات المطوّر تحت بطاقة الشركة الأم
  const soc = $('#ft-social');
  soc.innerHTML = links.length ? `<small>تابع المطوّر</small><div>${links.map(s => `<a href="${esc(s.href)}" target="_blank" rel="noopener me" title="${esc(s.ar)}" aria-label="${esc(s.en)}" style="--c:${s.color}">${socialIcon(s, 17)}</a>`).join('')}</div>` : '';
  soc.hidden = !links.length;
}
$('#ft-ver').innerHTML = `<i class="dot"></i>الإصدار <b dir="ltr">v${VERSION}</b><small>${new Intl.DateTimeFormat('ar-u-nu-latn', { day: 'numeric', month: 'long', year: 'numeric' }).format(new Date(RELEASE_DATE))}</small>`;
footerCredit(); // يظهر فورًا بالقيم الافتراضية، ثم يُحدَّث بعد تحميل الإعدادات
/** أرقام التذييل تعدّ تصاعديًا عند ظهورها */
function footerStats() {
  const vals = { 'fs-ch': S.ch.length, 'fs-co': new Set(S.ch.map(c => c.country_code).filter(Boolean)).size, 'fs-la': new Set(S.ch.map(c => c.language_code).filter(Boolean)).size };
  const run = () => Object.entries(vals).forEach(([id, n]) => {
    const el = document.getElementById(id), t0 = performance.now();
    const step = t => { const k = Math.min(1, (t - t0) / 1400), e = 1 - Math.pow(1 - k, 3); el.textContent = Math.round(n * e).toLocaleString('en-US'); if (k < 1) requestAnimationFrame(step); };
    requestAnimationFrame(step);
  });
  const io = new IntersectionObserver(es => { if (es[0].isIntersecting) { io.disconnect(); run(); } }, { threshold: .3 });
  io.observe($('.ft-stats'));
}

/* ───────── المقدمة المتحركة ─────────
   تبقى المقدمة ظاهرة حتى تكتمل مدتها (6.4 ث) وتصبح القنوات وصورها الأولى جاهزة خلفها،
   ثم يطير الشعار إلى مكانه في الترويسة وتنكشف الصفحة الرئيسية وعناصرها تصعد تباعًا. */
const T0 = performance.now();
const INTRO_MIN = 9400;   // أقل مدة للمقدمة: مشهد MTC-Group ثم مشهد MTC-iPTv
const INTRO_MAX = 20000;  // لا ننتظر أكثر من هذا مهما تأخر الاتصال
const SP_MSGS = ['جارٍ تجهيز القنوات…', 'نبحث عن أفضل السيرفرات…', 'نرتّب القنوات حسب الدول…', 'نجهّز الصور والشعارات…', 'تقريبًا جاهز…'];
const spTimer = setInterval(() => {
  const m = $('#sp-msg'); if (!m) return clearInterval(spTimer);
  m.classList.add('swap');
  setTimeout(() => { if (m.classList.contains('ready')) return; m.textContent = SP_MSGS[Math.min(SP_MSGS.indexOf(m.textContent) + 1, SP_MSGS.length - 1)]; m.classList.remove('swap'); }, 300);
}, 1600);
let introDone = false;
const wait = ms => new Promise(r => setTimeout(r, Math.max(0, ms)));
const elapsed = () => performance.now() - T0;
// شعار المجموعة في المشهد الأول يُحمَّل عند لحظة ظهوره (0.3 ث) لتتزامن حركة دخوله المضمّنة في الملف
wait(300 - elapsed()).then(() => { const i = $('#splash .sg-emb'); if (i) i.src = i.dataset.src; });

/** انتظار تحميل الصور الظاهرة في أول الصفحة (الشعار الكبير وأول الصفوف) حتى لا يرى المستخدم مربعات فارغة */
function settleImages(timeout = 4000) {
  const imgs = [...M.querySelectorAll('img')].filter(i => i.getBoundingClientRect().top < innerHeight * 1.4).slice(0, 30);
  const bg = M.querySelector('.hero-bg')?.style.backgroundImage.match(/url\(["']?(.*?)["']?\)/)?.[1];
  if (bg) { const im = new Image(); im.referrerPolicy = 'no-referrer'; im.src = bg; imgs.push(im); }
  const one = i => i.complete && i.naturalWidth ? Promise.resolve() : new Promise(r => { i.addEventListener('load', r, { once: true }); i.addEventListener('error', r, { once: true }); });
  return Promise.race([Promise.all(imgs.map(one)), wait(timeout)]);
}

async function finishIntro(count) {
  const s = $('#splash');
  if (!s || introDone) return;
  introDone = true;
  // رسالة «جاهز» قبل الخروج بقليل
  await wait(INTRO_MIN - 1500 - elapsed());
  clearInterval(spTimer);
  const m = $('#sp-msg');
  m.classList.remove('swap');
  m.textContent = count ? `${fmt(count)} قناة جاهزة للمشاهدة` : 'جاهز';
  m.classList.add('ready'); s.classList.add('done');
  await wait(Math.max(1100, INTRO_MIN - elapsed()));

  // الشعار يطير من وسط الشاشة إلى مكانه في الترويسة بنفس المقاس
  const logoEl = s.querySelector('.sp-logo'), mark = s.querySelector('.sp-mark'), target = $('#brand .mark');
  const a = mark.getBoundingClientRect(), b = target?.getBoundingClientRect(), L = logoEl.getBoundingClientRect();
  s.classList.add('out');
  document.body.classList.add('reveal');
  if (b?.width) {
    logoEl.style.transformOrigin = `${a.left + a.width / 2 - L.left}px ${a.top + a.height / 2 - L.top}px`;
    const dx = b.left + b.width / 2 - (a.left + a.width / 2), dy = b.top + b.height / 2 - (a.top + a.height / 2);
    requestAnimationFrame(() => { logoEl.style.transform = `translate(${dx}px, ${dy}px) scale(${b.width / a.width})`; });
  }
  await wait(1200);
  document.body.classList.remove('intro'); // شعار الترويسة يظهر في نفس اللحظة والمكان
  s.remove();
  setTimeout(() => document.body.classList.remove('reveal'), 2600);
  initInstall({ ic, toast }); // إشعار تثبيت التطبيق بعد قليل من التصفح
}

async function init() {
  setTimeout(() => finishIntro(), INTRO_MAX); // حد أقصى إذا تأخر الاتصال كثيرًا
  M.innerHTML = '<section class="hero sk"></section><div class="rows"><section class="row"><div class="rail">' + '<div class="card sk"><div class="thumb"></div></div>'.repeat(8) + '</div></section></div>';
  if (!configured()) { finishIntro(); M.innerHTML = '<div class="page"><p class="empty">لم يتم إعداد الاتصال بقاعدة البيانات بعد (config.js).</p></div>'; return; }
  try {
    const [rows, cats, countries, settings, fresh] = await Promise.all([
      restAll('catalog?select=id,number,name,network,logo_url,quality,is_featured,description,country_code,country_name,flag_url,is_arab,continent,category_slug,category_name,language_code,language_name,server&order=number.asc'),
      rest('categories?select=slug,name_ar,icon,hue,sort_order&order=sort_order').then(r => r.data || []).catch(() => []),
      restAll('countries?select=code,name_ar,flag_url,is_arab,continent,sort_order&order=sort_order,name_ar').catch(() => []),
      rest('site_settings?select=key,value').then(r => r.data || []).catch(() => []),
      // طلب مستقل: لو كانت قاعدة البيانات أقدم من عمود published_at تختفي القائمة فقط ولا يتأثر الموقع
      rest('catalog?select=id,published_at&published_at=not.is.null&order=published_at.desc,number.asc&limit=30').then(r => r.data || []).catch(() => [])
    ]);
    S.ch = rows.map(c => ({ ...c, number: c.number || 0 }));
    S.byId = new Map(S.ch.map(c => [c.id, c]));
    S.byNum = new Map(S.ch.map(c => [c.number, c]));
    S.cats = new Map(cats.map(c => [c.slug, c]));
    S.countries = countries;
    S.settings = Object.fromEntries(settings.map(x => [x.key, x.value]));
    // «مضافة حديثًا»: ما نُشر خلال آخر 30 يومًا (الأحدث أولًا)
    const since = Date.now() - 30 * 864e5;
    S.fresh = fresh.filter(r => Date.parse(r.published_at) > since).map(r => S.byId.get(r.id)).filter(Boolean);
    route();
    footerStats();
    footerCredit();
    await settleImages();
    finishIntro(S.ch.length);
  } catch (e) {
    finishIntro();
    const old = /catalog|does not exist|schema cache/i.test(e.message);
    M.innerHTML = `<div class="page"><p class="empty">تعذّر تحميل القنوات.<br><small>${old ? 'قاعدة البيانات لم تُحدَّث بعد — شغّل supabase/01_schema.sql ثم supabase/02_data.sql في Supabase SQL Editor.' : esc(e.message)}</small><br><button class="btn btn-light" id="retry">إعادة المحاولة</button></p></div>`;
    $('#retry').onclick = init;
    console.error('MTC: catalog load failed:', e);
  }
}
init();
