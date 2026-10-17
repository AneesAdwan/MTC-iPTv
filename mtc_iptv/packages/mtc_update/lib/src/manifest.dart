import 'dart:convert';
import 'dart:typed_data';

import 'package:pub_semver/pub_semver.dart';

import 'errors.dart';

/// The only application id this package is built for.
const String superAdminAppId = 'mtc-superadmin';

/// Current manifest schema number. Bump only with a coordinated verifier change.
const int manifestSchema = 1;

final RegExp _sha256Hex = RegExp(r'^[0-9a-f]{64}$');
final RegExp _channelRe = RegExp(r'^[a-z][a-z0-9-]{0,31}$');
final RegExp _appRe = RegExp(r'^[a-z][a-z0-9-]{0,63}$');
// A bare file name: no directory separators, no drive letters, no "..".
final RegExp _fileNameRe = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._+-]{0,199}$');

/// A release manifest. Its canonical byte encoding ([toCanonicalBytes]) is
/// exactly what is written to `manifest.json` and what the Ed25519 signature
/// in `manifest.sig` covers.
///
/// Canonical encoding rules:
/// * UTF-8 JSON object, no insignificant whitespace, keys sorted by code unit;
/// * optional fields (`rollback_to`, `rollback_from`) are omitted when null;
/// * `version` / `min_allowed_version` / `rollback_*` are normalized semver
///   strings (`Version.toString()`);
/// * `published_at` is UTC, second precision: `YYYY-MM-DDTHH:MM:SSZ`;
/// * `sha256` is lowercase hex, `size` is an integer byte count.
///
/// The verifier requires the downloaded bytes to be *byte-identical* to the
/// canonical re-encoding of what it parsed, which rules out duplicate keys,
/// unknown fields and JSON-parser differentials.
class ReleaseManifest {
  ReleaseManifest({
    this.app = superAdminAppId,
    required this.version,
    required this.file,
    required this.size,
    required String sha256,
    required this.minAllowedVersion,
    required DateTime publishedAt,
    this.channel = 'stable',
    this.rollbackTo,
    this.rollbackFrom,
  }) : sha256 = sha256.toLowerCase(),
       publishedAt = _truncateToSecondsUtc(publishedAt) {
    _validate();
  }

  /// Application id; must be [superAdminAppId] for SuperAdmin.
  final String app;

  /// Version of the artifact this manifest describes.
  final Version version;

  /// Bare file name of the artifact (e.g. `mtc-superadmin-1.2.0-windows.zip`).
  final String file;

  /// Exact artifact size in bytes.
  final int size;

  /// Lowercase hex SHA-256 of the artifact.
  final String sha256;

  /// Versions below this are considered blocked (e.g. known vulnerable): an
  /// installed version below it must update, and nothing below it may ever be
  /// installed (including through a rollback manifest).
  final Version minAllowedVersion;

  /// Publication time (UTC, second precision).
  final DateTime publishedAt;

  /// Release channel (`stable`, `beta`, ...).
  final String channel;

  /// Set only on a *rollback manifest*: must equal [version]. Explicitly
  /// authorizes installing [version] even though it is older than the
  /// installed one.
  final Version? rollbackTo;

  /// Required with [rollbackTo]: the exact installed version this rollback may
  /// be applied to. Binds the rollback so an old rollback manifest cannot be
  /// replayed later against a newer install.
  final Version? rollbackFrom;

  bool get isRollback => rollbackTo != null;

  void _validate() {
    void bad(String why) => throw ManifestFormatException(why);
    if (!_appRe.hasMatch(app)) bad('invalid app id "$app"');
    if (!_channelRe.hasMatch(channel)) bad('invalid channel "$channel"');
    if (!_fileNameRe.hasMatch(file) || file.contains('..')) {
      bad('invalid file name "$file" (must be a bare file name)');
    }
    if (size < 0) bad('negative size');
    if (!_sha256Hex.hasMatch(sha256)) {
      bad('sha256 must be 64 lowercase hex chars');
    }
    if ((rollbackTo == null) != (rollbackFrom == null)) {
      bad('rollback_to and rollback_from must be set together');
    }
  }

  /// Canonical map (sorted keys, normalized values).
  Map<String, Object> toCanonicalMap() {
    final m = <String, Object>{
      'app': app,
      'channel': channel,
      'file': file,
      'min_allowed_version': minAllowedVersion.toString(),
      'published_at': formatTimestamp(publishedAt),
      if (rollbackFrom != null) 'rollback_from': rollbackFrom.toString(),
      if (rollbackTo != null) 'rollback_to': rollbackTo.toString(),
      'schema': manifestSchema,
      'sha256': sha256,
      'size': size,
      'version': version.toString(),
    };
    final keys = m.keys.toList()..sort();
    return {for (final k in keys) k: m[k]!};
  }

  /// The exact bytes that are written to `manifest.json` and signed.
  Uint8List toCanonicalBytes() =>
      Uint8List.fromList(utf8.encode(jsonEncode(toCanonicalMap())));

  /// Parses manifest bytes strictly. Throws [ManifestFormatException] on any
  /// structural problem, unknown field or non-canonical encoding.
  static ReleaseManifest parseCanonical(List<int> bytes) {
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on FormatException catch (e) {
      throw ManifestFormatException('not valid UTF-8 JSON: ${e.message}');
    }
    if (decoded is! Map<String, dynamic>) {
      throw ManifestFormatException('manifest must be a JSON object');
    }
    final Map<String, dynamic> map = decoded;
    const allowed = {
      'app', 'channel', 'file', 'min_allowed_version', 'published_at', //
      'rollback_from', 'rollback_to', 'schema', 'sha256', 'size', 'version',
    };
    for (final k in decoded.keys) {
      if (!allowed.contains(k)) {
        throw ManifestFormatException('unknown field "$k"');
      }
    }
    if (decoded['schema'] != manifestSchema) {
      throw ManifestFormatException('unsupported schema ${decoded['schema']}');
    }
    String str(String k) {
      final v = map[k];
      if (v is! String) throw ManifestFormatException('"$k" must be a string');
      return v;
    }

    String? optStr(String k) {
      final v = map[k];
      if (v == null) return null;
      if (v is! String) throw ManifestFormatException('"$k" must be a string');
      return v;
    }

    final size = decoded['size'];
    if (size is! int) {
      throw ManifestFormatException('"size" must be an integer');
    }

    final manifest = ReleaseManifest(
      app: str('app'),
      channel: str('channel'),
      version: parseVersion(str('version'), 'version'),
      file: str('file'),
      size: size,
      sha256: str('sha256'),
      minAllowedVersion: parseVersion(
        str('min_allowed_version'),
        'min_allowed_version',
      ),
      publishedAt: parseTimestamp(str('published_at')),
      rollbackTo: _optVersion(optStr('rollback_to'), 'rollback_to'),
      rollbackFrom: _optVersion(optStr('rollback_from'), 'rollback_from'),
    );
    final canonical = manifest.toCanonicalBytes();
    if (!_bytesEqual(canonical, bytes)) {
      throw ManifestFormatException('manifest bytes are not canonical');
    }
    return manifest;
  }

  static Version? _optVersion(String? s, String field) =>
      s == null ? null : parseVersion(s, field);

  @override
  String toString() =>
      'ReleaseManifest($app $version${isRollback ? ' [rollback from $rollbackFrom]' : ''}, '
      '$channel, $file, $size bytes)';
}

/// Parses a semver string; throws [ManifestFormatException] when invalid.
Version parseVersion(String s, [String field = 'version']) {
  try {
    return Version.parse(s);
  } on FormatException {
    throw ManifestFormatException('"$field" is not a valid semver: "$s"');
  }
}

/// `YYYY-MM-DDTHH:MM:SSZ`.
String formatTimestamp(DateTime t) {
  final u = t.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${u.year.toString().padLeft(4, '0')}-${two(u.month)}-${two(u.day)}'
      'T${two(u.hour)}:${two(u.minute)}:${two(u.second)}Z';
}

final RegExp _tsRe = RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$');

DateTime parseTimestamp(String s) {
  if (!_tsRe.hasMatch(s)) {
    throw ManifestFormatException(
      '"published_at" must be YYYY-MM-DDTHH:MM:SSZ',
    );
  }
  final t = DateTime.tryParse(s);
  if (t == null || formatTimestamp(t) != s) {
    throw ManifestFormatException('"published_at" is not a valid date');
  }
  return t;
}

DateTime _truncateToSecondsUtc(DateTime t) {
  final u = t.toUtc();
  return DateTime.utc(u.year, u.month, u.day, u.hour, u.minute, u.second);
}

bool _bytesEqual(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
