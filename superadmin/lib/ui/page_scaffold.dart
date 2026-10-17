// Frame of every page: breadcrumb "Section › Page", title, ⓘ help, copy-link, page actions.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../app/nav.dart';
import '../app/theme/tokens.dart';
import '../core/tr.dart';
import 'help.dart';
import 'widgets.dart';

class ServicePage extends StatelessWidget {
  final NavPage page;
  final Widget child;
  final List<Widget> actions;

  /// Extra breadcrumb tail (e.g. the channel name on the channel page).
  final String? crumb;
  final List<String>? help;
  final bool stub;
  final bool scroll;
  const ServicePage({
    super.key,
    required this.page,
    required this.child,
    this.actions = const [],
    this.crumb,
    this.help,
    this.stub = true,
    this.scroll = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final section = Nav.sectionFor(page.path.replaceAll(':id', 'x'));
    final location = GoRouterState.of(context).uri.toString();
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(Space.xl, Space.lg, Space.xl, Space.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [context.tr(section.title), if (page.id != section.pages.first.id || crumb != null) context.tr(page.title), ?crumb].join('  ›  '),
                  key: const ValueKey('breadcrumb'),
                  style: TextStyle(color: c.textMuted, fontSize: 12.5),
                ),
                const SizedBox(height: 2),
                Text(
                  crumb ?? context.tr(page.title),
                  key: const ValueKey('page-title'),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          ...actions.expand((a) => [a, const SizedBox(width: Space.sm)]),
          IconButton(
            tooltip: context.tr(const Tr('انسخ رابط هالصفحة', 'Copy link to this page')),
            icon: const Icon(Icons.link, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: 'superadmin:/$location'));
              ScaffoldMessenger.maybeOf(context)
                  ?.showSnackBar(SnackBar(content: Text(context.tr(const Tr('انتسخ الرابط', 'Link copied'))), duration: const Duration(seconds: 2)));
            },
          ),
          HelpButton(ids: help ?? page.help),
        ],
      ),
    );
    final body = Padding(
      padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (stub) ...[const StubNotice(), const SizedBox(height: Space.md)],
          if (scroll) child else Expanded(child: child),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        Expanded(child: scroll ? SingleChildScrollView(child: body) : body),
      ],
    );
  }
}
