// Per-device preferences: language, theme and saved table views. Nothing security-relevant.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_paths.dart';
import 'tr.dart';

abstract interface class PrefsStore {
  Map<String, Object?> load();
  void save(Map<String, Object?> data);
}

class MemoryPrefsStore implements PrefsStore {
  Map<String, Object?> data;
  MemoryPrefsStore([Map<String, Object?>? initial]) : data = {...?initial};
  @override
  Map<String, Object?> load() => {...data};
  @override
  void save(Map<String, Object?> d) => data = {...d};
}

class FilePrefsStore implements PrefsStore {
  final File file;
  FilePrefsStore(this.file);
  factory FilePrefsStore.standard() => FilePrefsStore(File('${AppPaths.supportDir().path}${Platform.pathSeparator}prefs.json'));

  @override
  Map<String, Object?> load() {
    try {
      if (!file.existsSync()) return {};
      final v = jsonDecode(file.readAsStringSync());
      return v is Map<String, Object?> ? v : {};
    } catch (_) {
      return {}; // a damaged prefs file just means defaults
    }
  }

  @override
  void save(Map<String, Object?> data) {
    try {
      file.parent.createSync(recursive: true);
      final tmp = File('${file.path}.tmp')..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
      tmp.renameSync(file.path);
    } catch (_) {
      // Preferences are a convenience; failing to save them must never break the program.
    }
  }
}

/// A named set of filter parameters for one page (plan §6 2.1 "saved views").
@immutable
class SavedView {
  final String name;
  final Map<String, String> params;
  final bool builtIn;
  const SavedView(this.name, this.params, {this.builtIn = false});

  Map<String, Object?> toJson() => {'name': name, 'params': params};
  static SavedView? fromJson(Object? j) {
    if (j is! Map) return null;
    final name = j['name'];
    final params = j['params'];
    if (name is! String || params is! Map) return null;
    return SavedView(name, {for (final e in params.entries) '${e.key}': '${e.value}'});
  }
}

class PrefsController extends ChangeNotifier {
  final PrefsStore _store;
  Lang _lang = Lang.ar;
  ThemeMode _theme = ThemeMode.dark;
  final Map<String, List<SavedView>> _views = {};

  PrefsController(this._store) {
    final d = _store.load();
    _lang = Lang.fromCode(d['lang'] as String?);
    _theme = switch (d['theme']) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
    final v = d['views'];
    if (v is Map) {
      for (final e in v.entries) {
        final list = e.value;
        if (list is List) _views['${e.key}'] = [for (final x in list) ?SavedView.fromJson(x)];
      }
    }
  }

  Lang get lang => _lang;
  ThemeMode get themeMode => _theme;

  set lang(Lang l) {
    if (l == _lang) return;
    _lang = l;
    _persist();
  }

  set themeMode(ThemeMode m) {
    if (m == _theme) return;
    _theme = m;
    _persist();
  }

  void toggleLang() => lang = _lang == Lang.ar ? Lang.en : Lang.ar;
  void toggleTheme() => themeMode = _theme == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;

  List<SavedView> views(String pageId) => List.unmodifiable(_views[pageId] ?? const []);

  void saveView(String pageId, SavedView view) {
    final list = [...?_views[pageId]]..removeWhere((v) => v.name == view.name);
    _views[pageId] = [...list, view];
    _persist();
  }

  void deleteView(String pageId, String name) {
    _views[pageId]?.removeWhere((v) => v.name == name);
    _persist();
  }

  void _persist() {
    _store.save({
      'lang': _lang.name,
      'theme': switch (_theme) {
        ThemeMode.light => 'light',
        ThemeMode.system => 'system',
        _ => 'dark',
      },
      'views': {
        for (final e in _views.entries) e.key: [for (final v in e.value) v.toJson()],
      },
    });
    notifyListeners();
  }
}

final prefsProvider = Provider<PrefsController>((ref) => throw UnimplementedError('override prefsProvider in main/tests'));
