import 'package:flutter/foundation.dart';

/// Xly包的统一日志工具
///
/// 用于控制包内部的调试日志输出，避免污染用户项目的日志。
///
/// 使用方式:
/// ```dart
/// // 在 MyApp.initialize() 中初始化
/// XlyLogger.init(enableDebugLogging: true);
///
/// // 在包内部使用
/// XlyLogger.debug('调试信息');
/// XlyLogger.info('一般信息');
/// XlyLogger.warning('警告信息');
/// XlyLogger.error('错误信息');
/// ```
class XlyLogger {
  /// 是否启用调试日志（默认关闭，避免污染用户日志）
  static bool _enabled = false;

  /// 日志前缀，便于识别来源
  static const String _prefix = '[Xly]';

  /// 初始化日志系统
  ///
  /// [enabled] 是否启用调试日志输出
  static void init({required bool enabled}) {
    _enabled = enabled;
    if (_enabled) {
      debugPrint('$_prefix 调试日志已启用');
    }
  }

  /// 调试级别日志（默认关闭，用于详细的内部状态跟踪）
  ///
  /// 示例: 智能停靠的位置检测、鼠标追踪等
  static void debug(String message) {
    if (_enabled) {
      debugPrint('$_prefix [DEBUG] $message');
    }
  }

  /// 信息级别日志（默认关闭，用于一般性信息）
  ///
  /// 示例: 服务初始化成功、功能启用等
  static void info(String message) {
    if (_enabled) {
      debugPrint('$_prefix [INFO] $message');
    }
  }

  /// 警告级别日志（默认关闭，用于潜在问题）
  ///
  /// 示例: 配置不当、降级处理等
  static void warning(String message) {
    if (_enabled) {
      debugPrint('$_prefix [WARNING] $message');
    }
  }

  /// 错误级别日志（始终输出，用于严重错误）
  ///
  /// 注意: 错误日志不受 _enabled 控制，始终输出
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('$_prefix [ERROR] $message');
    if (error != null) {
      debugPrint('$_prefix [ERROR] Exception: $error');
    }
    if (stackTrace != null) {
      debugPrint('$_prefix [ERROR] StackTrace:\n$stackTrace');
    }
  }

  /// 检查是否启用了调试日志
  static bool get isEnabled => _enabled;
}
