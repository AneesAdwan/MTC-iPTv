import 'package:flutter/material.dart';

import 'tokens.dart';

const fontFamily = 'IBMPlexSansArabic'; // يغطي العربية واللاتينية معًا (§6.3)

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? MtcColors.dark : MtcColors.light;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.accent,
    onPrimary: Colors.white,
    secondary: c.accent2,
    onSecondary: Colors.white,
    error: c.bad,
    onError: Colors.white,
    surface: c.surface,
    onSurface: c.text,
    surfaceContainerLowest: c.bg,
    surfaceContainerLow: c.bg2,
    surfaceContainer: c.surface,
    surfaceContainerHigh: c.surface2,
    surfaceContainerHighest: c.surface2,
    onSurfaceVariant: c.textMuted,
    outline: c.line2,
    outlineVariant: c.line,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: fontFamily,
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.bg,
    dividerColor: c.line,
    extensions: [c],
    // إطار تركيز واضح لكل عنصر: أساس التنقل بلوحة المفاتيح والريموت (§6.5)
    focusColor: c.accent.withValues(alpha: 0.22),
    hoverColor: c.text.withValues(alpha: 0.05),
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: c.text, displayColor: c.text),
    cardTheme: CardThemeData(
      color: c.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md), side: BorderSide(color: c.line)),
    ),
    dividerTheme: DividerThemeData(color: c.line, space: 1, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface2,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.sm), borderSide: BorderSide(color: c.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.sm), borderSide: BorderSide(color: c.line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.sm), borderSide: BorderSide(color: c.accent, width: 1.5)),
      hintStyle: TextStyle(color: c.textDim),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(Radii.sm), border: Border.all(color: c.line2)),
      textStyle: TextStyle(color: c.text, fontFamily: fontFamily, fontSize: 12),
      waitDuration: const Duration(milliseconds: 500),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.lg), side: BorderSide(color: c.line)),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
    }),
  );
}
