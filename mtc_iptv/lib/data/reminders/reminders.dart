// التذكيرات (§8.5) وصندوق الوارد (V-09).
// «ذكّرني» يحفظ التذكير محليًا؛ المؤقّت يفحص كل 30 ثانية ويُطلق ما بقي على بدايته ≤ 5 دقائق:
// يُضاف لصندوق الوارد ويظهر تنبيه داخل البرنامج بزر «شاهد».
// (إشعارات النظام خارج البرنامج تأتي مع Android في R2 عبر إضافة الإشعارات المحلية.)
import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/backend/backend.dart';
import '../../core/storage/catalog_db.dart';

class ReminderService {
  static const lead = Duration(minutes: 5);
  final CatalogDb db;
  ReminderService(this.db);

  Stream<bool> watchIsSet(String channelId, DateTime startAt) =>
      (db.select(db.reminders)..where((r) => r.channelId.equals(channelId) & r.startAt.equals(startAt))).watchSingleOrNull().map((r) => r != null);

  Stream<Set<String>> watchKeys() => db.select(db.reminders).watch().map((rs) => {for (final r in rs) key(r.channelId, r.startAt)});

  static String key(String channelId, DateTime startAt) => '$channelId@${startAt.millisecondsSinceEpoch}';

  Future<bool> toggle(String channelId, DateTime startAt, String title) => db.transaction(() async {
        final q = db.delete(db.reminders)..where((r) => r.channelId.equals(channelId) & r.startAt.equals(startAt));
        if (await q.go() > 0) return false;
        await db.into(db.reminders).insert(RemindersCompanion.insert(channelId: channelId, startAt: startAt, title: title));
        return true;
      });

  /// يُطلق المستحق ويعيده (للتنبيه داخل البرنامج). المنتهية منذ زمن تُحذف دون تنبيه.
  Future<List<ReminderRow>> fireDue({DateTime? now}) => db.transaction(() async {
        final t = now ?? DateTime.now();
        await (db.delete(db.reminders)..where((r) => r.startAt.isSmallerThanValue(t.subtract(const Duration(hours: 2))))).go();
        final due = await (db.select(db.reminders)..where((r) => r.fired.equals(false) & r.startAt.isSmallerOrEqualValue(t.add(lead)))).get();
        for (final r in due) {
          await (db.update(db.reminders)..where((x) => x.channelId.equals(r.channelId) & x.startAt.equals(r.startAt)))
              .write(const RemindersCompanion(fired: Value(true)));
          await db.into(db.inbox).insert(InboxCompanion.insert(kind: 'reminder', title: r.title, channelId: Value(r.channelId), at: t, body: Value(r.startAt.toIso8601String())));
        }
        return due;
      });

  // ── صندوق الوارد ─────────────────────────────────────────────────────────
  Stream<List<InboxRow>> watchInbox() => (db.select(db.inbox)..orderBy([(i) => OrderingTerm.desc(i.at)])).watch();
  Stream<int> watchUnread() {
    final n = db.inbox.id.count();
    return (db.selectOnly(db.inbox)
          ..addColumns([n])
          ..where(db.inbox.read.equals(false)))
        .watchSingle()
        .map((r) => r.read(n) ?? 0);
  }

  Future<void> markAllRead() => db.update(db.inbox).write(const InboxCompanion(read: Value(true)));
  Future<void> clearInbox() => db.delete(db.inbox).go();
}

final remindersProvider = Provider<ReminderService>((ref) => ReminderService(ref.watch(catalogDbProvider)));
final inboxProvider = StreamProvider<List<InboxRow>>((ref) => ref.watch(remindersProvider).watchInbox());
final unreadProvider = StreamProvider<int>((ref) => ref.watch(remindersProvider).watchUnread());
final reminderKeysProvider = StreamProvider<Set<String>>((ref) => ref.watch(remindersProvider).watchKeys());

/// التذكيرات المنطلقة (يستمع لها التطبيق ليعرض التنبيه).
final firedRemindersProvider = StreamProvider<ReminderRow>((ref) {
  final r = ref.watch(remindersProvider);
  final out = StreamController<ReminderRow>();
  Future<void> tick() async {
    for (final x in await r.fireDue()) {
      out.add(x);
    }
  }

  final timer = Timer.periodic(const Duration(seconds: 30), (_) => tick());
  tick();
  ref.onDispose(() {
    timer.cancel();
    out.close();
  });
  return out.stream;
});
