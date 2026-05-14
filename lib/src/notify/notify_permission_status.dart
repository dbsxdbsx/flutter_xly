import 'notify_enums.dart';

/// 通知权限 / 展示能力状态。
///
/// Windows 桌面端没有移动端那种运行时授权弹窗，这里的“权限”包含：
/// 系统全局 Toast 开关、当前应用通知开关、横幅开关、通知中心开关和专注助手状态等展示条件。
class MyNotifyPermissionStatus {
  const MyNotifyPermissionStatus({
    required this.canShowNotifications,
    required this.issues,
    this.platform,
    this.windowsGlobalToastEnabled,
    this.windowsAppNotificationsEnabled,
    this.windowsShowBanner,
    this.windowsShowInActionCenter,
    this.windowsFocusAssistMode,
    this.openedSystemSettings = false,
  });

  /// 当前已知条件是否允许显示通知横幅。
  final bool canShowNotifications;

  /// 当前平台名称，便于日志和 UI 展示。
  final String? platform;

  /// Windows 全局 Toast 开关。
  final bool? windowsGlobalToastEnabled;

  /// Windows 当前应用通知开关。
  final bool? windowsAppNotificationsEnabled;

  /// Windows 当前应用横幅开关。
  final bool? windowsShowBanner;

  /// Windows 当前应用通知中心开关。
  final bool? windowsShowInActionCenter;

  /// Windows 专注助手 / 勿扰模式状态。
  final MyNotifyWindowsFocusAssistMode? windowsFocusAssistMode;

  /// 是否已经打开系统通知设置页。
  final bool openedSystemSettings;

  /// 不满足通知展示条件的原因。
  final List<String> issues;

  String get summary {
    if (canShowNotifications) return '通知条件已开启';
    if (issues.isEmpty) return '通知条件未完全确认';
    return issues.join('\n');
  }
}
