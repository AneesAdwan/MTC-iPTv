// قواعد التحويل (ADM-C6، §10.3 الخطوة 2): قرارات المدير المحفوظة تُطبَّق على كل استيراد قبل المطابقة.
//   group_category  group-title يحتوي النمط ← الفئة (tvg-group → slug)
//   name_country    الاسم أو group-title يحتوي النمط ← الدولة (إن لم تُعرف)
//   name_language   الاسم أو group-title يحتوي النمط ← اللغة (إن لم تُعرف)
//   name_cleanup    إزالة/استبدال نص في الاسم
//   id_map          tvg-id يساوي النمط ← معرّف قناتنا (ربط دائم بقناة موجودة)
// المطابقة نصية غير حساسة لحالة الأحرف، أو تعبير نمطي إن طُلب.
import 'import_parse.dart';

class TransformRule {
  final String kind, pattern, target;
  final bool isRegex;
  const TransformRule(this.kind, this.pattern, this.target, {this.isRegex = false});

  factory TransformRule.fromJson(Map<String, dynamic> j) => TransformRule('${j['kind']}', '${j['pattern']}', '${j['target'] ?? ''}', isRegex: j['is_regex'] == true);

  RegExp get _re => RegExp(isRegex ? pattern : RegExp.escape(pattern), caseSensitive: false);
  bool matches(String? s) {
    if (s == null || s.isEmpty) return false;
    try {
      return _re.hasMatch(s);
    } on FormatException {
      return false; // تعبير نمطي غير صالح: يُتجاهل بدل أن يوقف الاستيراد
    }
  }
}

class RuleOutcome {
  final ImportItem item;
  final String? category; // من group_category
  final String? mappedUid; // من id_map
  final List<String> applied; // للشفافية («لماذا» في المراجعة)
  const RuleOutcome(this.item, this.category, this.mappedUid, this.applied);
}

RuleOutcome applyRules(ImportItem it, List<TransformRule> rules) {
  var item = it;
  String? category, uid;
  final applied = <String>[];
  for (final r in rules) {
    switch (r.kind) {
      case 'name_cleanup':
        if (r.matches(item.name)) {
          try {
            final cleaned = item.name.replaceAll(r._re, r.target).replaceAll(RegExp(r'\s{2,}'), ' ').trim();
            if (cleaned.isNotEmpty && cleaned != item.name) {
              item = item.copyWith(name: cleaned);
              applied.add('cleanup:${r.pattern}');
            }
          } on FormatException {/* تجاهل */}
        }
      case 'group_category':
        if (category == null && r.matches(item.group)) {
          category = r.target;
          applied.add('category:${r.target}');
        }
      case 'name_country':
        if (item.country == null && (r.matches(item.name) || r.matches(item.group) || r.matches(item.rawName))) {
          item = item.copyWith(country: r.target.toUpperCase());
          applied.add('country:${r.target}');
        }
      case 'name_language':
        if (item.language == null && (r.matches(item.name) || r.matches(item.group) || r.matches(item.rawName))) {
          item = item.copyWith(language: r.target.toLowerCase());
          applied.add('language:${r.target}');
        }
      case 'id_map':
        if (uid == null && item.tvgId != null && item.tvgId!.toLowerCase() == r.pattern.toLowerCase()) {
          uid = r.target;
          item = item.copyWith(tvgId: r.target); // المطابقة تجد القناة بمعرّفها
          applied.add('id:${r.target}');
        }
    }
  }
  return RuleOutcome(item, category, uid, applied);
}
