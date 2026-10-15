"""
اختبار «قائمة رئيسية مصغّرة»: بدل تمرير رابط نسخة واحدة (يضيّع مسارات الصوت والترجمة البديلة المعرّفة
بـ #EXT-X-MEDIA)، نبني قائمة رئيسية فيها نسخة واحدة + كل أسطر #EXT-X-MEDIA بروابط مطلقة، ونعطيها لـ mpv
عبر memory://  — فيبقى البدء سريعًا وتبقى المسارات.
  python rendition_test.py <master_url> [...]
"""
import re, sys, tempfile, os, subprocess, urllib.request
from pathlib import Path
from urllib.parse import urljoin

MPV = str(Path.home() / 'scoop/apps/mpv/current/mpv.exe')

def mini_master(url, max_h=1080):
    with urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'}), timeout=8) as r:
        base, text = r.geturl(), r.read().decode('utf-8', 'replace')
    lines = text.splitlines()
    absu = lambda u: urljoin(base, u)
    media = [re.sub(r'URI="([^"]+)"', lambda m: f'URI="{absu(m.group(1))}"', l) for l in lines if l.startswith('#EXT-X-MEDIA')]
    variants = []
    for i, l in enumerate(lines):
        if l.startswith('#EXT-X-STREAM-INF'):
            h = int((re.search(r'RESOLUTION=\d+x(\d+)', l) or [0, 0])[1])
            nxt = next(x.strip() for x in lines[i + 1:] if x.strip() and not x.startswith('#'))
            variants.append((h, l, absu(nxt)))
    pool = [v for v in variants if v[0] <= max_h] or variants
    h, inf, vurl = max(pool, key=lambda v: v[0])
    return '\n'.join(['#EXTM3U', '#EXT-X-VERSION:6', *media, inf, vurl]) + '\n'

def tracks(target):
    fd, log = tempfile.mkstemp(suffix='.log'); os.close(fd)
    subprocess.run([MPV, '--no-config', '--ytdl=no', '--vo=null', '--ao=null', '--frames=30', '--msg-level=all=v', f'--log-file={log}', target],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=60)
    t = Path(log).read_text(encoding='utf-8', errors='replace'); os.unlink(log)
    vo = re.search(r'^\[\s*([\d.]+)\]\[\w\]\[cplayer\] VO:', t, re.M)
    return {'audio': len(re.findall(r'Audio\s+--aid=', t)), 'subs': len(re.findall(r'Subs\s+--sid=', t)),
            'variants_opened': len(re.findall(r"hls: Opening '.*?\.m3u8'", t)) + len(re.findall(r'https?: Opening .*?\.m3u8', t)),
            'first_frame': float(vo.group(1)) if vo else None}

if __name__ == '__main__':
    for u in sys.argv[1:]:
        mm = mini_master(u)
        print(u)
        print('  master as-is   :', tracks(u))
        print('  mini-master    :', tracks('memory://' + mm))
