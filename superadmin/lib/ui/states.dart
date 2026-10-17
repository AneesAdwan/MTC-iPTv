// Empty / loading / error states with one look everywhere. An error ALWAYS offers "retry" and
// "details" (plan §4 rule 7).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme/tokens.dart';
import '../core/errors.dart';
import '../core/tr.dart';

class LoadingState extends StatelessWidget {
  final Tr? label;
  const LoadingState({super.key, this.label});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5)),
        const SizedBox(height: Space.md),
        Text(context.tr(label ?? const Tr('جاري التحميل…', 'Loading…')), style: TextStyle(color: context.colors.textMuted)),
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final Tr title;
  final Tr? message;
  final Widget? action;
  const EmptyState({super.key, this.icon = Icons.inbox_outlined, required this.title, this.message, this.action});
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: c.textDim),
            const SizedBox(height: Space.md),
            Text(
              context.tr(title),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: Space.xs),
              Text(
                context.tr(message!),
                style: TextStyle(color: c.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[const SizedBox(height: Space.lg), action!],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final UiError error;
  final VoidCallback onRetry;
  final bool compact;
  const ErrorState({super.key, required this.error, required this.onRetry, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final buttons = Wrap(
      spacing: Space.sm,
      alignment: WrapAlignment.center,
      children: [
        FilledButton.icon(
          key: const ValueKey('error-retry'),
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 18),
          label: Text(context.tr(const Tr('أعد المحاولة', 'Retry'))),
        ),
        OutlinedButton(
          key: const ValueKey('error-details'),
          onPressed: () => showErrorDetails(context, error),
          child: Text(context.tr(const Tr('التفاصيل', 'Details'))),
        ),
      ],
    );
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: c.bad, size: 18),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(context.tr(error.message), style: TextStyle(color: c.bad)),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          buttons,
        ],
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: c.bad),
            const SizedBox(height: Space.md),
            Text(
              context.tr(error.message),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: Space.lg),
            buttons,
          ],
        ),
      ),
    );
  }
}

Future<void> showErrorDetails(BuildContext context, UiError error) => showDialog<void>(
  context: context,
  builder: (ctx) => AlertDialog(
    title: Text(ctx.tr(const Tr('تفاصيل الخطأ', 'Error details'))),
    content: SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ctx.tr(error.message)),
            const SizedBox(height: Space.md),
            Directionality(
              textDirection: TextDirection.ltr,
              child: SelectableText(error.details, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Clipboard.setData(ClipboardData(text: error.details)),
        child: Text(ctx.tr(const Tr('نسخ', 'Copy'))),
      ),
      FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.tr(const Tr('إغلاق', 'Close')))),
    ],
  ),
);

/// Small coloured pill (state, undo class, counts…).
class Pill extends StatelessWidget {
  final String text;
  final Tone tone;
  final IconData? icon;
  const Pill(this.text, {super.key, this.tone = Tone.neutral, this.icon});
  @override
  Widget build(BuildContext context) {
    final col = context.colors.tone(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: col.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: col), const SizedBox(width: 4)],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: col, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
