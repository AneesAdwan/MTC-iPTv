// Result of every write: "done n · failed m (details) · undo" (plan §8). One host at the bottom of
// the shell; Ctrl+Z triggers the same undo.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme/tokens.dart';
import '../core/tr.dart';
import '../data/rpc/admin_rpc.dart';
import 'preview_dialog.dart';

class ResultCenter extends ChangeNotifier {
  OpResult? _result;
  Tr? _title;
  Future<OpResult> Function()? _undo;
  bool _undoing = false;

  OpResult? get result => _result;
  Tr? get title => _title;
  bool get undoing => _undoing;
  bool get canUndo => _result != null && _result!.canUndo && _undo != null && !_undoing;

  void show(OpResult result, {Tr? title, Future<OpResult> Function()? undo}) {
    _result = result;
    _title = title;
    _undo = undo;
    notifyListeners();
  }

  void dismiss() {
    _result = null;
    _undo = null;
    notifyListeners();
  }

  /// Runs the undo of the last operation (button or Ctrl+Z). Returns false when there is nothing to undo.
  Future<bool> undoLast() async {
    if (!canUndo) return false;
    _undoing = true;
    notifyListeners();
    try {
      final r = await _undo!();
      _undoing = false;
      show(r, title: const Tr('تراجع', 'Undo'));
    } catch (_) {
      _undoing = false;
      notifyListeners();
    }
    return true;
  }
}

final resultCenterProvider = Provider<ResultCenter>((ref) {
  final c = ResultCenter();
  ref.onDispose(c.dispose);
  return c;
});

class ResultBar extends StatelessWidget {
  final OpResult result;
  final Tr? title;
  final VoidCallback? onUndo;
  final VoidCallback onDismiss;
  final bool undoing;
  const ResultBar({super.key, required this.result, this.title, this.onUndo, required this.onDismiss, this.undoing = false});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tone = result.failed > 0 ? (result.done > 0 ? Tone.warn : Tone.bad) : Tone.ok;
    final col = c.tone(tone);
    return Container(
      key: const ValueKey('result-bar'),
      padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.10),
        border: Border(top: BorderSide(color: col.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          Icon(result.failed > 0 ? Icons.error_outline : Icons.check_circle_outline, color: col, size: 18),
          const SizedBox(width: Space.sm),
          if (title != null) ...[Text(context.tr(title!), style: const TextStyle(fontWeight: FontWeight.w600)), const Text('  ·  ')],
          Text(context.tr(Tr('تمّ ${fmtInt(result.done)}', 'Done ${fmtInt(result.done)}')), key: const ValueKey('result-done')),
          const Text('  ·  '),
          Text(
            context.tr(Tr('فشل ${fmtInt(result.failed)}', 'Failed ${fmtInt(result.failed)}')),
            key: const ValueKey('result-failed'),
            style: TextStyle(color: result.failed > 0 ? c.bad : null),
          ),
          if (result.conflicts > 0) ...[
            const Text('  ·  '),
            Text(context.tr(Tr('تعارض ${fmtInt(result.conflicts)}', 'Conflicts ${fmtInt(result.conflicts)}')), style: TextStyle(color: c.warn)),
          ],
          if (result.failures.isNotEmpty)
            TextButton(key: const ValueKey('result-details'), onPressed: () => _details(context), child: Text(context.tr(const Tr('(التفاصيل)', '(details)')))),
          if (result.stub) ...[
            const SizedBox(width: Space.sm),
            Flexible(
              child: Text(
                context.tr(const Tr('تجريبي: الخادم لسا ما فيه هالدالة، وما تنفّذ شي.', 'Preview build: the server function does not exist yet; nothing ran.')),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: c.textMuted, fontSize: 12.5),
              ),
            ),
          ],
          const Spacer(),
          if (result.canUndo && onUndo != null)
            TextButton.icon(
              key: const ValueKey('result-undo'),
              onPressed: undoing ? null : onUndo,
              icon: const Icon(Icons.undo, size: 18),
              label: Text(context.tr(const Tr('تراجع (Ctrl+Z)', 'Undo (Ctrl+Z)'))),
            )
          else if (!result.canUndo)
            UndoClassBadge(result.undoClass),
          IconButton(onPressed: onDismiss, icon: const Icon(Icons.close, size: 18), tooltip: context.tr(const Tr('إخفاء', 'Dismiss'))),
        ],
      ),
    );
  }

  void _details(BuildContext context) => showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(ctx.tr(Tr('تفاصيل الفشل (${result.failures.length})', 'Failure details (${result.failures.length})'))),
      content: SizedBox(
        width: 560,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              'RPC: ${result.rpc}',
              textDirection: TextDirection.ltr,
              style: TextStyle(color: ctx.colors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: Space.sm),
            for (final f in result.failures)
              ListTile(dense: true, title: Text(f.item == '*' ? ctx.tr(const Tr('كل العناصر', 'All items')) : f.item), subtitle: SelectableText(f.reason)),
          ],
        ),
      ),
      actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.tr(const Tr('إغلاق', 'Close'))))],
    ),
  );
}

/// Placed once in the shell.
class ResultBarHost extends ConsumerWidget {
  const ResultBarHost({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final center = ref.watch(resultCenterProvider);
    return ListenableBuilder(
      listenable: center,
      builder: (context, _) {
        final r = center.result;
        if (r == null) return const SizedBox.shrink();
        return ResultBar(result: r, title: center.title, undoing: center.undoing, onUndo: center.undoLast, onDismiss: center.dismiss);
      },
    );
  }
}
