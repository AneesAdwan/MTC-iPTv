// التحديث داخل تطبيق Android: اختيار ملف APK حسب معمارية الجهاز، وقراءة البصمة من SHA256SUMS.txt.
import 'package:flutter_test/flutter_test.dart';
import 'package:mtc_iptv/data/updates/android_update.dart';
import 'package:mtc_iptv/data/updates/update_check.dart';

void main() {
  const assets = {
    'MTC-iPTv-3.0.0-alpha.32-android-arm64-v8a.apk': 'https://x/a',
    'MTC-iPTv-3.0.0-alpha.32-android-armeabi-v7a.apk': 'https://x/b',
    'MTC-iPTv-3.0.0-alpha.32-android-x86_64.apk': 'https://x/c',
    'MTC-iPTv-3.0.0-alpha.32-windows-setup.exe': 'https://x/d',
    'SHA256SUMS.txt': 'https://x/e',
  };

  test('picks the APK for the first ABI the device supports', () {
    expect(pickApk(assets, ['arm64-v8a', 'armeabi-v7a', 'armeabi']), 'MTC-iPTv-3.0.0-alpha.32-android-arm64-v8a.apk');
    expect(pickApk(assets, ['armeabi-v7a', 'armeabi']), 'MTC-iPTv-3.0.0-alpha.32-android-armeabi-v7a.apk');
    expect(pickApk(assets, ['x86_64', 'arm64-v8a']), 'MTC-iPTv-3.0.0-alpha.32-android-x86_64.apk');
    expect(pickApk(assets, ['mips']), isNull);
  });

  test('reads the checksum of a file from SHA256SUMS', () {
    final h = 'a' * 64, g = 'B' * 64;
    final sums = '$h  MTC-iPTv-3.0.0-alpha.32-android-arm64-v8a.apk\r\n$g *MTC-iPTv-3.0.0-alpha.32-windows-setup.exe\n';
    expect(sumFor(sums, 'MTC-iPTv-3.0.0-alpha.32-android-arm64-v8a.apk'), h);
    expect(sumFor(sums, 'MTC-iPTv-3.0.0-alpha.32-windows-setup.exe'), g.toLowerCase());
    expect(sumFor(sums, 'other.apk'), isNull);
  });

  test('the update check keeps direct download links of the release files', () {
    final u = pickUpdate(AppVersion.parse('3.0.0-alpha.31')!, [
      {
        'tag_name': 'v3.0.0-alpha.32',
        'html_url': 'https://github.com/x',
        'assets': [
          {'name': 'MTC-iPTv-3.0.0-alpha.32-android-arm64-v8a.apk', 'browser_download_url': 'https://dl/a'},
        ],
      },
    ]);
    expect(u!.assets['MTC-iPTv-3.0.0-alpha.32-android-arm64-v8a.apk'], 'https://dl/a');
  });
}
