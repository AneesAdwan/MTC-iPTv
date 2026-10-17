// Creates the SuperAdmin release-signing key pair ONCE.
//
//   dart run bin/keygen.dart                    # -> %USERPROFILE%\.mtc-iptv\superadmin_ed25519.key
//   dart run bin/keygen.dart --out D:\keys\x.key
//
// Prints the public key to embed in the app (TrustedKey list).
import 'dart:io';

import 'package:args/args.dart';
import 'package:mtc_update/tooling.dart';

Future<void> main(List<String> argv) async {
  final parser = ArgParser()
    ..addOption(
      'out',
      help: 'Private key path (public key goes to <out>.pub).',
      defaultsTo: defaultPrivateKeyPath(),
    )
    ..addOption(
      'id',
      help: 'Label for the key in the app list.',
      defaultsTo: 'superadmin-${DateTime.now().toUtc().year}',
    )
    ..addFlag(
      'allow-in-repo',
      help: 'Allow writing inside a git repo (throw-away keys only).',
      negatable: false,
    )
    ..addFlag(
      'no-acl',
      help: 'Do not restrict the Windows ACL of the key file.',
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
      'Usage: dart run bin/keygen.dart [options]\n\n${parser.usage}',
    );
    return;
  }

  final out = a.option('out')!;
  try {
    final key = await generateKeyFile(
      out,
      allowInRepo: a.flag('allow-in-repo'),
      restrictAcl: !a.flag('no-acl'),
    );
    stdout
      ..writeln(
        'Private key written: $out   (KEEP SECRET - back it up offline)',
      )
      ..writeln('Public key written:  $out.pub')
      ..writeln()
      ..writeln('Public key (base64): ${key.publicKeyBase64}')
      ..writeln()
      ..writeln('Embed in the SuperAdmin app:')
      ..writeln(
        "  TrustedKey(id: '${a.option('id')}', publicKeyBase64: '${key.publicKeyBase64}'),",
      );
  } on ToolException catch (e) {
    stderr.writeln('keygen: $e');
    exit(1);
  }
}
