import 'package:path/path.dart' as p;

/// 校验 [relativePath] 为安全的相对路径（非空、非绝对、不含 `..`）。
void assertSafeRelativePath(String relativePath) {
  final trimmed = relativePath.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(
      relativePath,
      'relativePath',
      '相对路径不能为空',
    );
  }
  if (p.isAbsolute(trimmed)) {
    throw ArgumentError.value(
      relativePath,
      'relativePath',
      '须为相对路径，不可使用绝对路径',
    );
  }
  if (p.split(trimmed).contains('..')) {
    throw ArgumentError.value(
      relativePath,
      'relativePath',
      '不得包含 ..',
    );
  }
}
