// Shared page plumbing: "preview → reason → server function → result bar", URL-backed filters,
// and two reusable page templates (records table, settings form).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/nav.dart';
import '../app/theme/tokens.dart';
import '../core/errors.dart';
import '../core/prefs.dart';
import '../core/tr.dart';
import '../data/models.dart';
import '../data/paging.dart';
import '../data/providers.dart';
import '../data/rpc/admin_rpc.dart';
import '../ui/data_table.dart';
import '../ui/filter_bar.dart';
import '../ui/page_scaffold.dart';
import '../ui/preview_dialog.dart';
import '../ui/result_bar.dart';
import '../ui/selection.dart';
import '../ui/states.dart';
import '../ui/widgets.dart';

/// Preview → (user confirms with a reason) → [run] → result bar (+ undo when the class allows it).
Future<OpResult?> previewAndRun(
  BuildContext context,
  WidgetRef ref,
  OperationPreview preview,
  Future<OpResult> Function(String reason) run, {
  Tr? title,
}) async {
  final decision = await showPreviewDialog(context, preview);
  if (decision == null) return null;
  final result = await run(decision.reason);
  final center = ref.read(resultCenterProvider);
  final channels = ref.read(channelsRepoProvider);
  center.show(
    result,
    title: title ?? preview.title,
    undo: result.undoToken == null ? null : () => channels.undo(result.undoToken!, reason: 'تراجع: ${decision.reason}'),
  );
  return result;
}

/// Single-item operation described by its RPC spec.
Future<OpResult?> confirmAndRun(
  BuildContext context,
  WidgetRef ref, {
  required Tr title,
  required RpcSpec spec,
  required Future<OpResult> Function(String reason) run,
  int affected = 1,
  Tr unit = const Tr('عنصر', 'item'),
  List<PreviewGroup> groups = const [],
  Tr confirmLabel = const Tr('نفّذ', 'Run'),
}) => previewAndRun(
  context,
  ref,
  OperationPreview(
    title: title,
    confirmLabel: confirmLabel,
    affected: affected,
    unit: unit,
    groups: groups,
    undoClass: spec.undoClass,
    typedConfirm: spec.undoClass == UndoClass.irreversible && spec.needsRecentMfa,
    needsRecentMfa: spec.needsRecentMfa,
  ),
  run,
);

/// Current filter params from the URL (minus [ignore]).
Map<String, String> routeParams(BuildContext context, {Set<String> ignore = const {'tab'}}) {
  final p = GoRouterState.of(context).uri.queryParameters;
  return {
    for (final e in p.entries)
      if (!ignore.contains(e.key) && e.value.isNotEmpty) e.key: e.value,
  };
}

/// Writes filter params back to the URL (keeps the page shareable).
void setRouteParams(BuildContext context, Map<String, String> params, {Map<String, String> keep = const {}}) {
  final path = GoRouterState.of(context).uri.path;
  final q = {
    ...keep,
    for (final e in params.entries)
      if (e.value.isNotEmpty) e.key: e.value,
  };
  context.go(Uri(path: path, queryParameters: q.isEmpty ? null : q).toString());
}

PageRequest requestFrom(Map<String, String> params) => PageRequest(
  query: params['q'] ?? '',
  filters: {
    for (final e in params.entries)
      if (e.key != 'q') e.key: e.value,
  },
);

/// Column of a GenericRow table.
@immutable
class RowColumn {
  final String key;
  final Tr label;
  final int flex;
  final bool tone;
  const RowColumn(this.key, this.label, {this.flex = 1, this.tone = false});
}

/// Template: a records table (GenericRow) with filters, selection and bulk actions.
class RecordsTablePage extends ConsumerStatefulWidget {
  final NavPage page;
  final PagedDataSource<GenericRow> Function(WidgetRef ref) source;
  final List<RowColumn> columns;
  final List<FilterDef> filters;
  final List<SavedView> views;
  final bool selectable;
  final List<Widget> Function(BuildContext context, WidgetRef ref, SelectionModel sel, PageRequest req)? bulkActions;
  final List<Widget> actions;
  final Widget? header;
  final List<String>? help;
  const RecordsTablePage({
    super.key,
    required this.page,
    required this.source,
    required this.columns,
    this.filters = const [],
    this.views = const [],
    this.selectable = false,
    this.bulkActions,
    this.actions = const [],
    this.header,
    this.help,
  });

  @override
  ConsumerState<RecordsTablePage> createState() => _RecordsTablePageState();
}

class _RecordsTablePageState extends ConsumerState<RecordsTablePage> {
  final _sel = SelectionModel();
  final _table = TableController();

  @override
  void dispose() {
    _sel.dispose();
    _table.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final params = routeParams(context);
    final req = requestFrom(params);
    final c = context.colors;
    return ServicePage(
      page: widget.page,
      help: widget.help,
      actions: widget.actions,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.header != null) ...[widget.header!, const SizedBox(height: Space.md)],
          FilterBar(pageId: widget.page.id, params: params, filters: widget.filters, builtInViews: widget.views, onChanged: (p) => setRouteParams(context, p)),
          const SizedBox(height: Space.md),
          Expanded(
            child: MtcDataTable<GenericRow>(
              source: widget.source(ref),
              query: req.query,
              filters: req.filters,
              selection: widget.selectable ? _sel : null,
              controller: _table,
              columns: [
                for (final col in widget.columns)
                  TableColumn<GenericRow>(
                    label: col.label,
                    flex: col.flex,
                    sortKey: col.key,
                    cell: (context, r) => col.tone
                        ? Pill(r[col.key], tone: r.tone)
                        : Text(
                            r[col.key],
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: c.text),
                          ),
                  ),
              ],
            ),
          ),
          if (widget.selectable)
            SelectionBar(model: _sel, shownIds: () => _table.shownIds, actions: widget.bulkActions?.call(context, ref, _sel, req) ?? const []),
        ],
      ),
    );
  }
}

/// Field of a settings form.
@immutable
class SettingField {
  final String key;
  final Tr label;
  final Tr? help;
  final SettingKind kind;
  final List<FilterOption> options;
  const SettingField(this.key, this.label, {this.kind = SettingKind.text, this.help, this.options = const []});
}

enum SettingKind { text, number, toggle, choice, multiline }

/// Template: a settings form that loads a group, validates, and saves through one admin_* call.
class SettingsFormPage extends ConsumerStatefulWidget {
  final NavPage page;
  final String group;
  final List<SettingField> fields;
  final RpcSpec spec;
  final Widget? extra;
  const SettingsFormPage({super.key, required this.page, required this.group, required this.fields, required this.spec, this.extra});

  @override
  ConsumerState<SettingsFormPage> createState() => _SettingsFormPageState();
}

class _SettingsFormPageState extends ConsumerState<SettingsFormPage> {
  Map<String, Object?>? _values;
  final Map<String, Object?> _edited = {};
  UiError? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final v = await ref.read(experienceRepoProvider).settings(widget.group);
      if (mounted) setState(() => _values = v);
    } catch (e, st) {
      if (mounted) setState(() => _error = describeError(e, st));
    }
  }

  Object? _v(String k) => _edited.containsKey(k) ? _edited[k] : _values?[k];

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_error != null) {
      body = ErrorState(error: _error!, onRetry: _load);
    } else if (_values == null) {
      body = const SizedBox(height: 200, child: LoadingState());
    } else {
      body = Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final f in widget.fields) FieldRow(label: f.label, help: f.help, field: _field(f)),
            const SizedBox(height: Space.lg),
            Row(
              children: [
                FilledButton.icon(
                  key: const ValueKey('settings-save'),
                  onPressed: _edited.isEmpty
                      ? null
                      : () => confirmAndRun(
                          context,
                          ref,
                          title: Tr('حفظ ${widget.page.title.ar}', 'Save ${widget.page.title.en}'),
                          spec: widget.spec,
                          affected: _edited.length,
                          unit: const Tr('إعداد', 'settings'),
                          groups: [
                            for (final e in _edited.entries) PreviewGroup(Tr(e.key, e.key), 1, examples: ['${_values?[e.key]} → ${e.value}']),
                          ],
                          run: (reason) => ref.read(experienceRepoProvider).saveSettings(widget.group, Map.of(_edited), reason: reason),
                        ),
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: Text(context.tr(const Tr('حفظ', 'Save'))),
                ),
                const SizedBox(width: Space.sm),
                if (_edited.isNotEmpty)
                  TextButton(onPressed: () => setState(_edited.clear), child: Text(context.tr(const Tr('تجاهل التعديلات', 'Discard changes')))),
              ],
            ),
          ],
        ),
      );
    }
    return ServicePage(
      page: widget.page,
      scroll: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          body,
          if (widget.extra != null) ...[const SizedBox(height: Space.lg), widget.extra!],
        ],
      ),
    );
  }

  Widget _field(SettingField f) {
    void set(Object? v) => setState(() => v == _values?[f.key] ? _edited.remove(f.key) : _edited[f.key] = v);
    final v = _v(f.key);
    switch (f.kind) {
      case SettingKind.toggle:
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: Switch(value: v == true, onChanged: set),
        );
      case SettingKind.choice:
        return DropdownButtonFormField<String>(
          initialValue: '$v',
          items: [for (final o in f.options) DropdownMenuItem(value: o.value, child: Text(context.tr(o.label)))],
          onChanged: set,
        );
      case SettingKind.number:
      case SettingKind.text:
      case SettingKind.multiline:
        return TextFormField(
          key: ValueKey('setting-${f.key}'),
          initialValue: v?.toString() ?? '',
          maxLines: f.kind == SettingKind.multiline ? 3 : 1,
          keyboardType: f.kind == SettingKind.number ? TextInputType.number : null,
          validator: (s) => f.kind == SettingKind.number && int.tryParse(s ?? '') == null ? context.tr(const Tr('رقم فقط', 'Numbers only')) : null,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: (s) {
            if (f.kind == SettingKind.number) {
              final n = int.tryParse(s);
              if (n != null) set(n);
            } else {
              set(s);
            }
          },
        );
    }
  }
}

/// Placeholder wrapper while a future loads, with the shared states.
class AsyncView<T> extends StatefulWidget {
  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, VoidCallback reload) builder;
  const AsyncView({super.key, required this.load, required this.builder});
  @override
  State<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends State<AsyncView<T>> {
  late Future<T> _f = widget.load();
  void _reload() => setState(() => _f = widget.load());
  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: _f,
    builder: (context, s) {
      if (s.hasError) return ErrorState(error: describeError(s.error!, s.stackTrace), onRetry: _reload);
      if (!s.hasData) return const SizedBox(height: 160, child: LoadingState());
      return widget.builder(context, s.data as T, _reload);
    },
  );
}

void unawaitedRun(Future<void> f) => unawaited(f);
