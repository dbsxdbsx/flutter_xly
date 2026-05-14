import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../logger.dart';
import '../toast/toast.dart';
import 'notify_enums.dart';
import 'notify_permission_status.dart';
import 'windows_notification_identity.dart';

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
  MyNotify({
    this.appName,
    this.windowsAppUserModelId,
    this.windowsGuid,
    this.windowsIconPath,
    this.fallbackPolicy = MyNotifyFallbackPolicy.windowsOnly,
  });

  static MyNotify get to {
    if (Get.isRegistered<MyNotify>()) return Get.find<MyNotify>();

    XlyLogger.diagnostic('MyNotify: 未发现已注册服务，自动创建默认通知服务（下游零配置）');
    return Get.put<MyNotify>(MyNotify(), permanent: true);
  }

  /// 通知中显示的应用名；不传时自动从 PackageInfo / EXE 名称推导。
  final String? appName;

  /// Windows AppUserModelID；通常无需配置，不传时由 XLY 自动生成。
  final String? windowsAppUserModelId;

  /// Windows 通知激活回调 GUID；通常无需配置，不传时由 XLY 自动生成稳定值。
  final String? windowsGuid;

  /// Windows 通知图标路径；通常无需配置，不传时使用当前 EXE 图标兜底。
  final String? windowsIconPath;

  /// 系统 Toast 被 Windows 策略静默时，是否额外显示 XLY 应用内提示。
  final MyNotifyFallbackPolicy fallbackPolicy;

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  final _isInitialized = false.obs;
  final _permissionGranted = false.obs;
  Future<void>? _initializationFuture;
  WindowsNotificationIdentity? _windowsIdentity;

  /// 是否已初始化
  bool get isInitialized => _isInitialized.value;

  /// 是否已获得通知权限
  bool get permissionGranted => _permissionGranted.value;

  @override
  void onInit() {
    super.onInit();
    _initializationFuture = _initialize();
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
          LinuxInitializationSettings(defaultActionName: 'Open notification');

      final WindowsInitializationSettings? initializationSettingsWindows =
          await _buildWindowsInitializationSettings();

      final InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
        macOS: initializationSettingsDarwin,
        linux: initializationSettingsLinux,
        windows: initializationSettingsWindows,
      );

      // 初始化插件
      final bool? initialized =
          await _flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      );

      if (initialized == true) {
        _isInitialized.value = true;

        // 检查权限状态
        await _checkPermissions();

        XlyLogger.info('MyNotify: 通知插件初始化成功');
      } else {
        XlyLogger.warning('MyNotify: 通知插件初始化失败');
      }
    } catch (e) {
      XlyLogger.error('MyNotify: 初始化异常', e);
    }
  }

  Future<WindowsInitializationSettings?>
      _buildWindowsInitializationSettings() async {
    if (!Platform.isWindows) return null;

    final identity = await WindowsNotificationIdentityManager.prepare(
      appName: appName,
      appUserModelId: windowsAppUserModelId,
      guid: windowsGuid,
      iconPath: windowsIconPath,
    );
    _windowsIdentity = identity;
    if (identity == null) return null;

    XlyLogger.diagnostic(
      'MyNotify(Windows): 使用系统通知身份初始化插件，'
      'AUMID=${identity.appUserModelId}, GUID=${identity.guid}',
    );

    return WindowsInitializationSettings(
      appName: identity.appName,
      appUserModelId: identity.appUserModelId,
      guid: identity.guid,
      iconPath: identity.iconPath,
    );
  }

  Future<void> _ensureInitialized() async {
    if (_isInitialized.value) return;
    final initializing = _initializationFuture ??= _initialize();
    await initializing;
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
      XlyLogger.error('MyNotify: 检查权限失败', e);
      _permissionGranted.value = false;
    }
  }

  /// 通知点击回调
  void _onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse,
  ) {
    XlyLogger.debug(
      'MyNotify: 通知被点击 - ID: ${notificationResponse.id}, Payload: ${notificationResponse.payload}',
    );

    // 这里可以根据需要处理通知点击事件
    // 例如导航到特定页面或执行特定操作
  }

  /// 请求通知权限
  Future<bool> requestPermissions({
    bool openSettingsIfNeeded = false,
    bool includeGlobalWindowsSetting = true,
  }) async {
    await _ensureInitialized();

    if (!_isInitialized.value) {
      XlyLogger.warning('MyNotify: 插件未初始化，无法请求权限');
      return false;
    }

    try {
      if (Platform.isWindows) {
        final status = await ensurePermissions(
          openSettingsIfNeeded: openSettingsIfNeeded,
          includeGlobalWindowsSetting: includeGlobalWindowsSetting,
        );
        _permissionGranted.value = status.canShowNotifications;
        return _permissionGranted.value;
      }

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
      XlyLogger.error('MyNotify: 请求权限失败', e);
      return false;
    }
  }

  /// 检查通知展示条件。
  Future<MyNotifyPermissionStatus> checkPermissionStatus() async {
    await _ensureInitialized();

    if (Platform.isWindows) {
      final identity = _windowsIdentity;
      if (identity == null) {
        return const MyNotifyPermissionStatus(
          platform: 'windows',
          canShowNotifications: false,
          issues: ['Windows 通知身份尚未初始化'],
        );
      }

      final snapshot =
          WindowsNotificationIdentityManager.inspectNotificationSettings(
        identity.appUserModelId,
      );
      return MyNotifyPermissionStatus(
        platform: 'windows',
        canShowNotifications: snapshot.canShowNotifications,
        windowsGlobalToastEnabled: snapshot.globalToastEnabled,
        windowsAppNotificationsEnabled: snapshot.appNotificationsEnabled,
        windowsShowBanner: snapshot.showBanner,
        windowsShowInActionCenter: snapshot.showInActionCenter,
        windowsFocusAssistMode: snapshot.focusAssistMode,
        issues: snapshot.issues,
      );
    }

    return MyNotifyPermissionStatus(
      platform: Platform.operatingSystem,
      canShowNotifications: _permissionGranted.value,
      issues: _permissionGranted.value ? const [] : const ['通知权限未开启'],
    );
  }

  /// 尝试开启当前平台可控的通知展示条件。
  ///
  /// Windows 上会尽力开启全局 Toast 开关和当前应用通知/横幅/通知中心开关。
  /// 如果系统策略仍然拦截，可通过 [openSettingsIfNeeded] 打开系统设置页。
  Future<MyNotifyPermissionStatus> ensurePermissions({
    bool openSettingsIfNeeded = false,
    bool includeGlobalWindowsSetting = true,
  }) async {
    await _ensureInitialized();

    if (Platform.isWindows) {
      final identity = _windowsIdentity;
      if (identity == null) {
        return const MyNotifyPermissionStatus(
          platform: 'windows',
          canShowNotifications: false,
          issues: ['Windows 通知身份尚未初始化'],
        );
      }

      final snapshot =
          WindowsNotificationIdentityManager.ensureNotificationSettingsEnabled(
        identity.appUserModelId,
        includeGlobalWindowsSetting: includeGlobalWindowsSetting,
      );
      var openedSettings = false;
      if (!snapshot.canShowNotifications && openSettingsIfNeeded) {
        openedSettings = snapshot.focusAssistSuppressesNormalNotifications
            ? await WindowsNotificationIdentityManager
                .openSystemFocusAssistSettings()
            : await WindowsNotificationIdentityManager
                .openSystemNotificationSettings();
      }

      final status = MyNotifyPermissionStatus(
        platform: 'windows',
        canShowNotifications: snapshot.canShowNotifications,
        windowsGlobalToastEnabled: snapshot.globalToastEnabled,
        windowsAppNotificationsEnabled: snapshot.appNotificationsEnabled,
        windowsShowBanner: snapshot.showBanner,
        windowsShowInActionCenter: snapshot.showInActionCenter,
        windowsFocusAssistMode: snapshot.focusAssistMode,
        openedSystemSettings: openedSettings,
        issues: snapshot.issues,
      );
      _permissionGranted.value = status.canShowNotifications;
      if (status.canShowNotifications) {
        XlyLogger.diagnostic('MyNotify(Windows): 通知相关开关已开启。');
      } else {
        XlyLogger.diagnostic(
            'MyNotify(Windows): 通知相关开关仍未完全开启：${status.summary}');
      }
      return status;
    }

    final granted = await requestPermissions();
    return MyNotifyPermissionStatus(
      platform: Platform.operatingSystem,
      canShowNotifications: granted,
      issues: granted ? const [] : const ['通知权限未开启'],
    );
  }

  /// 打开系统通知设置页。
  Future<bool> openNotificationSettings() async {
    return openWindowsNotificationSettings();
  }

  /// 打开 Windows 通知设置页。
  Future<bool> openWindowsNotificationSettings() async {
    if (Platform.isWindows) {
      return WindowsNotificationIdentityManager
          .openSystemNotificationSettings();
    }
    return false;
  }

  /// 打开 Windows 专注助手 / 勿扰设置页。
  Future<bool> openWindowsFocusAssistSettings() async {
    if (Platform.isWindows) {
      return WindowsNotificationIdentityManager.openSystemFocusAssistSettings();
    }
    return false;
  }

  /// 检查 Windows 专注助手 / 勿扰模式状态。
  Future<MyNotifyWindowsFocusAssistMode> checkWindowsFocusAssistMode() async {
    if (!Platform.isWindows) {
      return MyNotifyWindowsFocusAssistMode.unavailable;
    }
    return WindowsNotificationIdentityManager.inspectFocusAssistMode();
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
    bool? showInAppFallback,
  }) async {
    await _ensureInitialized();

    if (!_isInitialized.value) {
      XlyLogger.diagnostic('MyNotify: 插件未初始化，无法显示通知');
      return;
    }

    if (!_permissionGranted.value) {
      XlyLogger.info('MyNotify: 没有通知权限，尝试请求权限');
      final granted = await requestPermissions();
      if (!granted) {
        XlyLogger.warning('MyNotify: 权限请求失败，无法显示通知');
        return;
      }
    }

    try {
      final NotificationDetails notificationDetails = _buildNotificationDetails(
        type,
      );

      await _flutterLocalNotificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );

      XlyLogger.info('MyNotify: 通知显示成功 - $title: $body');
      if (Platform.isWindows) {
        if (_windowsIdentity != null) {
          WindowsNotificationIdentityManager.logNotificationSettings(
            _windowsIdentity!.appUserModelId,
          );
        }
        XlyLogger.diagnostic(
          'MyNotify(Windows): Toast API 调用已完成。若没有看到右下角横幅，'
          '通常是 Windows 通知开关、勿扰/专注助手或系统策略拦截；'
          'AUMID=${_windowsIdentity?.appUserModelId ?? "(unknown)"}',
        );
      }
      _showInAppFallbackIfNeeded(
        title: title,
        body: body,
        type: type,
        override: showInAppFallback,
      );
    } catch (e) {
      XlyLogger.error('MyNotify: 显示通知失败', e);
      _showInAppFallbackIfNeeded(
        title: title,
        body: body,
        type: type,
        override: showInAppFallback ?? true,
      );
    }
  }

  void _showInAppFallbackIfNeeded({
    required String title,
    required String body,
    required MyNotifyType type,
    bool? override,
  }) {
    final shouldShow = override ?? _shouldShowInAppFallback;
    if (!shouldShow) return;

    final message = body.isEmpty ? title : '$title\n$body';
    try {
      switch (type) {
        case MyNotifyType.error:
          MyToast.showError(
            message,
            position: ToastPosition.bottom,
            stackPreviousToasts: true,
          );
          break;
        case MyNotifyType.warning:
          MyToast.showWarn(
            message,
            position: ToastPosition.bottom,
            stackPreviousToasts: true,
          );
          break;
        case MyNotifyType.success:
          MyToast.showOk(
            message,
            position: ToastPosition.bottom,
            stackPreviousToasts: true,
          );
          break;
        case MyNotifyType.info:
          MyToast.showInfo(
            message,
            position: ToastPosition.bottom,
            stackPreviousToasts: true,
          );
          break;
      }
      XlyLogger.diagnostic('MyNotify: 已显示 XLY 应用内通知兜底。');
    } catch (e) {
      XlyLogger.diagnostic('MyNotify: 显示应用内通知兜底失败: $e');
    }
  }

  bool get _shouldShowInAppFallback {
    switch (fallbackPolicy) {
      case MyNotifyFallbackPolicy.never:
        return false;
      case MyNotifyFallbackPolicy.windowsOnly:
        return Platform.isWindows;
      case MyNotifyFallbackPolicy.always:
        return true;
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
    await _ensureInitialized();

    if (!_isInitialized.value) {
      XlyLogger.diagnostic('MyNotify: 插件未初始化，无法定时通知');
      return;
    }

    if (!_permissionGranted.value) {
      final granted = await requestPermissions();
      if (!granted) {
        XlyLogger.warning('MyNotify: 权限请求失败，无法定时通知');
        return;
      }
    }

    try {
      final NotificationDetails notificationDetails = _buildNotificationDetails(
        type,
      );
      final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(
        scheduledDate,
        tz.local,
      );

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzScheduledDate,
        notificationDetails: notificationDetails,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      XlyLogger.info('MyNotify: 定时通知设置成功 - $title: $body, 时间: $scheduledDate');
    } catch (e) {
      XlyLogger.error('MyNotify: 设置定时通知失败', e);
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
    await _ensureInitialized();
    if (!_isInitialized.value) return;

    try {
      if (Platform.isWindows && _windowsIdentity?.hasPackageIdentity == false) {
        XlyLogger.diagnostic(
          'MyNotify(Windows): 当前为非 MSIX 模式，Windows 可能不会取消已显示的历史通知；'
          '仍会尝试取消待调度通知。ID: $id',
        );
      }
      await _flutterLocalNotificationsPlugin.cancel(id: id);
      XlyLogger.info('MyNotify: 已取消通知 ID: $id');
    } catch (e) {
      XlyLogger.error('MyNotify: 取消通知失败', e);
    }
  }

  /// 取消所有通知
  Future<void> cancelAll() async {
    await _ensureInitialized();
    if (!_isInitialized.value) return;

    try {
      if (Platform.isWindows && _windowsIdentity?.hasPackageIdentity == false) {
        XlyLogger.diagnostic(
          'MyNotify(Windows): 当前为非 MSIX 模式，Windows 可能不会清除已显示的历史通知；'
          '仍会尝试取消待调度通知。',
        );
      }
      await _flutterLocalNotificationsPlugin.cancelAll();
      XlyLogger.info('MyNotify: 已取消所有通知');
    } catch (e) {
      XlyLogger.error('MyNotify: 取消所有通知失败', e);
    }
  }

  /// 获取待处理的通知请求
  Future<List<PendingNotificationRequest>>
      getPendingNotificationRequests() async {
    await _ensureInitialized();
    if (!_isInitialized.value) return [];

    try {
      return await _flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
    } catch (e) {
      XlyLogger.error('MyNotify: 获取待处理通知失败', e);
      return [];
    }
  }

  /// 获取活跃的通知
  Future<List<ActiveNotification>> getActiveNotifications() async {
    await _ensureInitialized();
    if (!_isInitialized.value) return [];

    try {
      if (Platform.isWindows && _windowsIdentity?.hasPackageIdentity == false) {
        XlyLogger.diagnostic(
          'MyNotify(Windows): 当前为非 MSIX 模式，Windows 不允许读取已显示通知列表，'
          'getActiveNotifications 将返回空列表。',
        );
      }
      return await _flutterLocalNotificationsPlugin.getActiveNotifications();
    } catch (e) {
      XlyLogger.error('MyNotify: 获取活跃通知失败', e);
      return [];
    }
  }
}
