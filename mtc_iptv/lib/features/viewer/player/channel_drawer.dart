// قائمة القنوات داخل المشغّل (خطة التحسينات 2.4، مثل `.yt-chl` في src/player.js): تُفتح من اليسار بزر أو G
// أو بسحب من طرف الشاشة، فيها بحث وتبويبات (الكل، المفضلة، تابع المشاهدة، نفس الفئة، نفس الدولة)،
// والتنقل بين القنوات دون الخروج من ملء الشاشة. الأسهم وEnter للوحة المفاتيح والريموت.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/storage/catalog_db.dart';
import '../../../data/catalog/catalog_repository.dart';
import '../channels_screen.dart' show favoritesProvider;
import '../home_screen.dart' show channelsProvider, historyProvider;
import '../widgets/channel_card.dart' show ChannelLogo;

enum DrawerTab { all, favorites, history, category, country }

class ChannelDrawer extends ConsumerStatefulWidget {
  final ChannelRow? current;
  final void Function(ChannelRow ch) onPick;
  final VoidCallback onClose;
  const ChannelDrawer({super.key, required this.current, required this.onPick, required this.onClose});
  @override
  ConsumerState<ChannelDrawer> createState() => _ChannelDrawerState();
}

class _ChannelDrawerState extends ConsumerState<ChannelDrawer> {
  DrawerTab tab = DrawerTab.all;
  final q = TextEditingController();
  final list = ScrollController();
  final _listFocus = FocusNode();
  int sel = -1; // العنصر المحدد بالأسهم
  static const _rowH = 50.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _listFocus.requestFocus());
  }

  @override
  void dispose() {
    q.dispose();
    list.dispose();
    _listFocus.dispose();
    super.dispose();
  }

  List<ChannelRow> _items() {
    final ch = widget.current;
    final all = switch (tab) {
      DrawerTab.all => ref.watch(channelsProvider(const ChannelFilter())).value,
      DrawerTab.favorites => ref.watch(favoritesProvider).value,
      DrawerTab.history => ref.watch(historyProvider).value,
      DrawerTab.category => ch?.category == null ? const <ChannelRow>[] : ref.watch(channelsProvider(ChannelFilter(category: ch!.category))).value,
      DrawerTab.country => ch?.country == null ? const <ChannelRow>[] : ref.watch(channelsProvider(ChannelFilter(country: ch!.country))).value,
    } ??
        const <ChannelRow>[];
    final s = q.text.trim().toLowerCase();
    if (s.isEmpty) return all;
    final locale = Localizations.localeOf(context);
    return all.where((x) => '${x.number}' == s || x.displayName(locale).toLowerCase().contains(s) || (x.nameAr ?? '').toLowerCase().contains(s) || (x.nameEn ?? '').toLowerCase().contains(s)).toList();
  }

  void _mark(int i, int n) {
    if (n == 0) return;
    setState(() => sel = i.clamp(0, n - 1));
    if (list.hasClients) {
      final target = (sel * _rowH) - list.position.viewportDimension / 2 + _rowH / 2;
      list.animateTo(target.clamp(0, list.position.maxScrollExtent), duration: const Duration(milliseconds: 120), curve: Curves.easeOut);
    }
  }

  KeyEventResult _onKey(List<ChannelRow> items, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    final n = items.length;
    if (k == LogicalKeyboardKey.arrowDown) {
      _mark(sel + 1, n);
    } else if (k == LogicalKeyboardKey.arrowUp) {
      _mark(sel - 1, n);
    } else if (k == LogicalKeyboardKey.pageDown) {
      _mark(sel + 10, n);
    } else if (k == LogicalKeyboardKey.pageUp) {
      _mark(sel - 10, n);
    } else if ((k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter || k == LogicalKeyboardKey.select) && sel >= 0 && sel < n) {
      widget.onPick(items[sel]);
    } else if (k == LogicalKeyboardKey.escape || e.physicalKey == PhysicalKeyboardKey.keyG || k == LogicalKeyboardKey.keyG) { // goBack: عبر رجوع النظام (handleBack في المشغّل)
      widget.onClose();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context), c = context.colors;
    final locale = Localizations.localeOf(context);
    final items = _items();
    final cur = widget.current?.id;
    if (sel < 0 || sel >= items.length) {
      final i = items.indexWhere((x) => x.id == cur);
      sel = i < 0 ? 0 : i;
      WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _mark(sel, items.length) : null);
    }
    final tabs = <(DrawerTab, String)>[
      (DrawerTab.all, t.filterAll),
      (DrawerTab.favorites, t.sV08),
      (DrawerTab.history, t.continueWatching),
      if (widget.current?.category != null) (DrawerTab.category, t.plSameCategory),
      if (widget.current?.country != null) (DrawerTab.country, t.plSameCountry),
    ];

    return LayoutBuilder(builder: (context, box) {
      final w = (box.maxWidth * .86).clamp(0.0, 380.0);
      return Directionality(
        textDirection: Directionality.of(context),
        child: Container(
          width: w,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xF50A0A0E), Color(0xE60E0E14)]),
            border: const Border(right: BorderSide(color: Color(0x14FFFFFF))),
            boxShadow: const [BoxShadow(color: Color(0x8C000000), blurRadius: 60, offset: Offset(20, 0))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
              child: Row(children: [
                Icon(Icons.format_list_bulleted_rounded, color: c.accent2, size: 20),
                const SizedBox(width: 8),
                Text(t.plChannels, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: .1), borderRadius: BorderRadius.circular(999)),
                  child: Text('${items.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                const Spacer(),
                IconButton(tooltip: t.close, onPressed: widget.onClose, icon: const Icon(Icons.close_rounded, color: Colors.white)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: TextField(
                controller: q,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                onChanged: (_) => setState(() => sel = -1),
                onSubmitted: (_) {
                  if (items.isNotEmpty) widget.onPick(items[sel.clamp(0, items.length - 1)]);
                },
                decoration: InputDecoration(
                  isDense: true,
                  hintText: t.searchChannelsHint,
                  hintStyle: const TextStyle(color: Colors.white54, fontSize: 13.5),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 18),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: .07),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: BorderSide(color: Colors.white.withValues(alpha: .08))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: BorderSide(color: Colors.white.withValues(alpha: .08))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: BorderSide(color: c.accent2.withValues(alpha: .6))),
                ),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), children: [
                for (final (k, label) in tabs)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => setState(() {
                        tab = k;
                        q.clear();
                        sel = -1;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: tab == k ? c.brandGradient : null,
                          color: tab == k ? null : Colors.white.withValues(alpha: .07),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(label, style: TextStyle(color: tab == k ? Colors.white : const Color(0xFFCFCFD8), fontSize: 12.5, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
              ]),
            ),
            Expanded(
              child: Focus(
                focusNode: _listFocus,
                onKeyEvent: (_, e) => _onKey(items, e),
                child: items.isEmpty
                    ? Center(child: Text(t.noMatches, style: const TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        controller: list,
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        itemExtent: _rowH,
                        itemCount: items.length,
                        itemBuilder: (_, i) => _Row(
                          ch: items[i],
                          playing: items[i].id == cur,
                          selected: i == sel,
                          name: items[i].displayName(locale),
                          onTap: () => widget.onPick(items[i]),
                        ),
                      ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x0FFFFFFF)))),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Text(t.plChannelsHint, style: const TextStyle(color: Colors.white38, fontSize: 11.5)),
            ),
          ]),
        ),
      );
    });
  }
}

class _Row extends StatelessWidget {
  final ChannelRow ch;
  final bool playing, selected;
  final String name;
  final VoidCallback onTap;
  const _Row({required this.ch, required this.playing, required this.selected, required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final sub = [ch.country, ch.category].whereType<String>().join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              gradient: playing ? LinearGradient(colors: [c.accent.withValues(alpha: .22), c.accent.withValues(alpha: .05)]) : null,
              color: playing ? null : (selected ? Colors.white.withValues(alpha: .1) : null),
              border: selected ? BorderDirectional(start: BorderSide(color: c.accent2, width: 3)) : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(children: [
              SizedBox(
                width: 40,
                child: Text('${ch.number ?? ''}',
                    textAlign: TextAlign.center, style: TextStyle(color: playing ? c.accent2 : Colors.white54, fontSize: 14, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 6),
              Container(
                width: 46,
                height: 32,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .06), borderRadius: BorderRadius.circular(7)),
                child: ChannelLogo(ch: ch, size: 26),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFE8E8EE), fontSize: 13.5, fontWeight: FontWeight.w600)),
                  if (sub.isNotEmpty) Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white38, fontSize: 11.5)),
                ]),
              ),
              if (playing) Icon(Icons.graphic_eq_rounded, color: c.accent2, size: 18),
            ]),
          ),
        ),
      ),
    );
  }
}
