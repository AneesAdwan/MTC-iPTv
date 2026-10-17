// Design tokens: the single source of colours, spacing and radii for SuperAdmin.
// Same brand as the viewer app (red-orange #FF2D55 → #FF7A1A). Red is reserved for danger (plan §8).
import 'package:flutter/material.dart';

@immutable
class MtcColors extends ThemeExtension<MtcColors> {
  final Color bg, bg2, surface, surface2, line, line2, text, textMuted, textDim;
  final Color accent, accent2, ok, warn, bad, info;

  const MtcColors({
    required this.bg,
    required this.bg2,
    required this.surface,
    required this.surface2,
    required this.line,
    required this.line2,
    required this.text,
    required this.textMuted,
    required this.textDim,
    required this.accent,
    required this.accent2,
    required this.ok,
    required this.warn,
    required this.bad,
    required this.info,
  });

  static const dark = MtcColors(
    bg: Color(0xFF08080C),
    bg2: Color(0xFF0F0F15),
    surface: Color(0xFF16161E),
    surface2: Color(0xFF1E1E28),
    line: Color(0x14FFFFFF),
    line2: Color(0x24FFFFFF),
    text: Color(0xFFF5F5F7),
    textMuted: Color(0xFF9A9AAB),
    textDim: Color(0xFF6B6B7B),
    accent: Color(0xFFFF2D55),
    accent2: Color(0xFFFF7A1A),
    ok: Color(0xFF22C55E),
    warn: Color(0xFFF59E0B),
    bad: Color(0xFFEF4444),
    info: Color(0xFF3B82F6),
  );

  static const light = MtcColors(
    bg: Color(0xFFF5F7FA),
    bg2: Color(0xFFEDF0F5),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF3F4F6),
    line: Color(0xFFE5E7EB),
    line2: Color(0xFFD1D5DB),
    text: Color(0xFF111827),
    textMuted: Color(0xFF4B5563),
    textDim: Color(0xFF6B7280),
    accent: Color(0xFFE11D48),
    accent2: Color(0xFFEA580C),
    ok: Color(0xFF16A34A),
    warn: Color(0xFFD97706),
    bad: Color(0xFFDC2626),
    info: Color(0xFF2563EB),
  );

  LinearGradient get brandGradient => LinearGradient(colors: [accent, accent2]);

  /// Colour for a semantic tone.
  Color tone(Tone t) => switch (t) {
    Tone.ok => ok,
    Tone.warn => warn,
    Tone.bad => bad,
    Tone.info => info,
    Tone.accent => accent,
    Tone.neutral => textMuted,
  };

  @override
  MtcColors copyWith() => this;

  @override
  MtcColors lerp(MtcColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return MtcColors(
      bg: l(bg, other.bg),
      bg2: l(bg2, other.bg2),
      surface: l(surface, other.surface),
      surface2: l(surface2, other.surface2),
      line: l(line, other.line),
      line2: l(line2, other.line2),
      text: l(text, other.text),
      textMuted: l(textMuted, other.textMuted),
      textDim: l(textDim, other.textDim),
      accent: l(accent, other.accent),
      accent2: l(accent2, other.accent2),
      ok: l(ok, other.ok),
      warn: l(warn, other.warn),
      bad: l(bad, other.bad),
      info: l(info, other.info),
    );
  }
}

/// Semantic tones used by badges, KPI cards, preview groups…
enum Tone { ok, warn, bad, info, accent, neutral }

abstract final class Space {
  static const xs = 4.0, sm = 8.0, md = 12.0, lg = 16.0, xl = 24.0, xxl = 32.0;
}

abstract final class Radii {
  static const sm = 8.0, md = 12.0, lg = 18.0;
}

extension MtcThemeX on BuildContext {
  MtcColors get colors {
    final t = Theme.of(this);
    return t.extension<MtcColors>() ?? (t.brightness == Brightness.dark ? MtcColors.dark : MtcColors.light);
  }
}
