"""
تجربة إعدادات mpv لتسريع أول إطار (المرحلة 0). يشغّل نفس العيّنات بعدة ملفات إعداد ويقارن الزمن.
لا يستخدم --length (يقطع بث DVR مبكرًا لأنه يُحسب من بداية النافذة الزمنية): يُقتل mpv بعد مدة ثابتة،
ويُحسب «مدة التشغيل» من أول إطار حتى القتل، ما لم يخرج mpv قبلها.
  python ttff_tune.py [--n 40] [--play 20]
"""
import argparse, json, os, re, statistics, subprocess, tempfile, time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

HERE = Path(__file__).resolve().parent
DATA = HERE.parent.parent / 'docs' / 'poc' / 'data'
MPV = os.environ.get('MPV') or str(Path.home() / 'scoop/apps/mpv/current/mpv.exe')

PROFILES = {
    'default': [],
    # mpv يختار أعلى جودة HLS افتراضيًا ويحلّل التدفق مطوّلًا؛ هذه الإعدادات تخفّف ذلك
    'fast': ['--demuxer-lavf-analyzeduration=0.5', '--demuxer-lavf-probesize=500000',
             '--demuxer-lavf-o-add=fflags=+nobuffer', '--cache-pause-initial=no', '--demuxer-readahead-secs=2'],
    'fast+lowfirst': ['--demuxer-lavf-analyzeduration=0.5', '--demuxer-lavf-probesize=500000',
                      '--demuxer-lavf-o-add=fflags=+nobuffer', '--cache-pause-initial=no', '--demuxer-readahead-secs=2',
                      '--hls-bitrate=min'],
}

def run(url, extra, play, ff_to):
    fd, name = tempfile.mkstemp(suffix='.log'); os.close(fd)
    args = [MPV, '--no-config', '--ytdl=no', '--vo=null', '--ao=null', '--network-timeout=15',
            '--msg-level=all=v', f'--log-file={name}', *extra, url]
    p = subprocess.Popen(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    t0 = time.monotonic(); limit = ff_to + play
    while p.poll() is None and time.monotonic() - t0 < limit: time.sleep(0.2)
    killed = p.poll() is None
    if killed: p.kill(); p.wait()
    end = time.monotonic() - t0
    txt = Path(name).read_text(encoding='utf-8', errors='replace')
    try: os.unlink(name)
    except OSError: pass
    m = re.search(r'^\[\s*([\d.]+)\]\[\w\]\[cplayer\] VO: \[', txt, re.M) or re.search(r'^\[\s*([\d.]+)\]\[\w\]\[cplayer\] AO: \[', txt, re.M)
    ff = float(m.group(1)) if m else None
    stalls = [float(x) for x in re.findall(r'End buffering \(waited ([\d.]+) secs\)', txt)]
    played = (end - ff) if ff is not None else 0
    ok = ff is not None and ff <= ff_to and (killed or played >= play * 0.9) and max(stalls, default=0) <= 5
    return {'ff': ff, 'played': round(played, 1), 'killed': killed, 'ok': ok, 'stall': max(stalls, default=0)}

def main():
    ap = argparse.ArgumentParser(); ap.add_argument('--n', type=int, default=0); ap.add_argument('--play', type=float, default=20)
    ap.add_argument('--ff-timeout', type=float, default=15); ap.add_argument('--workers', type=int, default=6); ap.add_argument('--profiles', default=','.join(PROFILES))
    a = ap.parse_args()
    res = json.load(open(DATA / 'results.json', encoding='utf-8'))['results']
    rows = [r for r in res if r['group'] in ('official', 'catalog') and r['vlc_ok']]  # المقام: ما نجح في VLC
    if a.n: rows = rows[:a.n]
    path = DATA / 'results-ttff.json'
    out = json.load(open(path, encoding='utf-8'))['results'] if path.exists() else {}
    for prof in a.profiles.split(','):
        extra = PROFILES[prof]
        with ThreadPoolExecutor(a.workers) as ex:
            rs = list(ex.map(lambda r: run(r['url'], extra, a.play, a.ff_timeout), rows))
        out[prof] = {r['id']: x for r, x in zip(rows, rs)}
        ffs = sorted(x['ff'] for x in rs if x['ok'])
        stats = f"ttff median={statistics.median(ffs):.2f}s  p90={ffs[max(0, int(len(ffs) * 0.9) - 1)]:.2f}s" if ffs else 'no successes'
        print(f"{prof:15} ok={sum(x['ok'] for x in rs)}/{len(rs)}  {stats}", flush=True)
        json.dump({'run_at': time.strftime('%Y-%m-%d %H:%M'), 'profiles': PROFILES, 'n': len(rows), 'results': out},
                  open(path, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    json.dump({'run_at': time.strftime('%Y-%m-%d %H:%M'), 'profiles': PROFILES, 'n': len(rows), 'results': out},
              open(DATA / 'results-ttff.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    fails = {p: [i for i, x in v.items() if not x['ok']] for p, v in out.items()}
    print('failures:', json.dumps(fails, ensure_ascii=False))

if __name__ == '__main__':
    main()
