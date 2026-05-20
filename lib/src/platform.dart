import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'package:window_manager/window_manager.dart';

import 'logger.dart';

/// 平台工具类：平台检测、权限与窗口控制。
///
/// 文件与目录路径请使用 [MyPaths]（`package:xly/xly.dart`）。
class MyPlatform {
  const MyPlatform._();

  /// 判断是否为桌面操作系统
  static bool get isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);

  /// 判断是否为移动操作系统
  static bool get isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.fuchsia);

  /// 判断是否为Web平台
  static bool get isWeb => kIsWeb;

  static bool get isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  static bool get isMacOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  static bool get isLinux =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool get isFuchsia =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.fuchsia;

  /// 获取当前平台名称
  static String get platformName {
    if (kIsWeb) return 'Web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.linux:
        return 'Linux';
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.fuchsia:
        return 'Fuchsia';
    }
  }

  /// 请求指定权限（Web / 桌面直接返回 true）。
  static Future<bool> requestPermission(Permission permission) async {
    if (kIsWeb || isDesktop) return true;

    try {
      final status = await permission.request();
      if (status.isGranted) {
        XlyLogger.info('获取权限成功：$permission');
        return true;
      } else {
        XlyLogger.warning('无法获取权限：$permission');
        return false;
      }
    } catch (e) {
      XlyLogger.error('请求权限时出错', e);
      return false;
    }
  }

  /// 显示窗口并获取焦点（仅桌面平台）
  static Future<void> showWindow() async {
    if (!isDesktop) return;
    try {
      await windowManager.show();
      await windowManager.focus();
    } catch (e) {
      XlyLogger.error('显示窗口时出错', e);
    }
  }

  /// 隐藏窗口（仅桌面平台）
  static Future<void> hideWindow() async {
    if (!isDesktop) return;
    try {
      await windowManager.hide();
    } catch (e) {
      XlyLogger.error('隐藏窗口时出错', e);
    }
  }
}
