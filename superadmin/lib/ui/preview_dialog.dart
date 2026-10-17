// Preview before any bulk / risky operation (plan §4 rule 5): what will happen, grouped, who is NOT
// affected and why, the undo class (§9.4), and a mandatory reason (recorded in the audit log).
import 'package:flutter/material.dart';

import '../app/theme/tokens.dart';
import '../core/tr.dart';
import '../data/rpc/admin_rpc.dart';
import 'help.dart';
import 'states.dart';

extension UndoClassText on UndoClass {
  Tr get label => switch (this) {
    UndoClass.full => const Tr('تراجع كامل', 'Full undo'),
    UndoClass.snapshot => const Tr('استعادة من لقطة', 'Snapshot restore'),
    UndoClass.compensating => const Tr('إجراء تعويضي', 'Compensating action'),
    UndoClass.irreversible => const Tr('غير قابلة للعكس', 'Irreversible'),
  };

  Tr get explanation => switch (this) {
    UndoClass.full => const Tr(
      'الخادم بيحفظ القيمة السابقة لكل صف، و«تراجع» بيرجّعها.',
      'The server keeps the previous value of every row; "Undo" restores it.',
    ),
    UndoClass.snapshot => const Tr(
      'بتنأخذ لقطة للصفوف المتأثرة قبل التنفيذ، والاستعادة بتمر بفحص التعارض.',
      'A snapshot of the affected rows is taken first; restoring goes through conflict checks.',
    ),
    UndoClass.compensating => const Tr(
      'ما في رجوع بالزمن: في عملية عكسية واضحة بتنسجّل كعملية جديدة.',
      'No time travel: a clear inverse operation is recorded as a new operation.',
    ),
    UndoClass.irreversible => const Tr('هالعملية ما إلها تراجع. تأكد قبل التنفيذ.', 'This operation cannot be undone. Make sure before running it.'),
  };

  Tone get tone => switch (this) {
    UndoClass.full => Tone.ok,
    UndoClass.snapshot => Tone.info,
    UndoClass.compensating => Tone.warn,
    UndoClass.irreversible => Tone.bad,
  };

  IconData get icon => switch (this) {
    UndoClass.full => Icons.undo,
    UndoClass.snapshot => Icons.photo_camera_back_outlined,
    UndoClass.compensating => Icons.swap_horiz,
    UndoClass.irreversible => Icons.block,
  };
}

class UndoClassBadge extends StatelessWidget {
  final UndoClass undoClass;
  const UndoClassBadge(this.undoClass, {super.key});
  @override
  Widget build(BuildContext context) => Tooltip(
    message: context.tr(undoClass.explanation),
    child: Pill(context.tr(undoClass.label), tone: undoClass.tone, icon: undoClass.icon, key: ValueKey('undo-class-${undoClass.name}')),
  );
}

@immutable
class PreviewGroup {
  final Tr label;
  final int count;
  final Tone tone;
  final List<String> examples;
  const PreviewGroup(this.label, this.count, {this.tone = Tone.neutral, this.examples = const []});
}

@immutable
class PreviewExclusion {
  final String item;
  final Tr reason;
  const PreviewExclusion(this.item, this.reason);
}

@immutable
class OperationPreview {
  final Tr title;
  final Tr confirmLabel;

  /// Total items the operation will touch.
  final int affected;
  final Tr unit;
  final List<PreviewGroup> groups;
  final List<PreviewExclusion> excluded;
  final UndoClass undoClass;

  /// Danger ops (plan §9.1/§9.4): the user types [affected] to confirm.
  final bool typedConfirm;
  final bool needsRecentMfa;
  const OperationPreview({
    required this.title,
    required this.confirmLabel,
    required this.affected,
    this.unit = const Tr('عنصر', 'items'),
    this.groups = const [],
    this.excluded = const [],
    required this.undoClass,
    this.typedConfirm = false,
    this.needsRecentMfa = false,
  });
}

@immutable
class PreviewDecision {
  final String reason;
  const PreviewDecision(this.reason);
}

Future<PreviewDecision?> showPreviewDialog(BuildContext context, OperationPreview preview) => showDialog<PreviewDecision>(
  context: context,
  builder: (_) => PreviewDialog(preview: preview),
);

class PreviewDialog extends StatefulWidget {
  final OperationPreview preview;
  const PreviewDialog({super.key, required this.preview});
  @override
  State<PreviewDialog> createState() => _PreviewDialogState();
}

class _PreviewDialogState extends State<PreviewDialog> {
  final _reason = TextEditingController();
  final _typed = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reason.addListener(() => setState(() {}));
    _typed.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _reason.dispose();
    _typed.dispose();
    super.dispose();
  }

  OperationPreview get p => widget.preview;
  bool get _reasonOk => _reason.text.trim().length >= 3;
  bool get _typedOk => !p.typedConfirm || _typed.text.trim() == '${p.affected}';
  bool get _canRun => _reasonOk && _typedOk && p.affected > 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final irreversible = p.undoClass == UndoClass.irreversible;
    return AlertDialog(
      key: const ValueKey('preview-dialog'),
      title: Row(
        children: [
          Expanded(child: Text(context.tr(p.title))),
          const HelpButton(ids: ['undo-classes'], tooltip: Tr('أصناف التراجع', 'Undo classes')),
        ],
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr(Tr('رح يتأثر ${fmtInt(p.affected)} ${p.unit.ar}', '${fmtInt(p.affected)} ${p.unit.en} will be affected')),
                key: const ValueKey('preview-affected'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: Space.md),
              for (final g in p.groups) _GroupRow(g),
              if (p.excluded.isNotEmpty) ...[
                const SizedBox(height: Space.md),
                Text(
                  context.tr(Tr('ما رح يتأثر (${fmtInt(p.excluded.length)}):', 'Not affected (${fmtInt(p.excluded.length)}):')),
                  style: TextStyle(color: c.textMuted, fontWeight: FontWeight.w600),
                ),
                for (final e in p.excluded.take(8))
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('• ${e.item} — ${context.tr(e.reason)}', style: TextStyle(color: c.textMuted)),
                  ),
              ],
              const SizedBox(height: Space.lg),
              Container(
                padding: const EdgeInsets.all(Space.md),
                decoration: BoxDecoration(
                  color: c.tone(p.undoClass.tone).withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(Radii.sm),
                  border: Border.all(color: c.tone(p.undoClass.tone).withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UndoClassBadge(p.undoClass),
                    const SizedBox(width: Space.md),
                    Expanded(child: Text(context.tr(p.undoClass.explanation), key: const ValueKey('undo-explanation'))),
                  ],
                ),
              ),
              if (p.needsRecentMfa) ...[
                const SizedBox(height: Space.sm),
                Text(
                  context.tr(
                    const Tr(
                      'عملية حساسة: الخادم بيطلب تحقق بخطوتين خلال آخر 15 دقيقة.',
                      'Sensitive operation: the server requires a TOTP verification within the last 15 minutes.',
                    ),
                  ),
                  style: TextStyle(color: c.warn, fontSize: 12.5),
                ),
              ],
              const SizedBox(height: Space.lg),
              TextField(
                key: const ValueKey('preview-reason'),
                controller: _reason,
                decoration: InputDecoration(
                  labelText: context.tr(const Tr('السبب (بينسجّل بسجل التغييرات)', 'Reason (recorded in the audit log)')),
                  helperText: _reasonOk ? null : context.tr(const Tr('مطلوب، 3 أحرف على الأقل', 'Required, at least 3 characters')),
                ),
                maxLines: 2,
                minLines: 1,
              ),
              if (p.typedConfirm) ...[
                const SizedBox(height: Space.md),
                TextField(
                  key: const ValueKey('preview-typed'),
                  controller: _typed,
                  decoration: InputDecoration(labelText: context.tr(Tr('للتأكيد اكتب العدد: ${p.affected}', 'To confirm, type the number: ${p.affected}'))),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr(const Tr('إلغاء', 'Cancel')))),
        FilledButton(
          key: const ValueKey('preview-run'),
          style: irreversible ? FilledButton.styleFrom(backgroundColor: c.bad) : null,
          onPressed: _canRun ? () => Navigator.pop(context, PreviewDecision(_reason.text.trim())) : null,
          child: Text(context.tr(p.confirmLabel)),
        ),
      ],
    );
  }
}

class _GroupRow extends StatelessWidget {
  final PreviewGroup g;
  const _GroupRow(this.g);
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: c.tone(g.tone), shape: BoxShape.circle),
          ),
          const SizedBox(width: Space.sm),
          Expanded(child: Text(context.tr(g.label))),
          if (g.examples.isNotEmpty)
            Flexible(
              child: Text(
                g.examples.take(3).join('، '),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: c.textDim, fontSize: 12),
              ),
            ),
          const SizedBox(width: Space.md),
          Text(fmtInt(g.count), style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
