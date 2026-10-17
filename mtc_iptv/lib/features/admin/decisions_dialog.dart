// قرار لكل قناة (خطة التحسينات 4.3، طلب المالك 2026-10-16): «ألاقي 3 قنوات، 2 يعملن وكل وحدة بتظهر صورة
// والـ3 مش شغالة — أخلي التنتين والـ3 أحذفها». لكل قناة في مجموعة (مكررات أو مقارنة):
//   إبقاء · إبقاء ونشر · إخفاء · دمج روابطها في قناة أخرى من المجموعة · سلة المحذوفات
// مع تعديل مباشر (الاسم، الرقم، الدولة، الفئة، الشعار)، وتجربة البث، و«الباقي ليس مكررًا»،
// ثم ملخص قبل التنفيذ. لا حذف نهائي: السلة 30 يومًا والدمج قابل للتراجع.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/widgets/country_flag.dart';
import '../../app/l10n/app_localizations.dart';
import '../../app/theme/tokens.dart';
import '../../core/text/bidi.dart';
import '../../data/admin/admin_repository.dart';
import 'channels/channels_admin_screen.dart' show adminRefProvider;
import 'channels/stream_preview.dart';
import 'widgets/admin_widgets.dart';

enum Decision { keep, publish, hide, merge, trash }

/// يفتح القرارات لمجموعة قنوات؛ true إن نُفّذ شيء (لتحديث الشاشة المستدعية).
Future<bool> showDecisions(BuildContext context, List<String> ids) async =>
    await showDialog<bool>(context: context, barrierDismissible: false, builder: (_) => _DecisionsDialog(ids: ids)) ?? false;

class _Plan {
  final AdminChannel ch;
  final List<AdminStream> streams;
  Decision d = Decision.keep;
  String? into; // هدف الدمج
  final nameAr = TextEditingController(), nameEn = TextEditingController(), number = TextEditingController(), logo = TextEditingController();
  String? country, category;
  bool editing = false;
  _Plan(this.ch, this.streams) {
    nameAr.text = ch.nameAr ?? '';
    nameEn.text = ch.nameEn ?? '';
    number.text = ch.number?.toString() ?? '';
    logo.text = ch.logoUrl ?? '';
    country = ch.countryCode;
    category = ch.categorySlug;
  }

  int get ok => streams.where((s) => const {'playable', 'reachable', 'degraded'}.contains(s.healthState)).length;

  /// الحقول التي غيّرها المدير فقط.
  Map<String, dynamic> get edits {
    String? v(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    return {
      if (v(nameAr) != ch.nameAr) 'name_ar': v(nameAr),
      if (v(nameEn) != ch.nameEn) 'name_en': v(nameEn),
      if (int.tryParse(number.text.trim()) != ch.number) 'number': int.tryParse(number.text.trim()),
      if (v(logo) != ch.logoUrl) 'logo_url': v(logo),
      if (country != ch.countryCode) 'country_code': country,
      if (category != ch.categorySlug) 'category_slug': category,
    };
  }

  void dispose() {
    for (final c in [nameAr, nameEn, number, logo]) {
      c.dispose();
    }
  }
}

class _DecisionsDialog extends ConsumerStatefulWidget {
  final List<String> ids;
  const _DecisionsDialog({required this.ids});
  @override
  ConsumerState<_DecisionsDialog> createState() => _DecisionsDialogState();
}

class _DecisionsDialogState extends ConsumerState<_DecisionsDialog> {
  List<_Plan>? plans;
  bool distinct = false, busy = false, summary = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final p in plans ?? const <_Plan>[]) {
      p.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final repo = ref.read(adminRepoProvider);
    if (repo == null) return;
    try {
      final chans = await repo.channelsByIds(widget.ids);
      final byId = {for (final c in chans) c.id: c};
      final list = <_Plan>[
        for (final id in widget.ids)
          if (byId[id] != null) _Plan(byId[id]!, await repo.streamsOf(id)),
      ];
      // اقتراح أولي: القناة بلا أي رابط يعمل ← السلة إن وُجدت في المجموعة قناة تعمل
      if (list.any((p) => p.ok > 0)) {
        for (final p in list) {
          if (p.streams.isNotEmpty && p.ok == 0) p.d = Decision.trash;
        }
      }
      if (mounted) setState(() => plans = list);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
  }

  String _name(_Plan p) {
    final lang = Localizations.localeOf(context).languageCode;
    return '${p.ch.number != null ? '${ltr('${p.ch.number}')} · ' : ''}${p.ch.displayName(lang)}';
  }

  /// أسطر الملخص، أو null مع رسالة خطأ إن كان القرار غير صالح.
  List<String> _lines(L10n t) {
    final ps = plans ?? const <_Plan>[];
    final out = <String>[];
    for (final p in ps) {
      if (p.edits.isNotEmpty && p.d != Decision.trash && p.d != Decision.merge) out.add(t.dcLineEdit(_name(p)));
      switch (p.d) {
        case Decision.publish:
          if (p.ch.publishState != 'published') out.add(t.dcLinePublish(_name(p)));
        case Decision.hide:
          out.add(t.dcLineHide(_name(p)));
        case Decision.merge:
          final into = ps.where((x) => x.ch.id == p.into).firstOrNull;
          if (into != null) out.add(t.dcLineMerge(_name(p), _name(into)));
        case Decision.trash:
          out.add(t.dcLineTrash(_name(p)));
        case Decision.keep:
          break;
      }
    }
    final rest = ps.where((p) => p.d == Decision.keep || p.d == Decision.publish || p.d == Decision.hide).length;
    if (distinct && rest > 1) out.add(t.dcLineDistinct(rest));
    return out;
  }

  String? _invalid(L10n t) {
    final ps = plans ?? const <_Plan>[];
    for (final p in ps.where((p) => p.d == Decision.merge)) {
      final target = ps.where((x) => x.ch.id == p.into).firstOrNull;
      if (target == null || target.d == Decision.merge || target.d == Decision.trash || target.d == Decision.hide) return t.dcMergeChain;
    }
    return null;
  }

  Future<void> _apply() async {
    final repo = ref.read(adminRepoProvider);
    final ps = plans;
    if (repo == null || ps == null) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      // 1) التعديلات (قبل الدمج: الهدف قد يأخذ رقمًا أو اسمًا جديدًا)
      for (final p in ps.where((p) => p.d != Decision.trash && p.d != Decision.merge && p.edits.isNotEmpty)) {
        await repo.updateChannel(p.ch.id, p.edits);
      }
      // 2) الدمج: الروابط تنتقل للهدف والقناة تُخفى مع merged_into (قابل للتراجع من صفحة القناة)
      for (final p in ps.where((p) => p.d == Decision.merge && p.into != null)) {
        await repo.mergeChannels(p.into!, [p.ch.id]);
      }
      // 3) السلة
      final trash = [for (final p in ps) if (p.d == Decision.trash) p.ch.id];
      if (trash.isNotEmpty) await repo.trashChannels(trash, reason: 'قرار من المكررات/المقارنة');
      // 4) الإخفاء والنشر
      final hide = [for (final p in ps) if (p.d == Decision.hide) p.ch.id];
      if (hide.isNotEmpty) await repo.updateChannels(hide, {'publish_state': 'hidden', 'hidden_reason': 'manual'});
      final pub = [for (final p in ps) if (p.d == Decision.publish && p.ch.publishState != 'published') p.ch.id];
      if (pub.isNotEmpty) await repo.updateChannels(pub, {'publish_state': 'published'});
      // 5) الباقي ليس مكررًا
      final rest = [for (final p in ps) if (p.d == Decision.keep || p.d == Decision.publish || p.d == Decision.hide) p.ch.id];
      if (distinct && rest.length > 1) await repo.markDistinct(rest);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = '$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context), c = context.colors;
    final ps = plans;
    final size = MediaQuery.sizeOf(context);
    final lines = ps == null ? const <String>[] : _lines(t);
    final invalid = ps == null ? null : _invalid(t);
    return Dialog(
      insetPadding: const EdgeInsets.all(Space.lg),
      child: SizedBox(
        width: (size.width - 48).clamp(320, 1100),
        height: (size.height - 48).clamp(360, 900),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.sm, Space.sm),
            child: Row(children: [
              Icon(Icons.rule_rounded, color: c.accent),
              const SizedBox(width: Space.sm),
              Expanded(child: Text(summary ? t.dcSummary : t.dcTitle, style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w700))),
              IconButton(onPressed: busy ? null : () => Navigator.pop(context, false), icon: const Icon(Icons.close_rounded)),
            ]),
          ),
          if (!summary) Padding(padding: const EdgeInsets.symmetric(horizontal: Space.lg), child: Text(t.dcHint, style: TextStyle(color: c.textMuted))),
          const SizedBox(height: Space.sm),
          Expanded(
            child: ps == null
                ? Center(child: error != null ? Text(error!, style: const TextStyle(color: Color(0xFFEF4444))) : const CircularProgressIndicator())
                : summary
                    ? ListView(padding: const EdgeInsets.all(Space.lg), children: [
                        if (lines.isEmpty) Text(t.dcNothing, style: TextStyle(color: c.textMuted)),
                        for (final l in lines)
                          Padding(
                            padding: const EdgeInsets.only(bottom: Space.sm),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Icon(Icons.chevron_left_rounded, size: 18, color: c.accent),
                              const SizedBox(width: Space.xs),
                              Expanded(child: Text(l, style: TextStyle(color: c.text))),
                            ]),
                          ),
                      ])
                    : ListView(padding: const EdgeInsets.symmetric(horizontal: Space.lg), children: [
                        Wrap(spacing: Space.md, runSpacing: Space.md, children: [for (final p in ps) _card(p, ps)]),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: distinct,
                          onChanged: (v) => setState(() => distinct = v ?? false),
                          title: Text(t.dcDistinct),
                        ),
                      ]),
          ),
          if (error != null && ps != null) Padding(padding: const EdgeInsets.symmetric(horizontal: Space.lg), child: Text(error!, style: const TextStyle(color: Color(0xFFEF4444)))),
          if (invalid != null && !summary) Padding(padding: const EdgeInsets.symmetric(horizontal: Space.lg), child: Text(invalid, style: const TextStyle(color: Color(0xFFEF4444)))),
          Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Row(children: [
              if (busy) const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              const Spacer(),
              if (summary) TextButton(onPressed: busy ? null : () => setState(() => summary = false), child: Text(t.back)),
              TextButton(onPressed: busy ? null : () => Navigator.pop(context, false), child: Text(t.cancel)),
              const SizedBox(width: Space.sm),
              FilledButton.icon(
                onPressed: busy || ps == null || invalid != null || (summary && lines.isEmpty) ? null : (summary ? _apply : () => setState(() => summary = true)),
                icon: Icon(summary ? Icons.check_rounded : Icons.fact_check_rounded),
                label: Text(summary ? t.dcApply : t.dcSummary),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _card(_Plan p, List<_Plan> all) {
    final t = L10n.of(context), c = context.colors;
    final lang = Localizations.localeOf(context).languageCode;
    final refs = ref.watch(adminRefProvider).value;
    String nm(Map m) => '${lang == 'ar' ? m['name_ar'] : m['name_en']}';
    final tone = switch (p.d) {
      Decision.trash => const Color(0xFFEF4444),
      Decision.merge => const Color(0xFFEAB308),
      Decision.hide => c.textMuted,
      Decision.publish => const Color(0xFF22C55E),
      Decision.keep => c.line2,
    };
    final targets = [for (final x in all) if (x != p) x];
    return Container(
      width: 330,
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.md), border: Border.all(color: tone, width: p.d == Decision.keep ? 1 : 2)),
      padding: const EdgeInsets.all(Space.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Container(
            width: 56,
            height: 40,
            decoration: BoxDecoration(color: c.bg2, borderRadius: BorderRadius.circular(Radii.sm)),
            child: p.ch.logoUrl == null ? Icon(Icons.image_not_supported_outlined, color: c.textDim) : Image.network(p.ch.logoUrl!, fit: BoxFit.contain, errorBuilder: (_, _, _) => Icon(Icons.broken_image_rounded, color: c.textDim)),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_name(p), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.text, fontWeight: FontWeight.w700)),
              Text([p.ch.countryCode, p.ch.categorySlug, p.ch.quality].whereType<String>().join(' · '), style: TextStyle(color: c.textMuted, fontSize: 12)),
            ]),
          ),
          StatePill(p.ch.publishState),
        ]),
        const SizedBox(height: Space.sm),
        Row(children: [
          Pill(t.dcStreams(p.ok, p.streams.length), p.ok > 0 ? healthColor('playable') : healthColor('unavailable')),
          const Spacer(),
          TextButton.icon(
            onPressed: p.streams.isEmpty ? null : () => previewChannel(context, ref, p.ch.id, p.ch.displayName(lang)),
            icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
            label: Text(t.aTry),
          ),
        ]),
        const SizedBox(height: Space.xs),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: p.d == Decision.merge ? 'merge:${p.into}' : p.d.name,
          decoration: const InputDecoration(isDense: true),
          items: [
            DropdownMenuItem(value: Decision.keep.name, child: Text(t.dcKeep)),
            DropdownMenuItem(value: Decision.publish.name, child: Text(t.dcPublish)),
            DropdownMenuItem(value: Decision.hide.name, child: Text(t.dcHide)),
            for (final x in targets) DropdownMenuItem(value: 'merge:${x.ch.id}', child: Text(t.dcMergeInto(_name(x)), overflow: TextOverflow.ellipsis)),
            DropdownMenuItem(value: Decision.trash.name, child: Text(t.dcTrash, style: const TextStyle(color: Color(0xFFEF4444)))),
          ],
          onChanged: (v) => setState(() {
            if (v == null) return;
            if (v.startsWith('merge:')) {
              p.d = Decision.merge;
              p.into = v.substring(6);
            } else {
              p.d = Decision.values.byName(v);
              p.into = null;
            }
          }),
        ),
        if (p.d != Decision.trash && p.d != Decision.merge)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => setState(() => p.editing = !p.editing),
              icon: Icon(p.editing ? Icons.expand_less_rounded : Icons.edit_rounded, size: 18),
              label: Text('${t.dcEdit}${p.edits.isEmpty ? '' : ' •'}'),
            ),
          ),
        if (p.editing && p.d != Decision.trash && p.d != Decision.merge) ...[
          TextField(controller: p.nameAr, decoration: InputDecoration(labelText: t.fNameAr, isDense: true), onChanged: (_) => setState(() {})),
          TextField(controller: p.nameEn, decoration: InputDecoration(labelText: t.fNameEn, isDense: true), onChanged: (_) => setState(() {})),
          TextField(
            controller: p.number,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: t.fNumber, isDense: true),
            onChanged: (_) => setState(() {}),
          ),
          DropdownButtonFormField<String?>(
            isExpanded: true,
            initialValue: p.country,
            decoration: InputDecoration(labelText: t.colCountry, isDense: true),
            items: [
              const DropdownMenuItem(value: null, child: Text('—')),
              for (final x in refs?.$1 ?? const <Map<String, dynamic>>[]) DropdownMenuItem(value: x['code'] as String, child: FlagLabel(x['code'] as String, nm(x))),
            ],
            onChanged: (v) => setState(() => p.country = v),
          ),
          DropdownButtonFormField<String?>(
            isExpanded: true,
            initialValue: p.category,
            decoration: InputDecoration(labelText: t.colCategory, isDense: true),
            items: [
              const DropdownMenuItem(value: null, child: Text('—')),
              for (final x in refs?.$2 ?? const <Map<String, dynamic>>[]) DropdownMenuItem(value: x['slug'] as String, child: Text(nm(x))),
            ],
            onChanged: (v) => setState(() => p.category = v),
          ),
          TextField(controller: p.logo, decoration: InputDecoration(labelText: t.fLogoUrl, isDense: true), onChanged: (_) => setState(() {})),
        ],
      ]),
    );
  }
}
