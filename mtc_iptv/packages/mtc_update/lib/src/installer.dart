import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

import 'errors.dart';
import 'install_state.dart';
import 'verifier.dart';

/// Marker written inside `versions\<ver>\` once that version confirmed
/// healthy. Used to rebuild `state.json` if it is ever corrupted.
const String confirmedMarkerName = '.mtc_confirmed';

/// What the launcher should start.
class LaunchDecision {
  LaunchDecision({
    required this.version,
    required this.directory,
    required this.isTrial,
    this.revertedReason,
  });

  final Version version;
  final Directory directory;

  /// `true` when [version] is the pending (unconfirmed) update. The launcher
  /// must supervise it: confirmation within the timeout or revert.
  final bool isTrial;

  /// Set when this call itself reverted a pending update (e.g. boot attempts
  /// exhausted) before deciding.
  final String? revertedReason;
}

/// Side-by-side installation under [root]:
///
/// ```
/// <root>\
///   state.json            current / previous / pending + history
///   state.json.bak        previous good copy of state.json
///   versions\
///     1.2.0\              current  (.mtc_confirmed marker inside)
///     1.1.0\              previous (kept until the next successful update)
///     1.3.0\              pending  (staged, on trial)
/// ```
///
/// Nothing is ever overwritten in place: a new version is extracted next to
/// the running one, tried, and only then promoted.
class SideBySideInstaller {
  SideBySideInstaller(
    this.root, {
    this.maxBootAttempts = 2,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    if (maxBootAttempts < 1) throw ArgumentError('maxBootAttempts >= 1');
  }

  final Directory root;

  /// Starts of a pending version allowed without a health confirmation. On
  /// the next start after that, the launcher reverts.
  final int maxBootAttempts;

  final DateTime Function() _clock;

  DateTime _now() => _clock().toUtc();

  Directory get versionsDir => Directory(p.join(root.path, 'versions'));
  File get stateFile => File(p.join(root.path, 'state.json'));
  File get _backupFile => File(p.join(root.path, 'state.json.bak'));
  File get _tmpFile => File(p.join(root.path, 'state.json.tmp'));

  Directory versionDir(Version v) =>
      Directory(p.join(versionsDir.path, v.toString()));

  // ---------------------------------------------------------------------
  // State persistence
  // ---------------------------------------------------------------------

  /// Reads `state.json`. If it is corrupted or missing, falls back to
  /// `state.json.bak`, then rebuilds from the `.mtc_confirmed` markers
  /// (highest confirmed = current, next = previous, no pending). A rebuilt
  /// state is written back and flagged [InstallState.recoveredFromCorruption].
  Future<InstallState> readState() async {
    final errors = <String>[];
    final candidates = [stateFile, _backupFile];
    for (var i = 0; i < candidates.length; i++) {
      final f = candidates[i];
      if (!await f.exists()) {
        errors.add('${p.basename(f.path)}: missing');
        continue;
      }
      try {
        final s = InstallState.fromJson(jsonDecode(await f.readAsString()));
        if (i == 1) {
          s.recoveredFromCorruption = true;
          s.log(
            _now(),
            'state_recovered',
            detail: 'restored from backup; ${errors.join('; ')}',
          );
          await _writeState(s);
        }
        return s;
      } catch (e) {
        errors.add('${p.basename(f.path)}: $e');
      }
    }
    return _rebuildFromMarkers(errors.join('; '));
  }

  Future<InstallState> _rebuildFromMarkers(String why) async {
    final confirmed = <Version>[];
    if (await versionsDir.exists()) {
      await for (final e in versionsDir.list(followLinks: false)) {
        if (e is! Directory) continue;
        final Version v;
        try {
          v = Version.parse(p.basename(e.path));
        } on FormatException {
          continue;
        }
        if (await File(p.join(e.path, confirmedMarkerName)).exists()) {
          confirmed.add(v);
        }
      }
    }
    if (confirmed.isEmpty) {
      throw InstallStateException(
        'no usable state and no confirmed version on disk ($why)',
      );
    }
    confirmed.sort();
    final s = InstallState(
      current: confirmed.last,
      previous: confirmed.length > 1 ? confirmed[confirmed.length - 2] : null,
      recoveredFromCorruption: true,
    );
    s.log(
      _now(),
      'state_recovered',
      version: s.current,
      detail: 'rebuilt from markers; $why',
    );
    await _writeState(s, backupOld: false);
    return s;
  }

  /// Atomic write: tmp file -> keep old as .bak -> rename over state.json.
  Future<void> _writeState(InstallState s, {bool backupOld = true}) async {
    await root.create(recursive: true);
    final text = const JsonEncoder.withIndent('  ').convert(s.toJson());
    final tmp = await _tmpFile.writeAsString(text, flush: true);
    if (backupOld && await stateFile.exists()) {
      // Only keep a backup that actually parses; never back up garbage.
      try {
        InstallState.fromJson(jsonDecode(await stateFile.readAsString()));
        await stateFile.copy(_backupFile.path);
      } catch (_) {}
    }
    await tmp.rename(stateFile.path);
  }

  // ---------------------------------------------------------------------
  // Operations
  // ---------------------------------------------------------------------

  /// First install: `versions\<v>\` already contains the app (put there by
  /// the setup program). Records it as current and confirmed.
  Future<InstallState> adoptInitial(Version v) async {
    final dir = versionDir(v);
    if (!await dir.exists()) {
      throw InstallStateException('${dir.path} does not exist');
    }
    await File(
      p.join(dir.path, confirmedMarkerName),
    ).writeAsString(_now().toIso8601String());
    final s = InstallState(current: v);
    s.log(_now(), 'adopted', version: v);
    await _writeState(s);
    return s;
  }

  /// Extracts a verified update zip into `versions\<ver>\` next to the
  /// running version and marks it pending. The artifact is re-hashed here
  /// (the bytes that are hashed are the bytes that get extracted), so a
  /// file swapped after verification is refused.
  Future<InstallState> stage(VerifiedUpdate update) async {
    final m = update.manifest;
    final s = await readState();
    final v = m.version;
    if (v == s.current) {
      throw InstallStateException('$v is already the current version');
    }

    final bytes = await update.artifact.readAsBytes();
    if (bytes.length != m.size) {
      throw UpdateRejectedException(
        UpdateRejection.fileSizeMismatch,
        'artifact changed after verification (size)',
      );
    }
    if (sha256OfBytes(bytes) != m.sha256) {
      throw UpdateRejectedException(
        UpdateRejection.fileHashMismatch,
        'artifact changed after verification (sha256)',
      );
    }

    await versionsDir.create(recursive: true);
    final staging = Directory(
      p.join(
        versionsDir.path,
        '.staging-$v-${Random.secure().nextInt(1 << 32)}',
      ),
    );
    try {
      await extractZipSafely(bytes, staging);
      // Drop an older pending that is being replaced.
      final oldPending = s.pending;
      if (oldPending != null && oldPending != v) {
        await _deleteDir(versionDir(oldPending));
      }
      final target = versionDir(v);
      await _deleteDir(target); // e.g. rollback to the kept previous version
      if (s.previous == v) s.previous = null;
      await staging.rename(target.path);
    } finally {
      await _deleteDir(staging);
    }

    s
      ..pending = v
      ..pendingBootAttempts = 0
      ..pendingSince = _now()
      ..log(
        _now(),
        'staged',
        version: v,
        detail: m.isRollback ? 'signed rollback from ${m.rollbackFrom}' : null,
      );
    await _writeState(s);
    return s;
  }

  /// Called by the launcher before starting the app. If an update is
  /// pending, counts a boot attempt; when attempts are exhausted the pending
  /// version is reverted first. Also survives a missing `current` folder by
  /// falling back to `previous`.
  Future<LaunchDecision> beginLaunch() async {
    final s = await readState();
    String? revertedReason;

    final pending = s.pending;
    if (pending != null) {
      if (!await versionDir(pending).exists()) {
        revertedReason = 'pending version folder is missing';
        await _revert(s, revertedReason);
      } else if (s.pendingBootAttempts >= maxBootAttempts) {
        revertedReason =
            'did not confirm healthy after ${s.pendingBootAttempts} start(s)';
        await _revert(s, revertedReason);
      } else {
        s.pendingBootAttempts++;
        s.log(
          _now(),
          'boot_attempt',
          version: pending,
          detail: 'attempt ${s.pendingBootAttempts}/$maxBootAttempts',
        );
        await _writeState(s);
        return LaunchDecision(
          version: pending,
          directory: versionDir(pending),
          isTrial: true,
        );
      }
    }

    if (!await versionDir(s.current).exists()) {
      final prev = s.previous;
      if (prev == null || !await versionDir(prev).exists()) {
        throw InstallStateException(
          'current version ${s.current} folder is missing and no previous version is available',
        );
      }
      s.log(
        _now(),
        'current_missing',
        version: s.current,
        detail: 'falling back to $prev',
      );
      s
        ..current = prev
        ..previous = null;
      await _writeState(s);
    }
    return LaunchDecision(
      version: s.current,
      directory: versionDir(s.current),
      isTrial: false,
      revertedReason: revertedReason,
    );
  }

  /// Called by the app once its startup health check passed (window up,
  /// server reachable, `admin_status` read). Promotes the pending version:
  /// old current becomes previous, the version before that is deleted.
  /// Calling it for the already-current version is a harmless no-op.
  Future<InstallState> confirmHealthy(Version running) async {
    final s = await readState();
    if (s.pending != running) {
      if (s.current == running) return s;
      throw InstallStateException(
        'running $running is neither pending (${s.pending}) nor current (${s.current})',
      );
    }
    await File(
      p.join(versionDir(running).path, confirmedMarkerName),
    ).writeAsString(_now().toIso8601String());
    final oldCurrent = s.current;
    s
      ..previous = oldCurrent
      ..current = running
      ..pending = null
      ..pendingBootAttempts = 0
      ..pendingSince = null
      ..log(
        _now(),
        'confirmed',
        version: running,
        detail: 'previous kept: $oldCurrent',
      );
    await _writeState(s); // persist before deleting anything
    await _pruneVersions(keep: {s.current, s.previous!});
    return s;
  }

  /// Reverts the pending version (launcher: crash / timeout). Records
  /// [reason]; the current version keeps running. No-op when nothing is
  /// pending (e.g. it confirmed in the meantime).
  Future<InstallState> revertPending(String reason) async {
    final s = await readState();
    if (s.pending == null) return s;
    await _revert(s, reason);
    return s;
  }

  Future<void> _revert(InstallState s, String reason) async {
    final failed = s.pending!;
    s
      ..pending = null
      ..pendingBootAttempts = 0
      ..pendingSince = null
      ..lastRevert = RevertRecord(version: failed, reason: reason, at: _now())
      ..log(_now(), 'reverted', version: failed, detail: reason);
    await _writeState(s);
    if (failed != s.current && failed != s.previous) {
      await _deleteDir(versionDir(failed));
    }
  }

  Future<void> _pruneVersions({required Set<Version> keep}) async {
    if (!await versionsDir.exists()) return;
    final keepNames = keep.map((v) => v.toString()).toSet();
    await for (final e in versionsDir.list(followLinks: false)) {
      if (e is Directory && !keepNames.contains(p.basename(e.path))) {
        await _deleteDir(e);
      }
    }
  }

  static Future<void> _deleteDir(Directory d) async {
    if (await d.exists()) await d.delete(recursive: true);
  }
}

/// Extracts a zip into [dest] refusing absolute paths, drive letters, `..`
/// segments and symlinks (zip-slip). [dest] must not exist yet.
Future<void> extractZipSafely(List<int> zipBytes, Directory dest) async {
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(zipBytes, verify: true);
  } catch (e) {
    throw InstallStateException('artifact is not a valid zip: $e');
  }
  await dest.create(recursive: true);
  final base = p.normalize(dest.absolute.path);
  for (final entry in archive) {
    final name = entry.name.replaceAll('\\', '/');
    if (name.isEmpty ||
        name.startsWith('/') ||
        RegExp(r'^[A-Za-z]:').hasMatch(name) ||
        name.split('/').contains('..') ||
        entry.isSymbolicLink) {
      throw InstallStateException('unsafe zip entry "${entry.name}"');
    }
    final out = p.normalize(p.join(base, name));
    if (!p.isWithin(base, out)) {
      throw InstallStateException('unsafe zip entry "${entry.name}"');
    }
    if (entry.isFile) {
      final f = File(out);
      await f.parent.create(recursive: true);
      await f.writeAsBytes(entry.readBytes() ?? const <int>[], flush: true);
    } else {
      await Directory(out).create(recursive: true);
    }
  }
}
