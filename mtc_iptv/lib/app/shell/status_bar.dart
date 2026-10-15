// شريط الحالة السفلي (§6.6): المهام الخلفية الجارية + البيئة + الإصدار.
// المهمة الجارية الآن: فحص الروابط (ADM-D4)؛ بقية المهام مع ADM-A2/H2.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/env.dart';
import '../../data/admin/health_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/tokens.dart';

class StatusBar extends ConsumerWidget {
  const StatusBar({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors, t = L10n.of(context);
    final style = TextStyle(fontSize: 11.5, color: c.textDim);
    final job = ref.watch(healthJobProvider);
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: Space.md),
      decoration: BoxDecoration(color: c.bg2, border: Border(top: BorderSide(color: c.line))),
      child: Row(children: [
        if (job.running) ...[
          SizedBox.square(dimension: 12, child: CircularProgressIndicator(strokeWidth: 1.6, value: job.progress, color: c.accent)),
          const SizedBox(width: 6),
          InkWell(onTap: () => context.go('/admin/health'), child: Text(t.checkRunning(job.done, job.total), style: style.copyWith(color: c.text))),
        ] else ...[
          Icon(Icons.check_circle_outline_rounded, size: 13, color: c.textDim),
          const SizedBox(width: 6),
          Text(t.statusIdle, style: style),
        ],
        const Spacer(),
        if (Env.isStaging) ...[Text('staging', style: style.copyWith(color: c.warn)), const SizedBox(width: Space.md)],
        Text(t.version(Env.version), style: style),
      ]),
    );
  }
}
