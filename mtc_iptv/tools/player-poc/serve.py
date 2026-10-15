"""
خادم محلي لعيّنات الاختبار المولّدة + قواعد تحاكي حالات الشبكة (ملحق ج.3).

  /<sample>/...               ملف عادي
  /ua/<sample>/...            يرفض (403) إن لم يحتوِ User-Agent على "MTC-Test"           ← P09
  /ref/<sample>/...           يرفض (403) إن لم يكن Referer = https://mtc-test.local/      ← P10
  /redir/<n>/<sample>/...     سلسلة 302 بطول n                                              ← P12
  /notfound                   404                                                         ← P14
  /auth/<sample>/...          401                                                         ← P15
  /slow/<sample>/...          يتأخر 20 ثانية قبل الرد على الطلب الأول                       ← P16
والمنفذ HTTPS (بشهادة موقّعة ذاتيًا) يخدم نفس المحتوى                                     ← P13
"""
import http.server, os, ssl, subprocess, sys, threading, time
from pathlib import Path
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parent.parent / 'test-streams' / 'out'
PORT = int(os.environ.get('POC_PORT', 8791))
TLS_PORT = PORT + 1
_slow_seen = set()
_lock = threading.Lock()

class H(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *a, **k): super().__init__(*a, directory=str(ROOT), **k)
    def log_message(self, *a): pass

    def _rewrite(self, rest):
        self.path = '/' + rest
        return super().do_GET()

    def do_GET(self):
        p = unquote(self.path.split('?')[0]).lstrip('/')
        if p == 'notfound':
            return self.send_error(404)
        if p.startswith('auth/'):
            self.send_response(401); self.send_header('WWW-Authenticate', 'Basic realm="x"'); self.end_headers(); return
        if p.startswith('ua/'):
            if 'MTC-Test' not in (self.headers.get('User-Agent') or ''): return self.send_error(403)
            return self._rewrite(p[3:])
        if p.startswith('ref/'):
            if self.headers.get('Referer') != 'https://mtc-test.local/': return self.send_error(403)
            return self._rewrite(p[4:])
        if p.startswith('redir/'):
            _, n, rest = p.split('/', 2)
            n = int(n)
            self.send_response(302)
            self.send_header('Location', f'/redir/{n-1}/{rest}' if n > 1 else f'/{rest}')
            self.end_headers(); return
        if p.startswith('slow/'):
            with _lock:
                first = p not in _slow_seen
                _slow_seen.add(p)
            if first: time.sleep(20)
            return self._rewrite(p[5:])
        return super().do_GET()

    do_HEAD = do_GET

def make_cert(d: Path):
    crt, key = d / 'self.crt', d / 'self.key'
    if not crt.exists():
        subprocess.run(['openssl', 'req', '-x509', '-newkey', 'rsa:2048', '-nodes', '-days', '30',
                        '-subj', '/CN=localhost', '-keyout', str(key), '-out', str(crt)],
                       check=True, capture_output=True)
    return crt, key

def main():
    srv = http.server.ThreadingHTTPServer(('127.0.0.1', PORT), H)
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    try:
        crt, key = make_cert(Path(__file__).parent)
        tls = http.server.ThreadingHTTPServer(('127.0.0.1', TLS_PORT), H)
        ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER); ctx.load_cert_chain(crt, key)
        tls.socket = ctx.wrap_socket(tls.socket, server_side=True)
        threading.Thread(target=tls.serve_forever, daemon=True).start()
        print(f'https://127.0.0.1:{TLS_PORT}', flush=True)
    except Exception as e:
        print('TLS disabled:', e, file=sys.stderr, flush=True)
    print(f'http://127.0.0.1:{PORT} -> {ROOT}', flush=True)
    try:
        while True: time.sleep(3600)
    except KeyboardInterrupt:
        pass

if __name__ == '__main__':
    main()
