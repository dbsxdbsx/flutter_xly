import 'dart:async';
import 'dart:io';

import 'logger.dart';

/// 单实例管理器
/// 使用本地TCP端口锁确保应用只能运行一个实例
class SingleInstanceManager {
  static SingleInstanceManager? _instance;
  static SingleInstanceManager get instance =>
      _instance ??= SingleInstanceManager._();

  SingleInstanceManager._();

  HttpServer? _server;
  int? _port;
  FutureOr<void> Function()? _onActivateCallback;
  bool _isRunning = false;

  /// 检查并初始化单实例
  ///
  /// [instanceKey] 实例唯一标识，默认使用应用名称
  /// [activateExisting] 当检测到已有实例时，是否激活现有实例
  /// [onActivate] 当收到激活请求时的回调函数
  ///
  /// 返回 true 表示当前是首个实例，可以继续运行
  /// 返回 false 表示已有实例在运行，当前实例应该退出
  Future<bool> initialize({
    required String instanceKey,
    bool activateExisting = true,
    FutureOr<void> Function()? onActivate,
  }) async {
    // 移动端和Web端直接返回true，不支持单实例
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      return true;
    }

    _onActivateCallback = onActivate;
    _port = _generatePort(instanceKey);

    try {
      // 尝试绑定端口
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, _port!);
      _isRunning = true;
      // 后台启动请求循环，避免阻塞初始化从而卡住窗口创建
      unawaited(_setupServer());

      XlyLogger.info('SingleInstance: 首个实例启动，监听端口 $_port');

      return true;
    } catch (e) {
      // 端口被占用，说明已有实例在运行
      if (activateExisting) {
        await _activateExistingInstance();
      }

      XlyLogger.info('SingleInstance: 检测到已有实例在运行，当前实例将退出');

      return false;
    }
  }

  /// 根据实例键生成稳定的端口号
  int _generatePort(String instanceKey) {
    // 使用简单的哈希算法将字符串映射到30000-39999端口范围
    int hash = instanceKey.hashCode;
    return 30000 + (hash.abs() % 10000);
  }

  /// 设置HTTP服务器监听激活请求
  Future<void> _setupServer() async {
    if (_server == null) return;

    await for (HttpRequest request in _server!) {
      try {
        if (request.method == 'POST' && request.uri.path == '/activate') {
          // 收到激活请求
          if (_onActivateCallback != null) {
            try {
              await _onActivateCallback!();
            } catch (e, s) {
              XlyLogger.error('SingleInstance: onActivate error: $e', s);
            }
          }

          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write('{"status":"activated"}');
        } else {
          request.response
            ..statusCode = HttpStatus.notFound
            ..write('Not Found');
        }

        await request.response.close();
      } catch (e) {
        XlyLogger.error('SingleInstance: 处理请求时出错', e);
        try {
          request.response
            ..statusCode = HttpStatus.internalServerError
            ..write('Internal Server Error');
          await request.response.close();
        } catch (_) {
          // 忽略关闭响应时的错误
        }
      }
    }
  }

  /// 激活已存在的实例
  Future<void> _activateExistingInstance() async {
    if (_port == null) return;

    try {
      final client = HttpClient();
      final request = await client.postUrl(
        Uri.parse('http://127.0.0.1:$_port/activate'),
      );
      request.headers.contentType = ContentType.json;
      request.write('{"action":"activate"}');

      final response = await request.close();
      await response.drain();
      client.close();

      XlyLogger.info('SingleInstance: 已发送激活请求到现有实例');
    } catch (e) {
      XlyLogger.error('SingleInstance: 激活现有实例失败', e);
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
      _isRunning = false;

      XlyLogger.info('SingleInstance: 单实例服务器已关闭');
    }
  }

  /// 检查单实例是否正在运行
  bool get isRunning => _isRunning;

  /// 获取当前监听的端口号
  int? get port => _port;
}
