"""
تجربة «اختيار الجودة مسبقًا» (المرحلة 0): التطبيق يقرأ قائمة HLS الرئيسية بنفسه، ويختار نسخة واحدة،
ثم يعطي mpv رابط تلك النسخة مباشرة — بدل أن يفتح ffmpeg كل النسخ ويحلّلها قبل البدء.
  python variant_test.py [--play 10] [--workers 6]
"""
import argparse, json, re, statistics, time, urllib.request
from concurrent.futures import ThreadPoolExecutor
from urllib.parse import urljoin

import ttff_tune as T

def pick_variant(url, timeout=8, max_height=1080):
    """يُرجع (الرابط المختار، عدد النسخ). إن لم تكن قائمة رئيسية يُرجع الرابط نفسه."""
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        final = r.geturl(); text = r.read(512 * 1024).decode('utf-8', 'replace')
    if '#EXT-X-STREAM-INF' not in text: return url, 0
    lines = text.splitlines(); variants = []
    for i, l in enumerate(lines):
        if l.startswith('#EXT-X-STREAM-INF'):
            bw = int((re.search(r'BANDWIDTH=(\d+)', l) or [0, 0])[1])
            h = int((re.search(r'RESOLUTION=\d+x(\d+)', l) or [0, 0])[1])
            nxt = next((x.strip() for x in lines[i + 1:] if x.strip() and not x.startswith('#')), None)
            if nxt: variants.append((h, bw, urljoin(final, nxt)))
    ok = [v for v in variants if v[0] <= max_height] or variants
    best = max(ok, key=lambda v: (v[0], v[1]))  # أعلى جودة ≤ 1080p
    return best[2], len(variants)

def one(r, play, ff_to):
    try: v, n = pick_variant(r['url'])
    except Exception: v, n = r['url'], -1
    t0 = time.monotonic()
    x = T.run(v, [], play, ff_to)
    return {'id': r['id'], 'variants': n, 'ff': x['ff'], 'ok': x['ok'], 'resolve_s': None}

def main():
    ap = argparse.ArgumentParser(); ap.add_argument('--play', type=float, default=10); ap.add_argument('--workers', type=int, default=6)
    a = ap.parse_args()
    rows = [r for r in json.load(open(T.DATA / 'results.json', encoding='utf-8'))['results'] if r['group'] in ('official', 'catalog') and r['vlc_ok']]
    with ThreadPoolExecutor(a.workers) as ex:
        rs = list(ex.map(lambda r: one(r, a.play, 15), rows))
    base = json.load(open(T.DATA / 'results-ttff.json', encoding='utf-8'))['results']['default']
    multi = [x for x in rs if x['variants'] > 1]
    ffs = sorted(x['ff'] for x in rs if x['ok'])
    bff = lambda ids: sorted(base[i]['ff'] for i in ids if base[i]['ok'])
    m_ids = [x['id'] for x in multi]
    print(f"variant-first  ok={sum(x['ok'] for x in rs)}/{len(rs)}  ttff median={statistics.median(ffs):.2f}s  p90={ffs[int(len(ffs)*0.9)-1]:.2f}s")
    print(f"master playlists: {len(multi)}  | default median on them={statistics.median(bff(m_ids)):.2f}s  variant-first median={statistics.median(sorted(x['ff'] for x in multi if x['ok'])):.2f}s")
    print('failures:', [x['id'] for x in rs if not x['ok']])
    d = json.load(open(T.DATA / 'results-ttff.json', encoding='utf-8'))
    d['results']['variant-first'] = {x['id']: x for x in rs}
    d['profiles']['variant-first'] = ['(app resolves HLS master → single variant ≤1080p)']
    json.dump(d, open(T.DATA / 'results-ttff.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)

if __name__ == '__main__':
    main()
