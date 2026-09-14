/// 桌面端启动时窗口的出示策略（与任务栏策略、关闭回托盘正交）。
///
/// [showWindowOnInit] 只表示启动结束后窗口在不在；
/// [deferShowUntilFirstFrame] 只表示「若要显示，是否等 Flutter 首帧再 show」。
class DesktopWindowLaunch {
  const DesktopWindowLaunch({
    required this.showDuringWindowInit,
    required this.showAfterFirstFrame,
  });

  /// 在 `windowManager` 初始化阶段就 `show()`。
  final bool showDuringWindowInit;

  /// 等 Flutter 首帧提交后再 `show()`（防空窗；传入启动叠层时默认走这条）。
  final bool showAfterFirstFrame;

  /// 启动后保持隐藏，直到调用方或托盘主动出示。
  bool get stayHidden => !showDuringWindowInit && !showAfterFirstFrame;

  /// 解析桌面窗口启动策略。
  ///
  /// - 非桌面：两条出示路径都关闭（没有 `window_manager`）。
  /// - [showWindowOnInit] 为 `false`：保持隐藏；[deferShowUntilFirstFrame] 被忽略。
  /// - 否则：未显式传 defer 时，有启动叠层则等首帧，没有则立即显示。
  factory DesktopWindowLaunch.resolve({
    required bool isDesktop,
    required bool showWindowOnInit,
    required bool hasSplash,
    bool? deferShowUntilFirstFrame,
  }) {
    if (!isDesktop || !showWindowOnInit) {
      return const DesktopWindowLaunch(
        showDuringWindowInit: false,
        showAfterFirstFrame: false,
      );
    }
    final defer = deferShowUntilFirstFrame ?? hasSplash;
    return DesktopWindowLaunch(
      showDuringWindowInit: !defer,
      showAfterFirstFrame: defer,
    );
  }
}
