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
/// - **简洁强制**: 只有iconPath是必需的，其他都可选
/// - **全局服务**: 继承GetxService，享受全局生命周期管理
/// - **统一访问**: 通过MyTray.to进行所有操作
///
/// ## 基础使用
/// ```dart
/// // 1. 在 main.dart 中注册服务（唯一初始化方式）
/// void main() async {
///   await MyApp.initialize(
///     services: [
///       // 最简使用 - 只需图标路径
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
/// tray.showNotification("标题", "消息");
/// ```
///
/// ## 完整配置示例
/// ```dart
/// MyService<MyTray>(
///   service: () => MyTray(
///     iconPath: "assets/icon.png",        // 必需：托盘图标路径
///     tooltip: "My App",                  // 可选：悬停提示
///     menuItems: [                        // 可选：右键菜单
///       MyTrayMenuItem(
///         label: '显示主窗口',
///         onTap: () => MyTray.to.restoreFromTray(),
///       ),
///       MyTrayMenuItem.separator(),
///       MyTrayMenuItem(
///         label: '退出应用',
///         onTap: () => exit(0),
///       ),
///     ],
///   ),
/// );
/// ```
///
/// ## 运行时操作
/// ```dart
/// final tray = MyTray.to;
///
/// // 基础操作
/// tray.minimizeToTray();              // 最小化到托盘
/// tray.restoreFromTray();             // 从托盘恢复
/// tray.showNotification("标题", "消息"); // 显示通知
///
/// // 动态配置
/// tray.setTooltip("新提示");           // 更新提示文本
/// tray.setContextMenu([...]);         // 更新右键菜单
/// tray.setIconState(MyTrayIconState.warning); // 切换图标状态
/// ```
///
/// ## 默认行为
/// - **tooltip**: 不显示（null）
/// - **menuItems**: 无菜单（null）
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
export 'tray_enums.dart';
export 'tray_wrapper.dart';
export 'windows_tray_api.dart';
