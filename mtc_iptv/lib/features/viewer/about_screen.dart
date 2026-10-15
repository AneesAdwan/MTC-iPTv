// V-11 حول: الإصدار، MTC-Group، المطوّر، التحقق من التحديثات، سياسة الخصوصية.
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme/tokens.dart';
import '../../core/config/env.dart';
import '../../core/text/bidi.dart';
import '../../data/updates/update_check.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});
  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  bool checking = false;
  String? result;
  UpdateInfo? update;

  Future<void> _check() async {
    final t = L10n.of(context);
    setState(() {
      checking = true;
      result = null;
      update = null;
    });
    try {
      final u = await checkForUpdate(Env.version);
      if (!mounted) return;
      setState(() {
        update = u;
        result = u == null ? t.upToDate : t.updateAvailable(ltr(u.version.toString()));
      });
    } catch (_) {
      if (mounted) setState(() => result = t.updateCheckFailed);
    } finally {
      if (mounted) setState(() => checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context), c = context.colors;
    return ListView(padding: const EdgeInsets.all(Space.xl), children: [
      Center(child: SvgPicture.asset('assets/brand/mtc-iptv-icon.svg', width: 80, height: 80)),
      const SizedBox(height: Space.md),
      Center(child: Text(t.appTitle, style: TextStyle(color: c.text, fontSize: 24, fontWeight: FontWeight.w800))),
      Center(child: Text(t.version(ltr(Env.version)), style: TextStyle(color: c.textMuted))),
      const SizedBox(height: Space.lg),
      Center(child: Text(t.company, textAlign: TextAlign.center, style: TextStyle(color: c.text))),
      Center(child: Text(t.developedBy, style: TextStyle(color: c.textMuted))),
      const SizedBox(height: Space.xl),
      Center(
        child: Wrap(spacing: Space.sm, runSpacing: Space.sm, alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
          FilledButton.tonalIcon(
            onPressed: checking ? null : _check,
            icon: checking ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.system_update_rounded),
            label: Text(t.checkUpdates),
          ),
          if (update != null)
            FilledButton.icon(
              onPressed: () => launchUrl(Uri.parse(update!.pageUrl), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.download_rounded),
              label: Text(t.download),
            ),
        ]),
      ),
      if (result != null) Padding(padding: const EdgeInsets.only(top: Space.sm), child: Center(child: Text(result!, style: TextStyle(color: c.textMuted)))),
      const SizedBox(height: Space.xl),
      Material(
        color: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md), side: BorderSide(color: c.line)),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          leading: const Icon(Icons.privacy_tip_rounded),
          title: Text(t.privacyPolicy),
          childrenPadding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.lg),
          children: [Text(t.privacyText, style: TextStyle(color: c.text, height: 1.6))],
        ),
      ),
    ]);
  }
}
