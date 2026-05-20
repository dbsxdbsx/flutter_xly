import 'package:path_provider/path_provider.dart';

import '../platform.dart';
import 'my_paths.dart';
import 'my_user_data_dir_store.dart';
import 'my_user_data_dir_validator.dart';

/// 启动前解析用户数据目录的结果。
class MyUserDataDirBootstrapResult {
  const MyUserDataDirBootstrapResult({
    required this.needsDesktopSetup,
    this.loadedPath,
    this.storedPath,
    this.storedEvaluation,
  });

  /// 桌面端需在 UI 中让用户选择数据目录。
  final bool needsDesktopSetup;

  /// [prepare] 已成功 [MyPaths.setUserDataDir] 时的路径。
  final String? loadedPath;

  /// [MyUserDataDirStore.load] 的原始值（不论是否已通过校验）。
  final String? storedPath;

  /// 对 [storedPath] 的 [MyUserDataDirValidator.evaluate] 结果；无 stored 时为 null。
  final MyUserDataDirValidation? storedEvaluation;

  /// Store 有记录但目录不可用（不存在或不可写等）。
  bool get hasInvalidStoredPath =>
      storedPath != null &&
      storedEvaluation != null &&
      !storedEvaluation!.canConfirm;
}

/// 用户数据目录启动编排（Store + Validator + [MyPaths]，不依赖系统文件对话框）。
class MyUserDataDirSession {
  MyUserDataDirSession._();

  /// 启动前：有有效 Store → [MyPaths.setUserDataDir]；移动无 Store → Documents + [apply]；桌面无 Store → [needsDesktopSetup]。
  static Future<MyUserDataDirBootstrapResult> prepare({
    required MyUserDataDirStore store,
    bool desktopRequiresExplicitDir = true,
  }) async {
    final stored = await store.load();
    MyUserDataDirValidation? storedEvaluation;
    if (stored != null) {
      storedEvaluation = await MyUserDataDirValidator.evaluate(stored);
      if (storedEvaluation.canConfirm) {
        MyPaths.setUserDataDir(stored);
        return MyUserDataDirBootstrapResult(
          needsDesktopSetup: false,
          loadedPath: stored,
          storedPath: stored,
          storedEvaluation: storedEvaluation,
        );
      }

      if (desktopRequiresExplicitDir && MyPlatform.isDesktop) {
        return MyUserDataDirBootstrapResult(
          needsDesktopSetup: true,
          storedPath: stored,
          storedEvaluation: storedEvaluation,
        );
      }
    }

    if (!desktopRequiresExplicitDir || !MyPlatform.isDesktop) {
      final docDir = await getApplicationDocumentsDirectory();
      final applied = await apply(
        userDataDir: docDir.path,
        store: store,
      );
      return MyUserDataDirBootstrapResult(
        needsDesktopSetup: false,
        loadedPath: applied,
        storedPath: stored,
        storedEvaluation: storedEvaluation,
      );
    }

    return MyUserDataDirBootstrapResult(
      needsDesktopSetup: true,
      storedPath: stored,
      storedEvaluation: storedEvaluation,
    );
  }

  /// 校验 → [store.save] → [MyPaths.setUserDataDir] → [onAfterApply]。
  ///
  /// [onAfterApply] 在路径已写入内存与 Store 之后调用，供应用同步 Rust 日志根、
  /// 重置路径缓存等副作用（库不负责具体实现）。
  static Future<String> apply({
    required String userDataDir,
    required MyUserDataDirStore store,
    Future<void> Function(String normalizedPath)? onAfterApply,
  }) async {
    await MyUserDataDirValidator.ensureExistingWritable(userDataDir);
    final normalized = MyUserDataDirValidator.normalizePath(userDataDir);
    await store.save(normalized);
    MyPaths.setUserDataDir(normalized);
    if (onAfterApply != null) {
      await onAfterApply(normalized);
    }
    return normalized;
  }
}
