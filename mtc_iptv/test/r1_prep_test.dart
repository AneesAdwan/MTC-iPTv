// المرحلة 7: الروابط العميقة، مفاتيح مزامنة المفضلة، قناة التحديث.
import 'package:flutter_test/flutter_test.dart';
import 'package:mtc_iptv/app/desktop/deep_links.dart';
import 'package:mtc_iptv/data/favorites/fav_sync.dart';
import 'package:mtc_iptv/data/updates/app_updater.dart';

void main() {
  group('deep links', () {
    const id = 'b0d79275-2883-4395-849c-1a0a16a34ecf';
    test('mtciptv://watch/<id> in its accepted forms', () {
      expect(channelFromDeepLink('mtciptv://watch/$id'), id);
      expect(channelFromDeepLink('mtciptv://watch/$id/'), id);
      expect(channelFromDeepLink('MTCIPTV://watch/$id?from=web'), id);
      expect(channelFromDeepLink('"mtciptv://watch/$id"'), id);
    });
    test('anything else is ignored', () {
      expect(channelFromDeepLink('mtciptv://admin/delete'), isNull);
      expect(channelFromDeepLink('mtciptv://watch/../../x'), isNull);
      expect(channelFromDeepLink('https://example.com/watch/$id'), isNull);
      expect(channelFromDeepLink(null), isNull);
    });
    test('found in argv or in a raw command line', () {
      expect(findDeepLink(['--hidden', 'mtciptv://watch/$id']), 'mtciptv://watch/$id');
      expect(findDeepLink(['"C:\\x\\mtc_iptv.exe" "mtciptv://watch/$id"']), 'mtciptv://watch/$id');
      expect(findDeepLink(['--hidden']), isNull);
    });
  });

  group('favorites sync keys', () {
    test('code alone, spaced/lowercase, or the edit key', () {
      expect(parseFavKey('ABCD2345'), ('ABCD2345', null));
      expect(parseFavKey(' abcd 2345 '), ('ABCD2345', null));
      final secret = 'a' * 48;
      expect(parseFavKey('ABCD2345-${secret.toUpperCase()}'), ('ABCD2345', secret));
    });
    test('ambiguous or malformed codes are rejected', () {
      expect(parseFavKey('ABCD0O1I'), isNull); // 0 O 1 I غير مستخدمة
      expect(parseFavKey('ABC'), isNull);
      expect(parseFavKey('ABCD2345-xyz'), isNull);
    });
    test('follower merge keeps the shared order, then local-only items', () {
      expect(mergeFavorites(['a', 'b'], ['c', 'a']), ['a', 'b', 'c']);
      expect(mergeFavorites([], ['x']), ['x']);
    });
    test('edit key round-trips through the link', () {
      final l = FavLink('ABCD2345', secret: 'f' * 48);
      expect(parseFavKey(l.editKey!), ('ABCD2345', 'f' * 48));
      expect(const FavLink('ABCD2345').editKey, isNull);
      expect(FavLink.fromJson(l.toJson()).secret, l.secret);
    });
  });

  group('update channel', () {
    test('channel and feed come from the version itself', () {
      expect(updateChannel('3.0.0-alpha.18'), 'alpha');
      expect(updateChannel('3.0.0-beta.2'), 'beta');
      expect(updateChannel('3.0.0'), 'stable');
      expect(feedUrlFor('3.0.0-alpha.18'), 'https://aneesadwan.github.io/MTC-iPTv/updates/windows-alpha.xml');
      expect(feedUrlFor('3.1.0'), endsWith('/windows-stable.xml'));
    });
  });
}
