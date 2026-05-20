/// Web 平台的 [MyPaths] 桩实现：所有文件 API 抛出 [UnsupportedError]。
///
/// 通过 `package:xly/paths.dart` 在 `dart.library.html` 下自动选用。
/// Bootstrap（[MyUserDataDirStore] 等）依赖 `dart:io`，Web 目标请勿 import 全家桶路径辅助类。
class MyPaths {
  MyPaths._();

  static void resetForTest() {}

  static String get installDir => _unsupported();

  static Future<Never> installFile(
    String relativePath, {
    bool androidPreferExternal = false,
  }) =>
      _unsupportedAsync();

  static void setUserDataDir(String path, {bool clearCache = true}) =>
      _unsupported();

  static bool get isUserDataDirSet => false;

  static String get userDataDir => _unsupported();

  static Future<Never> userDataFile(String relativePath) => _unsupportedAsync();

  static Future<Never> userDataLogsDir() => _unsupportedAsync();

  static Future<Never> copyAssetToInstallDir(
    String assetRelativePath, {
    bool androidPreferExternal = false,
  }) =>
      _unsupportedAsync();

  static Future<Never> copyAssetToUserDataDir(String assetRelativePath) =>
      _unsupportedAsync();

  static Future<Never> atomicWriteString(Object file, String content) =>
      _unsupportedAsync();

  static Never _unsupported() {
    throw UnsupportedError(_message);
  }

  static Future<Never> _unsupportedAsync() async {
    throw UnsupportedError(_message);
  }

  static const String _message = 'Web 平台不支持 MyPaths 文件 API；请使用浏览器存储或后端。';
}
