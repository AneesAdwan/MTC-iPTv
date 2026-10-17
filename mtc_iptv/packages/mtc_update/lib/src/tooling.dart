import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

import 'keys.dart';
import 'manifest.dart';
import 'verifier.dart';

/// `%USERPROFILE%\.mtc-iptv\superadmin_ed25519.key` (outside every repo).
String defaultPrivateKeyPath() {
  final home =
      Platform.environment['USERPROFILE'] ??
      Platform.environment['HOME'] ??
      '.';
  return p.join(home, '.mtc-iptv', 'superadmin_ed25519.key');
}

/// `true` when [path] (or one of its parents) contains a `.git` entry.
bool isInsideGitRepo(String path) {
  var dir = p.normalize(p.absolute(path));
  while (true) {
    if (FileSystemEntity.typeSync(p.join(dir, '.git')) !=
        FileSystemEntityType.notFound) {
      return true;
    }
    final parent = p.dirname(dir);
    if (parent == dir) return false;
    dir = parent;
  }
}

class ToolException implements Exception {
  ToolException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Creates a new key pair: private key at [path], public key at `[path].pub`.
/// Refuses to overwrite and (unless [allowInRepo]) refuses any location
/// inside a git working tree. On Windows the private key's ACL is reduced to
/// the current user when [restrictAcl] is set.
Future<SigningKey> generateKeyFile(
  String path, {
  bool allowInRepo = false,
  bool restrictAcl = true,
}) async {
  final keyFile = File(path);
  final pubFile = File('$path.pub');
  if (await keyFile.exists() || await pubFile.exists()) {
    throw ToolException(
      'refusing to overwrite existing key at $path (delete it yourself if you really mean it)',
    );
  }
  if (!allowInRepo && isInsideGitRepo(p.dirname(p.absolute(path)))) {
    throw ToolException(
      'refusing to write a private key inside a git repository: $path',
    );
  }
  await keyFile.parent.create(recursive: true);
  final key = await SigningKey.generate();
  await keyFile.writeAsString(key.toPrivateKeyFile(), flush: true);
  await pubFile.writeAsString(key.toPublicKeyFile(), flush: true);
  if (restrictAcl && Platform.isWindows) {
    final user = Platform.environment['USERNAME'];
    if (user != null) {
      final r = await Process.run('icacls', [
        keyFile.path,
        '/inheritance:r',
        '/grant:r',
        '$user:F',
      ]);
      if (r.exitCode != 0) {
        stderr.writeln('warning: could not restrict ACL: ${r.stderr}');
      }
    }
  }
  return key;
}

/// Loads a private key file written by [generateKeyFile].
Future<SigningKey> loadPrivateKey(
  String path, {
  bool allowInRepo = false,
}) async {
  final f = File(path);
  if (!await f.exists()) throw ToolException('private key not found: $path');
  if (!allowInRepo && isInsideGitRepo(p.dirname(p.absolute(path)))) {
    throw ToolException(
      'private key is inside a git repository ($path) - move it out (or pass --allow-key-in-repo for throw-away keys)',
    );
  }
  try {
    return await SigningKey.parsePrivateKeyFile(await f.readAsString());
  } on FormatException catch (e) {
    throw ToolException('cannot read private key: ${e.message}');
  }
}

class SignResult {
  SignResult(
    this.manifest,
    this.manifestFile,
    this.signatureFile,
    this.publicKeyBase64,
  );
  final ReleaseManifest manifest;
  final File manifestFile;
  final File signatureFile;
  final String publicKeyBase64;
}

/// Hashes [artifactPath], builds the manifest, writes `manifest.json`
/// (canonical bytes) and `manifest.sig` (base64 Ed25519 signature) into
/// [outDir] (default: the artifact's folder), then self-verifies.
///
/// For a signed rollback pass [rollbackFrom] (the exact installed version
/// being rolled back): the manifest gets `rollback_to = version`.
Future<SignResult> signRelease({
  required String artifactPath,
  required SigningKey key,
  required Version version,
  required Version minAllowedVersion,
  String channel = 'stable',
  String app = superAdminAppId,
  Version? rollbackFrom,
  String? outDir,
  DateTime? publishedAt,
}) async {
  final artifact = File(artifactPath);
  if (!await artifact.exists()) {
    throw ToolException('artifact not found: $artifactPath');
  }
  final manifest = ReleaseManifest(
    app: app,
    version: version,
    file: p.basename(artifact.path),
    size: await artifact.length(),
    sha256: await sha256OfFile(artifact),
    minAllowedVersion: minAllowedVersion,
    publishedAt: publishedAt ?? DateTime.now().toUtc(),
    channel: channel,
    rollbackTo: rollbackFrom == null ? null : version,
    rollbackFrom: rollbackFrom,
  );
  final bytes = manifest.toCanonicalBytes();
  final sig = await key.sign(bytes);
  final trusted = key.toTrustedKey('self-check');
  if (!await ed25519Verify(bytes, sig, trusted)) {
    throw ToolException('self-verification of the signature failed');
  }
  final dir = Directory(outDir ?? artifact.parent.path);
  await dir.create(recursive: true);
  final mf = File(p.join(dir.path, 'manifest.json'));
  final sf = File(p.join(dir.path, 'manifest.sig'));
  await mf.writeAsBytes(bytes, flush: true);
  await sf.writeAsString('${base64.encode(sig)}\n', flush: true);
  return SignResult(manifest, mf, sf, key.publicKeyBase64);
}
