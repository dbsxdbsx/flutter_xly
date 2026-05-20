import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../logger.dart';
import '_app_resolve.dart';
import '_path_safety.dart';
import '_user_data_state.dart';

/// 程序分发根与用户数据目录的统一路径门面。
///
/// 命名约定：`Dir` = 目录路径（[String]）；`DirFile` = 该目录下的 [File]（[Future]）。
/// `app*` = 程序侧资源根（与安装向导无关）；`userData*` = 用户业务数据根。
/// 详见仓库 `.doc/user_data_paths.md`。
class MyPaths {
  MyPaths._();

  /// 仅用于测试：清空 userData 状态与 app 轨移动缓存。
  static void resetForTest() {
    UserDataPathState.resetForTest();
    AppPathResolve.resetForTest();
  }

  // --- app 轨 ---

  /// app 轨根目录。桌面为 exe 同级；移动为 Documents（须先经 [appDirFile] 等异步方法预热缓存）。
  static String get appDir => AppPathResolve.syncAppDirOrThrow();

  /// [appDir] 下的文件（[relativePath] 为相对路径，禁止 `..` 与绝对路径）。
  static Future<File> appDirFile(
    String relativePath, {
    bool androidPreferExternal = false,
  }) {
    return AppPathResolve.file(
      relativePath,
      androidPreferExternal: androidPreferExternal,
    );
  }

  // --- userData 轨 ---

  static void setUserDataDir(String path, {bool clearCache = true}) {
    UserDataPathState.setDir(path, clearCache: clearCache);
  }

  static bool get isUserDataDirSet => UserDataPathState.isSet;

  static String get userDataDir => UserDataPathState.requireDir();

  static Future<File> userDataDirFile(String relativePath) {
    return UserDataPathState.file(relativePath);
  }

  static Future<String> userDataLogsDir() => UserDataPathState.logsDir();

  // --- assets ---

  /// 从 `assets/` 复制到 app 轨（目标不存在时写入）。
  static Future<File> copyAssetToAppDir(
    String assetRelativePath, {
    bool androidPreferExternal = false,
  }) {
    return _copyAssetToDir(
      assetRelativePath,
      app: true,
      androidPreferExternal: androidPreferExternal,
    );
  }

  /// 从 `assets/` 复制到 userData 轨（目标不存在时写入）。
  static Future<File> copyAssetToUserDataDir(String assetRelativePath) {
    return _copyAssetToDir(assetRelativePath, app: false);
  }

  /// 原子写入：先写 `.tmp` 再 rename。
  static Future<void> atomicWriteString(File file, String content) {
    return UserDataPathState.atomicWriteString(file, content);
  }

  static Future<File> _copyAssetToDir(
    String assetRelativePath, {
    required bool app,
    bool androidPreferExternal = false,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('Web 平台不支持路径文件 API');
    }
    assertSafeRelativePath(assetRelativePath);

    try {
      final targetFile = app
          ? await appDirFile(
              assetRelativePath,
              androidPreferExternal: androidPreferExternal,
            )
          : await userDataDirFile(assetRelativePath);

      if (!await targetFile.exists()) {
        final assetsPath = p.join('assets', assetRelativePath);
        final byteData = await rootBundle.load(assetsPath);

        if (Platform.isAndroid) {
          try {
            await Process.run('chmod', ['777', targetFile.path]);
          } catch (e) {
            XlyLogger.error('无法设置文件权限', e);
          }
        }
        await targetFile.writeAsBytes(byteData.buffer.asUint8List());
      }

      return targetFile;
    } catch (e) {
      XlyLogger.error('从 assets 复制文件时出错', e);
      rethrow;
    }
  }
}
