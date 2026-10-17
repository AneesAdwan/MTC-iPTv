// Filter bar with search + filters + saved views (plan §6 2.1). The filter state lives in the route's
// query parameters, so every view is a shareable link (/channels?state=hidden&country=QA, plan §8).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme/tokens.dart';
import '../core/prefs.dart';
import '../core/tr.dart';

@immutable
class FilterOption {
  final String value;
  final Tr label;
  const FilterOption(this.value, this.label);
}

@immutable
class FilterDef {
  final String key;
  final Tr label;
  final List<FilterOption> options;
  const FilterDef(this.key, this.label, this.options);
}

/// Lets the "/" shortcut focus the search box of the page on screen.
class FilterFocusRegistry {
  FocusNode? _node;
  void register(FocusNode n) => _node = n;
  void unregister(FocusNode n) {
    if (_node == n) _node = null;
  }

  bool focus() {
    final n = _node;
    if (n == null || n.context == null) return false;
    n.requestFocus();
    return true;
  }
}

final filterFocusProvider = Provider<FilterFocusRegistry>((ref) => FilterFocusRegistry());

class FilterBar extends ConsumerStatefulWidget {
  final String pageId;
  final List<FilterDef> filters;

  /// Current parameters (filter keys + 'q' for the search text).
  final Map<String, String> params;
  final ValueChanged<Map<String, String>> onChanged;
  final List<SavedView> builtInViews;
  final Tr searchHint;
  const FilterBar({
    super.key,
    required this.pageId,
    required this.params,
    required this.onChanged,
    this.filters = const [],
    this.builtInViews = const [],
    this.searchHint = const Tr('بحث…  ( / )', 'Search…  ( / )'),
  });

  @override
  ConsumerState<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends ConsumerState<FilterBar> {
  late final TextEditingController _q = TextEditingController(text: widget.params['q'] ?? '');
  final _focus = FocusNode(debugLabel: 'filter-search');
  Timer? _debounce;
  late final FilterFocusRegistry _registry = ref.read(filterFocusProvider);

  @override
  void initState() {
    super.initState();
    _registry.register(_focus);
  }

  @override
  void didUpdateWidget(FilterBar old) {
    super.didUpdateWidget(old);
    final q = widget.params['q'] ?? '';
    if (q != _q.text && !_focus.hasFocus) _q.text = q;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _registry.unregister(_focus);
    _focus.dispose();
    _q.dispose();
    super.dispose();
  }

  void _set(String key, String? value) {
    final next = {...widget.params};
    if (value == null || value.isEmpty) {
      next.remove(key);
    } else {
      next[key] = value;
    }
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final prefs = ref.watch(prefsProvider);
    final active = widget.params.entries.where((e) => e.value.isNotEmpty).length;
    return ListenableBuilder(
      listenable: prefs,
      builder: (context, _) {
        final saved = prefs.views(widget.pageId);
        return Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 280,
              child: TextField(
                key: const ValueKey('filter-search'),
                controller: _q,
                focusNode: _focus,
                decoration: InputDecoration(prefixIcon: const Icon(Icons.search, size: 18), hintText: context.tr(widget.searchHint)),
                onChanged: (v) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 300), () => _set('q', v.trim()));
                },
                onSubmitted: (v) {
                  _debounce?.cancel();
                  _set('q', v.trim());
                },
              ),
            ),
            for (final f in widget.filters) _FilterChip(def: f, value: widget.params[f.key], onSelected: (v) => _set(f.key, v)),
            if (active > 0)
              TextButton.icon(
                key: const ValueKey('filter-clear'),
                onPressed: () {
                  _q.clear();
                  widget.onChanged(const {});
                },
                icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                label: Text(context.tr(const Tr('مسح الفلاتر', 'Clear filters'))),
              ),
            PopupMenuButton<Object>(
              key: const ValueKey('saved-views'),
              tooltip: context.tr(const Tr('العروض المحفوظة', 'Saved views')),
              onSelected: (v) async {
                if (v is SavedView) {
                  widget.onChanged(v.params);
                } else if (v == #save) {
                  final name = await _askName(context);
                  if (name != null && name.isNotEmpty) prefs.saveView(widget.pageId, SavedView(name, widget.params));
                } else if (v is String) {
                  prefs.deleteView(widget.pageId, v);
                }
              },
              itemBuilder: (ctx) => [
                for (final v in widget.builtInViews) PopupMenuItem(value: v, child: Text(v.name)),
                if (widget.builtInViews.isNotEmpty && saved.isNotEmpty) const PopupMenuDivider(),
                for (final v in saved)
                  PopupMenuItem(
                    value: v,
                    child: Row(
                      children: [
                        Expanded(child: Text(v.name)),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 16),
                          onPressed: () {
                            Navigator.pop(ctx, v.name);
                          },
                        ),
                      ],
                    ),
                  ),
                const PopupMenuDivider(),
                PopupMenuItem(value: #save, enabled: active > 0, child: Text(ctx.tr(const Tr('احفظ العرض الحالي…', 'Save current view…')))),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  border: Border.all(color: c.line2),
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [const Icon(Icons.bookmarks_outlined, size: 16), const SizedBox(width: 6), Text(context.tr(const Tr('العروض', 'Views')))],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _askName(BuildContext context) {
    final ctl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr(const Tr('اسم العرض', 'View name'))),
        content: TextField(controller: ctl, autofocus: true, onSubmitted: (v) => Navigator.pop(ctx, v.trim())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.tr(const Tr('إلغاء', 'Cancel')))),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctl.text.trim()), child: Text(ctx.tr(const Tr('حفظ', 'Save')))),
        ],
      ),
    ).whenComplete(ctl.dispose);
  }
}

class _FilterChip extends StatelessWidget {
  final FilterDef def;
  final String? value;
  final ValueChanged<String?> onSelected;
  const _FilterChip({required this.def, required this.value, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final selected = def.options.where((o) => o.value == value).firstOrNull;
    final on = selected != null;
    return PopupMenuButton<String>(
      key: ValueKey('filter-${def.key}'),
      tooltip: context.tr(def.label),
      onSelected: (v) => onSelected(v.isEmpty ? null : v),
      itemBuilder: (ctx) => [
        PopupMenuItem(value: '', child: Text(ctx.tr(const Tr('الكل', 'All')))),
        for (final o in def.options) PopupMenuItem(value: o.value, child: Text(ctx.tr(o.label))),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: on ? c.accent.withValues(alpha: 0.10) : null,
          border: Border.all(color: on ? c.accent.withValues(alpha: 0.5) : c.line2),
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Text(on ? '${context.tr(def.label)}: ${context.tr(selected.label)}' : context.tr(def.label)), const Icon(Icons.arrow_drop_down, size: 18)],
        ),
      ),
    );
  }
}
