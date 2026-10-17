import 'package:pub_semver/pub_semver.dart';

import 'errors.dart';
import 'manifest.dart' show formatTimestamp;

/// One line of the install history (kept to the last [InstallState.maxHistory]).
class HistoryEntry {
  HistoryEntry({
    required this.at,
    required this.event,
    this.version,
    this.detail,
  });

  final DateTime at;

  /// `adopted`, `staged`, `boot_attempt`, `confirmed`, `reverted`,
  /// `state_recovered`, `current_missing`.
  final String event;
  final String? version;
  final String? detail;

  Map<String, Object?> toJson() => {
    'at': formatTimestamp(at),
    'event': event,
    if (version != null) 'version': version,
    if (detail != null) 'detail': detail,
  };

  static HistoryEntry fromJson(Object? j) {
    if (j is! Map<String, dynamic>) {
      throw const FormatException('history entry');
    }
    return HistoryEntry(
      at: DateTime.parse(j['at'] as String),
      event: j['event'] as String,
      version: j['version'] as String?,
      detail: j['detail'] as String?,
    );
  }
}

/// Why and when the last automatic (or explicit) revert happened. The app
/// should show this to the admin on its next start.
class RevertRecord {
  RevertRecord({required this.version, required this.reason, required this.at});

  /// The version that failed and was removed.
  final Version version;
  final String reason;
  final DateTime at;

  Map<String, Object?> toJson() => {
    'version': version.toString(),
    'reason': reason,
    'at': formatTimestamp(at),
  };

  static RevertRecord fromJson(Object? j) {
    if (j is! Map<String, dynamic>) throw const FormatException('last_revert');
    return RevertRecord(
      version: Version.parse(j['version'] as String),
      reason: j['reason'] as String,
      at: DateTime.parse(j['at'] as String),
    );
  }
}

/// Contents of `<root>\state.json`.
///
/// * [current]  - last version that confirmed healthy; what runs by default.
/// * [previous] - the version before [current]; kept on disk until the next
///   successful update (manual fallback / signed rollback source).
/// * [pending]  - staged, not yet confirmed. The launcher starts it on trial;
///   [pendingBootAttempts] counts starts that did not (yet) confirm.
class InstallState {
  InstallState({
    required this.current,
    this.previous,
    this.pending,
    this.pendingBootAttempts = 0,
    this.pendingSince,
    this.lastRevert,
    List<HistoryEntry>? history,
    this.recoveredFromCorruption = false,
  }) : history = history ?? [];

  static const int schema = 1;
  static const int maxHistory = 50;

  Version current;
  Version? previous;
  Version? pending;
  int pendingBootAttempts;
  DateTime? pendingSince;
  RevertRecord? lastRevert;
  final List<HistoryEntry> history;

  /// Not persisted: `true` when [readState] had to rebuild the state because
  /// `state.json` (and its backup) were unreadable.
  bool recoveredFromCorruption;

  void log(DateTime at, String event, {Version? version, String? detail}) {
    history.add(
      HistoryEntry(
        at: at,
        event: event,
        version: version?.toString(),
        detail: detail,
      ),
    );
    if (history.length > maxHistory) {
      history.removeRange(0, history.length - maxHistory);
    }
  }

  Map<String, Object?> toJson() => {
    'schema': schema,
    'current': current.toString(),
    'previous': previous?.toString(),
    'pending': pending?.toString(),
    'pending_boot_attempts': pendingBootAttempts,
    'pending_since': pendingSince == null
        ? null
        : formatTimestamp(pendingSince!),
    'last_revert': lastRevert?.toJson(),
    'history': [for (final h in history) h.toJson()],
  };

  /// Strict parse; any problem throws [InstallStateException].
  static InstallState fromJson(Object? j) {
    try {
      if (j is! Map<String, dynamic>) {
        throw const FormatException('not an object');
      }
      if (j['schema'] != schema) throw FormatException('schema ${j['schema']}');
      Version? optV(String k) {
        final v = j[k];
        return v == null ? null : Version.parse(v as String);
      }

      final current = Version.parse(j['current'] as String);
      final pending = optV('pending');
      final previous = optV('previous');
      if (pending != null && pending == current) {
        throw const FormatException('pending == current');
      }
      final attempts = j['pending_boot_attempts'] as int? ?? 0;
      if (attempts < 0) throw const FormatException('negative attempts');
      final ps = j['pending_since'] as String?;
      final lr = j['last_revert'];
      final hist = j['history'];
      return InstallState(
        current: current,
        previous: previous,
        pending: pending,
        pendingBootAttempts: attempts,
        pendingSince: ps == null ? null : DateTime.parse(ps),
        lastRevert: lr == null ? null : RevertRecord.fromJson(lr),
        history: hist == null
            ? []
            : [for (final h in hist as List<dynamic>) HistoryEntry.fromJson(h)],
      );
    } on InstallStateException {
      rethrow;
    } catch (e) {
      throw InstallStateException('invalid state file: $e');
    }
  }
}
