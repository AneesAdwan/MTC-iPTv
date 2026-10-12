// فحص التحديث: يقارن إصدار التطبيق بأحدث إصدار منشور على GitHub Releases.
import { APP_VERSION } from '../appVersion';

const LATEST_API = 'https://api.github.com/repos/AneesAdwan/MTC-iPTv/releases/latest';
export const APK_URL = 'https://github.com/AneesAdwan/MTC-iPTv/releases/latest/download/MTC-iPTv.apk';

const parse = (v) => String(v || '').replace(/^v/i, '').split('.').map(n => parseInt(n, 10) || 0);
function isNewer(remote, local) {
  const a = parse(remote), b = parse(local);
  for (let i = 0; i < 3; i++) { if ((a[i] || 0) > (b[i] || 0)) return true; if ((a[i] || 0) < (b[i] || 0)) return false; }
  return false;
}

// يرجع { available, version, notes, url } أو null عند الفشل/عدم وجود تحديث.
export async function checkUpdate() {
  try {
    const r = await fetch(LATEST_API, { headers: { accept: 'application/vnd.github+json' } });
    if (!r.ok) return null;
    const j = await r.json();
    const version = String(j.tag_name || '').replace(/^v/i, '');
    if (version && isNewer(version, APP_VERSION)) {
      return { available: true, version, notes: j.name || '', url: APK_URL };
    }
    return null;
  } catch { return null; }
}
