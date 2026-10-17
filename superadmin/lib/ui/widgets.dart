// Small shared pieces: brand mark, KPI card, panel, form helpers.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme/tokens.dart';
import '../core/tr.dart';

/// MTC-iPTv emblem drawn in code (gradient disc + play mark + broadcast arcs), so no SVG dependency.
class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 32});
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _BrandPainter());
}

class _BrandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 64;
    canvas.scale(s);
    const grad = LinearGradient(colors: [Color(0xFFFF2D55), Color(0xFFFF5A36), Color(0xFFFFB02E)]);
    final shader = grad.createShader(const Rect.fromLTWH(8, 8, 48, 48));
    canvas.drawCircle(const Offset(32, 32), 12.5, Paint()..shader = shader);
    final play = Path()
      ..moveTo(28.5, 25.5)
      ..lineTo(38.5, 32)
      ..lineTo(28.5, 38.5)
      ..close();
    canvas.drawPath(play, Paint()..color = Colors.white);
    final arc = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.8
      ..strokeCap = StrokeCap.round;
    for (final r in [16.0, 25.0]) {
      final rect = Rect.fromCircle(center: const Offset(32, 32), radius: r);
      canvas.drawArc(rect, -math.pi / 4, math.pi / 2, false, arc);
      canvas.drawArc(rect, math.pi * 3 / 4, math.pi / 2, false, arc);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Panel extends StatelessWidget {
  final Tr? title;
  final Widget child;
  final List<Widget> actions;
  final EdgeInsetsGeometry padding;
  const Panel({super.key, this.title, required this.child, this.actions = const [], this.padding = const EdgeInsets.all(Space.lg)});
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Material (not a decorated box) so ListTiles inside keep their ink and backgrounds.
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: c.line),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(context.tr(title!), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                  ...actions,
                ],
              ),
              const SizedBox(height: Space.md),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class KpiCard extends StatelessWidget {
  final Tr label;
  final String value;
  final Tr? hint;
  final Tone tone;
  final IconData icon;
  final VoidCallback? onTap;
  const KpiCard({super.key, required this.label, required this.value, this.hint, this.tone = Tone.neutral, required this.icon, this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final col = c.tone(tone);
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: c.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: col.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Radii.sm)),
                child: Icon(icon, color: col),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    Text(
                      context.tr(label),
                      style: TextStyle(color: c.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hint != null)
                      Text(
                        context.tr(hint!),
                        style: TextStyle(color: c.textDim, fontSize: 11.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Label + field row used by settings forms.
class FieldRow extends StatelessWidget {
  final Tr label;
  final Tr? help;
  final Widget field;
  const FieldRow({super.key, required this.label, required this.field, this.help});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Space.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 220,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr(label), style: const TextStyle(fontWeight: FontWeight.w600)),
                if (help != null) Text(context.tr(help!), style: TextStyle(color: context.colors.textDim, fontSize: 12)),
              ],
            ),
          ),
        ),
        const SizedBox(width: Space.lg),
        Expanded(child: field),
      ],
    ),
  );
}

/// A notice that this screen shows sample data until Phase 2 wires the server.
class StubNotice extends StatelessWidget {
  const StubNotice({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm),
      decoration: BoxDecoration(
        color: c.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: c.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.science_outlined, size: 16, color: c.info),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(
              context.tr(
                const Tr(
                  'بيانات تجريبية: دوال الخادم بتنربط بالمرحلة 2. أي حفظ هون ما بينفّذ شي وبيقلك هيك.',
                  'Sample data: server functions are wired in Phase 2. Saving here runs nothing and says so.',
                ),
              ),
              style: TextStyle(color: c.textMuted, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}
