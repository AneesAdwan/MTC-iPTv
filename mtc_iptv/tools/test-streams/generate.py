"""
توليد عيّنات بث اختبارية بـ ffmpeg (ملحق ج.1 — D-04).
كل العيّنات مولّدة محليًا من مصادر اصطناعية (testsrc + sine)، فهي قانونية وثابتة وقابلة لإعادة الاختبار.

الاستخدام:  python generate.py            ← يولّد في ./out
           python generate.py --force    ← يعيد التوليد حتى لو كانت موجودة
"""
import os, shutil, subprocess, sys
from pathlib import Path

OUT = Path(__file__).parent / 'out'
FORCE = '--force' in sys.argv
DUR = 30  # ثانية لكل عيّنة (VOD قصير)

def ff(*args, cwd=None):
    cmd = ['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', *map(str, args)]
    r = subprocess.run(cmd, cwd=cwd)
    if r.returncode:
        raise SystemExit(f'ffmpeg failed: {" ".join(cmd)}')

def src(w=1280, h=720, fps=25, dur=DUR, tone=440):
    return ['-f', 'lavfi', '-i', f'testsrc2=size={w}x{h}:rate={fps}:duration={dur}',
            '-f', 'lavfi', '-i', f'sine=frequency={tone}:sample_rate=48000:duration={dur}']

def job(name, fn):
    d = OUT / name
    if d.exists() and any(d.iterdir()) and not FORCE:
        print(f'  ✓ {name} (موجود)'); return
    if d.exists(): shutil.rmtree(d)
    d.mkdir(parents=True)
    print(f'  … {name}'); fn(d)

H264 = ['-c:v', 'libx264', '-preset', 'veryfast', '-pix_fmt', 'yuv420p', '-g', '50', '-keyint_min', '50', '-sc_threshold', '0']
HEVC = ['-c:v', 'libx265', '-preset', 'ultrafast', '-pix_fmt', 'yuv420p', '-g', '50', '-x265-params', 'log-level=error', '-tag:v', 'hvc1']
AAC = ['-c:a', 'aac', '-b:a', '128k']

def hls(d, extra, name='index.m3u8', seg='seg_%03d.ts', fmp4=False):
    a = ['-f', 'hls', '-hls_time', '4', '-hls_playlist_type', 'vod', '-hls_segment_filename', str(d / seg)]
    if fmp4: a += ['-hls_segment_type', 'fmp4', '-hls_fmp4_init_filename', 'init.mp4']
    ff(*extra, *a, d / name, cwd=d)  # cwd: ffmpeg يكتب ملف init بمسار نسبي

def main():
    if not shutil.which('ffmpeg'): raise SystemExit('ffmpeg غير موجود في PATH')
    OUT.mkdir(exist_ok=True)
    print('توليد العيّنات في', OUT)

    # G01 — HLS عادي H.264/AAC
    job('g01_hls_h264_aac', lambda d: hls(d, [*src(), *H264, *AAC]))

    # G02 — HLS متعدد الجودات (ABR): 360p / 720p / 1080p
    def g02(d):
        ff(*src(1920, 1080), '-filter_complex', '[0:v]split=3[a][b][c];[a]scale=640:360[v0];[b]scale=1280:720[v1];[c]copy[v2]',
           '-map', '[v0]', '-map', '[v1]', '-map', '[v2]', '-map', '1:a', '-map', '1:a', '-map', '1:a',
           *H264, '-b:v:0', '800k', '-b:v:1', '2500k', '-b:v:2', '5000k', *AAC,
           '-f', 'hls', '-hls_time', '4', '-hls_playlist_type', 'vod', '-master_pl_name', 'index.m3u8',
           '-var_stream_map', 'v:0,a:0 v:1,a:1 v:2,a:2', '-hls_segment_filename', str(d / 'v%v_%03d.ts'), d / 'v%v.m3u8')
    job('g02_hls_abr', g02)

    # G03 — HLS بمسارين صوت (عربي/إنجليزي) كـ Alternate Renditions
    def g03(d):
        ff(*src(), '-f', 'lavfi', '-i', f'sine=frequency=880:sample_rate=48000:duration={DUR}',
           '-map', '0:v', '-map', '1:a', '-map', '2:a', *H264, *AAC,
           '-metadata:s:a:0', 'language=ara', '-metadata:s:a:1', 'language=eng',
           '-f', 'hls', '-hls_time', '4', '-hls_playlist_type', 'vod', '-master_pl_name', 'index.m3u8',
           '-var_stream_map', 'v:0,agroup:aud a:0,agroup:aud,language:ara,name:Arabic,default:yes a:1,agroup:aud,language:eng,name:English',
           '-hls_segment_filename', str(d / 's%v_%03d.ts'), d / 's%v.m3u8')
    job('g03_hls_multiaudio', g03)

    # G04 — HLS مع ترجمة WebVTT
    def g04(d):
        srt = d / 'sub.srt'
        srt.write_text(''.join(f'{i+1}\n00:00:{i*5:02d},000 --> 00:00:{i*5+4:02d},000\nسطر ترجمة رقم {i+1}\n\n' for i in range(6)), encoding='utf-8')
        ff(*src(), '-i', srt, '-map', '0:v', '-map', '1:a', '-map', '2:s', *H264, *AAC, '-c:s', 'webvtt',
           '-f', 'hls', '-hls_time', '4', '-hls_playlist_type', 'vod', '-master_pl_name', 'index.m3u8',
           '-var_stream_map', 'v:0,a:0,s:0,sgroup:subs', '-hls_segment_filename', str(d / 'x%v_%03d.ts'), d / 'x%v.m3u8')
    job('g04_hls_webvtt', g04)

    # G05..G09 — MPEG-TS مباشر عبر HTTP بترميزات مختلفة
    job('g05_ts_h264_aac', lambda d: ff(*src(), *H264, *AAC, '-f', 'mpegts', d / 'stream.ts'))
    job('g06_ts_hevc_aac', lambda d: ff(*src(), *HEVC, *AAC, '-f', 'mpegts', d / 'stream.ts'))
    job('g07_ts_h264_ac3', lambda d: ff(*src(), *H264, '-c:a', 'ac3', '-b:a', '192k', '-f', 'mpegts', d / 'stream.ts'))
    job('g08_ts_h264_eac3', lambda d: ff(*src(), *H264, '-c:a', 'eac3', '-b:a', '192k', '-f', 'mpegts', d / 'stream.ts'))
    job('g09_ts_mpeg2_mp2', lambda d: ff(*src(720, 576), '-c:v', 'mpeg2video', '-b:v', '4M', '-c:a', 'mp2', '-b:a', '192k', '-f', 'mpegts', d / 'stream.ts'))

    # G10 — HLS بـ HEVC + AC3 (شائع في قنوات الرياضة)
    job('g10_hls_hevc_ac3', lambda d: hls(d, [*src(1920, 1080), *HEVC, '-c:a', 'ac3', '-b:a', '192k']))

    # G11 — MP4 تقدّمي، G12 — FLV
    job('g11_mp4_progressive', lambda d: ff(*src(), *H264, *AAC, '-movflags', '+faststart', d / 'video.mp4'))
    job('g12_flv_h264_aac', lambda d: ff(*src(), *H264, *AAC, '-f', 'flv', d / 'stream.flv'))

    # G13 — DASH
    job('g13_dash', lambda d: ff(*src(), *H264, *AAC, '-f', 'dash', '-seg_duration', '4', '-use_template', '1', '-use_timeline', '1', 'manifest.mpd', cwd=d))

    # G14 — 4K HEVC (10 ثوانٍ فقط لتقليل وقت الترميز)
    job('g14_ts_4k_hevc', lambda d: ff(*src(3840, 2160, 25, 12), *HEVC, *AAC, '-f', 'mpegts', d / 'stream.ts'))

    # G15 — HLS بمقاطع fMP4
    job('g15_hls_fmp4', lambda d: hls(d, [*src(), *H264, *AAC], seg='seg_%03d.m4s', fmp4=True))

    # G16 — ملف تالف (لاختبار «صيغة غير مدعومة»)
    def g16(d):
        (d / 'stream.ts').write_bytes(os.urandom(2 * 1024 * 1024))
    job('g16_garbage', g16)

    print('تم.')

if __name__ == '__main__':
    main()
