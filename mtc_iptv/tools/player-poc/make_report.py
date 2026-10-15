"""
يحوّل نتائج الاختبار إلى جداول Markdown لتقرير PoC (docs/poc/player-<date>.md).
  python make_report.py  → يطبع الجداول (تُلصق في التقرير)
يقرأ: results-generated.json (العيّنات المولّدة)، results.json (الكامل)، results-mediakit.json (إن وُجد)
"""
import collections, json, re, statistics, sys
from pathlib import Path

D = Path(__file__).resolve().parent.parent.parent / 'docs' / 'poc' / 'data'
load = lambda n: json.load(open(D / n, encoding='utf-8')) if (D / n).exists() else None
full = load('results.json')
mk = load('results-mediakit.json')
mk_by = {r['id']: r for r in (mk or {}).get('results', [])}

def med(xs):
    xs = [x for x in xs if x is not None]
    return f'{statistics.median(xs):.2f}' if xs else '—'

def p90(xs):
    xs = sorted(x for x in xs if x is not None)
    return f'{xs[int(len(xs) * 0.9) - 1 if len(xs) > 1 else 0]:.2f}' if xs else '—'

R = full['results']
gen = [r for r in R if r['group'] == 'generated']
real = [r for r in R if r['group'] in ('official', 'catalog')]
yes = lambda b: '✅' if b else '❌'

print(f"## بيانات التشغيل\n\n- التاريخ: {full['run_at']} · المدة: {full['duration_min']} دقيقة · {full['mpv']}\n- المعاملات: {full['params']}\n")

print('## أ. العيّنات المولّدة (التغطية الإلزامية)\n')
print('| # | الحالة | الوصف | المتوقع | mpv | VLC | media_kit | الترميز (mpv) | ملاحظة |')
print('|---|---|---|---|---|---|---|---|---|')
for r in gen:
    m = r['mpv'][0]
    exp = {'ok': 'يعمل', 'fail': 'يفشل', 'policy': 'سياسة'}.get(r['expect'], r['expect'])
    k = mk_by.get(r['id'])
    codec = '/'.join(x for x in [m.get('vcodec'), '+'.join(m.get('acodecs') or [])] if x) or '—'
    extra = []
    if m.get('audio_tracks', 0) > 1: extra.append(f"{m['audio_tracks']} مسارات صوت")
    if m.get('sub_tracks'): extra.append(f"{m['sub_tracks']} ترجمة")
    if not r['mpv_ok'] and m.get('err_class'): extra.append(f"mpv: {m['err_class']}")
    print(f"| {r['id']} | {r['case']} | {r['note']} | {exp} | {yes(r['mpv_ok'])} | {yes(r['vlc_ok'])} | {yes(k['ok']) if k else '⏳'} | {codec} | {'، '.join(extra)} |")

def summary(rows, label):
    n = len(rows)
    both = sum(r['mpv_ok'] and r['vlc_ok'] for r in rows)
    only_m = [r for r in rows if r['mpv_ok'] and not r['vlc_ok']]
    only_v = [r for r in rows if r['vlc_ok'] and not r['mpv_ok']]
    none = sum(not r['mpv_ok'] and not r['vlc_ok'] for r in rows)
    vlc_ok = [r for r in rows if r['vlc_ok']]
    g1 = sum(r['mpv_ok'] for r in vlc_ok)
    print(f'\n## {label} ({n} عيّنة)\n')
    print('| المقياس | القيمة |\n|---|---|')
    print(f'| عمل في الاثنين | {both} |')
    print(f'| mpv فقط | {len(only_m)} |')
    print(f'| VLC فقط | {len(only_v)} |')
    print(f'| فشل في الاثنين (المصدر معطّل غالبًا — خارج المقام) | {none} |')
    print(f'| **G1: نجاح mpv من العيّنات التي نجحت في VLC** | **{g1}/{len(vlc_ok)} = {100 * g1 / max(1, len(vlc_ok)):.1f}%** |')
    print(f'| نجاح mpv الكلي | {sum(r["mpv_ok"] for r in rows)}/{n} |')
    print(f'| نجاح VLC الكلي | {len(vlc_ok)}/{n} |')
    print(f"| زمن أول إطار — mpv (وسيط / P90) | {med([r['mpv'][0]['first_frame'] for r in rows if r['mpv_ok']])} / {p90([r['mpv'][0]['first_frame'] for r in rows if r['mpv_ok']])} ث |")
    print(f"| زمن أول إطار — VLC (وسيط / P90) | {med([r['vlc'][0].get('start') for r in rows if r['vlc_ok']])} / {p90([r['vlc'][0].get('start') for r in rows if r['vlc_ok']])} ث |")
    if mk:
        ks = [mk_by[r['id']] for r in rows if r['id'] in mk_by]
        kv = [mk_by[r['id']] for r in vlc_ok if r['id'] in mk_by]
        print(f"| **media_kit: نجاح من عيّنات VLC الناجحة** | **{sum(k['ok'] for k in kv)}/{len(kv)}** |")
        print(f"| media_kit: زمن أول إطار (وسيط) | {med([k['first_frame'] for k in ks if k['ok']])} ث |")
    errs = collections.Counter(r['mpv'][0].get('err_class') for r in rows if not r['mpv_ok'])
    print('\n**أسباب فشل mpv:** ' + '، '.join(f'{k or "تشغيل غير مستقر/قصير"}: {v}' for k, v in errs.most_common()))
    if only_v:
        print('\n**نجحت في VLC وفشلت في mpv:**\n')
        print('| # | القناة | البروتوكول | سبب mpv | تفاصيل |\n|---|---|---|---|---|')
        for r in only_v:
            m = r['mpv'][0]
            tail = re.sub(r'\s+', ' ', (m.get('err_tail') or '').split('\n')[-1])[-110:].replace('|', '/')
            why = m.get('err_class') or (f"بدأ ثم توقف (شُغّل {m.get('played')} ث، أطول توقف {m.get('max_stall')} ث)" if m.get('first_frame') else '—')
            print(f"| {r['id']} | {r['note']} | {r.get('proto', '')} | {why} | `{tail}` |")
    if only_m:
        print('\n**نجحت في mpv وفشلت في VLC:** ' + '، '.join(f"{r['id']} {r['note']}" for r in only_m))

summary(real, 'ب. القنوات الحقيقية: 30 رسمية + 100 من الكتالوج')
summary([r for r in real if r['group'] == 'official'], 'ب.1 الرسمية وحدها')
summary([r for r in real if r['group'] == 'catalog'], 'ب.2 الكتالوج وحده')

codecs = collections.Counter()
for r in real:
    m = r['mpv'][0]
    if r['mpv_ok']:
        codecs[(m.get('vcodec') or 'audio-only') + ' + ' + ('/'.join(sorted(set(m.get('acodecs') or []))) or '—')] += 1
print('\n## ج. الترميزات الفعلية في القنوات العاملة\n\n| الفيديو + الصوت | العدد |\n|---|---|')
for k, v in codecs.most_common(): print(f'| {k} | {v} |')
res = collections.Counter((r['mpv'][0].get('resolution') or '—') for r in real if r['mpv_ok'])
print('\n**الدقة:** ' + '، '.join(f'{k}: {v}' for k, v in res.most_common(8)))
