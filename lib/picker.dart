/// 系统文件/文件夹选择（[MyPicker]）子入口。
///
/// `import 'package:xly/picker.dart';` — 不拖入 [MySelector] / 应用内浮层。
///
/// [MyPicker.dir] 为系统选夹对话框，不是 [MyPaths.userDataDir]。
library;

export 'src/picker/my_picker.dart'
    if (dart.library.html) 'src/picker/my_picker_web.dart';
