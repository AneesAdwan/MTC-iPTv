// عزل الاتجاه داخل النص (§6.4): الأرقام والمعرّفات والروابط تبقى LTR داخل جملة عربية.
// بدون العزل يقلب محرّك الاتجاه «V-02» إلى «02-V» داخل جملة عربية.
// (المحارف تُكتب بأكوادها لا مباشرة: المحارف الخفية في الكود ممنوعة.)

const _lri = 0x2066, _rli = 0x2067, _pdi = 0x2069;

/// يعزل [s] كنص من اليسار لليمين (LRI ... PDI) داخل أي سياق.
String ltr(String s) => '${String.fromCharCode(_lri)}$s${String.fromCharCode(_pdi)}';

/// يعزل [s] كنص من اليمين لليسار (RLI ... PDI) داخل أي سياق.
String rtl(String s) => '${String.fromCharCode(_rli)}$s${String.fromCharCode(_pdi)}';