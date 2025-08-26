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
/// - **唯一初始化**: 只通过MyService<MyTray>初始化，避免配置冲突
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
/// tray.showNotification("标题", "消息");
/// ```
///
/// ## 完整配置示例
/// ```dart
/// MyService<MyTray>(
///   service: () => MyTray(
///     iconPath: "assets/icon.png",        // 可选：托盘图标路径，为空时使用默认应用图标
///     tooltip: "My App",                  // 可选：悬停提示
///     hideTaskBarIcon: true,              // 可选：托盘存在时是否隐藏任务栏图标（默认true）
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
/// tray.notify("标题", "消息");          // 显示通知
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
