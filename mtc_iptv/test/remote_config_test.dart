// الإعدادات المركزية (G1–G6، F1–F2): القراءة، الاستهداف، الإشعارات، الإخفاء الفوري، الافتراضيات.
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtc_iptv/core/settings/local_settings.dart';
import 'package:mtc_iptv/core/storage/catalog_db.dart';
import 'package:mtc_iptv/data/admin/settings_repository.dart';
import 'package:mtc_iptv/data/catalog/catalog_repository.dart';
import 'package:mtc_iptv/data/settings/remote_config.dart';

import 'viewer_test.dart' show seeded;

void main() {
  group('RemoteConfig getters', () {
    const rc = RemoteConfig({
      'brand': {'about_ar': 'نبذة', 'about_en': '  ', 'company_en': 'MTC'},
      'social': {
        'links': [
          {'platform': 'x', 'handle': 'mtc'},
        ],
        'support': {'whatsapp': '+962 79', 'telegram': null},
      },
      'features': {
        'maintenance': {'enabled': true, 'message_ar': 'صيانة'},
        'kill_switch': {
          'channels': ['c1'],
        },
        'features': {'guide': false},
      },
      'general': {
        'parental_locked_categories': ['adult'],
      },
      'player': {'stall_s': 9},
      'releases': {'min_supported': '3.0.0-alpha.10', 'recommended': '3.0.0-alpha.20'},
    });

    test('brand text falls back to Arabic, empty = null', () {
      expect(rc.brandText('about', 'en'), 'نبذة');
      expect(rc.brandText('company', 'en'), 'MTC');
      expect(rc.brandText('privacy', 'ar'), isNull);
    });

    test('social links and support channels', () {
      expect(rc.social.single['platform'], 'x');
      expect(rc.support, {'whatsapp': '+962 79'});
    });

    test('features, maintenance, kill switch, player, parental', () {
      expect(rc.maintenance, isTrue);
      expect(rc.maintenanceMessage('en'), 'صيانة');
      expect(rc.killedChannels, {'c1'});
      expect(rc.feature('guide'), isFalse);
      expect(rc.feature('report'), isTrue); // غياب المفتاح = مفعّلة
      expect(rc.playerSeconds('stall_s', 6), 9);
      expect(rc.playerSeconds('first_frame_s', 15), 15);
      expect(rc.parentalLockedCategories, ['adult']);
    });

    test('update requirement: force < min, recommend < recommended', () {
      expect(rc.updateRequirement('3.0.0-alpha.9'), 'force');
      expect(rc.updateRequirement('3.0.0-alpha.16'), 'recommend');
      expect(rc.updateRequirement('3.0.0'), isNull);
      expect(RemoteConfig.empty.updateRequirement('3.0.0-alpha.1'), isNull);
    });
  });

  group('targeting', () {
    final now = DateTime(2026, 10, 16, 12);
    test('announcement window, platform and version range', () {
      Map<String, dynamic> a([Map<String, dynamic> x = const {}]) => {'id': 'a', ...x};
      expect(announcementActive(a(), now: now, platform: 'windows', version: '3.0.0'), isTrue);
      expect(announcementActive(a({'enabled': false}), now: now), isFalse);
      expect(announcementActive(a({'from': '2026-10-17T00:00:00'}), now: now), isFalse);
      expect(announcementActive(a({'to': '2026-10-16T12:00:00'}), now: now), isFalse);
      expect(announcementActive(a({'platforms': ['android']}), now: now, platform: 'windows'), isFalse);
      expect(announcementActive(a({'min_version': '3.0.1'}), now: now, version: '3.0.0'), isFalse);
      expect(announcementActive(a({'max_version': '2.9.0'}), now: now, version: '3.0.0'), isFalse);
    });

    test('notification platform, language and schedule', () {
      expect(notificationTargets({'languages': ['en']}, lang: 'ar', platform: 'windows'), isFalse);
      expect(notificationTargets({'platforms': ['windows']}, lang: 'ar', platform: 'windows'), isTrue);
      expect(notificationTargets({'send_at': DateTime.now().add(const Duration(days: 1)).toIso8601String()}, lang: 'ar', platform: 'windows'), isFalse);
    });
  });

  group('deliverNotifications', () {
    late CatalogDb db;
    setUp(() => db = CatalogDb(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('delivers each notification once, in the right language, and keeps the newest ids', () async {
      final rc = RemoteConfig({
        'notifications': [
          {'id': 'n1', 'title_ar': 'مرحبا', 'title_en': 'Hi', 'link': '/watch/c9'},
          {'id': 'n2', 'title_en': 'English only', 'languages': ['en']},
        ],
      });
      expect(await deliverNotifications(db, rc, lang: 'ar'), 1);
      expect(await deliverNotifications(db, rc, lang: 'ar'), 0);
      final rows = await db.select(db.inbox).get();
      expect(rows.single.title, 'مرحبا');
      expect(rows.single.channelId, 'c9');

      // أكثر من 200: يبقى الأحدث دائمًا (لا يُعاد تسليم آخر إشعار)
      final many = RemoteConfig({
        'notifications': [for (var i = 0; i < 250; i++) {'id': 'm$i', 'title_ar': 't$i'}],
      });
      await deliverNotifications(db, many, lang: 'ar');
      final seen = (jsonDecode((await (db.select(db.syncState)..where((s) => s.key.equals('seen_notifications'))).getSingle()).value) as List).cast<String>();
      expect(seen.length, 200);
      expect(seen.last, 'm249');
      expect(await deliverNotifications(db, RemoteConfig({'notifications': [{'id': 'm249', 'title_ar': 'x'}]}), lang: 'ar'), 0);
    });
  });

  test('kill switch hides channels from viewer queries', () async {
    final db = await seeded();
    addTearDown(db.close);
    final repo = CatalogRepository(db, hidden: {'c1'});
    expect((await repo.watchChannels(const ChannelFilter()).first).map((c) => c.id), ['c2']);
    expect(await repo.channel('c1'), isNull);
    expect(await repo.channel('c2'), isNotNull);
  });

  group('social handles', () {
    test('cleanHandle accepts handle, @handle and full URLs', () {
      expect(cleanHandle('@mtc'), 'mtc');
      expect(cleanHandle('https://www.facebook.com/mtc.group/?ref=x'), 'mtc.group');
      expect(cleanHandle('linkedin.com/in/anees'), 'anees');
      expect(cleanHandle('https://snapchat.com/add/mtc/'), 'mtc');
    });

    test('socialUrl builds platform URLs', () {
      expect(socialUrl('x', '@mtc'), 'https://x.com/mtc');
      expect(socialUrl('tiktok', 'mtc'), 'https://tiktok.com/@mtc');
      expect(socialUrl('whatsapp', '+962 79 000'), 'https://wa.me/96279000');
      expect(socialUrl('custom', 'https://mtc.example/a'), 'https://mtc.example/a');
    });
  });

  group('local defaults (G3)', () {
    test('first run takes admin defaults; a user choice is kept', () {
      expect(const LocalSettings().customized, isFalse);
      // ملف قديم بلا المفتاح = مخصّص (لا نغيّر واجهة مستخدم قائم)
      expect(LocalSettings.fromJson(const {'locale': 'ar'}).customized, isTrue);
      expect(LocalSettings.fromJson(const LocalSettings().toJson()).customized, isFalse);
      expect(const LocalSettings(locale: Locale('en')).copyWith(customized: true).toJson()['customized'], isTrue);
    });

    test('applyDefaults only before the user chooses; parental defaults on first PIN', () {
      TestWidgetsFlutterBinding.ensureInitialized();
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final s = c.read(settingsProvider.notifier);
      s.applyDefaults(language: 'en', theme: 'light');
      expect(c.read(settingsProvider).locale.languageCode, 'en');
      expect(c.read(settingsProvider).themeMode, ThemeMode.light);
      s.setLocale(const Locale('ar'));
      s.applyDefaults(language: 'en', theme: 'dark');
      expect(c.read(settingsProvider).locale.languageCode, 'ar');
      expect(c.read(settingsProvider).themeMode, ThemeMode.light);

      s.setPin('1234', defaults: ['kids', 'adult']);
      expect(c.read(settingsProvider).lockedCategories, ['adult', 'kids']);
      s.toggleLockedCategory('kids');
      s.setPin('5678', defaults: ['kids']); // تغيير الرمز لا يعيد الافتراضيات
      expect(c.read(settingsProvider).lockedCategories, ['adult']);
    });
  });
}
