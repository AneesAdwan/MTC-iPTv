// V-02 الرئيسية (§8.1): «يعرض الآن» ثم صفوف يحددها المدير من ADM-B4 (site_settings.home_layout)،
// وإلا الترتيب الافتراضي: المميزة، تابع المشاهدة، المضافة حديثًا، صفوف الفئات، كل القنوات.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme/tokens.dart';
import '../../core/backend/backend.dart';
import '../../core/storage/catalog_db.dart';
import '../../data/catalog/catalog_repository.dart';
import '../../data/catalog/home_layout.dart';
import '../../data/epg/epg_repository.dart';
import 'channels_screen.dart' show favoritesProvider;
import 'widgets/channel_card.dart';

final featuredProvider = StreamProvider<List<ChannelRow>>((ref) => ref.watch(catalogRepoProvider).watchChannels(const ChannelFilter(featuredOnly: true), limit: 40));
final recentProvider = StreamProvider<List<ChannelRow>>((ref) => ref.watch(catalogRepoProvider).watchRecent(limit: 40));
final historyProvider = StreamProvider<List<ChannelRow>>((ref) => ref.watch(catalogRepoProvider).watchHistory(limit: 40));
final categoriesProvider = StreamProvider<List<CountWith<CategoryRow>>>((ref) => ref.watch(catalogRepoProvider).watchCategories());
final channelsProvider = StreamProvider.family<List<ChannelRow>, ChannelFilter>((ref, f) => ref.watch(catalogRepoProvider).watchChannels(f));
final categoryRowProvider = StreamProvider.family<List<ChannelRow>, String>(
    (ref, slug) => ref.watch(catalogRepoProvider).watchChannels(ChannelFilter(category: slug), limit: 40));
final countryRowProvider = StreamProvider.family<List<ChannelRow>, String>(
    (ref, code) => ref.watch(catalogRepoProvider).watchChannels(ChannelFilter(country: code), limit: 40));
/// المفتاح: المعرّفات مفصولة بفواصل (قائمة القيم لا تصلح مفتاحًا للعائلة).
final idsRowProvider = StreamProvider.family<List<ChannelRow>, String>((ref, key) => ref.watch(catalogRepoProvider).watchByIds(key.isEmpty ? const [] : key.split(',')));

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context);
    final locale = Localizations.localeOf(context);
    final ar = locale.languageCode == 'ar';
    final all = ref.watch(channelsProvider(const ChannelFilter()));
    final syncing = ref.watch(startupSyncProvider).isLoading;
    if ((all.value ?? const []).isEmpty) {
      return EmptyState(
        icon: syncing ? Icons.sync_rounded : Icons.live_tv_rounded,
        title: syncing ? t.syncing : t.catalogEmpty,
        hint: syncing ? null : t.catalogEmptyHint,
      );
    }
    final layout = ref.watch(homeLayoutProvider).value ?? HomeLayout.fallback;
    final now = DateTime.now();
    final cats = (ref.watch(categoriesProvider).value ?? const []).where((c) => c.count > 0).toList();
    final countries = {for (final c in ref.watch(_countriesNamesProvider).value ?? const <CountryRow>[]) c.code: c};

    String? custom(HomeRow r) => ar ? (r.titleAr ?? r.titleEn) : (r.titleEn ?? r.titleAr);
    List<ChannelRow> take(List<ChannelRow>? l, int n) => (l ?? const <ChannelRow>[]).take(n).toList();

    final children = <Widget>[];
    if (layout.hero.isNotEmpty) children.add(_Hero(ids: layout.hero));
    for (final r in layout.rows.where((r) => r.activeAt(now))) {
      switch (r.type) {
        case 'featured':
          children.add(ChannelRowSection(title: custom(r) ?? t.featured, channels: take(ref.watch(featuredProvider).value, r.count)));
        case 'history':
          children.add(ChannelRowSection(title: custom(r) ?? t.continueWatching, channels: take(ref.watch(historyProvider).value, r.count)));
        case 'favorites':
          children.add(ChannelRowSection(title: custom(r) ?? t.sV08, channels: take(ref.watch(favoritesProvider).value, r.count), onSeeAll: () => context.go('/favorites')));
        case 'recent':
          children.add(ChannelRowSection(title: custom(r) ?? t.recentlyAdded, channels: take(ref.watch(recentProvider).value, r.count)));
        case 'categories_auto':
          for (final c in cats.take(r.count)) {
            children.add(ChannelRowSection(
              title: '${c.item.displayName(locale)} · ${c.count}',
              channels: ref.watch(categoryRowProvider(c.item.slug)).value ?? const [],
              onSeeAll: () => context.go('/channels?category=${c.item.slug}'),
            ));
          }
        case 'category' when r.ref != null:
          final cat = cats.where((c) => c.item.slug == r.ref).firstOrNull;
          children.add(ChannelRowSection(
            title: custom(r) ?? cat?.item.displayName(locale) ?? r.ref!,
            channels: take(ref.watch(categoryRowProvider(r.ref!)).value, r.count),
            onSeeAll: () => context.go('/channels?category=${r.ref}'),
          ));
        case 'country' when r.ref != null:
          children.add(ChannelRowSection(
            title: custom(r) ?? countries[r.ref]?.displayName(locale) ?? r.ref!,
            channels: take(ref.watch(countryRowProvider(r.ref!)).value, r.count),
            onSeeAll: () => context.go('/channels?country=${r.ref}'),
          ));
        case 'manual':
          children.add(ChannelRowSection(title: custom(r) ?? '', channels: take(ref.watch(idsRowProvider(r.channelIds.join(','))).value, r.count)));
        case 'all':
          children.add(ChannelRowSection(title: custom(r) ?? t.allChannels, channels: take(all.value, r.count), onSeeAll: () => context.go('/channels')));
      }
    }
    return ListView(padding: const EdgeInsets.symmetric(vertical: 20), children: children);
  }
}

final _countriesNamesProvider = StreamProvider<List<CountryRow>>((ref) {
  final db = ref.watch(catalogDbProvider);
  return db.select(db.countries).watch();
});

/// «يعرض الآن» (ADM-B4): قناة أو أكثر تتناوب كل 8 ثوانٍ، مع البرنامج الحالي وزر «شاهد».
class _Hero extends ConsumerStatefulWidget {
  final List<String> ids;
  const _Hero({required this.ids});
  @override
  ConsumerState<_Hero> createState() => _HeroState();
}

class _HeroState extends ConsumerState<_Hero> {
  int i = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 8), (_) => mounted ? setState(() => i++) : null);
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chans = ref.watch(idsRowProvider(widget.ids.join(','))).value ?? const <ChannelRow>[];
    if (chans.isEmpty) return const SizedBox.shrink();
    final ch = chans[i % chans.length];
    final t = L10n.of(context), c = context.colors;
    final nn = ref.watch(nowNextProvider(ch.uid)).value;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.xl),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: Container(
          key: ValueKey(ch.id),
          height: 170,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.lg),
            gradient: LinearGradient(colors: [c.accent.withValues(alpha: .28), c.surface], begin: AlignmentDirectional.centerStart, end: AlignmentDirectional.centerEnd),
            border: Border.all(color: c.line),
          ),
          padding: const EdgeInsets.all(Space.xl),
          child: Row(children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(color: c.bg2, borderRadius: BorderRadius.circular(Radii.md)),
              child: Center(child: ChannelLogo(ch: ch, size: 96)),
            ),
            const SizedBox(width: Space.xl),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(t.nowLabel, style: TextStyle(color: c.accent, fontWeight: FontWeight.w700, fontSize: 12.5)),
                Text(ch.displayName(Localizations.localeOf(context)), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.text, fontSize: 24, fontWeight: FontWeight.w800)),
                if (nn?.now != null) Text(nn!.now!.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.textMuted)),
                const SizedBox(height: Space.md),
                FilledButton.icon(onPressed: () => context.push('/watch/${ch.id}'), icon: const Icon(Icons.play_arrow_rounded), label: Text(t.watchNow)),
              ]),
            ),
            if (chans.length > 1)
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var k = 0; k < chans.length; k++)
                  Container(
                    margin: const EdgeInsets.all(3),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: k == i % chans.length ? c.accent : c.line),
                  ),
              ]),
          ]),
        ),
      ),
    );
  }
}
