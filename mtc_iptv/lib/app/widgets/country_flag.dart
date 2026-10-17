// أعلام الدول صورًا مضمّنة (assets/flags/<code>.png من flagcdn — نفس أعلام الموقع، ملكية عامة):
// ويندوز لا يرسم أعلام الإيموجي (خط Segoe UI Emoji بلا أعلام)، فتظهر حرفين بدل العلم.
import 'package:flutter/material.dart';

class CountryFlag extends StatelessWidget {
  final String? code; // رمز الدولة (ISO، أي حالة أحرف)
  final double height;
  const CountryFlag(this.code, {super.key, this.height = 16});

  @override
  Widget build(BuildContext context) {
    final c = code?.trim().toLowerCase();
    final fallback = Icon(Icons.flag_outlined, size: height, color: Theme.of(context).hintColor);
    if (c == null || c.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height * .14),
      child: Image.asset(
        'assets/flags/$c.png',
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

/// علم + اسم الدولة في سطر (لقوائم الاختيار).
class FlagLabel extends StatelessWidget {
  final String? code;
  final String text;
  final double flagHeight;
  const FlagLabel(this.code, this.text, {super.key, this.flagHeight = 14});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        CountryFlag(code, height: flagHeight),
        SizedBox(width: flagHeight * .5),
        Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis)),
      ]);
}
