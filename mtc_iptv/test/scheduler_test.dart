// المُجدوِل (ADM-H2): ساعات العمل المسموحة كما تخزّنها PostgreSQL (int4range).
import 'package:flutter_test/flutter_test.dart';
import 'package:mtc_iptv/data/admin/scheduler.dart';

void main() {
  test('null = any time; "empty" = never', () {
    expect(hourAllowed(null, 13), isTrue);
    expect(hourAllowed('empty', 13), isFalse);
  });
  test('[1,6) = 01:00–05:59', () {
    expect([for (final h in [0, 1, 5, 6]) hourAllowed('[1,6)', h)], [false, true, true, false]);
  });
  test('ranges that cross midnight', () {
    expect([for (final h in [22, 23, 0, 3, 4, 12]) hourAllowed('[22,4)', h)], [true, true, true, true, false, false]);
  });
  test('inclusive upper bound and unknown formats', () {
    expect(hourAllowed('[1,5]', 5), isTrue);
    expect(hourAllowed('garbage', 3), isTrue);
  });
  test('heavy checks are the ones that wait while watching', () => expect(heavyTasks, containsAll(['health_published', 'playback_sample'])));
}
