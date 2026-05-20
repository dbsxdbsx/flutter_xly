import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../logger.dart';
import '_install_resolve.dart';
import '_path_safety.dart';
import '_user_data_state.dart';

/// 安装目录与用户数据目录的统一路径门面。
///
/// 命名约定：`Dir` = 目录路径（[String]），`File` = [File] 对象（[Future]）。
/// 详见仓库 `.doc/user_data_paths.md`。
class MyPaths {
  MyPaths._();

  /// 仅用于测试：清空 userData 状态与 install 移动缓存。
  static void resetForTest() {
    UserDataPathState.resetForTest();
    InstallPathResolve.resetForTest();
  }

  // --- install 轨 ---

  /// install 轨根目录。桌面为 exe 同级；移动为 Documents（须先经 [installFile] 等异步方法预热缓存）。
  static String get installDir => InstallPathResolve.syncInstallDirOrThrow();

  /// install 轨下的文件（[relativePath] 为相对路径，禁止 `..` 与绝对路径）。
  static Future<File> installFile(
    String relativePath, {
    bool androidPreferExternal = false,
  }) {
    return InstallPathResolve.file(
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

  static Future<File> userDataFile(String relativePath) {
    return UserDataPathState.file(relativePath);
  }

  static Future<String> userDataLogsDir() => UserDataPathState.logsDir();

  // --- assets ---

  /// 从 `assets/` 复制到 install 轨（目标不存在时写入）。
  static Future<File> copyAssetToInstallDir(
    String assetRelativePath, {
    bool androidPreferExternal = false,
  }) {
    return _copyAssetToDir(
      assetRelativePath,
      install: true,
      androidPreferExternal: androidPreferExternal,
    );
  }

  /// 从 `assets/` 复制到 userData 轨（目标不存在时写入）。
  static Future<File> copyAssetToUserDataDir(String assetRelativePath) {
    return _copyAssetToDir(assetRelativePath, install: false);
  }

  /// 原子写入：先写 `.tmp` 再 rename。
  static Future<void> atomicWriteString(File file, String content) {
    return UserDataPathState.atomicWriteString(file, content);
  }

  static Future<File> _copyAssetToDir(
    String assetRelativePath, {
    required bool install,
    bool androidPreferExternal = false,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('Web 平台不支持路径文件 API');
    }
    assertSafeRelativePath(assetRelativePath);

    try {
      final targetFile = install
          ? await installFile(
              assetRelativePath,
              androidPreferExternal: androidPreferExternal,
            )
          : await userDataFile(assetRelativePath);

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
