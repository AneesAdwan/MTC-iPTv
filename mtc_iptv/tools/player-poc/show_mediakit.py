"""يطبع نتائج media_kit مقارنةً بـ mpv وVLC لكل عيّنة.  python show_mediakit.py"""
import json
from pathlib import Path

D = Path(__file__).resolve().parent.parent.parent / 'docs' / 'poc' / 'data'
mk = json.load(open(D / 'results-mediakit.json', encoding='utf-8'))
base = {r['id']: r for r in json.load(open(D / 'results.json', encoding='utf-8'))['results']}
yes = lambda b: 'Y' if b else '-'
print(f"run_at={mk['run_at']}  n={len(mk['results'])}")
for r in mk['results']:
    b = base.get(r['id'], {})
    err = (r.get('error') or '')[:60]
    print(f"{r['id']:5} mk={yes(r['ok'])} mpv={yes(b.get('mpv_ok'))} vlc={yes(b.get('vlc_ok'))} "
          f"ff={r['first_frame']} played={r['played']} res={r['resolution']} hw={r['hwdec']} "
          f"a={r['audio_tracks']} s={r['sub_tracks']} {err}")
ok = sum(r['ok'] for r in mk['results'])
print(f'media_kit ok: {ok}/{len(mk["results"])}')
