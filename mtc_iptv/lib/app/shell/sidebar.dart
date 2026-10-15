// القائمة الجانبية (§6.6): مجمّعة حسب الأقسام، قابلة للطي (Ctrl+B)، وكل عنصر قابل للتركيز بالمفاتيح.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/settings/local_settings.dart';
import '../../data/auth/admin_auth.dart';
import '../l10n/app_localizations.dart';
import '../../data/settings/remote_config.dart';
import '../screens.dart';
import '../theme/tokens.dart';

/// قسم الإدارة يظهر فقط لجلسة مدير كاملة (admin_users + MFA). تجربة استخدام فقط:
/// الخادم يرفض أي عملية إدارية لغير ذلك (is_admin()).
final isAdminProvider = Provider<bool>((ref) => ref.watch(adminStateProvider).value?.isAdmin ?? false);

class Sidebar extends ConsumerWidget {
  final String location;

  /// التابلت: أيقونات فقط دائمًا (§6.5).
  final bool forceCollapsed;

  /// الجوال: داخل Drawer بعرض كامل، بلا زر طي، ويُغلق عند الاختيار.
  final bool inDrawer;
  const Sidebar({super.key, required this.location, this.forceCollapsed = false, this.inDrawer = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors, t = L10n.of(context);
    final collapsed = !inDrawer && (forceCollapsed || ref.watch(settingsProvider.select((s) => s.sidebarCollapsed)));
    final isAdmin = ref.watch(isAdminProvider);
    final current = screenForPath(location);

    final items = <Widget>[];
    ScreenGroup? lastGroup;
    // G5: الدليل يمكن إيقافه مركزيًا (يبقى للمدير)
    final rc = ref.watch(remoteConfigProvider).value;
    bool enabled(ScreenDef s) => isAdmin || s.id != 'V-07' || (rc?.feature('guide') ?? true);
    for (final s in screens.where((s) => s.inSidebar && (isAdmin || !s.group.isAdmin) && enabled(s))) {
      if (s.group != lastGroup) {
        if (s.group == ScreenGroup.a) items.add(_SectionDivider(label: t.groupAdmin, collapsed: collapsed, strong: true));
        items.add(_SectionDivider(label: s.group.title(t), collapsed: collapsed));
        lastGroup = s.group;
      }
      items.add(_NavItem(def: s, selected: current?.id == s.id, collapsed: collapsed, closeDrawer: inDrawer));
    }
    if (!isAdmin) {
      items.add(_SectionDivider(label: t.groupAdmin, collapsed: collapsed, strong: true));
      items.add(_NavItem(def: adminLoginScreen, selected: location == adminLoginScreen.path, collapsed: collapsed, closeDrawer: inDrawer));
    }

    return AnimatedContainer(
      duration: Motion.normal,
      curve: Curves.easeOutCubic,
      width: inDrawer ? null : (collapsed ? 68 : 248),
      decoration: BoxDecoration(color: c.bg2, border: BorderDirectional(end: BorderSide(color: c.line))),
      child: Column(children: [
        _Header(collapsed: collapsed),
        Expanded(
          child: FocusTraversalGroup(
            child: ListView(padding: const EdgeInsets.symmetric(vertical: Space.sm), children: items),
          ),
        ),
        if (!inDrawer && !forceCollapsed) ...[
          Divider(height: 1, color: c.line),
          _CollapseButton(collapsed: collapsed, label: collapsed ? t.expand : t.collapse),
        ],
      ]),
    );
  }
}

class _Header extends StatelessWidget {
  final bool collapsed;
  const _Header({required this.collapsed});
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 64,
      child: Center(
        child: collapsed
            ? SvgPicture.asset('assets/brand/mtc-iptv-icon.svg', width: 32, height: 32)
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                child: Row(children: [
                  SvgPicture.asset('assets/brand/mtc-iptv-icon.svg', width: 32, height: 32),
                  const SizedBox(width: Space.md),
                  ShaderMask(
                    shaderCallback: (r) => c.brandGradient.createShader(r),
                    child: const Text('MTC-iPTv', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ]),
              ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final String label;
  final bool collapsed, strong;
  const _SectionDivider({required this.label, required this.collapsed, this.strong = false});
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (collapsed) {
      return Padding(padding: const EdgeInsets.symmetric(vertical: Space.sm, horizontal: Space.lg), child: Divider(color: strong ? c.line2 : c.line));
    }
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(Space.lg + 4, strong ? Space.lg : Space.md, Space.lg, Space.xs),
      child: Text(
        label,
        style: TextStyle(
          fontSize: strong ? 12 : 11,
          fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
          color: strong ? c.accent : c.textDim,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final ScreenDef def;
  final bool selected, collapsed, closeDrawer;
  const _NavItem({required this.def, required this.selected, required this.collapsed, this.closeDrawer = false});
  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool focused = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors, t = L10n.of(context);
    final def = widget.def, selected = widget.selected, collapsed = widget.collapsed;
    final title = def.title(t);
    final fg = selected || focused ? c.text : c.textMuted;
    final tile = Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 1),
      child: Material(
        color: selected ? c.accent.withValues(alpha: 0.14) : Colors.transparent,
        // إطار تركيز واضح: أساس التنقل بلوحة المفاتيح والريموت (§6.5)
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          side: focused ? BorderSide(color: c.accent, width: 2) : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.sm),
          onFocusChange: (f) => setState(() => focused = f),
          onTap: () {
            if (widget.closeDrawer) Navigator.of(context).maybePop();
            context.go(def.path);
          },
          child: SizedBox(
            height: 38,
            child: Row(children: [
              // شريط الإشارة للعنصر المحدد على حافة البداية
              AnimatedContainer(
                duration: Motion.fast,
                width: 3,
                height: selected ? 20 : 0,
                decoration: BoxDecoration(gradient: c.brandGradient, borderRadius: BorderRadius.circular(2)),
              ),
              SizedBox(width: collapsed ? 0 : Space.sm),
              Expanded(
                child: collapsed
                    ? Icon(def.icon, size: 20, color: selected ? c.accent : fg)
                    : Row(children: [
                        Icon(def.icon, size: 19, color: selected ? c.accent : fg),
                        const SizedBox(width: Space.md),
                        Expanded(
                          child: Text(title,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13.5, color: fg, fontWeight: selected ? FontWeight.w600 : FontWeight.w500)),
                        ),
                      ]),
              ),
            ]),
          ),
        ),
      ),
    );
    return collapsed ? Tooltip(message: title, preferBelow: false, child: tile) : tile;
  }
}

class _CollapseButton extends ConsumerWidget {
  final bool collapsed;
  final String label;
  const _CollapseButton({required this.collapsed, required this.label});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final icon = Directionality.of(context) == TextDirection.rtl
        ? (collapsed ? Icons.chevron_left_rounded : Icons.chevron_right_rounded)
        : (collapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded);
    return Tooltip(
      message: '$label (Ctrl+B)',
      child: InkWell(
        onTap: () => ref.read(settingsProvider.notifier).toggleSidebar(),
        child: SizedBox(
          height: 44,
          child: Row(mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start, children: [
            if (!collapsed) const SizedBox(width: Space.lg + 4),
            Icon(icon, color: c.textMuted, size: 20),
            if (!collapsed) ...[
              const SizedBox(width: Space.sm),
              Expanded(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.textMuted, fontSize: 12.5))),
            ],
          ]),
        ),
      ),
    );
  }
}
