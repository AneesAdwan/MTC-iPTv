// V-10 الإعدادات: اللغة، الثيم، الأرقام، المشغّل، الرقابة الأبوية، التخزين والمزامنة، الخصوصية.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme/tokens.dart';
import '../../core/backend/backend.dart';
import '../../core/settings/local_settings.dart';
import '../../core/text/bidi.dart';
import '../../data/catalog/catalog_repository.dart';
import '../../data/epg/epg_repository.dart';
import '../../data/settings/remote_config.dart';
import 'guide_screen.dart' show fmtTime;
import 'home_screen.dart';

final _lastSyncProvider = StreamProvider<DateTime?>((ref) => ref.watch(catalogRepoProvider).watchLastSync());

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool syncing = false;

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _syncNow() async {
    final t = L10n.of(context);
    final sync = ref.read(catalogSyncProvider);
    if (sync == null) return;
    setState(() => syncing = true);
    try {
      await sync.syncReference();
      await sync.run();
      await ref.read(epgRepoProvider).sync(force: true);
      if (mounted) _toast(t.syncDone);
    } catch (_) {
      if (mounted) _toast(t.statusOffline);
    } finally {
      if (mounted) setState(() => syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context), c = context.colors;
    final s = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final last = ref.watch(_lastSyncProvider).value;
    final cats = ref.watch(categoriesProvider).value ?? const [];
    final locale = Localizations.localeOf(context);

    String lastText() {
      if (last == null) return t.never;
      final d = '${last.year}-${last.month.toString().padLeft(2, '0')}-${last.day.toString().padLeft(2, '0')}';
      return ltr('$d ${fmtTime(context, last)}');
    }

    return ListView(padding: const EdgeInsets.all(Space.lg), children: [
      _Section(title: t.sectionGeneral, children: [
        ListTile(
          leading: const Icon(Icons.translate_rounded),
          title: Text(t.language),
          trailing: SegmentedButton<String>(
            segments: const [ButtonSegment(value: 'ar', label: Text('العربية')), ButtonSegment(value: 'en', label: Text('English'))],
            selected: {s.locale.languageCode},
            onSelectionChanged: (v) => ctrl.setLocale(Locale(v.first)),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.contrast_rounded),
          title: Text(t.theme),
          trailing: SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(value: ThemeMode.dark, label: Text(t.themeDark)),
              ButtonSegment(value: ThemeMode.light, label: Text(t.themeLight)),
              ButtonSegment(value: ThemeMode.system, label: Text(t.themeSystem)),
            ],
            selected: {s.themeMode},
            onSelectionChanged: (v) => ctrl.setThemeMode(v.first),
          ),
        ),
        SwitchListTile(secondary: const Icon(Icons.pin_rounded), title: Text(t.showNumbers), value: s.showNumbers, onChanged: ctrl.setShowNumbers),
      ]),
      _Section(title: t.sectionPlayer, children: [
        ListTile(
          leading: const Icon(Icons.high_quality_rounded),
          title: Text(t.maxQuality),
          trailing: DropdownButton<int?>(
            value: s.maxQuality,
            underline: const SizedBox.shrink(),
            items: [
              DropdownMenuItem(value: null, child: Text(t.qualityNoLimit)),
              for (final h in const [720, 480, 360]) DropdownMenuItem(value: h, child: Text('${h}p')),
            ],
            onChanged: ctrl.setMaxQuality,
          ),
        ),
      ]),
      _Section(title: t.sectionParental, children: [
        ListTile(
          leading: const Icon(Icons.lock_rounded),
          title: Text(s.parentalOn ? t.lockedCategories : t.sectionParental),
          subtitle: Text(t.parentalHint, style: TextStyle(color: c.textMuted)),
          trailing: s.parentalOn
              ? OutlinedButton(
                  onPressed: () async {
                    if (await askPin(context, ref)) ctrl.setPin(null);
                  },
                  child: Text(t.removePin))
              : FilledButton.tonal(
                  onPressed: () async {
                    final pin = await _newPin(context);
                    if (pin != null) ctrl.setPin(pin, defaults: ref.read(remoteConfigProvider).value?.parentalLockedCategories ?? const []);
                  },
                  child: Text(t.setPin)),
        ),
        if (s.parentalOn)
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.md),
            child: Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
              for (final x in cats)
                FilterChip(
                  label: Text(x.item.displayName(locale)),
                  selected: s.lockedCategories.contains(x.item.slug),
                  onSelected: (_) => ctrl.toggleLockedCategory(x.item.slug),
                ),
            ]),
          ),
      ]),
      _Section(title: t.sectionStorage, children: [
        ListTile(
          leading: const Icon(Icons.sync_rounded),
          title: Text(t.lastSync(lastText())),
          trailing: FilledButton.tonalIcon(
            onPressed: syncing || ref.read(catalogSyncProvider) == null ? null : _syncNow,
            icon: syncing ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh_rounded, size: 18),
            label: Text(t.syncNow),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.history_rounded),
          title: Text(t.clearHistory),
          trailing: OutlinedButton(
            onPressed: () async {
              await ref.read(catalogRepoProvider).clearHistory();
              if (context.mounted) _toast(t.historyCleared);
            },
            child: Text(t.clearAll),
          ),
        ),
      ]),
      _Section(title: t.sectionPrivacy, children: [
        SwitchListTile(
          secondary: const Icon(Icons.insights_rounded),
          title: Text(t.telemetry),
          subtitle: Text(t.telemetryHint, style: TextStyle(color: c.textMuted)),
          value: s.telemetry,
          onChanged: ctrl.setTelemetry,
        ),
      ]),
    ]);
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: Space.sm, bottom: Space.sm),
          child: Text(title, style: TextStyle(color: c.accent, fontWeight: FontWeight.w700, fontSize: 13)),
        ),
        Material(
          color: c.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md), side: BorderSide(color: c.line)),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ]),
    );
  }
}

Widget _pinField(TextEditingController ctrl, String label, {String? error, VoidCallback? onDone}) => TextField(
      controller: ctrl,
      autofocus: true,
      obscureText: true,
      keyboardType: TextInputType.number,
      maxLength: 4,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 22, letterSpacing: 12),
      decoration: InputDecoration(labelText: label, errorText: error, counterText: ''),
      onSubmitted: (_) => onDone?.call(),
    );

Future<String?> _newPin(BuildContext context) {
  final t = L10n.of(context);
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) {
      void done() {
        if (ctrl.text.length == 4) Navigator.pop(context, ctrl.text);
      }

      return AlertDialog(
        title: Text(t.setPin),
        content: _pinField(ctrl, t.newPin, onDone: done),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
          FilledButton(onPressed: done, child: Text(t.save)),
        ],
      );
    },
  );
}

/// يطلب رمز الرقابة الأبوية؛ true إن كان صحيحًا (أو لا توجد رقابة).
Future<bool> askPin(BuildContext context, WidgetRef ref) async {
  final ctrl = ref.read(settingsProvider.notifier);
  if (!ref.read(settingsProvider).parentalOn) return true;
  final t = L10n.of(context);
  final input = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) {
      String? error;
      return StatefulBuilder(builder: (context, setState) {
        void done() {
          if (ctrl.checkPin(input.text)) {
            Navigator.pop(context, true);
          } else {
            setState(() => error = t.pinWrong);
            input.clear();
          }
        }

        return AlertDialog(
          title: Text(t.enterPin),
          content: _pinField(input, t.enterPin, error: error, onDone: done),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.cancel)),
            FilledButton(onPressed: done, child: Text(t.unlock)),
          ],
        );
      });
    },
  );
  // لا dispose هنا: الحقل قد يبقى مرسومًا أثناء حركة إغلاق الحوار
  return ok ?? false;
}
