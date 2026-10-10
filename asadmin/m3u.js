// تحليل ملفات M3U (مثل قوائم iptv-org) إلى عناصر جاهزة لدالة admin_import في قاعدة البيانات.
import { categorySlug, normName } from '../src/catalog.js';

const ATTR = /([\w-]+)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s,]+))/g;

/** "Al Jazeera (1080p) [Geo-blocked]" → { name:'Al Jazeera', quality:'FHD', geo:true } */
function cleanName(raw) {
  const res = raw.match(/\((\d{3,4})p\)/i);
  const h = res ? +res[1] : 0;
  return {
    name: raw.replace(/\([^)]*\)|\[[^\]]*\]/g, '').replace(/\s{2,}/g, ' ').trim() || raw.trim(),
    quality: h >= 2160 ? '4K' : h >= 1080 ? 'FHD' : h >= 720 ? 'HD' : h ? 'SD' : null,
    geo: /geo-?blocked/i.test(raw)
  };
}

/**
 * @param {string} text محتوى ملف M3U
 * @returns {{items: object[], skipped: number}} items: {uid,name,logo,country,category,language,quality,url}
 */
export function parseM3U(text, { skipHttp = true, skipGeo = true } = {}) {
  const out = new Map();
  let meta = '', skipped = 0;
  for (const raw of text.replace(/^﻿/, '').split(/\r?\n/)) {
    const line = raw.trim();
    if (!line) continue;
    if (line.startsWith('#EXTINF:')) { meta = line; continue; }
    if (line.startsWith('#') || !meta) continue;
    const info = meta; meta = '';
    let url;
    try { url = new URL(line); } catch { skipped++; continue; }
    if (!['https:', 'http:'].includes(url.protocol) || (skipHttp && url.protocol === 'http:') || url.href.length > 2000) { skipped++; continue; }

    const attrs = {};
    for (const m of info.matchAll(ATTR)) attrs[m[1].toLowerCase()] = m[2] ?? m[3] ?? m[4] ?? '';
    const comma = info.lastIndexOf(',');
    const display = (comma >= 0 ? info.slice(comma + 1) : '').trim() || attrs['tvg-name'] || '';
    if (!display) { skipped++; continue; }
    const { name, quality, geo } = cleanName(display);
    if (skipGeo && geo) { skipped++; continue; }

    // tvg-id بصيغة iptv-org: "AlJazeera.qa@SD" → المعرّف "AlJazeera.qa" والدولة "QA"
    const tvgId = (attrs['tvg-id'] || '').trim().split('@')[0];
    const country = ((tvgId.match(/\.([a-z]{2})$/i) || [])[1] || (attrs['tvg-country'] || '').split(/[;,]/)[0].trim()).toUpperCase();
    const code = country === 'UK' ? 'GB' : /^[A-Z]{2}$/.test(country) ? country : null;
    const uid = tvgId || `name:${normName(name)}|${code || ''}`;
    if (out.has(url.href)) continue;
    const logo = attrs['tvg-logo'] || '';
    out.set(url.href, {
      uid: uid.slice(0, 300),
      name: name.slice(0, 250),
      logo: /^https?:\/\//i.test(logo) ? logo.replace(/^http:/i, 'https:').slice(0, 2000) : null,
      country: code,
      category: categorySlug(attrs['group-title']),
      language: (attrs['tvg-language'] || '').split(/[;,]/)[0].trim().toLowerCase().slice(0, 3) || null,
      quality,
      url: url.href
    });
  }
  return { items: [...out.values()], skipped };
}
