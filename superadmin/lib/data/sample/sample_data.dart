// Deterministic sample data so every screen has a realistic layout before Phase 2 connects the
// server. Nothing here is ever written anywhere.
import 'dart:math';

import '../../app/theme/tokens.dart';
import '../../core/tr.dart';
import '../models.dart';

const sampleCountries = <String, Tr>{
  'PS': Tr('فلسطين', 'Palestine'),
  'JO': Tr('الأردن', 'Jordan'),
  'SA': Tr('السعودية', 'Saudi Arabia'),
  'QA': Tr('قطر', 'Qatar'),
  'AE': Tr('الإمارات', 'UAE'),
  'EG': Tr('مصر', 'Egypt'),
  'LB': Tr('لبنان', 'Lebanon'),
  'IQ': Tr('العراق', 'Iraq'),
  'KW': Tr('الكويت', 'Kuwait'),
  'MA': Tr('المغرب', 'Morocco'),
  'GB': Tr('بريطانيا', 'United Kingdom'),
  'US': Tr('أمريكا', 'United States'),
};

const sampleCategories = <String, Tr>{
  'news': Tr('أخبار', 'News'),
  'sports': Tr('رياضة', 'Sports'),
  'kids': Tr('أطفال', 'Kids'),
  'movies': Tr('أفلام', 'Movies'),
  'religious': Tr('دينية', 'Religious'),
  'music': Tr('موسيقى', 'Music'),
  'general': Tr('منوعات', 'General'),
  'documentary': Tr('وثائقية', 'Documentary'),
};

const _brands = [
  ('الجزيرة', 'Al Jazeera', 'Al Jazeera'),
  ('العربية', 'Al Arabiya', 'MBC'),
  ('إم بي سي', 'MBC', 'MBC'),
  ('روتانا', 'Rotana', 'Rotana'),
  ('بي إن سبورت', 'beIN Sports', 'beIN'),
  ('سبيستون', 'Spacetoon', 'Spacetoon'),
  ('رؤيا', 'Roya', 'Roya'),
  ('فلسطين', 'Palestine TV', 'PBC'),
  ('المملكة', 'Al Mamlaka', 'Al Mamlaka'),
  ('دبي', 'Dubai TV', 'DMI'),
  ('أبوظبي', 'Abu Dhabi TV', 'ADM'),
  ('الشرق', 'Asharq', 'SRMG'),
  ('سكاي نيوز عربية', 'Sky News Arabia', 'Sky'),
  ('بي بي سي عربي', 'BBC Arabic', 'BBC'),
  ('الحياة', 'Al Hayat', 'Al Hayat'),
  ('القاهرة والناس', 'Al Kahera Wal Nas', 'CWN'),
  ('الإخبارية', 'Al Ekhbariya', 'SBA'),
  ('ماجد', 'Majid Kids', 'ADM'),
  ('الشارقة', 'Sharjah TV', 'SBA-UAE'),
  ('الكويت', 'KTV', 'KTV'),
];

class SampleData {
  SampleData._();
  static final SampleData instance = SampleData._();

  final DateTime now = DateTime(2026, 10, 17, 18, 30);
  late final List<Channel> channels = _channels();

  List<Channel> _channels() {
    final r = Random(42);
    final out = <Channel>[];
    final countries = sampleCountries.keys.toList();
    final cats = sampleCategories.keys.toList();
    for (var i = 0; i < 1240; i++) {
      final b = _brands[i % _brands.length];
      final variant = i ~/ _brands.length;
      final suffix = variant == 0 ? '' : ' ${variant + 1}';
      final total = 1 + r.nextInt(5);
      final working = r.nextDouble() < 0.12 ? 0 : 1 + r.nextInt(total);
      final roll = r.nextDouble();
      final state = roll < 0.80
          ? ChannelState.published
          : roll < 0.88
          ? ChannelState.review
          : roll < 0.96
          ? ChannelState.hidden
          : ChannelState.trashed;
      out.add(
        Channel(
          id: 'ch-${i + 1}',
          number: i + 1,
          nameAr: '${b.$1}$suffix',
          nameEn: '${b.$2}$suffix',
          country: countries[(i * 7 + variant) % countries.length],
          category: cats[(i * 3 + variant) % cats.length],
          network: b.$3,
          workingLinks: working.clamp(0, total),
          totalLinks: total,
          state: state,
          updatedAt: now.subtract(Duration(minutes: r.nextInt(60 * 24 * 40))),
          hasLogo: r.nextDouble() > 0.15,
          hasEpg: r.nextDouble() > 0.35,
          epgId: r.nextDouble() > 0.35 ? '${b.$2.replaceAll(' ', '')}$suffix.${countries[i % countries.length].toLowerCase()}' : null,
          trashedAt: state == ChannelState.trashed ? now.subtract(Duration(days: r.nextInt(29))) : null,
        ),
      );
    }
    return out;
  }

  Kpis kpis() {
    int n(ChannelState s) => channels.where((c) => c.state == s).length;
    final links = channels.fold<int>(0, (a, c) => a + c.totalLinks);
    final working = channels.fold<int>(0, (a, c) => a + c.workingLinks);
    final pub = channels.where((c) => c.state == ChannelState.published).toList();
    return Kpis(
      published: n(ChannelState.published),
      review: n(ChannelState.review),
      hidden: n(ChannelState.hidden),
      linksWorking: working,
      linksBroken: ((links - working) * 0.7).round(),
      linksUnknown: ((links - working) * 0.3).round(),
      playSuccess24h: 0.934,
      playSamples24h: 2481,
      activeDevices7d: 318,
      epgCoverage: pub.isEmpty ? 0 : pub.where((c) => c.hasEpg).length / pub.length,
      openReports: 7,
    );
  }

  List<StreamLink> streams(String channelId) {
    final c = channels.firstWhere((x) => x.id == channelId, orElse: () => channels.first);
    final r = Random(c.number);
    return [
      for (var i = 0; i < c.totalLinks; i++)
        StreamLink(
          id: '${c.id}-s$i',
          maskedUrl: i.isEven
              ? 'https://live.example.net/${c.nameEn.toLowerCase().replaceAll(' ', '')}/index.m3u8'
              : 'http://srv${i + 1}.example.org/live/••••/••••/${1000 + c.number}.ts',
          status: i < c.workingLinks ? LinkStatus.working : (r.nextBool() ? LinkStatus.broken : LinkStatus.unknown),
          enabled: i < c.workingLinks || r.nextBool(),
          sources: [if (i == 0) 'iptv-org/iptv' else 'Free-TV/IPTV', if (i == 1) 'manual'],
          lastCheck: now.subtract(Duration(minutes: 5 + r.nextInt(600))),
        ),
    ];
  }

  List<AuditEntry> history(String target, {int count = 12}) {
    final r = Random(target.hashCode);
    const fields = ['name_ar', 'country', 'category', 'publish_state', 'logo_url', 'number'];
    return [
      for (var i = 0; i < count; i++)
        AuditEntry(
          id: '$target-a$i',
          at: now.subtract(Duration(hours: i * 7 + r.nextInt(6))),
          actor: i % 4 == 0 ? 'scheduler' : 'admin@mtc',
          device: i % 4 == 0 ? 'server' : 'SuperAdmin · Windows',
          action: i % 3 == 0 ? 'admin_channels_bulk' : 'admin_channel_update',
          target: target,
          field: fields[i % fields.length],
          before: 'قيمة ${i + 1}',
          after: 'قيمة ${i + 2}',
          reason: i % 2 == 0 ? 'تصحيح من مركز القرارات' : 'تحديث يدوي',
        ),
    ];
  }

  List<DecisionItem> decisions() {
    final r = Random(7);
    final out = <DecisionItem>[];
    final per = {
      'review': 34,
      'incomplete': 51,
      'duplicates': 18,
      'broken': 92,
      'logos': 23,
      'reports': 7,
      'conflicts': 5,
      'enrichment': 140,
      'unmatched': 26,
      'sources': 2,
    };
    var k = 0;
    for (final e in per.entries) {
      for (var i = 0; i < e.value; i++) {
        final c = channels[(k * 13) % channels.length];
        k++;
        final conf = 30 + r.nextInt(70);
        out.add(
          DecisionItem(
            id: 'd-${e.key}-$i',
            type: e.key,
            title: e.key == 'sources' ? (i == 0 ? 'Free-TV/IPTV' : 'custom: sat-list.m3u') : '${c.nameAr} · ${c.nameEn}',
            why: _why(e.key, c),
            evidence: _evidence(e.key, c, r),
            confidence: const {'review', 'enrichment', 'unmatched', 'duplicates'}.contains(e.key) ? conf : null,
            confidenceReasons: const [
              Tr('مذكورة بمصدرين مستقلين', 'Listed by 2 independent sources'),
              Tr('الفحص نجح', 'Probe succeeded'),
              Tr('الدولة واللغة متطابقين', 'Country and language match'),
            ],
            country: c.country,
            category: c.category,
          ),
        );
      }
    }
    return out;
  }

  Tr _why(String type, Channel c) => switch (type) {
    'review' => const Tr('قناة ما كانت عنا، إجت من iptv-org.', 'A channel we did not have, found in iptv-org.'),
    'incomplete' => const Tr('ناقصها شعار وفئة.', 'Missing logo and category.'),
    'duplicates' => Tr('في قناة تانية بنفس الاسم والدولة (${c.country}).', 'Another channel has the same name and country (${c.country}).'),
    'broken' => const Tr('كل روابطها فشلت بآخر فحصين وعند المشاهدين.', 'All its streams failed the last two probes and for viewers.'),
    'logos' => const Tr('الشعار ما بيفتح (404).', 'The logo does not load (404).'),
    'reports' => const Tr('3 مشاهدين بلّغوا إنها ما بتشتغل.', '3 viewers reported it does not play.'),
    'conflicts' => const Tr('المصدر بدو يغيّر الاسم وإنت قافله 🔒.', 'A source wants to change the name you locked 🔒.'),
    'enrichment' => const Tr('اقتراح اسم رسمي وشعار من iptv-org/database.', 'Official name and logo suggested by iptv-org/database.'),
    'unmatched' => const Tr('سجل من مصدر ممكن يكون هالقناة، بس مش أكيد.', 'A source record might be this channel, not certain.'),
    _ => const Tr('المصدر فشل 3 مرات متتالية وحجمه نزل فجأة.', 'The source failed 3 times in a row and its size dropped suddenly.'),
  };

  List<(Tr, String)> _evidence(String type, Channel c, Random r) => switch (type) {
    'broken' => [
      (const Tr('آخر فحص', 'Last probe'), fmtDateTime(now.subtract(Duration(minutes: r.nextInt(300))))),
      (const Tr('الخطأ', 'Error'), 'HTTP 403'),
      (const Tr('الروابط', 'Streams'), '0/${c.totalLinks}'),
    ],
    'sources' => [(const Tr('آخر جلب ناجح', 'Last good fetch'), fmtDateTime(now.subtract(const Duration(days: 2)))), (const Tr('الحجم', 'Size'), '1,034 → 18')],
    _ => [
      (const Tr('الرقم', 'Number'), '${c.number}'),
      (const Tr('الدولة', 'Country'), c.country),
      (const Tr('الروابط', 'Streams'), '${c.workingLinks}/${c.totalLinks}'),
    ],
  };

  List<JobInfo> jobs() => [
    JobInfo(
      id: 'j1',
      kind: const Tr('فحص الروابط السريع', 'Quick stream probe'),
      progress: 0.62,
      message: '620/1000 · 41 فشل',
      startedAt: now.subtract(const Duration(minutes: 9)),
      state: JobState.running,
      executor: 'edge',
    ),
    JobInfo(
      id: 'j2',
      kind: const Tr('مزامنة الدليل', 'EPG sync'),
      progress: 0.18,
      message: 'iptv-org/epg · ar',
      startedAt: now.subtract(const Duration(minutes: 2)),
      state: JobState.running,
      executor: 'github-actions',
    ),
    JobInfo(
      id: 'j3',
      kind: const Tr('جلب مصدر: iptv-org (فلسطين + الأردن)', 'Fetch source: iptv-org (PS + JO)'),
      progress: 0,
      message: '',
      startedAt: now,
      state: JobState.queued,
      executor: 'edge',
    ),
    JobInfo(
      id: 'j4',
      kind: const Tr('فحص الشعارات', 'Logo check'),
      progress: 0.4,
      message: 'HTTP timeout ×3',
      startedAt: now.subtract(const Duration(hours: 3)),
      state: JobState.failed,
      executor: 'edge',
    ),
    JobInfo(
      id: 'j5',
      kind: const Tr('كشف المكررات', 'Duplicate detection'),
      progress: 1,
      message: '18 مكرر محتمل',
      startedAt: now.subtract(const Duration(hours: 5)),
      state: JobState.done,
      executor: 'pg_cron',
    ),
  ];

  List<AlertItem> alerts() => [
    AlertItem(
      id: 'al1',
      title: const Tr('فشل جلب مصدر Free-TV/IPTV', 'Free-TV/IPTV fetch failed'),
      detail: const Tr('3 مرات متتالية. الجلب تباعد تلقائيًا.', '3 times in a row. Fetching backed off automatically.'),
      severity: Tone.bad,
      at: now.subtract(const Duration(minutes: 40)),
      state: AlertState.open,
      link: '/decisions?type=sources',
    ),
    AlertItem(
      id: 'al2',
      title: const Tr('حجم مصدر تغيّر بشكل غير طبيعي', 'Abnormal source size change'),
      detail: const Tr('sat-list.m3u: من 1,034 لـ 18. ولا شي انخفى.', 'sat-list.m3u: 1,034 → 18. Nothing was hidden.'),
      severity: Tone.warn,
      at: now.subtract(const Duration(hours: 2)),
      state: AlertState.open,
      link: '/sources/monitoring',
    ),
    AlertItem(
      id: 'al3',
      title: const Tr('بلاغات متكررة على قناة', 'Repeated reports on a channel'),
      detail: const Tr('الجزيرة 2: 3 بلاغات آخر ساعة.', 'Al Jazeera 2: 3 reports in the last hour.'),
      severity: Tone.warn,
      at: now.subtract(const Duration(hours: 4)),
      state: AlertState.seen,
      link: '/decisions?type=reports',
    ),
    AlertItem(
      id: 'al4',
      title: const Tr('النسخة الاحتياطية الأسبوعية نجحت', 'Weekly backup succeeded'),
      detail: const Tr('12.4 MB، مشفّرة.', '12.4 MB, encrypted.'),
      severity: Tone.ok,
      at: now.subtract(const Duration(days: 1)),
      state: AlertState.resolved,
    ),
  ];

  List<SourceCard> sources() => [
    SourceCard(
      id: 'iptv-org',
      name: 'iptv-org/iptv',
      kind: const Tr('بث مجتمعي', 'Community streams'),
      connected: true,
      lastSuccess: now.subtract(const Duration(hours: 6)),
      fresh: 180,
      existing: 850,
      review: 70,
      invalid: 50,
      schedule: const Tr('يومي', 'Daily'),
    ),
    SourceCard(
      id: 'free-tv',
      name: 'Free-TV/IPTV',
      kind: const Tr('بث مجتمعي', 'Community streams'),
      connected: false,
      lastSuccess: now.subtract(const Duration(days: 2)),
      fresh: 12,
      existing: 402,
      review: 9,
      invalid: 3,
      schedule: const Tr('أسبوعي', 'Weekly'),
    ),
    SourceCard(
      id: 'iptv-org-db',
      name: 'iptv-org/database',
      kind: const Tr('بيانات قنوات', 'Channel metadata'),
      connected: true,
      lastSuccess: now.subtract(const Duration(days: 1)),
      fresh: 0,
      existing: 1102,
      review: 140,
      invalid: 0,
      schedule: const Tr('أسبوعي', 'Weekly'),
    ),
    SourceCard(
      id: 'iptv-org-epg',
      name: 'iptv-org/epg',
      kind: const Tr('دليل برامج', 'Program guide'),
      connected: true,
      lastSuccess: now.subtract(const Duration(hours: 5)),
      fresh: 0,
      existing: 760,
      review: 31,
      invalid: 0,
      schedule: const Tr('كل 6 ساعات', 'Every 6 h'),
    ),
    SourceCard(
      id: 'custom-1',
      name: 'sat-list.m3u',
      kind: const Tr('مصدر خاص', 'Custom source'),
      connected: true,
      lastSuccess: now.subtract(const Duration(days: 3)),
      fresh: 0,
      existing: 18,
      review: 0,
      invalid: 2,
      schedule: const Tr('يدوي', 'Manual'),
      paused: true,
    ),
  ];

  List<SessionInfo> sessions() => [
    SessionInfo(
      id: 's1',
      device: 'Windows 11 · DESKTOP-MTC',
      version: '0.1.0',
      firstSeen: now.subtract(const Duration(hours: 3)),
      lastSeen: now,
      current: true,
    ),
    SessionInfo(
      id: 's2',
      device: 'Windows 10 · LAPTOP-OFFICE',
      version: '0.1.0',
      firstSeen: now.subtract(const Duration(days: 2)),
      lastSeen: now.subtract(const Duration(hours: 20)),
      current: false,
    ),
  ];
}
