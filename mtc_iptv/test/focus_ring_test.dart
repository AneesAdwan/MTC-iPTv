// إطار التركيز ظاهر على الأزرار (الريموت/لوحة المفاتيح، §6.5).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtc_iptv/app/theme/theme.dart';

void main() {
  for (final b in [Brightness.dark, Brightness.light]) {
    test('focused buttons get a visible ring, idle ones keep their look ($b)', () {
      TestWidgetsFlutterBinding.ensureInitialized();
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional; // ريموت/لوحة مفاتيح
      addTearDown(() => FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic);
      final t = buildTheme(b);
      for (final style in [t.filledButtonTheme.style, t.textButtonTheme.style, t.outlinedButtonTheme.style, t.iconButtonTheme.style]) {
        final focused = style!.side!.resolve({WidgetState.focused});
        expect(focused, isNotNull);
        expect(focused!.width, greaterThanOrEqualTo(2));
        expect(style.side!.resolve(<WidgetState>{}), isNull); // يرجع للشكل الافتراضي
      }
    });
  }

  test('no ring in touch mode (an autofocused dialog button on a phone)', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
    addTearDown(() => FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic);
    expect(buildTheme(Brightness.dark).textButtonTheme.style!.side!.resolve({WidgetState.focused}), isNull);
  });
}
