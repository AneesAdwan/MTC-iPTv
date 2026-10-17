// Bilingual text without code generation: every UI string is a `Tr(arabic, english)` pair, so a
// missing translation is impossible. Arabic is the default language (RTL); English is a live toggle.
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' hide TextDirection;

enum Lang {
  ar,
  en;

  Locale get locale => Locale(name);
  static Lang fromCode(String? code) => code == 'en' ? Lang.en : Lang.ar;
}

@immutable
class Tr {
  final String ar, en;
  const Tr(this.ar, this.en);
  String of(Lang lang) => lang == Lang.en ? en : ar;

  @override
  bool operator ==(Object other) => other is Tr && other.ar == ar && other.en == en;
  @override
  int get hashCode => Object.hash(ar, en);
}

extension TrX on BuildContext {
  Lang get lang => Lang.fromCode(Localizations.maybeLocaleOf(this)?.languageCode);
  String tr(Tr t) => t.of(lang);
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;
}

// Latin digits everywhere, also in Arabic (plan §8).
final _int = NumberFormat.decimalPattern('en');
final _dateTime = DateFormat('yyyy-MM-dd HH:mm', 'en');
final _time = DateFormat('HH:mm', 'en');

String fmtInt(num n) => _int.format(n);
String fmtDateTime(DateTime d) => _dateTime.format(d.toLocal());
String fmtTime(DateTime d) => _time.format(d.toLocal());

/// "37 of 1,204" style counter.
Tr ofTotal(int n, int total) => Tr('${fmtInt(n)} من ${fmtInt(total)}', '${fmtInt(n)} of ${fmtInt(total)}');
