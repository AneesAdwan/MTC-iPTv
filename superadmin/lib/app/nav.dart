// The 7 sections and their pages (plan §5, §6). One registry feeds the sidebar, the router, the
// breadcrumbs, the command palette and the ⓘ help of each page. Routes are stable and shareable
// (plan §8/§9): filters travel as query parameters, e.g. /channels?state=hidden, /decisions?type=broken.
import 'package:flutter/material.dart';

import '../core/tr.dart';

@immutable
class NavPage {
  final String id;
  final Tr title;
  final String path;

  /// Help files (plan §6 service numbers) shown by the ⓘ button.
  final List<String> help;
  final IconData icon;
  const NavPage(this.id, this.title, this.path, this.help, this.icon);
}

@immutable
class NavSection {
  final String id;
  final Tr title;
  final Tr summary;
  final IconData icon;
  final List<NavPage> pages;
  const NavSection(this.id, this.title, this.summary, this.icon, this.pages);
  String get path => pages.first.path;
}

abstract final class Nav {
  static const home = NavSection(
    'home',
    Tr('الرئيسية', 'Home'),
    Tr('شو وضع النظام هلأ، وشو بدو انتباهك', 'System status and what needs attention'),
    Icons.space_dashboard_outlined,
    [
      NavPage('home.overview', Tr('نظرة عامة', 'Overview'), '/home', ['1.1', '1.2'], Icons.insights),
      NavPage('home.jobs', Tr('المهام الجارية', 'Running jobs'), '/home/jobs', ['1.3'], Icons.sync),
      NavPage('home.alerts', Tr('التنبيهات', 'Alerts'), '/home/alerts', ['1.4'], Icons.notifications_none),
    ],
  );

  static const channels = NavSection(
    'channels',
    Tr('القنوات', 'Channels'),
    Tr('كل قناة ومعلوماتها وروابطها', 'Every channel, its info and streams'),
    Icons.live_tv_outlined,
    [
      NavPage('channels.list', Tr('قائمة القنوات', 'Channel list'), '/channels', ['2.1', '2.4'], Icons.table_rows_outlined),
      NavPage('channels.new', Tr('إضافة قناة', 'Add channel'), '/channels/new', ['2.2'], Icons.add_circle_outline),
      NavPage('channels.trash', Tr('السلة', 'Trash'), '/channels/trash', ['2.5'], Icons.delete_outline),
      NavPage('channels.numbering', Tr('الترقيم', 'Numbering'), '/channels/numbering', ['2.6'], Icons.format_list_numbered),
      NavPage('channels.networks', Tr('الشبكات', 'Networks'), '/channels/networks', ['2.7'], Icons.hub_outlined),
    ],
  );

  static const decisions = NavSection(
    'decisions',
    Tr('مركز القرارات', 'Decision center'),
    Tr('كل شي بدو قرار منك بمكان واحد', 'Everything that needs your decision, in one place'),
    Icons.flag_outlined,
    [
      NavPage('decisions.inbox', Tr('صندوق القرارات', 'Decision inbox'), '/decisions', ['3.0'], Icons.inbox_outlined),
      NavPage('decisions.compare', Tr('المقارنة', 'Compare'), '/decisions/compare', ['3.0'], Icons.compare_arrows),
    ],
  );

  static const sources = NavSection(
    'sources',
    Tr('المصادر', 'Sources'),
    Tr('من وين بتجي القنوات، وكيف بتطلع', 'Where channels come from and how they go out'),
    Icons.download_outlined,
    [
      NavPage('sources.hub', Tr('مركز المصادر', 'Sources hub'), '/sources', ['4.2'], Icons.cloud_download_outlined),
      NavPage('sources.import', Tr('الاستيراد', 'Import'), '/sources/import', ['4.1'], Icons.upload_file_outlined),
      NavPage('sources.connectors', Tr('الموصلات', 'Connectors'), '/sources/connectors', ['4.3'], Icons.cable_outlined),
      NavPage('sources.monitoring', Tr('مراقبة المصادر', 'Source monitoring'), '/sources/monitoring', ['4.4'], Icons.monitor_heart_outlined),
      NavPage('sources.enrichment', Tr('تحسين البيانات', 'Data enrichment'), '/sources/enrichment', ['4.5'], Icons.auto_fix_high_outlined),
      NavPage('sources.rules', Tr('قواعد التحويل', 'Transform rules'), '/sources/rules', ['4.6'], Icons.rule_outlined),
      NavPage('sources.export', Tr('التصدير', 'Export'), '/sources/export', ['4.7'], Icons.ios_share_outlined),
      NavPage('sources.licensing', Tr('الترخيص والإيقاف', 'Licensing & takedown'), '/sources/licensing', ['4.8'], Icons.gavel_outlined),
    ],
  );

  static const epg = NavSection(
    'epg',
    Tr('دليل البرامج', 'Program guide'),
    Tr('جدول البرامج لكل قناة', 'The program schedule of every channel'),
    Icons.calendar_view_week_outlined,
    [
      NavPage('epg.sources', Tr('مصادر الدليل', 'Guide sources'), '/epg', ['5.1'], Icons.rss_feed),
      NavPage('epg.mapping', Tr('ربط القنوات', 'Channel mapping'), '/epg/mapping', ['5.2'], Icons.link),
      NavPage('epg.preview', Tr('المعاينة', 'Preview'), '/epg/preview', ['5.3'], Icons.view_timeline_outlined),
    ],
  );

  static const experience = NavSection(
    'experience',
    Tr('الواجهة والتواصل', 'Experience & messaging'),
    Tr('شو بيشوف المشاهد، وشو بتبعتله', 'What viewers see and what you send them'),
    Icons.dashboard_customize_outlined,
    [
      NavPage('experience.home', Tr('رئيسية المشاهدين', 'Viewer home'), '/experience', ['6.1'], Icons.home_outlined),
      NavPage('experience.taxonomy', Tr('التقسيمات', 'Taxonomy'), '/experience/taxonomy', ['6.2'], Icons.category_outlined),
      NavPage('experience.notifications', Tr('الإشعارات', 'Notifications'), '/experience/notifications', ['6.3'], Icons.campaign_outlined),
      NavPage('experience.announcements', Tr('الإعلانات والشرائط', 'Announcements'), '/experience/announcements', ['6.4'], Icons.view_day_outlined),
      NavPage('experience.branding', Tr('الهوية والإعدادات', 'Branding & settings'), '/experience/branding', ['6.5'], Icons.palette_outlined),
      NavPage('experience.player', Tr('المشغّل والشبكة', 'Player & network'), '/experience/player', ['6.6'], Icons.play_circle_outline),
      NavPage('experience.features', Tr('المزايا والصيانة', 'Features & maintenance'), '/experience/features', ['6.7'], Icons.toggle_on_outlined),
      NavPage('experience.releases', Tr('الإصدارات والتحديث', 'Releases & updates'), '/experience/releases', ['6.8'], Icons.system_update_outlined),
    ],
  );

  static const system = NavSection(
    'system',
    Tr('النظام', 'System'),
    Tr('الحساب والأمان وسجل كل شي', 'Account, security and the log of everything'),
    Icons.settings_outlined,
    [
      NavPage('system.account', Tr('الحساب والأمان', 'Account & security'), '/system', ['7.1'], Icons.admin_panel_settings_outlined),
      NavPage('system.schedules', Tr('المهام المجدولة', 'Scheduled tasks'), '/system/schedules', ['7.2'], Icons.schedule),
      NavPage('system.audit', Tr('سجل التغييرات', 'Audit log'), '/system/audit', ['7.3'], Icons.history),
      NavPage('system.backup', Tr('النسخ الاحتياطي', 'Backup'), '/system/backup', ['7.4'], Icons.backup_outlined),
      NavPage('system.diagnostics', Tr('التشخيص والصيانة', 'Diagnostics'), '/system/diagnostics', ['7.5'], Icons.build_outlined),
      NavPage('system.analytics', Tr('التحليلات', 'Analytics'), '/system/analytics', ['7.6'], Icons.query_stats),
    ],
  );

  static const sections = [home, channels, decisions, sources, epg, experience, system];

  static Iterable<NavPage> get pages => sections.expand((s) => s.pages);

  /// Channel page (opened from the list, not in the sidebar).
  static const channelDetail = NavPage('channels.detail', Tr('صفحة القناة', 'Channel'), '/channels/:id', ['2.3'], Icons.tv);

  /// The section owning [location] (longest matching prefix).
  static NavSection sectionFor(String location) {
    final path = Uri.parse(location).path;
    for (final s in sections) {
      if (s.pages.any((p) => p.path == path)) return s;
    }
    for (final s in sections) {
      if (path.startsWith('/${s.path.split('/')[1]}')) return s;
    }
    return home;
  }

  static NavPage? pageFor(String location) {
    final path = Uri.parse(location).path;
    for (final p in pages) {
      if (p.path == path) return p;
    }
    if (path.startsWith('/channels/')) return channelDetail;
    return null;
  }
}

/// Decision types of the decision center (plan §6 section 3), used as `/decisions?type=ID`.
@immutable
class DecisionType {
  final String id;
  final String help;
  final Tr title;
  final IconData icon;
  const DecisionType(this.id, this.help, this.title, this.icon);

  static const all = [
    DecisionType('review', '3.1', Tr('جديدة للمراجعة', 'New, to review'), Icons.fiber_new_outlined),
    DecisionType('incomplete', '3.2', Tr('ناقصة', 'Incomplete'), Icons.rule_folder_outlined),
    DecisionType('duplicates', '3.3', Tr('مكرر محتمل', 'Possible duplicate'), Icons.copy_all_outlined),
    DecisionType('broken', '3.4', Tr('لا تعمل', 'Not working'), Icons.link_off),
    DecisionType('logos', '3.5', Tr('شعار معطّل', 'Broken logo'), Icons.broken_image_outlined),
    DecisionType('reports', '3.6', Tr('بلاغ مشاهد', 'Viewer report'), Icons.report_outlined),
    DecisionType('conflicts', '3.7', Tr('تعارض', 'Conflict'), Icons.lock_clock_outlined),
    DecisionType('enrichment', '3.8', Tr('تحسين بيانات', 'Enrichment'), Icons.auto_fix_high_outlined),
    DecisionType('unmatched', '3.9', Tr('مطابقة غير مؤكدة', 'Uncertain match'), Icons.help_outline),
    DecisionType('sources', '3.10', Tr('مصدر بده مراجعة', 'Source needs review'), Icons.cloud_off_outlined),
  ];

  static DecisionType? byId(String? id) => all.where((t) => t.id == id).firstOrNull;
}
