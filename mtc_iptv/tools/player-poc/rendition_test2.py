"""
محاولة ثانية لـ«قائمة رئيسية مصغّرة»: تُكتب في ملف ويخدمها خادم HTTP محلي (بدل memory://)،
فيقرأ ffmpeg مسارات #EXT-X-MEDIA كما في القائمة الأصلية لكن مع نسخة فيديو واحدة.
  python rendition_test2.py <master_url> [...]
"""
import http.server, os, sys, tempfile, threading
from pathlib import Path

from rendition_test import mini_master, tracks

d = Path(tempfile.mkdtemp())
srv = http.server.ThreadingHTTPServer(('127.0.0.1', 8794), lambda *a, **k: http.server.SimpleHTTPRequestHandler(*a, directory=str(d), **k))
srv.RequestHandlerClass.log_message = lambda *a: None
threading.Thread(target=srv.serve_forever, daemon=True).start()

for i, u in enumerate(sys.argv[1:]):
    (d / f'm{i}.m3u8').write_text(mini_master(u), encoding='utf-8')
    print(u)
    print('  master as-is      :', tracks(u))
    print('  mini via loopback :', tracks(f'http://127.0.0.1:8794/m{i}.m3u8'))
srv.shutdown()
