import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtc_superadmin/data/rpc/admin_rpc.dart';
import 'package:mtc_superadmin/ui/result_bar.dart';

import 'helpers.dart';

void main() {
  test('undo only for full/snapshot classes with a token; Ctrl+Z path runs it once', () async {
    final center = ResultCenter();
    var undone = 0;
    Future<OpResult> undo() async {
      undone++;
      return const OpResult(rpc: 'admin_undo', undoClass: UndoClass.full, done: 3);
    }

    center.show(
      const OpResult(rpc: 'admin_notification_send', undoClass: UndoClass.irreversible, done: 1, undoToken: 't'),
      undo: undo,
    );
    expect(center.canUndo, isFalse, reason: 'irreversible never offers undo');
    expect(await center.undoLast(), isFalse);

    center.show(
      const OpResult(rpc: 'admin_channels_bulk', undoClass: UndoClass.snapshot, done: 30, undoToken: 'tok'),
      undo: undo,
    );
    expect(center.canUndo, isTrue);
    expect(await center.undoLast(), isTrue);
    expect(undone, 1);
    expect(center.result!.rpc, 'admin_undo');
    expect(center.canUndo, isFalse, reason: 'an undo result has no token: undoing twice does nothing');
  });

  testWidgets('result bar: done · failed (details) · undo', (tester) async {
    var undone = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: ResultBar(
            result: const OpResult(
              rpc: 'admin_channels_bulk',
              undoClass: UndoClass.snapshot,
              done: 30,
              failed: 2,
              undoToken: 'tok',
              failures: [OpFailure('ch-1', 'row changed after preview')],
            ),
            onUndo: () => undone = true,
            onDismiss: () {},
          ),
        ),
      ),
    );
    expect(find.text('Done 30'), findsOneWidget);
    expect(find.text('Failed 2'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('result-details')));
    await tester.pumpAndSettle();
    expect(find.text('row changed after preview'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('result-undo')));
    expect(undone, isTrue);
  });

  testWidgets('"/" focuses the page filter (not while typing elsewhere)', (tester) async {
    await pumpApp(tester, location: '/channels');
    final field = find.byKey(const ValueKey('filter-search'));
    expect(tester.widget<TextField>(field).focusNode!.hasFocus, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.slash);
    await tester.pump();
    expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);
  });
}
