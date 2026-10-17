import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:mtc_update/mtc_update.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers.dart';

String _hex(List<int> b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
Uint8List _unhex(String s) => Uint8List.fromList([
  for (var i = 0; i < s.length; i += 2)
    int.parse(s.substring(i, i + 2), radix: 16),
]);

void main() {
  late SigningKey key; // the "production" key in these tests (temp only)
  late SigningKey otherKey; // a key the app does not trust
  late UpdateVerifier verifier;
  late Directory dir;

  setUpAll(() async {
    key = await SigningKey.generate();
    otherKey = await SigningKey.generate();
  });

  setUp(() {
    dir = tempDir();
    verifier = UpdateVerifier(
      trustedKeys: [key.toTrustedKey('k1')],
      channel: 'stable',
    );
  });

  Future<VerifiedUpdate> run(
    ReleaseManifest m,
    File artifact, {
    required String installed,
    SigningKey? signer,
    UpdateVerifier? using,
    String? blockedBelow,
  }) async {
    final s = await signManifest(m, signer ?? key);
    return (using ?? verifier).verify(
      installed: v(installed),
      manifestBytes: s.bytes,
      signatureText: s.sig,
      artifact: artifact,
      blockedBelow: blockedBelow == null ? null : v(blockedBelow),
    );
  }

  group('Ed25519 (package:cryptography)', () {
    test('matches RFC 8032 test vector 1', () async {
      final k = await SigningKey.fromSeed(
        _unhex(
          '9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60',
        ),
      );
      expect(
        _hex(k.publicKeyBytes),
        'd75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a',
      );
      final sig = await k.sign(const []);
      expect(
        _hex(sig),
        'e5564300c360ac729086e2cc806e828a84877f1eb8e5d974d873e065224901555fb8821590a33bacc61e39701cf9b46bd25bf5f0595bbe24655141438e7a100b',
      );
    });

    test('private key file round-trips', () async {
      final again = await SigningKey.parsePrivateKeyFile(
        key.toPrivateKeyFile(),
      );
      expect(again.publicKeyBase64, key.publicKeyBase64);
      expect(
        () => SigningKey.parsePrivateKeyFile('garbage'),
        throwsFormatException,
      );
    });
  });

  group('manifest', () {
    test('canonical bytes: sorted keys, compact, round-trip', () {
      final a = writeReleaseZip(dir, '1.2.0');
      final m = manifestFor(a, version: '1.2.0');
      final text = utf8.decode(m.toCanonicalBytes());
      expect(
        text,
        startsWith('{"app":"mtc-superadmin","channel":"stable","file":'),
      );
      expect(text, contains('"published_at":"2026-10-17T12:00:00Z"'));
      expect(text, isNot(contains(' ')));
      expect(text, isNot(contains('rollback')));
      final back = ReleaseManifest.parseCanonical(m.toCanonicalBytes());
      expect(back.toCanonicalBytes(), m.toCanonicalBytes());
    });

    test('rejects path-like file names and bad hashes', () {
      expect(
        () => ReleaseManifest(
          version: v('1.0.0'),
          file: r'..\evil.exe',
          size: 1,
          sha256: 'a' * 64,
          minAllowedVersion: v('1.0.0'),
          publishedAt: DateTime.utc(2026),
        ),
        throwsA(isA<ManifestFormatException>()),
      );
      expect(
        () => ReleaseManifest(
          version: v('1.0.0'),
          file: 'a.zip',
          size: 1,
          sha256: 'xyz',
          minAllowedVersion: v('1.0.0'),
          publishedAt: DateTime.utc(2026),
        ),
        throwsA(isA<ManifestFormatException>()),
      );
    });
  });

  group('accepts', () {
    test('valid update', () async {
      final a = writeReleaseZip(dir, '1.2.0');
      final u = await run(
        manifestFor(a, version: '1.2.0'),
        a,
        installed: '1.1.0',
      );
      expect(u.manifest.version, v('1.2.0'));
      expect(u.verifiedManifest.signedBy, 'k1');
      expect(u.verifiedManifest.isMandatory, isFalse);
      expect(u.verifiedManifest.isRollback, isFalse);
    });

    test('prerelease ordering: 1.2.0-beta.1 -> 1.2.0', () async {
      final a = writeReleaseZip(dir, '1.2.0');
      await run(manifestFor(a, version: '1.2.0'), a, installed: '1.2.0-beta.1');
    });

    test('key rotation: old and new key both trusted', () async {
      final rotated = UpdateVerifier(
        trustedKeys: [otherKey.toTrustedKey('new'), key.toTrustedKey('old')],
        channel: 'stable',
      );
      final a = writeReleaseZip(dir, '1.2.0');
      final byOld = await run(
        manifestFor(a, version: '1.2.0'),
        a,
        installed: '1.1.0',
        using: rotated,
      );
      expect(byOld.verifiedManifest.signedBy, 'old');
      final byNew = await run(
        manifestFor(a, version: '1.2.0'),
        a,
        installed: '1.1.0',
        using: rotated,
        signer: otherKey,
      );
      expect(byNew.verifiedManifest.signedBy, 'new');
    });

    test('installed below min_allowed_version -> mandatory', () async {
      final a = writeReleaseZip(dir, '1.3.0');
      final u = await run(
        manifestFor(a, version: '1.3.0', minAllowed: '1.2.0'),
        a,
        installed: '1.1.0',
      );
      expect(u.verifiedManifest.isMandatory, isTrue);
    });

    test('valid signed rollback to exactly the target version', () async {
      final a = writeReleaseZip(dir, '1.1.0');
      final u = await run(
        manifestFor(
          a,
          version: '1.1.0',
          rollbackTo: '1.1.0',
          rollbackFrom: '1.2.0',
        ),
        a,
        installed: '1.2.0',
      );
      expect(u.verifiedManifest.isRollback, isTrue);
    });
  });

  group('rejects', () {
    test('tampered file (same size)', () async {
      final a = writeReleaseZip(dir, '1.2.0');
      final m = manifestFor(a, version: '1.2.0');
      final bytes = a.readAsBytesSync();
      bytes[bytes.length ~/ 2] ^= 0xff;
      a.writeAsBytesSync(bytes);
      await expectLater(
        run(m, a, installed: '1.1.0'),
        rejectedWith(UpdateRejection.fileHashMismatch),
      );
    });

    test('truncated / extended file', () async {
      final a = writeReleaseZip(dir, '1.2.0');
      final m = manifestFor(a, version: '1.2.0');
      a.writeAsBytesSync([...a.readAsBytesSync(), 0]);
      await expectLater(
        run(m, a, installed: '1.1.0'),
        rejectedWith(UpdateRejection.fileSizeMismatch),
      );
    });

    test('artifact name differs from manifest', () async {
      final a = writeReleaseZip(dir, '1.2.0');
      final m = manifestFor(a, version: '1.2.0');
      final renamed = a.renameSync(p.join(dir.path, 'other.zip'));
      await expectLater(
        run(m, renamed, installed: '1.1.0'),
        rejectedWith(UpdateRejection.fileNameMismatch),
      );
    });

    test('tampered manifest (version bumped after signing)', () async {
      final a = writeReleaseZip(dir, '1.2.0');
      final s = await signManifest(manifestFor(a, version: '1.2.0'), key);
      final tampered = utf8.encode(
        utf8
            .decode(s.bytes)
            .replaceFirst('"version":"1.2.0"', '"version":"9.0.0"'),
      );
      await expectLater(
        verifier.verify(
          installed: v('1.1.0'),
          manifestBytes: tampered,
          signatureText: s.sig,
          artifact: a,
        ),
        rejectedWith(UpdateRejection.signatureInvalid),
      );
    });

    test(
      'tampered manifest (sha256 swapped to match a malicious file)',
      () async {
        final a = writeReleaseZip(dir, '1.2.0');
        final s = await signManifest(manifestFor(a, version: '1.2.0'), key);
        final evil = File(p.join(dir.path, 'evil.zip'))
          ..writeAsStringSync('evil');
        final forged = manifestFor(evil, version: '1.2.0').toCanonicalBytes();
        await expectLater(
          verifier.verify(
            installed: v('1.1.0'),
            manifestBytes: forged,
            signatureText: s.sig,
            artifact: evil,
          ),
          rejectedWith(UpdateRejection.signatureInvalid),
        );
      },
    );

    test('signed with an unknown key', () async {
      final a = writeReleaseZip(dir, '1.2.0');
      await expectLater(
        run(
          manifestFor(a, version: '1.2.0'),
          a,
          installed: '1.1.0',
          signer: otherKey,
        ),
        rejectedWith(UpdateRejection.signatureInvalid),
      );
    });

    test('wrong key: signature of a different manifest', () async {
      final a = writeReleaseZip(dir, '1.2.0');
      final good = await signManifest(manifestFor(a, version: '1.2.0'), key);
      final other = await signManifest(manifestFor(a, version: '1.3.0'), key);
      await expectLater(
        verifier.verify(
          installed: v('1.1.0'),
          manifestBytes: good.bytes,
          signatureText: other.sig,
          artifact: a,
        ),
        rejectedWith(UpdateRejection.signatureInvalid),
      );
    });

    test('malformed signature / no trusted keys', () async {
      final a = writeReleaseZip(dir, '1.2.0');
      final s = await signManifest(manifestFor(a, version: '1.2.0'), key);
      await expectLater(
        verifier.verify(
          installed: v('1.1.0'),
          manifestBytes: s.bytes,
          signatureText: 'not base64!!',
          artifact: a,
        ),
        rejectedWith(UpdateRejection.signatureMalformed),
      );
      await expectLater(
        verifier.verify(
          installed: v('1.1.0'),
          manifestBytes: s.bytes,
          signatureText: base64.encode([1, 2, 3]),
          artifact: a,
        ),
        rejectedWith(UpdateRejection.signatureMalformed),
      );
      await expectLater(
        UpdateVerifier(trustedKeys: [], channel: 'stable').verify(
          installed: v('1.1.0'),
          manifestBytes: s.bytes,
          signatureText: s.sig,
          artifact: a,
        ),
        rejectedWith(UpdateRejection.noTrustedKeys),
      );
    });

    test('validly signed but non-canonical or unknown fields', () async {
      final a = writeReleaseZip(dir, '1.2.0');
      final map = manifestFor(a, version: '1.2.0').toCanonicalMap();
      final pretty = await signBytes(
        utf8.encode(const JsonEncoder.withIndent(' ').convert(map)),
        key,
      );
      await expectLater(
        verifier.verify(
          installed: v('1.1.0'),
          manifestBytes: pretty.bytes,
          signatureText: pretty.sig,
          artifact: a,
        ),
        rejectedWith(UpdateRejection.manifestMalformed),
      );
      final extra = await signBytes(
        utf8.encode(jsonEncode({...map, 'zzz': 1})),
        key,
      );
      await expectLater(
        verifier.verify(
          installed: v('1.1.0'),
          manifestBytes: extra.bytes,
          signatureText: extra.sig,
          artifact: a,
        ),
        rejectedWith(UpdateRejection.manifestMalformed),
      );
    });

    test('older version', () async {
      final a = writeReleaseZip(dir, '1.1.0');
      await expectLater(
        run(manifestFor(a, version: '1.1.0'), a, installed: '1.2.0'),
        rejectedWith(UpdateRejection.versionNotNewer),
      );
    });

    test('equal version', () async {
      final a = writeReleaseZip(dir, '1.2.0');
      await expectLater(
        run(manifestFor(a, version: '1.2.0'), a, installed: '1.2.0'),
        rejectedWith(UpdateRejection.versionNotNewer),
      );
    });

    test('prerelease of the installed version is older', () async {
      final a = writeReleaseZip(dir, '1.2.0-rc.1');
      await expectLater(
        run(manifestFor(a, version: '1.2.0-rc.1'), a, installed: '1.2.0'),
        rejectedWith(UpdateRejection.versionNotNewer),
      );
    });

    test('rollback: rollback_to != version', () async {
      final a = writeReleaseZip(dir, '1.1.0');
      await expectLater(
        run(
          manifestFor(
            a,
            version: '1.1.0',
            rollbackTo: '1.0.0',
            rollbackFrom: '1.2.0',
          ),
          a,
          installed: '1.2.0',
        ),
        rejectedWith(UpdateRejection.rollbackNotAllowed),
      );
    });

    test('rollback: issued for another installed version (replay)', () async {
      final a = writeReleaseZip(dir, '1.1.0');
      await expectLater(
        run(
          manifestFor(
            a,
            version: '1.1.0',
            rollbackTo: '1.1.0',
            rollbackFrom: '1.2.0',
          ),
          a,
          installed: '1.3.0',
        ),
        rejectedWith(UpdateRejection.rollbackNotAllowed),
      );
    });

    test('rollback: target not older than installed', () async {
      final a = writeReleaseZip(dir, '1.3.0');
      await expectLater(
        run(
          manifestFor(
            a,
            version: '1.3.0',
            rollbackTo: '1.3.0',
            rollbackFrom: '1.2.0',
          ),
          a,
          installed: '1.2.0',
        ),
        rejectedWith(UpdateRejection.rollbackNotAllowed),
      );
    });

    test('rollback: signed by an unknown key', () async {
      final a = writeReleaseZip(dir, '1.1.0');
      await expectLater(
        run(
          manifestFor(
            a,
            version: '1.1.0',
            rollbackTo: '1.1.0',
            rollbackFrom: '1.2.0',
          ),
          a,
          installed: '1.2.0',
          signer: otherKey,
        ),
        rejectedWith(UpdateRejection.signatureInvalid),
      );
    });

    test('rollback: target below min_allowed_version', () async {
      final a = writeReleaseZip(dir, '1.1.0');
      await expectLater(
        run(
          manifestFor(
            a,
            version: '1.1.0',
            minAllowed: '1.2.0',
            rollbackTo: '1.1.0',
            rollbackFrom: '1.2.0',
          ),
          a,
          installed: '1.2.0',
        ),
        rejectedWith(UpdateRejection.versionBlocked),
      );
    });

    test('version below its own min_allowed_version', () async {
      final a = writeReleaseZip(dir, '1.2.0');
      await expectLater(
        run(
          manifestFor(a, version: '1.2.0', minAllowed: '1.5.0'),
          a,
          installed: '1.1.0',
        ),
        rejectedWith(UpdateRejection.versionBlocked),
      );
    });

    test('version below the locally recorded minimum', () async {
      final a = writeReleaseZip(dir, '1.2.0');
      await expectLater(
        run(
          manifestFor(a, version: '1.2.0', minAllowed: '1.0.0'),
          a,
          installed: '1.1.0',
          blockedBelow: '1.3.0',
        ),
        rejectedWith(UpdateRejection.versionBlocked),
      );
    });

    test('wrong app id', () async {
      final a = writeReleaseZip(dir, '1.2.0');
      await expectLater(
        run(
          manifestFor(a, version: '1.2.0', app: 'mtc-viewer'),
          a,
          installed: '1.1.0',
        ),
        rejectedWith(UpdateRejection.wrongApp),
      );
    });

    test('wrong channel', () async {
      final a = writeReleaseZip(dir, '1.2.0');
      await expectLater(
        run(
          manifestFor(a, version: '1.2.0', channel: 'beta'),
          a,
          installed: '1.1.0',
        ),
        rejectedWith(UpdateRejection.wrongChannel),
      );
    });
  });
}
