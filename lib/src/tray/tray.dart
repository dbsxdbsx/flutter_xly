/// MyTray 托盘功能模块
///
/// 提供完整的系统托盘解决方案，作为全局服务使用，包括：
/// - 托盘图标管理
/// - 消息通知
/// - 窗口最小化到托盘
/// - 右键菜单管理
/// - 动态图标状态切换
///
/// ## 设计理念
/// - **完全可选**: 不需要托盘功能时完全不涉及
/// - **唯一初始化**: 只通过`MyService<MyTray>`初始化，避免配置冲突
/// - **智能默认**: iconPath可选，为空时自动查找默认应用图标
/// - **早期检测**: 图标缺失时提供详细错误信息和解决方案
/// - **全局服务**: 继承GetxService，享受全局生命周期管理
/// - **统一访问**: 通过MyTray.to进行所有操作
///
/// ## 基础使用
/// ```dart
/// // 1. 在 main.dart 中注册服务（唯一初始化方式）
/// void main() async {
///   await MyApp.initialize(
///     services: [
///       // 最简使用 - 自动使用默认应用图标
///       MyService<MyTray>(
///         service: () => MyTray(),
///       ),
///       // 或指定自定义图标
///       MyService<MyTray>(
///         service: () => MyTray(iconPath: "assets/icon.png"),
///       ),
///     ],
///   );
/// }
///
/// // 2. 在任何页面中使用
/// final tray = MyTray.to;
/// tray.minimizeToTray();
/// await MyNotify.to.show("标题", "消息"); // 系统通知见 package:xly/notify.dart
/// ```
///
/// ## 完整配置示例
/// ```dart
/// MyService<MyTray>(
///   service: () => MyTray(
///     iconPath: "assets/icon.png",        // 可选：托盘图标路径，为空时使用默认应用图标
///     tooltip: "My App",                  // 可选：悬停提示
///     hideTaskBarIcon: false,            // 可选：窗口可见时是否仍隐藏任务栏图标（默认false；
///                                        //       Windows 上隐藏会同时移出 Alt+Tab）
///     closeToTray: true,                 // 可选：点关闭按钮(Alt+F4/自渲染X)隐藏到托盘而非退出（默认true）
///                                        //       ⚠️ 务必提供“退出”菜单项，否则只能从任务管理器结束
///     menuItems: [                        // 可选：右键菜单
///       MyTrayMenuItem(
///         label: '显示主窗口',
///         onTap: () => MyTray.to.pop(),
///       ),
///       MyTrayMenuItem.separator(),
///       MyTrayMenuItem(
///         label: '退出应用',
///         onTap: () => MyApp.exit(),     // 自动保留“正在退出”托盘状态，进程结束前再销毁
///       ),
///     ],
///   ),
/// );
/// ```
///
/// ## 默认图标行为
/// 当 `iconPath` 为空时，MyTray 会自动使用各平台的标准应用图标：
///
/// - **Windows**: `windows/runner/resources/app_icon.ico`
/// - **macOS**: `macos/Runner/Assets.xcassets/AppIcon.appiconset/app-icon-512@2x.png`
/// - **Linux**: `snap/gui/app_icon.png`
///
/// **重要**：如果对应平台的默认图标文件不存在，应用将**无法启动**并显示详细错误信息。
///
/// **解决方案**：
/// 1. 【推荐】使用 `dart run xly:generate icon="source.png"` 自动生成所有平台图标
/// 2. 手动放置图标文件到对应路径
/// 3. 在构造函数中明确指定 `iconPath` 参数
///
/// ## 运行时操作
/// ```dart
/// final tray = MyTray.to;
///
/// // 基础操作
/// tray.hide();                        // 隐藏到托盘
/// tray.pop();                         // 从托盘恢复
/// // 通知请用 MyNotify，见 .doc/notify_channels.md
///
/// // 动态配置
/// tray.setTooltip("新提示");           // 更新提示文本
/// tray.setContextMenu([...]);         // 更新右键菜单
/// tray.setIcon("new_icon.png");       // 切换图标
///
/// // 任务栏图标策略控制
/// tray.showTaskbarIcon();             // 显示任务栏图标
/// tray.hideTaskbarIcon();             // 隐藏任务栏图标
/// bool isHidden = tray.hideTaskBarIcon; // 获取当前策略
///
/// // 关闭即隐藏策略控制
/// tray.setCloseToTray(false);         // 关闭=退出（恢复原生行为）
/// bool isCloseToTray = tray.getCloseToTray();
///
/// // 自定义安全清理链可提前进入退出态；普通项目直接 MyApp.exit() 即可自动处理
/// await tray.beginExit();             // 保留图标、禁用交互并显示“正在安全退出…”
/// ```
///
/// ## 无边框窗口的关闭按钮（重要）
/// 无边框（`setTitleBarHidden: true`，默认）窗口没有系统“X”按钮。配合 `closeToTray`：
/// - 在你自己的界面右上角放一个关闭图标，`onTap: () => windowManager.close()`，
///   会被拦截为“缩回托盘”（推荐，语义统一，将来改 closeToTray 也无需改 UI）。
/// - 或直接 `onTap: () => MyTray.to.hide()`。
/// 即使不放按钮，Alt+F4 与“再点一次托盘图标”（toggleOnClick）也能把窗口收回托盘。
///
/// ## 默认行为
/// - **tooltip**: 不显示（null）
/// - **menuItems**: 无菜单（null）
/// - **hideTaskBarIcon**: `false` —— 窗口可见时保留任务栏图标 + Alt+Tab 条目；
///   仅 `hide()` 缩进托盘时移除。置 `true` 为“纯托盘工具”模式（窗口开着也无任务栏图标，
///   该状态下在 Windows 上也进不了 Alt+Tab，属平台硬约束）。
/// - **closeToTray**: `true` —— 点关闭按钮(Alt+F4/自渲染X)缩回托盘而非退出进程；
///   真正退出走托盘菜单 → `MyApp.exit()`。退出期间图标保留并显示“正在安全退出…”，
///   仅在最终 `exit(0)` 前显式销毁，避免状态误导和 Windows 幽灵图标。
/// - **图标验证**: 构造时检查文件存在性，不存在则抛异常
/// - **平台检查**: 非桌面平台自动跳过初始化
/// - **生命周期**: 随应用启动/关闭自动管理
///
/// ## 注意事项
/// - 仅在桌面平台（Windows/macOS/Linux）可用
/// - 图标文件必须存在，否则初始化时抛异常
/// - 作为GetxService，享受全局生命周期管理，不会被意外释放
/// - MyApp.initialize完全不涉及托盘逻辑，保持职责分离
library;

export 'my_tray.dart';
