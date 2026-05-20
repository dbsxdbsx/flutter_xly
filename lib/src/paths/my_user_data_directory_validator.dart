import 'dart:io';

import 'package:path/path.dart' as p;
import '../platform.dart';
import 'my_paths.dart';

/// 用户数据目录校验结果（用于启用/禁用「确定」与提示文案）。
class MyUserDataDirectoryValidation {
  const MyUserDataDirectoryValidation({
    required this.canConfirm,
    this.hint,
  });

  final bool canConfirm;
  final String? hint;
}

/// 用户数据目录校验与风险提示。
class MyUserDataDirectoryValidator {
  MyUserDataDirectoryValidator._();

  static const _writeProbeFileName = '.xly_write_probe';

  static String normalizePath(String path) {
    return p.normalize(p.absolute(path.trim()));
  }

  /// 评估路径是否可确认：须非空、目录已存在且可写（不自动创建）。
  static Future<MyUserDataDirectoryValidation> evaluate(String raw) async {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const MyUserDataDirectoryValidation(
        canConfirm: false,
        hint: '请选择或输入数据存储目录',
      );
    }

    final normalized = normalizePath(trimmed);
    final dir = Directory(normalized);
    if (!await dir.exists()) {
      return const MyUserDataDirectoryValidation(
        canConfirm: false,
        hint: '目录不存在，请先在资源管理器中创建，或重新选择',
      );
    }

    try {
      await _probeWritable(normalized);
    } on StateError catch (e) {
      return MyUserDataDirectoryValidation(
        canConfirm: false,
        hint: e.message,
      );
    }

    return const MyUserDataDirectoryValidation(canConfirm: true);
  }

  /// 返回需要向用户展示的风险提示（空列表表示无警告）。
  static List<String> warningsFor(String path) {
    final normalized = normalizePath(path);
    final warnings = <String>[];

    if (_isSameAsInstallDirectory(normalized)) {
      warnings.add(
        '所选目录与程序安装目录相同。清理构建产物或重装时，用户数据可能被一并删除。',
      );
    }

    if (_isOnSystemDrive(normalized)) {
      warnings.add(
        '所选目录位于系统盘。重装系统时若未备份，数据可能丢失；建议优先选择非系统分区。',
      );
    }

    return warnings;
  }

  /// 最终保存前再次校验（目录须已存在且可写）。
  static Future<void> ensureExistingWritable(String path) async {
    final evaluation = await evaluate(path);
    if (!evaluation.canConfirm) {
      throw StateError(evaluation.hint ?? '目录不可用');
    }
  }

  static Future<void> _probeWritable(String normalized) async {
    final probe = File(p.join(normalized, _writeProbeFileName));
    try {
      await probe.writeAsString('ok', flush: true);
    } catch (e) {
      throw StateError('目录不可写：$normalized');
    } finally {
      try {
        if (await probe.exists()) await probe.delete();
      } catch (_) {}
    }
  }

  static bool _isSameAsInstallDirectory(String normalizedDataDir) {
    if (MyPlatform.isWeb) return false;
    try {
      final installDir = MyPaths.installDir;
      return _pathsEqual(normalizedDataDir, installDir);
    } catch (_) {
      return false;
    }
  }

  static bool _isOnSystemDrive(String normalizedPath) {
    if (Platform.isWindows) {
      final systemDrive =
          (Platform.environment['SystemDrive'] ?? 'C:').toUpperCase();
      final drive = _windowsDrivePrefix(normalizedPath);
      if (drive == null) return false;
      return drive.toUpperCase() == systemDrive;
    }

    if (Platform.isMacOS || Platform.isLinux) {
      return normalizedPath == '/' ||
          normalizedPath.startsWith('${Platform.pathSeparator}System') ||
          normalizedPath.startsWith('/usr') ||
          normalizedPath.startsWith('/bin') ||
          normalizedPath.startsWith('/sbin');
    }

    return false;
  }

  static String? _windowsDrivePrefix(String path) {
    if (path.length < 2) return null;
    if (path[1] == ':') {
      return path.substring(0, 2);
    }
    return null;
  }

  static bool _pathsEqual(String a, String b) {
    if (Platform.isWindows) {
      return a.toLowerCase() == b.toLowerCase();
    }
    return a == b;
  }
}
