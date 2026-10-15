// ADM-B5 التقسيمات (§9.4): الفئات، الدول، اللغات — الاسمان، الترتيب، الظهور، وعدد القنوات مع منع حذف المستخدم.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme/tokens.dart';
import '../../data/admin/admin_repository.dart';
import 'channels/channels_admin_screen.dart';
import 'widgets/admin_widgets.dart';

final _taxProvider = FutureProvider.autoDispose.family<(List<Map<String, dynamic>>, Map<String, int>), String>((ref, table) async {
  final repo = ref.watch(adminRepoProvider);
  if (repo == null) return (const <Map<String, dynamic>>[], const <String, int>{});
  return (await repo.taxonomy(table), await repo.taxonomyUsage(table));
});

/// حقل قابل للتعديل: (العمود، النوع: text|int|bool|key)
typedef _Field = (String col, String kind, String Function(L10n) label);

final _fields = <String, List<_Field>>{
  'categories': [
    ('slug', 'key', (t) => t.fSlug),
    ('name_ar', 'text', (t) => t.fNameAr),
    ('name_en', 'text', (t) => t.fNameEn),
    ('icon', 'text', (t) => t.fIcon),
    ('hue', 'int', (t) => t.fHue),
    ('sort_order', 'int', (t) => t.fSort),
    ('is_visible', 'bool', (t) => t.fVisible),
  ],
  'countries': [
    ('code', 'key', (t) => 'ISO'),
    ('name_ar', 'text', (t) => t.fNameAr),
    ('name_en', 'text', (t) => t.fNameEn),
    ('flag_emoji', 'text', (t) => t.fFlag),
    ('continent', 'text', (t) => t.fContinent),
    ('is_arab', 'bool', (t) => t.fArab),
    ('sort_order', 'int', (t) => t.fSort),
    ('is_visible', 'bool', (t) => t.fVisible),
  ],
  'languages': [
    ('code', 'key', (t) => 'ISO-639-3'),
    ('name_ar', 'text', (t) => t.fNameAr),
    ('name_en', 'text', (t) => t.fNameEn),
    ('sort_order', 'int', (t) => t.fSort),
    ('is_visible', 'bool', (t) => t.fVisible),
  ],
};

const _filterParam = {'categories': 'category', 'countries': 'country'};

class TaxonomyScreen extends ConsumerWidget {
  const TaxonomyScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context);
    return DefaultTabController(
      length: 3,
      child: Column(children: [
        TabBar(tabs: [Tab(text: t.tabCategories), Tab(text: t.tabCountries), Tab(text: t.tabLanguages)]),
        const Expanded(child: TabBarView(children: [_Table(table: 'categories'), _Table(table: 'countries'), _Table(table: 'languages')])),
      ]),
    );
  }
}

class _Table extends ConsumerWidget {
  final String table;
  const _Table({required this.table});

  Future<void> _edit(BuildContext context, WidgetRef ref, Map<String, dynamic>? row) async {
    final repo = ref.read(adminRepoProvider);
    if (repo == null) return;
    final saved = await showDialog<bool>(context: context, builder: (_) => _EditDialog(table: table, row: row, repo: repo));
    if (saved == true) {
      ref.invalidate(_taxProvider(table));
      ref.invalidate(adminRefProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context), c = context.colors;
    final lang = Localizations.localeOf(context).languageCode;
    final data = ref.watch(_taxProvider(table));
    final rows = data.value?.$1 ?? const <Map<String, dynamic>>[];
    final usage = data.value?.$2 ?? const <String, int>{};
    final key = AdminRepository.taxonomyKey[table]!;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.lg, Space.sm),
        child: Row(children: [
          FilledButton.icon(onPressed: () => _edit(context, ref, null), icon: const Icon(Icons.add_rounded), label: Text(t.addItem)),
          const Spacer(),
          if (data.isLoading) const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          if (data.hasError) Text('${data.error}', style: const TextStyle(color: Color(0xFFEF4444))),
        ]),
      ),
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: Space.lg),
          itemCount: rows.length,
          separatorBuilder: (_, _) => Divider(height: 1, color: c.line),
          itemBuilder: (_, i) {
            final r = rows[i];
            final k = '${r[key]}';
            final n = usage[k] ?? 0;
            final visible = r['is_visible'] != false;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: SizedBox(
                width: 64,
                child: Text([if (r['flag_emoji'] != null) '${r['flag_emoji']}', k].join(' '), style: TextStyle(color: c.textMuted, fontWeight: FontWeight.w600)),
              ),
              title: Text('${lang == 'ar' ? r['name_ar'] : r['name_en']}', style: TextStyle(color: visible ? c.text : c.textDim, fontWeight: FontWeight.w600)),
              subtitle: Text('${lang == 'ar' ? r['name_en'] : r['name_ar']} · ${t.fSort} ${r['sort_order']}', style: TextStyle(color: c.textMuted, fontSize: 12)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (!visible) Padding(padding: const EdgeInsetsDirectional.only(end: Space.sm), child: Icon(Icons.visibility_off_rounded, size: 18, color: c.textDim)),
                ActionChip(
                  label: Text(t.usedBy(n)),
                  onPressed: _filterParam[table] == null || n == 0 ? null : () => context.go('/admin/channels?${_filterParam[table]}=$k'),
                ),
                IconButton(tooltip: t.aEdit, onPressed: () => _edit(context, ref, r), icon: const Icon(Icons.edit_rounded, size: 20)),
                IconButton(
                  tooltip: n > 0 ? t.cannotDeleteUsed(n) : t.aDelete,
                  onPressed: n > 0
                      ? null
                      : () async {
                          final repo = ref.read(adminRepoProvider);
                          if (repo == null || !await confirm(context, t.confirmDelete(1))) return;
                          try {
                            await repo.deleteTaxonomy(table, k);
                          } catch (e) {
                            if (context.mounted) toast(context, t.saveFailed('$e'));
                          }
                          ref.invalidate(_taxProvider(table));
                          ref.invalidate(adminRefProvider);
                        },
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                ),
              ]),
            );
          },
        ),
      ),
    ]);
  }
}

class _EditDialog extends StatefulWidget {
  final String table;
  final Map<String, dynamic>? row;
  final AdminRepository repo;
  const _EditDialog({required this.table, required this.row, required this.repo});
  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late final fields = _fields[widget.table]!;
  late final ctrls = {
    for (final f in fields)
      if (f.$2 != 'bool') f.$1: TextEditingController(text: widget.row?[f.$1]?.toString() ?? (f.$1 == 'sort_order' ? '100' : (f.$1 == 'hue' ? '220' : (f.$1 == 'icon' ? 'tv' : '')))),
  };
  late final bools = {for (final f in fields) if (f.$2 == 'bool') f.$1: widget.row?[f.$1] == true || (widget.row == null && f.$1 == 'is_visible')};
  String? error;
  bool saving = false;

  @override
  void dispose() {
    for (final x in ctrls.values) {
      x.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final row = <String, dynamic>{};
    for (final f in fields) {
      switch (f.$2) {
        case 'bool':
          row[f.$1] = bools[f.$1];
        case 'int':
          row[f.$1] = int.tryParse(ctrls[f.$1]!.text.trim()) ?? 0;
        default:
          final v = ctrls[f.$1]!.text.trim();
          row[f.$1] = v.isEmpty ? null : (widget.table == 'countries' && f.$1 == 'code' ? v.toUpperCase() : v);
      }
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.repo.upsertTaxonomy(widget.table, row);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        saving = false;
        error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    return AlertDialog(
      title: Text(widget.row == null ? t.addItem : t.aEdit),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final f in fields)
              if (f.$2 == 'bool')
                SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(f.$3(t)), value: bools[f.$1]!, onChanged: (v) => setState(() => bools[f.$1] = v))
              else
                TextField(
                  controller: ctrls[f.$1],
                  enabled: !(f.$2 == 'key' && widget.row != null), // المفتاح لا يتغير بعد الإنشاء (مرجع للقنوات)
                  keyboardType: f.$2 == 'int' ? TextInputType.number : null,
                  inputFormatters: f.$2 == 'int' ? [FilteringTextInputFormatter.digitsOnly] : null,
                  decoration: InputDecoration(labelText: f.$3(t)),
                ),
            if (error != null) Padding(padding: const EdgeInsets.only(top: Space.sm), child: Text(error!, style: const TextStyle(color: Color(0xFFEF4444)))),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.cancel)),
        FilledButton(onPressed: saving ? null : _save, child: Text(t.save)),
      ],
    );
  }
}
