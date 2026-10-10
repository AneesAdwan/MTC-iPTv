// أيقونات SVG خطية موحّدة للموقع ولوحة الإدارة.
const P = {
  home: 'M3 11l9-8 9 8v9a1 1 0 01-1 1h-5v-6H9v6H4a1 1 0 01-1-1z',
  live: 'M2 8.5a14 14 0 0120 0M5.5 12a9 9 0 0113 0M9 15.5a4 4 0 016 0M12 19h.01',
  globe: 'M12 3a9 9 0 100 18 9 9 0 000-18zM3 12h18M12 3c3 3 3 15 0 18M12 3c-3 3-3 15 0 18',
  grid: 'M4 4h7v7H4zM13 4h7v7h-7zM4 13h7v7H4zM13 13h7v7h-7z',
  film: 'M4 4h16v16H4zM8 4v16M16 4v16M4 9h4M4 15h4M16 9h4M16 15h4',
  tv: 'M3 7h18v12H3zM8 3l4 4 4-4',
  search: 'M11 4a7 7 0 100 14 7 7 0 000-14zM21 21l-5-5',
  play: 'M7 4l13 8-13 8z',
  pause: 'M7 4h3v16H7zM14 4h3v16h-3z',
  vol: 'M11 5L6 9H3v6h3l5 4zM16 9a4 4 0 010 6M19 6a8 8 0 010 12',
  mute: 'M11 5L6 9H3v6h3l5 4zM22 9l-6 6M16 9l6 6',
  pip: 'M3 5h18v14H3zM12 12h7v5h-7z',
  fs: 'M4 9V4h5M20 9V4h-5M4 15v5h5M20 15v5h-5',
  back: 'M9 5l7 7-7 7',
  next: 'M15 5l-7 7 7 7',
  x: 'M5 5l14 14M19 5L5 19',
  info: 'M12 3a9 9 0 100 18 9 9 0 000-18zM12 11v6M12 7h.01',
  menu: 'M4 6h16M4 12h16M4 18h16',
  star: 'M12 3l2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1-4.4-4.3 6.1-.9z',
  trash: 'M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3',
  edit: 'M4 20h4L19 9l-4-4L4 16zM14 6l4 4',
  eye: 'M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12zM12 9a3 3 0 100 6 3 3 0 000-6z',
  eyeoff: 'M3 3l18 18M10.6 5.1A10 10 0 0122 12s-1.2 2.1-3.4 4M6.6 6.6C3.7 8.4 2 12 2 12s4 7 10 7a9.6 9.6 0 004.4-1.1M9.9 9.9a3 3 0 004.2 4.2',
  refresh: 'M20 11a8 8 0 10-2.3 5.7M20 4v7h-7',
  plus: 'M12 5v14M5 12h14',
  link: 'M10 14a4 4 0 005.7 0l3-3a4 4 0 00-5.7-5.7l-1 1M14 10a4 4 0 00-5.7 0l-3 3a4 4 0 005.7 5.7l1-1',
  logout: 'M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4M16 17l5-5-5-5M21 12H9',
  check: 'M4 12l5 5L20 6',
  alert: 'M12 3l10 18H2zM12 10v5M12 18h.01',
  copy: 'M9 9h11v11H9zM5 15H4V4h11v1',
  external: 'M14 4h6v6M20 4l-9 9M18 14v6H4V6h6',
  user: 'M12 12a4 4 0 100-8 4 4 0 000 8zM4 21a8 8 0 0116 0',
  zap: 'M13 2L4 14h7l-1 8 9-12h-7z',
  chart: 'M4 20V10M10 20V4M16 20v-7M22 20H2',
  shield: 'M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z',
  settings: 'M12 9a3 3 0 100 6 3 3 0 000-6zM19 12l2-1-1-3-2 .2-1.3-1.3L17 5l-3-1-1 2h-2L10 4 7 5l.3 1.9L6 8.2 4 8l-1 3 2 1v0l-2 1 1 3 2-.2 1.3 1.3L7 19l3 1 1-2h2l1 2 3-1-.3-1.9 1.3-1.3 2 .2 1-3z',
  upload: 'M12 16V4M6 10l6-6 6 6M4 20h16',
  download: 'M12 4v12M6 10l6 6 6-6M4 20h16',
  history: 'M3 12a9 9 0 103-6.7L3 8M3 3v5h5M12 7v5l3 3',
  compare: 'M4 4h7v16H4zM13 4h7v16h-7zM7.5 9v6M16.5 9v6',
  filter: 'M3 5h18l-7 8v6l-4 2v-8z',
  dots: 'M12 5h.01M12 12h.01M12 19h.01',
  ball: 'M12 3a9 9 0 100 18 9 9 0 000-18zM12 7l3.5 2.5-1.3 4h-4.4l-1.3-4zM12 3v4M20.5 9.5l-5 0M3.5 9.5h5M7 19l2.8-5.5M17 19l-2.8-5.5',
  music: 'M9 18V5l11-2v13M9 18a3 3 0 11-6 0 3 3 0 016 0zM20 16a3 3 0 11-6 0 3 3 0 016 0z',
  book: 'M4 5a2 2 0 012-2h13v16H6a2 2 0 00-2 2zM4 5v16M8 7h7',
  sun: 'M12 8a4 4 0 100 8 4 4 0 000-8zM12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4',
  fork: 'M7 3v8M5 3v5a2 2 0 004 0V3M7 11v10M17 3c-2 0-3 2-3 5s1 4 3 4v9',
  car: 'M5 16h14M6 16l1.5-5h9L18 16M5 16v3h2v-3M17 16v3h2v-3M8 13.5h.01M16 13.5h.01',
  bag: 'M6 7h12l1 14H5zM9 7a3 3 0 016 0',
  heart: 'M12 20s-7-4.4-7-10a4 4 0 017-2.6A4 4 0 0119 10c0 5.6-7 10-7 10z',
  list: 'M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01',
  share: 'M18 8a3 3 0 100-6 3 3 0 000 6zM6 15a3 3 0 100-6 3 3 0 000 6zM18 22a3 3 0 100-6 3 3 0 000 6zM8.6 13.5l6.8 4M15.4 6.5l-6.8 4',
  flag: 'M5 21V4M5 4h11l-2 4 2 4H5',
  sort: 'M7 4v16M7 20l-3-3M7 20l3-3M17 20V4M17 4l-3 3M17 4l3 3',
  server: 'M4 4h16v6H4zM4 14h16v6H4zM8 7h.01M8 17h.01',
  layers: 'M12 3l9 5-9 5-9-5zM3 13l9 5 9-5M3 17l9 5 9-5',
  lang: 'M4 5h8M8 3v2M6 5c0 4 3 7 6 8M10 5c-1 4-4 7-7 8M13 21l4-10 4 10M14.5 17h5',
  db: 'M4 6c0-1.7 3.6-3 8-3s8 1.3 8 3-3.6 3-8 3-8-1.3-8-3zM4 6v12c0 1.7 3.6 3 8 3s8-1.3 8-3V6M4 12c0 1.7 3.6 3 8 3s8-1.3 8-3'
};
const FILLED = new Set(['play', 'pause', 'star']);
export const ic = (n, cls = '') =>
  `<svg viewBox="0 0 24 24" class="ic ${cls}" aria-hidden="true" fill="${FILLED.has(n) ? 'currentColor' : 'none'}" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="${P[n] || ''}"/></svg>`;

// الشعار «مدار البث»: زر تشغيل متوهّج تحيط به موجات بث على الجانبين وقمر صناعي يدور في مدار + الكلمة MTC-iPTv
let gid = 0;
export const logoMark = (size = 34) => { const id = `mtcg${++gid}`; return (
  `<svg class="mark" width="${size}" height="${size}" viewBox="0 0 64 64" aria-hidden="true"><defs><linearGradient id="${id}" gradientUnits="userSpaceOnUse" x1="8" y1="8" x2="56" y2="56"><stop offset="0" stop-color="#ff2d55"/><stop offset=".5" stop-color="#ff5a36"/><stop offset="1" stop-color="#ffb02e"/></linearGradient></defs>`
  + `<circle class="mk-rip" cx="32" cy="32" r="11" fill="none" stroke="url(#${id})" stroke-width="2"/><circle cx="32" cy="32" r="12.5" fill="url(#${id})"/><path class="mk-p" d="M28.5 25.5L38.5 32 28.5 38.5Z" fill="#fff" stroke="#fff" stroke-width="3" stroke-linejoin="round"/>`
  + `<g fill="none" stroke="url(#${id})" stroke-width="3.8" stroke-linecap="round"><path class="mk-w" style="--d:0" d="M44.26 21.72A16 16 0 0 1 44.26 42.28M19.74 42.28A16 16 0 0 1 19.74 21.72"/><path class="mk-w" style="--d:1" d="M51.15 15.93A25 25 0 0 1 51.15 48.07M12.85 48.07A25 25 0 0 1 12.85 15.93"/></g>`
  + `<circle cx="32" cy="32" r="27.5" fill="none" stroke="#ff7a1a" stroke-opacity=".25" stroke-width="1" stroke-dasharray="1.5 3"/><g class="mk-orb"><circle cx="32" cy="4.5" r="2.6" fill="#fff"/></g></svg>`); };
export const logo = (sub = '') =>
  `<span class="brand">${logoMark()}<span class="word">MTC<i>-iPTv</i>${sub ? `<small>${sub}</small>` : ''}</span></span>`;
