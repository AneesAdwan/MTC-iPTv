// ADM-B6 الشبكات والشعارات (§9.4): الشبكات (MBC، BBC، beIN…) بعدد قنواتها، فتح قنواتها، وإعادة التسمية.
// (مكتبة الشعارات بالرفع للتخزين وأحجام WebP: مع إعداد التخزين في المرحلة 6؛ فحص الشعارات في ADM-D5.)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme/tokens.dart';
import '../../data/admin/admin_repository.dart';
import '../viewer/widgets/channel_card.dart' show EmptyState;
import 'channels/channels_admin_screen.dart';
import 'widgets/admin_widgets.dart';

final _networksProvider = FutureProvider.autoDispose<List<(String, int, String?)>>((ref) async => await ref.watch(adminRepoProvider)?.networks() ?? const []);

class NetworksScreen extends ConsumerWidget {
  const NetworksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context), c = context.colors;
    final async = ref.watch(_networksProvider);
    final items = async.value ?? const <(String, int, String?)>[];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.lg, 0),
        child: Text(t.logoLibraryLater, style: TextStyle(color: c.textMuted, fontSize: 12)),
      ),
      Expanded(
        child: items.isEmpty
            ? (async.isLoading ? const Center(child: CircularProgressIndicator()) : EmptyState(icon: Icons.hub_rounded, title: t.noMatches))
            : GridView.builder(
                padding: const EdgeInsets.all(Space.lg),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 240, mainAxisExtent: 130, crossAxisSpacing: Space.md, mainAxisSpacing: Space.md),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final (name, n, logo) = items[i];
                  return Material(
                    color: c.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md), side: BorderSide(color: c.line)),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => context.go(Uri(path: '/admin/channels', queryParameters: {'q': name}).toString()),
                      child: Padding(
                        padding: const EdgeInsets.all(Space.md),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            SizedBox(width: 48, height: 36, child: logo == null ? null : Image.network(logo, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox())),
                            const Spacer(),
                            IconButton(
                              tooltip: t.netRename,
                              icon: const Icon(Icons.edit_rounded, size: 18),
                              onPressed: () async {
                                final ctrl = TextEditingController(text: name);
                                final v = await showDialog<String>(
                                  context: context,
                                  builder: (d) => AlertDialog(
                                    title: Text(t.netRename),
                                    content: TextField(controller: ctrl, autofocus: true, decoration: InputDecoration(labelText: t.netNewName)),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(d), child: Text(t.cancel)),
                                      FilledButton(onPressed: () => Navigator.pop(d, ctrl.text), child: Text(t.save)),
                                    ],
                                  ),
                                );
                                if (v == null || v.trim() == name) return;
                                try {
                                  await ref.read(adminRepoProvider)?.renameNetwork(name, v);
                                  if (context.mounted) toast(context, t.saved);
                                } catch (e) {
                                  if (context.mounted) toast(context, t.saveFailed('$e'));
                                }
                                ref.invalidate(_networksProvider);
                                ref.invalidate(adminChannelsProvider);
                              },
                            ),
                          ]),
                          const Spacer(),
                          Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.text, fontWeight: FontWeight.w700, fontSize: 15)),
                          Text(t.netChannels(n), style: TextStyle(color: c.textMuted, fontSize: 12)),
                        ]),
                      ),
                    ),
                  );
                },
              ),
      ),
    ]);
  }
}
