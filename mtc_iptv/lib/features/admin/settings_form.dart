// محرّك نماذج الإعدادات المركزية (ADM-G1/G3/G4/G5): حقول معرّفة بقائمة، والقيمة JSON واحدة لكل مفتاح
// في site_settings. المفاتيح المتداخلة بالنقطة: «maintenance.enabled».
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme/tokens.dart';
import '../../data/admin/settings_repository.dart';
import 'widgets/admin_widgets.dart';

enum FieldKind { text, multiline, integer, toggle, choice, chips, ltr }

class FieldSpec {
  final String path; // «a.b»
  final String Function(L10n) label;
  final FieldKind kind;
  final List<(String, String Function(L10n))> options; // choice/chips
  final Object? initial;
  final String Function(L10n)? hint;
  const FieldSpec(this.path, this.label, this.kind, {this.options = const [], this.initial, this.hint});
}

class FieldGroup {
  final String Function(L10n) title;
  final List<FieldSpec> fields;
  const FieldGroup(this.title, this.fields);
}

Object? readPath(Map<String, dynamic> m, String path) {
  Object? cur = m;
  for (final p in path.split('.')) {
    if (cur is! Map) return null;
    cur = cur[p];
  }
  return cur;
}

void writePath(Map<String, dynamic> m, String path, Object? v) {
  final parts = path.split('.');
  var cur = m;
  for (final p in parts.take(parts.length - 1)) {
    final next = cur[p] is Map ? Map<String, dynamic>.from(cur[p] as Map) : <String, dynamic>{};
    cur[p] = next;
    cur = next;
  }
  cur[parts.last] = v;
}

/// نموذج لمفتاح واحد في site_settings.
class SettingsKeyForm extends ConsumerStatefulWidget {
  final String settingKey;
  final List<FieldGroup> groups;
  final Widget? footer;
  const SettingsKeyForm({super.key, required this.settingKey, required this.groups, this.footer});
  @override
  ConsumerState<SettingsKeyForm> createState() => _SettingsKeyFormState();
}

class _SettingsKeyFormState extends ConsumerState<SettingsKeyForm> {
  Map<String, dynamic>? value;
  final ctrls = <String, TextEditingController>{};
  bool saving = false, dirty = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final repo = ref.read(settingsRepoProvider);
    if (repo == null) return;
    try {
      final v = (await repo.get(widget.settingKey) as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      // القيم الافتراضية لما لم يُحفظ بعد
      for (final g in widget.groups) {
        for (final f in g.fields) {
          if (readPath(v, f.path) == null && f.initial != null) writePath(v, f.path, f.initial);
        }
      }
      setState(() => value = v);
    } catch (e) {
      setState(() => error = '$e');
    }
  }

  TextEditingController _ctrl(FieldSpec f) => ctrls.putIfAbsent(f.path, () => TextEditingController(text: '${readPath(value!, f.path) ?? ''}'));

  void _set(String path, Object? v) => setState(() {
        writePath(value!, path, v);
        dirty = true;
      });

  Future<void> _save() async {
    final repo = ref.read(settingsRepoProvider);
    if (repo == null || value == null) return;
    final t = L10n.of(context);
    setState(() => saving = true);
    try {
      await repo.set(widget.settingKey, value!);
      if (mounted) toast(context, t.saved);
      setState(() => dirty = false);
    } catch (e) {
      if (mounted) toast(context, t.saveFailed('$e'));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget _field(FieldSpec f, L10n t, MtcColors c) {
    final v = readPath(value!, f.path);
    final helper = f.hint == null ? null : f.hint!(t);
    switch (f.kind) {
      case FieldKind.toggle:
        return SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(f.label(t)), subtitle: helper == null ? null : Text(helper), value: v == true, onChanged: (x) => _set(f.path, x));
      case FieldKind.choice:
        return DropdownButtonFormField<String>(
          initialValue: v as String?,
          decoration: InputDecoration(labelText: f.label(t), helperText: helper),
          items: [for (final (k, l) in f.options) DropdownMenuItem(value: k, child: Text(l(t)))],
          onChanged: (x) => _set(f.path, x),
        );
      case FieldKind.chips:
        final sel = {for (final x in (v as List?) ?? const []) '$x'};
        return InputDecorator(
          decoration: InputDecoration(labelText: f.label(t), helperText: helper, border: InputBorder.none),
          child: Wrap(spacing: Space.xs, runSpacing: Space.xs, children: [
            for (final (k, l) in f.options)
              FilterChip(label: Text(l(t)), selected: sel.contains(k), onSelected: (on) => _set(f.path, (on ? (sel..add(k)) : (sel..remove(k))).toList()..sort())),
          ]),
        );
      case FieldKind.integer:
        return TextField(
          controller: _ctrl(f),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(labelText: f.label(t), helperText: helper),
          onChanged: (x) => _set(f.path, int.tryParse(x)),
        );
      case FieldKind.multiline:
      case FieldKind.text:
      case FieldKind.ltr:
        return TextField(
          controller: _ctrl(f),
          maxLines: f.kind == FieldKind.multiline ? 6 : 1,
          minLines: f.kind == FieldKind.multiline ? 3 : 1,
          textDirection: f.kind == FieldKind.ltr ? TextDirection.ltr : null,
          decoration: InputDecoration(labelText: f.label(t), helperText: helper, alignLabelWithHint: true),
          onChanged: (x) => _set(f.path, x.trim().isEmpty ? null : x),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context), c = context.colors;
    if (error != null) return Center(child: Text(error!));
    if (value == null) return const Center(child: CircularProgressIndicator());
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880),
        child: ListView(padding: const EdgeInsets.all(Space.lg), children: [
          Row(children: [
            Expanded(child: Text(t.hlPublishHint, style: TextStyle(color: c.textMuted, fontSize: 12.5))),
            FilledButton.icon(
              onPressed: saving || !dirty ? null : _save,
              icon: saving ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_rounded),
              label: Text(t.save),
            ),
          ]),
          const SizedBox(height: Space.md),
          for (final g in widget.groups) ...[
            SectionCard(
              title: g.title(t),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (final f in g.fields) Padding(padding: const EdgeInsets.only(bottom: Space.sm), child: _field(f, t, c)),
              ]),
            ),
            const SizedBox(height: Space.md),
          ],
          ?widget.footer,
        ]),
      ),
    );
  }
}
