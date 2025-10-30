import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:window_manager/window_manager.dart';

import 'logger.dart';

/// 平台工具类，提供跨平台的文件操作、权限管理和窗口控制等功能
class MyPlatform {
  const MyPlatform._();

  /// 判断是否为桌面操作系统
  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  /// 判断是否为移动操作系统
  static bool get isMobile =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isFuchsia);

  /// 判断是否为Web平台
  static bool get isWeb => kIsWeb;

  // === 桌面平台细分检测 ===

  /// 判断是否为Windows平台
  static bool get isWindows => !kIsWeb && Platform.isWindows;

  /// 判断是否为macOS平台
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  /// 判断是否为Linux平台
  static bool get isLinux => !kIsWeb && Platform.isLinux;

  // === 移动平台细分检测 ===

  /// 判断是否为Android平台
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// 判断是否为iOS平台
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// 判断是否为Fuchsia平台
  static bool get isFuchsia => !kIsWeb && Platform.isFuchsia;

  /// 获取当前平台名称
  ///
  /// 返回当前运行平台的友好名称
  static String get platformName {
    if (kIsWeb) return 'Web';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isFuchsia) return 'Fuchsia';
    return 'Unknown';
  }

  /// 请求指定权限
  ///
  /// [permission] 需要请求的权限
  /// 返回是否获取权限成功
  ///
  /// 注意：Web平台和桌面平台将直接返回 true
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

  /// 获取应用程序目录
  ///
  /// Web平台会抛出 [UnsupportedError]
  /// 移动平台返回应用文档目录
  /// 桌面平台返回可执行文件所在目录
  static Future<String> getAppDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError('Web平台不支持获取应用程序目录');
    }

    try {
      if (isDesktop) {
        return path.dirname(Platform.resolvedExecutable);
      } else {
        final appDocDir = await getApplicationDocumentsDirectory();
        return appDocDir.path;
      }
    } catch (e) {
      XlyLogger.error('获取应用程序目录时出错', e);
      rethrow;
    }
  }

  /// 获取指定文件对象
  ///
  /// [fileName] 文件名
  /// [externalPath] 是否使用外部存储路径（仅Android平台有效）
  ///
  /// Web平台会抛出 [UnsupportedError]
  static Future<File> getFile(String fileName,
      [bool externalPath = true]) async {
    if (kIsWeb) {
      throw UnsupportedError('Web平台不支持文件操作');
    }
    return File(await getFilePath(fileName, externalPath));
  }

  /// 获取外部存储路径（仅Android平台）
  ///
  /// 非Android平台或获取失败时返回 null
  static Future<String?> getExternalStoragePath() async {
    if (!Platform.isAndroid) return null;

    try {
      final List<Directory>? externalStorageDirectories =
          await getExternalStorageDirectories();
      if (externalStorageDirectories != null &&
          externalStorageDirectories.isNotEmpty) {
        return externalStorageDirectories[0].path;
      }
    } catch (e) {
      XlyLogger.error('获取外部存储路径时出错', e);
    }
    return null;
  }

  /// 获取文件完整路径
  ///
  /// [fileName] 文件名
  /// [externalPath] 是否使用外部存储路径（仅Android平台有效）
  ///
  /// Web平台会抛出 [UnsupportedError]
  static Future<String> getFilePath(String fileName,
      [bool externalPath = false]) async {
    if (kIsWeb) {
      throw UnsupportedError('Web平台不支持文件操作');
    }

    try {
      String appDir;
      if (externalPath && Platform.isAndroid) {
        appDir = await getExternalStoragePath() ?? await getAppDirectory();
      } else {
        appDir = await getAppDirectory();
      }
      return path.join(appDir, fileName);
    } catch (e) {
      XlyLogger.error('获取文件路径时出错', e);
      rethrow;
    }
  }

  /// 从assets复制文件到应用目录
  ///
  /// [fileName] 文件名，必须与assets中的文件名一致
  /// [externalPath] 是否使用外部存储路径（仅Android平台有效）
  ///
  /// Web平台会抛出 [UnsupportedError]
  static Future<File> getFilePastedFromAssets(String fileName,
      [bool externalPath = false]) async {
    if (kIsWeb) {
      throw UnsupportedError('Web平台不支持文件操作');
    }

    try {
      final targetFile = await getFile(fileName, externalPath);

      if (!await targetFile.exists()) {
        final assetsPath = 'assets/$fileName';
        final byteData = await rootBundle.load(assetsPath);

        if (Platform.isAndroid) {
          try {
            await Process.run('chmod', ['777', targetFile.path]);
          } catch (e) {
            XlyLogger.error('无法设置文件权限', e);
          }
        }
        await targetFile.writeAsBytes(byteData.buffer.asUint8List());
      }

      return targetFile;
    } catch (e) {
      XlyLogger.error('从assets复制文件时出错', e);
      rethrow;
    }
  }

  /// 获取延迟时间的显示文本和颜色
  ///
  /// [delay] 延迟时间（毫秒）
  /// 返回包含显示文本和颜色的记录
  static ({String text, Color color}) getMsDelayTextAndColor(BigInt? delay) {
    String displayText = '--';
    Color textColor = Colors.grey;

    if (delay == null) {
      return (text: displayText, color: textColor);
    }

    final delayValue = delay.toInt();

    if (delayValue < 0) {
      displayText = '--';
      textColor = Colors.grey;
    } else {
      displayText = '${delayValue}ms';
      if (delayValue < 100) {
        textColor = Colors.green;
      } else if (delayValue < 500) {
        textColor = Colors.orange;
      } else {
        textColor = Colors.red;
      }
    }

    return (text: displayText, color: textColor);
  }

  /// 创建一个显示延迟时间的Widget
  ///
  /// [pingTimeFuture] 延迟时间Future
  /// [fontSize] 字体大小
  /// [textAlign] 文本对齐方式
  static Widget buildDelayDisplay({
    required Future<BigInt?>? pingTimeFuture,
    double? fontSize,
    TextAlign textAlign = TextAlign.end,
  }) {
    return FutureBuilder<BigInt?>(
      future: pingTimeFuture,
      builder: (context, snapshot) {
        final delayInfo = getMsDelayTextAndColor(
            snapshot.connectionState == ConnectionState.waiting
                ? null
                : snapshot.data);

        return Text(
          delayInfo.text,
          textAlign: textAlign,
          style: TextStyle(
            fontSize: fontSize,
            color: delayInfo.color,
          ),
        );
      },
    );
  }
}
