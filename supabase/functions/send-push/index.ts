// ════════════════════════════════════════════════════════════════════════════
// Supabase Edge Function: send-push
// ترسل إشعار Push إلى كل أجهزة التطبيق (الموضوع «all») عبر Firebase Cloud Messaging.
// تُستدعى من لوحة الإدارة فقط (تتحقق أن المستخدم مشرف). المفتاح السري على الخادم.
//
// الأسرار المطلوبة (Supabase → Project Settings → Edge Functions → Secrets):
//   FIREBASE_SERVICE_ACCOUNT = محتوى ملف مفتاح الخدمة (JSON) كاملًا
//   FIREBASE_PROJECT_ID      = mtci-iptv
//
// النشر:  supabase functions deploy send-push
// ════════════════════════════════════════════════════════════════════════════
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};
const json = (b: unknown, status = 200) =>
  new Response(JSON.stringify(b), { status, headers: { ...CORS, 'Content-Type': 'application/json' } });

// توقيع JWT بمفتاح الخدمة للحصول على رمز وصول Google (OAuth2)
async function getAccessToken(sa: { client_email: string; private_key: string }) {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const claim = {
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now, exp: now + 3600,
  };
  const b64 = (o: unknown) => btoa(JSON.stringify(o)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
  const unsigned = `${b64(header)}.${b64(claim)}`;

  const pem = sa.private_key.replace(/\\n/g, '\n');
  const der = atob(pem.replace(/-----[^-]+-----/g, '').replace(/\s/g, ''));
  const bytes = new Uint8Array([...der].map(c => c.charCodeAt(0)));
  const key = await crypto.subtle.importKey('pkcs8', bytes.buffer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign']);
  const sig = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(unsigned));
  const jwt = `${unsigned}.${btoa(String.fromCharCode(...new Uint8Array(sig))).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')}`;

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  const j = await res.json();
  if (!j.access_token) throw new Error('OAuth failed: ' + JSON.stringify(j));
  return j.access_token as string;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });
  try {
    // 1) تحقّق من الصلاحية: إمّا سرّ داخلي (للنداء التلقائي من قاعدة البيانات)، أو مشرف.
    const internal = Deno.env.get('PUSH_INTERNAL_SECRET');
    const isInternal = internal && req.headers.get('x-internal-secret') === internal;
    if (!isInternal) {
      const auth = req.headers.get('Authorization') || '';
      const supa = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, {
        global: { headers: { Authorization: auth } },
      });
      const { data: isAdmin } = await supa.rpc('is_mtc_admin');
      if (!isAdmin) return json({ error: 'forbidden' }, 403);
    }

    // 2) اقرأ المدخلات
    const { title, body, url, check } = await req.json().catch(() => ({}));

    // 3) تحقّق من الإعداد (الأسرار + مفتاح الخدمة)
    const saRaw = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
    if (!saRaw) return json({ error: 'no_service_account', hint: 'اضبط السرّ FIREBASE_SERVICE_ACCOUNT' }, 400);
    const sa = JSON.parse(saRaw);
    const projectId = Deno.env.get('FIREBASE_PROJECT_ID') || sa.project_id;
    const token = await getAccessToken(sa);

    // وضع الفحص: نتأكد أن كل شيء جاهز دون إرسال إشعار
    if (check) return json({ ok: true, ready: true, project: projectId });
    if (!title || !body) return json({ error: 'title and body required' }, 400);
    const msg = {
      message: {
        topic: 'all',
        notification: { title, body },
        data: url ? { url: String(url) } : {},
        android: { priority: 'high', notification: { sound: 'default' } },
      },
    };
    const r = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
      method: 'POST', headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify(msg),
    });
    const out = await r.json();
    if (!r.ok) return json({ error: 'fcm', detail: out }, 502);
    return json({ ok: true, id: out.name });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
