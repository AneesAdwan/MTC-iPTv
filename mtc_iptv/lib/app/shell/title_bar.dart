// شريط عنوان مخصص بهوية التطبيق مع أزرار النافذة الأصلية (§6.6).
// في العربية (RTL) تنتقل الأزرار إلى اليسار تلقائيًا، كما في ويندوز العربي.
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/config/env.dart';
import '../l10n/app_localizations.dart';
import '../theme/tokens.dart';

class TitleBar extends StatefulWidget {
  const TitleBar({super.key});
  @override
  State<TitleBar> createState() => _TitleBarState();
}

class _TitleBarState extends State<TitleBar> with WindowListener {
  bool maximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    windowManager.isMaximized().then((v) {
      if (mounted) setState(() => maximized = v);
    }).catchError((_) {}); // غير متاح في الاختبارات
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() => setState(() => maximized = true);
  @override
  void onWindowUnmaximize() => setState(() => maximized = false);

  @override
  Widget build(BuildContext context) {
    final c = context.colors, t = L10n.of(context);
    return Container(
      height: 38,
      decoration: BoxDecoration(color: c.bg2, border: Border(bottom: BorderSide(color: c.line))),
      child: Row(children: [
        Expanded(
          child: DragToMoveArea(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: Space.md),
              child: Row(children: [
                SvgPicture.asset('assets/brand/mtc-iptv-icon.svg', width: 18, height: 18),
                const SizedBox(width: Space.sm),
                Text(t.appTitle, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: c.text)),
                if (Env.isStaging) ...[
                  const SizedBox(width: Space.sm),
                  _Badge('STAGING', c.warn),
                ],
              ]),
            ),
          ),
        ),
        _CaptionButton(icon: Icons.remove_rounded, tooltip: t.minimize, onTap: windowManager.minimize),
        _CaptionButton(
          icon: maximized ? Icons.filter_none_rounded : Icons.crop_square_rounded,
          iconSize: maximized ? 13 : 15,
          tooltip: maximized ? t.restore : t.maximize,
          onTap: () async => maximized ? windowManager.unmaximize() : windowManager.maximize(),
        ),
        _CaptionButton(icon: Icons.close_rounded, tooltip: t.close, danger: true, onTap: windowManager.close),
      ]),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
        child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
      );
}

class _CaptionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool danger;
  final double iconSize;
  const _CaptionButton({required this.icon, required this.tooltip, required this.onTap, this.danger = false, this.iconSize = 16});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        canRequestFocus: false, // أزرار النافذة خارج ترتيب التنقل بالمفاتيح
        hoverColor: danger ? const Color(0xFFE81123) : c.text.withValues(alpha: 0.08),
        child: SizedBox(width: 46, height: 38, child: Icon(icon, size: iconSize, color: c.textMuted)),
      ),
    );
  }
}
