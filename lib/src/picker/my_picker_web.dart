/// Web 桩：系统文件/夹选择不可用。
class MyPicker {
  MyPicker._();

  static Future<Never> dir(
          {String? initialDir, String confirmButtonText = ""}) =>
      _unsupported();

  static Future<Never> file({
    String? initialDir,
    List<String>? acceptedExtensions,
    String? confirmButtonText,
  }) =>
      _unsupported();

  static Future<Never> files({
    String? initialDir,
    List<String>? acceptedExtensions,
    String? confirmButtonText,
  }) =>
      _unsupported();

  static Future<Never> userDataDirAndApply({
    required Object store,
    String? initialDir,
    Future<bool> Function(List<String> warnings)? confirmWarnings,
    Future<void> Function(String normalizedPath)? onAfterApply,
    String confirmButtonText = "",
  }) =>
      _unsupported();

  static String? resolveInitialDir(String? initialDir) => null;

  static Future<Never> _unsupported() async {
    throw UnsupportedError("MyPicker 在 Web 上不可用");
  }
}
