import 'dart:io';

import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride, kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:xly/picker.dart';
import 'package:xly/xly.dart';

final bool _runsOnDesktopHost =
    !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

final String _mockAppSupportDir =
    Directory.systemTemp.createTempSync('xly_app_support_').path;

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      if (call.method == 'getApplicationSupportDirectory') {
        return _mockAppSupportDir;
      }
      return null;
    });
  });

  tearDown(MyPaths.resetForTest);

  group('MyPaths userData 轨', () {
    test('userDataDir 在未 setUserDataDir 时抛出 StateError', () {
      expect(() => MyPaths.userDataDir, throwsA(isA<StateError>()));
    });

    test('setUserDataDir 与 userDataDir 往返', () {
      final dir = Directory.systemTemp.createTempSync('xly_user_data_');
      MyPaths.setUserDataDir(dir.path);
      expect(MyPaths.userDataDir, p.normalize(p.absolute(dir.path)));
      expect(MyPaths.isUserDataDirSet, isTrue);
    });

    test('setUserDataDir 空路径抛出 ArgumentError', () {
      expect(
        () => MyPaths.setUserDataDir('  '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('userDataDirFile 返回绝对路径', () async {
      final dir = Directory.systemTemp.createTempSync('xly_user_data_');
      MyPaths.setUserDataDir(dir.path);
      final file = await MyPaths.userDataDirFile('config.json');
      expect(file.path, p.join(MyPaths.userDataDir, 'config.json'));
      expect(p.isAbsolute(file.path), isTrue);
    });

    test('userDataDirFile 拒绝 .. 路径', () async {
      final dir = Directory.systemTemp.createTempSync('xly_user_data_');
      MyPaths.setUserDataDir(dir.path);
      expect(
        () => MyPaths.userDataDirFile('../escape.json'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('atomicWriteString 写入并可读回', () async {
      final dir = Directory.systemTemp.createTempSync('xly_user_data_');
      MyPaths.setUserDataDir(dir.path);
      final file = await MyPaths.userDataDirFile('atomic_test.txt');
      await MyPaths.atomicWriteString(file, 'hello');
      expect(await file.readAsString(), 'hello');
    });

    test('userDataLogsDir 创建 logs 子目录', () async {
      final dir = Directory.systemTemp.createTempSync('xly_user_data_');
      MyPaths.setUserDataDir(dir.path);
      final logs = await MyPaths.userDataLogsDir();
      expect(logs, p.join(MyPaths.userDataDir, 'logs'));
      expect(Directory(logs).existsSync(), isTrue);
    });
  });

  group('MyPaths app 轨', () {
    test('appDir 返回非空绝对路径', () {
      TestWidgetsFlutterBinding.ensureInitialized();
      final app = MyPaths.appDir;
      expect(app, isNotEmpty);
      expect(p.isAbsolute(app), isTrue);
    }, skip: !_runsOnDesktopHost);

    test('appDirFile 解析到 appDir 下', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final file = await MyPaths.appDirFile(
        'xly_app_probe_${DateTime.now().microsecondsSinceEpoch}.tmp',
      );
      expect(p.dirname(file.path), MyPaths.appDir);
    }, skip: !_runsOnDesktopHost);
  });

  group('MyUserDataDirValidator', () {
    test('normalizePath 转为绝对规范化路径', () {
      final raw = Directory.systemTemp.createTempSync('xly_val_').path;
      final normalized = MyUserDataDirValidator.normalizePath(raw);
      expect(p.isAbsolute(normalized), isTrue);
    });

    test('evaluate 对已存在可写目录返回 canConfirm', () async {
      final dir = Directory.systemTemp.createTempSync('xly_val_');
      final result = await MyUserDataDirValidator.evaluate(dir.path);
      expect(result.canConfirm, isTrue);
      expect(result.hint, isNull);
    });
  });

  group('MyUserDataDirStore', () {
    test('readPathFromJson 解析 userDataDir 字段', () {
      const store = MyUserDataDirStore();
      final path = MyUserDataDirStore.readPathFromJson(
        const {'userDataDir': r'D:\ProxyData', 'version': 1},
        store.jsonPathKey,
      );
      expect(path, r'D:\ProxyData');
    });
  });

  group('MyUserDataDirSession', () {
    test('apply 设置 userDataDir 并可 round-trip store', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final dir = Directory.systemTemp.createTempSync('xly_session_');
      final store = MyUserDataDirStore(
        bootstrapFileName:
            'xly_test_apply_${DateTime.now().microsecondsSinceEpoch}.json',
      );
      final applied = await MyUserDataDirSession.apply(
        userDataDir: dir.path,
        store: store,
      );
      expect(applied, MyPaths.userDataDir);
      final loaded = await store.load();
      expect(loaded, applied);
    });

    test('apply 在成功后调用 onAfterApply', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final dir = Directory.systemTemp.createTempSync('xly_session_hook_');
      final store = MyUserDataDirStore(
        bootstrapFileName:
            'xly_test_hook_${DateTime.now().microsecondsSinceEpoch}.json',
      );
      String? hooked;
      await MyUserDataDirSession.apply(
        userDataDir: dir.path,
        store: store,
        onAfterApply: (normalized) async {
          hooked = normalized;
        },
      );
      expect(hooked, MyPaths.userDataDir);
    });

    test('prepare 在 stored 无效时暴露 storedPath 与 evaluation', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final missing = p.join(
        Directory.systemTemp.path,
        'xly_missing_${DateTime.now().microsecondsSinceEpoch}',
      );
      final store = MyUserDataDirStore(
        bootstrapFileName:
            'xly_test_invalid_${DateTime.now().microsecondsSinceEpoch}.json',
      );
      await store.save(missing);

      final boot = await MyUserDataDirSession.prepare(
        store: store,
        desktopRequiresExplicitDir: true,
      );

      expect(boot.needsDesktopSetup, isTrue);
      expect(boot.loadedPath, isNull);
      expect(boot.storedPath, p.normalize(p.absolute(missing)));
      expect(boot.hasInvalidStoredPath, isTrue);
      expect(boot.storedEvaluation?.canConfirm, isFalse);
    }, skip: !_runsOnDesktopHost);
  });

  group('MyPicker.resolveInitialDir', () {
    test('未 setUserDataDir 且无 initialDir 时返回 null', () {
      expect(MyPicker.resolveInitialDir(null), isNull);
      expect(MyPicker.resolveInitialDir('  '), isNull);
    });

    test('已 setUserDataDir 时回退到 userDataDir', () {
      final dir = Directory.systemTemp.createTempSync('xly_picker_init_');
      MyPaths.setUserDataDir(dir.path);
      expect(MyPicker.resolveInitialDir(null), MyPaths.userDataDir);
    });

    test('显式 initialDir 优先于 userDataDir', () {
      final dir = Directory.systemTemp.createTempSync('xly_picker_init2_');
      MyPaths.setUserDataDir(dir.path);
      expect(MyPicker.resolveInitialDir(r'D:\Custom'), r'D:\Custom');
    });
  });
}
