// Signs a SuperAdmin release artifact.
//
//   dart run bin/sign_release.dart --artifact dist\mtc-superadmin-1.2.0-windows.zip ^
//       --version 1.2.0 --min-allowed 1.0.0 [--channel stable] [--key PATH] [--out DIR]
//
// Signed rollback (install 1.1.0 on machines currently running 1.2.0):
//   dart run bin/sign_release.dart --artifact dist\mtc-superadmin-1.1.0-windows.zip ^
//       --version 1.1.0 --min-allowed 1.0.0 --rollback-from 1.2.0
//
// Writes manifest.json + manifest.sig next to the artifact (or into --out).
import 'dart:io';

import 'package:args/args.dart';
import 'package:mtc_update/mtc_update.dart';
import 'package:mtc_update/tooling.dart';
import 'package:pub_semver/pub_semver.dart';

Future<void> main(List<String> argv) async {
  final parser = ArgParser()
    ..addOption('artifact', help: 'Release zip to sign (required).')
    ..addOption('version', help: 'Semver of the artifact (required).')
    ..addOption('min-allowed', help: 'min_allowed_version (required).')
    ..addOption('channel', defaultsTo: 'stable')
    ..addOption('app', defaultsTo: superAdminAppId)
    ..addOption(
      'rollback-from',
      help: 'Make a signed rollback manifest for this exact installed version.',
    )
    ..addOption(
      'key',
      help: 'Private key path.',
      defaultsTo: defaultPrivateKeyPath(),
    )
    ..addOption('out', help: 'Output folder (default: artifact folder).')
    ..addOption(
      'published-at',
      help: 'Override timestamp (YYYY-MM-DDTHH:MM:SSZ).',
    )
    ..addFlag(
      'allow-key-in-repo',
      help: 'Accept a key inside a git repo (throw-away keys only).',
      negatable: false,
    )
    ..addFlag('help', abbr: 'h', negatable: false);

  final ArgResults a;
  try {
    a = parser.parse(argv);
  } on FormatException catch (e) {
    stderr.writeln('${e.message}\n\n${parser.usage}');
    exit(64);
  }
  if (a.flag('help')) {
    stdout.writeln(
      'Usage: dart run bin/sign_release.dart [options]\n\n${parser.usage}',
    );
    return;
  }
  String req(String name) {
    final v = a.option(name);
    if (v == null || v.isEmpty) {
      stderr.writeln('--$name is required\n\n${parser.usage}');
      exit(64);
    }
    return v;
  }

  try {
    final artifact = req('artifact');
    final version = Version.parse(req('version'));
    final minAllowed = Version.parse(req('min-allowed'));
    final rbf = a.option('rollback-from');
    final pa = a.option('published-at');
    final key = await loadPrivateKey(
      a.option('key')!,
      allowInRepo: a.flag('allow-key-in-repo'),
    );
    final r = await signRelease(
      artifactPath: artifact,
      key: key,
      version: version,
      minAllowedVersion: minAllowed,
      channel: a.option('channel')!,
      app: a.option('app')!,
      rollbackFrom: rbf == null ? null : Version.parse(rbf),
      outDir: a.option('out'),
      publishedAt: pa == null ? null : parseTimestamp(pa),
    );
    stdout
      ..writeln('Signed ${r.manifest}')
      ..writeln('  sha256:    ${r.manifest.sha256}')
      ..writeln('  manifest:  ${r.manifestFile.path}')
      ..writeln('  signature: ${r.signatureFile.path}')
      ..writeln('  key (pub): ${r.publicKeyBase64}')
      ..writeln('Upload the artifact + manifest.json + manifest.sig together.');
  } on ToolException catch (e) {
    stderr.writeln('sign_release: $e');
    exit(1);
  } on ManifestFormatException catch (e) {
    stderr.writeln('sign_release: ${e.message}');
    exit(1);
  } on FormatException catch (e) {
    stderr.writeln('sign_release: ${e.message}');
    exit(64);
  }
}
