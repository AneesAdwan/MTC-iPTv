// تخطيط الرئيسية (ADM-B4 ← V-02): «يعرض الآن» وصفوف بأنواع، يحدده المدير في site_settings.home_layout (عام).
// التطبيق يجلبه عند المزامنة ويحفظه محليًا (يعمل دون اتصال)؛ دونه يُستخدم التخطيط الافتراضي.
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/backend/backend.dart';
import '../../core/logging/log.dart';

/// أنواع الصفوف (§9.4).
const homeRowTypes = ['featured', 'history', 'favorites', 'recent', 'categories_auto', 'category', 'country', 'manual', 'all'];

class HomeRow {
  final String type;
  final String? titleAr, titleEn, ref; // ref: slug الفئة أو رمز الدولة
  final List<String> channelIds; // للنوع manual
  final int count;
  final bool visible;
  final DateTime? from, to; // قوائم مختارة بتاريخ (مثل «قنوات رمضان»)

  const HomeRow({required this.type, this.titleAr, this.titleEn, this.ref, this.channelIds = const [], this.count = 20, this.visible = true, this.from, this.to});

  factory HomeRow.fromJson(Map<String, dynamic> j) => HomeRow(
        type: '${j['type']}',
        titleAr: j['title_ar'] as String?,
        titleEn: j['title_en'] as String?,
        ref: j['ref'] as String?,
        channelIds: [for (final x in (j['channel_ids'] as List?) ?? const []) '$x'],
        count: (j['count'] as num?)?.toInt() ?? 20,
        visible: j['visible'] != false,
        from: DateTime.tryParse('${j['from']}'),
        to: DateTime.tryParse('${j['to']}'),
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'title_ar': ?titleAr,
        'title_en': ?titleEn,
        'ref': ?ref,
        if (channelIds.isNotEmpty) 'channel_ids': channelIds,
        'count': count,
        'visible': visible,
        if (from != null) 'from': from!.toIso8601String().substring(0, 10),
        if (to != null) 'to': to!.toIso8601String().substring(0, 10),
      };

  HomeRow copyWith({String? type, String? titleAr, String? titleEn, String? ref, List<String>? channelIds, int? count, bool? visible, DateTime? from, DateTime? to, bool clearDates = false}) =>
      HomeRow(
        type: type ?? this.type,
        titleAr: titleAr ?? this.titleAr,
        titleEn: titleEn ?? this.titleEn,
        ref: ref ?? this.ref,
        channelIds: channelIds ?? this.channelIds,
        count: count ?? this.count,
        visible: visible ?? this.visible,
        from: clearDates ? null : (from ?? this.from),
        to: clearDates ? null : (to ?? this.to),
      );

  /// ظاهر الآن؟ (الإخفاء والتواريخ؛ «إلى» شامل لليوم كله).
  bool activeAt(DateTime t) => visible && (from == null || !t.isBefore(from!)) && (to == null || t.isBefore(to!.add(const Duration(days: 1))));
}

class HomeLayout {
  final List<String> hero; // قنوات «يعرض الآن» (تتناوب)
  final List<HomeRow> rows;
  const HomeLayout({this.hero = const [], this.rows = const []});

  /// الافتراضي = ترتيب الرئيسية قبل ADM-B4.
  static const fallback = HomeLayout(rows: [
    HomeRow(type: 'featured'),
    HomeRow(type: 'history', count: 12),
    HomeRow(type: 'recent'),
    HomeRow(type: 'categories_auto', count: 8),
    HomeRow(type: 'all'),
  ]);

  factory HomeLayout.fromJson(Map<String, dynamic> j) => HomeLayout(
        hero: [for (final x in (j['hero'] as List?) ?? const []) '$x'],
        rows: [for (final r in (j['rows'] as List?) ?? const []) if (homeRowTypes.contains((r as Map)['type'])) HomeRow.fromJson(r.cast<String, dynamic>())],
      );

  Map<String, dynamic> toJson() => {'version': 1, 'hero': hero, 'rows': [for (final r in rows) r.toJson()]};
}

/// يجلب التخطيط بعد مزامنة الكتالوج ويحفظه في SyncState.
final homeLayoutSyncProvider = FutureProvider<void>((ref) async {
  await ref.watch(startupSyncProvider.future);
  final client = ref.watch(supabaseProvider);
  if (client == null) return;
  try {
    final r = await client.from('site_settings').select('value').eq('key', 'home_layout').maybeSingle();
    final db = ref.read(catalogDbProvider);
    if (r == null) {
      await (db.delete(db.syncState)..where((s) => s.key.equals('home_layout'))).go();
    } else {
      await db.setSyncValue('home_layout', jsonEncode(r['value']));
    }
  } catch (e) {
    log.warning('home layout fetch failed', e);
  }
});

final homeLayoutProvider = StreamProvider<HomeLayout>((ref) {
  ref.watch(homeLayoutSyncProvider);
  final db = ref.watch(catalogDbProvider);
  return (db.select(db.syncState)..where((s) => s.key.equals('home_layout'))).watchSingleOrNull().map((row) {
    if (row == null) return HomeLayout.fallback;
    try {
      final l = HomeLayout.fromJson((jsonDecode(row.value) as Map).cast<String, dynamic>());
      return l.rows.isEmpty && l.hero.isEmpty ? HomeLayout.fallback : l;
    } catch (_) {
      return HomeLayout.fallback;
    }
  });
});
