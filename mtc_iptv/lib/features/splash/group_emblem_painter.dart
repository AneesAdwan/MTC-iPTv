// شعار MTC-Group المتحرك (img/mtc-group-emblem.svg في الموقع، viewBox 200) مرسومًا متجهيًا عنصرًا عنصرًا،
// لأن flutter_svg لا يشغّل حركات CSS/SMIL داخل SVG. التوقيتات من <style> الملف نفسه:
//   دخول: حلقات HUD تدور وتكبر (0.1–1.3 ث)، رسم حافة السداسي (0.25–1.35)، امتلاؤه (0.7–1.5)،
//   رسم حرف M (0.9–1.9)، مسارات الدارة (1.5–2.1)، العقد تقفز (1.9–2.4).
//   دائم: هالة تتنفس، حلقتان تدوران بعكس بعض، قمر بيانات، تدرّج ذهبي يدور، رؤوس تتلألأ، نبضات بيانات
//   على المسارات، توهج M يتنفس، لمعة تعبر السداسي.
import 'dart:math' as math;

import 'package:flutter/material.dart';

class GroupEmblemPainter extends CustomPainter {
  /// ثوانٍ منذ ظهور الشعار.
  final double t;
  GroupEmblemPainter(this.t);

  static const _c = Offset(100, 100);
  static final _hex = Path()
    ..moveTo(100, 26)
    ..lineTo(164.09, 63)
    ..lineTo(164.09, 137)
    ..lineTo(100, 174)
    ..lineTo(35.91, 137)
    ..lineTo(35.91, 63)
    ..close();
  static final _hexInner = Path()
    ..moveTo(100, 38)
    ..lineTo(153.69, 69)
    ..lineTo(153.69, 131)
    ..lineTo(100, 162)
    ..lineTo(46.31, 131)
    ..lineTo(46.31, 69)
    ..close();
  static final _m = Path()
    ..moveTo(76, 122)
    ..lineTo(76, 78)
    ..lineTo(100, 102)
    ..lineTo(124, 78)
    ..lineTo(124, 122);
  static final _traces = <Path>[
    Path()..moveTo(76, 124)..lineTo(76, 132)..lineTo(68, 140),
    Path()..moveTo(124, 124)..lineTo(124, 132)..lineTo(132, 140),
    Path()..moveTo(100, 110)..lineTo(100, 148),
    Path()..moveTo(100, 90)..lineTo(100, 52),
    Path()..moveTo(76, 76)..lineTo(76, 66)..lineTo(84, 58),
    Path()..moveTo(124, 76)..lineTo(124, 66)..lineTo(116, 58),
    Path()..moveTo(71, 100)..lineTo(56, 100),
    Path()..moveTo(129, 100)..lineTo(144, 100),
  ];
  // ترتيب النبضات في الملف: 3،5،7،1،2،0،6،4 من المسارات أعلاه
  static const _pulseOrder = [3, 5, 7, 1, 2, 0, 6, 4];
  static const _nodes = [Offset(68, 140), Offset(132, 140), Offset(100, 150), Offset(100, 50), Offset(84, 58), Offset(116, 58), Offset(54, 100), Offset(146, 100)];
  static const _vertices = [Offset(100, 26), Offset(164.09, 63), Offset(164.09, 137), Offset(100, 174), Offset(35.91, 137), Offset(35.91, 63)];

  static double _seg(double t, double start, double dur, [Curve c = Curves.linear]) => c.transform(((t - start) / dur).clamp(0.0, 1.0));

  /// جزء من مسار بنسبة [p] (رسم تدريجي مثل stroke-dashoffset).
  static Path _part(Path p, double from, double to) {
    final out = Path();
    var total = 0.0;
    final ms = p.computeMetrics().toList();
    for (final m in ms) {
      total += m.length;
    }
    var acc = 0.0;
    for (final m in ms) {
      final a = (from * total - acc).clamp(0.0, m.length), b = (to * total - acc).clamp(0.0, m.length);
      if (b > a) out.addPath(m.extractPath(a, b), Offset.zero);
      acc += m.length;
    }
    return out;
  }

  Shader _gold(Rect r) => LinearGradient(
        colors: const [Color(0xFFFFF3DC), Color(0xFFFFC37A), Color(0xFFFF7A1A), Color(0xFFFF2D55), Color(0xFFFFD9A8)],
        stops: const [0, .3, .6, .85, 1],
        transform: GradientRotation(t / 8 * 2 * math.pi),
      ).createShader(r);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 200);
    const goldRect = Rect.fromLTWH(30, 30, 140, 140);
    const ease = Cubic(.65, 0, .35, 1);

    // الهالة تتنفس
    final halo = 1 + .08 * (math.sin(t / 4 * 2 * math.pi) + 1) / 2;
    canvas.drawCircle(
      _c,
      96 * halo,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFFFF4B3A).withValues(alpha: .55),
          const Color(0xFFFF2D55).withValues(alpha: .12),
          const Color(0x00FF2D55),
        ], stops: const [0, .6, 1])
            .createShader(Rect.fromCircle(center: _c, radius: 96 * halo)),
    );

    // حلقات HUD
    final hud = _seg(t, .1, 1.2, const Cubic(.2, .8, .2, 1));
    if (hud > 0) {
      canvas.save();
      canvas.translate(_c.dx, _c.dy);
      canvas.scale(.7 + .3 * hud);
      canvas.rotate(-40 * math.pi / 180 * (1 - hud));
      canvas.translate(-_c.dx, -_c.dy);
      final o = hud;
      // r1: متقطعة ذهبية، 40 ث
      canvas.save();
      canvas.translate(_c.dx, _c.dy);
      canvas.rotate(t / 40 * 2 * math.pi);
      canvas.translate(-_c.dx, -_c.dy);
      _dashedCircle(canvas, 92, const [46, 10, 6, 10, 2, 10], Paint()
        ..shader = _gold(goldRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: .75 * o));
      canvas.restore();
      // r2: نقاط، 26 ث بالعكس
      canvas.save();
      canvas.translate(_c.dx, _c.dy);
      canvas.rotate(-t / 26 * 2 * math.pi);
      canvas.translate(-_c.dx, -_c.dy);
      _dashedCircle(canvas, 85, const [.8, 4.2], Paint()
        ..color = const Color(0xFFFFC37A).withValues(alpha: .35 * o)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4);
      canvas.restore();
      // القمر: 7 ث
      final a = -math.pi / 2 + t / 7 * 2 * math.pi;
      canvas.drawCircle(_c + Offset(math.cos(a), math.sin(a)) * 92, 3, Paint()
        ..color = Colors.white.withValues(alpha: o)
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2.2));
      canvas.restore();
    }

    // السداسي: امتلاء + حدّ داخلي + لمعة
    final fill = _seg(t, .7, .8, Curves.easeOut);
    if (fill > 0) {
      canvas.drawPath(
        _hex,
        Paint()
          ..shader = RadialGradient(center: const Alignment(0, -.16), radius: .62, colors: [
            const Color(0xFF3A1124).withValues(alpha: fill),
            const Color(0xFF1A0812).withValues(alpha: fill),
            const Color(0xFF0B0509).withValues(alpha: fill),
          ], stops: const [0, .65, 1])
              .createShader(_hex.getBounds()),
      );
      canvas.drawPath(_hexInner, Paint()
        ..color = const Color(0xFFFFC37A).withValues(alpha: .22 * fill)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
      // اللمعة: 5.5 ث تبدأ عند 2.4
      if (t > 2.4) {
        final p = ((t - 2.4) % 5.5) / 5.5;
        final x = p < .4 ? -150 + 320 * Curves.easeInOut.transform(p / .4) : 999.0;
        canvas.save();
        canvas.clipPath(_hex);
        canvas.translate(40 + x, 10);
        canvas.transform(Matrix4.skewX(-20 * math.pi / 180).storage);
        const r = Rect.fromLTWH(0, 0, 34, 180);
        canvas.drawRect(r, Paint()..shader = LinearGradient(colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: .22 * fill), Colors.white.withValues(alpha: 0)]).createShader(r));
        canvas.restore();
      }
    }

    // حافة السداسي ترسم نفسها
    final edge = _seg(t, .25, 1.1, ease);
    if (edge > 0) {
      canvas.drawPath(_part(_hex, 0, edge), Paint()
        ..shader = _gold(goldRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.6
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round);
    }

    // الرؤوس تتلألأ
    if (edge >= 1) {
      for (var i = 0; i < _vertices.length; i++) {
        final tw = .35 + .65 * (math.sin((t - i * .5) / 3 * 2 * math.pi) + 1) / 2;
        canvas.drawCircle(_vertices[i], 2.2, Paint()
          ..color = const Color(0xFFFFF3DC).withValues(alpha: tw)
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2.2));
      }
    }

    // مسارات الدارة
    final tr = _seg(t, 1.5, .6, ease);
    if (tr > 0) {
      final p = Paint()
        ..color = const Color(0xFFFFB46A).withValues(alpha: .7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      for (final path in _traces) {
        canvas.drawPath(_part(path, 0, tr), p);
      }
    }

    // نبضات البيانات (2.6 ث لكل نبضة، بفارق 0.3 ث)
    final pulse = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);
    for (var i = 0; i < _pulseOrder.length; i++) {
      final start = 2.2 + i * .3;
      if (t < start) continue;
      final q = Cubic(.5, 0, .5, 1).transform(((t - start) % 2.6) / 2.6);
      final o = q < .1 ? q / .1 : (q < .7 ? 1.0 : 1 - (q - .7) / .3);
      // شَرطة طولها 14% تنتقل من -14% إلى 104% (stroke-dashoffset 14 → -104)
      final head = -.14 + 1.18 * q;
      final from = head.clamp(0.0, 1.0), to = (head + .14).clamp(0.0, 1.0);
      if (to > from) canvas.drawPath(_part(_traces[_pulseOrder[i]], from, to), pulse..color = Colors.white.withValues(alpha: o.clamp(0.0, 1.0)));
    }

    // العقد تقفز
    final nd = _seg(t, 1.9, .5, const Cubic(.34, 1.56, .64, 1));
    if (nd > 0) {
      for (final n in _nodes) {
        canvas.drawCircle(n, 3.4 * nd, Paint()..color = const Color(0xFF160A10));
        canvas.drawCircle(n, 3.4 * nd, Paint()
          ..shader = _gold(goldRect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8);
      }
    }

    // توهج M يتنفس (من 2 ث)
    if (t > 2) {
      final b = .25 + .6 * (math.sin((t - 2) / 3.2 * 2 * math.pi - math.pi / 2) + 1) / 2;
      canvas.drawPath(_m, Paint()
        ..color = const Color(0xFFFF8A3A).withValues(alpha: b)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    }
    // حرف M يرسم نفسه
    final m = _seg(t, .9, 1.0, ease);
    if (m > 0) {
      canvas.drawPath(_part(_m, 0, m), Paint()
        ..shader = const LinearGradient(colors: [Color(0xFFFFFAF0), Color(0xFFFFD59E), Color(0xFFFF8A3A)], begin: Alignment.topLeft, end: Alignment.bottomRight)
            .createShader(const Rect.fromLTWH(76, 74, 48, 52))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round);
    }
  }

  static void _dashedCircle(Canvas canvas, double r, List<double> dash, Paint p) {
    final circ = 2 * math.pi * r;
    var pos = 0.0, i = 0;
    while (pos < circ) {
      final len = dash[i % dash.length];
      if (i.isEven) canvas.drawArc(Rect.fromCircle(center: _c, radius: r), pos / r, len / r, false, p);
      pos += len;
      i++;
    }
  }

  @override
  bool shouldRepaint(GroupEmblemPainter o) => o.t != t;
}
