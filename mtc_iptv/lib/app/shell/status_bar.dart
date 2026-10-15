// شريط الحالة السفلي (§6.6): المهام الخلفية الجارية + البيئة + الإصدار.
// المهام الحقيقية تأتي من المُجدوِل (المرحلة 2)؛ الآن يعرض «لا مهام جارية».
import 'package:flutter/material.dart';

import '../../core/config/env.dart';
import '../l10n/app_localizations.dart';
import '../theme/tokens.dart';

class StatusBar extends StatelessWidget {
  const StatusBar({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.colors, t = L10n.of(context);
    final style = TextStyle(fontSize: 11.5, color: c.textDim);
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: Space.md),
      decoration: BoxDecoration(color: c.bg2, border: Border(top: BorderSide(color: c.line))),
      child: Row(children: [
        Icon(Icons.check_circle_outline_rounded, size: 13, color: c.textDim),
        const SizedBox(width: 6),
        Text(t.statusIdle, style: style),
        const Spacer(),
        if (Env.isStaging) ...[Text('staging', style: style.copyWith(color: c.warn)), const SizedBox(width: Space.md)],
        Text(t.version(Env.version), style: style),
      ]),
    );
  }
}
