// سجل الشاشات (ملحق ب): المصدر الوحيد للمعرّف والمسار والأيقونة والمجموعة والمرحلة.
// منه تُبنى القائمة الجانبية والتوجيه ولوحة الأوامر — إضافة شاشة = سطر واحد هنا.
import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';

enum ScreenGroup { viewer, a, b, c, d, e, f, g, h, i }

extension ScreenGroupX on ScreenGroup {
  bool get isAdmin => this != ScreenGroup.viewer;
  String title(L10n t) => switch (this) {
        ScreenGroup.viewer => t.groupViewer,
        ScreenGroup.a => t.groupA,
        ScreenGroup.b => t.groupB,
        ScreenGroup.c => t.groupC,
        ScreenGroup.d => t.groupD,
        ScreenGroup.e => t.groupE,
        ScreenGroup.f => t.groupF,
        ScreenGroup.g => t.groupG,
        ScreenGroup.h => t.groupH,
        ScreenGroup.i => t.groupI,
      };
}

class ScreenDef {
  final String id; // V-02, ADM-B1 …
  final String path;
  final IconData icon;
  final ScreenGroup group;
  final int phase; // المرحلة التي تُبنى فيها (§25)
  final String Function(L10n) title;
  final bool inSidebar;

  const ScreenDef(this.id, this.path, this.icon, this.group, this.phase, this.title, {this.inSidebar = true});
}

const _v = ScreenGroup.viewer;

final screens = <ScreenDef>[
  // ── المشاهدة (V-01 … V-12) — المرحلة 3
  ScreenDef('V-02', '/home', Icons.home_rounded, _v, 3, (t) => t.sV02),
  ScreenDef('V-03', '/channels', Icons.live_tv_rounded, _v, 3, (t) => t.sV03),
  ScreenDef('V-04', '/countries', Icons.public_rounded, _v, 3, (t) => t.sV04),
  ScreenDef('V-05', '/search', Icons.search_rounded, _v, 3, (t) => t.sV05),
  ScreenDef('V-07', '/guide', Icons.view_timeline_rounded, _v, 3, (t) => t.sV07),
  ScreenDef('V-08', '/favorites', Icons.favorite_rounded, _v, 3, (t) => t.sV08),
  ScreenDef('V-09', '/inbox', Icons.notifications_rounded, _v, 3, (t) => t.sV09),
  ScreenDef('V-10', '/settings', Icons.tune_rounded, _v, 3, (t) => t.sV10),
  ScreenDef('V-11', '/about', Icons.info_outline_rounded, _v, 3, (t) => t.sV11),
  ScreenDef('V-06', '/watch', Icons.play_circle_rounded, _v, 3, (t) => t.sV06, inSidebar: false),
  ScreenDef('V-12', '/report', Icons.flag_rounded, _v, 3, (t) => t.sV12, inSidebar: false),

  // ── A. نظرة عامة
  ScreenDef('ADM-A1', '/admin/dashboard', Icons.dashboard_rounded, ScreenGroup.a, 4, (t) => t.sA1),
  ScreenDef('ADM-A2', '/admin/jobs', Icons.pending_actions_rounded, ScreenGroup.a, 4, (t) => t.sA2),
  ScreenDef('ADM-A3', '/admin/alerts', Icons.notification_important_rounded, ScreenGroup.a, 6, (t) => t.sA3),
  // ── B. الكتالوج
  ScreenDef('ADM-B1', '/admin/channels', Icons.tv_rounded, ScreenGroup.b, 4, (t) => t.sB1),
  ScreenDef('ADM-B2', '/admin/channel', Icons.article_rounded, ScreenGroup.b, 4, (t) => t.sB2, inSidebar: false),
  ScreenDef('ADM-B3', '/admin/streams', Icons.dns_rounded, ScreenGroup.b, 4, (t) => t.sB3),
  ScreenDef('ADM-B4', '/admin/home-layout', Icons.view_quilt_rounded, ScreenGroup.b, 4, (t) => t.sB4),
  ScreenDef('ADM-B5', '/admin/taxonomy', Icons.category_rounded, ScreenGroup.b, 4, (t) => t.sB5),
  ScreenDef('ADM-B6', '/admin/networks', Icons.hub_rounded, ScreenGroup.b, 4, (t) => t.sB6),
  ScreenDef('ADM-B7', '/admin/numbering', Icons.format_list_numbered_rounded, ScreenGroup.b, 4, (t) => t.sB7),
  // ── C. الاستيراد والتحويل
  ScreenDef('ADM-C1', '/admin/import', Icons.upload_file_rounded, ScreenGroup.c, 5, (t) => t.sC1),
  ScreenDef('ADM-C2', '/admin/import-review', Icons.fact_check_rounded, ScreenGroup.c, 5, (t) => t.sC2),
  ScreenDef('ADM-C3', '/admin/sources', Icons.playlist_play_rounded, ScreenGroup.c, 5, (t) => t.sC3),
  ScreenDef('ADM-C4', '/admin/connectors', Icons.extension_rounded, ScreenGroup.c, 5, (t) => t.sC4),
  ScreenDef('ADM-C5', '/admin/export', Icons.download_rounded, ScreenGroup.c, 5, (t) => t.sC5),
  ScreenDef('ADM-C6', '/admin/rules', Icons.rule_rounded, ScreenGroup.c, 5, (t) => t.sC6),
  // ── D. الجودة
  ScreenDef('ADM-D1', '/admin/review', Icons.verified_rounded, ScreenGroup.d, 4, (t) => t.sD1),
  ScreenDef('ADM-D2', '/admin/duplicates', Icons.merge_rounded, ScreenGroup.d, 4, (t) => t.sD2),
  ScreenDef('ADM-D3', '/admin/compare', Icons.compare_arrows_rounded, ScreenGroup.d, 4, (t) => t.sD3),
  ScreenDef('ADM-D4', '/admin/health', Icons.monitor_heart_rounded, ScreenGroup.d, 4, (t) => t.sD4),
  ScreenDef('ADM-D5', '/admin/logos', Icons.image_rounded, ScreenGroup.d, 4, (t) => t.sD5),
  ScreenDef('ADM-D6', '/admin/reports', Icons.report_rounded, ScreenGroup.d, 4, (t) => t.sD6),
  // ── E. دليل البرامج
  ScreenDef('ADM-E1', '/admin/epg-sources', Icons.rss_feed_rounded, ScreenGroup.e, 5, (t) => t.sE1),
  ScreenDef('ADM-E2', '/admin/epg-mapping', Icons.link_rounded, ScreenGroup.e, 5, (t) => t.sE2),
  ScreenDef('ADM-E3', '/admin/epg-preview', Icons.calendar_view_day_rounded, ScreenGroup.e, 5, (t) => t.sE3),
  // ── F. التواصل
  ScreenDef('ADM-F1', '/admin/notifications', Icons.campaign_rounded, ScreenGroup.f, 6, (t) => t.sF1),
  ScreenDef('ADM-F2', '/admin/announcements', Icons.announcement_rounded, ScreenGroup.f, 6, (t) => t.sF2),
  // ── G. الإعدادات
  ScreenDef('ADM-G1', '/admin/brand', Icons.palette_rounded, ScreenGroup.g, 6, (t) => t.sG1),
  ScreenDef('ADM-G2', '/admin/social', Icons.share_rounded, ScreenGroup.g, 6, (t) => t.sG2),
  ScreenDef('ADM-G3', '/admin/settings', Icons.settings_rounded, ScreenGroup.g, 6, (t) => t.sG3),
  ScreenDef('ADM-G4', '/admin/player', Icons.settings_input_antenna_rounded, ScreenGroup.g, 6, (t) => t.sG4),
  ScreenDef('ADM-G5', '/admin/features', Icons.toggle_on_rounded, ScreenGroup.g, 6, (t) => t.sG5),
  ScreenDef('ADM-G6', '/admin/releases', Icons.system_update_rounded, ScreenGroup.g, 6, (t) => t.sG6),
  // ── H. الأمن والنظام
  ScreenDef('ADM-H1', '/admin/account', Icons.admin_panel_settings_rounded, ScreenGroup.h, 6, (t) => t.sH1),
  ScreenDef('ADM-H2', '/admin/scheduler', Icons.schedule_rounded, ScreenGroup.h, 6, (t) => t.sH2),
  ScreenDef('ADM-H3', '/admin/audit', Icons.history_rounded, ScreenGroup.h, 6, (t) => t.sH3),
  ScreenDef('ADM-H4', '/admin/backups', Icons.backup_rounded, ScreenGroup.h, 6, (t) => t.sH4),
  ScreenDef('ADM-H5', '/admin/maintenance', Icons.build_circle_rounded, ScreenGroup.h, 6, (t) => t.sH5),
  // ── I. التقارير
  ScreenDef('ADM-I1', '/admin/analytics', Icons.insights_rounded, ScreenGroup.i, 6, (t) => t.sI1),
];

ScreenDef? screenForPath(String path) {
  for (final s in screens) {
    if (path == s.path || path.startsWith('${s.path}/')) return s;
  }
  return null;
}
