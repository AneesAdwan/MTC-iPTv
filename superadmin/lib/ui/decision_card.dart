// One item that needs a decision (plan §6 section 3): the channel, the problem in one sentence
// ("why it is here"), the evidence, an optional confidence score WITH its reasons, and decision buttons.
import 'package:flutter/material.dart';

import '../app/theme/tokens.dart';
import '../core/tr.dart';
import 'states.dart';

@immutable
class DecisionAction {
  final Tr label;
  final VoidCallback? onPressed;
  final bool primary;
  final bool danger;
  const DecisionAction(this.label, this.onPressed, {this.primary = false, this.danger = false});
}

class DecisionCard extends StatelessWidget {
  final String title;
  final Tr typeLabel;
  final Tone typeTone;
  final Tr why;
  final List<(Tr, String)> evidence;
  final int? confidence;
  final List<Tr> confidenceReasons;
  final List<DecisionAction> actions;
  final bool selected;
  final ValueChanged<bool>? onSelectChanged;

  const DecisionCard({
    super.key,
    required this.title,
    required this.typeLabel,
    required this.why,
    required this.actions,
    this.typeTone = Tone.info,
    this.evidence = const [],
    this.confidence,
    this.confidenceReasons = const [],
    this.selected = false,
    this.onSelectChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: selected ? c.accent.withValues(alpha: 0.06) : c.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: selected ? c.accent.withValues(alpha: 0.5) : c.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onSelectChanged != null) Checkbox(value: selected, onChanged: (v) => onSelectChanged!(v ?? false)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Pill(context.tr(typeLabel), tone: typeTone),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (confidence != null)
                      Tooltip(
                        message: confidenceReasons.map(context.tr).join('\n'),
                        child: Pill(
                          context.tr(Tr('ثقة $confidence%', 'Confidence $confidence%')),
                          tone: confidence! >= 75 ? Tone.ok : (confidence! >= 45 ? Tone.warn : Tone.bad),
                          icon: Icons.insights,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: Space.xs),
                Text(context.tr(why), style: TextStyle(color: c.textMuted)),
                if (evidence.isNotEmpty) ...[
                  const SizedBox(height: Space.sm),
                  Wrap(
                    spacing: Space.lg,
                    runSpacing: 2,
                    children: [
                      for (final (k, v) in evidence)
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${context.tr(k)}: ',
                                style: TextStyle(color: c.textDim, fontSize: 12.5),
                              ),
                              TextSpan(text: v, style: const TextStyle(fontSize: 12.5)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: Space.sm),
                Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.xs,
                  children: [
                    for (final a in actions)
                      if (a.primary)
                        FilledButton(onPressed: a.onPressed, child: Text(context.tr(a.label)))
                      else
                        OutlinedButton(
                          onPressed: a.onPressed,
                          style: a.danger
                              ? OutlinedButton.styleFrom(
                                  foregroundColor: c.bad,
                                  side: BorderSide(color: c.bad.withValues(alpha: 0.5)),
                                )
                              : null,
                          child: Text(context.tr(a.label)),
                        ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
