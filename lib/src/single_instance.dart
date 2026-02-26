import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'logger.dart';

/// 单实例管理器
///
/// 使用本地 TCP 端口锁确保应用只能运行一个实例。
///
/// ## 智能僵尸检测
/// 当端口被占用时，不会盲目假设"已有实例在运行"，而是会：
/// 1. 尝试与旧实例通信（健康检查）
/// 2. 如果旧实例响应 → 确认是真实运行的实例，激活它并退出
/// 3. 如果旧实例无响应 → 判定为僵尸进程/残留端口，等待重试接管
/// 4. 重试仍失败 → 以警告方式放行，避免阻塞用户
///
/// 这使得开发调试时无需手动配置 `singleInstance: false`，也不会因为
/// 上一次调试的僵尸进程而导致窗口无法显示。
class SingleInstanceManager {
  static SingleInstanceManager? _instance;
  static SingleInstanceManager get instance =>
      _instance ??= SingleInstanceManager._();

  SingleInstanceManager._();

  HttpServer? _server;
  int? _port;
  FutureOr<void> Function()? _onActivateCallback;
  bool _isRunning = false;

  /// 健康检查路径和期望响应
  static const _healthPath = '/health';
  static const _healthResponse = '{"status":"alive"}';
  static const _activatePath = '/activate';

  /// 重试配置
  static const _maxRetries = 3;
  static const _retryBaseDelay = Duration(milliseconds: 500);

  /// 健康检查/激活的超时时间
  static const _probeTimeout = Duration(seconds: 2);

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
    // 移动端和 Web 端直接返回 true，不支持单实例
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      return true;
    }

    _onActivateCallback = onActivate;
    _port = _generatePort(instanceKey);

    // 第一次尝试绑定端口
    if (await _tryBind()) {
      XlyLogger.info('SingleInstance: 首个实例启动，监听端口 $_port');
      return true;
    }

    // 端口被占用——验证旧实例是否真的活着
    XlyLogger.info('SingleInstance: 端口 $_port 被占用，正在验证旧实例状态...');

    final isAlive = await _probeExistingInstance();

    if (isAlive) {
      // 旧实例确实在运行
      if (activateExisting) {
        await _activateExistingInstance();
      }
      XlyLogger.info('SingleInstance: 已确认旧实例存活，当前实例将退出');
      return false;
    }

    // 旧实例已死（僵尸进程/残留端口）——等待并重试接管
    XlyLogger.info('SingleInstance: 旧实例无响应（僵尸/残留端口），尝试重试接管...');

    for (int i = 0; i < _maxRetries; i++) {
      final delay = _retryBaseDelay * (i + 1);
      XlyLogger.info(
        'SingleInstance: 第 ${i + 1}/$_maxRetries 次重试，等待 ${delay.inMilliseconds}ms...',
      );
      await Future.delayed(delay);

      if (await _tryBind()) {
        XlyLogger.info('SingleInstance: 重试成功，端口已接管，监听端口 $_port');
        return true;
      }
    }

    // 所有重试都失败——以警告方式放行，避免阻塞用户
    XlyLogger.warning(
      'SingleInstance: 无法绑定端口 $_port（旧实例无响应但端口未释放），'
      '以降级模式继续启动。如果确实有另一个实例在运行，可能会出现端口冲突。',
    );
    return true;
  }

  /// 尝试绑定端口，成功则启动 HTTP 服务器
  Future<bool> _tryBind() async {
    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, _port!);
      _isRunning = true;
      // 后台启动请求循环，避免阻塞初始化从而卡住窗口创建
      unawaited(_setupServer());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 探测旧实例是否真正存活（通过健康检查端点）
  ///
  /// 返回 true 表示旧实例活着，false 表示已死
  Future<bool> _probeExistingInstance() async {
    if (_port == null) return false;

    try {
      final client = HttpClient();
      client.connectionTimeout = _probeTimeout;

      final request = await client
          .getUrl(Uri.parse('http://127.0.0.1:$_port$_healthPath'))
          .timeout(_probeTimeout);

      final response = await request.close().timeout(_probeTimeout);
      final body =
          await response.transform(utf8.decoder).join().timeout(_probeTimeout);
      client.close(force: true);

      // 只有收到正确的健康响应才认为实例存活
      return response.statusCode == HttpStatus.ok && body.contains('alive');
    } catch (e) {
      // 连接失败/超时/拒绝 → 旧实例已死
      XlyLogger.info('SingleInstance: 健康检查失败 ($e)，判定旧实例已失效');
      return false;
    }
  }

  /// 根据实例键生成稳定的端口号
  int _generatePort(String instanceKey) {
    // 使用简单的哈希算法将字符串映射到 30000-39999 端口范围
    int hash = instanceKey.hashCode;
    return 30000 + (hash.abs() % 10000);
  }

  /// 设置 HTTP 服务器监听激活请求和健康检查
  Future<void> _setupServer() async {
    if (_server == null) return;

    await for (HttpRequest request in _server!) {
      try {
        if (request.method == 'GET' && request.uri.path == _healthPath) {
          // 健康检查端点——让新实例验证我们是否存活
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(_healthResponse);
        } else if (request.method == 'POST' &&
            request.uri.path == _activatePath) {
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
      client.connectionTimeout = _probeTimeout;

      final request = await client
          .postUrl(Uri.parse('http://127.0.0.1:$_port$_activatePath'))
          .timeout(_probeTimeout);
      request.headers.contentType = ContentType.json;
      request.write('{"action":"activate"}');

      final response = await request.close().timeout(_probeTimeout);
      await response.drain();
      client.close(force: true);

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
