// Static guards: no direct table writes anywhere in lib/, and every ⓘ has its help file.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mtc_superadmin/app/nav.dart';
import 'package:mtc_superadmin/ui/help.dart';

void main() {
  test('no direct table writes (writes go through admin_* RPCs only)', () {
    final offenders = <String>[];
    final write = RegExp(r'\.from\([^)]*\)\s*\.\s*(insert|update|upsert|delete)\(', multiLine: true);
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      final src = f.readAsStringSync().replaceAll(RegExp(r'\s+'), ' ');
      if (write.hasMatch(src)) offenders.add(f.path);
      if (src.contains('service_role')) offenders.add('${f.path} (service_role)');
    }
    expect(offenders, isEmpty);
  });

  test('every page and decision type has its Arabic help file', () {
    final ids = {
      for (final p in [...Nav.pages, Nav.channelDetail]) ...p.help,
      for (final t in DecisionType.all) t.help,
      'rules',
      'undo-classes',
    };
    for (final id in ids) {
      final f = File(helpAsset(id));
      expect(f.existsSync(), isTrue, reason: f.path);
      expect(f.readAsStringSync().trim(), isNotEmpty, reason: f.path);
    }
  });

  test('section 6 of the plan is fully covered (47 services)', () {
    final files = Directory('assets/help/ar').listSync().whereType<File>().where((f) => RegExp(r'\d+-\d+\.md$').hasMatch(f.path));
    expect(files.length, 47);
  });

  test('routes are unique and stable', () {
    final paths = Nav.pages.map((p) => p.path).toList();
    expect(paths.toSet(), hasLength(paths.length));
    expect(paths, containsAll(['/home', '/channels', '/decisions', '/sources', '/epg', '/experience', '/system']));
  });
}
