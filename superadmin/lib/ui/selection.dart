// Selection across server-paged tables (plan §6 2.1 / §8): row, "shown", "all matching", invert, clear,
// with an honest "n of total" counter.
//
// Model: either an explicit set of ids, or "all rows matching the filter EXCEPT a set of ids". That
// makes "all matching" work without downloading every id, and makes invert a constant-time flip.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme/tokens.dart';
import '../core/tr.dart';

/// What a bulk operation sends to the server.
@immutable
class SelectionSnapshot {
  final bool allMatching;

  /// Selected ids (explicit mode) or excluded ids (all-matching mode).
  final Set<String> ids;
  final int count;
  const SelectionSnapshot({required this.allMatching, required this.ids, required this.count});
  factory SelectionSnapshot.one(String id) => SelectionSnapshot(allMatching: false, ids: {id}, count: 1);

  Map<String, Object?> toParams() => allMatching ? {'p_all_matching': true, 'p_excluded_ids': ids.toList()} : {'p_ids': ids.toList()};
}

class SelectionModel extends ChangeNotifier {
  bool _all = false;
  final Set<String> _ids = {};
  int _total = 0;

  bool get allMatching => _all;
  int get total => _total;

  /// Number of selected rows (out of [total] rows matching the filter).
  int get count => _all ? math.max(0, _total - _ids.length) : _ids.length;
  bool get isEmpty => count == 0;
  bool get isNotEmpty => !isEmpty;

  void setTotal(int t) {
    if (t == _total) return;
    _total = t;
    notifyListeners();
  }

  bool isSelected(String id) => _all ? !_ids.contains(id) : _ids.contains(id);

  void toggle(String id) => setSelected(id, !isSelected(id));

  void setSelected(String id, bool selected) {
    if (isSelected(id) == selected) return;
    // explicit: the set holds selected ids; all-matching: the set holds excluded ids.
    if (selected != _all) {
      _ids.add(id);
    } else {
      _ids.remove(id);
    }
    notifyListeners();
  }

  /// Select every row currently shown on screen (adds to the selection).
  void selectShown(Iterable<String> ids) {
    for (final id in ids) {
      _all ? _ids.remove(id) : _ids.add(id);
    }
    notifyListeners();
  }

  /// Unselect every row currently shown.
  void unselectShown(Iterable<String> ids) {
    for (final id in ids) {
      _all ? _ids.add(id) : _ids.remove(id);
    }
    notifyListeners();
  }

  /// Every row matching the current filter on the server, including rows on other pages.
  void selectAllMatching() {
    _all = true;
    _ids.clear();
    notifyListeners();
  }

  /// Selected ↔ not selected, over all matching rows.
  void invert() {
    _all = !_all;
    notifyListeners();
  }

  void clear() {
    if (!_all && _ids.isEmpty) return;
    _all = false;
    _ids.clear();
    notifyListeners();
  }

  /// State of the header checkbox for the rows on screen: true / false / null (some).
  bool? shownState(Iterable<String> shownIds) {
    var any = false, all = true;
    for (final id in shownIds) {
      if (isSelected(id)) {
        any = true;
      } else {
        all = false;
      }
    }
    if (shownIds.isEmpty) return false;
    return all ? true : (any ? null : false);
  }

  SelectionSnapshot snapshot() => SelectionSnapshot(allMatching: _all, ids: {..._ids}, count: count);
}

/// Bar under a table: "Selected 37 of 1,204 · shown · all matching · invert · clear" + actions.
class SelectionBar extends StatelessWidget {
  final SelectionModel model;
  final List<String> Function() shownIds;
  final List<Widget> actions;
  const SelectionBar({super.key, required this.model, required this.shownIds, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final has = model.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm),
          decoration: BoxDecoration(
            color: has ? c.accent.withValues(alpha: 0.08) : c.surface,
            border: Border(top: BorderSide(color: has ? c.accent.withValues(alpha: 0.4) : c.line)),
          ),
          child: Wrap(
            spacing: Space.sm,
            runSpacing: Space.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                context.tr(Tr('محدد ', 'Selected ')) + context.tr(ofTotal(model.count, model.total)),
                key: const ValueKey('selection-count'),
                style: TextStyle(fontWeight: FontWeight.w600, color: has ? c.text : c.textMuted),
              ),
              _Btn(const Tr('المعروض', 'Shown'), () => model.selectShown(shownIds()), key: const ValueKey('sel-shown')),
              _Btn(Tr('كل النتائج (${fmtInt(model.total)})', 'All matching (${fmtInt(model.total)})'), model.selectAllMatching, key: const ValueKey('sel-all')),
              _Btn(const Tr('عكس', 'Invert'), model.invert, key: const ValueKey('sel-invert')),
              if (has) _Btn(const Tr('مسح', 'Clear'), model.clear, key: const ValueKey('sel-clear')),
              if (has && actions.isNotEmpty) ...[SizedBox(height: 20, child: VerticalDivider(color: c.line2)), ...actions],
            ],
          ),
        );
      },
    );
  }
}

class _Btn extends StatelessWidget {
  final Tr label;
  final VoidCallback onTap;
  const _Btn(this.label, this.onTap, {super.key});
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 10)),
    child: Text(context.tr(label)),
  );
}
