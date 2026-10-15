// عناصر مشتركة لمركز الإدارة: شارات الحالة والصحة، بطاقة مؤشر، قسم.
import 'package:flutter/material.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/theme/tokens.dart';

String publishLabel(L10n t, String s) => switch (s) {
      'published' => t.psPublished,
      'pending' => t.psPending,
      'hidden' => t.psHidden,
      'draft' => t.psDraft,
      'rejected' => t.psRejected,
      _ => s,
    };

String healthLabel(L10n t, String s) => switch (s) {
      'playable' => t.hsPlayable,
      'reachable' => t.hsReachable,
      'degraded' => t.hsDegraded,
      'auth_failed' => t.hsAuthFailed,
      'unsupported' => t.hsUnsupported,
      'network_error' => t.hsNetworkError,
      'unavailable' => t.hsUnavailable,
      'geo_restricted' => t.hsGeoRestricted,
      'inconclusive' => t.hsInconclusive,
      'disabled' => t.hsDisabled,
      _ => s,
    };

/// ألوان الحالات (§12.2): أخضر يعمل، أزرق وصول فقط، أصفر متدهور، أحمر فشل، رمادي غير حاسم/معطّل.
Color healthColor(String s) => switch (s) {
      'playable' => const Color(0xFF22C55E),
      'reachable' => const Color(0xFF3B82F6),
      'degraded' => const Color(0xFFEAB308),
      'auth_failed' || 'unsupported' || 'network_error' || 'unavailable' => const Color(0xFFEF4444),
      'geo_restricted' => const Color(0xFFA855F7),
      _ => const Color(0xFF8A8A99),
    };

IconData healthIcon(String s) => switch (s) {
      'playable' => Icons.check_circle_rounded,
      'reachable' => Icons.wifi_tethering_rounded,
      'degraded' => Icons.speed_rounded,
      'auth_failed' => Icons.lock_rounded,
      'unsupported' => Icons.extension_off_rounded,
      'network_error' => Icons.portable_wifi_off_rounded,
      'unavailable' => Icons.cancel_rounded,
      'geo_restricted' => Icons.public_off_rounded,
      'disabled' => Icons.pause_circle_rounded,
      _ => Icons.help_rounded,
    };

Color publishColor(String s) => switch (s) {
      'published' => const Color(0xFF22C55E),
      'pending' => const Color(0xFFEAB308),
      'hidden' => const Color(0xFF8A8A99),
      'rejected' => const Color(0xFFEF4444),
      _ => const Color(0xFF3B82F6),
    };

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const Pill(this.text, this.color, {super.key, this.icon});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: .45))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) Padding(padding: const EdgeInsetsDirectional.only(end: 4), child: Icon(icon, size: 13, color: color)),
          Text(text, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w600)),
        ]),
      );
}

class HealthPill extends StatelessWidget {
  final String state;
  const HealthPill(this.state, {super.key});
  @override
  Widget build(BuildContext context) => Pill(healthLabel(L10n.of(context), state), healthColor(state), icon: healthIcon(state));
}

class StatePill extends StatelessWidget {
  final String state;
  const StatePill(this.state, {super.key});
  @override
  Widget build(BuildContext context) => Pill(publishLabel(L10n.of(context), state), publishColor(state));
}

class StatCard extends StatelessWidget {
  final String label, value;
  final String? hint;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;
  const StatCard({super.key, required this.label, required this.value, required this.icon, this.hint, this.color, this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final col = color ?? c.accent;
    return SizedBox(
      width: 210,
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md), side: BorderSide(color: c.line)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(icon, size: 18, color: col),
                const SizedBox(width: Space.sm),
                Expanded(child: Text(label, style: TextStyle(color: c.textMuted, fontSize: 12.5))),
              ]),
              const SizedBox(height: Space.sm),
              Directionality(textDirection: TextDirection.ltr, child: Text(value, style: TextStyle(color: c.text, fontSize: 26, fontWeight: FontWeight.w800))),
              if (hint != null) Text(hint!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.textMuted, fontSize: 11.5)),
            ]),
          ),
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const SectionCard({super.key, required this.title, required this.child, this.trailing});
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md), side: BorderSide(color: c.line)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text(title, style: TextStyle(color: c.text, fontWeight: FontWeight.w700))),
            ?trailing,
          ]),
          const SizedBox(height: Space.sm),
          child,
        ]),
      ),
    );
  }
}

String shortTime(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
}

void toast(BuildContext context, String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

Future<bool> confirm(BuildContext context, String message) async {
  final t = L10n.of(context);
  return await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(t.cancel)),
            FilledButton(onPressed: () => Navigator.pop(c, true), style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)), child: Text(t.aDelete)),
          ],
        ),
      ) ??
      false;
}
