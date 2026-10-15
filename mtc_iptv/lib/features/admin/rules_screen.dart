// ADM-C6 قواعد التحويل (§9.5، §10.3): group-title ← فئة، نصوص ← دولة أو لغة، تنظيف الأسماء، معرّفات خارجية ← قنواتنا.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme/tokens.dart';
import '../../data/admin/admin_repository.dart';
import 'epg_screens.dart' show migrationAware;
import 'widgets/admin_widgets.dart';

const ruleKinds = ['group_category', 'name_country', 'name_language', 'name_cleanup', 'id_map'];

String ruleKindLabel(L10n t, String k) => switch (k) {
      'group_category' => t.rkGroupCategory,
      'name_country' => t.rkNameCountry,
      'name_language' => t.rkNameLanguage,
      'name_cleanup' => t.rkNameCleanup,
      _ => t.rkIdMap,
    };

final _rulesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async => await ref.watch(adminRepoProvider)?.transformRules() ?? const []);

class RulesScreen extends ConsumerWidget {
  const RulesScreen({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, Map<String, dynamic>? row) async {
    final t = L10n.of(context);
    var kind = (row?['kind'] as String?) ?? 'group_category';
    var regex = row?['is_regex'] == true;
    final pattern = TextEditingController(text: row?['pattern'] as String? ?? ''), target = TextEditingController(text: row?['target'] as String? ?? '');
    final note = TextEditingController(text: row?['note'] as String? ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, set) => AlertDialog(
          title: Text(row == null ? t.addItem : t.aEdit),
          content: SizedBox(
            width: 480,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                initialValue: kind,
                items: [for (final k in ruleKinds) DropdownMenuItem(value: k, child: Text(ruleKindLabel(t, k)))],
                onChanged: (v) => set(() => kind = v ?? kind),
              ),
              TextField(controller: pattern, decoration: InputDecoration(labelText: t.rPattern)),
              TextField(controller: target, decoration: InputDecoration(labelText: t.rTarget, helperText: kind == 'name_cleanup' ? '' : null)),
              CheckboxListTile(contentPadding: EdgeInsets.zero, value: regex, onChanged: (v) => set(() => regex = v ?? false), title: Text(t.rRegex)),
              TextField(controller: note, decoration: InputDecoration(labelText: t.rNote)),
            ]),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: Text(t.cancel)), FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(t.save))],
        ),
      ),
    );
    if (ok != true || pattern.text.trim().isEmpty) return;
    try {
      await ref.read(adminRepoProvider)?.upsertRule({
        'id': ?row?['id'],
        'kind': kind,
        'pattern': pattern.text.trim(),
        'target': target.text.trim(),
        'is_regex': regex,
        'note': note.text.trim().isEmpty ? null : note.text.trim(),
      });
    } catch (e) {
      if (context.mounted) toast(context, t.saveFailed('$e'));
    }
    ref.invalidate(_rulesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context), c = context.colors;
    final async = ref.watch(_rulesProvider);
    if (async.hasError) return migrationAware(context, async.error!);
    final rules = async.value ?? const <Map<String, dynamic>>[];
    return ListView(padding: const EdgeInsets.all(Space.lg), children: [
      Row(children: [
        FilledButton.icon(onPressed: () => _edit(context, ref, null), icon: const Icon(Icons.add_rounded), label: Text(t.addItem)),
        const SizedBox(width: Space.md),
        Expanded(child: Text(t.rulesHint, style: TextStyle(color: c.textMuted, fontSize: 12.5))),
      ]),
      const SizedBox(height: Space.md),
      for (final k in ruleKinds)
        if (rules.any((r) => r['kind'] == k))
          Padding(
            padding: const EdgeInsets.only(bottom: Space.md),
            child: SectionCard(
              title: ruleKindLabel(t, k),
              child: Column(children: [
                for (final r in rules.where((r) => r['kind'] == k))
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Switch(
                      value: r['enabled'] == true,
                      onChanged: (v) async {
                        await ref.read(adminRepoProvider)?.upsertRule({...r, 'enabled': v});
                        ref.invalidate(_rulesProvider);
                      },
                    ),
                    title: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text('${r['is_regex'] == true ? '/${r['pattern']}/' : '"${r['pattern']}"'}  →  ${'${r['target']}'.isEmpty ? '∅' : r['target']}',
                          style: TextStyle(color: c.text, fontFamily: 'monospace', fontSize: 13)),
                    ),
                    subtitle: r['note'] == null ? null : Text('${r['note']}', style: TextStyle(color: c.textMuted)),
                    trailing: Wrap(children: [
                      IconButton(onPressed: () => _edit(context, ref, r), icon: const Icon(Icons.edit_rounded, size: 18)),
                      IconButton(
                        onPressed: () async {
                          if (!await confirm(context, t.confirmDelete(1))) return;
                          await ref.read(adminRepoProvider)?.deleteRule(r['id'] as String);
                          ref.invalidate(_rulesProvider);
                        },
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      ),
                    ]),
                  ),
              ]),
            ),
          ),
    ]);
  }
}
