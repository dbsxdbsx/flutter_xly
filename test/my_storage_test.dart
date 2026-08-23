import 'package:flutter_test/flutter_test.dart';
import 'package:xly/xly.dart';

void main() {
  setUp(MyStorage.debugReset);

  group('MyStorage.resolveContainerName', () {
    test('显式 storageContainer 优先', () {
      expect(
        MyStorage.resolveContainerName(
          storageContainer: 'my_app',
          appName: '显示名',
          packageName: 'com.example.app',
        ),
        'my_app',
      );
    });

    test('拒绝默认共享名 GetStorage，回退到 appName', () {
      expect(
        MyStorage.resolveContainerName(
          storageContainer: 'GetStorage',
          appName: '梦入零式',
        ),
        '梦入零式',
      );
    });

    test('无 appName 时用 packageName', () {
      expect(
        MyStorage.resolveContainerName(packageName: 'com.example.foo'),
        'com.example.foo',
      );
    });

    test('全空则兜底 XlyFlutterApp', () {
      expect(MyStorage.resolveContainerName(), 'XlyFlutterApp');
    });

    test('消毒 Windows 非法文件名字符', () {
      expect(
        MyStorage.sanitizeContainerName(r'a<>:"/\|?*b'),
        'a_________b',
      );
    });

    test('空串与仅空白无效', () {
      expect(MyStorage.sanitizeContainerName('   '), isNull);
      expect(MyStorage.sanitizeContainerName(''), isNull);
    });
  });

  group('MyStorage.isOwnedKey', () {
    test('只认领 _xly_ 前缀', () {
      expect(MyStorage.isOwnedKey('_xly_float_panel_state'), isTrue);
      expect(MyStorage.isOwnedKey('_xly_storage_migrated_v1'), isTrue);
      expect(MyStorage.isOwnedKey('engine_registry'), isFalse);
      expect(MyStorage.isOwnedKey('chat_session'), isFalse);
      expect(MyStorage.isOwnedKey('window_draggable'), isFalse);
    });
  });

  group('MyStorage.migrateOwnedKeys', () {
    test('只搬走 _xly_ 键，不误伤其它应用', () async {
      final source = <String, dynamic>{
        '_xly_float_panel_state': 'closed',
        '_xly_float_panel_closed_x_ratio': 0.2,
        'engine_registry': ['pikafish'],
        'chat_session': ['secret'],
        'apiKey': 'do-not-copy',
      };
      final dest = <String, dynamic>{};

      final copied = await MyStorage.migrateOwnedKeys(
        sourceKeys: source.keys.toList(),
        readSource: (k) => source[k],
        readDest: (k) => dest[k],
        writeDest: (k, v) async => dest[k] = v,
        removeSource: (k) async => source.remove(k),
      );

      expect(copied, 2);
      expect(dest['_xly_float_panel_state'], 'closed');
      expect(dest['_xly_float_panel_closed_x_ratio'], 0.2);
      expect(source.containsKey('_xly_float_panel_state'), isFalse);
      expect(source['engine_registry'], ['pikafish']);
      expect(source['chat_session'], ['secret']);
      expect(source['apiKey'], 'do-not-copy');
    });

    test('目标已有值则不覆盖，但仍从源删除已认领键', () async {
      final source = <String, dynamic>{'_xly_float_panel_state': 'from-shared'};
      final dest = <String, dynamic>{'_xly_float_panel_state': 'already-local'};

      final copied = await MyStorage.migrateOwnedKeys(
        sourceKeys: source.keys.toList(),
        readSource: (k) => source[k],
        readDest: (k) => dest[k],
        writeDest: (k, v) async => dest[k] = v,
        removeSource: (k) async => source.remove(k),
      );

      expect(copied, 0);
      expect(dest['_xly_float_panel_state'], 'already-local');
      expect(source.containsKey('_xly_float_panel_state'), isFalse);
    });
  });
}
