// ════════════════════════════════════════════════════════════════════════════
// تثبيت الموقع كتطبيق — إشعار يناسب كل جهاز، والمستخدم يوافق أو يرفض:
//   • أندرويد / كروم / إيدج / سامسونج: زر «تثبيت» يفتح نافذة التثبيت الأصلية للمتصفح
//   • آيفون وآيباد: خطوات «مشاركة ← إضافة إلى الشاشة الرئيسية»
//   • ماك سفاري: «ملف ← إضافة إلى Dock»   • فايرفوكس وغيره: حفظ في المفضلة
//   • التلفاز: بطاقة كبيرة تُدار بأزرار الريموت (الأسهم و OK و رجوع)
// القرار يُحفظ: «لاحقًا» = نسأل بعد 7 أيام · «لا تسألني» = لا نسأل أبدًا · بعد التثبيت لا يظهر.
// ════════════════════════════════════════════════════════════════════════════
const KEY = 'mtc-install', SNOOZE_DAYS = 7;
const ua = navigator.userAgent;
const store = {
  get() { try { return JSON.parse(localStorage.getItem(KEY)) || {}; } catch { return {}; } },
  set(v) { try { localStorage.setItem(KEY, JSON.stringify(v)); } catch { /* ignore */ } }
};

/* ── الجهاز والمتصفح ── */
export const device = (() => {
  const tv = /SMART-?TV|SmartTV|Tizen|Web0S|webOS|NetCast|HbbTV|BRAVIA|AFT[A-Z]|Android TV|GoogleTV|CrKey|Roku|VIDAA|Hisense|AQUOS|PhilipsTV|Viera|TV Safari/i.test(ua)
    || (/Android/i.test(ua) && !/Mobile/i.test(ua) && matchMedia('(pointer: none)').matches);
  const ios = /iPhone|iPad|iPod/i.test(ua) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  const macSafari = !ios && /Macintosh/i.test(ua) && /Safari/i.test(ua) && !/Chrome|Chromium|Edg|Firefox|OPR/i.test(ua);
  const firefox = /Firefox|FxiOS/i.test(ua);
  const android = /Android/i.test(ua) && !tv;
  const mobile = !tv && (ios || android || /Mobile/i.test(ua));
  const mac = /Macintosh|Mac OS/i.test(ua);
  return { tv, ios, macSafari, firefox, android, mobile, mac, kind: tv ? 'tv' : mobile ? 'mobile' : 'desktop' };
})();
export const isInstalled = () => matchMedia('(display-mode: standalone)').matches || matchMedia('(display-mode: minimal-ui)').matches || navigator.standalone === true;

let deferred = null, box = null, icFn = s => '', toastFn = null, readyAt = 0;
window.addEventListener('beforeinstallprompt', e => { e.preventDefault(); deferred = e; if (readyAt && !box) maybeShow(); });
window.addEventListener('appinstalled', () => { store.set({ installed: true }); close(); toastFn?.('تم تثبيت MTC-iPTv — تجده الآن بين تطبيقاتك'); });

// عامل الخدمة (شرط التثبيت في معظم المتصفحات + فتح الواجهة بدون اتصال)
if ('serviceWorker' in navigator && /^https:|^http:\/\/(localhost|127\.)/.test(location.href)) {
  addEventListener('load', () => navigator.serviceWorker.register('sw.js').catch(() => {}));
}

/** نص الإشعار وخطوات التثبيت حسب الجهاز */
function content() {
  const ic = icFn, share = `<i class="ins-k">${ic('share')}</i>`;
  if (deferred) return {
    sub: device.tv ? 'ثبّته على تلفازك وافتحه مباشرة من قائمة التطبيقات' : device.mobile ? 'على شاشتك الرئيسية — يفتح بلمسة واحدة وبملء الشاشة مثل أي تطبيق' : 'كتطبيق على جهازك — نافذة مستقلة واختصار في قائمة البرامج',
    native: true
  };
  if (device.ios) return {
    sub: 'أضفه إلى شاشتك الرئيسية ليفتح بملء الشاشة مثل التطبيقات',
    steps: [`اضغط زر المشاركة ${share} في شريط المتصفح`, 'اختر <b>«إضافة إلى الشاشة الرئيسية»</b>', 'اضغط <b>«إضافة»</b> في الأعلى']
  };
  if (device.macSafari) return {
    sub: 'أضفه إلى شريط Dock ليفتح كتطبيق مستقل',
    steps: ['من شريط القوائم اختر <b>ملف</b>', 'اختر <b>«إضافة إلى Dock»</b>', 'اضغط <b>«إضافة»</b>']
  };
  if (device.tv) return {
    sub: 'احفظه على تلفازك لتصل إليه بسرعة من الريموت',
    steps: ['افتح قائمة المتصفح من زر <b>القائمة</b> في الريموت', 'اختر <b>«إضافة إلى الشاشة الرئيسية»</b> أو <b>«إضافة إلى المفضلة»</b>', 'افتح MTC-iPTv من الشاشة الرئيسية أو المفضلة متى شئت']
  };
  if (device.android && device.firefox) return {
    sub: 'أضفه إلى شاشتك الرئيسية ليفتح كتطبيق',
    steps: ['افتح قائمة المتصفح <b>⋮</b>', 'اختر <b>«تثبيت»</b> أو <b>«إضافة إلى الشاشة الرئيسية»</b>']
  };
  return {
    sub: 'احفظه في المفضلة للوصول السريع',
    steps: [`اضغط <b dir="ltr">${device.mac ? '⌘ + D' : 'Ctrl + D'}</b> لحفظ الموقع في المفضلة`, 'أو افتحه من متصفح Chrome أو Edge لتثبيته كتطبيق كامل']
  };
}

function close() { if (!box) return; const b = box; box = null; b.classList.remove('on'); setTimeout(() => b.remove(), 350); }

/** يعرض إشعار التثبيت (force = من زر «ثبّت التطبيق» حتى لو رفض سابقًا) */
export function openInstall(force = false) {
  if (box) return;
  if (isInstalled()) { toastFn?.('التطبيق مثبّت بالفعل على هذا الجهاز'); return; }
  const C = content(), ic = icFn;
  box = document.createElement('div');
  box.className = `ins ${device.tv ? 'tv' : ''}`;
  box.setAttribute('role', 'dialog'); box.setAttribute('aria-label', 'تثبيت MTC-iPTv');
  box.innerHTML = `<div class="ins-card">
    <button class="ins-x" data-i="later" aria-label="إغلاق">${ic('x')}</button>
    <div class="ins-top"><img class="ins-logo" src="img/app-icon-192.png" alt="">
      <div><b>ثبّت MTC-iPTv</b><p>${C.sub}</p></div></div>
    <ul class="ins-feat"><li>${ic('zap')} فتح أسرع</li><li>${ic('tv')} ملء الشاشة</li><li>${ic('heart')} مفضلتك معك</li></ul>
    ${C.steps ? `<ol class="ins-steps" hidden>${C.steps.map(s => `<li>${s}</li>`).join('')}</ol>` : ''}
    <div class="ins-act">
      <button class="ins-btn pri" data-i="${C.native ? 'install' : 'how'}">${ic(C.native ? 'download' : 'info')}<span>${C.native ? 'تثبيت' : 'كيف أثبّته؟'}</span></button>
      <button class="ins-btn" data-i="later">لاحقًا</button>
    </div>
    ${force ? '' : '<button class="ins-never" data-i="never">لا تسألني مرة أخرى</button>'}
  </div>`;
  document.body.appendChild(box);
  requestAnimationFrame(() => box?.classList.add('on'));
  const btns = () => [...box.querySelectorAll('button')].filter(b => b.offsetParent);
  if (device.tv) setTimeout(() => box?.querySelector('.pri')?.focus(), 380);

  box.addEventListener('click', async e => {
    const a = e.target.closest('[data-i]')?.dataset.i;
    if (!a) return;
    if (a === 'install' && deferred) {
      const ev = deferred; deferred = null;
      ev.prompt();
      const { outcome } = await ev.userChoice.catch(() => ({ outcome: 'dismissed' }));
      if (outcome === 'accepted') store.set({ installed: true });
      else store.set({ snooze: Date.now() });
      close();
    }
    if (a === 'how') {
      box.querySelector('.ins-steps').hidden = false; box.querySelector('.ins-feat').hidden = true;
      const b = box.querySelector('.pri'); b.dataset.i = 'done'; b.innerHTML = `${ic('check')}<span>فهمت</span>`;
      if (device.tv) b.focus();
      return;
    }
    if (a === 'done') { store.set({ snooze: Date.now() }); close(); }
    if (a === 'later') { store.set({ snooze: Date.now() }); close(); }
    if (a === 'never') { store.set({ never: true }); close(); }
  });
  // الريموت ولوحة المفاتيح: الأسهم للتنقل، OK للتأكيد، رجوع/Esc = لاحقًا — ولا تصل للمشغّل
  box.addEventListener('keydown', e => {
    const list = btns(), i = list.indexOf(document.activeElement);
    if (['ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown'].includes(e.key)) {
      const d = e.key === 'ArrowLeft' || e.key === 'ArrowDown' ? 1 : -1;
      list[(i + d + list.length) % list.length]?.focus(); e.preventDefault();
    }
    if (e.key === 'Escape' || e.key === 'Backspace' || e.key === 'GoBack' || e.keyCode === 10009 || e.keyCode === 461) { store.set({ snooze: Date.now() }); close(); e.preventDefault(); }
    e.stopPropagation();
  });
}

function maybeShow() {
  if (box || isInstalled()) return;
  const s = store.get();
  if (s.never || s.installed) return;
  if (s.snooze && Date.now() - s.snooze < SNOOZE_DAYS * 864e5) return;
  // لا نقاطع المشاهدة بملء الشاشة
  if (document.fullscreenElement || location.hash.startsWith('#/watch')) { setTimeout(maybeShow, 30000); return; }
  openInstall();
}

/** يُستدعى بعد انتهاء المقدمة: يعرض الإشعار بعد مهلة قصيرة من التصفح */
export function initInstall({ ic, toast, delay = 12000 }) {
  icFn = ic; toastFn = toast;
  if (isInstalled()) document.documentElement.classList.add('is-app');
  setTimeout(() => { readyAt = Date.now(); maybeShow(); }, delay);
}
