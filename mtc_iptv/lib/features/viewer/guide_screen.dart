// V-07 دليل البرامج: شبكة زمنية (القنوات × الوقت)، القفز لـ«الآن»، والتنقل بالأيام.
// عمود القنوات ثابت والجدول يتمرر أفقيًا وعموديًا معه (متحكّمان متزامنان).
// الضغط على برنامج: التفاصيل + «شاهد» (إن كان يُعرض الآن) أو «ذكّرني» (إن كان قادمًا).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;

import '../../app/l10n/app_localizations.dart';
import '../../app/theme/tokens.dart';
import '../../core/storage/catalog_db.dart';
import '../../core/text/bidi.dart';
import '../../data/catalog/catalog_repository.dart';
import '../../data/epg/epg_repository.dart';
import '../../data/reminders/reminders.dart';
import 'home_screen.dart';
import 'widgets/channel_card.dart';

const _pxPerMin = 4.0;
const _rowH = 64.0;
const _chanW = 180.0;
const _headerH = 32.0;

final _guideDaysProvider = FutureProvider<List<DateTime>>((ref) async {
  ref.watch(epgSyncProvider);
  return ref.watch(epgRepoProvider).days();
});

final _guideDayProvider = StreamProvider.family<List<ProgrammeRow>, DateTime>((ref, day) {
  ref.watch(epgSyncProvider);
  return ref.watch(epgRepoProvider).watchRange(day, DateTime(day.year, day.month, day.day + 1));
});

DateTime _today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

/// HH:mm بأرقام لاتينية في اللغتين (كبقية الأرقام في البرنامج).
String fmtTime(BuildContext context, DateTime t) {
  final l = t.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

/// «من – إلى» مثبّتة من اليسار لليمين (وإلا تنقلب في العربية: 23:00 – 22:00).
String fmtRange(BuildContext context, DateTime a, DateTime b) => ltr('${fmtTime(context, a)} – ${fmtTime(context, b)}');

/// اتجاه نص البيانات من محتواه (أوصاف EPG كثيرًا ما تكون إنجليزية داخل واجهة عربية).
TextDirection textDirOf(String s) => RegExp('[؀-ۿ]').hasMatch(s) ? TextDirection.rtl : TextDirection.ltr;

/// أرقام لاتينية في التواريخ العربية (intl يعطي ١٧ بدل 17).
String latinDigits(String s) => s.replaceAllMapped(RegExp('[٠-٩]'), (m) => '${m[0]!.codeUnitAt(0) - 0x0660}');

class GuideScreen extends ConsumerStatefulWidget {
  const GuideScreen({super.key});
  @override
  ConsumerState<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends ConsumerState<GuideScreen> {
  DateTime day = _today();
  final h = ScrollController();
  final vChan = ScrollController(), vGrid = ScrollController();
  bool _syncing = false;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // تزامن التمرير العمودي بين عمود القنوات والجدول
    void link(ScrollController from, ScrollController to) => from.addListener(() {
          if (_syncing || !to.hasClients) return;
          _syncing = true;
          to.jumpTo(from.offset.clamp(0, to.position.maxScrollExtent));
          _syncing = false;
        });
    link(vChan, vGrid);
    link(vGrid, vChan);
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToNow(animate: false));
    _tick = Timer.periodic(const Duration(minutes: 1), (_) => mounted ? setState(() {}) : null); // خط «الآن»
  }

  @override
  void dispose() {
    _tick?.cancel();
    h.dispose();
    vChan.dispose();
    vGrid.dispose();
    super.dispose();
  }

  void _jumpToNow({bool animate = true}) {
    if (day != _today()) setState(() => day = _today());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!h.hasClients) return;
      final now = DateTime.now();
      final x = ((now.hour * 60 + now.minute) * _pxPerMin - 60 * _pxPerMin).clamp(0.0, h.position.maxScrollExtent);
      animate ? h.animateTo(x, duration: const Duration(milliseconds: 350), curve: Curves.easeOut) : h.jumpTo(x);
    });
  }

  String _dayLabel(L10n t, DateTime d) {
    final diff = d.difference(_today()).inDays;
    if (diff == 0) return t.today;
    if (diff == 1) return t.tomorrow;
    if (diff == -1) return t.yesterday;
    return latinDigits(intl.DateFormat.MMMEd(Localizations.localeOf(context).languageCode).format(d));
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context), c = context.colors;
    final days = ref.watch(_guideDaysProvider).value ?? const <DateTime>[];
    final progs = ref.watch(_guideDayProvider(day)).value ?? const <ProgrammeRow>[];
    final channels = ref.watch(channelsProvider(const ChannelFilter())).value ?? const <ChannelRow>[];

    final byUid = <String, List<ProgrammeRow>>{};
    for (final p in progs) {
      (byUid[p.channelUid] ??= []).add(p);
    }
    final rows = [for (final ch in channels) if (byUid.containsKey(ch.uid)) ch];

    final toolbar = Padding(
      padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg, Space.sm),
      child: Row(children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final d in days)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: Space.sm),
                  child: ChoiceChip(label: Text(_dayLabel(t, d)), selected: d == day, onSelected: (_) => setState(() => day = d)),
                ),
            ]),
          ),
        ),
        FilledButton.tonalIcon(onPressed: _jumpToNow, icon: const Icon(Icons.schedule_rounded, size: 18), label: Text(t.jumpToNow)),
      ]),
    );

    if (rows.isEmpty) {
      return Column(children: [
        toolbar,
        Expanded(child: EmptyState(icon: Icons.view_timeline_rounded, title: t.guideEmpty, hint: t.guideEmptyHint)),
      ]);
    }

    const dayW = 24 * 60 * _pxPerMin;
    final now = DateTime.now();
    final nowX = day == _today() ? (now.hour * 60 + now.minute) * _pxPerMin : null;

    return Column(children: [
      toolbar,
      Expanded(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // عمود القنوات الثابت
          SizedBox(
            width: _chanW,
            child: Column(children: [
              const SizedBox(height: _headerH),
              Expanded(
                child: ListView.builder(
                  controller: vChan,
                  itemExtent: _rowH,
                  itemCount: rows.length,
                  itemBuilder: (_, i) => _ChannelCell(ch: rows[i]),
                ),
              ),
            ]),
          ),
          Expanded(
            child: Scrollbar(
              controller: h,
              child: SingleChildScrollView(
                controller: h,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: dayW,
                  child: Column(children: [
                    SizedBox(height: _headerH, child: _TimeAxis(day: day, nowX: nowX)),
                    Expanded(
                      child: ListView.builder(
                        controller: vGrid,
                        itemExtent: _rowH,
                        itemCount: rows.length,
                        itemBuilder: (_, i) => _ProgrammeRowView(ch: rows[i], day: day, items: byUid[rows[i].uid]!, nowX: nowX),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      ),
      Container(height: 1, color: c.line),
    ]);
  }
}

class _ChannelCell extends StatelessWidget {
  final ChannelRow ch;
  const _ChannelCell({required this.ch});
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: () => context.push('/watch/${ch.id}'),
      child: Container(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line), right: BorderSide(color: c.line), left: BorderSide(color: c.line))),
        padding: const EdgeInsets.symmetric(horizontal: Space.sm),
        child: Row(children: [
          ChannelLogo(ch: ch, size: 40),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(ch.displayName(Localizations.localeOf(context)), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.text, fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }
}

class _TimeAxis extends StatelessWidget {
  final DateTime day;
  final double? nowX;
  const _TimeAxis({required this.day, this.nowX});
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Stack(children: [
      for (var hr = 0; hr < 24; hr++)
        PositionedDirectional(
          start: hr * 60 * _pxPerMin,
          top: 0,
          bottom: 0,
          width: 60 * _pxPerMin,
          child: Container(
            decoration: BoxDecoration(border: BorderDirectional(start: BorderSide(color: c.line))),
            padding: const EdgeInsetsDirectional.only(start: 6),
            alignment: AlignmentDirectional.centerStart,
            child: Text(fmtTime(context, DateTime(day.year, day.month, day.day, hr)), style: TextStyle(color: c.textMuted, fontSize: 12)),
          ),
        ),
      if (nowX != null) PositionedDirectional(start: nowX! - 1, top: 0, bottom: 0, width: 2, child: ColoredBox(color: c.accent)),
    ]);
  }
}

class _ProgrammeRowView extends ConsumerWidget {
  final ChannelRow ch;
  final DateTime day;
  final List<ProgrammeRow> items;
  final double? nowX;
  const _ProgrammeRowView({required this.ch, required this.day, required this.items, this.nowX});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final dayStart = day, dayEnd = DateTime(day.year, day.month, day.day + 1);
    final keys = ref.watch(reminderKeysProvider).value ?? const <String>{};
    final now = DateTime.now();
    double x(DateTime t) {
      final l = t.toLocal();
      final clamped = l.isBefore(dayStart) ? dayStart : (l.isAfter(dayEnd) ? dayEnd : l);
      return clamped.difference(dayStart).inMinutes * _pxPerMin;
    }

    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
      child: Stack(children: [
        for (final p in items)
          PositionedDirectional(
            start: x(p.startAt),
            width: (x(p.endAt) - x(p.startAt)).clamp(2.0, double.infinity),
            top: 4,
            bottom: 4,
            child: _ProgrammeBlock(
              p: p,
              ch: ch,
              live: !now.isBefore(p.startAt) && now.isBefore(p.endAt),
              past: !now.isBefore(p.endAt),
              reminded: keys.contains(ReminderService.key(ch.id, p.startAt)),
            ),
          ),
        if (nowX != null) PositionedDirectional(start: nowX! - 1, top: 0, bottom: 0, width: 2, child: IgnorePointer(child: ColoredBox(color: c.accent))),
      ]),
    );
  }
}

class _ProgrammeBlock extends StatelessWidget {
  final ProgrammeRow p;
  final ChannelRow ch;
  final bool live, past, reminded;
  const _ProgrammeBlock({required this.p, required this.ch, required this.live, required this.past, required this.reminded});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 2),
      child: Material(
        color: live ? c.accent.withValues(alpha: .18) : c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.sm), side: BorderSide(color: live ? c.accent : c.line)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showProgrammeSheet(context, ch, p),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Row(children: [
                if (reminded) Padding(padding: const EdgeInsetsDirectional.only(end: 4), child: Icon(Icons.notifications_active_rounded, size: 13, color: c.accent)),
                Expanded(
                  child: Text(p.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: past ? c.textMuted : c.text, fontSize: 12.5, fontWeight: FontWeight.w600)),
                ),
              ]),
              Text(fmtRange(context, p.startAt, p.endAt), maxLines: 1, overflow: TextOverflow.clip, style: TextStyle(color: c.textMuted, fontSize: 11)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// تفاصيل برنامج: الوصف + «شاهد» أو «ذكّرني».
Future<void> showProgrammeSheet(BuildContext context, ChannelRow ch, ProgrammeRow p) => showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => Consumer(builder: (context, ref, _) {
        final t = L10n.of(context), c = context.colors;
        final now = DateTime.now();
        final live = !now.isBefore(p.startAt) && now.isBefore(p.endAt);
        final future = now.isBefore(p.startAt);
        final reminded = (ref.watch(reminderKeysProvider).value ?? const <String>{}).contains(ReminderService.key(ch.id, p.startAt));
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.title, textDirection: textDirOf(p.title), style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: Space.xs),
              Text('${ch.displayName(Localizations.localeOf(context))} · ${fmtRange(context, p.startAt, p.endAt)}', style: TextStyle(color: c.textMuted)),
              if ((p.description ?? '').isNotEmpty) ...[
                const SizedBox(height: Space.md),
                SizedBox(width: double.infinity, child: Text(p.description!, textDirection: textDirOf(p.description!), style: TextStyle(color: c.text, height: 1.5))),
              ],
              const SizedBox(height: Space.lg),
              Wrap(spacing: Space.sm, children: [
                if (live)
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/watch/${ch.id}');
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(t.watchNow),
                  ),
                if (future)
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      final on = await ref.read(remindersProvider).toggle(ch.id, p.startAt, '${p.title} — ${ch.displayName(Localizations.localeOf(context))}');
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(on ? t.reminderSet : t.reminderRemoved)));
                    },
                    icon: Icon(reminded ? Icons.notifications_off_rounded : Icons.notifications_active_rounded),
                    label: Text(reminded ? t.cancelReminder : t.remindMe),
                  ),
              ]),
            ]),
          ),
        );
      }),
    );
