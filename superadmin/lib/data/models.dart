// Read models shown by the program. In Phase 2 they are filled from server views/RPCs; until then
// from lib/data/sample/sample_data.dart.
import 'package:flutter/foundation.dart';

import '../app/theme/tokens.dart';
import '../core/tr.dart';

/// Where a channel is now — computed in ONE place on the server (`channel_status`, plan §4 rule 9).
enum ChannelState {
  published(Tr('منشورة', 'Published'), Tone.ok),
  review(Tr('قيد المراجعة', 'In review'), Tone.warn),
  hidden(Tr('مخفية', 'Hidden'), Tone.neutral),
  trashed(Tr('بالسلة', 'In trash'), Tone.bad);

  final Tr label;
  final Tone tone;
  const ChannelState(this.label, this.tone);
  static ChannelState? byName(String? n) => values.where((v) => v.name == n).firstOrNull;
}

@immutable
class Channel {
  final String id;
  final int number;
  final String nameAr, nameEn;
  final String country, category, network;
  final int workingLinks, totalLinks;
  final ChannelState state;
  final DateTime updatedAt;
  final bool hasLogo, hasEpg;
  final String? epgId;
  final DateTime? trashedAt;
  const Channel({
    required this.id,
    required this.number,
    required this.nameAr,
    required this.nameEn,
    required this.country,
    required this.category,
    required this.network,
    required this.workingLinks,
    required this.totalLinks,
    required this.state,
    required this.updatedAt,
    required this.hasLogo,
    required this.hasEpg,
    this.epgId,
    this.trashedAt,
  });

  String name(Lang l) => l == Lang.en && nameEn.isNotEmpty ? nameEn : nameAr;
}

enum LinkStatus {
  working(Tr('يعمل', 'Working'), Tone.ok),
  flaky(Tr('متقطع', 'Flaky'), Tone.warn),
  broken(Tr('معطّل', 'Broken'), Tone.bad),
  unknown(Tr('غير مؤكد', 'Unverified'), Tone.neutral);

  final Tr label;
  final Tone tone;
  const LinkStatus(this.label, this.tone);
}

@immutable
class StreamLink {
  final String id;

  /// Always masked by the server (credentials never reach the UI or logs).
  final String maskedUrl;
  final LinkStatus status;
  final bool enabled;
  final List<String> sources;
  final DateTime? lastCheck;
  const StreamLink({required this.id, required this.maskedUrl, required this.status, required this.enabled, required this.sources, this.lastCheck});
}

@immutable
class AuditEntry {
  final String id;
  final DateTime at;
  final String actor, device, action, target, field, before, after, reason;
  const AuditEntry({
    required this.id,
    required this.at,
    required this.actor,
    required this.device,
    required this.action,
    required this.target,
    required this.field,
    required this.before,
    required this.after,
    required this.reason,
  });
}

@immutable
class DecisionItem {
  final String id;
  final String type;
  final String title;
  final Tr why;
  final List<(Tr, String)> evidence;
  final int? confidence;
  final List<Tr> confidenceReasons;
  final String country, category;
  const DecisionItem({
    required this.id,
    required this.type,
    required this.title,
    required this.why,
    this.evidence = const [],
    this.confidence,
    this.confidenceReasons = const [],
    this.country = '',
    this.category = '',
  });
}

enum JobState {
  running(Tr('شغالة', 'Running'), Tone.info),
  queued(Tr('بالانتظار', 'Queued'), Tone.neutral),
  failed(Tr('فشلت', 'Failed'), Tone.bad),
  stopped(Tr('موقوفة', 'Stopped'), Tone.warn),
  done(Tr('خلصت', 'Done'), Tone.ok);

  final Tr label;
  final Tone tone;
  const JobState(this.label, this.tone);
}

@immutable
class JobInfo {
  final String id;
  final Tr kind;
  final double progress;
  final String message;
  final DateTime startedAt;
  final JobState state;
  final String executor;
  const JobInfo({
    required this.id,
    required this.kind,
    required this.progress,
    required this.message,
    required this.startedAt,
    required this.state,
    required this.executor,
  });
}

enum AlertState { open, seen, resolved }

@immutable
class AlertItem {
  final String id;
  final Tr title;
  final Tr detail;
  final Tone severity;
  final DateTime at;
  final AlertState state;
  final String? link;
  const AlertItem({required this.id, required this.title, required this.detail, required this.severity, required this.at, required this.state, this.link});
}

@immutable
class SourceCard {
  final String id, name;
  final Tr kind;
  final bool connected;
  final DateTime? lastSuccess;
  final int fresh, existing, review, invalid;
  final Tr schedule;
  final bool paused;
  const SourceCard({
    required this.id,
    required this.name,
    required this.kind,
    required this.connected,
    required this.lastSuccess,
    required this.fresh,
    required this.existing,
    required this.review,
    required this.invalid,
    required this.schedule,
    this.paused = false,
  });
}

@immutable
class SessionInfo {
  final String id, device, version;
  final DateTime firstSeen, lastSeen;
  final bool current;
  const SessionInfo({required this.id, required this.device, required this.version, required this.firstSeen, required this.lastSeen, required this.current});
}

/// Generic row for the simpler tables (rules, schedules, sources log…). Cells keyed by column id.
@immutable
class GenericRow {
  final String id;
  final Map<String, String> cells;
  final Tone tone;
  const GenericRow(this.id, this.cells, {this.tone = Tone.neutral});
  String operator [](String k) => cells[k] ?? '';
}

@immutable
class Kpis {
  final int published, review, hidden;
  final int linksWorking, linksBroken, linksUnknown;
  final double? playSuccess24h;
  final int playSamples24h;
  final int activeDevices7d;
  final double epgCoverage;
  final int openReports;
  const Kpis({
    required this.published,
    required this.review,
    required this.hidden,
    required this.linksWorking,
    required this.linksBroken,
    required this.linksUnknown,
    required this.playSuccess24h,
    required this.playSamples24h,
    required this.activeDevices7d,
    required this.epgCoverage,
    required this.openReports,
  });
}
