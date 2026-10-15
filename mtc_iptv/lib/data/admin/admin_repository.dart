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
        streamStates: [for (final s in (j['streams'] as List?) ?? const []) '${(s as Map)['health_state']}'],
      );

  String displayName(String lang) => lang == 'ar' ? (nameAr ?? nameEn ?? name) : (nameEn ?? nameAr ?? name);
  int get streamsOk => streamStates.where(workingStates.contains).length;
}

class ChannelQuery {
  final String search;
  final String? state, country, category;
  final bool featured, noLogo, manual;
  final int page;
  static const pageSize = 50;
  const ChannelQuery({this.search = '', this.state, this.country, this.category, this.featured = false, this.noLogo = false, this.manual = false, this.page = 0});

  ChannelQuery copyWith({String? search, String? state, String? country, String? category, bool? featured, bool? noLogo, bool? manual, int? page, bool clearState = false, bool clearCountry = false, bool clearCategory = false}) =>
      ChannelQuery(
        search: search ?? this.search,
        state: clearState ? null : (state ?? this.state),
        country: clearCountry ? null : (country ?? this.country),
        category: clearCategory ? null : (category ?? this.category),
        featured: featured ?? this.featured,
        noLogo: noLogo ?? this.noLogo,
        manual: manual ?? this.manual,
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
      other.page == page;
  @override
  int get hashCode => Object.hash(search, state, country, category, featured, noLogo, manual, page);
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
  const Dashboard(this.channelsByState, this.streamsByHealth, this.openReports, this.epgChannels, this.recent);
  int get channels => channelsByState.values.fold(0, (a, b) => a + b);
  int get streams => streamsByHealth.values.fold(0, (a, b) => a + b);
}

class AdminRepository {
  final SupabaseClient db;
  AdminRepository(this.db);

  static const _channelCols =
      'id,uid,number,name,name_ar,name_en,alt_names,network,logo_url,country_code,category_slug,language_code,quality,description,website,epg_id,publish_state,is_featured,is_manual,parental_locked,epg_offset_minutes,updated_at';
  static const _streamCols =
      'id,channel_id,url,label,quality,priority,user_agent,referrer,headers,protocol,has_credentials,health_state,health_reason,health_score,http_status,response_ms,last_checked_at';

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
    final epgRows = await db
        .from('epg_programmes')
        .select('channel_uid')
        .gte('end_at', now.toIso8601String())
        .lte('start_at', now.add(const Duration(hours: 24)).toIso8601String())
        .limit(20000);
    final uids = {for (final r in epgRows) r['channel_uid'] as String};
    final published = await db.from('channels').select('uid').eq('publish_state', 'published').limit(20000);
    final covered = published.where((r) => uids.contains(r['uid'])).length;
    return Dashboard(ch, st, reports, covered, await recentAudit(limit: 10));
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
  Future<ChannelPage> channels(ChannelQuery q) async {
    var f = db.from('channels').select('$_channelCols,streams(health_state)');
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

  Future<void> deleteChannels(List<String> ids) => db.from('channels').delete().inFilter('id', ids);

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
    return r['id'] as String;
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

  Future<List<(AdminStream, String, int?)>> streamsByHealth(String state, {int limit = 500}) async {
    final rows = await db.from('streams').select('$_streamCols,channels(name,name_ar,name_en,number)').eq('health_state', state).order('last_checked_at', ascending: true, nullsFirst: true).limit(limit);
    return [
      for (final r in rows)
        (
          AdminStream.fromJson(r),
          '${(r['channels'] as Map?)?['name_ar'] ?? (r['channels'] as Map?)?['name'] ?? ''}',
          ((r['channels'] as Map?)?['number'] as num?)?.toInt(),
        ),
    ];
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
}

final adminRepoProvider = Provider<AdminRepository?>((ref) {
  final c = ref.watch(supabaseProvider);
  return c == null ? null : AdminRepository(c);
});
