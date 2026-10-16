// V-11 حول: الإصدار، MTC-Group، المطوّر، التحقق من التحديثات، سياسة الخصوصية.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme/tokens.dart';
import '../../core/config/env.dart';
import '../../core/text/bidi.dart';
import '../../data/settings/remote_config.dart';
import '../../data/updates/app_updater.dart';
import '../../data/updates/update_check.dart';
import 'widgets/social_links.dart';

class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});
  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
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
    // G1/G2: نصوص الهوية والحسابات من الإعدادات المركزية، مع النصوص المدمجة احتياطًا
    final rc = ref.watch(remoteConfigProvider).value ?? RemoteConfig.empty;
    final lang = Localizations.localeOf(context).languageCode;
    String? b(String k) => rc.brandText(k, lang);
    final about = b('about'), terms = b('terms');
    final site = '${rc.brand['website'] ?? ''}'.trim(), email = '${rc.brand['email'] ?? ''}'.trim();
    final social = [for (final s in rc.social) if (s['about'] != false) ('${s['platform']}', '${s['handle'] ?? ''}', s['label'] as String?)];
    return ListView(padding: const EdgeInsets.all(Space.xl), children: [
      Center(child: SvgPicture.asset('assets/brand/mtc-iptv-icon.svg', width: 80, height: 80)),
      const SizedBox(height: Space.md),
      Center(child: Text(b('app_name') ?? t.appTitle, style: TextStyle(color: c.text, fontSize: 24, fontWeight: FontWeight.w800))),
      Center(child: Text(t.version(ltr(Env.version)), style: TextStyle(color: c.textMuted))),
      if (about != null)
        Padding(
          padding: const EdgeInsets.only(top: Space.md),
          child: Text(about, textAlign: TextAlign.center, style: TextStyle(color: c.text, height: 1.6)),
        ),
      const SizedBox(height: Space.lg),
      Center(child: Text(b('company') ?? t.company, textAlign: TextAlign.center, style: TextStyle(color: c.text))),
      Center(child: Text(b('credits') ?? t.developedBy, style: TextStyle(color: c.textMuted))),
      if (site.isNotEmpty || email.isNotEmpty)
        Center(
          child: Wrap(spacing: Space.sm, children: [
            if (site.isNotEmpty)
              TextButton(
                onPressed: () => launchUrl(Uri.parse(site.startsWith('http') ? site : 'https://$site'), mode: LaunchMode.externalApplication),
                child: Text(site, textDirection: TextDirection.ltr),
              ),
            if (email.isNotEmpty)
              TextButton(onPressed: () => launchUrl(Uri(scheme: 'mailto', path: email)), child: Text(email, textDirection: TextDirection.ltr)),
          ]),
        ),
      if (social.isNotEmpty) ...[
        const SizedBox(height: Space.lg),
        Center(child: Text(t.followUs, style: TextStyle(color: c.textMuted, fontWeight: FontWeight.w600))),
        const SizedBox(height: Space.sm),
        SocialLinks(links: social),
      ],
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
              // Windows: التنزيل والتحقق من التوقيع والتثبيت داخل البرنامج (WinSparkle)؛ غيره: صفحة الإصدار
              onPressed: () => AppUpdater.checkNow(fallbackUrl: update!.pageUrl, context: context, known: update),
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
          children: [Text(b('privacy') ?? t.privacyText, style: TextStyle(color: c.text, height: 1.6))],
        ),
      ),
      if (terms != null) ...[
        const SizedBox(height: Space.sm),
        Material(
          color: c.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md), side: BorderSide(color: c.line)),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            leading: const Icon(Icons.gavel_rounded),
            title: Text(t.termsOfUse),
            childrenPadding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.lg),
            children: [Text(terms, style: TextStyle(color: c.text, height: 1.6))],
          ),
        ),
      ],
    ]);
  }
}
