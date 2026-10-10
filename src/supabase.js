// طبقة الاتصال الوحيدة مع Supabase (REST + Auth) — مشتركة بين واجهة المشاهدة ولوحة الإدارة.
// تستخدم المفتاح العام (anon) فقط؛ الصلاحيات الفعلية تفرضها سياسات RLS في قاعدة البيانات.
const cfg = () => window.MTC_CONFIG || {};
const base = () => String(cfg().supabaseUrl || '').replace(/\/$/, '');
const key = () => cfg().supabaseAnonKey || '';
export const configured = () => Boolean(base() && key());

const SESSION_KEY = 'mtc-admin-session';
export function getSession() {
  try { return JSON.parse(localStorage.getItem(SESSION_KEY) || 'null'); } catch { return null; }
}
function saveSession(s) {
  try {
    if (s) localStorage.setItem(SESSION_KEY, JSON.stringify(s));
    else localStorage.removeItem(SESSION_KEY);
  } catch { /* التخزين غير متاح */ }
}

async function authCall(grant, body) {
  const r = await fetch(`${base()}/auth/v1/token?grant_type=${grant}`, {
    method: 'POST',
    headers: { apikey: key(), 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
  });
  const j = await r.json().catch(() => ({}));
  if (!r.ok) throw new Error(j.error_description || j.msg || j.message || 'تعذّر تسجيل الدخول');
  j.expires_at = Math.floor(Date.now() / 1000) + (j.expires_in || 3600);
  saveSession(j);
  return j;
}

export async function login(email, password) {
  if (!configured()) throw new Error('يرجى إعداد اتصال Supabase في config.js');
  return authCall('password', { email, password });
}
export function logout() { saveSession(null); }

async function validSession() {
  const s = getSession();
  if (!s?.access_token) return null;
  if (s.expires_at > Date.now() / 1000 + 60) return s;
  try { return await authCall('refresh_token', { refresh_token: s.refresh_token }); }
  catch { saveSession(null); return null; }
}

/**
 * طلب REST إلى Supabase.
 * @returns {Promise<{data:any,total:number|null}>} total متاح عند طلب count.
 */
export async function rest(path, { method = 'GET', body, auth = false, prefer, range } = {}) {
  if (!configured()) throw new Error('يرجى إعداد اتصال Supabase في config.js');
  let token = key();
  if (auth) {
    const s = await validSession();
    if (!s) throw new Error('انتهت الجلسة، يرجى تسجيل الدخول مجددًا');
    token = s.access_token;
  }
  const headers = { apikey: key(), Authorization: `Bearer ${token}` };
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  if (prefer) headers.Prefer = prefer;
  if (range) { headers['Range-Unit'] = 'items'; headers.Range = range; }
  const r = await fetch(`${base()}/rest/v1/${path}`, {
    method, headers, body: body !== undefined ? JSON.stringify(body) : undefined
  });
  const txt = await r.text();
  let data = null;
  try { data = txt ? JSON.parse(txt) : null; } catch { data = txt; }
  if (!r.ok) throw new Error(data?.message || data?.error || `HTTP ${r.status}`);
  const m = (r.headers.get('content-range') || '').match(/\/(\d+)$/);
  return { data, total: m ? +m[1] : null };
}

/** يجلب كل الصفوف على دفعات (حد Supabase الافتراضي 1000 صف لكل طلب). */
export async function restAll(path, opts = {}) {
  const out = [];
  for (let from = 0; ; from += 1000) {
    const { data } = await rest(path, { ...opts, range: `${from}-${from + 999}` });
    if (!Array.isArray(data)) break;
    out.push(...data);
    if (data.length < 1000) break;
  }
  return out;
}
