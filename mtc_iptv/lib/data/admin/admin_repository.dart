// بيانات مركز الإدارة (المرحلة 4): قراءة وكتابة مباشرة على Supabase بصلاحية المدير.
// الحماية الحقيقية على الخادم (RLS)؛ هنا فقط الاستعلامات.
// الكتابة بالأعمدة الجديدة (publish_state، name_ar/en، health_state) ومشغّلات التوافق تحدّث القديمة.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/backend/backend.dart';

const publishStates = ['published', 'pending', 'hidden', 'draft', 'rejected'];
const healthStates = ['playable', 'reachable', 'degraded', 'auth_failed', 'unsupported', 'network_error', 'unavailable', 'geo_restricted', 'inconclusive', 'disabled'];

/// حالات تُعدّ «تعمل» في عمود (تعمل/الكل).
const workingStates = {'playable', 'reachable', 'degraded'};

class AdminStream {
  final String id, channelId, url;
  final String? label, quality, userAgent, referrer, healthReason, protocol;
  final int priority;
  final String healthState;
  final int? healthScore, httpStatus, responseMs;
  final bool hasCredentials;
  final Map<String, dynamic> headers;
  final DateTime? lastCheckedAt;
  const AdminStream({
    required this.id,
    required this.channelId,
    required this.url,
    this.label,
    this.quality,
    this.userAgent,
    this.referrer,
    this.healthReason,
    this.protocol,
    this.priority = 0,
    this.healthState = 'inconclusive',
    this.healthScore,
    this.httpStatus,
    this.responseMs,
    this.hasCredentials = false,
    this.headers = const {},
    this.lastCheckedAt,
  });

  factory AdminStream.fromJson(Map<String, dynamic> j) => AdminStream(
        id: j['id'] as String,
        channelId: j['channel_id'] as String,
        url: j['url'] as String,
        label: j['label'] as String?,
        quality: j['quality'] as String?,
        userAgent: j['user_agent'] as String?,
        referrer: j['referrer'] as String?,
        healthReason: j['health_reason'] as String?,
        protocol: j['protocol'] as String?,
        priority: (j['priority'] as num?)?.toInt() ?? 0,
        healthState: (j['health_state'] as String?) ?? 'inconclusive',
        healthScore: (j['health_score'] as num?)?.toInt(),
        httpStatus: (j['http_status'] as num?)?.toInt(),
        responseMs: (j['response_ms'] as num?)?.toInt(),
        hasCredentials: j['has_credentials'] == true,
        headers: (j['headers'] as Map?)?.cast<String, dynamic>() ?? const {},
        lastCheckedAt: DateTime.tryParse('${j['last_checked_at']}')?.toLocal(),
      );

  Map<String, String> get requestHeaders => {
        for (final e in headers.entries) e.key: '${e.value}',
        'User-Agent': ?userAgent,
        'Referer': ?referrer,
      };

  bool get working => workingStates.contains(healthState);

  /// الرابط مع إخفاء بيانات الاعتماد (§19.4): /live/user/pass/1.ts ← /live/••••/••••/1.ts، ‏?password=… ← ••••
  String get maskedUrl {
    if (!hasCredentials) return url;
    var u = url.replaceAllMapped(RegExp(r'//[^/@]+@'), (_) => '//••••@');
    u = u.replaceAllMapped(RegExp(r'([?&](?:username|user|password|pass|token|key)=)[^&]+', caseSensitive: false), (m) => '${m[1]}••••');
    u = u.replaceAllMapped(RegExp(r'/(live|movie|series)/[^/]+/[^/]+/'), (m) => '/${m[1]}/••••/••••/');
    return u;
  }
}

class AdminChannel {
  final String id, uid;
  final int? number;
  final String name;
  final String? nameAr, nameEn, network, logoUrl, countryCode, categorySlug, languageCode, quality, description, website, epgId;
  final List<String> altNames;
  final String publishState;
  final bool isFeatured, isManual, parentalLocked;
  final int epgOffset;
  final DateTime? updatedAt;

  /// سلة المحذوفات (0007)
  final DateTime? trashedAt;
  final String? trashReason;
  final List<String> streamStates; // health_state لكل رابط (للعمود تعمل/الكل)

  const AdminChannel({
    required this.id,
    required this.uid,
    required this.name,
    this.number,
    this.nameAr,
    this.nameEn,
    this.network,
    this.logoUrl,
    this.countryCode,
    this.categorySlug,
    this.languageCode,
    this.quality,
    this.description,
    this.website,
    this.epgId,
    this.altNames = const [],
    this.publishState = 'published',
    this.isFeatured = false,
    this.isManual = false,
    this.parentalLocked = false,
    this.epgOffset = 0,
    this.updatedAt,
    this.trashedAt,
    this.trashReason,
    this.streamStates = const [],
  });

  factory AdminChannel.fromJson(Map<String, dynamic> j) => AdminChannel(
        id: j['id'] as String,
        uid: j['uid'] as String,
        number: (j['number'] as num?)?.toInt(),
        name: (j['name'] as String?) ?? '',
        nameAr: j['name_ar'] as String?,
        nameEn: j['name_en'] as String?,
        network: j['network'] as String?,
        logoUrl: j['logo_url'] as String?,
        countryCode: j['country_code'] as String?,
        categorySlug: j['category_slug'] as String?,
        languageCode: j['language_code'] as String?,
        quality: j['quality'] as String?,
        description: j['description'] as String?,
        website: j['website'] as String?,
        epgId: j['epg_id'] as String?,
        altNames: [for (final x in (j['alt_names'] as List?) ?? const []) '$x'],
        publishState: (j['publish_state'] as String?) ?? 'published',
        isFeatured: j['is_featured'] == true,
        isManual: j['is_manual'] == true,
        parentalLocked: j['parental_locked'] == true,
        epgOffset: (j['epg_offset_minutes'] as num?)?.toInt() ?? 0,
        updatedAt: DateTime.tryParse('${j['updated_at']}')?.toLocal(),
        trashedAt: j['trashed_at'] == null ? null : DateTime.tryParse('${j['trashed_at']}')?.toLocal(),
        trashReason: j['trash_reason'] as String?,
        streamStates: [for (final s in (j['streams'] as List?) ?? const []) '${(s as Map)['health_state']}'],
      );

  String displayName(String lang) => lang == 'ar' ? (nameAr ?? nameEn ?? name) : (nameEn ?? nameAr ?? name);
  int get streamsOk => streamStates.where(workingStates.contains).length;
}

class ChannelQuery {
  final String search;
  final String? state, country, category;
  final bool featured, noLogo, manual;

  /// سلة المحذوفات (0007): القنوات فيها لا تظهر إلا بهذا الفلتر.
  final bool trash;
  final int page;
  static const pageSize = 50;
  const ChannelQuery({this.search = '', this.state, this.country, this.category, this.featured = false, this.noLogo = false, this.manual = false, this.trash = false, this.page = 0});

  ChannelQuery copyWith({String? search, String? state, String? country, String? category, bool? featured, bool? noLogo, bool? manual, bool? trash, int? page, bool clearState = false, bool clearCountry = false, bool clearCategory = false}) =>
      ChannelQuery(
        search: search ?? this.search,
        state: clearState ? null : (state ?? this.state),
        country: clearCountry ? null : (country ?? this.country),
        category: clearCategory ? null : (category ?? this.category),
        featured: featured ?? this.featured,
        noLogo: noLogo ?? this.noLogo,
        manual: manual ?? this.manual,
        trash: trash ?? this.trash,
        page: page ?? 0, // أي تغيير في الفلاتر يعيد للصفحة الأولى
      );

  @override
  bool operator ==(Object other) =>
      other is ChannelQuery &&
      other.search == search &&
      other.state == state &&
      other.country == country &&
      other.category == category &&
      other.featured == featured &&
      other.noLogo == noLogo &&
      other.manual == manual &&
      other.trash == trash &&
      other.page == page;
  @override
  int get hashCode => Object.hash(search, state, country, category, featured, noLogo, manual, trash, page);
}

class ChannelPage {
  final List<AdminChannel> items;
  final int total;
  const ChannelPage(this.items, this.total);
}

class ReportGroup {
  final String channelId;
  final String channelName;
  final int? number;
  final List<Map<String, dynamic>> reports; // المفتوحة، الأحدث أولًا
  const ReportGroup(this.channelId, this.channelName, this.number, this.reports);
}

class AuditEntry {
  final DateTime at;
  final String action, table;
  final String? reason; // manual | import | merge | migration | restore | sync
  final Map<String, dynamic>? before, after;
  const AuditEntry(this.at, this.action, this.table, this.reason, this.before, this.after);

  /// الحقول التي تغيّرت (دون حقول النظام).
  List<(String, Object?, Object?)> get changes {
    const skip = {'updated_at', 'catalog_rev', 'created_at'};
    final keys = {...?before?.keys, ...?after?.keys}..removeAll(skip);
    return [
      for (final k in keys)
        if ('${before?[k]}' != '${after?[k]}') (k, before?[k], after?[k]),
    ];
  }
}

class Dashboard {
  final Map<String, int> channelsByState, streamsByHealth;
  final int openReports, epgChannels;
  final List<AuditEntry> recent;

  /// من قياس المشاهدين (0005): null = الترحيل غير مطبّق أو العيّنة غير كافية.
  final int? attempts24h, activeDevices7, openAlerts;
  final double? successRate24h;
  const Dashboard(this.channelsByState, this.streamsByHealth, this.openReports, this.epgChannels, this.recent,
      {this.attempts24h, this.successRate24h, this.activeDevices7, this.openAlerts});
  int get channels => channelsByState.values.fold(0, (a, b) => a + b);
  int get streams => streamsByHealth.values.fold(0, (a, b) => a + b);
}

class AdminRepository {
  final SupabaseClient db;
  AdminRepository(this.db);

  static const _channelCols =
      'id,uid,number,name,name_ar,name_en,alt_names,network,logo_url,country_code,category_slug,language_code,quality,description,website,epg_id,publish_state,is_featured,is_manual,parental_locked,epg_offset_minutes,updated_at,trashed_at,trash_reason';
  static const _streamCols =
      'id,channel_id,url,label,quality,priority,user_agent,referrer,headers,protocol,has_credentials,health_state,health_reason,health_score,http_status,response_ms,last_checked_at';

  /// كل الصفوف على صفحات (PostgREST يعيد 1000 صف كحد أقصى في الطلب الواحد على Supabase).
  /// [page] يجب أن يرتّب بمفتاح فريد ليكون التقسيم ثابتًا.
  Future<List<Map<String, dynamic>>> _all(PostgrestTransformBuilder<PostgrestList> Function(int from, int to) page) async {
    const size = 1000;
    final out = <Map<String, dynamic>>[];
    for (var from = 0;; from += size) {
      final rows = await page(from, from + size - 1);
      out.addAll(rows);
      if (rows.length < size) return out;
    }
  }

  // ── لوحة المعلومات ───────────────────────────────────────────────────────
  Future<Dashboard> dashboard() async {
    final ch = <String, int>{};
    final st = <String, int>{};
    await Future.wait([
      for (final s in publishStates) db.from('channels').count().eq('publish_state', s).then((n) => ch[s] = n),
      for (final s in healthStates) db.from('streams').count().eq('health_state', s).then((n) => st[s] = n),
    ]);
    final reports = await db.from('reports').count().eq('status', 'open');
    // تغطية EPG: القنوات المنشورة التي لها برامج خلال 24 ساعة (§9.3)
    final now = DateTime.now().toUtc();
    final epgRows = await _all((a, b) => db
        .from('epg_programmes')
        .select('channel_uid,start_at')
        .gte('end_at', now.toIso8601String())
        .lte('start_at', now.add(const Duration(hours: 24)).toIso8601String())
        .order('channel_uid', ascending: true)
        .order('start_at', ascending: true)
        .range(a, b));
    final uids = {for (final r in epgRows) r['channel_uid'] as String};
    final published = await _all((a, b) => db.from('channels').select('uid').eq('publish_state', 'published').order('id', ascending: true).range(a, b));
    final covered = published.where((r) => uids.contains(r['uid'])).length;
    // §9.3: نسبة النجاح من أحداث آخر 24 ساعة (تُعرض فقط بعيّنة ≥ 100)، والأجهزة النشطة 7 أيام، والتنبيهات الجديدة
    int? attempts, ok, devices, alerts;
    try {
      final since = now.subtract(const Duration(hours: 24)).toIso8601String();
      attempts = await db.from('playback_events').count().gte('at', since).neq('outcome', 'abandoned');
      ok = await db.from('playback_events').count().gte('at', since).eq('outcome', 'success');
      // عمود صريح: المدير لا يملك قراءة push_token، و count() يطلب كل الأعمدة
      devices = (await db.from('installations').select('id').gte('last_seen_at', now.subtract(const Duration(days: 7)).toIso8601String()).limit(1).count(CountOption.exact)).count;
      alerts = await openAlerts();
    } catch (_) {
      // الترحيل 0005 غير مطبّق بعد
    }
    return Dashboard(ch, st, reports, covered, await recentAudit(limit: 10),
        attempts24h: attempts,
        successRate24h: attempts != null && attempts >= 100 && ok != null ? ok / attempts : null,
        activeDevices7: devices,
        openAlerts: alerts);
  }

  Future<List<AuditEntry>> recentAudit({int limit = 10, String? rowId}) async {
    var q = db.from('audit_logs').select('at,action,table_name,reason,before,after');
    if (rowId != null) q = q.eq('row_id', rowId);
    final rows = await q.order('at', ascending: false).limit(limit);
    return [
      for (final r in rows)
        AuditEntry(DateTime.parse(r['at'] as String).toLocal(), r['action'] as String, r['table_name'] as String, r['reason'] as String?,
            (r['before'] as Map?)?.cast<String, dynamic>(), (r['after'] as Map?)?.cast<String, dynamic>()),
    ];
  }

  // ── القنوات ──────────────────────────────────────────────────────────────
  /// فلاتر القائمة (للصفحة ولـ «تحديد كل النتائج»).
  PostgrestFilterBuilder<T> _channelFilters<T>(PostgrestFilterBuilder<T> f, ChannelQuery q) {
    f = q.trash ? f.not('trashed_at', 'is', null) : f.isFilter('trashed_at', null);
    if (q.state != null) f = f.eq('publish_state', q.state!);
    if (q.country != null) f = f.eq('country_code', q.country!);
    if (q.category != null) f = f.eq('category_slug', q.category!);
    if (q.featured) f = f.eq('is_featured', true);
    if (q.manual) f = f.eq('is_manual', true);
    if (q.noLogo) f = f.isFilter('logo_url', null);
    final s = q.search.trim();
    if (s.isNotEmpty) {
      final n = int.tryParse(s);
      final like = '%${s.replaceAll(RegExp(r'[,()%*]'), ' ')}%';
      f = n != null ? f.eq('number', n) : f.or('name.ilike.$like,name_ar.ilike.$like,name_en.ilike.$like,uid.ilike.$like,network.ilike.$like');
    }
    return f;
  }

  Future<ChannelPage> channels(ChannelQuery q) async {
    final f = _channelFilters(db.from('channels').select('$_channelCols,streams(health_state)'), q);
    final from = q.page * ChannelQuery.pageSize;
    final res = await f.order('number', ascending: true, nullsFirst: false).order('name', ascending: true).range(from, from + ChannelQuery.pageSize - 1).count(CountOption.exact);
    return ChannelPage([for (final r in res.data) AdminChannel.fromJson(r)], res.count);
  }

  Future<AdminChannel?> channel(String id) async {
    final r = await db.from('channels').select('$_channelCols,streams(health_state)').eq('id', id).maybeSingle();
    return r == null ? null : AdminChannel.fromJson(r);
  }

  Future<void> updateChannel(String id, Map<String, dynamic> fields) => db.from('channels').update(fields).eq('id', id);

  Future<void> updateChannels(List<String> ids, Map<String, dynamic> fields) => db.from('channels').update(fields).inFilter('id', ids);

  /// كل معرّفات القنوات المطابقة للفلاتر (كل الصفحات) — «تحديد كل النتائج» (خطة التحسينات 4.1).
  Future<List<String>> channelIds(ChannelQuery q) async =>
      [for (final r in await _all((a, b) => _channelFilters(db.from('channels').select('id'), q).order('id', ascending: true).range(a, b))) r['id'] as String];

  // ── سلة المحذوفات (0007): لا حذف فوري من اللوحة ──
  Future<int> trashChannels(List<String> ids, {String? reason}) async =>
      ((await db.rpc('admin_trash', params: {'p_ids': ids, 'p_reason': reason})) as num).toInt();

  Future<int> restoreChannels(List<String> ids) async => ((await db.rpc('admin_restore', params: {'p_ids': ids})) as num).toInt();

  /// حذف نهائي لقنوات من السلة فقط (الدالة ترفض ما ليس في السلة).
  Future<int> purgeChannels(List<String> ids) async => ((await db.rpc('admin_trash_purge', params: {'p_ids': ids})) as num).toInt();

  /// ما مضى عليه 30 يومًا في السلة (المُجدوِل).
  Future<int> purgeExpiredTrash() async => ((await db.rpc('admin_trash_purge')) as num).toInt();

  /// إضافة يدوية (§9.4): تتجاوز المراجعة، معلَّمة يدوية.
  Future<String> createChannel({required String nameAr, required String nameEn, int? number, String? country, String? category, String? logoUrl}) async {
    final name = nameEn.trim().isNotEmpty ? nameEn.trim() : nameAr.trim();
    final r = await db
        .from('channels')
        .insert({
          'uid': 'manual:${DateTime.now().microsecondsSinceEpoch}',
          'name': name,
          if (nameAr.trim().isNotEmpty) 'name_ar': nameAr.trim(),
          if (nameEn.trim().isNotEmpty) 'name_en': nameEn.trim(),
          'number': ?number,
          'country_code': ?country,
          'category_slug': ?category,
          if (logoUrl != null && logoUrl.trim().isNotEmpty) 'logo_url': logoUrl.trim(),
          'is_manual': true,
          'is_published': true,
          'published_at': DateTime.now().toUtc().toIso8601String(),
        })
        .select('id')
        .single();
    final id = r['id'] as String;
    // بوابة المراجعة (channels_review_gate) تجعل كل إدراج «قيد المراجعة» ولو أرسلنا is_published؛
    // الإضافة اليدوية راجعها المدير بنفسه، فتُنشر فورًا (كانت تذهب لقيد المراجعة — اكتُشف باختبار 2026-10-16)
    await db.from('channels').update({'publish_state': 'published'}).eq('id', id);
    return id;
  }

  Future<int?> nextFreeNumber() async {
    final r = await db.from('channels').select('number').not('number', 'is', null).order('number', ascending: false).limit(1);
    return r.isEmpty ? 1 : ((r.first['number'] as num).toInt() + 1);
  }

  // ── الروابط ──────────────────────────────────────────────────────────────
  Future<List<AdminStream>> streamsOf(String channelId) async {
    final rows = await db.from('streams').select(_streamCols).eq('channel_id', channelId).order('priority', ascending: true).order('created_at', ascending: true);
    return [for (final r in rows) AdminStream.fromJson(r)];
  }

  /// روابط حالة صحية معيّنة مع اسم قناتها ورقمها وحالة نشرها ('trash' إن كانت في السلة) —
  /// ليعرف المدير أي رابط يعمل وقناته ليست في التطبيق بعد.
  Future<List<(AdminStream, String, int?, String)>> streamsByHealth(String state, {int limit = 500}) async {
    final rows = await db
        .from('streams')
        .select('$_streamCols,channels(name,name_ar,name_en,number,publish_state,trashed_at)')
        .eq('health_state', state)
        .order('last_checked_at', ascending: true, nullsFirst: true)
        .limit(limit);
    return [
      for (final r in rows)
        (
          AdminStream.fromJson(r),
          '${(r['channels'] as Map?)?['name_ar'] ?? (r['channels'] as Map?)?['name'] ?? ''}',
          ((r['channels'] as Map?)?['number'] as num?)?.toInt(),
          (r['channels'] as Map?)?['trashed_at'] != null ? 'trash' : '${(r['channels'] as Map?)?['publish_state'] ?? ''}',
        ),
    ];
  }

  /// «إضافة للنظام»: نشر قنوات (ما في السلة يُسترجع أولًا). يعيد عدد القنوات.
  Future<int> publishChannels(List<String> ids) async {
    if (ids.isEmpty) return 0;
    await restoreChannels(ids); // لا يفعل شيئًا لما ليس في السلة
    await updateChannels(ids, {'publish_state': 'published'});
    return ids.length;
  }

  Future<void> addStream(String channelId, {required String url, String? label, String? userAgent, String? referrer, int priority = 0}) => db.from('streams').insert({
        'channel_id': channelId,
        'url': url.trim(),
        if (label != null && label.trim().isNotEmpty) 'label': label.trim(),
        if (userAgent != null && userAgent.trim().isNotEmpty) 'user_agent': userAgent.trim(),
        if (referrer != null && referrer.trim().isNotEmpty) 'referrer': referrer.trim(),
        'priority': priority,
      });

  Future<void> updateStream(String id, Map<String, dynamic> fields) => db.from('streams').update(fields).eq('id', id);

  Future<void> deleteStreams(List<String> ids) => db.from('streams').delete().inFilter('id', ids);

  /// ترتيب الأولوية حسب القائمة (0 أولًا).
  Future<void> reorderStreams(List<String> ids) async {
    for (var i = 0; i < ids.length; i++) {
      await db.from('streams').update({'priority': i}).eq('id', ids[i]);
    }
  }

  /// نتيجة فحص (§12.2): لا تُكتب على رابط معطّل يدويًا (D-14: لا قرار تلقائي).
  Future<void> recordHealth(String id, {required String state, required String reason, int? http, int? ms, int? score}) => db
      .from('streams')
      .update({
        'health_state': state,
        'health_reason': reason.length > 300 ? reason.substring(0, 300) : reason,
        'health_score': score,
        'http_status': http,
        'response_ms': ms,
        'last_checked_at': DateTime.now().toUtc().toIso8601String(),
      })
      .eq('id', id)
      .neq('health_state', 'disabled');

  // ── البلاغات ─────────────────────────────────────────────────────────────
  Future<List<ReportGroup>> openReports() async {
    final rows = await db
        .from('reports')
        .select('id,channel_id,stream_id,reason,note,created_at,channels(name,name_ar,number)')
        .eq('status', 'open')
        .order('created_at', ascending: false)
        .limit(1000);
    final groups = <String, ReportGroup>{};
    for (final r in rows) {
      final id = r['channel_id'] as String;
      final ch = (r['channels'] as Map?) ?? const {};
      (groups[id] ??= ReportGroup(id, '${ch['name_ar'] ?? ch['name'] ?? id}', (ch['number'] as num?)?.toInt(), [])).reports.add(r);
    }
    return groups.values.toList()..sort((a, b) => b.reports.length.compareTo(a.reports.length));
  }

  Future<void> resolveReports(String channelId) => db.from('reports').update({'status': 'resolved'}).eq('channel_id', channelId).eq('status', 'open');

  // ── المرجع ───────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> countries() => db.from('countries').select('code,name_ar,name_en,flag_emoji').order('sort_order', ascending: true);
  Future<List<Map<String, dynamic>>> categories() => db.from('categories').select('slug,name_ar,name_en').order('sort_order', ascending: true);

  // ── قيد المراجعة (ADM-D1): العرض review_queue والدوال الموجودة في الإنتاج ──
  Future<Map<String, int>> reviewCounts() async {
    final rows = await _all((a, b) => db.from('review_queue').select('id,bucket').order('id', ascending: true).range(a, b));
    final m = <String, int>{};
    for (final r in rows) {
      m['${r['bucket']}'] = (m['${r['bucket']}'] ?? 0) + 1;
    }
    return m;
  }

  Future<(List<Map<String, dynamic>>, int)> reviewItems(String bucket, {int page = 0, int size = 50}) async {
    final res = await db
        .from('review_queue')
        .select('id,number,name,uid,logo_url,logo_status,quality,country_code,category_slug,total,online,unchecked,duplicate_of,created_at')
        .eq('bucket', bucket)
        .order('created_at', ascending: true)
        .order('id', ascending: true)
        .range(page * size, page * size + size - 1)
        .count(CountOption.exact);
    return (res.data, res.count);
  }

  Future<List<String>> reviewIds(String bucket) async => [for (final r in await _all((a, b) => db.from('review_queue').select('id').eq('bucket', bucket).order('id', ascending: true).range(a, b))) r['id'] as String];

  /// approve نشر · reject حذف نهائي · merge دمج المكررة في أصلها.
  Future<int> reviewApply(String action, List<String> ids) async => ((await db.rpc('admin_review_apply', params: {'p_action': action, 'p_ids': ids})) as num).toInt();

  /// «ليست مكررة»: مفتاح تكرار خاص بكل قناة.
  Future<int> markDistinct(List<String> ids) async => ((await db.rpc('admin_mark_distinct', params: {'p_ids': ids})) as num).toInt();

  Future<Map<String, String>> channelNames(List<String> ids) async {
    if (ids.isEmpty) return const {};
    final rows = await db.from('channels').select('id,name,name_ar,number').inFilter('id', ids);
    return {for (final r in rows) r['id'] as String: '${r['number'] ?? '—'} · ${r['name_ar'] ?? r['name']}'};
  }

  // ── الترقيم (ADM-B7): admin_renumber_* (ذري على الخادم) ───────────────────
  Map<String, dynamic> _renumberParams(List<String> keys, int start, int block, bool publishedFirst) =>
      {'p_keys': keys, 'p_start': start, 'p_block': block, 'p_published_first': publishedFirst};

  Future<Map<String, dynamic>> renumberPreview(List<String> keys, {int start = 1, int block = 0, bool publishedFirst = true, int limit = 200}) async =>
      Map<String, dynamic>.from(await db.rpc('admin_renumber_preview', params: {..._renumberParams(keys, start, block, publishedFirst), 'p_limit': limit}) as Map);

  Future<int> renumberApply(List<String> keys, {int start = 1, int block = 0, bool publishedFirst = true}) async =>
      ((await db.rpc('admin_renumber_apply', params: _renumberParams(keys, start, block, publishedFirst))) as num).toInt();

  // ── التقسيمات (ADM-B5) ───────────────────────────────────────────────────
  static const taxonomyKey = {'categories': 'slug', 'countries': 'code', 'languages': 'code'};
  static const _channelColumn = {'categories': 'category_slug', 'countries': 'country_code', 'languages': 'language_code'};

  Future<List<Map<String, dynamic>>> taxonomy(String table) => db.from(table).select().order('sort_order', ascending: true).order(taxonomyKey[table]!, ascending: true);

  /// عدد القنوات لكل عنصر (لعرضه ولمنع حذف المستخدم).
  Future<Map<String, int>> taxonomyUsage(String table) async {
    final col = _channelColumn[table]!;
    final rows = await _all((a, b) => db.from('channels').select('id,$col').not(col, 'is', null).order('id', ascending: true).range(a, b));
    final m = <String, int>{};
    for (final r in rows) {
      m['${r[col]}'] = (m['${r[col]}'] ?? 0) + 1;
    }
    return m;
  }

  Future<void> upsertTaxonomy(String table, Map<String, dynamic> row) => db.from(table).upsert(row, onConflict: taxonomyKey[table]);
  Future<void> deleteTaxonomy(String table, String key) => db.from(table).delete().eq(taxonomyKey[table]!, key);

  // ── الروابط والسيرفرات (ADM-B3) ──────────────────────────────────────────
  Future<(List<(AdminStream, String, int?)>, int)> streams({String host = '', String? state, String? protocol, bool credentialsOnly = false, int page = 0, int size = 100}) async {
    var f = db.from('streams').select('$_streamCols,channels(name,name_ar,number)');
    if (host.trim().isNotEmpty) f = f.ilike('host', '%${host.trim().replaceAll(RegExp(r'[%*,()]'), '')}%');
    if (state != null) f = f.eq('health_state', state);
    if (protocol != null) f = f.eq('protocol', protocol);
    if (credentialsOnly) f = f.eq('has_credentials', true);
    final res = await f.order('host', ascending: true).order('priority', ascending: true).range(page * size, page * size + size - 1).count(CountOption.exact);
    return (
      [
        for (final r in res.data)
          (AdminStream.fromJson(r), '${(r['channels'] as Map?)?['name_ar'] ?? (r['channels'] as Map?)?['name'] ?? ''}', ((r['channels'] as Map?)?['number'] as num?)?.toInt()),
      ],
      res.count,
    );
  }

  /// معرّفات كل الروابط المطابقة للفلاتر (كل الصفحات) — «تحديد كل النتائج» (4.1).
  Future<List<String>> streamIds({String host = '', String? state, String? protocol, bool credentialsOnly = false}) async {
    final rows = await _all((a, b) {
      var f = db.from('streams').select('id');
      if (host.trim().isNotEmpty) f = f.ilike('host', '%${host.trim().replaceAll(RegExp(r'[%*,()]'), '')}%');
      if (state != null) f = f.eq('health_state', state);
      if (protocol != null) f = f.eq('protocol', protocol);
      if (credentialsOnly) f = f.eq('has_credentials', true);
      return f.order('id', ascending: true).range(a, b);
    });
    return [for (final r in rows) r['id'] as String];
  }

  Future<List<AdminStream>> streamsByIds(List<String> ids) async {
    final out = <AdminStream>[];
    for (var i = 0; i < ids.length; i += 200) {
      final part = ids.sublist(i, (i + 200).clamp(0, ids.length));
      out.addAll([for (final r in await db.from('streams').select(_streamCols).inFilter('id', part)) AdminStream.fromJson(r)]);
    }
    return out;
  }

  /// ملخّص النطاقات: عدد الروابط والعاملة لكل نطاق.
  Future<List<(String, int, int)>> hosts() async {
    final rows = await _all((a, b) => db.from('streams').select('id,host,health_state').order('id', ascending: true).range(a, b));
    final total = <String, int>{}, ok = <String, int>{};
    for (final r in rows) {
      final h = '${r['host'] ?? '?'}';
      total[h] = (total[h] ?? 0) + 1;
      if (workingStates.contains(r['health_state'])) ok[h] = (ok[h] ?? 0) + 1;
    }
    return [for (final e in total.entries) (e.key, e.value, ok[e.key] ?? 0)]..sort((a, b) => b.$2.compareTo(a.$2));
  }

  // ── المكررات والدمج (ADM-D2، §11.4) ──────────────────────────────────────
  /// مجموعات (نفس الاسم المطبّع + الدولة) من admin_duplicates في الإنتاج.
  Future<List<Map<String, dynamic>>> duplicates() async => [for (final g in (await db.rpc('admin_duplicates') as List)) Map<String, dynamic>.from(g as Map)];

  /// دمج **قابل للتراجع** (§11.4): الروابط والبلاغات المفتوحة تنتقل للأساسية، والمدموجة تبقى مخفية بـ merged_into
  /// (لا تُحذف كما في admin_merge القديمة). [keepFields]: الحقول المختارة من المدموجة لتُكتب على الأساسية.
  Future<void> mergeChannels(String keep, List<String> remove, {Map<String, dynamic> keepFields = const {}}) async {
    final others = remove.where((x) => x != keep).toList();
    if (others.isEmpty) return;
    // رقم مأخوذ من مدموجة: يُفرغ منها أولًا (الأرقام فريدة)
    if (keepFields.containsKey('number')) await db.from('channels').update({'number': null}).inFilter('id', others).eq('number', keepFields['number']);
    await db.from('streams').update({'channel_id': keep}).inFilter('channel_id', others);
    await db.from('reports').update({'channel_id': keep}).inFilter('channel_id', others).eq('status', 'open');
    await db.from('channels').update({'publish_state': 'hidden', 'hidden_reason': 'duplicate', 'merged_into': keep}).inFilter('id', others);
    if (keepFields.isNotEmpty) await updateChannel(keep, keepFields);
  }

  /// التراجع عن دمج: تُعاد الروابط التي نقلها الدمج (من سجل التدقيق) وتُستعاد حالة النشر السابقة.
  Future<int> unmerge(String mergedId) async {
    final ch = await db.from('channels').select('merged_into').eq('id', mergedId).single();
    final keep = ch['merged_into'] as String?;
    if (keep == null) return 0;
    final moves = await db
        .from('audit_logs')
        .select('row_id,before,after')
        .eq('table_name', 'streams')
        .eq('action', 'UPDATE')
        .eq('before->>channel_id', mergedId)
        .eq('after->>channel_id', keep)
        .limit(5000);
    final ids = {for (final m in moves) m['row_id'] as String}.toList();
    if (ids.isNotEmpty) await db.from('streams').update({'channel_id': mergedId}).inFilter('id', ids).eq('channel_id', keep);
    final before = await db
        .from('audit_logs')
        .select('before')
        .eq('table_name', 'channels')
        .eq('row_id', mergedId)
        .eq('after->>merged_into', keep)
        .order('at', ascending: false)
        .limit(1);
    final prev = before.isEmpty ? 'pending' : '${(before.first['before'] as Map?)?['publish_state'] ?? 'pending'}';
    await db.from('channels').update({'merged_into': null, 'duplicate_of': null, 'publish_state': prev == 'hidden' ? 'pending' : prev}).eq('id', mergedId);
    return ids.length;
  }

  Future<List<AdminChannel>> mergedInto(String keep) async =>
      [for (final r in await db.from('channels').select('$_channelCols,streams(health_state)').eq('merged_into', keep)) AdminChannel.fromJson(r)];

  Future<int> hideDuplicates(String keep, List<String> hide) async => ((await db.rpc('admin_hide_duplicates', params: {'p_keep': keep, 'p_hide': hide})) as num).toInt();

  Future<List<AdminChannel>> channelsByIds(List<String> ids) async =>
      ids.isEmpty ? const [] : [for (final r in await db.from('channels').select('$_channelCols,streams(health_state)').inFilter('id', ids)) AdminChannel.fromJson(r)];

  // ── الشعارات (ADM-D5) ────────────────────────────────────────────────────
  /// [status]: broken | unknown | ok | missing (بلا شعار).
  Future<List<AdminChannel>> channelsByLogo(String status, {int limit = 1000}) async {
    var f = db.from('channels').select('$_channelCols,logo_status,streams(health_state)');
    f = status == 'missing' ? f.isFilter('logo_url', null) : f.eq('logo_status', status).not('logo_url', 'is', null);
    final rows = await f.order('number', ascending: true, nullsFirst: false).limit(limit);
    return [for (final r in rows) AdminChannel.fromJson(r)];
  }

  Future<Map<String, int>> logoCounts() async {
    final m = <String, int>{};
    await Future.wait([
      for (final s in ['ok', 'broken', 'unknown']) db.from('channels').count().eq('logo_status', s).not('logo_url', 'is', null).then((n) => m[s] = n),
      db.from('channels').count().isFilter('logo_url', null).then((n) => m['missing'] = n),
    ]);
    return m;
  }

  Future<int> recordLogos(List<(String, bool)> results) async =>
      ((await db.rpc('admin_record_logos', params: {'p_results': [for (final (id, ok) in results) {'id': id, 'ok': ok}]})) as num).toInt();

  // ── الشبكات (ADM-B6) ─────────────────────────────────────────────────────
  /// (الشبكة، عدد القنوات، شعار ممثّل).
  Future<List<(String, int, String?)>> networks() async {
    final rows = await _all((a, b) => db.from('channels').select('id,network,logo_url').not('network', 'is', null).order('id', ascending: true).range(a, b));
    final n = <String, int>{}, logo = <String, String?>{};
    for (final r in rows) {
      final k = '${r['network']}'.trim();
      if (k.isEmpty) continue;
      n[k] = (n[k] ?? 0) + 1;
      logo[k] ??= r['logo_url'] as String?;
    }
    return [for (final e in n.entries) (e.key, e.value, logo[e.key])]..sort((a, b) => b.$2.compareTo(a.$2));
  }

  Future<void> renameNetwork(String from, String? to) => db.from('channels').update({'network': (to == null || to.trim().isEmpty) ? null : to.trim()}).eq('network', from);

  // ── العرض في الرئيسية (ADM-B4): site_settings.home_layout (عام للتطبيقات) ──
  Future<Map<String, dynamic>?> homeLayout() async {
    final r = await db.from('site_settings').select('value').eq('key', 'home_layout').maybeSingle();
    return (r?['value'] as Map?)?.cast<String, dynamic>();
  }

  Future<void> saveHomeLayout(Map<String, dynamic> layout) async {
    await db.from('site_settings').upsert({'key': 'home_layout', 'value': layout, 'is_public': true, 'updated_at': DateTime.now().toUtc().toIso8601String()});
    // توافق: الموقع القديم يقرأ hero.channel_id (قناة واحدة)
    final hero = (layout['hero'] as List?)?.cast<String>() ?? const [];
    await db.from('site_settings').upsert({'key': 'hero', 'value': {'channel_id': hero.isEmpty ? null : hero.first}, 'is_public': true});
  }

  // ── الاستيراد (ADM-C1/C2/C3، §10) ─────────────────────────────────────────
  /// فهرس المطابقة: كل القنوات (حقول المطابقة فقط) وكل الروابط.
  Future<(List<Map<String, dynamic>>, List<Map<String, dynamic>>)> matchingCatalog() async => (
        await _all((a, b) => db.from('channels').select('id,uid,name,name_ar,name_en,alt_names,country_code,epg_id,publish_state').order('id', ascending: true).range(a, b)),
        await _all((a, b) => db.from('streams').select('id,url,channel_id,source_id').order('id', ascending: true).range(a, b)),
      );

  /// admin_import في الإنتاج: القنوات الجديدة تمرّ ببوابة المراجعة (تصبح «قيد المراجعة» دائمًا، §10.4)،
  /// والموجودة (بنفس uid) لا تتغير بياناتها — يُضاف الرابط فقط ويُملأ الشعار إن كان فارغًا.
  Future<(int, int)> importItems(String? sourceId, List<Map<String, dynamic>> items) async {
    var ch = 0, st = 0;
    for (var i = 0; i < items.length; i += 500) {
      final r = Map<String, dynamic>.from(await db.rpc('admin_import',
          params: {'p_source': sourceId, 'p_items': items.sublist(i, (i + 500).clamp(0, items.length)), 'p_publish': true}) as Map);
      ch += (r['channels'] as num?)?.toInt() ?? 0;
      st += (r['streams'] as num?)?.toInt() ?? 0;
    }
    return (ch, st);
  }

  /// ترويسات الروابط (admin_import لا يستقبلها).
  Future<void> setStreamHeaders(String url, {String? userAgent, String? referrer, Map<String, String> headers = const {}}) => db
      .from('streams')
      .update({'user_agent': ?userAgent, 'referrer': ?referrer, if (headers.isNotEmpty) 'headers': headers})
      .eq('url', url);

  // ── المصادر (ADM-C3) ─────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> sources() => db.from('playlist_sources').select().order('name', ascending: true);

  Future<String> addSource(String name, String url) async =>
      (await db.from('playlist_sources').insert({'name': name.trim(), 'url': url.trim(), 'auto_publish': false}).select('id').single())['id'] as String;

  Future<void> updateSource(String id, Map<String, dynamic> fields) => db.from('playlist_sources').update(fields).eq('id', id);

  /// حذف المصدر **دون** حذف روابطه وقنواته (§10.4 «لا حذف»؛ القيد الأصلي cascade كان سيحذفها).
  Future<void> removeSource(String id) async {
    await db.from('streams').update({'source_id': null}).eq('source_id', id);
    await db.from('playlist_sources').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> sourceStreams(String id) =>
      _all((a, b) => db.from('streams').select('id,url,health_state').eq('source_id', id).order('id', ascending: true).range(a, b));

  Future<void> markSourceImported(String id) async {
    final s = await sourceStreams(id);
    final chans = await _all((a, b) => db.from('streams').select('id,channel_id').eq('source_id', id).order('id', ascending: true).range(a, b));
    await updateSource(id, {
      'status': 'ready',
      'last_error': null,
      'last_import_at': DateTime.now().toUtc().toIso8601String(),
      'stream_count': s.length,
      'channel_count': {for (final r in chans) r['channel_id']}.length,
    });
  }

  // ── التصدير (ADM-C5) ─────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> exportRows({String? state, String? country, String? category}) => _all((a, b) {
        var f = db.from('channels').select(
            'id,uid,number,name,name_ar,name_en,logo_url,country_code,category_slug,language_code,epg_id,publish_state,streams(url,user_agent,referrer,label,health_state,has_credentials,priority)');
        if (state != null) f = f.eq('publish_state', state);
        if (country != null) f = f.eq('country_code', country);
        if (category != null) f = f.eq('category_slug', category);
        return f.order('number', ascending: true, nullsFirst: false).order('id', ascending: true).range(a, b);
      });

  // ── دليل البرامج (ADM-E1/E2/E3) — يتطلب الترحيل 0004 ─────────────────────
  Future<List<Map<String, dynamic>>> epgSources() => db.from('epg_sources').select().order('priority', ascending: true).order('name', ascending: true);
  Future<void> upsertEpgSource(Map<String, dynamic> row) => db.from('epg_sources').upsert(row);
  Future<void> deleteEpgSource(String id) => db.from('epg_sources').delete().eq('id', id);

  /// القنوات المنشورة مع حقول المطابقة.
  Future<List<Map<String, dynamic>>> epgTargets() => _all((a, b) =>
      db.from('channels').select('id,uid,epg_id,name,name_ar,name_en,alt_names,number,logo_url,epg_offset_minutes').eq('publish_state', 'published').order('id', ascending: true).range(a, b));

  /// المعرّفات (uid) التي لها برامج خلال 24 ساعة.
  Future<Set<String>> uidsWithProgrammes() async {
    final now = DateTime.now().toUtc();
    final rows = await _all((a, b) => db
        .from('epg_programmes')
        .select('channel_uid,start_at')
        .gte('end_at', now.toIso8601String())
        .lte('start_at', now.add(const Duration(hours: 24)).toIso8601String())
        .order('channel_uid', ascending: true)
        .order('start_at', ascending: true)
        .range(a, b));
    return {for (final r in rows) r['channel_uid'] as String};
  }

  Future<int> epgUpsert(List<Map<String, dynamic>> rows) async {
    var n = 0;
    for (var i = 0; i < rows.length; i += 500) {
      n += ((await db.rpc('admin_epg_upsert', params: {'p_rows': rows.sublist(i, (i + 500).clamp(0, rows.length))})) as num).toInt();
    }
    return n;
  }

  Future<void> epgFinish(String sourceId, {required String status, required int channels, required int programmes, String? error}) =>
      db.rpc('admin_epg_finish', params: {'p_source': sourceId, 'p_status': status, 'p_channels': channels, 'p_programmes': programmes, 'p_error': error});

  Future<List<Map<String, dynamic>>> epgDay(String uid, DateTime day) async =>
      [for (final r in await db.rpc('epg_day', params: {'p_uid': uid, 'p_day': day.toIso8601String().substring(0, 10)}) as List) Map<String, dynamic>.from(r as Map)];

  // ── قواعد التحويل (ADM-C6) ───────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> transformRules() => db.from('transform_rules').select().order('kind', ascending: true).order('priority', ascending: true);
  Future<void> upsertRule(Map<String, dynamic> row) => db.from('transform_rules').upsert(row);
  Future<void> deleteRule(String id) => db.from('transform_rules').delete().eq('id', id);

  // ── حسابات Xtream (Vault) ────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> xtreamAccounts() => db.from('xtream_accounts').select('id,name,server,username,enabled,last_import_at').order('name', ascending: true);
  Future<String> saveXtream(String name, String server, String user, String pass) async =>
      (await db.rpc('admin_xtream_save', params: {'p_name': name, 'p_server': server, 'p_username': user, 'p_password': pass})) as String;
  Future<String?> xtreamPassword(String id) async => (await db.rpc('admin_xtream_password', params: {'p_id': id})) as String?;
  Future<void> deleteXtream(String id) => db.rpc('admin_xtream_delete', params: {'p_id': id});

  // ── سجل التدقيق (ADM-H3) ─────────────────────────────────────────────────
  Future<(List<AuditEntry>, List<Map<String, dynamic>>, int)> auditSearch({String? table, String? action, String? rowId, int page = 0, int size = 100}) async {
    var f = db.from('audit_logs').select('id,at,action,table_name,row_id,reason,before,after');
    if (table != null) f = f.eq('table_name', table);
    if (action != null) f = f.eq('action', action);
    if (rowId != null && rowId.trim().isNotEmpty) f = f.eq('row_id', rowId.trim());
    final res = await f.order('at', ascending: false).range(page * size, page * size + size - 1).count(CountOption.exact);
    return (
      [
        for (final r in res.data)
          AuditEntry(DateTime.parse(r['at'] as String).toLocal(), r['action'] as String, r['table_name'] as String, r['reason'] as String?,
              (r['before'] as Map?)?.cast<String, dynamic>(), (r['after'] as Map?)?.cast<String, dynamic>()),
      ],
      res.data,
      res.count,
    );
  }

  // ── قوائم المُجدوِل (ADM-H2) ─────────────────────────────────────────────
  /// روابط القنوات المنشورة (غير المعطّلة) — فحص الوصول كل 6 ساعات.
  Future<List<AdminStream>> publishedStreams() async => [
        for (final r in await _all((a, b) => db
            .from('streams')
            .select('$_streamCols,channels!inner(publish_state)')
            .eq('channels.publish_state', 'published')
            .neq('health_state', 'disabled')
            .order('id', ascending: true)
            .range(a, b)))
          AdminStream.fromJson(r),
      ];

  Future<List<AdminStream>> allStreams() async => [
        for (final r in await _all((a, b) => db.from('streams').select(_streamCols).neq('health_state', 'disabled').order('id', ascending: true).range(a, b))) AdminStream.fromJson(r),
      ];

  /// عيّنة دوّارة للتشغيل الحقيقي: الأقدم فحصًا أولًا (§17: 200 يوميًا).
  Future<List<AdminStream>> playbackSample({int size = 200}) async => [
        for (final r in await db.from('streams').select(_streamCols).neq('health_state', 'disabled').order('last_checked_at', ascending: true, nullsFirst: true).limit(size))
          AdminStream.fromJson(r),
      ];

  Future<List<Map<String, dynamic>>> channelsWithLogos() =>
      _all((a, b) => db.from('channels').select('id,logo_url').not('logo_url', 'is', null).order('id', ascending: true).range(a, b));

  Future<bool> acquireTask(String key, String device) async => (await db.rpc('admin_task_acquire', params: {'p_key': key, 'p_device': device})) == true;
  Future<void> finishTask(String key, String device, String status) => db.rpc('admin_task_finish', params: {'p_key': key, 'p_device': device, 'p_status': status});
  Future<void> updateTask(String key, Map<String, dynamic> fields) => db.from('scheduled_tasks').update(fields).eq('key', key);

  // ── النسخ الاحتياطي والاستعادة (ADM-H4، §21) ─────────────────────────────
  /// الجداول المشمولة ومفتاح ترتيب ثابت لكل منها (§21.1). كلمات مرور Xtream في Vault لا تُصدَّر (§21.1).
  static const backupTables = {
    'languages': 'code',
    'countries': 'code',
    'categories': 'slug',
    'channels': 'id',
    'streams': 'id',
    'channel_field_provenance': 'channel_id',
    'playlist_sources': 'id',
    'site_settings': 'key',
    'scheduled_tasks': 'key',
    'epg_sources': 'id',
    'transform_rules': 'id',
    'xtream_accounts': 'id',
    'reports': 'id',
    'admin_users': 'user_id',
    'audit_logs': 'id',
  };

  /// ما تمكن استعادته بالإضافة/التحديث (الجداول ذات المعرّف المولّد دائمًا لا تُستعاد: audit_logs، reports).
  static const restorableTables = ['languages', 'countries', 'categories', 'channels', 'streams', 'playlist_sources', 'site_settings', 'epg_sources', 'transform_rules'];

  /// أعمدة يولّدها الخادم ولا تُكتب.
  static const _generated = {
    'streams': {'host', 'protocol', 'has_credentials', 'catalog_rev'},
    'countries': {'flag_url'},
    'channels': {'catalog_rev'},
  };

  Future<List<Map<String, dynamic>>> dumpTable(String table) async {
    final key = backupTables[table]!;
    if (table == 'audit_logs') {
      // الاحتفاظ 365 يومًا (§9.10)
      final since = DateTime.now().toUtc().subtract(const Duration(days: 365)).toIso8601String();
      return _all((a, b) => db.from(table).select().gte('at', since).order(key, ascending: true).range(a, b));
    }
    if (table == 'xtream_accounts') return _all((a, b) => db.from(table).select('id,name,server,username,enabled,last_import_at,created_at').order(key, ascending: true).range(a, b));
    return _all((a, b) => db.from(table).select().order(key, ascending: true).range(a, b));
  }

  Future<int> tableCount(String table) => db.from(table).count();

  /// استعادة بالإضافة/التحديث فقط (upsert) — لا تحذف أي صف أحدث من النسخة.
  Future<int> restoreUpsert(String table, List<Map<String, dynamic>> rows) async {
    final skip = _generated[table] ?? const <String>{};
    final clean = [for (final r in rows) {for (final e in r.entries) if (!skip.contains(e.key)) e.key: e.value}];
    for (var i = 0; i < clean.length; i += 500) {
      await db.from(table).upsert(clean.sublist(i, (i + 500).clamp(0, clean.length)), onConflict: backupTables[table]);
    }
    return clean.length;
  }

  // ── المهام (ADM-A2) ──────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> taskRuns({int limit = 100}) =>
      db.from('task_runs').select('id,task_key,device,started_at,finished_at,status,summary,error').order('started_at', ascending: false).limit(limit);

  Future<List<Map<String, dynamic>>> scheduledTasks() => db.from('scheduled_tasks').select().order('key', ascending: true);

  /// تسجيل تشغيل يدوي (يظهر في ADM-A2). يتطلب جلسة مدير بتحقق بخطوتين.
  Future<int?> startRun(String taskKey, String device) async {
    final r = await db.from('task_runs').insert({'task_key': taskKey, 'device': device}).select('id').single();
    return (r['id'] as num).toInt();
  }

  Future<void> finishRun(int id, {required String status, Map<String, dynamic> summary = const {}, String? error}) => db
      .from('task_runs')
      .update({'status': status, 'finished_at': DateTime.now().toUtc().toIso8601String(), 'summary': summary, 'error': error})
      .eq('id', id);

  // ── القياس والتجميع (0005) ────────────────────────────────────────────────
  static String _day(DateTime d) => d.toUtc().toIso8601String().substring(0, 10);

  Future<Map<String, dynamic>> telemetryRollup(DateTime from) async =>
      ((await db.rpc('admin_telemetry_rollup', params: {'p_from': _day(from)})) as Map).cast<String, dynamic>();

  /// التجميعات اليومية منذ [from] (صف لكل يوم × رابط × منصّة × دولة).
  Future<List<Map<String, dynamic>>> playbackStats(DateTime from) => _all((a, b) => db
      .from('playback_stats_daily')
      .select()
      .gte('day', _day(from))
      .order('day', ascending: true)
      .order('stream_id', ascending: true)
      .order('platform', ascending: true)
      .order('country', ascending: true)
      .range(a, b));

  /// الأجهزة التي ظهرت منذ [since] (بلا رمز Push: لا يقرؤه المدير).
  Future<List<Map<String, dynamic>>> installations(DateTime since) => _all((a, b) => db
      .from('installations')
      .select('id,platform,app_version,locale,country,first_seen_at,last_seen_at')
      .gte('last_seen_at', since.toUtc().toIso8601String())
      .order('id', ascending: true)
      .range(a, b));

  /// النطاق (host) لكل رابط — لتجميع النجاح حسب الخادم دون نقل الروابط.
  Future<Map<String, String>> streamHosts(Iterable<String> ids) async {
    final out = <String, String>{};
    final list = ids.toList();
    for (var i = 0; i < list.length; i += 200) {
      final rows = await db.from('streams').select('id,host').inFilter('id', list.sublist(i, (i + 200).clamp(0, list.length)));
      for (final r in rows) {
        out['${r['id']}'] = '${r['host'] ?? ''}';
      }
    }
    return out;
  }

  /// للتحليلات: الاسمان والرقم، على دفعات (قد تكون مئات القنوات).
  Future<List<Map<String, dynamic>>> channelRows(Iterable<String> ids) async {
    final list = ids.toList();
    final out = <Map<String, dynamic>>[];
    for (var i = 0; i < list.length; i += 200) {
      out.addAll(await db.from('channels').select('id,number,name,name_ar,name_en').inFilter('id', list.sublist(i, (i + 200).clamp(0, list.length))));
    }
    return out;
  }

  Future<List<Map<String, dynamic>>> reportsSince(DateTime since) => _all((a, b) =>
      db.from('reports').select('id,channel_id,reason,status,created_at').gte('created_at', since.toUtc().toIso8601String()).order('id', ascending: true).range(a, b));

  Future<List<Map<String, dynamic>>> runsSince(DateTime since) => _all((a, b) =>
      db.from('task_runs').select('id,task_key,status,started_at').gte('started_at', since.toUtc().toIso8601String()).order('id', ascending: true).range(a, b));

  // ── التنبيهات (ADM-A3) ───────────────────────────────────────────────────
  Future<int> alertsScan() async => ((await db.rpc('admin_alerts_scan')) as num).toInt();

  Future<List<Map<String, dynamic>>> alerts({String? status, int limit = 300}) {
    var q = db.from('admin_alerts').select();
    if (status != null) q = q.eq('status', status);
    return q.order('last_at', ascending: false).limit(limit);
  }

  Future<int> openAlerts() => db.from('admin_alerts').count().eq('status', 'new');

  Future<void> setAlertStatus(List<int> ids, String status) => db
      .from('admin_alerts')
      .update({'status': status, 'resolved_at': status == 'resolved' ? DateTime.now().toUtc().toIso8601String() : null})
      .inFilter('id', ids);

  /// يرفعه البرنامج نفسه (مثل توقف موصل iptv-org تلقائيًا).
  Future<void> raiseAlert(String kind, String key, String title, {String severity = 'warning', Map<String, dynamic> detail = const {}, String? refType, String? refId}) =>
      db.rpc('admin_alert_raise', params: {
        'p_kind': kind,
        'p_severity': severity,
        'p_key': key,
        'p_title': title,
        'p_detail': detail,
        'p_ref_type': refType,
        'p_ref_id': refId,
      });
}

final adminRepoProvider = Provider<AdminRepository?>((ref) {
  final c = ref.watch(supabaseProvider);
  return c == null ? null : AdminRepository(c);
});
