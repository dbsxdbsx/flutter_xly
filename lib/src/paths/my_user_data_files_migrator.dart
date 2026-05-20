import 'dart:io';

import 'package:path/path.dart' as p;
import '../logger.dart';
import 'my_paths.dart';

/// 将旧版「安装目录 / exe 同级」中的用户数据文件迁移到 [userDataRoot]。
class MyUserDataFilesMigrator {
  MyUserDataFilesMigrator._();

  /// 从 [legacyDir]（默认 [MyPaths.installDir]）迁到 [userDataRoot]。
  ///
  /// [fileNames] 由应用传入（如 `config.json`、业务数据库名等），不含可执行文件。
  /// 目标已存在且较新时保留目标并删除源副本。
  static Future<void> migrateFromInstallDir({
    required String userDataRoot,
    required List<String> fileNames,
    String? legacyDir,
  }) async {
    final normalizedData = p.normalize(userDataRoot);
    final normalizedLegacy = p.normalize(
      legacyDir ?? MyPaths.installDir,
    );

    if (_pathsEqual(normalizedData, normalizedLegacy)) return;
    if (fileNames.isEmpty) return;

    final dataDir = Directory(normalizedData);
    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }

    for (final name in fileNames) {
      if (name.trim().isEmpty) continue;
      await _migrateOne(
        src: File(p.join(normalizedLegacy, name)),
        dest: File(p.join(normalizedData, name)),
      );
    }
  }

  static Future<void> _migrateOne({
    required File src,
    required File dest,
  }) async {
    if (!await src.exists()) return;

    try {
      if (!await dest.exists()) {
        await src.rename(dest.path);
        XlyLogger.info('已迁移: ${src.path} → ${dest.path}');
        return;
      }

      final srcMod = await src.lastModified();
      final destMod = await dest.lastModified();
      if (srcMod.isAfter(destMod)) {
        await dest.delete();
        await src.rename(dest.path);
        XlyLogger.info('已用较新文件覆盖: ${src.path} → ${dest.path}');
        return;
      }

      await src.delete();
      XlyLogger.debug('目标已较新，已删除安装目录旁旧副本: ${src.path}');
    } catch (e, st) {
      XlyLogger.error('迁移失败 ${src.path} → ${dest.path}', e, st);
    }
  }

  static bool _pathsEqual(String a, String b) {
    return p.equals(p.normalize(a), p.normalize(b));
  }
}
