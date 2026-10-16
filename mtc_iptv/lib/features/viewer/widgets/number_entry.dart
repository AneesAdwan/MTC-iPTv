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

/// لوحة أرقام على الشاشة (للجوال واللمس): تُظهر القناة المطابقة أثناء الكتابة، والانتقال بزر «انتقال».
Future<void> showNumberPad(BuildContext context, {required void Function(ChannelRow ch) onChannel}) async {
  final ch = await showModalBottomSheet<ChannelRow>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true, // وإلا يُقصّ صف «انتقال» على الجوال (ارتفاع الورقة محدود بنصف الشاشة)
    builder: (_) => const SingleChildScrollView(child: _NumberPad()),
  );
  if (ch != null) onChannel(ch);
}

class _NumberPad extends ConsumerStatefulWidget {
  const _NumberPad();
  @override
  ConsumerState<_NumberPad> createState() => _NumberPadState();
}

class _NumberPadState extends ConsumerState<_NumberPad> {
  String digits = '';
  ChannelRow? match;
  int _q = 0; // يُهمل نتيجة بحث أقدم من آخر رقم

  Future<void> _set(String d) async {
    setState(() {
      digits = d;
      match = null;
    });
    final n = int.tryParse(d);
    if (n == null) return;
    final q = ++_q;
    final ch = await ref.read(catalogRepoProvider).byNumber(n);
    if (mounted && q == _q) setState(() => match = ch);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors, t = L10n.of(context);
    final n = int.tryParse(digits);
    Widget key(Widget child, VoidCallback? onTap) => Padding(
          padding: const EdgeInsets.all(5),
          child: Material(
            color: c.surface2,
            borderRadius: BorderRadius.circular(Radii.md),
            child: InkWell(borderRadius: BorderRadius.circular(Radii.md), onTap: onTap, child: SizedBox(height: 58, child: Center(child: child))),
          ),
        );
    Widget digit(int d) => key(Text('$d', style: TextStyle(color: c.text, fontSize: 24, fontWeight: FontWeight.w700)), digits.length >= 4 ? null : () => _set('$digits$d'));
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.lg),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(t.numPad, style: TextStyle(color: c.textMuted)),
        const SizedBox(height: Space.xs),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(digits.isEmpty ? '—' : digits, style: TextStyle(color: c.accent, fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: 4)),
        ),
        SizedBox(
          height: 22,
          child: Text(
            digits.isEmpty ? t.numPadHint : (match?.displayName(Localizations.localeOf(context)) ?? (n == null ? '' : t.noChannelNumber(n))),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: match != null ? c.text : c.textMuted, fontWeight: match != null ? FontWeight.w600 : FontWeight.w400),
          ),
        ),
        const SizedBox(height: Space.sm),
        Directionality(
          textDirection: TextDirection.ltr, // ترتيب لوحة الهاتف ثابت
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(children: [
              for (final row in const [[1, 2, 3], [4, 5, 6], [7, 8, 9]]) Row(children: [for (final d in row) Expanded(child: digit(d))]),
              Row(children: [
                Expanded(child: key(Icon(Icons.backspace_outlined, color: c.textMuted), digits.isEmpty ? null : () => _set(digits.substring(0, digits.length - 1)))),
                Expanded(child: digit(0)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: SizedBox(
                      height: 58,
                      child: FilledButton(
                        style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md))),
                        onPressed: match == null ? null : () => Navigator.pop(context, match),
                        child: Text(t.numPadGo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }
}

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
      skipTraversal: true, // مستمع للأرقام فقط، لا هدف للأسهم
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
