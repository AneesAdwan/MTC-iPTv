import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtc_superadmin/ui/selection.dart';

void main() {
  late SelectionModel m;
  setUp(() => m = SelectionModel()..setTotal(100));

  test('row toggle counts explicit ids', () {
    m.toggle('a');
    m.toggle('b');
    expect(m.count, 2);
    expect(m.isSelected('a'), isTrue);
    m.toggle('a');
    expect(m.count, 1);
    expect(m.snapshot().toParams(), {
      'p_ids': ['b'],
    });
  });

  test('select shown adds the visible page', () {
    m.selectShown(['a', 'b', 'c']);
    expect(m.count, 3);
    expect(m.shownState(['a', 'b', 'c']), isTrue);
    expect(m.shownState(['a', 'x']), isNull);
    m.unselectShown(['a', 'b', 'c']);
    expect(m.isEmpty, isTrue);
  });

  test('all matching covers every row on the server, minus exclusions', () {
    m.selectAllMatching();
    expect(m.count, 100);
    expect(m.isSelected('zzz-on-another-page'), isTrue);
    m.toggle('x');
    expect(m.count, 99);
    expect(m.isSelected('x'), isFalse);
    final p = m.snapshot().toParams();
    expect(p['p_all_matching'], isTrue);
    expect(p['p_excluded_ids'], ['x']);
  });

  test('invert flips selected/unselected over all matching rows', () {
    m.toggle('a');
    m.toggle('b');
    m.invert();
    expect(m.count, 98);
    expect(m.isSelected('a'), isFalse);
    expect(m.isSelected('c'), isTrue);
    m.invert();
    expect(m.count, 2);
    expect(m.isSelected('a'), isTrue);
  });

  test('invert of nothing = all; clear resets', () {
    m.invert();
    expect(m.count, 100);
    m.clear();
    expect(m.count, 0);
    expect(m.allMatching, isFalse);
  });

  test('count never negative when total shrinks', () {
    m.selectAllMatching();
    m.selectShown([]);
    for (final id in ['a', 'b', 'c']) {
      m.toggle(id);
    }
    m.setTotal(2);
    expect(m.count, 0);
  });

  testWidgets('selection bar shows "n of total" and its buttons work', (tester) async {
    m.setTotal(1204);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: SelectionBar(model: m, shownIds: () => ['a', 'b', 'c']),
        ),
      ),
    );
    String count() => tester.widget<Text>(find.byKey(const ValueKey('selection-count'))).data!;
    expect(count(), 'Selected 0 of 1,204');
    await tester.tap(find.byKey(const ValueKey('sel-shown')));
    await tester.pump();
    expect(count(), 'Selected 3 of 1,204');
    await tester.tap(find.byKey(const ValueKey('sel-invert')));
    await tester.pump();
    expect(count(), 'Selected 1,201 of 1,204');
    await tester.tap(find.byKey(const ValueKey('sel-all')));
    await tester.pump();
    expect(count(), 'Selected 1,204 of 1,204');
    await tester.tap(find.byKey(const ValueKey('sel-clear')));
    await tester.pump();
    expect(count(), 'Selected 0 of 1,204');
    expect(find.byKey(const ValueKey('sel-clear')), findsNothing);
  });
}
