// V-02 الرئيسية: المميزة، تابع المشاهدة، المضافة حديثًا، ثم صفوف حسب الفئات (§8.1).
// تخطيط الرئيسية من لوحة الإدارة (ADM-B4) يأتي في R1-الإدارة؛ هذا الترتيب الافتراضي.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/app_localizations.dart';
import '../../core/backend/backend.dart';
import '../../core/storage/catalog_db.dart';
import '../../data/catalog/catalog_repository.dart';
import 'widgets/channel_card.dart';

final featuredProvider = StreamProvider<List<ChannelRow>>((ref) => ref.watch(catalogRepoProvider).watchChannels(const ChannelFilter(featuredOnly: true), limit: 20));
final recentProvider = StreamProvider<List<ChannelRow>>((ref) => ref.watch(catalogRepoProvider).watchRecent());
final historyProvider = StreamProvider<List<ChannelRow>>((ref) => ref.watch(catalogRepoProvider).watchHistory());
final categoriesProvider = StreamProvider<List<CountWith<CategoryRow>>>((ref) => ref.watch(catalogRepoProvider).watchCategories());
final channelsProvider = StreamProvider.family<List<ChannelRow>, ChannelFilter>((ref, f) => ref.watch(catalogRepoProvider).watchChannels(f));
final categoryRowProvider = StreamProvider.family<List<ChannelRow>, String>(
    (ref, slug) => ref.watch(catalogRepoProvider).watchChannels(ChannelFilter(category: slug), limit: 20));

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context);
    final locale = Localizations.localeOf(context);
    final all = ref.watch(channelsProvider(const ChannelFilter()));
    final syncing = ref.watch(startupSyncProvider).isLoading;
    if ((all.value ?? const []).isEmpty) {
      return EmptyState(
        icon: syncing ? Icons.sync_rounded : Icons.live_tv_rounded,
        title: syncing ? t.syncing : t.catalogEmpty,
        hint: syncing ? null : t.catalogEmptyHint,
      );
    }
    final cats = (ref.watch(categoriesProvider).value ?? const []).where((c) => c.count > 0).take(8).toList();
    return ListView(padding: const EdgeInsets.symmetric(vertical: 20), children: [
      ChannelRowSection(title: t.featured, channels: ref.watch(featuredProvider).value ?? const []),
      ChannelRowSection(title: t.continueWatching, channels: ref.watch(historyProvider).value ?? const []),
      ChannelRowSection(title: t.recentlyAdded, channels: ref.watch(recentProvider).value ?? const []),
      for (final c in cats)
        ChannelRowSection(
          title: '${c.item.displayName(locale)} · ${c.count}',
          channels: ref.watch(categoryRowProvider(c.item.slug)).value ?? const [],
          onSeeAll: () => context.go('/channels?category=${c.item.slug}'),
        ),
      ChannelRowSection(
        title: t.allChannels,
        channels: (all.value ?? const []).take(20).toList(),
        onSeeAll: () => context.go('/channels'),
      ),
    ]);
  }
}
