import 'dart:io';

import 'package:path/path.dart' as p;

/// 用户数据根目录（配置、日志、业务 JSON 等），与 [MyPlatform.installDirectory] 分离。
///
/// 桌面端由应用在启动时或首次运行时 [setRoot]；移动端通常在 bootstrap 中自动设为文档目录。
class MyUserDataPaths {
  MyUserDataPaths._();

  static String? _root;
  static final Map<String, File> _fileCache = {};

  /// 当前是否已配置用户数据根（可能为空字符串，以 [isConfigured] 为准）。
  static String? get root => _root;

  static bool get isConfigured => _root != null && _root!.isNotEmpty;

  /// 设置用户数据根；默认同时 [resetCache]。
  static void setRoot(String path, {bool clearCache = true}) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(path, 'path', '用户数据目录不能为空');
    }
    _root = p.normalize(p.absolute(trimmed));
    if (clearCache) resetCache();
  }

  /// 读取用户数据根；未 [setRoot] 时抛出 [StateError]。
  static String requireRoot() {
    final root = _root;
    if (root == null || root.isEmpty) {
      throw StateError('用户数据目录尚未配置，请先调用 MyUserDataPaths.setRoot');
    }
    return root;
  }

  /// 根目录变更后清空 [file] / [filePath] 的缓存。
  static void resetCache() {
    _fileCache.clear();
  }

  /// 用户数据目录下的文件（绝对路径）。父目录不存在时会创建。
  static Future<File> file(String fileName) async {
    final cached = _fileCache[fileName];
    if (cached != null) return cached;

    final resolved = File(await filePath(fileName));
    _fileCache[fileName] = resolved;
    return resolved;
  }

  /// 用户数据目录下文件的绝对路径字符串。
  static Future<String> filePath(String fileName) async {
    final root = requireRoot();
    final full = p.join(root, fileName);
    final parent = Directory(p.dirname(full));
    if (fileName.contains(p.separator) && !await parent.exists()) {
      await parent.create(recursive: true);
    } else {
      final rootDir = Directory(root);
      if (!await rootDir.exists()) {
        await rootDir.create(recursive: true);
      }
    }
    return full;
  }

  /// 用户数据目录下的 `logs` 子目录（绝对路径）。
  static Future<String> logsDirectory() async {
    final logs = p.join(requireRoot(), 'logs');
    final dir = Directory(logs);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return logs;
  }

  /// 原子写入：先写 `.tmp` 再 rename，避免崩溃时截断目标文件。
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
