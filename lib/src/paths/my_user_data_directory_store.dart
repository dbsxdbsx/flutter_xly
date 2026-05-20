import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 将用户选择的数据目录路径保存在系统应用支持目录（bootstrap 指针），
/// 以便下次启动时定位真实数据位置。
class MyUserDataDirectoryStore {
  const MyUserDataDirectoryStore({
    this.bootstrapFileName = 'user_data_directory.json',
    this.jsonPathKey = 'userDataDirectory',
  });

  /// Bootstrap 文件名，位于 [getApplicationSupportDirectory] 下。
  final String bootstrapFileName;

  /// JSON 中保存路径的字段名。
  final String jsonPathKey;

  /// 默认实例（`user_data_directory.json` + `userDataDirectory` 字段）。
  static const defaultInstance = MyUserDataDirectoryStore();

  Future<File> _bootstrapFile() async {
    final supportDir = await getApplicationSupportDirectory();
    return File(p.join(supportDir.path, bootstrapFileName));
  }

  Future<String?> load() async {
    final file = await _bootstrapFile();
    if (!await file.exists()) return null;

    try {
      final raw = await file.readAsString();
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      return readPathFromJson(json, jsonPathKey);
    } catch (_) {
      return null;
    }
  }

  /// 从 bootstrap JSON 中解析用户数据目录路径（供 [load] 与测试使用）。
  static String? readPathFromJson(
    Map<String, dynamic> json,
    String jsonPathKey,
  ) {
    final path = json[jsonPathKey];
    if (path is! String || path.trim().isEmpty) return null;
    return p.normalize(path.trim());
  }

  /// 构造将要写入 bootstrap 文件的 JSON 对象。
  Map<String, dynamic> buildJsonPayload(String userDataDirectory) {
    return {
      jsonPathKey: p.normalize(userDataDirectory.trim()),
      'version': 1,
    };
  }

  Future<void> save(String userDataDirectory) async {
    final normalized = p.normalize(userDataDirectory.trim());
    final file = await _bootstrapFile();
    final dir = file.parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final content = const JsonEncoder.withIndent('  ')
        .convert(buildJsonPayload(normalized));

    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(content);
    try {
      await tmp.rename(file.path);
    } on FileSystemException {
      if (await file.exists()) await file.delete();
      await tmp.rename(file.path);
    }
  }
}
