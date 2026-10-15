// شاشة مؤقتة لكل شاشة في السجل حتى تُبنى في مرحلتها (§25).
// تعرض المعرّف والمرحلة، فيبقى التنقل في الهيكل كاملًا قابلًا للتجربة من اليوم الأول.
import 'package:flutter/material.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/screens.dart';
import '../../app/theme/tokens.dart';
import '../../core/text/bidi.dart';

class PlaceholderScreen extends StatelessWidget {
  final ScreenDef def;
  const PlaceholderScreen({super.key, required this.def});

  @override
  Widget build(BuildContext context) {
    final c = context.colors, t = L10n.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: c.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Radii.lg)),
              child: Icon(def.icon, size: 36, color: c.accent),
            ),
            const SizedBox(height: Space.lg),
            Text(def.title(t), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.text)),
            const SizedBox(height: Space.xs),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(def.id, style: TextStyle(color: c.textDim, fontSize: 12, letterSpacing: 0.5)),
            ),
            const SizedBox(height: Space.lg),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: 6),
              decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(99), border: Border.all(color: c.line)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.construction_rounded, size: 15, color: c.warn),
                const SizedBox(width: 6),
                Text(t.placeholderTitle, style: TextStyle(color: c.textMuted, fontSize: 12.5)),
              ]),
            ),
            const SizedBox(height: Space.md),
            Text(t.placeholderBody(ltr(def.id), '${def.phase}'), textAlign: TextAlign.center, style: TextStyle(color: c.textMuted)),
          ]),
        ),
      ),
    );
  }
}
