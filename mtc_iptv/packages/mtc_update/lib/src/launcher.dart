import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

import 'installer.dart';

/// A started app process, as seen by the launcher.
abstract class LaunchedProcess {
  Future<int> get exitCode;
  void kill();
}

/// Starts the app for a [LaunchDecision]. Injected so tests can fake it.
typedef ProcessSpawner = Future<LaunchedProcess> Function(LaunchDecision d);

enum LaunchResult {
  /// Started the confirmed current version (normal start).
  startedCurrent,

  /// Started a pending version and it confirmed healthy in time.
  trialConfirmed,
}

class LaunchOutcome {
  LaunchOutcome(this.result, this.version, this.reverts);

  final LaunchResult result;

  /// Version left running.
  final Version version;

  /// Reasons of reverts that happened during this launch (empty if none).
  final List<String> reverts;
}

/// The launcher's whole job, as one testable function:
///
/// 1. `beginLaunch()` (counts a boot attempt for a pending update, or
///    reverts it when attempts are exhausted);
/// 2. start the chosen version;
/// 3. if it is a trial: wait until the app calls `confirmHealthy()` (seen in
///    `state.json`), it exits, or [healthTimeout] passes;
/// 4. on exit / timeout: kill it, `revertPending(reason)`, and start the
///    current version instead.
Future<LaunchOutcome> superviseLaunch({
  required SideBySideInstaller installer,
  required ProcessSpawner spawn,
  Duration healthTimeout = const Duration(seconds: 90),
  Duration pollInterval = const Duration(milliseconds: 500),
}) async {
  final reverts = <String>[];
  // At most: one trial + one fallback start.
  for (var round = 0; round < 3; round++) {
    final d = await installer.beginLaunch();
    if (d.revertedReason != null) reverts.add(d.revertedReason!);
    final proc = await spawn(d);
    if (!d.isTrial) {
      return LaunchOutcome(LaunchResult.startedCurrent, d.version, reverts);
    }

    int? exitCode;
    unawaited(proc.exitCode.then((c) => exitCode = c));
    final deadline = DateTime.now().add(healthTimeout);
    var confirmed = false;
    while (true) {
      final s = await installer.readState();
      if (s.pending != d.version && s.current == d.version) {
        confirmed = true;
        break;
      }
      if (exitCode != null || !DateTime.now().isBefore(deadline)) break;
      await Future<void>.delayed(pollInterval);
    }
    if (confirmed) {
      return LaunchOutcome(LaunchResult.trialConfirmed, d.version, reverts);
    }

    final String reason;
    if (exitCode != null) {
      reason = 'exited with code $exitCode before confirming health';
    } else {
      proc.kill();
      reason = 'no health confirmation within ${healthTimeout.inSeconds}s';
    }
    reverts.add(reason);
    await installer.revertPending(reason);
  }
  throw StateError('launcher could not settle on a version');
}

/// Real process spawner: runs `<versionDir>\<exeRelativePath>`.
ProcessSpawner ioProcessSpawner(
  String exeRelativePath, {
  List<String> arguments = const [],
}) {
  return (d) async {
    final exe = p.join(d.directory.path, exeRelativePath);
    // Normal start: detached, the launcher exits right away. Trial start:
    // attached so the launcher can see an early exit (output discarded).
    final proc = await Process.start(
      exe,
      [...arguments, if (d.isTrial) '--mtc-update-trial'],
      workingDirectory: d.directory.path,
      mode: d.isTrial ? ProcessStartMode.normal : ProcessStartMode.detached,
    );
    if (d.isTrial) {
      unawaited(proc.stdout.drain<void>());
      unawaited(proc.stderr.drain<void>());
    }
    return _IoProcess(proc, attached: d.isTrial);
  };
}

class _IoProcess implements LaunchedProcess {
  _IoProcess(this._p, {required this.attached});
  final Process _p;
  final bool attached;

  @override
  Future<int> get exitCode => attached ? _p.exitCode : Completer<int>().future; // detached: unknown

  @override
  void kill() => _p.kill();
}
