// الريموت: سهم في نافذة حوار لا شيء مركّز فيها يذهب لأول زر (محاكي Android TV 16، 2026-10-16).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtc_iptv/app/layout/tv_focus.dart';

Widget host(Widget child) => MaterialApp(actions: tvFriendlyActions, home: Scaffold(body: child));

void main() {
  testWidgets('arrow key crosses from a page (nested Navigator scope) to the sidebar', (tester) async {
    final sideNode = FocusNode(debugLabel: 'side'), pageNode = FocusNode(debugLabel: 'page');
    addTearDown(sideNode.dispose);
    addTearDown(pageNode.dispose);
    await tester.pumpWidget(MaterialApp(
      actions: tvFriendlyActions,
      home: Scaffold(
        body: Row(children: [
          Expanded(
            // الصفحة داخل Navigator خاص (كما ShellRoute في go_router) = نطاق تركيز منفصل
            child: Navigator(onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => Center(child: TextButton(focusNode: pageNode, onPressed: () {}, child: const Text('page'))))),
          ),
          SizedBox(width: 200, child: Center(child: TextButton(focusNode: sideNode, onPressed: () {}, child: const Text('side')))),
        ]),
      ),
    ));
    pageNode.requestFocus();
    await tester.pump();
    expect(pageNode.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(sideNode.hasPrimaryFocus, isTrue, reason: 'arrow did not leave the page scope');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(pageNode.hasPrimaryFocus, isTrue, reason: 'arrow did not come back to the page');
  });

  testWidgets('arrow key in a fresh dialog focuses its first button', (tester) async {
    var closed = false;
    await tester.pumpWidget(host(Builder(
      builder: (ctx) => TextButton(
        onPressed: () => showDialog(
          context: ctx,
          builder: (d) => AlertDialog(
            content: const Text('hello'),
            actions: [TextButton(onPressed: () {
              closed = true;
              Navigator.pop(d);
            }, child: const Text('close'))],
          ),
        ),
        child: const Text('open'),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    final focused = FocusManager.instance.primaryFocus?.context;
    expect(focused, isNotNull);
    expect(find.descendant(of: find.byWidget(focused!.widget), matching: find.text('close')).evaluate().isNotEmpty ||
        focused.findAncestorWidgetOfExactType<TextButton>() != null, isTrue, reason: 'focus did not reach the dialog button');

    // OK في الريموت (select) يفعّل الزر المركّز
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(closed, isTrue);
  });
}
