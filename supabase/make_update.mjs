// يولّد supabase/03_update.sql من 01_schema.sql: نفس البنية لكن بدون حذف أي جدول أو بيانات.
// شغّله بعد أي تعديل على 01_schema.sql:  node supabase/make_update.mjs
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const R = path.dirname(fileURLToPath(import.meta.url)) + '/';
const src = fs.readFileSync(R + '01_schema.sql', 'utf8').split('\n');
const out = [];
let i = 0, inRef = false;

// تخطي الترويسة الأصلية حتى begin;
while (i < src.length && src[i].trim() !== 'begin;') i++;

const header = `-- ════════════════════════════════════════════════════════════════════════════
-- MTC-iPTv — 03_update.sql : ترقية قاعدة البيانات إلى آخر إصدار دون حذف أي بيانات
--
-- لأي قاعدة بُنيت بإصدار أقدم من 01_schema.sql: يضيف الأعمدة الناقصة، ويعيد إنشاء كل الدوال
-- والواجهات والمشغّلات والصلاحيات كما في آخر إصدار. القنوات والروابط والمصادر والإعدادات تبقى كما هي.
-- آمن للتشغيل أكثر من مرة.
--
-- ⚙️ مولّد تلقائيًا من 01_schema.sql — لا تعدّله يدويًا.
-- التشغيل: Supabase Dashboard → SQL Editor → New query → الصق → Run
-- ════════════════════════════════════════════════════════════════════════════`;
out.push(header);

const tableCols = []; // [table, columnDef, colName, hasCheck]
for (; i < src.length; i++) {
  let line = src[i];
  if (line.startsWith('-- ─── 13)')) break; // قسم إضافة المشرف الأول: غير لازم هنا
  if (line.includes('-- @@REFERENCE_DATA_START')) inRef = true;
  if (line.includes('-- @@REFERENCE_DATA_END')) inRef = false;

  // لا نحذف الجداول
  if (/^drop table if exists/.test(line)) { while (!src[i].trim().endsWith(';')) i++; continue; }

  // الجداول: تُنشأ إن لم توجد، ثم تُضاف أعمدتها الناقصة
  const t = line.match(/^create table (?:if not exists )?(public\.\w+) \($/);
  if (t) {
    const table = t[1], block = [line.replace(/^create table (?:if not exists )?/, 'create table if not exists ')];
    const cols = [];
    while (!/^\);/.test(src[++i])) {
      block.push(src[i]);
      const def = src[i].replace(/--.*$/, '').trim().replace(/,$/, '');
      const m = def.match(/^(\w+)\s+(.+)$/);
      if (m && !/^(constraint|primary|unique|check|foreign)$/i.test(m[1])) cols.push([m[1], def]);
    }
    block.push(src[i]);
    out.push(...block);
    for (const [name, def] of cols) {
      if (/primary key/i.test(def)) continue;
      out.push(`alter table ${table} add column if not exists ${def};`);
      const chk = def.match(/check\s*\((.*)\)\s*$/i) || def.match(/check\s*(\(.*\))/i);
      if (chk) {
        // القيد القديم قد يكون أضيق (مثل hidden_reason قبل «pending»): يُستبدل بالجديد
        const cname = `${table.split('.')[1]}_${name}_check`;
        const body = def.slice(def.toLowerCase().indexOf('check'));
        const expr = body.slice(body.indexOf('('));
        let depth = 0, end = 0;
        for (let k = 0; k < expr.length; k++) { if (expr[k] === '(') depth++; if (expr[k] === ')') { depth--; if (!depth) { end = k; break; } } }
        out.push(`alter table ${table} drop constraint if exists ${cname};`);
        out.push(`alter table ${table} add constraint ${cname} check ${expr.slice(0, end + 1)} not valid;`);
      }
    }
    continue;
  }

  // الفهارس
  line = line.replace(/^create index (?!if not exists)/, 'create index if not exists ').replace(/^create unique index (?!if not exists)/, 'create unique index if not exists ');

  // المشغّلات والسياسات: حذف القديم ثم الإنشاء
  const tr = line.match(/^create trigger (\w+) .* on (public\.\w+)/);
  if (tr) out.push(`drop trigger if exists ${tr[1]} on ${tr[2]};`);
  const po = line.match(/^create policy ("[^"]+") on (public\.\w+)/);
  if (po && !out[out.length - 1]?.startsWith(`drop policy if exists ${po[1]} on ${po[2]}`)) out.push(`drop policy if exists ${po[1]} on ${po[2]};`);

  // البيانات المرجعية: يُضاف الناقص فقط
  if (inRef && /\);\s*$/.test(line)) line = line.replace(/\);\s*$/, ') on conflict do nothing;');

  out.push(line);

  // بعد بناء الجداول والفهارس: تاريخ النشر للقنوات المنشورة سابقًا
  if (line.startsWith('create index if not exists reports_channel_idx')) {
    out.push('', '-- القنوات المنشورة قبل وجود تاريخ النشر: تاريخ نشرها = تاريخ إضافتها',
      'update public.channels set published_at = created_at where is_published and hidden_reason is null and published_at is null;');
  }
}
fs.writeFileSync(R + '03_update.sql', out.join('\n').replace(/\n{3,}/g, '\n\n') + '\n');
console.log('03_update.sql:', out.length, 'lines');
