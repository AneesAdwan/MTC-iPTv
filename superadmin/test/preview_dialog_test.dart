import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtc_superadmin/app/theme/theme.dart';
import 'package:mtc_superadmin/core/tr.dart';
import 'package:mtc_superadmin/data/rpc/admin_rpc.dart';
import 'package:mtc_superadmin/data/rpc/rpc_catalog.dart';
import 'package:mtc_superadmin/ui/preview_dialog.dart';

Future<PreviewDecision?> _open(WidgetTester tester, OperationPreview p, {Lang lang = Lang.ar}) async {
  PreviewDecision? result;
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(Brightness.dark),
      locale: lang.locale,
      supportedLocales: [for (final l in Lang.values) l.locale],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(onPressed: () async => result = await showPreviewDialog(context, p), child: const Text('open')),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

OperationPreview _p(UndoClass u, {bool typed = false}) => OperationPreview(
  title: const Tr('عملية', 'Operation'),
  confirmLabel: const Tr('نفّذ', 'Run'),
  affected: 37,
  unit: const Tr('قناة', 'channels'),
  undoClass: u,
  typedConfirm: typed,
  groups: const [PreviewGroup(Tr('تنتشر', 'Publish'), 30), PreviewGroup(Tr('تنخفى', 'Hide'), 5)],
  excluded: const [PreviewExclusion('قناة X', Tr('ما إلها رابط يعمل', 'no working stream'))],
);

bool _runEnabled(WidgetTester tester) => tester.widget<FilledButton>(find.byKey(const ValueKey('preview-run'))).onPressed != null;

void main() {
  for (final u in UndoClass.values) {
    for (final lang in Lang.values) {
      testWidgets('renders undo class ${u.name} (${lang.name})', (tester) async {
        await _open(tester, _p(u), lang: lang);
        expect(find.byKey(ValueKey('undo-class-${u.name}')), findsOneWidget);
        expect(find.text(u.label.of(lang)), findsOneWidget);
        expect(tester.widget<Text>(find.byKey(const ValueKey('undo-explanation'))).data, u.explanation.of(lang));
        expect(find.text(lang == Lang.ar ? 'رح يتأثر 37 قناة' : '37 channels will be affected'), findsOneWidget);
      });
    }
  }

  testWidgets('irreversible: no undo promise, red button, typed confirmation + reason required', (tester) async {
    await _open(tester, _p(UndoClass.irreversible, typed: true));
    expect(find.text('هالعملية ما إلها تراجع. تأكد قبل التنفيذ.'), findsOneWidget);
    expect(_runEnabled(tester), isFalse);
    await tester.enterText(find.byKey(const ValueKey('preview-reason')), 'طلب صاحب الحقوق');
    await tester.pump();
    expect(_runEnabled(tester), isFalse, reason: 'typed confirmation still missing');
    await tester.enterText(find.byKey(const ValueKey('preview-typed')), '36');
    await tester.pump();
    expect(_runEnabled(tester), isFalse, reason: 'wrong number');
    await tester.enterText(find.byKey(const ValueKey('preview-typed')), '37');
    await tester.pump();
    expect(_runEnabled(tester), isTrue);
  });

  testWidgets('reason is mandatory for every class and is returned', (tester) async {
    PreviewDecision? got;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(onPressed: () async => got = await showPreviewDialog(context, _p(UndoClass.full)), child: const Text('open')),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(_runEnabled(tester), isFalse);
    await tester.enterText(find.byKey(const ValueKey('preview-reason')), 'ok');
    await tester.pump();
    expect(_runEnabled(tester), isFalse, reason: 'shorter than 3 characters');
    await tester.enterText(find.byKey(const ValueKey('preview-reason')), 'تنظيف');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('preview-run')));
    await tester.pumpAndSettle();
    expect(got?.reason, 'تنظيف');
  });

  test('catalog: every server function is admin_*, dangerous ones need recent MFA', () {
    for (final s in Rpc.all) {
      expect(s.name, startsWith('admin_'));
    }
    expect(Rpc.all.map((s) => s.name).toSet(), hasLength(Rpc.all.length), reason: 'unique names');
    for (final s in [Rpc.channelsPurge, Rpc.backupRestore, Rpc.notificationSend, Rpc.sourcePause, Rpc.sessionRevoke]) {
      expect(s.needsRecentMfa, isTrue, reason: s.name);
    }
    expect(Rpc.channelsPurge.undoClass, UndoClass.irreversible);
    expect(Rpc.notificationSend.undoClass, UndoClass.irreversible);
    expect(Rpc.channelsBulk.undoClass, UndoClass.snapshot);
  });
}
