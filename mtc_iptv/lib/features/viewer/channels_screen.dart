// V-03 القنوات: شبكة بفلاتر الفئة والدولة (من الرابط: /channels?category=news&country=SA).
// V-04 الدول: الأعلام وعدد القنوات. V-05 البحث. V-08 المفضلة.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme/tokens.dart';
import '../../core/storage/catalog_db.dart';
import '../../data/catalog/catalog_repository.dart';
import 'home_screen.dart';
import 'widgets/channel_card.dart';

final countriesProvider = StreamProvider<List<CountWith<CountryRow>>>((ref) => ref.watch(catalogRepoProvider).watchCountries());
final favoritesProvider = StreamProvider<List<ChannelRow>>((ref) => ref.watch(catalogRepoProvider).watchFavorites());

class ChannelsScreen extends ConsumerWidget {
  final String? country, category;
  const ChannelsScreen({super.key, this.country, this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context), c = context.colors;
    final locale = Localizations.localeOf(context);
    final channels = ref.watch(channelsProvider(ChannelFilter(country: country, category: category))).value ?? const <ChannelRow>[];
    final cats = (ref.watch(categoriesProvider).value ?? const []).where((x) => x.count > 0).toList();
    final countries = ref.watch(countriesProvider).value ?? const [];

    String q({String? cat, String? cty}) {
      final p = {'category': ?cat, 'country': ?cty};
      return Uri(path: '/channels', queryParameters: p.isEmpty ? null : p).toString();
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // الفئات: شرائح قابلة للتمرير؛ الدولة: قائمة منسدلة
      SizedBox(
        height: 52,
        child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm), children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: Space.sm),
            child: ChoiceChip(label: Text(t.filterAll), selected: category == null, onSelected: (_) => context.go(q(cty: country))),
          ),
          for (final x in cats)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: Space.sm),
              child: ChoiceChip(
                label: Text('${x.item.displayName(locale)} ${x.count}'),
                selected: category == x.item.slug,
                onSelected: (_) => context.go(q(cat: x.item.slug, cty: country)),
              ),
            ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.lg),
        child: Row(children: [
          Text(t.channelsCount(channels.length), style: TextStyle(color: c.textMuted)),
          const Spacer(),
          DropdownButton<String?>(
            value: country,
            hint: Text(t.country),
            underline: const SizedBox.shrink(),
            items: [
              DropdownMenuItem(value: null, child: Text('${t.country}: ${t.filterAll}')),
              for (final x in countries) DropdownMenuItem(value: x.item.code, child: Text('${x.item.flag ?? ''} ${x.item.displayName(locale)} (${x.count})')),
            ],
            onChanged: (v) => context.go(q(cat: category, cty: v)),
          ),
        ]),
      ),
      Expanded(child: channels.isEmpty ? EmptyState(icon: Icons.tv_off_rounded, title: t.noMatches) : ChannelGrid(channels: channels)),
    ]);
  }
}

class CountriesScreen extends ConsumerWidget {
  const CountriesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors, t = L10n.of(context);
    final locale = Localizations.localeOf(context);
    final list = ref.watch(countriesProvider).value ?? const [];
    if (list.isEmpty) return EmptyState(icon: Icons.public_off_rounded, title: t.catalogEmpty);
    return GridView.builder(
      padding: const EdgeInsets.all(Space.lg),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 200, mainAxisExtent: 112, crossAxisSpacing: Space.md, mainAxisSpacing: Space.md),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final x = list[i];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.go('/channels?country=${x.item.code}'),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(x.item.flag ?? '🏳️', style: const TextStyle(fontSize: 34)),
              const SizedBox(height: Space.xs),
              Text(x.item.displayName(locale), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.text, fontWeight: FontWeight.w600)),
              Text(t.channelsCount(x.count), style: TextStyle(color: c.textMuted, fontSize: 12)),
            ]),
          ),
        );
      },
    );
  }
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final ctrl = TextEditingController();
  String q = '';

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final results = q.trim().isEmpty ? const <ChannelRow>[] : (ref.watch(channelsProvider(ChannelFilter(query: q))).value ?? const <ChannelRow>[]);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: TextField(
          controller: ctrl,
          autofocus: true,
          onChanged: (v) => setState(() => q = v),
          decoration: InputDecoration(hintText: t.searchChannelsHint, prefixIcon: const Icon(Icons.search_rounded)),
        ),
      ),
      Expanded(
        child: q.trim().isEmpty
            ? EmptyState(icon: Icons.manage_search_rounded, title: t.searchChannelsHint)
            : results.isEmpty
                ? EmptyState(icon: Icons.search_off_rounded, title: t.noMatches)
                : ChannelGrid(channels: results, padding: const EdgeInsets.symmetric(horizontal: Space.lg)),
      ),
    ]);
  }
}

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context);
    final list = ref.watch(favoritesProvider).value ?? const <ChannelRow>[];
    return list.isEmpty ? EmptyState(icon: Icons.favorite_border_rounded, title: t.favoritesEmpty, hint: t.favoritesEmptyHint) : ChannelGrid(channels: list);
  }
}
