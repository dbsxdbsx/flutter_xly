import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../paths/my_paths.dart';
import '../paths/my_user_data_dir_session.dart';
import '../paths/my_user_data_dir_store.dart';
import '../paths/my_user_data_dir_validator.dart';

/// 系统文件/文件夹选择（非 [MySelector]）。
///
/// 类名已表达「选择」语义，方法使用 [dir] / [file] / [files]，不再重复 pick 前缀。
/// [dir] 为系统目录选择对话框，不是 [MyPaths.userDataDir] 路径 getter。
///
/// 详见 `.doc/user_data_picker.md`。
class MyPicker {
  MyPicker._();

  /// 选择单个目录；取消返回 null。桌面为主。
  static Future<String?> dir({
    String? initialDir,
    String confirmButtonText = '选择文件夹',
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('MyPicker.dir 在 Web 上不可用');
    }
    return getDirectoryPath(
      confirmButtonText: confirmButtonText,
      initialDirectory: resolveInitialDir(initialDir),
    );
  }

  /// 选择单个文件；取消返回 null。
  static Future<String?> file({
    String? initialDir,
    List<String>? acceptedExtensions,
    String? confirmButtonText,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('MyPicker.file 在 Web 上不可用');
    }
    final result = await openFile(
      acceptedTypeGroups: _typeGroups(acceptedExtensions),
      initialDirectory: resolveInitialDir(initialDir),
      confirmButtonText: confirmButtonText,
    );
    return result?.path;
  }

  /// 选择多个文件；取消或未选返回空列表。
  static Future<List<String>> files({
    String? initialDir,
    List<String>? acceptedExtensions,
    String? confirmButtonText,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('MyPicker.files 在 Web 上不可用');
    }
    final result = await openFiles(
      acceptedTypeGroups: _typeGroups(acceptedExtensions),
      initialDirectory: resolveInitialDir(initialDir),
      confirmButtonText: confirmButtonText,
    );
    return result.map((f) => f.path).toList();
  }

  /// 系统选目录 → 可选 warnings 确认 → [MyUserDataDirSession.apply]。
  static Future<String?> userDataDirAndApply({
    required MyUserDataDirStore store,
    String? initialDir,
    Future<bool> Function(List<String> warnings)? confirmWarnings,
    Future<void> Function(String normalizedPath)? onAfterApply,
    String confirmButtonText = '选择文件夹',
  }) async {
    final picked = await dir(
      initialDir: initialDir,
      confirmButtonText: confirmButtonText,
    );
    if (picked == null || picked.isEmpty) return null;

    await MyUserDataDirValidator.ensureExistingWritable(picked);
    final normalized = MyUserDataDirValidator.normalizePath(picked);
    final warnings = MyUserDataDirValidator.warningsFor(normalized);
    if (warnings.isNotEmpty && confirmWarnings != null) {
      final proceed = await confirmWarnings(warnings);
      if (!proceed) return null;
    }

    return MyUserDataDirSession.apply(
      userDataDir: normalized,
      store: store,
      onAfterApply: onAfterApply,
    );
  }

  /// 解析系统对话框初始目录：显式 [initialDir] 优先，否则已 [MyPaths.setUserDataDir] 时用 [MyPaths.userDataDir]。
  static String? resolveInitialDir(String? initialDir) {
    final trimmed = initialDir?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    if (MyPaths.isUserDataDirSet) return MyPaths.userDataDir;
    return null;
  }

  static List<XTypeGroup> _typeGroups(List<String>? acceptedExtensions) {
    if (acceptedExtensions == null || acceptedExtensions.isEmpty) {
      return const [XTypeGroup(label: 'files', extensions: [])];
    }
    return [
      XTypeGroup(
        label: 'files',
        extensions: acceptedExtensions,
      ),
    ];
  }
}
