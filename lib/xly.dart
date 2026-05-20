/// xly 包默认入口：再导出各子模块与第三方便捷 API。
///
/// 按需引用示例：
/// - `package:xly/xly.dart` — 全家桶（默认）
/// - `package:xly/app.dart` — MyApp / 路由 / 窗口
/// - `package:xly/float_panel.dart` — FloatPanel
/// - `package:xly/paths.dart` — MyPaths（见 [paths.dart]）
library;

export 'app.dart';
export 'float_panel.dart';

export 'package:flutter_screenutil/flutter_screenutil.dart';
export 'package:get/get.dart';
export 'package:window_manager/window_manager.dart';
export 'package:screen_retriever/screen_retriever.dart';
export 'package:get_storage/get_storage.dart';

export 'src/window_enums.dart' show WindowCorner, WindowEdge;
export 'src/navigation.dart' show goToPage;
export 'src/toast/lib.dart';
export 'src/button.dart';
export 'src/icon.dart';
export 'src/dialogue/lib.dart';
export 'src/menu/lib.dart';
export 'src/focus.dart' show XlyFocusController, XlyFocusableExtension;
export 'src/splash.dart';
export 'src/end_of_list_widget.dart';
export 'src/group_box.dart';
export 'src/card.dart';
export 'src/list.dart';
export 'src/url_launcher.dart';
export 'src/text_editor.dart';
export 'src/spin_box.dart';
export 'src/auto_start.dart';
export 'src/platform.dart' show MyPlatform;
export 'src/paths/lib.dart';
export 'src/scaffold.dart';
export 'src/smart_dock/smart_dock.dart';
export 'src/tray/tray.dart';
export 'src/notify/lib.dart';
export 'src/loading_dot.dart';
export 'src/tab_view/lib.dart';
export 'src/selector/lib.dart';
