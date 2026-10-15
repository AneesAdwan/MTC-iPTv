"""يعدّ القوائم الرئيسية الحقيقية التي تعرّف مسارات بديلة (#EXT-X-MEDIA) — لتحديد قاعدة «اختيار الجودة مسبقًا»."""
import json, urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

D = Path(__file__).resolve().parent.parent.parent / 'docs' / 'poc' / 'data'
rows = [r for r in json.load(open(D / 'results.json', encoding='utf-8'))['results'] if r['group'] in ('official', 'catalog') and r['vlc_ok']]

def scan(r):
    try:
        with urllib.request.urlopen(urllib.request.Request(r['url'], headers={'User-Agent': 'Mozilla/5.0'}), timeout=8) as f:
            t = f.read(512 * 1024).decode('utf-8', 'replace')
    except Exception:
        return r['id'], 'error', 0, 0
    if '#EXT-X-STREAM-INF' not in t: return r['id'], 'media', 0, 0
    aud = sum(1 for l in t.splitlines() if l.startswith('#EXT-X-MEDIA') and 'TYPE=AUDIO' in l)
    sub = sum(1 for l in t.splitlines() if l.startswith('#EXT-X-MEDIA') and ('TYPE=SUBTITLES' in l or 'TYPE=CLOSED-CAPTIONS' in l))
    return r['id'], 'master', aud, sub

with ThreadPoolExecutor(12) as ex:
    res = list(ex.map(scan, rows))
masters = [x for x in res if x[1] == 'master']
alt_audio = [x for x in masters if x[2] > 1]
any_media = [x for x in masters if x[2] or x[3]]
print(f'samples={len(res)} masters={len(masters)} with_any_EXT-X-MEDIA={len(any_media)} with_2+_audio={len(alt_audio)} with_subs={sum(1 for x in masters if x[3])}')
print('2+ audio:', [x[0] for x in alt_audio])
print('any media:', [x[0] for x in any_media])
