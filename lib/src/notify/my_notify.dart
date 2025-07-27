import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notify_enums.dart';

/// MyNotify 系统通知管理器
///
/// 基于flutter_local_notifications包的封装，提供跨平台的系统通知功能
/// 作为GetxService使用，享受全局生命周期管理
///
/// ## 主要功能
/// - 显示系统通知
/// - 定时通知
/// - 通知权限管理
/// - 跨平台支持（Android、iOS、macOS、Windows、Linux）
///
/// ## 基础使用
/// ```dart
/// // 1. 在 main.dart 中注册服务
/// void main() async {
///   await MyApp.initialize(
///     services: [
///       MyService<MyNotify>(
///         service: () => MyNotify(),
///         permanent: true,
///       ),
///     ],
///   );
/// }
///
/// // 2. 在任何地方使用
/// final myNotify = MyNotify.to;
/// await myNotify.show("标题", "消息内容");
/// ```
class MyNotify extends GetxService {
  static MyNotify get to => Get.find();

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  final _isInitialized = false.obs;
  final _permissionGranted = false.obs;

  /// 是否已初始化
  bool get isInitialized => _isInitialized.value;

  /// 是否已获得通知权限
  bool get permissionGranted => _permissionGranted.value;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  /// 初始化通知插件
  Future<void> _initialize() async {
    try {
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      // 初始化时区数据
      tz.initializeTimeZones();

      // 初始化各平台设置
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const LinuxInitializationSettings initializationSettingsLinux =
          LinuxInitializationSettings(
        defaultActionName: 'Open notification',
      );

      const WindowsInitializationSettings initializationSettingsWindows =
          WindowsInitializationSettings(
        appName: 'XLY Flutter Package',
        appUserModelId: 'com.xly.flutter.package',
        guid: 'a5b3c4d5-e6f7-8901-2345-6789abcdef01',
      );

      final InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
        macOS: initializationSettingsDarwin,
        linux: initializationSettingsLinux,
        windows: initializationSettingsWindows,
      );

      // 初始化插件
      final bool? initialized = await _flutterLocalNotificationsPlugin
          .initialize(initializationSettings,
              onDidReceiveNotificationResponse:
                  _onDidReceiveNotificationResponse);

      if (initialized == true) {
        _isInitialized.value = true;

        // 检查权限状态
        await _checkPermissions();

        if (kDebugMode) {
          print('MyNotify: 通知插件初始化成功');
        }
      } else {
        if (kDebugMode) {
          print('MyNotify: 通知插件初始化失败');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('MyNotify: 初始化异常: $e');
      }
    }
  }

  /// 检查通知权限
  Future<void> _checkPermissions() async {
    try {
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin>();

        final bool? granted =
            await androidImplementation?.areNotificationsEnabled();
        _permissionGranted.value = granted ?? false;
      } else if (Platform.isIOS || Platform.isMacOS) {
        final IOSFlutterLocalNotificationsPlugin? iosImplementation =
            _flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin>();

        final bool? granted = await iosImplementation?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        _permissionGranted.value = granted ?? false;
      } else {
        // 其他平台默认认为有权限
        _permissionGranted.value = true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('MyNotify: 检查权限失败: $e');
      }
      _permissionGranted.value = false;
    }
  }

  /// 通知点击回调
  void _onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) {
    if (kDebugMode) {
      print(
          'MyNotify: 通知被点击 - ID: ${notificationResponse.id}, Payload: ${notificationResponse.payload}');
    }

    // 这里可以根据需要处理通知点击事件
    // 例如导航到特定页面或执行特定操作
  }

  /// 请求通知权限
  Future<bool> requestPermissions() async {
    if (!_isInitialized.value) {
      if (kDebugMode) {
        print('MyNotify: 插件未初始化，无法请求权限');
      }
      return false;
    }

    try {
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin>();

        final bool? granted =
            await androidImplementation?.requestNotificationsPermission();
        _permissionGranted.value = granted ?? false;
        return _permissionGranted.value;
      } else if (Platform.isIOS || Platform.isMacOS) {
        final IOSFlutterLocalNotificationsPlugin? iosImplementation =
            _flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin>();

        final bool? granted = await iosImplementation?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        _permissionGranted.value = granted ?? false;
        return _permissionGranted.value;
      }

      return true; // 其他平台默认有权限
    } catch (e) {
      if (kDebugMode) {
        print('MyNotify: 请求权限失败: $e');
      }
      return false;
    }
  }

  /// 显示通知
  ///
  /// [title] 通知标题
  /// [body] 通知内容
  /// [type] 通知类型，影响图标和样式
  /// [id] 通知ID，默认为0，相同ID会覆盖之前的通知
  /// [payload] 点击通知时传递的数据
  Future<void> show(
    String title,
    String body, {
    MyNotifyType type = MyNotifyType.info,
    int id = 0,
    String? payload,
  }) async {
    if (!_isInitialized.value) {
      if (kDebugMode) {
        print('MyNotify: 插件未初始化，无法显示通知');
      }
      return;
    }

    if (!_permissionGranted.value) {
      if (kDebugMode) {
        print('MyNotify: 没有通知权限，尝试请求权限');
      }
      final granted = await requestPermissions();
      if (!granted) {
        if (kDebugMode) {
          print('MyNotify: 权限请求失败，无法显示通知');
        }
        return;
      }
    }

    try {
      final NotificationDetails notificationDetails =
          _buildNotificationDetails(type);

      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      if (kDebugMode) {
        print('MyNotify: 通知显示成功 - $title: $body');
      }
    } catch (e) {
      if (kDebugMode) {
        print('MyNotify: 显示通知失败: $e');
      }
    }
  }

  /// 定时显示通知
  ///
  /// [title] 通知标题
  /// [body] 通知内容
  /// [scheduledDate] 预定显示时间
  /// [type] 通知类型
  /// [id] 通知ID
  /// [payload] 点击通知时传递的数据
  Future<void> schedule(
    String title,
    String body,
    DateTime scheduledDate, {
    MyNotifyType type = MyNotifyType.info,
    int id = 0,
    String? payload,
  }) async {
    if (!_isInitialized.value) {
      if (kDebugMode) {
        print('MyNotify: 插件未初始化，无法定时通知');
      }
      return;
    }

    if (!_permissionGranted.value) {
      final granted = await requestPermissions();
      if (!granted) {
        if (kDebugMode) {
          print('MyNotify: 权限请求失败，无法定时通知');
        }
        return;
      }
    }

    try {
      final NotificationDetails notificationDetails =
          _buildNotificationDetails(type);
      final tz.TZDateTime tzScheduledDate =
          tz.TZDateTime.from(scheduledDate, tz.local);

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        notificationDetails,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      if (kDebugMode) {
        print('MyNotify: 定时通知设置成功 - $title: $body, 时间: $scheduledDate');
      }
    } catch (e) {
      if (kDebugMode) {
        print('MyNotify: 设置定时通知失败: $e');
      }
    }
  }

  /// 构建通知详情
  NotificationDetails _buildNotificationDetails(MyNotifyType type) {
    // Android 通知详情
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'xly_notify_channel',
      'XLY 通知',
      channelDescription: 'XLY Flutter Package 通知频道',
      importance: _getAndroidImportance(type),
      priority: _getAndroidPriority(type),
      enableVibration: true,
      playSound: true,
    );

    // iOS/macOS 通知详情
    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // Linux 通知详情
    final LinuxNotificationDetails linuxDetails = LinuxNotificationDetails(
      urgency: _getLinuxUrgency(type),
    );

    // Windows 通知详情
    const WindowsNotificationDetails windowsDetails =
        WindowsNotificationDetails();

    return NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
      linux: linuxDetails,
      windows: windowsDetails,
    );
  }

  /// 获取Android重要性级别
  Importance _getAndroidImportance(MyNotifyType type) {
    switch (type) {
      case MyNotifyType.error:
        return Importance.max;
      case MyNotifyType.warning:
        return Importance.high;
      case MyNotifyType.success:
        return Importance.high;
      case MyNotifyType.info:
        return Importance.defaultImportance;
    }
  }

  /// 获取Android优先级
  Priority _getAndroidPriority(MyNotifyType type) {
    switch (type) {
      case MyNotifyType.error:
        return Priority.max;
      case MyNotifyType.warning:
        return Priority.high;
      case MyNotifyType.success:
        return Priority.high;
      case MyNotifyType.info:
        return Priority.defaultPriority;
    }
  }

  /// 获取Linux紧急程度
  LinuxNotificationUrgency _getLinuxUrgency(MyNotifyType type) {
    switch (type) {
      case MyNotifyType.error:
        return LinuxNotificationUrgency.critical;
      case MyNotifyType.warning:
        return LinuxNotificationUrgency.normal;
      case MyNotifyType.success:
        return LinuxNotificationUrgency.normal;
      case MyNotifyType.info:
        return LinuxNotificationUrgency.low;
    }
  }

  /// 取消指定ID的通知
  Future<void> cancel(int id) async {
    if (!_isInitialized.value) return;

    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
      if (kDebugMode) {
        print('MyNotify: 已取消通知 ID: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        print('MyNotify: 取消通知失败: $e');
      }
    }
  }

  /// 取消所有通知
  Future<void> cancelAll() async {
    if (!_isInitialized.value) return;

    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      if (kDebugMode) {
        print('MyNotify: 已取消所有通知');
      }
    } catch (e) {
      if (kDebugMode) {
        print('MyNotify: 取消所有通知失败: $e');
      }
    }
  }

  /// 获取待处理的通知请求
  Future<List<PendingNotificationRequest>>
      getPendingNotificationRequests() async {
    if (!_isInitialized.value) return [];

    try {
      return await _flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
    } catch (e) {
      if (kDebugMode) {
        print('MyNotify: 获取待处理通知失败: $e');
      }
      return [];
    }
  }

  /// 获取活跃的通知
  Future<List<ActiveNotification>> getActiveNotifications() async {
    if (!_isInitialized.value) return [];

    try {
      return await _flutterLocalNotificationsPlugin.getActiveNotifications();
    } catch (e) {
      if (kDebugMode) {
        print('MyNotify: 获取活跃通知失败: $e');
      }
      return [];
    }
  }
}
