// بطاقة القناة وشبكة القنوات (V-02/V-03/V-05/V-08): الشعار، الاسم، الرقم، الجودة.
// قابلة للتركيز بلوحة المفاتيح والريموت بإطار واضح (§6.5).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/storage/catalog_db.dart';
import '../../../data/catalog/catalog_repository.dart';

class ChannelLogo extends StatelessWidget {
  final ChannelRow ch;
  final double size;
  const ChannelLogo({super.key, required this.ch, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final name = ch.displayName(Localizations.localeOf(context));
    final initials = name.trim().split(RegExp(r'\s+')).take(2).map((w) => w.isEmpty ? '' : w.characters.first).join().toUpperCase();
    final fallback = Center(child: Text(initials, style: TextStyle(color: c.textMuted, fontWeight: FontWeight.w700, fontSize: size * 0.3)));
    return SizedBox(
      width: size,
      height: size,
      child: ch.logoUrl == null
          ? fallback
          : Image.network(
              ch.logoUrl!,
              fit: BoxFit.contain,
              cacheWidth: (size * 2).round(),
              errorBuilder: (_, _, _) => fallback,
              loadingBuilder: (_, child, p) => p == null ? child : fallback,
            ),
    );
  }
}

class ChannelCard extends StatefulWidget {
  final ChannelRow ch;
  final double width;
  const ChannelCard({super.key, required this.ch, this.width = 156});
  @override
  State<ChannelCard> createState() => _ChannelCardState();
}

class _ChannelCardState extends State<ChannelCard> {
  bool focused = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ch = widget.ch;
    final name = ch.displayName(Localizations.localeOf(context));
    return SizedBox(
      width: widget.width,
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          side: BorderSide(color: focused ? c.accent : c.line, width: focused ? 2 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/watch/${ch.id}'),
          onFocusChange: (f) => setState(() => focused = f),
          child: Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Stack(clipBehavior: Clip.none, children: [
                Container(
                  height: 72,
                  width: double.infinity,
                  decoration: BoxDecoration(color: c.bg2, borderRadius: BorderRadius.circular(Radii.sm)),
                  child: Center(child: ChannelLogo(ch: ch, size: 60)),
                ),
                if (ch.number != null)
                  PositionedDirectional(
                    top: 4,
                    start: 4,
                    child: _Pill(text: '${ch.number}', color: c.textMuted, bg: c.surface2),
                  ),
                if (ch.quality != null)
                  PositionedDirectional(top: 4, end: 4, child: _Pill(text: ch.quality!, color: c.accent, bg: c.accent.withValues(alpha: .14))),
              ]),
              const SizedBox(height: Space.sm),
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.text, fontWeight: FontWeight.w600, fontSize: 13)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color, bg;
  const _Pill({required this.text, required this.color, required this.bg});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Directionality(textDirection: TextDirection.ltr, child: Text(text, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700))),
      );
}

/// شبكة متجاوبة (عدد الأعمدة حسب العرض)، كسولة للقوائم الطويلة (§22).
class ChannelGrid extends StatelessWidget {
  final List<ChannelRow> channels;
  final EdgeInsetsGeometry padding;
  const ChannelGrid({super.key, required this.channels, this.padding = const EdgeInsets.all(Space.lg)});
  @override
  Widget build(BuildContext context) => GridView.builder(
        padding: padding,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 170, mainAxisExtent: 132, crossAxisSpacing: Space.md, mainAxisSpacing: Space.md),
        itemCount: channels.length,
        itemBuilder: (_, i) => ChannelCard(ch: channels[i], width: double.infinity),
      );
}

/// صف أفقي بعنوان (الرئيسية).
class ChannelRowSection extends StatelessWidget {
  final String title;
  final List<ChannelRow> channels;
  final VoidCallback? onSeeAll;
  const ChannelRowSection({super.key, required this.title, required this.channels, this.onSeeAll});
  @override
  Widget build(BuildContext context) {
    if (channels.isEmpty) return const SizedBox.shrink();
    final c = context.colors, t = L10n.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xl),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.lg),
          child: Row(children: [
            Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.text)),
            const Spacer(),
            if (onSeeAll != null) TextButton(onPressed: onSeeAll, child: Text(t.seeAll)),
          ]),
        ),
        const SizedBox(height: Space.sm),
        SizedBox(
          height: 136,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Space.lg),
            itemCount: channels.length,
            separatorBuilder: (_, _) => const SizedBox(width: Space.md),
            itemBuilder: (_, i) => ChannelCard(ch: channels[i]),
          ),
        ),
      ]),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? hint;
  const EmptyState({super.key, required this.icon, required this.title, this.hint});
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 48, color: c.textDim),
          const SizedBox(height: Space.md),
          Text(title, textAlign: TextAlign.center, style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w600)),
          if (hint != null) ...[const SizedBox(height: Space.xs), Text(hint!, textAlign: TextAlign.center, style: TextStyle(color: c.textMuted))],
        ]),
      ),
    );
  }
}
