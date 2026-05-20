import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:xly/xly.dart';

void main() {
  group('MyUserDataPaths', () {
    tearDown(() {
      MyUserDataPaths.resetCache();
    });

    test('requireRoot 在未 setRoot 时抛出 StateError', () {
      expect(() => MyUserDataPaths.requireRoot(), throwsA(isA<StateError>()));
    });

    test('setRoot 与 requireRoot 往返', () {
      final dir = Directory.systemTemp.createTempSync('xly_user_data_');
      MyUserDataPaths.setRoot(dir.path);
      expect(MyUserDataPaths.requireRoot(), p.normalize(p.absolute(dir.path)));
      expect(MyUserDataPaths.isConfigured, isTrue);
    });

    test('setRoot 空路径抛出 ArgumentError', () {
      expect(
        () => MyUserDataPaths.setRoot('  '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('file 返回用户数据目录下的绝对路径', () async {
      final dir = Directory.systemTemp.createTempSync('xly_user_data_');
      MyUserDataPaths.setRoot(dir.path);
      final file = await MyUserDataPaths.file('config.json');
      expect(file.path, p.join(MyUserDataPaths.requireRoot(), 'config.json'));
      expect(p.isAbsolute(file.path), isTrue);
    });

    test('resetCache 后 file 仍指向同一根目录', () async {
      final dir = Directory.systemTemp.createTempSync('xly_user_data_');
      MyUserDataPaths.setRoot(dir.path);
      final before = await MyUserDataPaths.file('a.json');
      MyUserDataPaths.resetCache();
      final after = await MyUserDataPaths.file('a.json');
      expect(after.path, before.path);
    });

    test('atomicWriteString 写入并可读回', () async {
      final dir = Directory.systemTemp.createTempSync('xly_user_data_');
      MyUserDataPaths.setRoot(dir.path);
      final file = await MyUserDataPaths.file('atomic_test.txt');
      await MyUserDataPaths.atomicWriteString(file, 'hello');
      expect(await file.readAsString(), 'hello');
    });
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

    test('evaluate 对不存在目录返回 hint', () async {
      final missing = p.join(
        Directory.systemTemp.path,
        'xly_nonexistent_${DateTime.now().microsecondsSinceEpoch}',
      );
      final result = await MyUserDataDirectoryValidator.evaluate(missing);
      expect(result.canConfirm, isFalse);
      expect(result.hint, isNotEmpty);
    });
  });

  group('MyUserDataFilesMigrator', () {
    test('从安装目录迁移到用户数据目录', () async {
      final legacy = Directory.systemTemp.createTempSync('xly_legacy_');
      final data = Directory.systemTemp.createTempSync('xly_data_');
      final legacyFile = File(p.join(legacy.path, 'prefs.json'));
      await legacyFile.writeAsString('{"v":1}');

      await MyUserDataFilesMigrator.migrateFromInstallDirectory(
        userDataRoot: data.path,
        fileNames: const ['prefs.json'],
        legacyDir: legacy.path,
      );

      expect(await legacyFile.exists(), isFalse);
      final dest = File(p.join(data.path, 'prefs.json'));
      expect(await dest.exists(), isTrue);
      expect(await dest.readAsString(), '{"v":1}');
    });

    test('目标较新时保留目标并删除源', () async {
      final legacy = Directory.systemTemp.createTempSync('xly_legacy_');
      final data = Directory.systemTemp.createTempSync('xly_data_');
      await File(p.join(legacy.path, 'a.json')).writeAsString('old');
      final dest = File(p.join(data.path, 'a.json'));
      await dest.writeAsString('new');
      final destMod = await dest.lastModified();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await File(p.join(legacy.path, 'a.json')).setLastModified(
        destMod.subtract(const Duration(hours: 1)),
      );

      await MyUserDataFilesMigrator.migrateFromInstallDirectory(
        userDataRoot: data.path,
        fileNames: const ['a.json'],
        legacyDir: legacy.path,
      );

      expect(await dest.readAsString(), 'new');
      expect(await File(p.join(legacy.path, 'a.json')).exists(), isFalse);
    });
  });

  group('MyPlatform.installDirectory', () {
    test('返回非空绝对路径', () {
      final install = MyPlatform.installDirectory;
      expect(install, isNotEmpty);
      expect(p.isAbsolute(install), isTrue);
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

    test('buildJsonPayload 包含路径与 version', () {
      const store = MyUserDataDirectoryStore();
      final payload = store.buildJsonPayload(r'D:\ProxyData');
      expect(payload['userDataDirectory'], r'D:\ProxyData');
      expect(payload['version'], 1);
    });
  });
}
