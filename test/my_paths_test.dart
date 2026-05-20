import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:xly/xly.dart';

final bool _runsOnDesktopHost =
    !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

void main() {
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

    test('userDataFile 返回绝对路径', () async {
      final dir = Directory.systemTemp.createTempSync('xly_user_data_');
      MyPaths.setUserDataDir(dir.path);
      final file = await MyPaths.userDataFile('config.json');
      expect(file.path, p.join(MyPaths.userDataDir, 'config.json'));
      expect(p.isAbsolute(file.path), isTrue);
    });

    test('userDataFile 拒绝 .. 路径', () async {
      final dir = Directory.systemTemp.createTempSync('xly_user_data_');
      MyPaths.setUserDataDir(dir.path);
      expect(
        () => MyPaths.userDataFile('../escape.json'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('atomicWriteString 写入并可读回', () async {
      final dir = Directory.systemTemp.createTempSync('xly_user_data_');
      MyPaths.setUserDataDir(dir.path);
      final file = await MyPaths.userDataFile('atomic_test.txt');
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

  group('MyPaths install 轨', () {
    test('installDir 返回非空绝对路径', () {
      TestWidgetsFlutterBinding.ensureInitialized();
      final install = MyPaths.installDir;
      expect(install, isNotEmpty);
      expect(p.isAbsolute(install), isTrue);
    }, skip: !_runsOnDesktopHost);

    test('installFile 解析到 installDir 下', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final file = await MyPaths.installFile(
        'xly_install_probe_${DateTime.now().microsecondsSinceEpoch}.tmp',
      );
      expect(p.dirname(file.path), MyPaths.installDir);
    }, skip: !_runsOnDesktopHost);
  });

  group('MyUserDataDirectoryValidator', () {
    test('normalizePath 转为绝对规范化路径', () {
      final raw = Directory.systemTemp.createTempSync('xly_val_').path;
      final normalized = MyUserDataDirectoryValidator.normalizePath(raw);
      expect(p.isAbsolute(normalized), isTrue);
    });

    test('evaluate 对已存在可写目录返回 canConfirm', () async {
      final dir = Directory.systemTemp.createTempSync('xly_val_');
      final result = await MyUserDataDirectoryValidator.evaluate(dir.path);
      expect(result.canConfirm, isTrue);
      expect(result.hint, isNull);
    });
  });

  group('MyUserDataFilesMigrator', () {
    test('migrateFromInstallDir 从安装目录迁移', () async {
      final legacy = Directory.systemTemp.createTempSync('xly_legacy_');
      final data = Directory.systemTemp.createTempSync('xly_data_');
      final legacyFile = File(p.join(legacy.path, 'prefs.json'));
      await legacyFile.writeAsString('{"v":1}');

      await MyUserDataFilesMigrator.migrateFromInstallDir(
        userDataRoot: data.path,
        fileNames: const ['prefs.json'],
        legacyDir: legacy.path,
      );

      expect(await legacyFile.exists(), isFalse);
      final dest = File(p.join(data.path, 'prefs.json'));
      expect(await dest.exists(), isTrue);
      expect(await dest.readAsString(), '{"v":1}');
    });
  });

  group('MyUserDataDirectoryStore', () {
    test('readPathFromJson 解析 userDataDirectory 字段', () {
      const store = MyUserDataDirectoryStore();
      final path = MyUserDataDirectoryStore.readPathFromJson(
        const {'userDataDirectory': r'D:\ProxyData', 'version': 1},
        store.jsonPathKey,
      );
      expect(path, r'D:\ProxyData');
    });
  });
}
