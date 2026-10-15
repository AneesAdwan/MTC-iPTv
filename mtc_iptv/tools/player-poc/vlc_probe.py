"""
يشغّل رابطًا واحدًا في libVLC (المرجع) ويطبع النتيجة JSON. يُشغَّل كعملية منفصلة لكل عيّنة.
  python vlc_probe.py <url> <play_seconds> <first_frame_timeout> [user_agent] [referer]
"""
import json, os, sys, time

VLC_DIR = os.environ.get('VLC_DIR', r'C:\Program Files\VideoLAN\VLC')
if os.path.isdir(VLC_DIR):
    os.add_dll_directory(VLC_DIR)
    os.environ.setdefault('PYTHON_VLC_MODULE_PATH', VLC_DIR)
import vlc  # noqa: E402

def main():
    url, play_s, ff_to = sys.argv[1], float(sys.argv[2]), float(sys.argv[3])
    ua = sys.argv[4] if len(sys.argv) > 4 and sys.argv[4] else None
    ref = sys.argv[5] if len(sys.argv) > 5 and sys.argv[5] else None

    inst = vlc.Instance('--intf=dummy', '--vout=dummy', '--aout=dummy', '--no-video-title-show',
                        '--quiet', '--network-caching=1500')
    media = inst.media_new(url)
    if ua: media.add_option(f':http-user-agent={ua}')
    if ref: media.add_option(f':http-referrer={ref}')
    mp = inst.media_player_new(); mp.set_media(media)

    ev = {'vout': None, 'error': False, 'end': False}
    t0 = time.monotonic()
    em = mp.event_manager()
    em.event_attach(vlc.EventType.MediaPlayerVout, lambda e: ev.__setitem__('vout', ev['vout'] or (time.monotonic() - t0)))
    em.event_attach(vlc.EventType.MediaPlayerEncounteredError, lambda e: ev.__setitem__('error', True))
    em.event_attach(vlc.EventType.MediaPlayerEndReached, lambda e: ev.__setitem__('end', True))
    mp.play()

    first_play = None; last_t = -1; last_adv = None; max_stall = 0.0
    while True:
        now = time.monotonic() - t0
        if ev['error'] or ev['end']: break
        t = mp.get_time()
        if t > 0 and first_play is None:
            first_play = now
        if first_play is not None:
            if t != last_t:
                if last_adv is not None: max_stall = max(max_stall, now - last_adv)
                last_t, last_adv = t, now
            elif now - last_adv > max_stall:
                max_stall = now - last_adv
            if now - first_play >= play_s: break
        elif now > ff_to: break
        time.sleep(0.25)

    played = (time.monotonic() - t0 - first_play) if first_play is not None else 0.0
    tracks = {'video': [], 'audio': []}
    try:
        m = mp.get_media(); m.parse_with_options(vlc.MediaParseFlag.network, 1000)
        for tr in m.tracks_get() or []:
            codec = vlc.libvlc_media_get_codec_description(tr.type, tr.codec) if hasattr(vlc, 'libvlc_media_get_codec_description') else str(tr.codec)
            if isinstance(codec, bytes): codec = codec.decode('utf-8', 'replace')
            if tr.type == vlc.TrackType.video: tracks['video'].append(codec)
            elif tr.type == vlc.TrackType.audio: tracks['audio'].append(codec)
    except Exception:
        pass
    mp.stop(); mp.release(); inst.release()
    print(json.dumps({
        'first_frame': ev['vout'], 'first_play': first_play, 'played': round(played, 2),
        'max_stall': round(max_stall, 2), 'error': ev['error'], 'ended': ev['end'], 'tracks': tracks,
    }))

if __name__ == '__main__':
    main()
