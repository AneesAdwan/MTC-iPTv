// ════════════════════════════════════════════════════════════════════════════
// MTC-iPTv — وسيط البث (Cloudflare Worker)
//
// يحل ثلاث مشاكل تمنع تشغيل بعض القنوات على موقعك: CORS، و http على https، و HTTP 403.
// استعمله للقنوات المرخّصة لك فقط — فالبث يمر عبر حسابك وتتحمّل مسؤوليته.
//
// الاستعمال من الموقع:  https://<اسمك>.workers.dev/?url=<رابط_البث_الكامل>
//
// ما يفعله هذا الإصدار إضافةً إلى نسختك البسيطة:
//   • يعيد كتابة روابط قوائم m3u8 الداخلية (الجودات والمقاطع) لتمر هي أيضًا عبر الوسيط،
//     وبدون ذلك يُحمَّل الملف الرئيسي فقط ثم يتوقف الفيديو.
//   • يمرّر ترويسة Referer/Origin للمصدر للنطاقات التي تضبطها في REFERERS (لمصادرك المرخّصة).
//
// النشر: Cloudflare Dashboard ← Workers ← عدّل الـ Worker ← الصق هذا الملف ← Deploy.
// ════════════════════════════════════════════════════════════════════════════

// لمصادر محمية تتطلب ترويسة مصدر معيّنة: ضع نطاق البث والموقع الرسمي المصرّح لك باستخدامه.
// اتركه فارغًا إن لم تحتج ذلك. استعمله فقط لمصادر لديك حق استخدامها.
const REFERERS = {
  'hadara.ps': 'https://alfajertv.com',  // بثّ الفجر على سيرفرات حضارة يتطلب ترويسة موقعه الرسمي
};

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, HEAD, OPTIONS',
  'Access-Control-Allow-Headers': '*',
  'Access-Control-Expose-Headers': 'Content-Length, Content-Range, Content-Type',
};

export default {
  async fetch(request) {
    if (request.method === 'OPTIONS') return new Response(null, { headers: CORS });

    const self = new URL(request.url);
    const target = self.searchParams.get('url');
    if (!target) return new Response('MTC Proxy Is Running Successfully!', { headers: { ...CORS, 'Content-Type': 'text/plain;charset=UTF-8' } });

    let t;
    try { t = new URL(target); } catch { return new Response('Bad url', { status: 400, headers: CORS }); }

    // ترويسة المصدر للمصادر المحمية المصرّح بها (إن ضُبطت)، وإلا من نطاق البث نفسه
    const host = t.hostname.replace(/^www\./, '');
    const refKey = Object.keys(REFERERS).find(h => host === h || host.endsWith('.' + h));
    const ref = refKey ? REFERERS[refKey] : t.origin;

    const headers = {
      'User-Agent': request.headers.get('User-Agent') || 'Mozilla/5.0',
      'Referer': ref, 'Origin': new URL(ref).origin,
      'Accept': '*/*',
    };
    const range = request.headers.get('Range');
    if (range) headers['Range'] = range;

    let res;
    try { res = await fetch(t.href, { headers, redirect: 'follow' }); }
    catch { return new Response('Upstream fetch failed', { status: 502, headers: CORS }); }

    const ct = (res.headers.get('Content-Type') || '').toLowerCase();
    const looksPlaylist = /mpegurl|m3u8/.test(ct) || /\.m3u8(\?|$)/i.test(t.pathname);

    // إخراج الترويسات مع السماح بالوصول (CORS)
    const out = new Headers(res.headers);
    for (const [k, v] of Object.entries(CORS)) out.set(k, v);
    out.delete('Content-Security-Policy'); out.delete('X-Frame-Options');

    // غير قائمة، أو استجابة خطأ (403 وغيره): تُمرَّر كما هي بلا إعادة كتابة
    if (!looksPlaylist || !res.ok) return new Response(res.body, { status: res.status, headers: out });

    const text = await res.text();
    if (!text.trimStart().startsWith('#EXTM3U')) return new Response(text, { status: res.status, headers: out });

    // إعادة كتابة قائمة m3u8: كل رابط داخلي يصبح عبر الوسيط بعنوان مطلق
    const base = t.href;
    const prefix = self.origin + '/?url=';
    const abs = u => { try { return new URL(u, base).href; } catch { return u; } };
    const rewritten = text.split('\n').map(line => {
      const s = line.trim();
      if (!s) return line;
      if (s.startsWith('#')) {
        // سمات URI="..." داخل أسطر التعليمات (المفاتيح، الترجمات، الصوت البديل)
        return line.replace(/URI="([^"]+)"/g, (_, u) => `URI="${prefix}${encodeURIComponent(abs(u))}"`);
      }
      return prefix + encodeURIComponent(abs(s)); // سطر رابط (جودة أو مقطع)
    }).join('\n');

    out.delete('Content-Length');
    out.set('Content-Type', 'application/vnd.apple.mpegurl');
    return new Response(rewritten, { status: res.status, headers: out });
  }
};
