import 'dart:io';

import 'package:path/path.dart' as p;

import '_path_safety.dart';

/// [MyPaths] 用户数据轨内部状态。
class UserDataPathState {
  UserDataPathState._();

  static String? _root;
  static final Map<String, File> _fileCache = {};

  static bool get isSet => _root != null && _root!.isNotEmpty;

  static void setDir(String path, {bool clearCache = true}) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(path, 'path', '用户数据目录不能为空');
    }
    _root = p.normalize(p.absolute(trimmed));
    if (clearCache) clearFileCache();
  }

  static String requireDir() {
    final root = _root;
    if (root == null || root.isEmpty) {
      throw StateError('用户数据目录尚未配置，请先调用 MyPaths.setUserDataDir');
    }
    return root;
  }

  static void clearFileCache() {
    _fileCache.clear();
  }

  static void resetForTest() {
    _root = null;
    _fileCache.clear();
  }

  static Future<File> file(String relativePath) async {
    assertSafeRelativePath(relativePath);
    final cached = _fileCache[relativePath];
    if (cached != null) return cached;

    final resolved = File(await filePath(relativePath));
    _fileCache[relativePath] = resolved;
    return resolved;
  }

  static Future<String> filePath(String relativePath) async {
    assertSafeRelativePath(relativePath);
    final root = requireDir();
    final full = p.join(root, relativePath);
    final parent = Directory(p.dirname(full));
    if (relativePath.contains(p.separator) && !await parent.exists()) {
      await parent.create(recursive: true);
    } else {
      final rootDir = Directory(root);
      if (!await rootDir.exists()) {
        await rootDir.create(recursive: true);
      }
    }
    return full;
  }

  static Future<String> logsDir() async {
    final logs = p.join(requireDir(), 'logs');
    final dir = Directory(logs);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return logs;
  }

  static Future<void> atomicWriteString(File file, String content) async {
    final tmpFile = File('${file.path}.tmp');
    try {
      await tmpFile.writeAsString(content);
      try {
        await tmpFile.rename(file.path);
      } on FileSystemException {
        if (await file.exists()) await file.delete();
        await tmpFile.rename(file.path);
      }
    } finally {
      try {
        if (await tmpFile.exists()) await tmpFile.delete();
      } catch (_) {}
    }
  }
}
