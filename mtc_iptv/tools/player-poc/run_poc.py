"""
إثبات مفهوم المشغّل — المرحلة 0 (ملحق ج).

يشغّل كل عيّنة في mpv (نفس محرّك libmpv الذي تستخدمه media_kit) وفي libVLC (المرجع)،
ويقيس: أول إطار، مدة التشغيل، أطول توقف، الترميز، وسبب الفشل، ثم يكتب:
  docs/poc/data/samples.json   ← قائمة العيّنات (قابلة لإعادة الاختبار)
  docs/poc/data/results.json   ← النتائج الخام
  docs/poc/data/results.csv    ← نفس النتائج للجداول

الاستخدام:
  python run_poc.py                    ← تشغيل كامل (عيّنات مولّدة + 30 رسمية + 100 من الكتالوج)
  python run_poc.py --only generated   ← المولّدة فقط
  python run_poc.py --play 20 --workers 4 --attempts 1
"""
import argparse, csv, json, os, random, re, shutil, subprocess, sys, tempfile, time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

HERE = Path(__file__).resolve().parent
APP = HERE.parent.parent                       # mtc_iptv/
REPO = APP.parent                              # MTC-iPTv/
OUT = APP / 'docs' / 'poc' / 'data'
GEN = HERE.parent / 'test-streams' / 'out'
MPV = os.environ.get('MPV') or shutil.which('mpv.exe') or str(Path.home() / 'scoop/apps/mpv/current/mpv.exe')
FFMPEG = shutil.which('ffmpeg') or 'ffmpeg'
PORT = int(os.environ.get('POC_PORT', 8791))
BASE, TLS = f'http://127.0.0.1:{PORT}', f'https://127.0.0.1:{PORT + 1}'
RTMP = 'rtmp://127.0.0.1:19350/live/test'
UA_OK, REF_OK = 'MTC-Test/1.0', 'https://mtc-test.local/'

ARAB = {'SA', 'AE', 'EG', 'QA', 'KW', 'BH', 'OM', 'JO', 'LB', 'SY', 'IQ', 'PS', 'YE', 'LY', 'TN', 'DZ', 'MA', 'SD', 'MR', 'SO', 'DJ', 'KM'}
OFFICIAL = re.compile(r'(getaj\.net|aljazeera|alarabiya|france24|dwstatic|dw\.com|euronews|trt\.|trtworld|cgtn|skynews|bbc|alhurra|nhkworld|arirang|channelnewsasia|ndtv|almayadeen|almanar|ekhbariya|kan\.org|najah|aqsa|rt\.com|rttv|abc\.|cbsn|nasa|ert\.gr|rai\.it|tagesschau|zdf|ard)', re.I)

# ─── العيّنات ────────────────────────────────────────────────────────────────
def generated():
    g = lambda id, case, path, note, **k: {'id': id, 'group': 'generated', 'case': case, 'url': f'{BASE}/{path}', 'note': note, 'expect': 'ok', **k}
    S = [
        g('G01', 'P01', 'g01_hls_h264_aac/index.m3u8', 'HLS H.264/AAC'),
        g('G02', 'P02', 'g02_hls_abr/index.m3u8', 'HLS متعدد الجودات 360/720/1080'),
        g('G03', 'P03', 'g03_hls_multiaudio/index.m3u8', 'HLS بمسارَي صوت ara/eng'),
        g('G04', 'P04', 'g04_hls_webvtt/index.m3u8', 'HLS + ترجمة WebVTT'),
        g('G05', 'P05', 'g05_ts_h264_aac/stream.ts', 'MPEG-TS مباشر H.264/AAC'),
        g('G06', 'P06', 'g06_ts_hevc_aac/stream.ts', 'MPEG-TS HEVC/AAC'),
        g('G07', 'P07', 'g07_ts_h264_ac3/stream.ts', 'MPEG-TS H.264/AC3'),
        g('G08', 'P07', 'g08_ts_h264_eac3/stream.ts', 'MPEG-TS H.264/E-AC3'),
        g('G09', 'P08', 'g09_ts_mpeg2_mp2/stream.ts', 'MPEG-TS MPEG-2/MP2 (DVB)'),
        g('G10', 'P06', 'g10_hls_hevc_ac3/index.m3u8', 'HLS HEVC 1080p/AC3'),
        g('G11', 'P05', 'g11_mp4_progressive/video.mp4', 'MP4 تقدّمي'),
        g('G12', 'P05', 'g12_flv_h264_aac/stream.flv', 'FLV عبر HTTP'),
        g('G13', 'P22', 'g13_dash/manifest.mpd', 'DASH'),
        g('G14', 'P20', 'g14_ts_4k_hevc/stream.ts', '4K HEVC', play=10),
        g('G15', 'P01', 'g15_hls_fmp4/index.m3u8', 'HLS بمقاطع fMP4'),
        g('G16', 'P18', 'g16_garbage/stream.ts', 'ملف تالف', expect='fail'),
        g('R09a', 'P09', 'ua/g01_hls_h264_aac/index.m3u8', 'يتطلب User-Agent — مع الترويسة', ua=UA_OK),
        g('R09b', 'P09', 'ua/g01_hls_h264_aac/index.m3u8', 'يتطلب User-Agent — بدونها', expect='fail'),
        g('R10a', 'P10', 'ref/g01_hls_h264_aac/index.m3u8', 'يتطلب Referer — مع الترويسة', ref=REF_OK),
        g('R10b', 'P10', 'ref/g01_hls_h264_aac/index.m3u8', 'يتطلب Referer — بدونها', expect='fail'),
        g('R12', 'P12', 'redir/3/g01_hls_h264_aac/index.m3u8', '3 تحويلات 302 متتالية'),
        g('R14', 'P14', 'notfound', '404', expect='fail'),
        g('R15', 'P15', 'auth/g01_hls_h264_aac/index.m3u8', '401', expect='fail'),
        g('R16', 'P16', 'slow/g01_hls_h264_aac/index.m3u8', 'سيرفر يتأخر 20 ثانية', expect='fail'),
    ]
    S.append({'id': 'R13', 'group': 'generated', 'case': 'P13', 'url': f'{TLS}/g01_hls_h264_aac/index.m3u8',
              'note': 'HTTPS بشهادة موقّعة ذاتيًا', 'expect': 'policy'})
    S.append({'id': 'R21', 'group': 'generated', 'case': 'P21', 'url': RTMP, 'note': 'RTMP (خادم ffmpeg محلي)', 'expect': 'ok', 'rtmp': True})
    return S

def catalog(n_official=30, n_catalog=100, seed=42):
    data = json.load(open(REPO / 'data' / 'demo.json', encoding='utf-8'))
    rows = []
    for c in data['channels']:
        for s in c.get('streams', []):
            rows.append({'uid': c['uid'], 'name': c['name'], 'country': c.get('country'), 'url': s['url']})
    rnd = random.Random(seed)
    rnd.shuffle(rows)
    host = lambda u: (re.match(r'^[a-z]+://([^/:?#]+)', u, re.I) or [None, ''])[1].lower()
    proto = lambda u: 'rtmp' if u.lower().startswith('rtmp') else 'm3u8' if '.m3u8' in u.lower() else 'ts' if re.search(r'\.ts(\?|$)', u, re.I) else 'mpd' if '.mpd' in u.lower() else 'other'
    used_hosts, used_urls, out = {}, set(), []

    def take(pred, n, group, per_host=2):
        k = 0
        for r in rows:
            if k >= n: break
            h = host(r['url'])
            if r['url'] in used_urls or used_hosts.get(h, 0) >= per_host or not pred(r): continue
            used_urls.add(r['url']); used_hosts[h] = used_hosts.get(h, 0) + 1; k += 1
            out.append({'id': f'{group[0].upper()}{len([x for x in out if x["group"] == group]) + 1:03d}', 'group': group,
                        'case': 'catalog', 'url': r['url'], 'note': f"{r['name']} ({r['country']})", 'uid': r['uid'],
                        'country': r['country'], 'proto': proto(r['url']), 'expect': 'unknown'})
        return k

    take(lambda r: OFFICIAL.search(r['url']), n_official, 'official', per_host=3)
    # الكتالوج: نصف عربي ونصف عالمي، مع ضمان تمثيل البروتوكولات غير HLS
    nonhls = take(lambda r: proto(r['url']) != 'm3u8', 10, 'catalog')
    arab = take(lambda r: r['country'] in ARAB, (n_catalog - nonhls) // 2, 'catalog')
    take(lambda r: r['country'] not in ARAB, n_catalog - nonhls - arab, 'catalog')
    return out

# ─── mpv ────────────────────────────────────────────────────────────────────
ERR_PATTERNS = [
    ('auth_failed', r'HTTP error 40[13]|Server returned 40[13]|401 Unauthorized|403 Forbidden'),
    ('unavailable', r'HTTP error 40[4-9]|HTTP error 410|Server returned 404|404 Not Found'),
    ('network_error', r'Could not resolve|Failed to resolve|Connection refused|timed out|Timeout|Connection reset|Network is unreachable|No route'),
    ('network_error', r'TLS|SSL|certificate'),
    ('unsupported', r'Failed to recognize file format|No video or audio streams selected|Could not open codec|Unsupported codec|Invalid data found'),
    ('unavailable', r'HTTP error 5\d\d|Server returned 5'),
]

def classify(text):
    for code, pat in ERR_PATTERNS:
        if re.search(pat, text, re.I): return code
    return 'inconclusive'

def run_mpv(s, play, ff_timeout):
    fd, name = tempfile.mkstemp(suffix='.log'); os.close(fd); log = Path(name)
    url = s['url'] + ('?p=mpv' if '/slow/' in s['url'] else '')
    args = [MPV, '--no-config', '--ytdl=no', '--vo=null', '--ao=null', f'--length={play}', '--network-timeout=15',
            '--msg-level=all=v', f'--log-file={log}', '--demuxer-lavf-o-add=reconnect=1']
    if s.get('ua'): args.append(f'--user-agent={s["ua"]}')
    if s.get('ref'): args.append(f'--referrer={s["ref"]}')
    args.append(url)
    t0 = time.monotonic()
    try:
        subprocess.run(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=ff_timeout + play + 15)
        timed_out = False
    except subprocess.TimeoutExpired:
        timed_out = True
    wall = time.monotonic() - t0
    txt = log.read_text(encoding='utf-8', errors='replace')
    try: log.unlink()
    except OSError: pass
    ts = lambda pat: (lambda m: float(m.group(1)) if m else None)(re.search(r'^\[\s*([\d.]+)\]\[\w\]\[cplayer\] ' + pat, txt, re.M))
    first = ts(r'VO: \[') ; first_audio = ts(r'AO: \[')
    restart = ts(r'playback restart complete')
    exit_m = re.search(r'Exiting\.\.\. \((.*?)\)', txt)
    exit_t = ts(r'Exiting')
    stalls = [float(x) for x in re.findall(r'End buffering \(waited ([\d.]+) secs\)', txt)]
    vcodec = re.search(r'Video\s+--vid=\d+\s+\(\*?\s*([^\s)]+)[^)]*\)', txt)
    acodecs = re.findall(r'Audio\s+--aid=\d+\s+(?:--alang=\S+\s+)?\(\*?\s*([^\s)]+)', txt)
    res = re.search(r'VO: \[\w+\] (\d+x\d+)', txt)
    nsub = len(re.findall(r'Subs\s+--sid=\d+', txt))
    played = (exit_t - restart) if (restart is not None and exit_t is not None) else 0.0
    start = first if first is not None else (first_audio if restart is not None else None)
    errors = '\n'.join(l for l in txt.splitlines() if re.search(r'\]\[(e|w)\]', l))[-1500:]
    return {
        'first_frame': start, 'video': first is not None, 'played': round(played, 2), 'max_stall': max(stalls, default=0.0),
        'exit': exit_m.group(1) if exit_m else ('timeout' if timed_out else 'unknown'), 'wall': round(wall, 2),
        'vcodec': vcodec.group(1) if vcodec else None, 'acodecs': acodecs, 'resolution': res.group(1) if res else None,
        'audio_tracks': len(acodecs), 'sub_tracks': nsub, 'err_class': None if start is not None else classify(errors + ' ' + (exit_m.group(1) if exit_m else '')),
        'err_tail': errors[-400:] if start is None else '',
    }

# ─── VLC ────────────────────────────────────────────────────────────────────
def run_vlc(s, play, ff_timeout):
    url = s['url'] + ('?p=vlc' if '/slow/' in s['url'] else '')
    try:
        r = subprocess.run([sys.executable, str(HERE / 'vlc_probe.py'), url, str(play), str(ff_timeout), s.get('ua', ''), s.get('ref', '')],
                           capture_output=True, text=True, timeout=ff_timeout + play + 20)
        line = (r.stdout.strip().splitlines() or ['{}'])[-1]
        d = json.loads(line)
    except Exception as e:
        d = {'first_frame': None, 'first_play': None, 'played': 0, 'max_stall': 0, 'error': True, 'probe_error': str(e)[:200]}
    d['start'] = d.get('first_frame') if d.get('first_frame') is not None else d.get('first_play')
    return d

# ─── الحكم ───────────────────────────────────────────────────────────────────
def verdict(r, play, ff_timeout):
    start = r.get('first_frame') if 'video' in r else r.get('start')
    if start is None or start > ff_timeout: return False
    need = min(play, s_len(r)) * 0.9
    return r.get('played', 0) >= need and r.get('max_stall', 0) <= 5

def s_len(r): return r.get('_len', 10 ** 9)

def run_one(s, args, rtmp_lock=None):
    play = s.get('play', args.play)
    out = {'mpv': [], 'vlc': []}
    for _ in range(args.attempts):
        for name, fn in (('mpv', run_mpv), ('vlc', run_vlc)):
            srv = None
            if s.get('rtmp'):
                srv = subprocess.Popen([FFMPEG, '-hide_banner', '-loglevel', 'error', '-re', '-stream_loop', '-1', '-i',
                                        str(GEN / 'g05_ts_h264_aac' / 'stream.ts'), '-c', 'copy', '-f', 'flv', '-listen', '1', RTMP],
                                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                time.sleep(1.5)
            try:
                r = fn(s, play, args.ff_timeout)
            finally:
                if srv: srv.kill(); srv.wait()
            r['_len'] = play
            r['ok'] = verdict(r, play, args.ff_timeout)
            out[name].append(r)
    for name in list(out):
        oks = [x['ok'] for x in out[name]]
        out[name + '_ok'] = sum(oks) * 2 > len(oks)  # الأغلبية
    return {**s, **out}

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--only', choices=['generated', 'official', 'catalog'])
    ap.add_argument('--play', type=float, default=20)
    ap.add_argument('--ff-timeout', type=float, default=15)
    ap.add_argument('--attempts', type=int, default=1)
    ap.add_argument('--workers', type=int, default=4)
    args = ap.parse_args()

    OUT.mkdir(parents=True, exist_ok=True)
    samples = generated() + catalog()
    json.dump(samples, open(OUT / 'samples.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    if args.only: samples = [s for s in samples if s['group'] == args.only]

    srv = subprocess.Popen([sys.executable, str(HERE / 'serve.py')], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    time.sleep(2)
    results, t0 = [], time.monotonic()
    normal = [s for s in samples if not s.get('rtmp')]
    try:
        with ThreadPoolExecutor(args.workers) as ex:
            futs = {ex.submit(run_one, s, args): s for s in normal}
            for i, f in enumerate(as_completed(futs), 1):
                r = f.result(); results.append(r)
                print(f'[{i}/{len(samples)}] {r["id"]:5} mpv={"✓" if r["mpv_ok"] else "✗"} vlc={"✓" if r["vlc_ok"] else "✗"}  {r["note"][:50]}', flush=True)
        for s in [s for s in samples if s.get('rtmp')]:
            r = run_one(s, args); results.append(r)
            print(f'[rtmp] {r["id"]} mpv={"✓" if r["mpv_ok"] else "✗"} vlc={"✓" if r["vlc_ok"] else "✗"}', flush=True)
    finally:
        srv.kill()

    results.sort(key=lambda r: (r['group'], r['id']))
    json.dump({'run_at': time.strftime('%Y-%m-%d %H:%M'), 'params': vars(args), 'mpv': subprocess.run([MPV, '--version'], capture_output=True, text=True).stdout.splitlines()[0],
               'duration_min': round((time.monotonic() - t0) / 60, 1), 'results': results},
              open(OUT / 'results.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    with open(OUT / 'results.csv', 'w', newline='', encoding='utf-8-sig') as f:
        w = csv.writer(f)
        w.writerow(['id', 'group', 'case', 'expect', 'note', 'url', 'mpv_ok', 'vlc_ok', 'mpv_first_frame', 'vlc_first_frame', 'mpv_err', 'vcodec', 'acodecs', 'resolution', 'audio_tracks', 'sub_tracks'])
        for r in results:
            m, v = r['mpv'][0], r['vlc'][0]
            w.writerow([r['id'], r['group'], r['case'], r['expect'], r['note'], r['url'], r['mpv_ok'], r['vlc_ok'],
                        m.get('first_frame'), v.get('start'), m.get('err_class'), m.get('vcodec'), '/'.join(m.get('acodecs') or []),
                        m.get('resolution'), m.get('audio_tracks'), m.get('sub_tracks')])
    print(f'\nتم في {round((time.monotonic() - t0) / 60, 1)} دقيقة ← {OUT}')

if __name__ == '__main__':
    main()
