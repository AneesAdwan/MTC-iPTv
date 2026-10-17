import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:mtc_update/mtc_update.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

Version v(String s) => Version.parse(s);

/// A fresh temp directory, deleted after the test. Never inside the repo and
/// never under %USERPROFILE%\.mtc-iptv.
Directory tempDir() {
  final d = Directory.systemTemp.createTempSync('mtc_update_test_');
  addTearDown(() {
    if (d.existsSync()) d.deleteSync(recursive: true);
  });
  return d;
}

/// Zip bytes containing [files] (relative path -> text).
Uint8List makeZip(Map<String, String> files) {
  final a = Archive();
  files.forEach((name, text) {
    a.add(ArchiveFile.bytes(name, utf8.encode(text)));
  });
  return ZipEncoder().encodeBytes(a);
}

/// Writes a release zip for [version] into [dir] and returns it.
File writeReleaseZip(Directory dir, String version, {String? name}) {
  final f = File(
    p.join(dir.path, name ?? 'mtc-superadmin-$version-windows.zip'),
  );
  f.writeAsBytesSync(
    makeZip({
      'mtc_superadmin.exe': 'fake exe $version',
      'data/flutter_assets/version.txt': version,
    }),
  );
  return f;
}

/// Builds a manifest describing [artifact].
ReleaseManifest manifestFor(
  File artifact, {
  required String version,
  String minAllowed = '1.0.0',
  String channel = 'stable',
  String app = superAdminAppId,
  String? rollbackTo,
  String? rollbackFrom,
}) {
  return ReleaseManifest(
    app: app,
    version: v(version),
    file: p.basename(artifact.path),
    size: artifact.lengthSync(),
    sha256: sha256OfBytes(artifact.readAsBytesSync()),
    minAllowedVersion: v(minAllowed),
    publishedAt: DateTime.utc(2026, 10, 17, 12),
    channel: channel,
    rollbackTo: rollbackTo == null ? null : v(rollbackTo),
    rollbackFrom: rollbackFrom == null ? null : v(rollbackFrom),
  );
}

class Signed {
  Signed(this.bytes, this.sig);
  final Uint8List bytes;
  final String sig;
}

Future<Signed> signBytes(List<int> bytes, SigningKey key) async =>
    Signed(Uint8List.fromList(bytes), base64.encode(await key.sign(bytes)));

Future<Signed> signManifest(ReleaseManifest m, SigningKey key) =>
    signBytes(m.toCanonicalBytes(), key);

Matcher rejectedWith(UpdateRejection r) => throwsA(
  isA<UpdateRejectedException>().having((e) => e.reason, 'reason', r),
);
