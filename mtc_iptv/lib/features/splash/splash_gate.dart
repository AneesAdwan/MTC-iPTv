// V-01 — المقدمة (§6.7): نسخة قصيرة ≤ ثانية واحدة فوق التطبيق، ثم تختفي.
// تحترم «تقليل الحركة» في النظام (تُتخطّى). المقدمة الكاملة لأول تشغيل تُبنى في المرحلة 3.
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/theme/tokens.dart';

class SplashGate extends StatefulWidget {
  final Widget child;
  const SplashGate({super.key, required this.child});
  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> with SingleTickerProviderStateMixin {
  late final AnimationController ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 950));
  bool done = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      done = true;
    } else if (!ctrl.isAnimating && !done) {
      ctrl.forward().whenComplete(() {
        if (mounted) setState(() => done = true);
      });
    }
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (done) return widget.child;
    final c = context.colors;
    // 0→0.45 ظهور الشعار، 0.45→0.7 ثبات، 0.7→1 تلاشي الطبقة عن التطبيق
    final logoIn = CurvedAnimation(parent: ctrl, curve: const Interval(0, 0.45, curve: Curves.easeOutBack));
    final out = CurvedAnimation(parent: ctrl, curve: const Interval(0.7, 1, curve: Curves.easeIn));
    return Stack(children: [
      widget.child,
      AnimatedBuilder(
        animation: ctrl,
        builder: (_, _) => IgnorePointer(
          child: Opacity(
            opacity: 1 - out.value,
            child: ColoredBox(
              color: c.bg,
              child: Center(
                child: Transform.scale(
                  scale: 0.8 + 0.2 * logoIn.value,
                  child: Opacity(
                    opacity: logoIn.value.clamp(0, 1),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      SvgPicture.asset('assets/brand/mtc-iptv-icon.svg', width: 96, height: 96),
                      const SizedBox(height: Space.lg),
                      ShaderMask(
                        shaderCallback: (r) => c.brandGradient.createShader(r),
                        child: const Text('MTC-iPTv', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                      const SizedBox(height: Space.xs),
                      Text('MTC-Group', style: TextStyle(color: c.textDim, fontSize: 12, letterSpacing: 2)),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}
