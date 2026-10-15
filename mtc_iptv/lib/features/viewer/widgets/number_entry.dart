// إدخال رقم القناة (§8.2، وضع التلفاز): الأرقام من لوحة المفاتيح أو الريموت تظهر كبيرة،
// والقفز بعد 1.5 ثانية من آخر رقم (أو فورًا بـ Enter). لا يعمل أثناء الكتابة في حقل نصي.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/storage/catalog_db.dart';
import '../../../data/catalog/catalog_repository.dart';

final _digitKeys = {
  LogicalKeyboardKey.digit0: 0, LogicalKeyboardKey.digit1: 1, LogicalKeyboardKey.digit2: 2, LogicalKeyboardKey.digit3: 3,
  LogicalKeyboardKey.digit4: 4, LogicalKeyboardKey.digit5: 5, LogicalKeyboardKey.digit6: 6, LogicalKeyboardKey.digit7: 7,
  LogicalKeyboardKey.digit8: 8, LogicalKeyboardKey.digit9: 9,
  LogicalKeyboardKey.numpad0: 0, LogicalKeyboardKey.numpad1: 1, LogicalKeyboardKey.numpad2: 2, LogicalKeyboardKey.numpad3: 3,
  LogicalKeyboardKey.numpad4: 4, LogicalKeyboardKey.numpad5: 5, LogicalKeyboardKey.numpad6: 6, LogicalKeyboardKey.numpad7: 7,
  LogicalKeyboardKey.numpad8: 8, LogicalKeyboardKey.numpad9: 9,
};

class NumberEntry extends ConsumerStatefulWidget {
  final Widget child;
  final void Function(ChannelRow ch) onChannel;
  const NumberEntry({super.key, required this.child, required this.onChannel});
  @override
  ConsumerState<NumberEntry> createState() => _NumberEntryState();
}

class _NumberEntryState extends ConsumerState<NumberEntry> {
  static const delay = Duration(milliseconds: 1500);
  String digits = '';
  String? notFound;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _typingInField {
    final ctx = FocusManager.instance.primaryFocus?.context;
    return ctx != null && (ctx.widget is EditableText || ctx.findAncestorWidgetOfExactType<EditableText>() != null);
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent || _typingInField) return KeyEventResult.ignored;
    final d = _digitKeys[e.logicalKey];
    if (d != null) {
      setState(() {
        notFound = null;
        digits = '$digits$d';
        if (digits.length > 4) digits = digits.substring(digits.length - 4);
      });
      _timer?.cancel();
      _timer = Timer(delay, _go);
      return KeyEventResult.handled;
    }
    if (digits.isNotEmpty && (e.logicalKey == LogicalKeyboardKey.enter || e.logicalKey == LogicalKeyboardKey.numpadEnter)) {
      _timer?.cancel();
      _go();
      return KeyEventResult.handled;
    }
    if (digits.isNotEmpty && e.logicalKey == LogicalKeyboardKey.escape) {
      _timer?.cancel();
      setState(() => digits = '');
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _go() async {
    final n = int.tryParse(digits);
    if (n == null) return;
    final ch = await ref.read(catalogRepoProvider).byNumber(n);
    if (!mounted) return;
    if (ch == null) {
      setState(() => notFound = L10n.of(context).noChannelNumber(n));
      _timer = Timer(delay, () => mounted ? setState(() => digits = '') : null);
      return;
    }
    setState(() => digits = '');
    widget.onChannel(ch);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Focus(
      onKeyEvent: _onKey,
      child: Stack(children: [
        widget.child,
        if (digits.isNotEmpty)
          PositionedDirectional(
            top: 72,
            end: 32,
            child: IgnorePointer(
              child: Material(
                color: Colors.black.withValues(alpha: .78),
                borderRadius: BorderRadius.circular(Radii.md),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(digits, style: TextStyle(color: c.accent, fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: 4)),
                    ),
                    if (notFound != null) Text(notFound!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ]),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}
