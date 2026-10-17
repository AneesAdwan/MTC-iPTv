import 'dart:io';

import 'package:mtc_update/mtc_update.dart';
import 'package:mtc_update/tooling.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  test(
    'default key path is outside the repo, under %USERPROFILE%\\.mtc-iptv',
    () {
      final path = defaultPrivateKeyPath();
      expect(path, endsWith(p.join('.mtc-iptv', 'superadmin_ed25519.key')));
    },
  );

  test('keygen -> sign_release -> verifier accepts', () async {
    final dir = tempDir();
    final keyPath = p.join(dir.path, 'keys', 'test.key');
    final key = await generateKeyFile(keyPath, restrictAcl: false);
    expect(
      File('$keyPath.pub').readAsStringSync(),
      contains(key.publicKeyBase64),
    );

    final loaded = await loadPrivateKey(keyPath);
    expect(loaded.publicKeyBase64, key.publicKeyBase64);

    final artifact = writeReleaseZip(dir, '1.2.0');
    final r = await signRelease(
      artifactPath: artifact.path,
      key: loaded,
      version: v('1.2.0'),
      minAllowedVersion: v('1.0.0'),
      outDir: p.join(dir.path, 'out'),
    );
    expect(r.manifestFile.existsSync(), isTrue);
    expect(r.signatureFile.existsSync(), isTrue);

    final u =
        await UpdateVerifier(
          trustedKeys: [key.toTrustedKey('t')],
          channel: 'stable',
        ).verify(
          installed: v('1.1.0'),
          manifestBytes: r.manifestFile.readAsBytesSync(),
          signatureText: r.signatureFile.readAsStringSync(),
          artifact: artifact,
        );
    expect(u.manifest.sha256, r.manifest.sha256);
  });

  test('sign_release can produce a signed rollback manifest', () async {
    final dir = tempDir();
    final key = await SigningKey.generate();
    final artifact = writeReleaseZip(dir, '1.1.0');
    final r = await signRelease(
      artifactPath: artifact.path,
      key: key,
      version: v('1.1.0'),
      minAllowedVersion: v('1.0.0'),
      rollbackFrom: v('1.2.0'),
    );
    expect(r.manifest.rollbackTo, v('1.1.0'));
    expect(r.manifest.rollbackFrom, v('1.2.0'));
  });

  test('keygen refuses to overwrite an existing key', () async {
    final dir = tempDir();
    final keyPath = p.join(dir.path, 'a.key');
    await generateKeyFile(keyPath, restrictAcl: false);
    await expectLater(
      generateKeyFile(keyPath, restrictAcl: false),
      throwsA(isA<ToolException>()),
    );
  });

  test('keygen / loadPrivateKey refuse locations inside a git repo', () async {
    final dir = tempDir();
    Directory(p.join(dir.path, '.git')).createSync();
    final keyPath = p.join(dir.path, 'sub', 'b.key');
    await expectLater(
      generateKeyFile(keyPath, restrictAcl: false),
      throwsA(isA<ToolException>()),
    );
    // Throw-away key explicitly allowed in repo, but loading still refuses by default.
    await generateKeyFile(keyPath, restrictAcl: false, allowInRepo: true);
    await expectLater(loadPrivateKey(keyPath), throwsA(isA<ToolException>()));
    expect(
      (await loadPrivateKey(keyPath, allowInRepo: true)).publicKeyBytes,
      hasLength(32),
    );
  });
}
