library xly;

// Library imports for parts (usable by part files)
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

// Internal modules used by parts
import 'src/exit.dart';
import 'src/platform.dart';
import 'src/single_instance.dart';
import 'src/smart_dock/smart_dock_manager.dart';
import 'src/splash.dart';
import 'src/toast/toast.dart';
import 'src/tray/my_tray.dart';
import 'src/window_enums.dart';
import 'src/navigation.dart';

// 3rd packages (re-export convenience)
export 'package:flutter_screenutil/flutter_screenutil.dart';
export 'package:get/get.dart';
export 'package:window_manager/window_manager.dart';
export 'package:screen_retriever/screen_retriever.dart';
export 'package:get_storage/get_storage.dart';

// Public APIs (non-part modules)
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
export 'src/scaffold.dart';
export 'src/smart_dock/smart_dock.dart';
export 'src/tray/tray.dart';
export 'src/notify/lib.dart';
export 'src/loading_dot.dart';

// 3rd packages (re-export convenience)
export 'package:flutter_screenutil/flutter_screenutil.dart';
export 'package:get/get.dart';
export 'package:window_manager/window_manager.dart';
export 'package:screen_retriever/screen_retriever.dart';
export 'package:get_storage/get_storage.dart';

// Public APIs (non-part modules)
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
export 'src/scaffold.dart';
export 'src/smart_dock/smart_dock.dart';
export 'src/tray/tray.dart';
export 'src/notify/lib.dart';
export 'src/loading_dot.dart';

// Declare parts that are internal to this library (must come last)
part 'src/app.dart';
part 'src/float_panel.dart';
