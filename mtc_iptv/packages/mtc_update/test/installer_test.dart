import 'dart:async';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:mtc_update/mtc_update.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers.dart';

class FakeProcess implements LaunchedProcess {
  final Completer<int> _exit = Completer<int>();
  bool killed = false;

  void exit(int code) {
    if (!_exit.isCompleted) _exit.complete(code);
  }

  @override
  Future<int> get exitCode => _exit.future;

  @override
  void kill() {
    killed = true;
    exit(-1);
  }
}

void main() {
  late SigningKey key;
  late UpdateVerifier verifier;
  late Directory work; // downloads
  late Directory root; // install root
  late SideBySideInstaller inst;

  setUpAll(() async {
    key = await SigningKey.generate();
    verifier = UpdateVerifier(
      trustedKeys: [key.toTrustedKey('k1')],
      channel: 'stable',
    );
  });

  setUp(() async {
    work = tempDir();
    root = tempDir();
    inst = SideBySideInstaller(root, maxBootAttempts: 2);
    final d = inst.versionDir(v('1.0.0'))..createSync(recursive: true);
    File(
      p.join(d.path, 'mtc_superadmin.exe'),
    ).writeAsStringSync('fake exe 1.0.0');
    await inst.adoptInitial(v('1.0.0'));
  });

  Future<VerifiedUpdate> download(
    String version, {
    required String installed,
    String? rollbackFrom,
  }) async {
    final a = writeReleaseZip(work, version);
    final m = manifestFor(
      a,
      version: version,
      rollbackTo: rollbackFrom == null ? null : version,
      rollbackFrom: rollbackFrom,
    );
    final s = await signManifest(m, key);
    return verifier.verify(
      installed: v(installed),
      manifestBytes: s.bytes,
      signatureText: s.sig,
      artifact: a,
    );
  }

  Future<void> updateTo(String version, {required String from}) async {
    await inst.stage(await download(version, installed: from));
    final d = await inst.beginLaunch();
    expect(d.isTrial, isTrue);
    await inst.confirmHealthy(v(version));
  }

  group('side-by-side', () {
    test('stage -> trial -> confirm: new current, previous kept', () async {
      final s = await inst.stage(await download('1.1.0', installed: '1.0.0'));
      expect(s.pending, v('1.1.0'));
      expect(s.current, v('1.0.0'));
      final exe = File(
        p.join(inst.versionDir(v('1.1.0')).path, 'mtc_superadmin.exe'),
      );
      expect(exe.readAsStringSync(), 'fake exe 1.1.0');
      // Running version untouched while staging.
      expect(inst.versionDir(v('1.0.0')).existsSync(), isTrue);

      final d = await inst.beginLaunch();
      expect(d.isTrial, isTrue);
      expect(d.version, v('1.1.0'));

      final after = await inst.confirmHealthy(v('1.1.0'));
      expect(after.current, v('1.1.0'));
      expect(after.previous, v('1.0.0'));
      expect(after.pending, isNull);
      expect(inst.versionDir(v('1.0.0')).existsSync(), isTrue);
      expect(
        File(
          p.join(inst.versionDir(v('1.1.0')).path, confirmedMarkerName),
        ).existsSync(),
        isTrue,
      );

      final next = await inst.beginLaunch();
      expect(next.isTrial, isFalse);
      expect(next.version, v('1.1.0'));
    });

    test('previous kept only until the next successful update', () async {
      await updateTo('1.1.0', from: '1.0.0');
      await updateTo('1.2.0', from: '1.1.0');
      final s = await inst.readState();
      expect(s.current, v('1.2.0'));
      expect(s.previous, v('1.1.0'));
      expect(inst.versionDir(v('1.0.0')).existsSync(), isFalse);
      expect(inst.versionDir(v('1.1.0')).existsSync(), isTrue);
    });

    test('confirmHealthy on the current version is a no-op', () async {
      final s = await inst.confirmHealthy(v('1.0.0'));
      expect(s.current, v('1.0.0'));
      expect(s.pending, isNull);
    });

    test(
      'no confirmation after maxBootAttempts -> auto-revert with reason',
      () async {
        await inst.stage(await download('1.1.0', installed: '1.0.0'));
        expect(
          (await inst.beginLaunch()).isTrial,
          isTrue,
        ); // attempt 1 (crashed)
        expect(
          (await inst.beginLaunch()).isTrial,
          isTrue,
        ); // attempt 2 (crashed)
        final d = await inst.beginLaunch(); // exhausted -> revert
        expect(d.isTrial, isFalse);
        expect(d.version, v('1.0.0'));
        expect(d.revertedReason, contains('did not confirm healthy after 2'));

        final s = await inst.readState();
        expect(s.current, v('1.0.0'));
        expect(s.pending, isNull);
        expect(s.lastRevert!.version, v('1.1.0'));
        expect(s.lastRevert!.reason, contains('did not confirm'));
        expect(s.history.map((h) => h.event), contains('reverted'));
        expect(inst.versionDir(v('1.1.0')).existsSync(), isFalse);
        expect(inst.versionDir(v('1.0.0')).existsSync(), isTrue);
      },
    );

    test('artifact swapped after verification is refused at staging', () async {
      final u = await download('1.1.0', installed: '1.0.0');
      final bytes = u.artifact.readAsBytesSync();
      bytes[10] ^= 0x01;
      u.artifact.writeAsBytesSync(bytes);
      await expectLater(
        inst.stage(u),
        rejectedWith(UpdateRejection.fileHashMismatch),
      );
      expect((await inst.readState()).pending, isNull);
      expect(inst.versionDir(v('1.1.0')).existsSync(), isFalse);
    });

    test('zip-slip entries are refused', () async {
      final a = Archive()..add(ArchiveFile.bytes('../evil.txt', [1, 2, 3]));
      final out = Directory(p.join(work.path, 'x'));
      await expectLater(
        extractZipSafely(ZipEncoder().encodeBytes(a), out),
        throwsA(isA<InstallStateException>()),
      );
      expect(File(p.join(work.path, 'evil.txt')).existsSync(), isFalse);
    });

    test('signed rollback to the kept previous version', () async {
      await updateTo('1.1.0', from: '1.0.0');
      final u = await download(
        '1.0.0',
        installed: '1.1.0',
        rollbackFrom: '1.1.0',
      );
      final s = await inst.stage(u);
      expect(s.pending, v('1.0.0'));
      expect((await inst.beginLaunch()).version, v('1.0.0'));
      final after = await inst.confirmHealthy(v('1.0.0'));
      expect(after.current, v('1.0.0'));
      expect(after.previous, v('1.1.0'));
    });

    test('missing current folder falls back to previous', () async {
      await updateTo('1.1.0', from: '1.0.0');
      inst.versionDir(v('1.1.0')).deleteSync(recursive: true);
      final d = await inst.beginLaunch();
      expect(d.version, v('1.0.0'));
      expect((await inst.readState()).history.last.event, 'current_missing');
    });
  });

  group('corrupted state file', () {
    test('garbage state.json -> restored from state.json.bak', () async {
      await updateTo('1.1.0', from: '1.0.0'); // ensures a .bak exists
      inst.stateFile.writeAsStringSync('{"schema":1, broken');
      final s = await inst.readState();
      expect(s.recoveredFromCorruption, isTrue);
      expect(s.current, isNotNull);
      expect(s.history.last.event, 'state_recovered');
      // Written back: next read is clean.
      expect((await inst.readState()).recoveredFromCorruption, isFalse);
    });

    test('state.json and backup unreadable -> rebuilt from markers', () async {
      await updateTo('1.1.0', from: '1.0.0');
      inst.stateFile.writeAsStringSync('');
      File('${inst.stateFile.path}.bak').writeAsStringSync('nope');
      final s = await inst.readState();
      expect(s.recoveredFromCorruption, isTrue);
      expect(s.current, v('1.1.0'));
      expect(s.previous, v('1.0.0'));
      expect(s.pending, isNull);
    });

    test(
      'pending update + corrupted state -> pending dropped, safe version runs',
      () async {
        await inst.stage(await download('1.1.0', installed: '1.0.0'));
        inst.stateFile.writeAsStringSync('\u0000\u0001');
        File('${inst.stateFile.path}.bak').deleteSync();
        final d = await inst.beginLaunch();
        expect(d.version, v('1.0.0'));
        expect(d.isTrial, isFalse);
      },
    );

    test(
      'semantically invalid state (pending == current) is treated as corrupt',
      () async {
        inst.stateFile.writeAsStringSync(
          '{"schema":1,"current":"1.0.0","pending":"1.0.0","history":[]}',
        );
        final s = await inst.readState();
        expect(s.recoveredFromCorruption, isTrue);
        expect(s.pending, isNull);
      },
    );

    test('nothing recoverable -> InstallStateException', () async {
      inst.stateFile.writeAsStringSync('x');
      final bak = File('${inst.stateFile.path}.bak');
      if (bak.existsSync()) bak.deleteSync();
      File(
        p.join(inst.versionDir(v('1.0.0')).path, confirmedMarkerName),
      ).deleteSync();
      await expectLater(
        inst.readState(),
        throwsA(isA<InstallStateException>()),
      );
    });
  });

  group('superviseLaunch (launcher logic)', () {
    test('normal start of the current version', () async {
      final out = await superviseLaunch(
        installer: inst,
        spawn: (d) async => FakeProcess(),
      );
      expect(out.result, LaunchResult.startedCurrent);
      expect(out.version, v('1.0.0'));
      expect(out.reverts, isEmpty);
    });

    test('trial confirms in time -> promoted', () async {
      await inst.stage(await download('1.1.0', installed: '1.0.0'));
      final out = await superviseLaunch(
        installer: inst,
        healthTimeout: const Duration(seconds: 5),
        pollInterval: const Duration(milliseconds: 10),
        spawn: (d) async {
          // The "app" confirms after its health check.
          if (d.isTrial) {
            Timer(
              const Duration(milliseconds: 50),
              () => inst.confirmHealthy(d.version),
            );
          }
          return FakeProcess();
        },
      );
      expect(out.result, LaunchResult.trialConfirmed);
      expect(out.version, v('1.1.0'));
      final s = await inst.readState();
      expect(s.current, v('1.1.0'));
      expect(s.previous, v('1.0.0'));
    });

    test(
      'trial crashes on start -> reverted, previous started, reason recorded',
      () async {
        await inst.stage(await download('1.1.0', installed: '1.0.0'));
        final started = <String>[];
        final out = await superviseLaunch(
          installer: inst,
          healthTimeout: const Duration(seconds: 5),
          pollInterval: const Duration(milliseconds: 10),
          spawn: (d) async {
            started.add(d.version.toString());
            final proc = FakeProcess();
            if (d.isTrial) proc.exit(3); // crash
            return proc;
          },
        );
        expect(started, ['1.1.0', '1.0.0']);
        expect(out.result, LaunchResult.startedCurrent);
        expect(out.version, v('1.0.0'));
        expect(out.reverts.single, contains('exited with code 3'));
        final s = await inst.readState();
        expect(s.lastRevert!.reason, contains('exited with code 3'));
        expect(s.lastRevert!.version, v('1.1.0'));
        expect(s.pending, isNull);
      },
    );

    test(
      'trial hangs without confirming -> killed and reverted after timeout',
      () async {
        await inst.stage(await download('1.1.0', installed: '1.0.0'));
        final procs = <FakeProcess>[];
        final out = await superviseLaunch(
          installer: inst,
          healthTimeout: const Duration(milliseconds: 200),
          pollInterval: const Duration(milliseconds: 10),
          spawn: (d) async {
            final proc = FakeProcess();
            procs.add(proc);
            return proc;
          },
        );
        expect(procs.first.killed, isTrue);
        expect(out.version, v('1.0.0'));
        expect(out.reverts.single, contains('no health confirmation'));
        expect(
          (await inst.readState()).lastRevert!.reason,
          contains('no health confirmation'),
        );
      },
    );
  });
}
