// فك ترميز الملف المستورد (§10.2): gzip، ثم الترميز من المحتوى: BOM لـ UTF-8/UTF-16، UTF-8 صالح،
// وإلا Windows-1256 (ملفات عربية قديمة). كل ملف مُدخل غير موثوق: حدّ حجم بعد فك الضغط.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class DecodedText {
  final String text;
  final String encoding; // utf-8 | utf-16le | utf-16be | windows-1256
  final bool gzipped;
  const DecodedText(this.text, this.encoding, {this.gzipped = false});
}

class ImportTooLarge implements Exception {
  final int bytes;
  const ImportTooLarge(this.bytes);
  @override
  String toString() => 'ImportTooLarge($bytes bytes)';
}

/// الحد الأقصى بعد فك الضغط (قنبلة gzip): 64MB.
const maxImportBytes = 64 * 1024 * 1024;

DecodedText decodeImport(List<int> input) {
  var bytes = input is Uint8List ? input : Uint8List.fromList(input);
  var gz = false;
  if (bytes.length > 2 && bytes[0] == 0x1f && bytes[1] == 0x8b) {
    final cap = _CappedSink();
    gzip.decoder.startChunkedConversion(cap)
      ..add(bytes)
      ..close();
    bytes = cap.out.takeBytes();
    gz = true;
  }
  if (bytes.length > maxImportBytes) throw ImportTooLarge(bytes.length);

  if (bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
    return DecodedText(utf8.decode(bytes.sublist(3), allowMalformed: true), 'utf-8', gzipped: gz);
  }
  if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) return DecodedText(_utf16(bytes.sublist(2), little: true), 'utf-16le', gzipped: gz);
  if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) return DecodedText(_utf16(bytes.sublist(2), little: false), 'utf-16be', gzipped: gz);
  try {
    return DecodedText(utf8.decode(bytes), 'utf-8', gzipped: gz);
  } on FormatException {
    return DecodedText(decodeWindows1256(bytes), 'windows-1256', gzipped: gz);
  }
}

/// يجمع ناتج فك الضغط ويتوقف فور تجاوز الحد (لا ينتظر النهاية).
class _CappedSink implements Sink<List<int>> {
  final out = BytesBuilder(copy: false);
  @override
  void add(List<int> chunk) {
    out.add(chunk);
    if (out.length > maxImportBytes) throw ImportTooLarge(out.length);
  }

  @override
  void close() {}
}

String _utf16(List<int> b, {required bool little}) {
  final units = <int>[for (var i = 0; i + 1 < b.length; i += 2) little ? b[i] | (b[i + 1] << 8) : (b[i] << 8) | b[i + 1]];
  return String.fromCharCodes(units);
}

/// Windows-1256 (0x80–0xFF)؛ 0x00–0x7F مثل ASCII.
const _cp1256 = [
  0x20AC, 0x067E, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021, 0x02C6, 0x2030, 0x0679, 0x2039, 0x0152, 0x0686, 0x0698, 0x0688, //
  0x06AF, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014, 0x06A9, 0x2122, 0x0691, 0x203A, 0x0153, 0x200C, 0x200D, 0x06BA, //
  0x00A0, 0x060C, 0x00A2, 0x00A3, 0x00A4, 0x00A5, 0x00A6, 0x00A7, 0x00A8, 0x00A9, 0x06BE, 0x00AB, 0x00AC, 0x00AD, 0x00AE, 0x00AF, //
  0x00B0, 0x00B1, 0x00B2, 0x00B3, 0x00B4, 0x00B5, 0x00B6, 0x00B7, 0x00B8, 0x00B9, 0x061B, 0x00BB, 0x00BC, 0x00BD, 0x00BE, 0x061F, //
  0x06C1, 0x0621, 0x0622, 0x0623, 0x0624, 0x0625, 0x0626, 0x0627, 0x0628, 0x0629, 0x062A, 0x062B, 0x062C, 0x062D, 0x062E, 0x062F, //
  0x0630, 0x0631, 0x0632, 0x0633, 0x0634, 0x0635, 0x0636, 0x00D7, 0x0637, 0x0638, 0x0639, 0x063A, 0x0640, 0x0641, 0x0642, 0x0643, //
  0x00E0, 0x0644, 0x00E2, 0x0645, 0x0646, 0x0647, 0x0648, 0x00E7, 0x00E8, 0x00E9, 0x00EA, 0x00EB, 0x0649, 0x064A, 0x00EE, 0x00EF, //
  0x064B, 0x064C, 0x064D, 0x064E, 0x00F4, 0x064F, 0x0650, 0x00F7, 0x0651, 0x00F9, 0x0652, 0x00FB, 0x00FC, 0x200E, 0x200F, 0x06D2, //
];

String decodeWindows1256(List<int> bytes) => String.fromCharCodes([for (final b in bytes) b < 0x80 ? b : _cp1256[b - 0x80]]);
