// The one table of the program: server-side paging through PagedDataSource, sortable headers,
// selection (row / shown / all matching), keyboard (Space select · Enter open · Del trash), and the
// shared loading / empty / error states.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme/tokens.dart';
import '../core/errors.dart';
import '../core/tr.dart';
import '../data/paging.dart';
import 'selection.dart';
import 'states.dart';

@immutable
class TableColumn<T> {
  final Tr label;
  final int flex;
  final double? width;
  final String? sortKey;
  final bool numeric;
  final Widget Function(BuildContext context, T row) cell;
  const TableColumn({required this.label, required this.cell, this.flex = 1, this.width, this.sortKey, this.numeric = false});
}

/// Lets a page reload its table after a write.
class TableController extends ChangeNotifier {
  List<String> _shownIds = const [];
  List<String> get shownIds => _shownIds;
  void reload() => notifyListeners();
}

class MtcDataTable<T> extends StatefulWidget {
  final PagedDataSource<T> source;
  final List<TableColumn<T>> columns;
  final String query;
  final Map<String, String> filters;
  final SelectionModel? selection;
  final TableController? controller;
  final ValueChanged<T>? onOpen;

  /// Del key on a row (usually "move to trash" through a preview).
  final ValueChanged<T>? onDelete;
  final int pageSize;
  final Tr emptyTitle;
  final Tr? emptyMessage;
  final double rowHeight;

  const MtcDataTable({
    super.key,
    required this.source,
    required this.columns,
    this.query = '',
    this.filters = const {},
    this.selection,
    this.controller,
    this.onOpen,
    this.onDelete,
    this.pageSize = 50,
    this.emptyTitle = const Tr('ما في نتائج', 'No results'),
    this.emptyMessage,
    this.rowHeight = 44,
  });

  @override
  State<MtcDataTable<T>> createState() => _MtcDataTableState<T>();
}

class _MtcDataTableState<T> extends State<MtcDataTable<T>> {
  late PageRequest _req = PageRequest(limit: widget.pageSize, query: widget.query, filters: widget.filters);
  PageResult<T>? _page;
  UiError? _error;
  bool _loading = false;
  int _token = 0;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_load);
    _load();
  }

  @override
  void didUpdateWidget(MtcDataTable<T> old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?.removeListener(_load);
      widget.controller?.addListener(_load);
    }
    final next = _req.copyWith(query: widget.query, filters: widget.filters);
    if (!next.sameFilter(_req) || old.source != widget.source) {
      _req = next.copyWith(offset: 0);
      widget.selection?.clear(); // a selection belongs to one filter
      _load();
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final token = ++_token;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.source.fetch(_req);
      if (!mounted || token != _token) return;
      setState(() {
        _page = page;
        _loading = false;
      });
      widget.selection?.setTotal(page.total);
      widget.controller?._shownIds = [for (final r in page.items) widget.source.idOf(r)];
    } catch (e, st) {
      if (!mounted || token != _token) return;
      setState(() {
        _error = describeError(e, st);
        _loading = false;
      });
    }
  }

  void _go(int offset) {
    _req = _req.copyWith(offset: offset);
    _load();
  }

  void _sort(String key) {
    final desc = _req.sort == key ? !_req.descending : false;
    _req = _req.copyWith(sort: key, descending: desc, offset: 0);
    _load();
  }

  List<String> get _shownIds => [for (final r in _page?.items ?? <T>[]) widget.source.idOf(r)];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final sel = widget.selection;
    final header = Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: Space.sm),
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          if (sel != null)
            ListenableBuilder(
              listenable: sel,
              builder: (context, _) => SizedBox(
                width: 40,
                child: Checkbox(
                  key: const ValueKey('table-select-shown'),
                  tristate: true,
                  value: sel.shownState(_shownIds),
                  onChanged: (_) => sel.shownState(_shownIds) == true ? sel.unselectShown(_shownIds) : sel.selectShown(_shownIds),
                ),
              ),
            ),
          for (final col in widget.columns) _cellBox(col, _HeaderCell(col: col, req: _req, onSort: _sort)),
        ],
      ),
    );

    Widget body;
    if (_error != null) {
      body = ErrorState(error: _error!, onRetry: _load);
    } else if (_page == null) {
      body = const LoadingState();
    } else if (_page!.items.isEmpty) {
      body = EmptyState(title: widget.emptyTitle, message: widget.emptyMessage, icon: Icons.search_off);
    } else {
      final items = _page!.items;
      body = ListView.builder(
        itemCount: items.length,
        itemExtent: widget.rowHeight,
        itemBuilder: (context, i) => _Row<T>(
          key: ValueKey('row-${widget.source.idOf(items[i])}'),
          row: items[i],
          id: widget.source.idOf(items[i]),
          columns: widget.columns,
          selection: sel,
          onOpen: widget.onOpen,
          onDelete: widget.onDelete,
          cellBox: _cellBox,
          striped: i.isOdd,
        ),
      );
    }

    final total = _page?.total ?? 0;
    final from = total == 0 ? 0 : _req.offset + 1;
    final to = (_req.offset + (_page?.items.length ?? 0));
    final footer = Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: Space.md),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          if (_loading && _page != null) const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
          const Spacer(),
          Text(
            context.tr(Tr('${fmtInt(from)}–${fmtInt(to)} من ${fmtInt(total)}', '${fmtInt(from)}–${fmtInt(to)} of ${fmtInt(total)}')),
            key: const ValueKey('table-range'),
            style: TextStyle(color: c.textMuted),
          ),
          IconButton(
            key: const ValueKey('table-prev'),
            tooltip: context.tr(const Tr('السابق', 'Previous')),
            onPressed: _req.offset > 0 ? () => _go((_req.offset - _req.limit).clamp(0, total)) : null,
            icon: Icon(context.isRtl ? Icons.chevron_right : Icons.chevron_left),
          ),
          IconButton(
            key: const ValueKey('table-next'),
            tooltip: context.tr(const Tr('التالي', 'Next')),
            onPressed: to < total ? () => _go(_req.offset + _req.limit) : null,
            icon: Icon(context.isRtl ? Icons.chevron_left : Icons.chevron_right),
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          header,
          Expanded(child: body),
          footer,
        ],
      ),
    );
  }

  Widget _cellBox(TableColumn<T> col, Widget child) {
    final aligned = Align(alignment: col.numeric ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart, child: child);
    final padded = Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.sm),
      child: aligned,
    );
    return col.width != null ? SizedBox(width: col.width, child: padded) : Expanded(flex: col.flex, child: padded);
  }
}

class _HeaderCell<T> extends StatelessWidget {
  final TableColumn<T> col;
  final PageRequest req;
  final ValueChanged<String> onSort;
  const _HeaderCell({super.key, required this.col, required this.req, required this.onSort});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Text(
      context.tr(col.label),
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontWeight: FontWeight.w600, color: c.textMuted, fontSize: 12.5),
    );
    if (col.sortKey == null) return text;
    final active = req.sort == col.sortKey;
    return InkWell(
      onTap: () => onSort(col.sortKey!),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: text),
          if (active) Icon(req.descending ? Icons.arrow_downward : Icons.arrow_upward, size: 14, color: c.accent),
        ],
      ),
    );
  }
}

class _Row<T> extends StatefulWidget {
  final T row;
  final String id;
  final List<TableColumn<T>> columns;
  final SelectionModel? selection;
  final ValueChanged<T>? onOpen, onDelete;
  final Widget Function(TableColumn<T>, Widget) cellBox;
  final bool striped;
  const _Row({
    super.key,
    required this.row,
    required this.id,
    required this.columns,
    required this.selection,
    required this.onOpen,
    required this.onDelete,
    required this.cellBox,
    required this.striped,
  });

  @override
  State<_Row<T>> createState() => _RowState<T>();
}

class _RowState<T> extends State<_Row<T>> {
  bool _focused = false;

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.space && widget.selection != null) {
      widget.selection!.toggle(widget.id);
      return KeyEventResult.handled;
    }
    if ((k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) && widget.onOpen != null) {
      widget.onOpen!(widget.row);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.delete && widget.onDelete != null) {
      widget.onDelete!(widget.row);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final sel = widget.selection;
    Widget build(bool selected) => Focus(
      onKeyEvent: _onKey,
      onFocusChange: (f) => setState(() => _focused = f),
      child: InkWell(
        onTap: widget.onOpen == null ? (sel == null ? null : () => sel.toggle(widget.id)) : () => widget.onOpen!(widget.row),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: Space.sm),
          decoration: BoxDecoration(
            color: selected ? c.accent.withValues(alpha: 0.08) : (widget.striped ? c.bg2.withValues(alpha: 0.35) : null),
            border: Border(
              bottom: BorderSide(color: c.line),
              left: _focused ? BorderSide(color: c.accent, width: 2) : BorderSide.none,
              right: _focused ? BorderSide(color: c.accent, width: 2) : BorderSide.none,
            ),
          ),
          child: Row(
            children: [
              if (sel != null)
                SizedBox(
                  width: 40,
                  child: Checkbox(value: selected, onChanged: (v) => sel.setSelected(widget.id, v ?? false)),
                ),
              for (final col in widget.columns) widget.cellBox(col, col.cell(context, widget.row)),
            ],
          ),
        ),
      ),
    );
    if (sel == null) return build(false);
    return ListenableBuilder(listenable: sel, builder: (context, _) => build(sel.isSelected(widget.id)));
  }
}
