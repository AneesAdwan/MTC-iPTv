/// Every reason the verifier can refuse an update. One value per rejection
/// class so the UI / logs can show a precise, translated message.
enum UpdateRejection {
  /// The verifier was built with an empty trusted-key list (programming error).
  noTrustedKeys,

  /// `manifest.sig` is not base64 of exactly 64 bytes.
  signatureMalformed,

  /// No trusted public key validates the signature over the manifest bytes.
  /// Covers: manifest tampered, signed with a wrong / unknown / retired key.
  signatureInvalid,

  /// Signature is valid but the manifest is structurally invalid, has unknown
  /// fields, or is not in canonical form.
  manifestMalformed,

  /// `app` is not the expected application id.
  wrongApp,

  /// `channel` differs from the channel this install follows.
  wrongChannel,

  /// Normal update whose version is lower than or equal to the installed one
  /// (anti-rollback).
  versionNotNewer,

  /// Rollback manifest that is not acceptable: `rollback_to` != `version`,
  /// `rollback_from` != installed version, or target not older than installed.
  rollbackNotAllowed,

  /// Target version is below the manifest's own `min_allowed_version` or
  /// below the highest minimum this install has already seen (blocked).
  versionBlocked,

  /// The artifact name does not match the manifest `file`.
  fileNameMismatch,

  /// The artifact size differs from the manifest `size`.
  fileSizeMismatch,

  /// The artifact SHA-256 differs from the manifest `sha256`.
  fileHashMismatch,
}

/// Thrown by the verifier. [reason] is stable and machine-readable.
class UpdateRejectedException implements Exception {
  UpdateRejectedException(this.reason, this.message);

  final UpdateRejection reason;
  final String message;

  @override
  String toString() => 'UpdateRejectedException(${reason.name}): $message';
}

/// Structural problem in a manifest (raised while parsing / constructing).
class ManifestFormatException implements Exception {
  ManifestFormatException(this.message);

  final String message;

  @override
  String toString() => 'ManifestFormatException: $message';
}

/// Problem with the side-by-side install layout or its state file.
class InstallStateException implements Exception {
  InstallStateException(this.message);

  final String message;

  @override
  String toString() => 'InstallStateException: $message';
}
