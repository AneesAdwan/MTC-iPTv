// إثبات مفهوم سطح المكتب (المرحلة 0): المُجدوِل في الخلفية + البدء مع ويندوز + التحديث التلقائي.
//
//  • إغلاق النافذة يُخفيها إلى منطقة الإشعارات (Tray) والمُجدوِل يستمر.
//  • مهمة تجريبية كل دقيقة تكتب في سجل، مع «تعويض» إن فات موعدها والبرنامج مغلق.
//  • البدء مع ويندوز (مخفيًا بـ --hidden).
//  • فحص التحديثات من appcast محلي (WinSparkle، توقيع DSA).
//
// السجل: %APPDATA%\com.mtciptv\mtc_desktop_poc\scheduler.log  (يُقرأ لإثبات التشغيل في الخلفية)
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:auto_updater/auto_updater.dart';
import 'package:flutter/material.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:path_provider/path_provider.dart';
// tray_manager 0.8: الواجهة القديمة عبر legacy.dart (للتجربة فقط؛ التطبيق الحقيقي يستخدم الواجهة الأصلية)
import 'package:tray_manager/legacy.dart';
import 'package:window_manager/window_manager.dart';

const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');
const feedUrl = String.fromEnvironment('FEED_URL', defaultValue: 'http://127.0.0.1:8793/appcast.xml');
const taskInterval = Duration(minutes: 1);

late final File stateFile, logFile;

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationSupportDirectory();
  stateFile = File('${dir.path}${Platform.pathSeparator}scheduler.json');
  logFile = File('${dir.path}${Platform.pathSeparator}scheduler.log');

  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow(const WindowOptions(size: Size(720, 520), title: 'MTC-iPTv — Desktop PoC'), () async {
    if (!args.contains('--hidden')) {
      await windowManager.show();
      await windowManager.focus();
    }
  });
  await windowManager.setPreventClose(true);

  launchAtStartup.setup(appName: 'MTC-iPTv Desktop PoC', appPath: Platform.resolvedExecutable, args: ['--hidden']);

  await autoUpdater.setFeedURL(feedUrl);
  await autoUpdater.setScheduledCheckInterval(3600);

  await log('start v$appVersion pid=$pid hidden=${args.contains('--hidden')}');
  runApp(const PocApp());
}

Future<void> log(String msg) async {
  final line = '${DateTime.now().toIso8601String()}  $msg\n';
  await logFile.writeAsString(line, mode: FileMode.append, flush: true);
}

class PocApp extends StatelessWidget {
  const PocApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true),
        home: const Directionality(textDirection: TextDirection.rtl, child: Home()),
      );
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WindowListener, TrayListener {
  Timer? timer;
  DateTime? lastRun;
  int runs = 0;
  bool startup = false;
  final lines = <String>[];

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    trayManager.addListener(this);
    _init();
  }

  Future<void> _init() async {
    await trayManager.setIcon('assets/tray.ico');
    await trayManager.setToolTip('MTC-iPTv PoC v$appVersion');
    await trayManager.setContextMenu(Menu(items: [
      MenuItem(key: 'show', label: 'Show'),
      MenuItem(key: 'run', label: 'Run task now'),
      MenuItem(key: 'update', label: 'Check for updates'),
      MenuItem.separator(),
      MenuItem(key: 'quit', label: 'Quit'),
    ]));
    startup = await launchAtStartup.isEnabled();

    // التعويض: إن مضى على آخر تشغيل أكثر من الفترة (البرنامج كان مغلقًا) نشغّل فورًا
    if (await stateFile.exists()) {
      final s = jsonDecode(await stateFile.readAsString()) as Map<String, dynamic>;
      lastRun = DateTime.tryParse(s['last_run'] ?? '');
      runs = s['runs'] ?? 0;
    }
    final overdue = lastRun == null || DateTime.now().difference(lastRun!) > taskInterval;
    if (overdue) await _runTask(catchUp: lastRun != null);
    timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (lastRun == null || DateTime.now().difference(lastRun!) >= taskInterval) await _runTask();
    });
    setState(() {});
  }

  Future<void> _runTask({bool catchUp = false, bool manual = false}) async {
    final missed = lastRun == null ? 0 : DateTime.now().difference(lastRun!).inSeconds ~/ taskInterval.inSeconds - 1;
    lastRun = DateTime.now();
    runs++;
    await stateFile.writeAsString(jsonEncode({'last_run': lastRun!.toIso8601String(), 'runs': runs}));
    final visible = await windowManager.isVisible();
    final msg = 'task #$runs ${catchUp ? 'CATCH-UP (missed≈$missed) ' : ''}${manual ? 'MANUAL ' : ''}window=${visible ? 'visible' : 'hidden/tray'}';
    await log(msg);
    if (mounted) setState(() => lines.insert(0, '${TimeOfDay.now().format(context)}  $msg'));
  }

  @override
  void onWindowClose() async {
    await log('window closed -> hidden to tray');
    await windowManager.hide();
  }

  @override
  void onTrayIconMouseDown() => windowManager.show();

  @override
  void onTrayIconRightMouseDown() => trayManager.popUpContextMenu();

  @override
  void onTrayMenuItemClick(MenuItem item) async {
    switch (item.key) {
      case 'show':
        await windowManager.show();
      case 'run':
        await _runTask(manual: true);
      case 'update':
        await autoUpdater.checkForUpdates();
      case 'quit':
        await log('quit');
        await windowManager.setPreventClose(false);
        await windowManager.destroy();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('MTC-iPTv — Desktop PoC  v$appVersion')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('عدد مرات تشغيل المهمة: $runs   ·   آخر تشغيل: ${lastRun?.toLocal() ?? '—'}'),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              FilledButton(onPressed: () => _runTask(manual: true), child: const Text('شغّل المهمة الآن')),
              OutlinedButton(onPressed: () => autoUpdater.checkForUpdates(), child: const Text('فحص التحديثات')),
              OutlinedButton(onPressed: () => windowManager.hide(), child: const Text('إخفاء إلى منطقة الإشعارات')),
            ]),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('البدء مع ويندوز (مخفيًا)'),
              value: startup,
              onChanged: (v) async {
                v ? await launchAtStartup.enable() : await launchAtStartup.disable();
                startup = await launchAtStartup.isEnabled();
                await log('launch_at_startup=$startup');
                setState(() {});
              },
            ),
            const Divider(),
            Expanded(child: ListView(children: [for (final l in lines) Text(l, textDirection: TextDirection.ltr)])),
          ]),
        ),
      );
}
