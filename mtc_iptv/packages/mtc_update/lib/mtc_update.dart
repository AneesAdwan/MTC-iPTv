/// Secure self-update for MTC-iPTv SuperAdmin (pure Dart, no Flutter).
///
/// * [ReleaseManifest] - signed release description, canonical bytes.
/// * [UpdateVerifier] - Ed25519 signature, app/channel, anti-rollback,
///   min_allowed_version, size + SHA-256 of the artifact.
/// * [SideBySideInstaller] - `versions\<ver>\` layout, pending trial,
///   `confirmHealthy()`, automatic revert with recorded reason.
/// * [superviseLaunch] - the launcher logic.
library;

export 'src/errors.dart';
export 'src/install_state.dart';
export 'src/installer.dart';
export 'src/keys.dart';
export 'src/launcher.dart';
export 'src/manifest.dart';
export 'src/verifier.dart';
