import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Header line of a private key file written by `bin/keygen.dart`.
const String privateKeyFileHeader = 'MTC-SUPERADMIN-ED25519-PRIVATE-KEY v1';

/// Header line of the companion public key file (`<key>.pub`).
const String publicKeyFileHeader = 'MTC-SUPERADMIN-ED25519-PUBLIC-KEY v1';

final Ed25519 _ed25519 = Ed25519();

/// A public key the app trusts to sign release manifests. Embed a const list
/// of these in the app; keep the old key in the list during a rotation window.
class TrustedKey {
  const TrustedKey({required this.id, required this.publicKeyBase64});

  /// Free-form label for logs (e.g. `2026-10`). Not security relevant.
  final String id;

  /// Base64 of the raw 32-byte Ed25519 public key.
  final String publicKeyBase64;

  /// Decoded key bytes; throws [FormatException] when not 32 bytes of base64.
  Uint8List get bytes {
    final b = base64.decode(publicKeyBase64.trim());
    if (b.length != 32) {
      throw FormatException('Ed25519 public key "$id" must be 32 bytes');
    }
    return b;
  }

  SimplePublicKey toPublicKey() =>
      SimplePublicKey(bytes, type: KeyPairType.ed25519);
}

/// An Ed25519 signing key (32-byte seed). Only the signing tool and tests use
/// this; the app never holds a private key.
class SigningKey {
  SigningKey._(this._seed, this._keyPair, this.publicKeyBytes);

  final Uint8List _seed;
  final SimpleKeyPair _keyPair;

  /// Raw 32-byte public key.
  final Uint8List publicKeyBytes;

  String get publicKeyBase64 => base64.encode(publicKeyBytes);

  TrustedKey toTrustedKey(String id) =>
      TrustedKey(id: id, publicKeyBase64: publicKeyBase64);

  /// Generates a fresh random key (uses a CSPRNG via `package:cryptography`).
  static Future<SigningKey> generate() async {
    final kp = await _ed25519.newKeyPair();
    return fromSeed(await kp.extractPrivateKeyBytes());
  }

  /// Builds a key from its 32-byte seed (RFC 8032 "secret key").
  static Future<SigningKey> fromSeed(List<int> seed) async {
    if (seed.length != 32) {
      throw const FormatException('Ed25519 seed must be 32 bytes');
    }
    final s = Uint8List.fromList(seed);
    final kp = await _ed25519.newKeyPairFromSeed(s);
    final pub = await kp.extractPublicKey();
    return SigningKey._(s, kp, Uint8List.fromList(pub.bytes));
  }

  /// Parses the text format written by [toPrivateKeyFile].
  static Future<SigningKey> parsePrivateKeyFile(String text) async {
    final lines = const LineSplitter()
        .convert(text)
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !l.startsWith('#'))
        .toList();
    if (lines.length != 2 || lines[0] != privateKeyFileHeader) {
      throw const FormatException(
        'not an MTC SuperAdmin Ed25519 private key file',
      );
    }
    final List<int> seed;
    try {
      seed = base64.decode(lines[1]);
    } on FormatException {
      throw const FormatException('private key body is not base64');
    }
    return fromSeed(seed);
  }

  /// Private key file contents (header + base64 seed). Keep it secret.
  String toPrivateKeyFile() =>
      '# KEEP SECRET. Never commit, never upload, never paste in chats.\n'
      '$privateKeyFileHeader\n${base64.encode(_seed)}\n';

  /// Public key file contents (safe to share / commit).
  String toPublicKeyFile() => '$publicKeyFileHeader\n$publicKeyBase64\n';

  /// Detached Ed25519 signature over [message] (64 bytes).
  Future<Uint8List> sign(List<int> message) async {
    final sig = await _ed25519.sign(message, keyPair: _keyPair);
    return Uint8List.fromList(sig.bytes);
  }
}

/// Verifies a detached Ed25519 [signature] over [message] with [key].
Future<bool> ed25519Verify(
  List<int> message,
  List<int> signature,
  TrustedKey key,
) async {
  if (signature.length != 64) return false;
  final SimplePublicKey pk;
  try {
    pk = key.toPublicKey();
  } on FormatException {
    return false;
  }
  return _ed25519.verify(
    message,
    signature: Signature(signature, publicKey: pk),
  );
}
