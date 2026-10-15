// أزرار الحسابات الاجتماعية وقنوات الدعم (G2) — تُعرض في «حول» و«الإبلاغ عن مشكلة».
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/tokens.dart';
import '../../../data/admin/settings_repository.dart' show socialUrl;

const _names = {
  'facebook': 'Facebook',
  'instagram': 'Instagram',
  'linkedin': 'LinkedIn',
  'snapchat': 'Snapchat',
  'threads': 'Threads',
  'x': 'X',
  'tiktok': 'TikTok',
  'pinterest': 'Pinterest',
  'whatsapp': 'WhatsApp',
  'telegram': 'Telegram',
  'youtube': 'YouTube',
};

IconData _icon(String p) => switch (p) {
      'whatsapp' => Icons.chat_rounded,
      'telegram' => Icons.send_rounded,
      'youtube' => Icons.smart_display_rounded,
      'instagram' || 'snapchat' || 'pinterest' => Icons.photo_camera_rounded,
      'linkedin' => Icons.work_rounded,
      'custom' => Icons.link_rounded,
      _ => Icons.public_rounded,
    };

/// (المنصّة، المعرّف، تسمية اختيارية) ← زر يفتح الرابط خارجيًا.
class SocialLinks extends StatelessWidget {
  final List<(String platform, String handle, String? label)> links;
  const SocialLinks({super.key, required this.links});

  @override
  Widget build(BuildContext context) {
    final items = [for (final l in links) if (l.$2.trim().isNotEmpty) l];
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: Space.sm, runSpacing: Space.sm, alignment: WrapAlignment.center, children: [
      for (final (p, h, label) in items)
        OutlinedButton.icon(
          onPressed: () => launchUrl(Uri.parse(socialUrl(p, h)), mode: LaunchMode.externalApplication),
          icon: Icon(_icon(p), size: 18),
          label: Text(label?.trim().isNotEmpty == true ? label!.trim() : (_names[p] ?? h)),
        ),
    ]);
  }
}
