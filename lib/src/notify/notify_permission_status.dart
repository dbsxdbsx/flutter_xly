import 'notify_enums.dart';

/// 通知权限 / 展示能力状态。
///
/// Windows 桌面端没有移动端那种运行时授权弹窗。这里明确区分：
/// - 通知是否能提交到 Windows；
/// - 横幅是否会被专注助手 / 勿扰模式静默。
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

  /// 当前已知条件是否允许向系统提交通知。
  ///
  /// 保留旧字段名以兼容现有调用；Windows 专注助手开启时仍可为 true，因为
  /// 通知通常仍可进入通知中心，只是不保证弹出横幅。
  final bool canShowNotifications;

  bool get canSubmitNotifications => canShowNotifications;

  /// 当前已知条件是否允许立即显示横幅。
  bool get canShowBanner {
    if (!canSubmitNotifications) return false;
    if (platform != 'windows') return true;
    if (windowsShowBanner == false) return false;
    return windowsFocusAssistMode !=
            MyNotifyWindowsFocusAssistMode.priorityOnly &&
        windowsFocusAssistMode != MyNotifyWindowsFocusAssistMode.alarmsOnly;
  }

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

  /// 影响系统提交或横幅呈现的诊断信息。
  final List<String> issues;

  String get summary {
    if (canSubmitNotifications && issues.isEmpty) return '系统通知可提交并可显示横幅';
    if (canSubmitNotifications) {
      return '系统通知可提交，但横幅可能被静默：\n${issues.join('\n')}';
    }
    if (issues.isEmpty) return '通知条件未完全确认';
    return issues.join('\n');
  }
}
