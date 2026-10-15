/// تطبيع الأسماء (§11.1).
///
/// [normName] مطابقة حرفيًا لدالة SQL `public.norm_name` في المخطط الحالي — يجب أن تبقى
/// النتيجتان متطابقتين (اختبار في test/normalize_test.dart)، لأن `dup_key` في قاعدة البيانات
/// مبني عليها.
///
/// [matchKey] أقوى: تضيف توحيد الحروف العربية والأرقام الهندية، وتُستخدم للمطابقة والاقتراح.
library;

final _brackets = RegExp(r'\s*[\(\[][^\)\]]*[\)\]]');
// [[:space:]] | [-_.:'"!?&*/\\|،] | \m(hd|fhd|sd|uhd|4k|tv)\M   (+ نُبقي "+" لأن ATV و ATV+ مختلفتان)
final _noise = RegExp(r"""(\s|[-_.:'"!?&*/\\|،]|\b(?:hd|fhd|sd|uhd|4k|tv)\b)+""");

String normName(String? name) {
  final lower = (name ?? '').toLowerCase();
  return lower.replaceAll(_brackets, '').replaceAll(_noise, '');
}

final _tashkeel = RegExp('[ؐ-ًؚ-ٰٟۖ-ۭـ]'); // تشكيل + تطويل
const _arabicFold = {
  'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا',
  'ة': 'ه', 'ى': 'ي', 'ئ': 'ي', 'ؤ': 'و',
};
const _indicDigits = '٠١٢٣٤٥٦٧٨٩';
const _persianDigits = '۰۱۲۳۴۵۶۷۸۹';

String foldArabic(String s) {
  final b = StringBuffer();
  for (final r in s.replaceAll(_tashkeel, '').runes) {
    final ch = String.fromCharCode(r);
    final i = _indicDigits.indexOf(ch), j = _persianDigits.indexOf(ch);
    b.write(i >= 0 ? '$i' : j >= 0 ? '$j' : (_arabicFold[ch] ?? ch));
  }
  return b.toString();
}

/// مفتاح المطابقة: [normName] بعد توحيد العربية والأرقام.
String matchKey(String? name) => normName(foldArabic(name ?? ''));

final _quality = RegExp(r'\b(4k|2160p|uhd|1080[pi]?|fhd|720p|hd|576[pi]?|480[pi]?|sd)\b', caseSensitive: false);

/// يستخرج الجودة من الاسم: "Al Jazeera (1080p)" → FHD
String? qualityFromName(String name) {
  String? best;
  const rank = {'4K': 4, 'FHD': 3, 'HD': 2, 'SD': 1};
  for (final m in _quality.allMatches(name)) {
    final t = m.group(1)!.toLowerCase();
    final q = (t == '4k' || t == '2160p' || t == 'uhd')
        ? '4K'
        : (t.startsWith('1080') || t == 'fhd')
            ? 'FHD'
            : (t == '720p' || t == 'hd')
                ? 'HD'
                : 'SD';
    if (best == null || rank[q]! > rank[best]!) best = q;
  }
  return best;
}

final _cleanTags = RegExp(r'\s*(\[[^\]]*\]|\((?:\d{3,4}[pi]|4k|geo-?blocked|not 24/7)[^)]*\))', caseSensitive: false);
final _prefix = RegExp(r'^\s*(\|[A-Z]{2,3}\||[A-Z]{2,3}\s*[:|]\s+)');

/// اسم معروض نظيف: يزيل [Geo-blocked] و(1080p) وبادئات مثل "|AR|" و"AR: ".
String cleanDisplayName(String name) =>
    name.replaceAll(_cleanTags, '').replaceFirst(_prefix, '').replaceAll(RegExp(r'\s{2,}'), ' ').trim();

/// بادئة الدولة/اللغة من الاسم إن وُجدت: "|SA| MBC" → "SA"
String? namePrefixCode(String name) {
  final m = RegExp(r'^\s*\|?([A-Z]{2,3})[|:]').firstMatch(name);
  return m?.group(1);
}
