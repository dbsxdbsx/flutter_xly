/// 路径 API 子入口（install / userData 双轨）。
///
/// `import 'package:xly/paths.dart';` — 不拖入 MyApp / MyFloatPanel / UI 组件。
library;

export 'src/paths/lib.dart'
    if (dart.library.html) 'src/paths/lib_web.dart';
