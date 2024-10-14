import 'dart:io';

import 'package:flutter/services.dart';

/// 退出应用程序
///
/// 此函数会先调用系统方法关闭应用程序界面,然后强制退出进程
Future<void> exitApp({bool? animated}) async {
  // 调用系统方法关闭应用程序界面
  await SystemChannels.platform.invokeMethod('SystemNavigator.pop', animated);
  // 强制退出进程
  exit(0);
}
