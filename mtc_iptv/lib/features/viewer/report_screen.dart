// V-12 الإبلاغ عن مشكلة: السبب، الملاحظة، وتفاصيل تقنية **بموافقة** المستخدم (دون روابط، §20).
// يُكتب في جدول reports (سياسة الإدراج متاحة للزوار بحالة open فقط)، ويظهر للمدير في ADM-D6.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme/tokens.dart';
import '../../core/backend/backend.dart';
import '../../core/config/env.dart';
import '../../core/storage/catalog_db.dart';
import '../../data/catalog/catalog_repository.dart';
import '../../data/settings/remote_config.dart';
import '../../player/playback_controller.dart';
import 'widgets/channel_card.dart';
import 'widgets/social_links.dart';

final _reportChannelProvider = FutureProvider.family<ChannelRow?, String>((ref, id) => ref.watch(catalogRepoProvider).channel(id));

/// ملاحظة البلاغ مع التشخيص (إن وافق المستخدم)، ضمن حد الجدول (500 حرف).
String composeReportNote(String note, {String? diag}) {
  final n = note.trim();
  if (diag == null) return n.length > 500 ? n.substring(0, 500) : n;
  final tail = '\n[$diag]';
  final room = 500 - tail.length;
  return '${n.length > room ? n.substring(0, room) : n}$tail'.trim();
}

/// من شاشة المشاهدة: حوار فوق المشغّل (يستمر البث خلفه).
Future<void> showReportDialog(BuildContext context, String channelId) => showDialog(
      context: context,
      builder: (_) => Dialog(child: SizedBox(width: 560, child: ReportScreen(channelId: channelId, asDialog: true))),
    );

class ReportScreen extends ConsumerStatefulWidget {
  final String? channelId;
  final bool asDialog;
  const ReportScreen({super.key, this.channelId, this.asDialog = false});
  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  String reason = 'not_working';
  bool attach = false; // الموافقة صريحة: غير محدد افتراضيًا
  bool sending = false;
  final note = TextEditingController();

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Future<void> _send(ChannelRow ch) async {
    final t = L10n.of(context);
    final client = ref.read(supabaseProvider);
    final messenger = ScaffoldMessenger.of(context);
    if (client == null) {
      messenger.showSnackBar(SnackBar(content: Text(t.reportFailed)));
      return;
    }
    final play = ref.read(playbackProvider);
    final samePlayback = play.channel?.id == ch.id;
    final diag = attach
        ? [
            'v${Env.version}',
            Platform.operatingSystem,
            if (samePlayback) 'server ${play.index + 1}/${play.streams.length}',
            if (samePlayback) 'phase ${play.phase.name}',
            if (samePlayback && play.errorCode != null) 'err ${play.errorCode}',
          ].join(' · ')
        : null;
    setState(() => sending = true);
    try {
      await client.from('reports').insert({
        'channel_id': ch.id,
        if (samePlayback && play.stream != null) 'stream_id': play.stream!.id,
        'reason': reason,
        'note': composeReportNote(note.text, diag: diag),
      });
      messenger.showSnackBar(SnackBar(content: Text(t.reportSent)));
      if (!mounted) return;
      if (widget.asDialog) {
        Navigator.of(context).pop();
      } else {
        context.canPop() ? context.pop() : context.go('/home');
      }
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(t.reportFailed)));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context), c = context.colors;
    final id = widget.channelId;
    final ch = id == null ? null : ref.watch(_reportChannelProvider(id)).value;
    if (ch == null) return EmptyState(icon: Icons.flag_rounded, title: t.reportTitle, hint: t.reportChannelHint);

    final support = (ref.watch(remoteConfigProvider).value ?? RemoteConfig.empty).support;
    final reasons = {'not_working': t.reasonNotWorking, 'wrong_info': t.reasonWrongInfo, 'bad_quality': t.reasonBadQuality, 'other': t.reasonOther};
    return Align(
      alignment: AlignmentDirectional.topStart,
      heightFactor: widget.asDialog ? 1 : null, // في الحوار: بارتفاع المحتوى فقط
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(shrinkWrap: widget.asDialog, padding: const EdgeInsets.all(Space.xl), children: [
          Row(children: [
            ChannelLogo(ch: ch, size: 48),
            const SizedBox(width: Space.md),
            Expanded(child: Text(ch.displayName(Localizations.localeOf(context)), style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: Space.lg),
          Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
            for (final e in reasons.entries) ChoiceChip(label: Text(e.value), selected: reason == e.key, onSelected: (_) => setState(() => reason = e.key)),
          ]),
          const SizedBox(height: Space.lg),
          TextField(controller: note, maxLines: 4, maxLength: 400, decoration: InputDecoration(hintText: t.noteHint)),
          CheckboxListTile(
            value: attach,
            onChanged: (v) => setState(() => attach = v ?? false),
            title: Text(t.attachDiag, style: TextStyle(color: c.text, fontSize: 13.5)),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: Space.md),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton.icon(
              onPressed: sending ? null : () => _send(ch),
              icon: sending ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded),
              label: Text(t.send),
            ),
          ),
          // G2: قنوات الدعم المباشر (واتساب/تيليجرام) إن حدّدها المدير
          if (support.isNotEmpty) ...[
            const Divider(height: Space.xl * 2),
            Text(t.contactSupport, style: TextStyle(color: c.textMuted, fontWeight: FontWeight.w600)),
            const SizedBox(height: Space.sm),
            Align(alignment: AlignmentDirectional.centerStart, child: SocialLinks(links: [for (final e in support.entries) (e.key, e.value, null)])),
          ],
        ]),
      ),
    );
  }
}
