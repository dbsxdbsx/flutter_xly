import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

import '../logger.dart';

/// 本应用专用 GetStorage 容器。
///
/// 无容器名的 `GetStorage()` 会写成用户「文档」下的 `GetStorage.gs`，
/// 桌面端所有同样用法的应用共享该文件。xly 内部（浮窗位置等）必须走命名容器。
///
/// 业务代码请用 [box]，不要再写 `GetStorage()`。
class MyStorage {
  MyStorage._();

  /// get_storage 默认容器名，对应共享文件 `GetStorage.gs`。
  static const String sharedContainerName = 'GetStorage';

  /// 未提供 appName / packageName / storageContainer 时的兜底。
  static const String fallbackContainerName = 'XlyFlutterApp';

  static const String migratedFlagKey = '_xly_storage_migrated_v1';

  static String? _containerName;
  static GetStorage? _instance;
  static Future<void>? _initFuture;

  /// 当前容器是否已由 [ensureInitialized] 就绪。
  static bool get isReady => _containerName != null;

  static String get containerName => _containerName ?? fallbackContainerName;

  /// 本应用命名容器。须先 [ensureInitialized]（`MyApp.initialize` 会调）。
  static GetStorage get box => _instance ??= GetStorage(containerName);

  /// 解析并初始化命名容器；必要时从共享默认盒迁走 `_xly_*` 键。
  ///
  /// 仍会 `GetStorage.init()` 默认盒：旧应用若在 `MyApp.initialize` 之后
  /// 直接 `GetStorage()`，升级后不至于读到未落盘的空盒。xly 自身不再往默认盒写。
  static Future<void> ensureInitialized({
    String? storageContainer,
    String? appName,
    String? packageName,
  }) {
    return _initFuture ??= _init(
      storageContainer: storageContainer,
      appName: appName,
      packageName: packageName,
    );
  }

  static Future<void> _init({
    String? storageContainer,
    String? appName,
    String? packageName,
  }) async {
    final name = resolveContainerName(
      storageContainer: storageContainer,
      appName: appName,
      packageName: packageName,
    );
    await GetStorage.init(name);
    // 兼容：业务仍可能 GetStorage()，必须先 await 默认盒加载。
    await GetStorage.init(sharedContainerName);
    _containerName = name;
    _instance = GetStorage(name);
    try {
      await migrateXlyKeysFromDefault();
    } catch (e) {
      XlyLogger.warning('MyStorage: 从默认容器迁移失败: $e');
    }
  }

  /// 容器名优先级：显式 [storageContainer] → [appName] → [packageName] → 兜底。
  /// 默认共享名 `GetStorage` 会被拒绝，以免又写回 `GetStorage.gs`。
  static String resolveContainerName({
    String? storageContainer,
    String? appName,
    String? packageName,
  }) {
    for (final raw in [storageContainer, appName, packageName]) {
      final name = sanitizeContainerName(raw);
      if (name != null) return name;
    }
    return fallbackContainerName;
  }

  /// 去掉 Windows 非法文件名字符；空串或 `GetStorage` 视为无效。
  static String? sanitizeContainerName(String? raw) {
    if (raw == null) return null;
    var name = raw.trim();
    if (name.isEmpty) return null;
    name = name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    name = name.replaceAll(RegExp(r'[\x00-\x1F]'), '');
    name = name.replaceAll(RegExp(r'[. ]+$'), '');
    if (name.isEmpty) return null;
    if (name.toLowerCase() == sharedContainerName.toLowerCase()) {
      return null;
    }
    if (RegExp(
      r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])$',
      caseSensitive: false,
    ).hasMatch(name)) {
      name = '${name}_box';
    }
    if (name.length > 80) {
      name = name.substring(0, 80).replaceAll(RegExp(r'[. ]+$'), '');
    }
    return name.isEmpty ? null : name;
  }

  /// xly 内部键：`_xly_` 前缀。不认领业务键，避免从共享文件误搬走别人的数据。
  static bool isOwnedKey(String key) => key.startsWith('_xly_');

  /// 仅迁移本库拥有的键；其它应用的数据留在默认容器。
  static Future<int> migrateXlyKeysFromDefault({
    GetStorage? source,
    GetStorage? destination,
  }) async {
    final dest = destination ?? box;
    if (dest.read<bool>(migratedFlagKey) == true) {
      return 0;
    }

    final src = source ?? GetStorage(sharedContainerName);
    final copied = await migrateOwnedKeys(
      sourceKeys: keysOf(src),
      readSource: src.read,
      readDest: dest.read,
      writeDest: dest.write,
      removeSource: src.remove,
    );
    await dest.write(migratedFlagKey, true);
    if (copied > 0) {
      XlyLogger.info('MyStorage: 已从默认容器迁移 $copied 个键到 $containerName');
    }
    return copied;
  }

  /// 可单测的迁移核：只拷 [isOwnedKey] 为真且目标尚未有值的键，再从源删除。
  @visibleForTesting
  static Future<int> migrateOwnedKeys({
    required List<String> sourceKeys,
    required dynamic Function(String key) readSource,
    required dynamic Function(String key) readDest,
    required Future<void> Function(String key, dynamic value) writeDest,
    required Future<void> Function(String key) removeSource,
  }) async {
    final ownedKeys = sourceKeys.where(isOwnedKey).toList();
    var copied = 0;
    for (final key in ownedKeys) {
      if (readDest(key) != null) continue;
      final value = readSource(key);
      if (value == null) continue;
      await writeDest(key, value);
      copied += 1;
    }
    for (final key in ownedKeys) {
      await removeSource(key);
    }
    return copied;
  }

  static List<String> keysOf(GetStorage box) {
    try {
      final raw = box.getKeys<Iterable<String>>();
      return raw.toList();
    } catch (_) {
      try {
        final raw = box.getKeys<Iterable<dynamic>>();
        return raw.map((e) => e.toString()).toList();
      } catch (e) {
        XlyLogger.warning('MyStorage: 读取键列表失败: $e');
        return const [];
      }
    }
  }

  /// 测试用：清掉单例状态。不影响 get_storage 进程内缓存。
  @visibleForTesting
  static void debugReset() {
    _containerName = null;
    _instance = null;
    _initFuture = null;
  }
}
