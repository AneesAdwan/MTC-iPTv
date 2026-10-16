// الريموت (§8.2، نمط التلفاز). أسهم الريموت في Flutter تنقل التركيز «من» عنصر مركّز إلى جاره داخل
// نطاق التركيز نفسه. على محاكي Android TV 16 (2026-10-16) ظهرت مشكلتان تُعلِقان مستخدم التلفاز:
//  1. لا شيء مركّز (نافذة حوار فُتحت للتو): السهم لا يفعل شيئًا ← نذهب لأول عنصر.
//  2. الصفحة داخل Navigator الهيكل (نطاق خاص بها) والقائمة الجانبية خارجه: السهم لا يعبر إليها ←
//     إن لم يجد السهم شيئًا في النطاق، نبحث هندسيًا في الشاشة كلها عن أقرب عنصر في الاتجاه نفسه.
//     لا نعبر أبدًا من نافذة منبثقة (حوار) إلى ما خلفها.
import 'package:flutter/widgets.dart';

class DirectionalOrFirstAction extends DirectionalFocusAction {
  @override
  void invoke(DirectionalFocusIntent intent) {
    final f = FocusManager.instance.primaryFocus;
    if (f == null || (f is FocusScopeNode && f.focusedChild == null)) {
      (f ?? FocusManager.instance.rootScope).nextFocus();
      return;
    }
    if (f.focusInDirection(intent.direction)) return;
    // داخل نافذة حوار: لا نخرج منها
    final ctx = f.context;
    if (ctx != null && ModalRoute.of(ctx) is PopupRoute) return;
    final next = nearestInDirection(f, intent.direction, FocusManager.instance.rootScope.traversalDescendants);
    next?.requestFocus();
  }
}

/// أقرب عنصر قابل للتركيز في الاتجاه المطلوب (المسافة في الاتجاه + ضعف الانحراف العمودي عليه).
FocusNode? nearestInDirection(FocusNode from, TraversalDirection dir, Iterable<FocusNode> candidates) {
  final r = from.rect;
  FocusNode? best;
  var bestScore = double.infinity;
  for (final n in candidates) {
    if (identical(n, from) || !n.canRequestFocus || n.skipTraversal || n.context == null) continue;
    if (n is FocusScopeNode) continue;
    final o = n.rect;
    if (o.isEmpty) continue;
    final (double gap, double off) = switch (dir) {
      TraversalDirection.right => (o.left - r.right, (o.center.dy - r.center.dy).abs()),
      TraversalDirection.left => (r.left - o.right, (o.center.dy - r.center.dy).abs()),
      TraversalDirection.down => (o.top - r.bottom, (o.center.dx - r.center.dx).abs()),
      TraversalDirection.up => (r.top - o.bottom, (o.center.dx - r.center.dx).abs()),
    };
    if (gap < -1) continue; // ليس في هذا الاتجاه
    final score = gap + 2 * off;
    if (score < bestScore) {
      bestScore = score;
      best = n;
    }
  }
  return best;
}

/// الإجراءات الافتراضية + السهم المحسَّن للريموت.
Map<Type, Action<Intent>> get tvFriendlyActions => {
      ...WidgetsApp.defaultActions,
      DirectionalFocusIntent: DirectionalOrFirstAction(),
    };
