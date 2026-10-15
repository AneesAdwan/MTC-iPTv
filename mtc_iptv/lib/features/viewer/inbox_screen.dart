// V-09 الإشعارات: صندوق وارد محلي (التذكيرات الآن؛ إعلانات الإدارة مع ADM-F1/F2).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme/tokens.dart';
import '../../core/storage/catalog_db.dart';
import '../../data/reminders/reminders.dart';
import 'guide_screen.dart' show fmtTime;
import 'widgets/channel_card.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});
  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  late final ReminderService _reminders;

  @override
  void initState() {
    super.initState();
    _reminders = ref.read(remindersProvider);
  }

  @override
  void dispose() {
    _reminders.markAllRead(); // ما عُرض يُعدّ مقروءًا بعد مغادرة الشاشة
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context), c = context.colors;
    final items = ref.watch(inboxProvider).value ?? const <InboxRow>[];
    if (items.isEmpty) return EmptyState(icon: Icons.notifications_none_rounded, title: t.inboxEmpty);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg, 0),
        child: Row(children: [
          const Spacer(),
          TextButton.icon(onPressed: _reminders.markAllRead, icon: const Icon(Icons.done_all_rounded, size: 18), label: Text(t.markAllRead)),
          TextButton.icon(onPressed: _reminders.clearInbox, icon: const Icon(Icons.delete_sweep_rounded, size: 18), label: Text(t.clearAll)),
        ]),
      ),
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.all(Space.lg),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
          itemBuilder: (_, i) {
            final m = items[i];
            final start = DateTime.tryParse(m.body ?? '');
            return Material(
              color: m.read ? c.surface : c.accent.withValues(alpha: .10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md), side: BorderSide(color: m.read ? c.line : c.accent.withValues(alpha: .5))),
              child: ListTile(
                leading: Icon(m.kind == 'reminder' ? Icons.notifications_active_rounded : Icons.campaign_rounded, color: c.accent),
                title: Text(m.title, style: TextStyle(color: c.text, fontWeight: m.read ? FontWeight.w500 : FontWeight.w700)),
                subtitle: Text([t.kindReminder, if (start != null) fmtTime(context, start)].join(' · '), style: TextStyle(color: c.textMuted)),
                trailing: m.channelId == null ? null : FilledButton.tonal(onPressed: () => context.push('/watch/${m.channelId}'), child: Text(t.watchNow)),
              ),
            );
          },
        ),
      ),
    ]);
  }
}
