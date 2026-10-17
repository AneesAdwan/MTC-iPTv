// ⓘ on every screen opens the explanation of the service (plan §4 rule 3). The text is the plan's
// section 6, one Arabic Markdown file per service in assets/help/ar/ (2.1 → 2-1.md).
import 'package:flutter/material.dart';

import '../app/theme/tokens.dart';
import '../core/tr.dart';

String helpAsset(String id) => 'assets/help/ar/${id.replaceAll('.', '-')}.md';

class HelpButton extends StatelessWidget {
  final List<String> ids;
  final Tr tooltip;
  const HelpButton({super.key, required this.ids, this.tooltip = const Tr('شرح هالخدمة', 'What this service does')});

  @override
  Widget build(BuildContext context) => IconButton(
    key: const ValueKey('help-button'),
    tooltip: context.tr(tooltip),
    icon: const Icon(Icons.info_outline),
    onPressed: () => showHelp(context, ids),
  );
}

Future<void> showHelp(BuildContext context, List<String> ids) => showDialog<void>(
  context: context,
  builder: (ctx) => Dialog(
    key: const ValueKey('help-dialog'),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.xl, Space.lg, Space.md, 0),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: ctx.colors.accent),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(ctx.tr(const Tr('شرح الخدمة', 'About this service')), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
              ],
            ),
          ),
          if (ctx.lang == Lang.en)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.xl),
              child: Text('The explanations are in Arabic for now.', style: TextStyle(color: ctx.colors.textMuted, fontSize: 12.5)),
            ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Space.xl),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, id) in ids.indexed) ...[
                      if (i > 0)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: Space.lg),
                          child: Divider(),
                        ),
                      HelpView(id: id),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);

class HelpView extends StatelessWidget {
  final String id;
  const HelpView({super.key, required this.id});

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: DefaultAssetBundle.of(context).loadString(helpAsset(id)),
    builder: (context, snap) {
      if (snap.hasError) return Text(context.tr(const Tr('الشرح غير متوفر.', 'Help not available.')));
      if (!snap.hasData) return const LinearProgressIndicator();
      return MiniMarkdown(snap.data!);
    },
  );
}

/// Just enough Markdown for the help files: headings, bullets (nested), numbered lists, quotes,
/// tables, **bold** and `code`.
class MiniMarkdown extends StatelessWidget {
  final String source;
  const MiniMarkdown(this.source, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final out = <Widget>[];
    final lines = source.replaceAll('\r', '').split('\n');
    var i = 0;
    while (i < lines.length) {
      final raw = lines[i];
      final line = raw.trimRight();
      final t = line.trimLeft();
      if (t.isEmpty) {
        out.add(const SizedBox(height: Space.sm));
      } else if (t.startsWith('|')) {
        final rows = <List<String>>[];
        while (i < lines.length && lines[i].trim().startsWith('|')) {
          final cells = lines[i].trim().split('|');
          final row = cells.sublist(1, cells.length - 1).map((s) => s.trim()).toList();
          if (!row.every((s) => RegExp(r'^:?-{2,}:?$').hasMatch(s))) rows.add(row);
          i++;
        }
        out.add(_table(context, rows));
        continue;
      } else if (t.startsWith('#')) {
        final level = t.indexOf(' ');
        final text = t.substring(level + 1);
        out.add(
          Padding(
            padding: const EdgeInsets.only(top: Space.sm, bottom: Space.xs),
            child: Text.rich(
              _inline(text, c),
              style: TextStyle(fontSize: level <= 1 ? 20 : 16, fontWeight: FontWeight.w700),
            ),
          ),
        );
      } else if (t.startsWith('> ')) {
        out.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: Space.xs),
            padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm),
            decoration: BoxDecoration(
              border: BorderDirectional(start: BorderSide(color: c.accent, width: 3)),
              color: c.surface2,
            ),
            child: Text.rich(_inline(t.substring(2), c), style: TextStyle(color: c.textMuted)),
          ),
        );
      } else {
        final bullet = RegExp(r'^(\s*)(- |\d+\. )(.*)$').firstMatch(line);
        if (bullet != null) {
          final depth = bullet.group(1)!.length ~/ 2;
          final marker = bullet.group(2)!.trim();
          out.add(
            Padding(
              padding: EdgeInsetsDirectional.only(start: 8.0 + depth * 18, top: 2, bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(marker == '-' ? (depth == 0 ? '•' : '◦') : marker, style: TextStyle(color: c.accent)),
                  ),
                  Expanded(child: Text.rich(_inline(bullet.group(3)!, c), style: const TextStyle(height: 1.5))),
                ],
              ),
            ),
          );
        } else {
          out.add(Text.rich(_inline(t, c), style: const TextStyle(height: 1.6)));
        }
      }
      i++;
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: out);
  }

  Widget _table(BuildContext context, List<List<String>> rows) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final c = context.colors;
    final cols = rows.map((r) => r.length).reduce((a, b) => a > b ? a : b);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.sm),
      child: Table(
        border: TableBorder.all(color: c.line2, borderRadius: BorderRadius.circular(Radii.sm)),
        defaultVerticalAlignment: TableCellVerticalAlignment.top,
        children: [
          for (final (ri, r) in rows.indexed)
            TableRow(
              decoration: ri == 0 ? BoxDecoration(color: c.surface2) : null,
              children: [
                for (var ci = 0; ci < cols; ci++)
                  Padding(
                    padding: const EdgeInsets.all(Space.sm),
                    child: Text.rich(
                      _inline(ci < r.length ? r[ci] : '', c),
                      style: TextStyle(fontSize: 13, fontWeight: ri == 0 ? FontWeight.w700 : FontWeight.w400),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  static TextSpan _inline(String s, MtcColors c) {
    final spans = <InlineSpan>[];
    final re = RegExp(r'\*\*(.+?)\*\*|`([^`]+)`');
    var last = 0;
    for (final m in re.allMatches(s)) {
      if (m.start > last) spans.add(TextSpan(text: s.substring(last, m.start)));
      if (m.group(1) != null) {
        spans.add(
          TextSpan(
            text: m.group(1),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: m.group(2),
            style: TextStyle(fontFamily: 'monospace', backgroundColor: c.surface2, fontSize: 12.5),
          ),
        );
      }
      last = m.end;
    }
    if (last < s.length) spans.add(TextSpan(text: s.substring(last)));
    return TextSpan(children: spans);
  }
}
