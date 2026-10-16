// صف أفقي يعمل بالماوس على الكمبيوتر (طلب المالك 2026-10-16: «الفئات على ويندوز ما بتتحرك»):
// Flutter لا يسحب القوائم بالماوس افتراضيًا، والعجلة العمودية لا تحرّك قائمة أفقية، فتبقى العناصر خارج الشاشة
// غير قابلة للوصول. هنا: سحب بالماوس، شريط تمرير ظاهر، أسهم عند الطرفين (تظهر حين يوجد ما يُمرَّر)،
// واختياريًا العجلة العمودية تحرّك الصف (للأشرطة القصيرة كالفئات، لا لصفوف الرئيسية حتى لا تعلق الصفحة).
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class HScroller extends StatefulWidget {
  final double height;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double spacing;
  final EdgeInsetsGeometry padding;

  /// العجلة العمودية تحرّك الصف أفقيًا.
  final bool wheelScrolls;

  /// عنصر يُمرَّر إليه عند الفتح (الشريحة المختارة): الشاشة تُبنى من جديد عند اختيار فئة، فكان الشريط
  /// يعود لأوله وتختفي الفئة المختارة — بدا كأن الزر لا يعمل (فحص 2026-10-16).
  final int? selectedIndex;
  const HScroller({
    super.key,
    required this.height,
    required this.itemCount,
    required this.itemBuilder,
    this.spacing = Space.sm,
    this.padding = const EdgeInsets.symmetric(horizontal: Space.lg),
    this.wheelScrolls = false,
    this.selectedIndex,
  });

  /// لقائمة عناصر ثابتة (أشرطة الشرائح في الإدارة).
  HScroller.children({
    super.key,
    required this.height,
    required List<Widget> children,
    this.spacing = Space.sm,
    this.padding = const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm),
    this.wheelScrolls = true,
    this.selectedIndex,
  })  : itemCount = children.length,
        itemBuilder = ((_, i) => children[i]);

  @override
  State<HScroller> createState() => _HScrollerState();
}

/// السحب بالماوس واللمس والقلم (السلوك الافتراضي يستثني الماوس). يُستخدم أيضًا للتطبيق كله.
class DragAllScrollBehavior extends MaterialScrollBehavior {
  const DragAllScrollBehavior();
  @override
  Set<PointerDeviceKind> get dragDevices => PointerDeviceKind.values.toSet();
}

class _HScrollerState extends State<HScroller> {
  final ctrl = ScrollController();
  final _selKey = GlobalKey();
  bool canBack = false, canFwd = false, hover = false;

  @override
  void initState() {
    super.initState();
    ctrl.addListener(_update);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _update();
      _revealSelected();
    });
  }

  /// القائمة كسولة: العنصر البعيد لم يُبنَ بعد، فنتقدّم صفحةً صفحة حتى يُبنى ثم نُظهره.
  Future<void> _revealSelected() async {
    final i = widget.selectedIndex;
    if (i == null || i <= 0) return;
    for (var k = 0; k < 40 && mounted && ctrl.hasClients; k++) {
      final ctx = _selKey.currentContext;
      if (ctx != null) {
        if (ctx.mounted) await Scrollable.ensureVisible(ctx, alignment: 0.5, duration: Duration.zero);
        return;
      }
      final p = ctrl.position;
      if (p.pixels >= p.maxScrollExtent) return;
      ctrl.jumpTo((p.pixels + p.viewportDimension).clamp(p.minScrollExtent, p.maxScrollExtent));
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  @override
  void didUpdateWidget(HScroller old) {
    super.didUpdateWidget(old);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _update();
      // الفئات تصل بعد أول بناء (من قاعدة البيانات)، فالمؤشر يتغير لاحقًا
      if (old.selectedIndex != widget.selectedIndex) _revealSelected();
    });
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  void _update() {
    if (!mounted || !ctrl.hasClients) return;
    final p = ctrl.position;
    final b = p.pixels > p.minScrollExtent + 1, f = p.pixels < p.maxScrollExtent - 1;
    if (b != canBack || f != canFwd) {
      setState(() {
        canBack = b;
        canFwd = f;
      });
    }
  }

  /// [dir] = -1 للخلف، 1 للأمام (منطقيًا؛ القائمة تنعكس وحدها في RTL).
  void page(int dir) {
    if (!ctrl.hasClients) return;
    final p = ctrl.position;
    final to = (p.pixels + dir * p.viewportDimension * 0.8).clamp(p.minScrollExtent, p.maxScrollExtent);
    ctrl.animateTo(to, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  void _onSignal(PointerSignalEvent e) {
    if (!widget.wheelScrolls || e is! PointerScrollEvent || !ctrl.hasClients) return;
    final d = e.scrollDelta.dy != 0 ? e.scrollDelta.dy : e.scrollDelta.dx;
    if (d == 0) return;
    GestureBinding.instance.pointerSignalResolver.register(e, (_) {
      final p = ctrl.position;
      ctrl.jumpTo((p.pixels + d).clamp(p.minScrollExtent, p.maxScrollExtent));
    });
  }

  @override
  Widget build(BuildContext context) {
    // الماوس موجود على الكمبيوتر حتى لو كانت النافذة ضيقة (نمط «جوال»)
    final desktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    final list = ScrollConfiguration(
      behavior: const DragAllScrollBehavior(),
      child: ListView.separated(
        controller: ctrl,
        scrollDirection: Axis.horizontal,
        padding: widget.padding,
        itemCount: widget.itemCount,
        separatorBuilder: (_, _) => SizedBox(width: widget.spacing),
        itemBuilder: (context, i) => i == widget.selectedIndex ? KeyedSubtree(key: _selKey, child: widget.itemBuilder(context, i)) : widget.itemBuilder(context, i),
      ),
    );
    return SizedBox(
      height: widget.height,
      child: MouseRegion(
        onEnter: (_) => setState(() => hover = true),
        onExit: (_) => setState(() => hover = false),
        child: Listener(
          onPointerSignal: _onSignal,
          child: Stack(children: [
            Positioned.fill(
              child: desktop
                  ? Scrollbar(controller: ctrl, thumbVisibility: hover && (canBack || canFwd), thickness: 4, radius: const Radius.circular(2), child: list)
                  : list,
            ),
            if (desktop && canBack) PositionedDirectional(start: 2, top: 0, bottom: 0, child: _Arrow(back: true, visible: hover, onTap: () => page(-1))),
            if (desktop && canFwd) PositionedDirectional(end: 2, top: 0, bottom: 0, child: _Arrow(back: false, visible: hover, onTap: () => page(1))),
          ]),
        ),
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  final bool back, visible;
  final VoidCallback onTap;
  const _Arrow({required this.back, required this.visible, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // أيقونتا chevron تنعكسان وحدهما في RTL (matchTextDirection)، فتشير «للأمام» دائمًا لاتجاه القائمة
    final icon = back ? Icons.chevron_left_rounded : Icons.chevron_right_rounded;
    return Center(
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0.55,
        duration: const Duration(milliseconds: 150),
        child: Material(
          color: c.surface2.withValues(alpha: .92),
          shape: CircleBorder(side: BorderSide(color: c.line2)),
          elevation: 2,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, color: c.text, size: 22)),
          ),
        ),
      ),
    );
  }
}
