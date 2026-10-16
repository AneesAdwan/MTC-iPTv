// شعار MTC-iPTv فوق البث (طلب المالك 2026-10-17: «تصميم جديد متطور… يعمل حركات كل دقيقتين كأنه قناة تلفزيونية فخمة»).
// متجهي بالكامل (رسم مباشر بمقاسات img/mtc-iptv-icon.svg — viewBox 64 — فيبقى حادًا بأي مقاس)، والاسم بخط Inter 900.
// flutter_svg لا يشغّل حركات SVG، لذا الحركة مرسومة هنا:
//   • دائمًا وبهدوء: تدرّج الدائرة يدور، والمدار المنقّط يلفّ، والقمر الصغير يدور حوله.
//   • «هوية القناة» عند الظهور ثم كل [BrandBug.interval]: الدائرة تنبض، الموجات تومض وتُبثّ حلقات للخارج،
//     القمر يلفّ لفة سريعة بذيل مذنّب، لمعة تعبر الاسم، ونجمة بريق عند آخره.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

const _red = Color(0xFFFF2D55), _coral = Color(0xFFFF5A36), _orange = Color(0xFFFF7A1A), _amber = Color(0xFFFFB02E);

class BrandBug extends StatefulWidget {
  final double height;
  final bool dim; // أخفت حين يظهر شريط التحكم
  final Duration interval;
  const BrandBug({super.key, required this.height, this.dim = false, this.interval = const Duration(minutes: 2)});

  /// مدة «هوية القناة» بالثواني.
  static const double identSeconds = 4.0;

  @override
  State<BrandBug> createState() => _BrandBugState();
}

class _BrandBugState extends State<BrandBug> with TickerProviderStateMixin {
  late final _idle = AnimationController(vsync: this, duration: const Duration(seconds: 12));
  late final _ident = AnimationController(vsync: this, duration: Duration(milliseconds: (BrandBug.identSeconds * 1000).round()));
  Timer? _timer;
  bool _entry = true, _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _entry = false;
      _ident.value = 1;
      return;
    }
    _idle.repeat();
    _ident.forward(from: 0).whenComplete(() => _entry = false);
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted) return;
      _entry = false;
      _ident.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _idle.dispose();
    _ident.dispose();
    super.dispose();
  }

  double get _t => _ident.value * BrandBug.identSeconds;

  /// تقدّم مقطع من «الهوية»: يبدأ عند [a] ثانية ويستغرق [d] ثانية (0..1).
  double _seg(double a, double d, [Curve c = Curves.linear]) => c.transform(((_t - a) / d).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final h = widget.height, s = h / 64;
    final style = TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w900,
      fontSize: 40 * s,
      letterSpacing: -1 * s,
      height: 1,
      color: Colors.white,
      decoration: TextDecoration.none,
      shadows: const [Shadow(color: Color(0x99000000), blurRadius: 8, offset: Offset(0, 1))],
    );

    final icon = RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_idle, _ident]),
        builder: (_, _) => CustomPaint(size: Size.square(h), painter: BugIconPainter(spin: _idle.value, t: _t, entry: _entry)),
      ),
    );

    final word = AnimatedBuilder(
      animation: _ident,
      builder: (_, _) {
        final reveal = _entry ? _seg(.45, .8, const Cubic(.2, .8, .2, 1)) : 1.0;
        final sheen = _seg(1.15, 1.1, Curves.easeInOut);
        final shift = _seg(.9, 2.4, Curves.easeInOut); // تدرّج «-iPTv» يتموّج أثناء الهوية
        final star = _seg(2.05, .9);

        Widget text = Row(mainAxisSize: MainAxisSize.min, children: [
          Text('MTC', style: style),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (r) => LinearGradient(
              colors: const [_red, _coral, _amber, _coral, _red],
              stops: const [0, .3, .5, .7, 1],
              begin: Alignment(-1 - 2 * shift, 0),
              end: Alignment(3 - 2 * shift, 0),
            ).createShader(r),
            child: Text('-iPTv', style: style),
          ),
        ]);
        if (sheen > 0 && sheen < 1) {
          final x = -.25 + 1.5 * sheen;
          text = ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (r) => LinearGradient(
              begin: const Alignment(-1, -.5),
              end: const Alignment(1, .5),
              colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: .85), Colors.white.withValues(alpha: 0)],
              stops: [(x - .12).clamp(0.0, 1.0), x.clamp(0.0, 1.0), (x + .12).clamp(0.0, 1.0)],
            ).createShader(r),
            child: text,
          );
        }
        if (reveal < 1) {
          text = ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: reveal.clamp(0.01, 1.0),
              child: Opacity(opacity: reveal, child: Transform.translate(offset: Offset(-18 * s * (1 - reveal), 0), child: text)),
            ),
          );
        }
        return Stack(clipBehavior: Clip.none, children: [
          text,
          if (star > 0 && star < 1)
            Positioned(
              right: -h * .2,
              top: -h * .16,
              child: CustomPaint(size: Size.square(h * .44), painter: _SparklePainter(star)),
            ),
        ]);
      },
    );

    return AnimatedOpacity(
      opacity: widget.dim ? .6 : .95,
      duration: const Duration(milliseconds: 300),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(mainAxisSize: MainAxisSize.min, children: [icon, SizedBox(width: 14 * s), word]),
      ),
    );
  }
}

/// رمز MTC-iPTv بمقاسات viewBox 64. [spin] حركة الهدوء الدائمة (0..1 كل 12 ث)، و[t] ثواني «الهوية» (4 = انتهت)،
/// و[entry] أول ظهور (يقفز الرمز وتُرسم الموجات).
class BugIconPainter extends CustomPainter {
  final double spin, t;
  final bool entry;
  BugIconPainter({required this.spin, required this.t, required this.entry});

  double _seg(double a, double d, [Curve c = Curves.linear]) => c.transform(((t - a) / d).clamp(0.0, 1.0));

  /// نتوء 0→1→0 بين [a] و[a+d].
  double _bump(double a, double d) {
    final p = ((t - a) / d).clamp(0.0, 1.0);
    return math.sin(p * math.pi);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 64);
    const c = Offset(32, 32);
    const rect = Rect.fromLTWH(8, 8, 48, 48);
    final grad = LinearGradient(colors: const [_red, _coral, _amber], transform: GradientRotation(spin * 2 * math.pi)).createShader(rect);

    // أول ظهور: قفزة مع دوران
    final pop = entry ? _seg(0, .8, const Cubic(.34, 1.56, .64, 1)) : 1.0;
    canvas.translate(32, 32);
    canvas.rotate(-math.pi / 2 * (1 - pop));
    canvas.scale(.2 + .8 * pop);
    canvas.translate(-32, -32);
    final alpha = entry ? _seg(0, .35) : 1.0;

    // حلقتا بث تتسعان للخارج
    for (final a in [.5, .85]) {
      final p = _seg(a, 1.4, Curves.easeOutCubic);
      if (p <= 0 || p >= 1) continue;
      canvas.drawCircle(
        c,
        13 + 31 * p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6 * (1 - .6 * p)
          ..color = _orange.withValues(alpha: .75 * (1 - p) * alpha),
      );
    }

    // توهّج خلف الدائرة: هادئ دائمًا، ويشتد مع النبضة
    final glow = .28 + .5 * _bump(.15, 1.3);
    canvas.drawCircle(c, 15, Paint()
      ..color = _coral.withValues(alpha: glow * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));

    // المدار المنقّط يدور ببطء
    final dash = Paint()
      ..color = _orange.withValues(alpha: .32 * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rot = spin * math.pi;
    for (var a = 0.0; a < 2 * math.pi - .01; a += 4.5 / 27.5) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: 27.5), a + rot, 1.5 / 27.5, false, dash);
    }

    // القمر: يدور ببطء، ولفّة سريعة بذيل مذنّب أثناء الهوية
    final fast = _seg(.3, 1.5, Curves.easeInOutCubic);
    final ang = -math.pi / 4 + spin * 2 * math.pi + fast * 2 * math.pi;
    final trail = _bump(.3, 1.5);
    Offset at(double a) => c + Offset(math.cos(a), math.sin(a)) * 27.5;
    for (var i = 10; i >= 1; i--) {
      if (trail <= .02) break;
      canvas.drawCircle(at(ang - i * .11), 2.2 * (1 - i / 13), Paint()..color = _amber.withValues(alpha: trail * .75 * (1 - i / 10.5) * alpha));
    }
    canvas.drawCircle(at(ang), 3.6, Paint()
      ..color = _amber.withValues(alpha: .55 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    canvas.drawCircle(at(ang), 2.3, Paint()..color = Color.lerp(_amber, Colors.white, .55)!.withValues(alpha: alpha));

    // الدائرة الملونة تنبض (مثل beat في الموقع: تنكمش ثم تنتفخ ثم تستقر)
    final bp = ((t - .15) / .75).clamp(0.0, 1.0);
    final beat = bp <= 0 || bp >= 1
        ? 1.0
        : bp < .3
            ? 1 - .14 * (bp / .3)
            : bp < .65
                ? .86 + .22 * ((bp - .3) / .35)
                : 1.08 - .08 * ((bp - .65) / .35);
    final r = 12.5 * beat;
    canvas.drawCircle(c, r, Paint()..shader = grad..color = Colors.white.withValues(alpha: alpha));
    // لمعة زجاجية أعلى الدائرة
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(center: const Alignment(-.45, -.55), radius: .9, colors: [Colors.white.withValues(alpha: .38 * alpha), Colors.white.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: c, radius: r)),
    );

    // مثلث التشغيل
    canvas.save();
    canvas.translate(32, 32);
    canvas.scale(beat);
    canvas.translate(-32, -32);
    final tri = Path()
      ..moveTo(28.5, 25.5)
      ..lineTo(38.5, 32)
      ..lineTo(28.5, 38.5)
      ..close();
    canvas.drawPath(
      tri,
      Paint()
        ..color = Colors.white.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(tri, Paint()..color = Colors.white.withValues(alpha: alpha));
    canvas.restore();

    // الموجتان (±40° حول الأفقي): تُرسمان من المنتصف عند الظهور، وتومضان مع كل هوية
    for (final (rad, a0) in [(16.0, .3), (25.0, .48)]) {
      final draw = entry ? _seg(a0, .5, const Cubic(.65, 0, .35, 1)) : 1.0;
      if (draw <= 0) continue;
      final half = 40 * math.pi / 180 * draw;
      final flash = _bump(a0 + .1, .6);
      final wp = Paint()
        ..shader = grad
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.8
        ..strokeCap = StrokeCap.round;
      final box = Rect.fromCircle(center: c, radius: rad);
      for (final mid in [0.0, math.pi]) {
        canvas.drawArc(box, mid - half, 2 * half, false, wp);
        if (flash > .01) {
          canvas.drawArc(
            box,
            mid - half,
            2 * half,
            false,
            Paint()
              ..color = Colors.white.withValues(alpha: .75 * flash)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3.8
              ..strokeCap = StrokeCap.round
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(BugIconPainter o) => o.spin != spin || o.t != t || o.entry != entry;
}

/// نجمة بريق رباعية تكبر وتدور ثم تختفي ([p] من 0 إلى 1).
class _SparklePainter extends CustomPainter {
  final double p;
  _SparklePainter(this.p);
  @override
  void paint(Canvas canvas, Size size) {
    final k = math.sin(p * math.pi);
    if (k <= 0) return;
    final c = size.center(Offset.zero), R = size.width / 2 * k, r = R * .16;
    canvas.translate(c.dx, c.dy);
    canvas.rotate(p * math.pi / 2);
    final star = Path()
      ..moveTo(0, -R)
      ..quadraticBezierTo(r, -r, R, 0)
      ..quadraticBezierTo(r, r, 0, R)
      ..quadraticBezierTo(-r, r, -R, 0)
      ..quadraticBezierTo(-r, -r, 0, -R)
      ..close();
    canvas.drawCircle(Offset.zero, R * .45, Paint()
      ..color = _amber.withValues(alpha: .55 * k)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, R * .3 + .1));
    canvas.drawPath(star, Paint()..color = Colors.white.withValues(alpha: k));
  }

  @override
  bool shouldRepaint(_SparklePainter o) => o.p != p;
}
