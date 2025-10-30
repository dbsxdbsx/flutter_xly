import 'dart:io';

import 'package:autostart_settings/autostart_settings.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:xly/src/platform.dart';
import 'package:xly/src/toast/toast.dart';

import 'logger.dart';

/// 自启动管理类，提供跨平台的开机自启动功能
class MyAutoStart {
  const MyAutoStart._();

  /// 设置开机自启动
  ///
  /// [enable] 是否启用开机自启动
  /// [packageName] 包名，仅桌面平台需要，默认为 null
  ///
  /// 返回是否设置成功
  ///
  /// 注意：
  /// - Web平台不支持此功能，将返回 false
  /// - 移动平台会打开系统设置页面（可能会失败）
  /// - 桌面平台需要提供正确的包名
  static Future<bool> setAutoStart(bool enable, {String? packageName}) async {
    if (kIsWeb) {
      XlyLogger.info('Web平台不支持开机自启动');
      return false;
    }

    try {
      if (MyPlatform.isDesktop) {
        return _setDesktopAutoStart(enable, packageName);
      } else if (Platform.isAndroid) {
        return _setAndroidAutoStart();
      }
      return false;
    } catch (e) {
      XlyLogger.error('设置开机自启动时出错', e);
      return false;
    }
  }

  /// 设置桌面平台的开机自启动
  static Future<bool> _setDesktopAutoStart(
      bool enable, String? packageName) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      final packageInfo = await PackageInfo.fromPlatform();

      // 配置自启动
      launchAtStartup.setup(
        appName: packageInfo.appName,
        appPath: Platform.resolvedExecutable,
        // 如果未提供包名，则使用默认格式：com.{appName}.app
        packageName:
            packageName ?? 'com.${packageInfo.appName.toLowerCase()}.app',
      );

      // 根据 enable 参数启用或禁用自启动
      if (enable) {
        final result = await launchAtStartup.enable();
        XlyLogger.info('启用开机自启动${result ? '成功' : '失败'}');
        return result;
      } else {
        final result = await launchAtStartup.disable();
        XlyLogger.info('禁用开机自启动${result ? '成功' : '失败'}');
        return result;
      }
    } catch (e) {
      XlyLogger.error('设置桌面平台开机自启动时出错', e);
      return false;
    }
  }

  /// 设置 Android 平台的开机自启动
  static Future<bool> _setAndroidAutoStart() async {
    try {
      MyToast.show('即将打开设置页面\n（可能会失败）');

      // 检查是否可以打开自启动设置页面
      final canOpen = await AutostartSettings.canOpen(
        autoStart: true,
        batterySafer: true,
      );

      if (canOpen) {
        final result = await AutostartSettings.open(
          autoStart: true,
          batterySafer: true,
        );
        XlyLogger.info('打开Android自启动设置页面${result ? '成功' : '失败'}');
        return result;
      } else {
        XlyLogger.warning('无法打开Android自启动设置页面');
        return false;
      }
    } catch (e) {
      XlyLogger.error('设置Android平台开机自启动时出错', e);
      return false;
    }
  }

  /// 检查是否支持开机自启动功能
  static bool isSupported() {
    if (kIsWeb) return false;
    return MyPlatform.isDesktop || Platform.isAndroid;
  }
}
