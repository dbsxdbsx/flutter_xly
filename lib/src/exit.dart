import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

const _platformPopTimeout = Duration(seconds: 2);
const _beforeProcessExitTimeout = Duration(seconds: 2);

/// 退出应用程序
///
/// 桌面端在最终清理回调完成后立即 `exit(0)`。
/// 移动端只请求系统导航退出，不强杀 Android/iOS 进程。
Future<void> exitApp({
  bool? animated,
  Future<void> Function()? beforeProcessExit,
}) async {
  final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  if (!isDesktop) {
    await SystemChannels.platform
        .invokeMethod('SystemNavigator.pop', animated)
        .timeout(_platformPopTimeout);
    return;
  }

  try {
    // 托盘等原生资源必须在 Flutter Engine 仍可调用插件时显式销毁。
    // 不先等待 SystemNavigator.pop，避免窗口/Engine 关闭后再调插件形成竞态。
    await beforeProcessExit?.call().timeout(_beforeProcessExitTimeout);
  } finally {
    exit(0);
  }
}
