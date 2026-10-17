// V-01 — المقدمة (خطة التحسينات، المرحلة 3): مقدمة الموقع نفسها (#splash في index.html + styles.css):
//   1) مشهد MTC-Group: هالة، الشعار، «تقدّم ← إحدى شركات»، الاسم بلمعة، خط ذهبي بجوهرة، الاسم الكامل.
//   2) يصعد المشهد للأعلى ويصغر، وتتجمّع أشرطة ضوء نحو موضع الشعار.
//   3) شعار MTC-iPTv: يظهر بقفزة، يُرسم المثلث ثم الموجات، حلقات نابضة، ومدار بنقطة تدور.
//   4) حروف «MTC-iPTv» تظهر واحدًا تلو الآخر (من الضبابية)، و«-iPTv» بتدرّج لامع، ثم الشعار النصي.
//   5) شريط التحميل برسائل متتالية، ثم «N قناة جاهزة للمشاهدة»، ثم تتلاشى المقدمة عن التطبيق.
// حسب الجهاز: كمبيوتر/تابلت/تلفزيون أفقي (الشعار بجانب الاسم)، الجوال عمودي (الشعار فوق الاسم) بمقاسات أصغر.
// تُعرض كاملة في كل تشغيل وأبطأ من الموقع (طلب المالك 2026-10-17: «سريع كثير… ما شفنا اشي»):
// الخط الزمني مصمم بـ10.4 ث ويُشغَّل ×1.4 (≈14.6 ث). لمسة/مفتاح يتخطّى، و«تقليل الحركة» في النظام يلغيها.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show KeyDownEvent;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/layout/form_factor.dart';
import '../../core/config/env.dart';
import '../../core/text/bidi.dart';
import '../../data/catalog/catalog_repository.dart';
import '../../data/settings/remote_config.dart';
import '../viewer/home_screen.dart' show channelsProvider;
import 'group_emblem_painter.dart';

const _red = Color(0xFFFF2D55), _orange = Color(0xFFFF7A1A), _amber = Color(0xFFFFB02E);

class SplashGate extends ConsumerStatefulWidget {
  final Widget child;
  const SplashGate({super.key, required this.child});
  @override
  ConsumerState<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends ConsumerState<SplashGate> with TickerProviderStateMixin {
  /// مدة الخط الزمني بثواني التصميم (كل التوقيتات أدناه بها)، وكم أبطأ يُشغَّل.
  static const double total = 10.4, _slow = 1.4;
  late final AnimationController tl = AnimationController(vsync: this, duration: Duration(milliseconds: (total * _slow * 1000).round()));
  late final AnimationController loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
  late final AnimationController drift = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat(reverse: true);
  bool done = false, started = false;
  final _focus = FocusNode(debugLabel: 'splash');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (started) return;
    started = true;
    if (MediaQuery.of(context).disableAnimations) {
      loop.stop();
      drift.stop();
      done = true;
      return;
    }
    tl.forward().whenComplete(_finish);
    WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _focus.requestFocus() : null);
  }

  void _finish() {
    // الحركات المتكررة (النبض، الأضواء) تتوقف مع انتهاء المقدمة: لا إطارات بلا داعٍ (ولا تعلق الاختبارات)
    loop.stop();
    drift.stop();
    if (mounted && !done) setState(() => done = true);
  }

  /// لمسة أو مفتاح: قفز لمرحلة الخروج.
  void _skip() {
    if (done) return;
    final outStart = (total - 1.1) / total;
    if (tl.value < outStart) tl.value = outStart;
    tl.forward().whenComplete(_finish);
  }

  @override
  void dispose() {
    tl.dispose();
    loop.dispose();
    drift.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// تقدّم مقطع من الخط الزمني: يبدأ عند [start] ثانية ويستغرق [dur] ثانية (0..1).
  double seg(double start, double dur, [Curve curve = Curves.linear]) {
    final t = tl.value * total;
    return curve.transform(((t - start) / dur).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    if (done) return widget.child;
    return Stack(children: [
      widget.child,
      Positioned.fill(
        child: Focus(
          focusNode: _focus,
          onKeyEvent: (_, e) {
            if (e is KeyDownEvent) _skip();
            return KeyEventResult.handled;
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _skip,
            // Material شفاف: النصوص فوق التطبيق (خارج Scaffold) وإلا تظهر بخط أصفر تحتها
            child: Material(
              type: MaterialType.transparency,
              child: AnimatedBuilder(animation: Listenable.merge([tl, loop, drift]), builder: (context, _) => _scene(context)),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _scene(BuildContext context) {
    final t = L10n.of(context);
    final size = MediaQuery.sizeOf(context);
    final ff = formFactorOf(context);
    final phone = ff == FormFactor.phone;
    final w = size.width, h = size.height, vmin = math.min(w, h);
    // مقاس الشعار (--s في الموقع: clamp(72px, 11vw, 124px))، أكبر على التلفزيون وأصغر على الجوال
    final s = phone ? (w * .2).clamp(60.0, 92.0) : (w * .11).clamp(72.0, ff == FormFactor.tv ? 150.0 : 124.0);
    final out = seg(total - 1.1, 1.1, Curves.easeInOut);

    return Opacity(
      opacity: (1 - out).clamp(0.0, 1.0),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(fit: StackFit.expand, children: [
          _background(w, h),
          _group(t, w, h, vmin, phone),
          // شعار MTC-iPTv تحت مشهد MTC-Group بمسافة واضحة (لا يلتصقان)، في الوسط على كل الأجهزة
          Center(
            child: Transform.translate(
              offset: Offset(0, h * .07),
              child: Transform.scale(
                scale: (.93 + .07 * seg(2.2, 7, const Cubic(.2, .6, .2, 1))) * (1 - .08 * out),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: w * .94, maxHeight: h * .36),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      _logo(s, phone, w),
                      SizedBox(height: s * .34),
                      _tag(t, phone),
                    ]),
                  ),
                ),
              ),
            ),
          ),
          _footer(t, h, phone),
          _corners(t, h),
          _skipHint(t, h),
        ]),
      ),
    );
  }

  // ── الخلفية: داكنة + أضواء «أورورا» تتحرك ببطء + تعتيم الأطراف ──
  Widget _background(double w, double h) {
    final a = seg(.1, 2.1, Curves.easeOut);
    final d = Curves.easeInOut.transform(drift.value);
    final m = math.max(w, h);
    Widget blob(Color c, double size, double dx, double dy, double op) => Positioned(
          left: w / 2 + dx - size / 2,
          top: h / 2 + dy - size / 2,
          child: Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [c.withValues(alpha: op), c.withValues(alpha: 0)], stops: const [0, .65]))),
        );
    return Stack(fit: StackFit.expand, children: [
      const ColoredBox(color: Color(0xFF050508)),
      Opacity(
        opacity: a,
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: Stack(children: [
            blob(_red, m * .46 * (1 + .15 * d), -m * .15 + m * .08 * d, -m * .07 + m * .04 * d, .55),
            blob(_orange, m * .46 * (1 - .1 * d), m * .17 - m * .09 * d, m * .09 - m * .05 * d, .55),
            blob(const Color(0xFFB0127A), m * .36 * (1 + .2 * d), -m * .0 + m * .05 * d, -m * .08 - m * .07 * d, .4),
          ]),
        ),
      ),
      const DecoratedBox(decoration: BoxDecoration(gradient: RadialGradient(colors: [Colors.transparent, Color(0xBF000000)], stops: [.35, 1], radius: .9))),
    ]);
  }

  // ── المشهد الأول: MTC-Group في الوسط (الشعار فوق الاسم على كل الأجهزة)، ثم يصعد لأعلى الشاشة ويصغر ──
  // بعد الصعود يشغل [9%..32%] من الارتفاع، وشعار MTC-iPTv يبدأ تحته بمسافة (≈ 38%).
  Widget _group(L10n t, double w, double h, double vmin, bool phone) {
    final settle = seg(2.6, 1.1, const Cubic(.65, 0, .25, 1));
    final k = 1 - (1 - .54) * settle;
    final emb = phone ? (vmin * .3).clamp(84.0, 140.0) : (vmin * .22).clamp(110.0, 210.0);
    double fade(double start) => seg(start, .9, const Cubic(.2, .8, .2, 1));
    Widget rise(double start, Widget child) {
      final p = fade(start);
      return Opacity(
        opacity: p,
        child: Transform.translate(offset: Offset(0, 8 * (1 - p)), child: p < 1 ? ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: 12 * (1 - p), sigmaY: 12 * (1 - p)), child: child) : child),
      );
    }

    final rule = seg(1.25, 1.1, const Cubic(.65, 0, .35, 1));
    final gem = seg(2.0, .6, const Cubic(.34, 1.56, .64, 1));
    final track = seg(1.45, 1.6, const Cubic(.2, .8, .2, 1));
    final shimmer = (tl.value * total - 1.8) / 3.6 % 1;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final nameSize = phone ? (vmin * .1).clamp(30.0, 46.0) : (vmin * .08).clamp(36.0, 78.0);

    final texts = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        rise(
          1.0,
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('MTC', style: TextStyle(color: Colors.white, fontSize: nameSize, fontWeight: FontWeight.w900, height: 1.02, shadows: const [Shadow(color: Color(0x40FF7850), blurRadius: 40)])),
              _shimmerText('-Group', TextStyle(fontSize: nameSize, fontWeight: FontWeight.w900, height: 1.02), shimmer),
            ]),
          ),
        ),
        const SizedBox(height: 4),
        // خط ذهبي يتمدد من الوسط، وجوهرة في منتصفه
        SizedBox(
          width: nameSize * 5.2,
          height: 10,
          child: Stack(alignment: Alignment.center, children: [
            Transform.scale(
              scaleX: rule,
              child: Container(
                height: 1,
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Color(0xFFFFC37A), _orange, Color(0xFFFFC37A), Colors.transparent], stops: [0, .18, .5, .82, 1])),
              ),
            ),
            Transform.rotate(
              angle: math.pi / 4,
              child: Transform.scale(
                scale: gem,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: const Color(0xFFFFE2BF), boxShadow: [BoxShadow(color: const Color(0xFFFF9A4A), blurRadius: 12 + 8 * math.sin(loop.value * 2 * math.pi).abs())]),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 4),
        rise(1.15, Text(t.sgName, textAlign: TextAlign.center, style: TextStyle(color: const Color(0xFFF2F2F7), fontWeight: FontWeight.w700, fontSize: phone ? 15 : (vmin * .033).clamp(16.0, 31.0)))),
        const SizedBox(height: 4),
        Opacity(
          opacity: track,
          child: Text(
            'MIDDLE EAST TECHNOLOGY CENTER GROUP',
            textAlign: TextAlign.center,
            style: TextStyle(color: const Color(0xCCFFDCB4), fontWeight: FontWeight.w600, fontSize: phone ? 10 : (vmin * .021).clamp(12.0, 19.0), letterSpacing: (phone ? 2.0 : 5.0) + 10 * (1 - track)),
          ),
        ),
        SizedBox(height: phone ? 10 : (vmin * .018).clamp(8.0, 16.0)),
        // «تقدّم»: MTC-Group تقدّم ← MTC-iPTv تحتها
        Opacity(
          opacity: fade(1.6),
          child: Text(t.sgCap1, style: TextStyle(color: const Color(0xFFFFB37A), fontWeight: FontWeight.w700, letterSpacing: 4, fontSize: phone ? 15 : (vmin * .026).clamp(14.0, 22.0))),
        ),
      ],
    );

    final halo = seg(.3, 2.6);
    // شعار MTC-Group المتحرك (متجهي، بتوقيتات ملف الموقع المتحرك) — يبدأ عند 0.3 ث
    final emblem = CustomPaint(size: Size.square(emb), painter: GroupEmblemPainter(tl.value * total - .3));

    return Positioned.fill(
      child: Padding(
        padding: EdgeInsets.only(top: h * .09 * settle),
        child: Align(
          // من منتصف الشاشة إلى أعلاها، ويصغر من حافته العليا فيبقى أعلاه ثابتًا
          alignment: Alignment.lerp(Alignment.center, Alignment.topCenter, settle)!,
          child: Transform.scale(
            scale: k,
            alignment: Alignment.lerp(Alignment.center, Alignment.topCenter, settle)!,
            child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
              // الهالة
              Opacity(
                opacity: (halo < .35 ? halo / .35 : 1 - (halo - .35) / .65).clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: .6 + .8 * halo,
                  child: Container(
                    width: emb * 4,
                    height: emb * 2.4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [_red.withValues(alpha: .32), _orange.withValues(alpha: .1), Colors.transparent], stops: const [0, .55, 1]),
                    ),
                  ),
                ),
              ),
              // يصغر ليناسب الشاشة بدل أن يفيض (بعد الصعود: ≤ 42% × 0.54 من الارتفاع)
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: w * .94, maxHeight: h * .42),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Directionality(
                    textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [emblem, SizedBox(height: phone ? 14 : (vmin * .022).clamp(12.0, 22.0)), texts]),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _shimmerText(String text, TextStyle style, double phase) => ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (r) => LinearGradient(
          colors: const [_red, _orange, Color(0xFFFFD3A8), _orange, _red],
          stops: const [0, .35, .5, .65, 1],
          begin: Alignment(-1 - 2.5 + 4 * phase, 0),
          end: Alignment(1 - 2.5 + 4 * phase + 1.5, 0),
        ).createShader(r),
        child: Text(text, style: style.copyWith(color: Colors.white)),
      );

  // ── الشعار: الرمز + «MTC-iPTv» (أفقي، أو عمودي على الجوال) ──
  Widget _logo(double s, bool phone, double w) {
    final pop = seg(3.5, 1.2, const Cubic(.34, 1.56, .64, 1));
    final glow = seg(3.7, 1.6);
    final tri = seg(4.2, .9, const Cubic(.65, 0, .35, 1));
    final fill = seg(4.9, .4);
    final wave1 = seg(5.0, .6, const Cubic(.65, 0, .35, 1));
    final wave2 = seg(5.18, .6, const Cubic(.65, 0, .35, 1));
    final orbit = seg(5.6, .8);
    final ringsOn = seg(5.3, .2);

    final mark = SizedBox(
      width: s,
      height: s,
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
        if (!phone) _Ribbons(progress: [for (var i = 0; i < 4; i++) seg(2.4 + i * .15, 1.4, const Cubic(.7, 0, .25, 1))], s: s, w: w),
        // التوهج خلف الرمز ينبض
        Opacity(
          opacity: glow * (.85 + .15 * math.sin(loop.value * 2 * math.pi)),
          child: Container(
            width: s * 1.44,
            height: s * 1.44,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0x8CFF463C), Colors.transparent], stops: [0, .62])),
          ),
        ),
        // حلقتان تتسعان وتتلاشيان
        for (final off in [0.0, .5])
          Builder(builder: (_) {
            final p = (loop.value + off) % 1;
            final o = (p < .12 ? p / .12 : 1 - (p - .12) / .88) * ringsOn;
            return Opacity(
              opacity: o.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: .8 + 2.6 * p,
                child: Container(
                  width: s * .39,
                  height: s * .39,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xBFFF8246), width: 2 / (.8 + 2.6 * p)),
                    boxShadow: const [BoxShadow(color: Color(0x8CFF503C), blurRadius: 16)],
                  ),
                ),
              ),
            );
          }),
        Opacity(
          opacity: (pop * 1.6).clamp(0.0, 1.0),
          child: Transform.rotate(
            angle: -.21 * (1 - pop),
            child: Transform.scale(
              scale: .3 + .7 * pop,
              child: CustomPaint(size: Size.square(s), painter: _MarkPainter(tri: tri, fill: fill, wave1: wave1, wave2: wave2, orbit: orbit, spin: loop.value, beat: (tl.value * total > 6.2) ? loop.value : 0)),
            ),
          ),
        ),
      ]),
    );

    final fontSize = phone ? s * .52 : s * .676;
    const word = 'MTC-iPTv';
    final shimmer = ((tl.value * total - 6.5) / 3.2) % 1;
    final letters = Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
      for (var i = 0; i < word.length; i++)
        Builder(builder: (_) {
          final p = seg(4.8 + i * .12, 1.1, const Cubic(.2, .8, .2, 1));
          final style = TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900, height: 1, letterSpacing: -fontSize * .022);
          final ch = i < 3 ? Text(word[i], style: style.copyWith(color: Colors.white)) : _shimmerText(word[i], style, shimmer);
          return Opacity(
            opacity: p,
            child: Transform.translate(
              offset: Offset(0, fontSize * .35 * (1 - p)),
              child: Transform.scale(
                scale: .96 + .04 * p,
                child: p < 1 ? ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: 14 * (1 - p), sigmaY: 14 * (1 - p)), child: ch) : ch,
              ),
            ),
          );
        }),
    ]);

    return phone
        ? Column(mainAxisSize: MainAxisSize.min, children: [mark, SizedBox(height: s * .3), letters])
        : Row(mainAxisSize: MainAxisSize.min, children: [mark, SizedBox(width: s * .294), letters]);
  }

  Widget _tag(L10n t, bool phone) {
    final p = seg(6.3, 1.4, const Cubic(.2, .8, .2, 1));
    final fs = phone ? 12.5 : (MediaQuery.sizeOf(context).width * .015).clamp(13.0, 16.0);
    return Opacity(
      opacity: p,
      child: Directionality(
        textDirection: Localizations.localeOf(context).languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        child: Text(t.spTag, textAlign: TextAlign.center, style: TextStyle(color: const Color(0x9EFFFFFF), fontSize: fs, fontWeight: FontWeight.w500, letterSpacing: fs * (.12 + .38 * (1 - p)))),
      ),
    );
  }

  // ── الزاويتان السفليتان: رقم الإصدار يسارًا، واسم المطوّر يمينًا ──
  Widget _corners(L10n t, double h) {
    final p = seg(6.6, 1);
    final lang = Localizations.localeOf(context).languageCode;
    final dev = ref.watch(remoteConfigProvider).value?.developerName(lang) ?? (lang == 'ar' ? 'أنيس عدوان' : 'Anees Adwan'); // قبل أول مزامنة
    final style = TextStyle(color: Colors.white.withValues(alpha: .42), fontSize: 11.5, fontWeight: FontWeight.w500, letterSpacing: .3);
    final pad = (h * .035).clamp(14.0, 28.0);
    final dir = lang == 'ar' ? TextDirection.rtl : TextDirection.ltr;
    return Positioned(
      left: pad + 4,
      right: pad + 4,
      bottom: pad,
      child: Opacity(
        opacity: p,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(child: Text(t.version(ltr(Env.version)), textDirection: dir, style: style, maxLines: 1, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 16),
          Flexible(child: Text(t.spDev(dev), textDirection: dir, style: style, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end)),
        ]),
      ),
    );
  }

  // ── أعلى: «اضغط للتخطي» (المقدمة صارت أطول) ──
  Widget _skipHint(L10n t, double h) {
    final p = seg(1.6, .8) * (1 - seg(total - 1.6, .4));
    final lang = Localizations.localeOf(context).languageCode;
    return Positioned(
      top: (h * .035).clamp(14.0, 28.0),
      left: 0,
      right: 0,
      child: Opacity(
        opacity: p * .5,
        child: Text(t.spSkip, textAlign: TextAlign.center, textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w500, letterSpacing: .4)),
      ),
    );
  }

  // ── أسفل: شريط تحميل ورسائل متتالية، ثم «N قناة جاهزة» ──
  Widget _footer(L10n t, double h, bool phone) {
    final appear = seg(6.6, 1);
    final readyAt = total - 1.6;
    final ready = tl.value * total >= readyAt;
    final msgs = [t.spMsg1, t.spMsg2, t.spMsg3, t.spMsg4, t.spMsg5];
    // ثلاث رسائل ≈ ثانية لكل منها قبل «جاهزة»
    final idx = ((tl.value * total - 6.6) / .75).floor().clamp(0, msgs.length - 1);
    final count = ref.watch(channelsProvider(const ChannelFilter())).value?.length ?? 0;
    final msg = ready ? (count > 0 ? t.spReady(count) : t.spReadyNoCount) : msgs[idx];
    final barW = (MediaQuery.sizeOf(context).width * .44).clamp(0.0, 200.0);
    return Positioned(
      left: 0,
      right: 0,
      bottom: (h * .11).clamp(40.0, 96.0),
      child: Opacity(
        opacity: appear,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: barW,
            height: 2,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .1), borderRadius: BorderRadius.circular(2)),
            clipBehavior: Clip.hardEdge,
            child: ready
                ? Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [_red, _orange]), boxShadow: [BoxShadow(color: Color(0xE6FF5A3C), blurRadius: 10)]))
                : Align(
                    alignment: Alignment(-1.6 + 3.2 * Curves.easeInOutCubic.transform((loop.value * 1.6) % 1), 0),
                    child: Container(width: barW * .35, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, _orange, _red, Colors.transparent]))),
                  ),
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Directionality(
              key: ValueKey(msg),
              textDirection: Localizations.localeOf(context).languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
              child: Text(msg, style: TextStyle(color: ready ? Colors.white : Colors.white54, fontSize: 13, fontWeight: ready ? FontWeight.w700 : FontWeight.w400)),
            ),
          ),
        ]),
      ),
    );
  }
}

/// أشرطة ضوء تأتي من الطرفين وتنكمش نحو مركز الرمز (spRibbon في الموقع).
class _Ribbons extends StatelessWidget {
  final List<double> progress;
  final double s, w;
  const _Ribbons({required this.progress, required this.s, required this.w});
  @override
  Widget build(BuildContext context) {
    const ys = [-30.0, -10.0, 10.0, 30.0];
    return IgnorePointer(
      child: CustomPaint(
        size: Size.square(s),
        painter: _RibbonPainter(progress: progress, ys: [for (final y in ys) y * s / 124], len: w * .6, far: w * .7),
      ),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  final List<double> progress, ys;
  final double len, far;
  _RibbonPainter({required this.progress, required this.ys, required this.len, required this.far});
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    for (var i = 0; i < progress.length; i++) {
      final p = progress[i];
      if (p <= 0 || p >= 1) continue;
      final op = p < .25 ? p / .25 : 1 - (p - .25) / .75;
      final fromRight = i.isEven;
      final x = far * (1 - p), sx = 1 - .98 * p;
      canvas.save();
      canvas.translate(c.dx, c.dy);
      if (!fromRight) canvas.rotate(math.pi);
      canvas.translate(x, ys[i] * (fromRight ? 1 : -1));
      canvas.scale(sx, 1);
      final r = Rect.fromLTWH(0, -1, len, 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(2)),
        Paint()
          ..shader = LinearGradient(colors: [Colors.white.withValues(alpha: .95 * op), _orange.withValues(alpha: op), _red.withValues(alpha: 0)], stops: const [0, .3, 1]).createShader(r)
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_RibbonPainter o) => true;
}

/// رمز MTC-iPTv (img/mtc-iptv-icon.svg في الموقع، viewBox 64): دائرة متدرجة، مثلث تشغيل يُرسم ثم يمتلئ،
/// موجتا بث على الجانبين تُرسمان، ومدار منقّط بنقطة تدور.
class _MarkPainter extends CustomPainter {
  final double tri, fill, wave1, wave2, orbit, spin, beat;
  _MarkPainter({required this.tri, required this.fill, required this.wave1, required this.wave2, required this.orbit, required this.spin, required this.beat});

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 64;
    canvas.scale(k);
    const c = Offset(32, 32);
    final grad = const LinearGradient(colors: [_red, Color(0xFFFF5A36), _amber]).createShader(const Rect.fromLTWH(8, 8, 48, 48));

    // المدار + النقطة
    if (orbit > 0) {
      final dash = Paint()
        ..color = _orange.withValues(alpha: .3 * orbit)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8;
      for (var a = 0.0; a < 2 * math.pi; a += 4.5 / 27.5) {
        canvas.drawArc(Rect.fromCircle(center: c, radius: 27.5), a, 1.5 / 27.5, false, dash);
      }
      final ang = -math.pi / 2 + spin * 2 * math.pi * .6;
      canvas.drawCircle(c + Offset(math.cos(ang), math.sin(ang)) * 27.5, 2.2, Paint()..color = Colors.white.withValues(alpha: orbit));
    }

    // الدائرة الملونة (تنبض قليلًا مع المثلث)
    final b = beat == 0 ? 1.0 : 1 - .06 * math.sin(beat * 2 * math.pi).abs();
    canvas.drawCircle(c, 12.5 * b, Paint()..shader = grad);

    // المثلث: رسم الحدّ ثم الامتلاء
    final triPath = Path()
      ..moveTo(28.5, 25.5)
      ..lineTo(38.5, 32)
      ..lineTo(28.5, 38.5)
      ..close();
    if (fill > 0) canvas.drawPath(triPath, Paint()..color = Colors.white.withValues(alpha: fill));
    if (tri > 0) {
      final m = triPath.computeMetrics().first;
      canvas.drawPath(
        m.extractPath(0, m.length * tri),
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1),
      );
    }

    // الموجتان (±40° حول الأفقي، نصفا قطر 16 و25)
    final wp = Paint()
      ..shader = grad
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1.2);
    for (final (r, p) in [(16.0, wave1), (25.0, wave2)]) {
      if (p <= 0) continue;
      const span = 80 * math.pi / 180;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), -40 * math.pi / 180, span * p, false, wp);
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), 140 * math.pi / 180, span * p, false, wp);
    }
  }

  @override
  bool shouldRepaint(_MarkPainter o) => true;
}
