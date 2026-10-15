// الرقابة الأبوية (§8.4): القناة مقفلة إن كانت مخصّصة للكبار أو ضمن فئة مقفلة، والرقابة مفعّلة.
// إدخال الرمز مرة يفتح القناة حتى إغلاق البرنامج.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/local_settings.dart';
import '../../core/storage/catalog_db.dart';
import 'settings_screen.dart' show askPin;

final Set<String> _unlocked = {};

bool isChannelLocked(ChannelRow ch, LocalSettings s) =>
    s.parentalOn && !_unlocked.contains(ch.id) && (ch.parental || (ch.category != null && s.lockedCategories.contains(ch.category)));

/// true إن كانت القناة مفتوحة (أو فُتحت الآن بالرمز الصحيح).
Future<bool> ensureUnlocked(BuildContext context, WidgetRef ref, ChannelRow ch) async {
  if (!isChannelLocked(ch, ref.read(settingsProvider))) return true;
  final ok = await askPin(context, ref);
  if (ok) _unlocked.add(ch.id);
  return ok;
}
