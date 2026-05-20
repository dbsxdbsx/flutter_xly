import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../logger.dart';
import '_path_safety.dart';

bool get _isDesktopHost =>
    !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

/// app 轨目录与文件解析（供 [MyPaths] 使用）。
class AppPathResolve {
  AppPathResolve._();

  static String? _mobileAppDirCache;

  static void resetForTest() {
    _mobileAppDirCache = null;
  }

  /// 桌面：exe 目录（同步）。移动：若已缓存则返回 Documents 等，否则抛 [StateError]。
  static String syncAppDirOrThrow() {
    if (kIsWeb) {
      throw UnsupportedError('Web 平台不支持路径文件 API');
    }
    if (_isDesktopHost) {
      return p.normalize(p.dirname(Platform.resolvedExecutable));
    }
    final cached = _mobileAppDirCache;
    if (cached != null) return cached;
    throw StateError(
      '移动端 appDir 尚未就绪，请先调用 MyPaths.appDirFile 等异步方法',
    );
  }

  static Future<String> resolveAppDir({
    bool androidPreferExternal = false,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('Web 平台不支持路径文件 API');
    }
    if (_isDesktopHost) {
      return syncAppDirOrThrow();
    }
    if (androidPreferExternal && Platform.isAndroid) {
      final external = await _externalStoragePath();
      if (external != null) {
        _mobileAppDirCache = external;
        return external;
      }
    }
    if (_mobileAppDirCache != null) {
      return _mobileAppDirCache!;
    }
    final doc = await getApplicationDocumentsDirectory();
    _mobileAppDirCache = doc.path;
    return doc.path;
  }

  static Future<String> filePath(
    String relativePath, {
    bool androidPreferExternal = false,
  }) async {
    assertSafeRelativePath(relativePath);
    final base = await resolveAppDir(
      androidPreferExternal: androidPreferExternal,
    );
    return p.join(base, relativePath);
  }

  static Future<File> file(
    String relativePath, {
    bool androidPreferExternal = false,
  }) async {
    return File(await filePath(
      relativePath,
      androidPreferExternal: androidPreferExternal,
    ));
  }

  static Future<String?> _externalStoragePath() async {
    if (!Platform.isAndroid) return null;
    try {
      final dirs = await getExternalStorageDirectories();
      if (dirs != null && dirs.isNotEmpty) {
        return dirs.first.path;
      }
    } catch (e) {
      XlyLogger.error('获取外部存储路径时出错', e);
    }
    return null;
  }
}
