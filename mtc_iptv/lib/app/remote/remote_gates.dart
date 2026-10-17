// آثار الإعدادات المركزية على المشاهد:
//   G5 وضع الصيانة: شاشة الرسالة للمشاهدين (برنامج SuperAdmin لا يُحجب).
//   G6 الحد الأدنى المدعوم: الأقدم يُجبر على التحديث. الموصى به: شريط تنبيه.
//   F2 الإعلانات: شريط (معلومة/تحذير/صيانة) أو نافذة ترحيبية مرة واحدة، والقابل للإغلاق يُحفظ إغلاقه.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/backend/backend.dart';
import '../../core/config/env.dart';
import '../../data/settings/remote_config.dart';
import '../../data/updates/app_updater.dart';
import '../l10n/app_localizations.dart';
import '../shell/sidebar.dart' show isAdminProvider;
import '../theme/tokens.dart';

/// يلف التطبيق كله (تحت الموجّه): الصيانة والتحديث الإجباري.
class RemoteGates extends ConsumerWidget {
  final Widget child;
  const RemoteGates({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rc = ref.watch(remoteConfigProvider).value ?? RemoteConfig.empty;
    // برنامج SuperAdmin لا تحجبه الصيانة ولا التحديث الإجباري (تحديثه منفصل عن تطبيق المشاهدين)
    final admin = Env.superAdmin || ref.watch(isAdminProvider);
    final lang = Localizations.localeOf(context).languageCode;
    final t = L10n.of(context);
    if (rc.updateRequirement(Env.version) == 'force' && !admin) {
      return _FullPage(
        icon: Icons.system_update_rounded,
        title: t.updateRequired,
        body: '${rc.releases['notes_$lang'] ?? ''}',
        action: FilledButton(onPressed: () => AppUpdater.checkNow(fallbackUrl: rc.updateUrl, context: context), child: Text(t.updateNow)),
      );
    }
    if (rc.maintenance && !admin) {
      return _FullPage(
        icon: Icons.construction_rounded,
        title: t.maintenanceTitle,
        body: rc.maintenanceMessage(lang),
      );
    }
    return child;
  }
}

class _FullPage extends StatelessWidget {
  final IconData icon;
  final String title, body;
  final Widget? action;
  const _FullPage({required this.icon, required this.title, required this.body, this.action});
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.bg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 56, color: c.accent),
              const SizedBox(height: Space.md),
              Text(title, textAlign: TextAlign.center, style: TextStyle(color: c.text, fontSize: 22, fontWeight: FontWeight.w800)),
              if (body.isNotEmpty) ...[const SizedBox(height: Space.sm), Text(body, textAlign: TextAlign.center, style: TextStyle(color: c.textMuted, height: 1.5))],
              if (action != null) ...[const SizedBox(height: Space.lg), action!],
            ]),
          ),
        ),
      ),
    );
  }
}

// ── الإعلانات وتنبيه التحديث داخل الهيكل ─────────────────────────────────
final _dismissedProvider = StreamProvider<Set<String>>((ref) {
  final db = ref.watch(catalogDbProvider);
  return (db.select(db.syncState)..where((s) => s.key.equals('dismissed_announcements')))
      .watchSingleOrNull()
      .map((r) => r == null ? <String>{} : {for (final x in jsonDecode(r.value) as List) '$x'});
});

Future<void> _dismiss(WidgetRef ref, String id) async {
  final db = ref.read(catalogDbProvider);
  final cur = ref.read(_dismissedProvider).value ?? const <String>{};
  await db.setSyncValue('dismissed_announcements', jsonEncode([...cur, id].reversed.take(200).toList()));
}

/// الشرائط أعلى المحتوى (تحت الشريط العلوي)، والنافذة الترحيبية مرة واحدة.
class AnnouncementBar extends ConsumerStatefulWidget {
  const AnnouncementBar({super.key});
  @override
  ConsumerState<AnnouncementBar> createState() => _AnnouncementBarState();
}

class _AnnouncementBarState extends ConsumerState<AnnouncementBar> {
  final _shownDialogs = <String>{};
  bool _updateClosed = false;

  @override
  Widget build(BuildContext context) {
    final rc = ref.watch(remoteConfigProvider).value ?? RemoteConfig.empty;
    final dismissed = ref.watch(_dismissedProvider).value ?? const <String>{};
    final lang = Localizations.localeOf(context).languageCode;
    final t = L10n.of(context), c = context.colors;
    String txt(Map a, String k) => '${a['${k}_$lang'] ?? a['${k}_${lang == 'ar' ? 'en' : 'ar'}'] ?? ''}';
    final active = [for (final a in rc.announcements) if (announcementActive(a) && !dismissed.contains('${a['id']}')) a];

    // النافذة الترحيبية: مرة واحدة لكل إعلان
    for (final a in active.where((a) => a['style'] == 'dialog')) {
      final id = '${a['id']}';
      if (_shownDialogs.add(id)) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await showDialog(
            context: context,
            barrierDismissible: a['dismissible'] != false,
            builder: (d) => AlertDialog(
              title: Text(txt(a, 'title')),
              content: Text(txt(a, 'body')),
              // autofocus: زر الإغلاق مركّز من البداية، فـ OK في الريموت يغلق النافذة مباشرة
              actions: [TextButton(autofocus: true, onPressed: () => Navigator.pop(d), child: Text(t.close))],
            ),
          );
          await _dismiss(ref, id);
        });
      }
    }

    Color color(String kind) => switch (kind) { 'warning' => const Color(0xFFEAB308), 'maintenance' => const Color(0xFFEF4444), _ => c.accent };
    final banners = [for (final a in active) if (a['style'] != 'dialog') a];
    final recommend = !_updateClosed && rc.updateRequirement(Env.version) == 'recommend';
    if (banners.isEmpty && !recommend) return const SizedBox.shrink();
    return Column(children: [
      if (recommend)
        _Banner(
          color: c.accent,
          icon: Icons.system_update_rounded,
          text: t.updateRecommended,
          action: TextButton(onPressed: () => AppUpdater.checkNow(fallbackUrl: rc.updateUrl, context: context), child: Text(t.updateNow)),
          onClose: () => setState(() => _updateClosed = true),
        ),
      for (final a in banners)
        _Banner(
          color: color('${a['kind']}'),
          icon: a['kind'] == 'warning' ? Icons.warning_amber_rounded : (a['kind'] == 'maintenance' ? Icons.construction_rounded : Icons.info_outline_rounded),
          text: [txt(a, 'title'), txt(a, 'body')].where((s) => s.isNotEmpty).join(' — '),
          onClose: a['dismissible'] == false ? null : () => _dismiss(ref, '${a['id']}'),
        ),
    ]);
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  final Widget? action;
  final VoidCallback? onClose;
  const _Banner({required this.color, required this.icon, required this.text, this.action, this.onClose});
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      color: color.withValues(alpha: .14),
      padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: 6),
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: Space.sm),
        Expanded(child: Text(text, style: TextStyle(color: c.text, fontSize: 13))),
        ?action,
        if (onClose != null) IconButton(visualDensity: VisualDensity.compact, onPressed: onClose, icon: const Icon(Icons.close_rounded, size: 18)),
      ]),
    );
  }
}
