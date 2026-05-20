/// 浮动面板：全局 [FloatPanel] 服务与 overlay UI。
///
/// 可选入口：`import 'package:xly/float_panel.dart';`
/// 全家桶仍可用：`import 'package:xly/xly.dart';`
library;

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'src/logger.dart';

part 'src/float_panel/models.dart';
part 'src/float_panel/service.dart';
part 'src/float_panel/box_controller.dart';
part 'src/float_panel/widgets.dart';
