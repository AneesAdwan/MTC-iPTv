import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

import 'errors.dart';
import 'keys.dart';
import 'manifest.dart';

/// A manifest whose signature, app id, channel and version rules all passed.
/// Only [UpdateVerifier] creates these.
class VerifiedManifest {
  VerifiedManifest._(this.manifest, this.signedBy, this.installed);

  final ReleaseManifest manifest;

  /// Id of the trusted key that validated the signature.
  final String signedBy;

  /// Installed version the decision was made against.
  final Version installed;

  /// `true` when the installed version is below `min_allowed_version`: the
  /// installed build is blocked and the app must apply this update before
  /// doing anything else (no "later" button).
  bool get isMandatory => installed < manifest.minAllowedVersion;

  bool get isRollback => manifest.isRollback;
}

/// A fully verified update: manifest + artifact bytes on disk matched.
class VerifiedUpdate {
  VerifiedUpdate._(this.verifiedManifest, this.artifact);

  final VerifiedManifest verifiedManifest;

  /// The artifact that was hashed. Hash it again right before use (the
  /// installer does) - files on disk can change after verification.
  final File artifact;

  ReleaseManifest get manifest => verifiedManifest.manifest;
}

/// Verifies downloaded release manifests and artifacts against embedded
/// public keys. Order: signature first (nothing in the manifest is trusted
/// before that), then structure, app / channel, version policy, artifact.
class UpdateVerifier {
  UpdateVerifier({
    required List<TrustedKey> trustedKeys,
    required this.channel,
    this.appId = superAdminAppId,
  }) : trustedKeys = List.unmodifiable(trustedKeys);

  /// Every key that may sign manifests. Supports rotation: list both the new
  /// and the old key for one release cycle, then drop the old one.
  final List<TrustedKey> trustedKeys;

  /// Channel this install follows (e.g. `stable`).
  final String channel;

  /// Expected application id.
  final String appId;

  Never _reject(UpdateRejection r, String msg) =>
      throw UpdateRejectedException(r, msg);

  /// Step 1 (before downloading the artifact): verify `manifest.json` bytes
  /// and the `manifest.sig` text against the installed version.
  ///
  /// [blockedBelow] is the highest `min_allowed_version` this install has ever
  /// accepted (persist `manifest.minAllowedVersion` after each update); a
  /// target below it is refused even if an older manifest says otherwise.
  Future<VerifiedManifest> verifyManifest({
    required Version installed,
    required List<int> manifestBytes,
    required String signatureText,
    Version? blockedBelow,
  }) async {
    if (trustedKeys.isEmpty) {
      _reject(UpdateRejection.noTrustedKeys, 'no trusted keys configured');
    }

    // --- signature -------------------------------------------------------
    final Uint8List sig;
    try {
      sig = base64.decode(signatureText.trim());
    } on FormatException {
      _reject(UpdateRejection.signatureMalformed, 'signature is not base64');
    }
    if (sig.length != 64) {
      _reject(
        UpdateRejection.signatureMalformed,
        'signature must be 64 bytes, got ${sig.length}',
      );
    }
    String? signedBy;
    for (final key in trustedKeys) {
      if (await ed25519Verify(manifestBytes, sig, key)) {
        signedBy = key.id;
        break;
      }
    }
    if (signedBy == null) {
      _reject(
        UpdateRejection.signatureInvalid,
        'no trusted key validates this manifest (tampered or unknown key)',
      );
    }

    // --- structure -------------------------------------------------------
    final ReleaseManifest m;
    try {
      m = ReleaseManifest.parseCanonical(manifestBytes);
    } on ManifestFormatException catch (e) {
      _reject(UpdateRejection.manifestMalformed, e.message);
    }

    // --- identity --------------------------------------------------------
    if (m.app != appId) {
      _reject(
        UpdateRejection.wrongApp,
        'manifest is for "${m.app}", not "$appId"',
      );
    }
    if (m.channel != channel) {
      _reject(
        UpdateRejection.wrongChannel,
        'manifest channel "${m.channel}" != install channel "$channel"',
      );
    }

    // --- version policy --------------------------------------------------
    if (m.version < m.minAllowedVersion) {
      _reject(
        UpdateRejection.versionBlocked,
        '${m.version} is below its own min_allowed_version ${m.minAllowedVersion}',
      );
    }
    if (blockedBelow != null && m.version < blockedBelow) {
      _reject(
        UpdateRejection.versionBlocked,
        '${m.version} is below the locally recorded minimum $blockedBelow',
      );
    }
    if (m.isRollback) {
      if (m.rollbackTo != m.version) {
        _reject(
          UpdateRejection.rollbackNotAllowed,
          'rollback_to ${m.rollbackTo} != version ${m.version}',
        );
      }
      if (m.rollbackFrom != installed) {
        _reject(
          UpdateRejection.rollbackNotAllowed,
          'rollback applies to ${m.rollbackFrom}, installed is $installed',
        );
      }
      if (m.version >= installed) {
        _reject(
          UpdateRejection.rollbackNotAllowed,
          'rollback target ${m.version} is not older than installed $installed',
        );
      }
    } else if (m.version <= installed) {
      _reject(
        UpdateRejection.versionNotNewer,
        '${m.version} is not newer than installed $installed',
      );
    }

    return VerifiedManifest._(m, signedBy, installed);
  }

  /// Step 2 (after download): check the artifact name, size and SHA-256.
  Future<VerifiedUpdate> verifyArtifact(
    VerifiedManifest verified,
    File artifact, {
    bool checkFileName = true,
  }) async {
    final m = verified.manifest;
    if (checkFileName && p.basename(artifact.path) != m.file) {
      _reject(
        UpdateRejection.fileNameMismatch,
        'artifact is "${p.basename(artifact.path)}", manifest says "${m.file}"',
      );
    }
    final len = await artifact.length();
    if (len != m.size) {
      _reject(
        UpdateRejection.fileSizeMismatch,
        'artifact is $len bytes, manifest says ${m.size}',
      );
    }
    final digest = await sha256OfFile(artifact);
    if (digest != m.sha256) {
      _reject(UpdateRejection.fileHashMismatch, 'artifact sha256 mismatch');
    }
    return VerifiedUpdate._(verified, artifact);
  }

  /// Convenience: [verifyManifest] then [verifyArtifact].
  Future<VerifiedUpdate> verify({
    required Version installed,
    required List<int> manifestBytes,
    required String signatureText,
    required File artifact,
    Version? blockedBelow,
    bool checkFileName = true,
  }) async {
    final vm = await verifyManifest(
      installed: installed,
      manifestBytes: manifestBytes,
      signatureText: signatureText,
      blockedBelow: blockedBelow,
    );
    return verifyArtifact(vm, artifact, checkFileName: checkFileName);
  }
}

/// Streaming lowercase-hex SHA-256 of a file.
Future<String> sha256OfFile(File f) async =>
    (await crypto.sha256.bind(f.openRead()).first).toString();

/// Lowercase-hex SHA-256 of bytes.
String sha256OfBytes(List<int> bytes) =>
    crypto.sha256.convert(bytes).toString();
