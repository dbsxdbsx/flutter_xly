/// 应用壳：[MyApp.initialize]、路由、窗口与停靠 API。
///
/// 可选入口：`import 'package:xly/app.dart';`
/// 全家桶仍可用：`import 'package:xly/xly.dart';`
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import 'float_panel.dart';
import 'src/exit.dart';
import 'src/logger.dart';
import 'src/platform.dart';
import 'src/single_instance.dart';
import 'src/smart_dock/smart_dock_manager.dart';
import 'src/splash.dart';
import 'src/toast/toast.dart';
import 'src/tray/my_tray.dart';
import 'src/window_enums.dart';

part 'src/app/models.dart';
part 'src/app/my_app.dart';
