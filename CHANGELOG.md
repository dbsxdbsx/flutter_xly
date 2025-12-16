## 0.29.2 - 2025-12-16

### Fixed

- **修复 MyCardList.scrollToIndex 滚动定位不准问题**：原实现使用硬编码卡片高度，导致目标节点无法正确居中
  - 改用动态计算：`cardHeight = (maxScrollExtent + viewportHeight) / itemCount`
  - 自动适应缩放、屏幕变化等情况，无累积偏移误差

### Enhanced

- **scrollToIndex 健壮性增强**：
  - 添加 `index` 越界保护（自动 clamp 到有效范围）
  - 添加 `hasClients` 检查 + `postFrameCallback` 延迟执行，避免首帧访问异常
  - 添加 `RenderBox` 检查 + 延迟重试，确保列表已渲染
  - 添加 `maxScrollExtent ≤ 0` 保护，内容不足时不执行无意义滚动
  - 完善 API 文档注释

- **Example Page4 滚动测试 UI 优化**：
  - 为可拖动列表和静态列表分别添加独立的滚动控制组件
  - 重新设计底部控制区布局，两组控件对称排列，颜色区分
  - 每组包含：标签、自动滚动开关（Checkbox）、目标选择（Dropdown）

## 0.29.1 - 2025-12-16

### Added

- **MySpinBox 标签对齐选项**：新增 `floatingLabelAlignment` 参数，默认居中对齐（适合数字选择器的对称布局）

## 0.29.0 - 2025-12-16

### Added

- **MySpinBox 动态最小宽度**：根据 `max` 值的位数自动计算组件最小宽度，修复数字显示区域被压缩导致截断的问题（如 "30" 显示为 "3("）
  - 新增 `_calculateMinWidth()` 方法，综合考虑按钮宽度、数字位数、字体大小、后缀文字等因素
  - 使用 `ConstrainedBox` 包裹组件确保最小宽度
  - 无需手动设置，自动适配各种 `max` 值场景

- **MyTextEditor 标签对齐选项**：新增 `floatingLabelAlignment` 参数，支持标签水平位置设置
  - `FloatingLabelAlignment.start`（默认）：左对齐
  - `FloatingLabelAlignment.center`：居中对齐
  - 示例页面 Page6 的"综合自定义样式输入框"已更新为居中标签展示

## 0.28.6 - 2025-12-16

### Fixed

- **修复 Snackbar 在弹层关闭过程中的 Overlay 崩溃问题**：解决 Flutter 3.38.1+ 对话框关闭回调中调用 `Get.snackbar` 导致 "No Overlay widget found" 异常
  - 在 `GetMaterialApp` 的 builder 中包裹永久 `Overlay`，确保 `Get.overlayContext` 始终可用
  - 移除 `menu/widget.dart` 中的 `microtask` 包装，简化代码逻辑
  - 移除 `MyScaffold` 中冗余的 Overlay 包装（因 App 根部已包裹）
  - 参考：[getx#3425](https://github.com/jonataslaw/getx/issues/3425)

### Enhanced

- **README 文档完善**：新增 Snackbar 说明章节，解释顶部/底部通知栏的行为和边界场景处理
- **示例项目**：Page3 新增 Overlay 问题测试按钮，方便验证修复效果

## 0.28.5 - 2025-12-15

### Fixed

- **修复异步回调导致的 Unhandled Future Exception 问题**：解决当用户传入 async 回调时，内部异常变成未处理 Future 异常的问题
  - 将所有用户回调类型从 `VoidCallback?` 改为 `FutureOr<void> Function()?`，同时支持同步和异步回调
  - 所有回调调用处添加 `await` + `try-catch` 兜底，防止用户未处理的异常导致应用崩溃
  - 使用 `XlyLogger.error` 统一记录异常，Debug 模式可见，Release 模式不显示
  - 向后兼容：现有同步回调无需任何修改

### Changed

- **受影响的组件和参数**：
  - `MyDialogSheet.showCenter`: `onConfirm`, `onExit`
  - `MyDialog.show` / `showIos`: `onLeftButtonPressed`, `onRightButtonPressed`
  - `MyMenuItem`: `onTap`
  - `MyTrayMenuItem`: `onTap`
  - `FloatPanelIconBtn`: `onTap`
  - `MyAdaptiveNavigationItem`: `onTap`
  - `MyEndOfListWidget`: `onRetry`
  - `MyTextEditor`: `onCleared`
  - `SingleInstanceManager.initialize`: `onActivate`

## 0.28.4 - 2025-12-15

### Fixed

- **修复 Dialog/BottomSheet 内 Overlay 组件崩溃问题**：解决在 Dialog 或 BottomSheet 内部使用 `MyMenu` 或 `MyTextEditor` 下拉功能时触发 "No Overlay widget found" 错误
  - 为所有 `Overlay.of(context)` 调用添加 `rootOverlay: true` 参数
  - 影响组件：`MyMenu`（5 处）、`MyTextEditor`（2 处）
  - 现在可以在 Dialog、BottomSheet、Popup 等任意层级中安全使用这些组件
  - 更新 Flutter 最低版本要求为 3.7.0（支持 `rootOverlay` 参数）

## 0.28.3 - 2025-11-09

### Fixed

- **Windows 托盘菜单关闭问题修复**：修复 Windows 平台上托盘右键菜单无法通过点击空白区域关闭的问题
  - 在`popUpContextMenu()`调用中添加`bringAppToFront: true`参数
  - 虽然该参数已被标记为 deprecated，但仍是解决此问题的最简单有效方案
  - 参考：[tray_manager#63](https://github.com/leanflutter/tray_manager/issues/63)
  - 用户现在可以通过点击窗口区域、按 ESC 键或再次右键托盘图标来关闭菜单

## 0.28.2 - 2025-11-09

### Enhanced

- **菜单模块代码重构**：优化菜单组件的代码结构和可维护性
  - 新增 `menu_models.dart` 独立文件，集中管理菜单模型类（MyMenuItem、MyMenuDivider、MyMenuPopStyle）
  - 优化 `MyMenuStyle` 为可选参数，提供更灵活的默认值处理
  - 修复内部导入路径，使用相对路径替代绝对路径
  - 重构 `widget.dart` 菜单核心逻辑，改进代码可读性
  - 统一 `lib.dart` 导出顺序，优化模块对外接口

## 0.28.1 - 2025-10-30

### Fixed

- **SmartDock 与 MyTray 依赖解耦**：修复智能停靠功能与托盘功能的可选依赖关系
  - 使用 `Get.isRegistered<MyTray>()` 检查服务是否已注册，替代 try-catch 方式
  - 消除未使用 MyTray 时的错误日志 `"MyTray" not found`
  - 确保 SmartDock 和 MyTray 功能完全正交，可独立使用
  - 两个功能同时使用时仍能正确协调窗口状态（如任务栏图标显示）

### Added

- **测试覆盖**：新增 `smart_dock_without_tray_test.dart` 测试文件
  - 验证 SmartDock 在无 MyTray 时正常工作
  - 覆盖三种使用场景：仅 SmartDock、仅 MyTray、两者同时使用
  - 12 个测试用例确保功能独立性和协同性

## 0.28.0 - 2025-10-30

### Added

- **统一日志系统**：引入 `XlyLogger` 统一日志工具，避免包内部调试日志污染用户项目
  - 新增 `enableDebugLogging` 参数到 `MyApp.initialize()`，默认为 `false`
  - 提供四级日志输出：`debug()`、`info()`、`warning()`、`error()`
  - Example 项目默认启用调试日志（`enableDebugLogging: true`），方便包开发
  - 用户项目默认关闭调试日志，需要时可主动启用
  - 错误级别日志始终输出，确保重要错误可见
  - 所有日志带 `[Xly]` 前缀，便于识别来源

### Enhanced

- **日志输出优化**：将全部 158 个 `print`/`debugPrint` 调用迁移到统一日志系统
  - Smart Dock 模块（72 个）：窗口停靠、鼠标追踪、动画等内部状态日志
  - MyTray 模块（21 个）：托盘初始化、菜单操作等日志
  - MyNotify 模块（22 个）：通知权限、显示状态等日志
  - MyApp 核心（19 个）：窗口操作、全屏切换等日志
  - 工具类（24 个）：平台工具、自启动、单实例等日志
- **代码质量**：移除所有未使用的 `import 'package:flutter/foundation.dart'` 引用

### Documentation

- **新增贡献者指南**：创建 `.doc/contributor_logging_guide.md`，规范日志使用
  - 详细的日志级别选择指南
  - 编码规范和最佳实践
  - 常见问题解答
- **README 更新**：添加调试日志说明和贡献者链接

## 0.27.2 - 2025-10-26

### Enhanced

- **服务注册错误处理**：优化服务注册失败时的错误处理机制
  - 移除服务注册过程中的 try-catch 包装，让异常自然向上传播
  - 服务注册失败时应用初始化将立即终止，提供更明确的失败信号
  - 避免静默失败，确保开发者能及时发现服务配置问题

## 0.27.1 - 2025-10-26

### Fixed

- **服务注册顺序保证**：修复服务注册机制，确保严格按照用户输入顺序依次初始化
  - 将并行注册改为顺序注册，避免服务依赖关系导致的初始化失败
  - 简化服务注册逻辑，提高代码可维护性和可预测性
  - 用户现可通过调整 `services` 参数中的顺序来控制服务初始化顺序

## 0.27.0 - 2025-10-26

### Added

- **异步服务支持**：`MyService` 现在支持异步服务初始化
  - 新增 `asyncService` 参数：用于注册需要异步初始化的服务（如从数据库/网络加载配置）
  - 保留 `service` 参数：用于传统的同步服务注册
  - 使用 `Get.putAsync()` 实现异步服务注册，等待初始化完成后再继续
  - 服务按照用户定义的顺序依次注册，确保依赖关系正确处理
  - 完善的单元测试覆盖，确保同步/异步服务混合使用的稳定性

### Enhanced

- **服务注册时机优化**：服务现在在 `MyApp.initialize()` 中注册，而非 `build()` 中
  - 确保所有服务（包括异步服务）在应用启动前完全初始化
  - 提供更好的错误处理和调试信息
  - 避免潜在的竞态条件和初始化顺序问题
- **README 文档完善**：新增"异步服务支持"章节
  - 详细的异步服务使用指南和最佳实践
  - 异步工厂方法模式示例
  - 注意事项和错误处理说明

### Fixed

- **服务检测逻辑修复**：修复 `MyTray` 服务检测时的空指针问题，正确处理异步服务类型检查

## 0.26.1 - 2025-09-22

### Enhanced

- **FloatPanel 常亮控制功能**：新增按钮"常亮（高亮显示）"状态管理
  - 新增 `setHighlighted(bool)` 方法：设置指定按钮的常亮状态
  - 新增 `toggleHighlighted()` 方法：切换按钮常亮状态
  - 新增 `isHighlighted` getter：查询按钮是否处于常亮状态
  - 新增 `highlightedIds` 集合：全局管理所有常亮按钮的 ID
  - 常亮状态与启用/禁用状态完全独立，不相互影响
  - 示例项目新增常亮控制演示区域和完整测试用例

### Fixed

- **代码质量优化**：清理 FloatPanel 源码中的损坏注释，完善 API 文档注释

## 0.26.0 - 2025-09-13

### Added

- **Windows 启动闪现一键修复工具**：新增`dart run xly:win_setup`命令，彻底解决 Flutter Windows 应用启动时的白屏/黑屏闪现问题
  - 精确查找并注释掉`windows/runner/flutter_window.cpp`中的强制显示代码
  - 支持`--project-dir`参数指定项目路径，`--dry-run`演练模式，`--backup`自动备份
  - 安全的非侵入式补丁，保持其他自定义代码不变
  - 配合`showWindowOnInit: false`实现真正的静默启动，完全消除启动闪现

### Enhanced

- **README 文档完善**：新增"根除 Windows 启动闪现：静默启动补丁"章节
  - 详细说明问题原因、解决方案和使用方法
  - 提供完整的命令行选项说明和使用示例
  - 强调一劳永逸的优化效果和技术背景
- **Justfile 工具集成**：新增`just setup-win`快捷命令，简化 Windows 优化流程

## 0.25.1 - 2025-09-13

### Fixed

- **窗口初始化逻辑简化**：移除复杂的兜底校正机制，采用更直接的窗口状态控制方式
  - 简化`showWindowOnInit`和`focusWindowOnInit`的处理逻辑，提升代码可维护性
  - 优化窗口显示、焦点和居中的执行顺序，确保更稳定的初始化行为
  - 减少不必要的异步操作和延时处理，提升应用启动性能

## 0.25.0 - 2025-09-05

### Breaking Changes

- **MyApp.initialize 参数重命名**：为提升 API 语义清晰度，重命名了窗口初始化相关参数
  - `showWindow` → `showWindowOnInit`：明确表示仅在初始化时控制窗口显示
  - `focusWindow` → `focusWindowOnInit`：明确表示仅在初始化时控制窗口焦点
  - `centerWindow` → `centerWindowOnInit`：明确表示仅在初始化时控制窗口居中
  - **迁移指南**：将现有代码中的参数名更新为新名称即可，功能行为完全一致

### Enhanced

- **showWindowOnInit 行为增强**：新增兜底校正机制，确保最终窗口状态与参数设置严格一致
  - 解决 Windows runner 默认模板在首帧回调中强制 Show 窗口的冲突问题
  - 当`showWindowOnInit=false`时，通过多层校正（立即隐藏+首帧后校正+延时兜底）确保窗口最终隐藏
  - 当`showWindowOnInit=true`时，确保窗口最终可见，避免某些平台时序问题
  - 添加详细注释说明：如需完全根除短暂闪现，可在 C++侧移除 runner 的首帧 Show 逻辑

### Documentation

- **参数语义说明**：README.md 中补充`showWindowOnInit`和`focusWindowOnInit`的精确定义和注意事项
- **技术背景**：代码注释中详细说明 Windows runner 首帧 Show 冲突的技术原理和解决方案

---

## 0.24.0 - 2025-09-04

### Added

- **单实例管理功能**：新增`SingleInstanceManager`确保应用只运行一个实例
  - 支持配置参数：`singleInstance`（默认启用）、`singleInstanceKey`（实例标识）、`singleInstanceActivateOnSecond`（激活已有实例）
  - 使用 TCP 端口锁机制，通过稳定哈希算法生成端口号（30000-39999 范围）
  - 仅在桌面平台生效，移动端和 Web 端自动跳过
  - 检测到已有实例时自动激活并退出当前实例

### Fixed

- **单实例初始化阻塞问题**：修复`SingleInstanceManager`初始化时无限等待监听循环导致窗口无法显示的问题
  - 将 HTTP 服务器监听改为后台异步执行，避免阻塞窗口创建
  - 修复端口生成算法，使用稳定的字符串哈希替代不可靠的`String.hashCode`

### Enhanced

- **应用退出流程**：`MyApp.exit()`现在会自动清理单实例管理器资源
- **文档完善**：README.md 新增单实例机制详细说明，包含配置参数、工作原理和注意事项

---

## 0.23.0 - 2025-09-04

### Added

- 窗口标题 API：`MyApp.setWindowTitle(String)` 与 `MyApp.getWindowTitle()`
  - 桌面平台：同步原生窗口标题（调用 `windowManager.setTitle`）
  - 非桌面平台：仅更新内部全局状态，`GetMaterialApp.title` 仍可即时反映
  - 通过全局 Rx 字符串 `_globalWindowTitle` 驱动，标题变更即时生效

### Enhanced

- 示例 Page1：新增“设置随机标题”“读取当前标题”两个测试按钮，便于验证标题读写功能
- 初始化逻辑：当 `MyApp.initialize` 传入 `appName` 时，自动写入全局标题并同步原生窗口

### Documentation

- README：新增“窗口标题控制”章节，补充 API 用法、跨平台行为与特性说明

---

## 0.22.2 - 2025-08-31

### Fixed

- **pub.dev 链接显示问题修复**：修复 README.md 和 CHANGELOG.md 中相对链接在 pub.dev 上显示不正确的问题
  - 将所有`.doc/`目录的相对链接替换为"本地 | GitHub"双链接格式
  - 修复文档链接文件名不一致问题（`float_panel_usage.md` → `float_panel_migration_and_usage.md`）
  - 确保用户在 pub.dev 上能够正确访问所有文档链接

### Enhanced

- **GitHub 开源链接可见性**：在 pubspec.yaml 中添加 homepage 和 repository 字段
  - 添加`homepage: https://github.com/dbsxdbsx/flutter_xly`
  - 添加`repository: https://github.com/dbsxdbsx/flutter_xly`
  - 确保 GitHub 开源链接在 pub.dev 包页面上清晰可见

## 0.22.1 - 2025-08-31

### Fixed

- **FloatPanel 停靠偏移修复**：修复浮动面板在左右边缘停靠时偏移量不对称的问题
  - 修正 dock 偏移量计算公式，从 `panelWidth * (panelWidth / 50) / 2` 简化为 `panelWidth / 2`
  - 确保左右停靠时均为严格的"半隐藏"效果，解决右侧"缩进过多"、左侧"缩进过少"的不一致现象
  - 保持运行时 `.w` 缩放的一致性，适配不同屏幕密度

### Enhanced

- **FloatPanel 配置扩展**：新增多项可选配置参数，提升自定义灵活性
  - 新增 `borderColor`、`initialPanelIcon` 等样式配置选项
  - 新增 `panelAnimDuration`、`panelAnimCurve`、`dockAnimDuration`、`dockAnimCurve` 等动画配置
  - 所有新增参数均有合理默认值，保持向后兼容
  - 更新相关文档和示例代码

## 0.22.0 - 2025-08-30

### Breaking Changes

- **FloatPanel 系统重构**：完全移除旧的 `MyFloatBar` 组件，统一使用新的 `FloatPanel` 系统
  - 移除 `appBuilder` 中使用 `MyFloatBar` 的方式
  - 新的 `FloatPanel` 通过 `MyApp.initialize` 的 `floatPanel` 参数直接配置
  - 支持智能联动、多选禁用、自定义样式等高级功能

### Enhanced

- **文档更新**：更新 README.md 中的浮动面板使用说明，移除过时的 `MyFloatBar` 引用
- **示例项目优化**：示例项目已完全迁移到新的 `FloatPanel` 系统

### Migration Guide

- 将原有的 `appBuilder` + `MyFloatBar` 方式替换为 `floatPanel` 参数配置
- 详细迁移指南请参考：[本地](.doc/float_panel_migration_and_usage.md) | [GitHub](https://github.com/dbsxdbsx/flutter_xly/blob/main/.doc/float_panel_migration_and_usage.md)

## 0.21.1 - 2025-08-28

### Fixed

- **回退键处理优化**：修复 `keyToRollBack` 参数设置的回退键在弹层场景下的行为不一致问题
  - 全局层面：回退键现在优先调用 `Navigator.maybePop()` 处理可弹栈的层（Dialog、BottomSheet、PopupMenu 等）
  - MyScaffold 层面：小屏 Drawer 模式下回退键优先关闭侧边栏，避免直接触发全局回退/退出逻辑
  - 保持原有双击回退键回退/退出的语义，仅在有弹层可关闭时优先消费按键事件
  - 解决用户反馈的"汉堡菜单打开时按回退键直接退出应用而非关闭菜单"的问题

## 0.21.0 - 2025-08-28

### Breaking Changes

- **移除 navigatorKey 参数**：从 `MyApp.initialize` 中移除 `navigatorKey` 参数
  - 内部使用 `Get.key` 作为全局 NavigatorKey，简化用户配置
  - 如需访问 NavigatorState，请使用 `Get.key.currentState`
  - 如需全局 BuildContext，请使用 `Get.context` 或 `Get.overlayContext`
  - 对话框请使用 `Get.dialog` 替代原生 `showDialog`

### Enhanced

- **简化初始化参数**：降低心智负担，开箱即用
- **文档更新**：添加 navigatorKey 移除的详细说明和迁移指南

## 0.20.3 - 2025-08-28

### Enhanced

- **MyButton 组件优化**：改进按钮组件的样式和交互逻辑
- **MyDialogSheet 组件完善**：优化对话框组件的显示效果和用户体验
- **示例页面功能扩展**：Page3 新增更多交互演示和功能测试
- **文档更新**：完善 README.md 中的相关功能说明和使用示例

### Technical

- **依赖更新**：更新 example 项目的依赖锁定文件，确保版本一致性

## 0.20.2 - 2025-08-28

### Enhanced

- **MyDialog & MyDialogSheet**：新增 barrierDismissible 参数（默认 true），支持按需控制点击遮罩关闭
  - MyDialog.show / MyDialog.showIos / 内部 \_showDialog 透传该参数
  - MyDialogSheet.show 增加同名参数，保持命名与 Flutter 官方一致
- **README**：补充严格模态用法示例（barrierDismissible: false）并在基础示例中标注默认语义

## 0.20.1 - 2025-08-28

### Added

- **图标生成工具托盘图标自动复制功能**：扩展 `dart run xly:generate icon` 命令，自动处理托盘图标一致性
  - 使用统一的 `assets/_auto_tray_icon_gen/` 文件夹简化资产管理
  - 为桌面平台（Windows、macOS、Linux）自动复制应用图标到 Flutter assets
  - 自动更新 pubspec.yaml 添加必要的 assets 路径声明
  - 确保 MyTray 托盘图标与应用窗口图标完全一致，跨启动方式稳定
- **MyTray 图标解析优化**：重构默认图标路径解析逻辑
  - 新增 `_resolveIconPath()` 统一解析方法，优先检查 `_auto_tray_icon_gen` 文件夹
  - 使用 MyPlatform.getAppDirectory 和 getFilePastedFromAssets 确保路径一致性
  - 移除对 `assets/icons/tray.ico` 的硬编码兜底，完全基于平台默认图标路径
  - 解决 VSCode F5 调试与从应用目录运行时托盘图标不一致的问题

### Enhanced

- **工具文档更新**：tool/README.md 新增托盘图标自动复制功能说明和 Windows 图标缓存注意事项
- **MyTray 文档完善**：.doc/my_tray_design.md 新增自动图标一致性最佳实践章节和图标缓存问题说明
- **README 更新**：添加托盘图标一致性工作流、自动化优势说明和 Windows 图标缓存提醒

## 0.20.0 - 2025-08-26

### Added

- **MyTray 托盘点击切换功能**：新增 toggleOnClick 参数，支持托盘左键点击切换显示/隐藏
  - 构造参数：bool toggleOnClick = true，控制托盘左键点击行为
  - toggleOnClick=false：保持现状（智能停靠下模拟悬停弹出；否则恢复显示并聚焦）
  - toggleOnClick=true：切换语义（普通模式 hide↔pop 切换；智能停靠下隐藏 ↔ 无激活显示切换）
  - 运行时 API：getToggleOnClick()、setToggleOnClick(bool)、toggleToggleOnClick()
  - 智能停靠兼容：保持"隐藏 → 显示不会立即缩回"的既有体验
- **MyTray 任务栏图标策略控制**：新增 hideTaskBarIcon 参数和运行时 API
  - 构造参数：bool hideTaskBarIcon = true，控制托盘存在时任务栏图标是否隐藏
  - 运行时 API：showTaskbarIcon()、hideTaskbarIcon()、getHideTaskBarIcon()
  - 全局策略：无论 hide()/pop()操作，任务栏图标显示完全由策略决定
  - 与智能停靠完全解耦：不影响悬停唤醒、不激活显示等现有行为

### Enhanced

- **示例页面功能扩展**：Page9 新增托盘功能完整演示区域
  - 新增 toggleOnClick 策略演示：实时显示当前切换开关状态，提供开启、关闭、切换三种操作按钮
  - 任务栏图标策略演示：实时显示当前任务栏图标状态（隐藏/显示），提供显示、隐藏、切换三种操作按钮
  - 支持手动验证策略切换效果和托盘点击行为变化

## 0.19.5 - 2025-08-26 [069950e]

### Enhanced

- **MyTray 组件依赖升级**：将 tray_manager 依赖从 0.2.3 升级至 0.5.1
  - 提升系统托盘功能的稳定性和兼容性
  - 支持更多平台特性和 bug 修复

### Improved

- **示例页面 UI 优化**：改进 Page9 托盘演示页面的按钮布局
  - 将"设置测试禁用菜单"和"禁用/启用测试菜单项"按钮改为并排显示
  - 优化界面空间利用率，提升用户体验
  - 使用响应式单位确保跨设备适配

## 0.19.4 - 2025-08-26 [f751300]

### Added

- **MyTray 组件功能完善**：新增系统托盘组件的完整功能实现
  - 实现托盘图标显示、右键菜单、点击事件等核心功能
  - 支持动态更新托盘图标和菜单项
  - 添加托盘状态管理和事件回调机制

### Documentation

- **MyTray 组件文档完善**：为系统托盘组件补充完整文档
  - 新增专门的设计文档：`.doc/my_tray_design.md`
  - 包含组件设计思路、功能特性、使用方法等详细说明
  - 在 README.md 中添加 MyTray 组件的功能说明和使用示例

## 0.19.3 - 2025-08-25 [89a0ccd]

### Documentation

- **MyLoadingDot 组件文档完善**：为多点动态加载指示器组件补充完整文档
  - 在 README.md 功能列表中添加 MyLoadingDot 组件说明
  - 在 README.md 使用示例中添加详细的 MyLoadingDot 使用代码示例
  - 在注意事项中添加 MyLoadingDot 组件的特性说明和文档链接
  - 新增专门的使用指南：`.doc/my_loading_dot_usage_guide.md`
  - 包含四种动画类型详解、性能优化说明、实际应用场景、参数详解、最佳实践等

## 0.19.2 - 2025-08-25 [252b0fc]

### Fixed

- **MyTextEditor 组件修复**：解决`showAllOnPopWithNonTyping`参数相关的焦点与箭头点击行为问题
  - 修复重新获得焦点时未正确显示全量候选列表的问题
  - 修复点击侧边箭头时会意外清空输入文本的问题
  - 优化箭头点击与焦点回调的协调机制，避免重复触发导致的文本闪动
  - 改进焦点状态判断逻辑，确保不同触发方式下的行为一致性

### Documentation

- 更新 MyTextEditor 使用指南：补充焦点与箭头点击行为的详细说明

## 0.19.1 - 2025-08-25 [a2dea1c]

### Enhanced

- **MyTextEditor 组件增强**：新增`showAllOnPopWithNonTyping `参数，优化下拉候选列表的触发行为
  - 支持通过箭头点击或获得焦点时显示全量候选列表（不受当前输入过滤）
  - 改进触发来源追踪机制，区分输入、焦点、箭头三种触发方式
  - 优化焦点获得时的候选列表展示逻辑，提升用户体验
  - 完善键盘导航与鼠标交互的协调性

### Documentation

- 更新 README.md：移除已完成的 MyTextEditor 相关 TODO 项目

## 0.19.0 - 2025-08-25 [ee290ad]

### Added

- **MyLoadingDot 组件**：新增多点动态加载指示器，支持多种动画效果
  - 支持 fade、bounce、scale、wave 四种动画类型
  - 提供`MyLoadingDot.typing()`工厂方法，兼容"正在输入"场景
  - 自适应容器宽度，支持响应式尺寸单位
  - 可配置点数量、间距、颜色、动画周期等参数
  - 内置相位偏移和随机化起始相位，避免多实例同步问题

### Enhanced

- **示例应用完善**：新增 Page10 演示页面，展示 MyLoadingDot 的各种使用方式
  - 包含基础用法、不同动画类型、自定义参数等完整示例
  - 优化浮动导航栏的页面标题，提升用户体验
  - 更新侧边栏导航，新增 LoadingDot 演示入口

### Documentation

- 更新 README.md：移除已完成的 TODO 项目（3dot loading widget）
- 完善组件导出：在 xly.dart 中正确导出 MyLoadingDot 组件

## 0.18.1 - 2025-08-24

### Enhanced

- **MyTextEditor 功能完善**：进一步优化文本编辑器组件的用户体验
  - 完善下拉候选列表的交互逻辑和显示效果
  - 优化示例页面的演示效果和用户指导
  - 清理冗余代码文件，提升项目结构清晰度

### Documentation

- 更新 `.doc/my_text_editor_usage_guide.md`：完善使用指南内容
- 更新 `README.md`：优化 MyTextEditor 相关文档说明
- 更新示例页面：改进 page6.dart 的演示效果

### Technical

- 移除 `user_code/display_view.dart`：清理不再使用的代码文件
- 更新依赖锁定文件：确保依赖版本一致性

## 0.18.0 - 2025-08-24 [61b8608]

### Breaking Changes

- **MyTextEditor 下拉位置控制 API 重构**：
  - 移除 `dropdownShowBelow` 参数（bool）
  - 移除 `dropdownAutoDirection` 参数（bool）
  - 新增 `showListCandidateBelow` 参数（bool?，默认 null）
    - `null`：自动判定方向，基于可用空间决定向上或向下（推荐）
    - `true`：强制显示在下方
    - `false`：强制显示在上方

### Migration Guide

- 旧代码迁移：
  - `dropdownShowBelow: true` → `showListCandidateBelow: true`
  - `dropdownShowBelow: false` → `showListCandidateBelow: false`
  - 移除所有 `dropdownAutoDirection` 参数（默认 null 即自动）

### Documentation

- 更新 `.doc/my_text_editor_usage_guide.md`：重写"下拉位置控制"章节，提供三态布尔使用示例
- 更新 `README.md`：调整 MyTextEditor 示例代码，展示新 API 用法

## 0.17.5 - 2025-08-19

### Enhanced

- **智能托盘隐藏行为优化**：改进智能停靠模式下的"隐藏到托盘"交互体验
  - 新增 `MouseTracker.forceCollapseToHidden()` API：支持强制收起到隐藏位同时保留悬停唤醒能力
  - 优化 `MyTray.hide()` 在智能停靠模式下的行为：当窗口已展开时，点击"隐藏到托盘"会立即收起到边缘/角落隐藏位，避免鼠标仍在窗口区域时的视觉干扰
  - 保持悬停唤醒功能：用户仍可通过鼠标移动到屏幕边缘重新激活窗口

### Documentation

- 更新智能托盘相关文档：
  - README.md：补充智能收起行为说明
  - `.doc/smart_tray_technical.md`：更新技术实现细节
  - `.doc/smart_tray_user_guide.md`：完善用户体验说明与特别说明

## 0.17.4 - 2025-08-19

### Breaking Changes

- 移除 `MyTextEditor.dropdownMaxHeight` 参数：高度现在仅由 `maxShowDropDownItems` 与单项高度共同决定（`finalHeight = itemHeight * min(totalOptions, maxShowDropDownItems)`）。若之前依赖像素级封顶，请通过调小 `maxShowDropDownItems` 或减小行高来达到类似效果。

### Documentation

- 更新 `.doc/my_text_editor_usage_guide.md`：移除 `dropdownMaxHeight` 的所有示例与参数说明，新增“参数联动说明”。

## 0.17.3 - 2025-08-19 [0e909df]

### Breaking Changes

- 文本编辑器(MyTextEditor)下拉组件行为调整：移除了内部基于“最大可见项数”的滚动估算逻辑，统一改为使用实际可视区域与 maxScrollExtent 进行对齐滚动，避免滚动抖动与边界错位。

### Enhanced

- 下拉位置控制重构：当 dropdownShowBelow 为 false 时，通过位移统一在输入框上方展示。
- 自动滚动策略优化：选中项若超出可视区，上下对齐滚动以确保完整可见，动画更顺滑（150ms easeOut）。
- 结构清理：去除控制器中未使用的 \_maxVisibleItems 字段与相关参数，API 更简洁。

### Documentation

- 智能托盘文档增强：
  - 补充“托盘左击（智能停靠隐藏下）仅模拟悬停弹出”的交互语义与示意流程图。
  - README 与 .doc/smart*tray*\* 文档同步更新使用说明与最佳实践。

## 0.17.2 - 2025-08-08 [321935b]

### Enhanced

- **MyTextEditor 下拉导航优化**：进一步完善键盘导航和用户交互体验
  - 优化键盘导航逻辑，提升选项选择的响应性和准确性
  - 改进鼠标与键盘交互的协调性，确保状态同步更加流畅
  - 完善下拉列表的显示和隐藏机制，减少不必要的重绘
  - 优化选项过滤和搜索性能，支持更大数据集的流畅操作

### Documentation

- **MyTextEditor 使用指南更新**：补充最新功能说明和使用示例
  - 更新 API 文档，反映最新的功能改进和参数变化
  - 完善使用示例，包含更多实际应用场景
  - 优化参数说明和最佳实践建议

## 0.17.1 - 2025-08-07 [b014823]

### Enhanced

- **MyTextEditor 文档全面完善**：大幅提升开发者使用体验和文档质量
  - 扩展 README.md 使用示例：从基础用法扩展为包含多种场景的完整示例集合
  - 创建专门使用指南：新增`.doc/my_text_editor_usage_guide.md`详细使用指南
  - 完整 API 文档：涵盖所有重要参数、使用场景和最佳实践
  - 参数速查表：提供便于开发者快速查找的参数对照表
  - 实用示例集合：包含基础用法、下拉建议、自定义样式、控制器管理等完整示例
  - 最佳实践指导：提供性能优化建议、常见问题解答和错误处理方案

## 0.17.0 - 2025-08-07 [7fa3910]

### Enhanced

- **MyTextEditor 下拉导航系统全面升级**：完善键盘导航和用户交互体验
  - 智能键盘导航：支持上下箭头键精确导航，Enter 键选择，Escape 键关闭
  - 鼠标键盘协同：鼠标悬停与键盘导航状态智能同步，无缝切换
  - 智能滚动系统：选中项自动滚动到可视区域，支持大量选项的流畅导航
  - 防抖动机制：选择选项后智能防止下拉列表闪烁，提升交互流畅度
  - 手动关闭记忆：用户主动关闭下拉列表后，输入新内容前不会自动重新打开

### Fixed

- **下拉列表交互问题修复**：解决多种边界情况和用户体验问题
  - 修复键盘导航时焦点丢失问题，确保导航连续性
  - 修复选项选择后下拉列表意外重新打开的问题
  - 修复 Escape 键行为：优先关闭下拉列表，再让编辑器失去焦点
  - 修复大量选项时的显示和滚动问题，支持完整选项列表展示

## 0.16.0 - 2025-08-01

### Added

- **智能导航系统**：为 MyScaffold 添加完整的智能导航解决方案
  - 自动路由同步：侧边栏选中状态与当前路由自动同步，无论通过什么方式导航
  - 简化导航 API：只需指定 route 参数即可自动导航，无需手写 onTap 回调
  - 智能自动滚动：当侧边栏有很多菜单项时，选中项自动滚动到可视区域
  - 可配置滚动条：alwaysShowScrollbar 参数控制滚动条显示行为
  - 可配置自动滚动：autoScrollToSelected 参数控制自动滚动功能

### Enhanced

- **MyAdaptiveNavigationItem 增强**：添加 route 参数支持自动导航

  - 优先使用自定义 onTap，如果没有则使用 route 自动导航
  - 完全向后兼容，现有代码无需修改
  - 大幅简化用户代码，提升开发效率

- **导航体验优化**：移除所有不必要的延迟，提升响应速度
  - 即时的界面更新和状态同步
  - 优化路由监听机制，100ms 高频检查确保及时响应
  - 平滑的 300ms 滚动动画，使用 ScreenUtil 响应式尺寸计算

### Fixed

- **SpinBox 组件命名统一**：将"自定义编辑框"统一为标准命名
  - 修复页面导航按钮使用 Get.toNamed 而非 Get.back，确保精确导航
  - 统一所有页面的导航按钮风格，提供一致的用户体验

## 0.15.0 - 2025-08-01

### Added

- **MyTray 简化配置**：在 MyApp.initialize 中添加 tray 参数，提供更简洁的配置方式
  - 新增 tray 参数支持，可直接传入 MyTray 实例进行配置
  - 保持向后兼容，传统 MyService<MyTray>方式仍然支持
  - 更新文档和示例，展示新的简化使用方式

### Enhanced

- **MyScaffold 响应式单位支持**：全面支持 ScreenUtil 响应式单位

  - 所有内部尺寸属性使用.w/.h/.r/.sp 响应式单位
  - 包括边距、内边距、圆角、容器尺寸、图标大小等
  - 菜单项文本和徽章文本支持响应式字体缩放(.sp)
  - 提供更好的跨设备适配体验

- **智能停靠状态下功能冲突防护**：在智能停靠状态下自动禁用可能冲突的窗口功能

  - 双击最大化功能在智能停靠状态下自动禁用，防止破坏停靠布局
  - 全屏功能在智能停靠状态下自动禁用，避免状态冲突
  - UI 按钮智能显示禁用状态和原因，提供友好的用户反馈
  - 操作时显示明确提示，告知用户如何恢复功能（先关闭智能停靠）

- **全屏功能支持**：新增完整的全屏功能 API 和 UI 控制
  - 新增 `MyApp.isFullScreenEnabled()` 检查全屏功能可用性
  - 新增 `MyApp.setFullScreenEnabled()` 控制全屏功能启用状态
  - 新增 `MyApp.toggleFullScreen()` 切换全屏状态
  - 全屏功能与智能停靠智能交互，避免功能冲突

### Changed

- **命名一致性改进**：重命名 AdaptiveNavigationItem 为 MyAdaptiveNavigationItem

  - 保持与其他 My 系列组件的命名一致性
  - 更新所有相关文档和示例代码

- **组件命名统一**：将 SpinBox 相关术语统一更新为"自定义编辑框"
  - 侧边栏菜单项：'SpinBox' → '自定义编辑框'
  - 文档标题：'使用自定义数字输入框' → '使用自定义编辑框'
  - 示例代码：所有相关标签和注释统一更新
  - 保持与其他菜单项命名风格的一致性

### Improved

- **概念澄清和命名优化**：修正全屏和最大化功能的概念混淆
  - 重命名 `isDoubleClickFullScreenEnabled()` → `isDoubleClickMaximizeEnabled()`
  - 重命名 `setDoubleClickFullScreenEnabled()` → `setDoubleClickMaximizeEnabled()`

## 0.14.3 - 2025-07-28

### Changed

- **CHANGELOG 的 git 提交**：[1dfae6d]

### Enhanced

- **智能停靠状态下功能冲突防护**：在智能停靠状态下自动禁用可能冲突的窗口功能
  - 双击最大化功能在智能停靠状态下自动禁用，防止破坏停靠布局
  - 全屏功能在智能停靠状态下自动禁用，避免状态冲突
  - UI 按钮智能显示禁用状态和原因，提供友好的用户反馈
  - 操作时显示明确提示，告知用户如何恢复功能（先关闭智能停靠）

### Added

- **全屏功能支持**：新增完整的全屏功能 API 和 UI 控制
  - 新增 `MyApp.isFullScreenEnabled()` 检查全屏功能可用性
  - 新增 `MyApp.setFullScreenEnabled()` 控制全屏功能启用状态
  - 新增 `MyApp.toggleFullScreen()` 切换全屏状态
  - 全屏功能与智能停靠智能交互，避免功能冲突

### Improved

- **概念澄清和命名优化**：修正全屏和最大化功能的概念混淆
  - 重命名 `isDoubleClickFullScreenEnabled()` → `isDoubleClickMaximizeEnabled()`
  - 重命名 `setDoubleClickFullScreenEnabled()` → `setDoubleClickMaximizeEnabled()`
  - 明确区分：最大化（占据工作区域，任务栏可见）vs 全屏（占据整个屏幕，隐藏系统 UI）
  - 移除不必要的 F11 快捷键，保持应用简洁性

### Documentation

- **智能托盘技术文档**：新增 `.doc/smart_tray_technical.md` 详细技术实现说明
- **智能托盘用户指南**：新增 `.doc/smart_tray_user_guide.md` 用户使用指南
- **全屏功能文档**：在 README.md 中添加全屏功能的详细使用说明
  - 基本 API 使用方法
  - 与智能停靠的交互说明
  - 全屏 vs 最大化的区别说明
  - 注意事项和最佳实践

### Technical

- **智能托盘隐藏机制**：完善智能停靠状态下的托盘隐藏逻辑
  - 智能停靠激活时自动进入托盘模式，隐藏任务栏图标
  - 窗口焦点管理：获得焦点时保持任务栏隐藏状态
  - 退出智能停靠时自动恢复任务栏显示
- **状态管理优化**：改进 GetX 响应式状态管理，修复 UI 更新问题

## 0.14.2 - 2025-07-28 [3c6360c]

### Enhanced

- **简化 MyTray 配置**：在 `MyApp.initialize` 中添加 `tray` 参数，提供更简洁的托盘配置方式
  - 新增 `tray: MyTray(...)` 参数，无需了解 GetxService 概念
  - 保持向后兼容：传统的 `MyService<MyTray>` 方式仍然支持
  - 配置优先级：如果同时提供 `tray` 参数和 `services` 中的 MyTray，`tray` 参数优先
- **用户体验改进**：降低新手使用门槛，与其他功能（如 splash、theme 等）的配置方式保持一致

### Documentation

- 更新 README.md，展示新的简化配置方式，同时保留传统方式说明
- 更新.doc/my_tray_design.md，添加推荐和传统两种初始化方式的对比
- 更新 example 项目，使用新的简化配置方式

### Fixed

- 移除 example/page9.dart 中的"恢复窗口"按钮，简化界面

## 0.14.1 - 2025-07-27 [81957d6]

### Breaking Changes

- **重要架构清理**：完全移除 `MyApp.initialize` 中的托盘相关参数：
  - 移除 `enableTray` 参数
  - 移除 `trayIcon` 参数
  - 移除 `trayTooltip` 参数
  - 删除 `MyTrayWrapper` 组件文件
- **唯一初始化方式**：现在托盘功能完全通过 `MyService<MyTray>` 管理，避免架构重复和参数冲突

### Enhanced

- **智能默认图标**：`MyTray` 构造函数的 `iconPath` 参数现在可选，为空时自动使用各平台的默认应用图标：
  - Windows: `windows/runner/resources/app_icon.ico`
  - macOS: `macos/Runner/Assets.xcassets/AppIcon.appiconset/app-icon-512@2x.png`
  - Linux: `snap/gui/app_icon.png`
- **早期错误检测**：当默认图标文件不存在时，应用将无法启动并显示详细错误信息和解决方案
- **API 简化**：`MyTray.setIcon()` 方法的参数现在可选，为空时使用默认应用图标
- 更新示例应用，移除 `MyApp.initialize` 中的托盘参数，展示新的初始化方式

### Documentation

- 更新 `.doc/my_tray_design.md`，详细说明架构清理和智能默认图标功能
- 更新 README.md，新增 MyTray 使用示例和特性说明
- 强调唯一初始化方式的设计优势：避免配置冲突、架构清晰、职责单一

## 0.14.0 - 2025-07-27

### Added

- 新增系统托盘管理组件 `MyTray`，支持托盘图标、右键菜单、窗口最小化到托盘等功能
- 新增系统通知管理组件 `MyNotify`，基于 `flutter_local_notifications` 封装的跨平台通知管理器
- 新增托盘设计文档 (.doc/my_tray_design.md)，详细说明托盘功能的设计理念和使用方法
- 新增通知使用指南 (.doc/my_notify_usage_guide.md)，提供完整的系统通知功能说明
- 新增示例页面 8 (page8.dart)，展示托盘和通知功能的完整使用示例
- 新增托盘图标资源 (example/assets/icons/tray.ico)，为示例应用提供托盘图标

### Enhanced

- 完善 `MyApp` 类，新增对托盘和通知服务的支持
- 优化示例应用的服务注册，展示托盘和通知功能的集成方式
- 改进 README 文档，新增托盘和通知功能的详细介绍和使用示例
- 更新功能列表，新增系统托盘管理和系统通知管理功能
- 完善内置依赖包列表，新增 `tray_manager`、`flutter_local_notifications`、`timezone` 等依赖

### Dependencies

- 新增 `tray_manager: ^0.2.3` - 系统托盘管理
- 新增 `flutter_local_notifications: ^19.4.0` - 本地通知
- 新增 `timezone: ^0.10.0` - 时区处理

### Documentation

- MyTray 组件遵循"无隐式消息"设计原则，只有用户明确操作时才显示反馈
- MyNotify 与 MyTray 职责分离：MyTray 专注托盘管理，MyNotify 专注系统通知
- 托盘功能仅在桌面平台（Windows/macOS/Linux）可用
- 通知功能支持所有平台：Android、iOS、macOS、Windows、Linux

## 0.13.1 - 2025-07-15

### Added

- 新增自适应侧边栏实现指南文档 (.doc/adaptive_sidebar_implementation_guide.md)
- 新增自适应侧边栏使用文档 (.doc/adaptive_sidebar_usage.md)
- 新增 MyScaffold 的 leading 参数支持，允许自定义左侧组件
- 新增 MyScaffold 的 trailing 参数支持，允许自定义右侧组件
- 新增示例服务类 ExampleService，展示服务层架构

### Enhanced

- 完善 MyScaffold 自适应侧边栏功能，优化不同屏幕尺寸下的表现
- 改进 MyScaffold 在 mini 模式下的汉堡菜单图标显示逻辑
- 优化示例页面的导航和布局，提升用户体验
- 改进平台信息显示组件，增加更多系统信息展示
- 完善 README 文档，新增自适应侧边栏相关文档链接

### Fixed

- 修复智能隐藏 dock 功能的拖拽动画问题：增加拖拽完成检测，避免拖拽过程中过早触发对齐动画
- 重大简化：智能隐藏 dock 功能现在直接对齐到真正的屏幕边缘/角落，完全忽略任务栏
- 确保智能隐藏 dock 功能的拖拽对齐和鼠标悬停弹出位置一致性

### Documentation

- 新增智能隐藏 dock 功能修复总结文档 (.doc/smart_dock_fix_summary.md)

## 0.13.0 - 2025-07-15

### Added

- 新增自适应侧边栏实现指南文档 (.doc/adaptive_sidebar_implementation_guide.md)
- 新增自适应侧边栏使用文档 (.doc/adaptive_sidebar_usage.md)
- 新增 MyScaffold 的 leading 参数支持，允许自定义左侧组件
- 新增 MyScaffold 的 trailing 参数支持，允许自定义右侧组件
- 新增示例服务类 ExampleService，展示服务层架构

### Enhanced

- 完善 MyScaffold 自适应侧边栏功能，优化不同屏幕尺寸下的表现
- 改进 MyScaffold 在 mini 模式下的汉堡菜单图标显示逻辑
- 优化示例页面的导航和布局，提升用户体验
- 改进平台信息显示组件，增加更多系统信息展示
- 完善 README 文档，新增自适应侧边栏相关文档链接

### Fixed

- 修复 MyScaffold 在不同模式切换时的 UI 一致性问题
- 解决示例页面在不同屏幕尺寸下的布局适配问题

## 0.12.0 - 2025-07-14

### Added

- 新增智能停靠系统重构，将原有单一文件拆分为模块化架构
- 新增 `DockDetector` 类，专门负责检测窗口是否接近屏幕边缘
- 新增 `MouseTracker` 类，处理鼠标位置追踪和悬停检测
- 新增 `NativeWindowHelper` 类，封装原生窗口操作 API
- 新增 `WindowAnimator` 类，专门处理窗口动画效果
- 新增 `WindowFocusManager` 类，管理窗口焦点和激活状态
- 新增 `SmartDock` 主控制器类，协调各个模块的工作

### Enhanced

- 重构智能停靠功能，采用模块化设计提升代码可维护性
- 优化窗口动画性能，减少不必要的重复动画执行
- 改进鼠标悬停检测逻辑，提升用户交互体验
- 完善智能停靠文档，新增详细的架构说明和使用指南

### Fixed

- 修复智能停靠过程中可能出现的窗口焦点问题
- 解决鼠标悬停时的动画冲突问题
- 优化边缘检测算法，提高停靠触发的准确性

### Documentation

- 新增 `lib/src/smart_dock/README.md` 详细架构文档
- 更新主 README 文档中的智能停靠功能说明
- 完善代码注释，提升代码可读性

## 0.11.0 - 2025-07-12

### Added

- 新增细粒度平台检测功能到 MyPlatform 类
- 新增 `MyPlatform.isWeb` - 检测 Web 平台
- 新增 `MyPlatform.isWindows` - 检测 Windows 平台
- 新增 `MyPlatform.isMacOS` - 检测 macOS 平台
- 新增 `MyPlatform.isLinux` - 检测 Linux 平台
- 新增 `MyPlatform.isAndroid` - 检测 Android 平台
- 新增 `MyPlatform.isIOS` - 检测 iOS 平台
- 新增 `MyPlatform.isFuchsia` - 检测 Fuchsia 平台
- 新增 `MyPlatform.platformName` - 获取当前平台友好名称
- 在示例应用中新增平台信息显示组件，位于自适应侧边栏底部

### Enhanced

- 完善平台检测功能的单元测试覆盖
- 更新 README 文档，展示细粒度平台检测的使用方法
- 优化示例应用的平台信息展示，采用类似系统信息面板的设计风格

### Documentation

- 更新功能列表，强调跨平台工具类支持细粒度平台检测
- 新增完整的平台检测使用示例和 API 说明

## 0.10.3 - 2025-07-12

### Fixed

- 修正 README 中平台检测方法的错误调用方式
- 将 `MyPlatform.isDesktopOs()` 更正为 `MyPlatform.isDesktop`
- 将 `MyPlatform.isMobileOs()` 更正为 `MyPlatform.isMobile`
- 确保文档示例与实际 API 保持一致

## 0.10.2 - 2025-07-12

### Documentation

- 改进 Toast 功能文档说明，明确区分普通模式和堆叠模式的差异
- 修正 README 中 Toast 参数名称不一致问题（`stackToasts` → `stackPreviousToasts`）
- 新增 Toast 显示模式对比示例，帮助用户理解"连续显示 Toast"的实现原理
- 优化 Toast 特性列表，突出显示两种显示模式的区别和使用场景

## 0.10.1 - 2025-07-09

### Added

- 新增窗口比例调整控制功能：`MyApp.setAspectRatioEnabled()` 和 `MyApp.isAspectRatioEnabled()`
- 在 `MyApp.initialize()` 中新增 `setAspectRatioEnabled` 参数，默认值为 `true`
- 支持动态启用/禁用窗口固定比例调整，提供更灵活的窗口管理体验

### Enhanced

- 更新功能列表，新增"窗口比例调整控制"功能说明
- 在示例页面 1 中新增窗口比例调整切换按钮，方便用户测试该功能
- 优化窗口控制按钮布局，将原来的 3 个按钮重新排列为 2 行，提升界面美观性

### Documentation

- 更新 README.md，新增窗口控制 API 部分，详细介绍窗口比例调整功能
- 为窗口比例调整功能提供完整的使用示例和特性说明

## 0.10.0 - 2025-07-09

### Added

- 新增自适应侧边栏导航组件 `MyScaffold`
- 根据屏幕尺寸自动切换显示模式：小屏幕使用抽屉或底部导航，中屏幕使用收缩侧边栏，大屏幕使用展开侧边栏
- 支持类似传统 Flutter Scaffold 的 API 设计，提供 `drawer`、`body`、`appBar` 等参数
- 支持自定义断点宽度、抽屉宽度比例等配置选项
- 支持导航项徽章显示和侧边栏底部额外内容
- 新增 `MyAdaptiveNavigationItem` 类用于定义导航项

### Enhanced

- 更新功能列表，新增"自适应侧边栏导航"功能说明
- 优化示例项目，展示自适应导航的使用方式
- 改进 `MyList` 组件的 GlobalKey 重复问题处理

### Documentation

- 更新 README.md，新增自适应侧边栏导航功能介绍
- 为 `MyScaffold` 组件提供详细的文档注释和使用示例

## 0.9.3 - 2025-07-08

### Breaking Changes

- **重要变更**：将本地存储从 `SharedPreferences` 替换为 `GetStorage`
- 移除 `shared_preferences` 依赖，新增 `get_storage` 依赖
- 更新所有相关代码示例和文档，使用 `GetStorage` API

### Enhanced

- `MyApp.initialize()` 现在自动初始化 `GetStorage`，新增 `initializeGetStorage` 参数（默认为 true）
- 简化了本地存储的使用方式，提供更好的类型安全和响应式特性
- 优化了示例服务中的存储逻辑，移除了重复的初始化代码

### Documentation

- 更新 README.md 中的所有 `SharedPreferences` 示例为 `GetStorage`
- 更新功能列表，将"基于 shared_preferences 的本地存储"改为"基于 GetStorage 的本地存储"
- 更新依赖包列表，将 `shared_preferences` 替换为 `get_storage`

## 0.9.2 - 2025-07-08

### Added

- 新增应用图标生成工具，支持一键为所有平台生成应用图标
- 新增 `bin/generate.dart` 命令行入口，提供简洁的 `dart run xly:generate icon="图像路径"` 语法
- 新增 `tool/icon_generator.dart` 核心图标生成工具类
- 支持 PNG、JPEG、JPG 格式的输入图像
- 自动检测项目中存在的平台并生成对应图标：Android、iOS、Windows、macOS、Linux、Web
- 为 example 项目生成了完整的图标资源文件作为使用示例

### Enhanced

- 图标生成工具自动创建必要的目录结构和配置文件
- 支持多种尺寸规格，确保各平台图标符合官方规范
- iOS 图标自动移除 alpha 通道，符合 App Store 要求
- Windows 平台生成 ICO 格式图标，包含多种尺寸
- 建议源图标尺寸 1024x1024 像素或更大，确保最佳质量

### Documentation

- 更新 README.md，添加应用图标生成功能的详细说明
- 更新 tool/README.md，补充图标生成工具的使用方法和特性介绍
- 提供清晰的命令示例和支持格式说明

## 0.9.1 - 2025-07-08

### Fixed

- 修复应用重命名工具的 Flutter 依赖问题，移除了对 `dart:ui` 的依赖
- 将 `app_renamer.dart` 从 `lib/src/` 移动到 `tool/` 目录，防止用户误导入
- 替换 `debugPrint` 为 `print`，确保命令行工具正常运行

### Enhanced

- 优化应用重命名工具的项目结构，提高代码组织性
- 完善文档说明，添加详细的使用指南和注意事项
- 在 `tool/README.md` 中添加对原始 rename_app 项目的鸣谢

### Documentation

- 简化根目录 README.md 中的重命名功能介绍
- 创建专门的 `tool/README.md` 文档，详细说明开发工具的使用方法
- 更新示例项目文档，统一命令格式

## 0.9.0 - 2025-07-03

### Added

- 新增智能边缘停靠功能，支持自动检测窗口拖拽行为并触发停靠
- 新增 `SmartDockManager` 类，实现完整的智能窗口停靠机制
- 支持边缘停靠和角落停靠两种智能停靠模式
- 添加鼠标悬停显示/离开隐藏的交互逻辑，类似 QQ 的停靠体验
- 新增 `setSmartEdgeDocking()` 方法，用于启用/禁用智能停靠
- 新增 `enableSimpleEdgeDocking()` 方法，支持手动边缘停靠
- 新增窗口展开/收缩控制方法：`toggleDockedWindow()`、`expandDockedWindow()`、`collapseDockedWindow()`

### Enhanced

- 优化动画系统，防止重复动画执行，提升性能
- 改进窗口停靠的用户体验，支持智能判断停靠类型
- 完善 README 文档，添加详细的智能停靠使用说明和功能对比表

### Fixed

- 修复动画过程中可能出现的重复执行问题
- 优化智能隐藏监听的启动和停止逻辑

## 0.8.0 - 2025-07-02

### Added

- 新增 `appBuilder` 参数，允许在 `MyXlyApp` 顶层注入全局 UI 组件。
- 新增 `MyFloatBar` 组件，一个可拖拽的浮动操作栏，可结合 `appBuilder` 使用。

## 0.7.0 (2025-07-01)

- **重构**：优化 `MyApp.initialize` 初始化逻辑，确立了“直接参数 -> 服务 -> 路由”的配置应用顺序，解决了因 UI 依赖（如 `flutter_screenutil`）初始化时机不当而导致的 `LateInitializationError`。
- **增强**：新增窗口可调整大小（`resizable`）的持久化设置，使其行为与现有的 `draggable` 设置一致，提升了用户体验。
- **文档**：在 `README.md` 中详细说明了新的初始化顺序和配置覆盖机制。
- **清理**：移除了代码中用于调试的 `debugPrint` 语句。

## 0.6.0 (2025-06-16)

- 新增窗口停靠功能：`MyApp.dockToCorner()`方法，支持窗口停靠到屏幕四个角落
- 新增`WindowCorner`枚举，定义窗口停靠位置（topLeft、topRight、bottomLeft、bottomRight）
- 集成`screen_retriever`依赖，用于获取屏幕信息和工作区域
- 窗口停靠功能自动检测任务栏位置，确保窗口不被遮挡
- 支持 Windows、macOS、Linux 桌面平台的窗口停靠
- 更新 README.md，添加窗口停靠功能的详细文档和使用示例
- 在示例页面添加窗口停靠测试按钮，方便功能验证
- 将`window_manager`和`screen_retriever`移至已重导出包列表

## 0.5.3

- 修复所有 60 个诊断消息（错误、警告、信息、提示）
- 将所有弃用的`withOpacity()`替换为`withValues(alpha: ...)`
- 修复弃用的颜色 API（alpha、red、green、blue）
- 替换弃用的`addScopedWillPopCallback`为`addLocalHistoryEntry`
- 修复弃用的`dialogBackgroundColor`API
- 将所有`print`语句替换为`debugPrint`
- 移除未使用的代码元素和变量
- 修复私有类型在公共 API 中使用的问题
- 解决 Windows 平台 CMake 构建错误

## 0.5.2

- 修复 README.md 中底部菜单示例代码错误，将`MyBottomMenu.show()`更正为`MyDialogSheet.showBottom()`

## 0.5.1

- 修复`flutter_inset_box_shadow`依赖问题，更新为`flutter_inset_shadow`[git: 00fdbe0]

## 0.4.0

- 新增 MyBottomMenu 组件
- 新增 MyEndOfListWidget 组件
- 新增 MyGroupBox 组件
- 新增 MyList 和 MyCardList 组件
- 新增 MyCard 组件
- 给菜单组件新增阴影效果

## 0.3.0

- 新增 Splash 页面
- 新增 MyDialog 组件
- 新增通过 Key 返回上一页或退出 App 功能
- 新增 MyApp.exit 功能
- 其他细节优化

## 0.2.0

- 新增 Focus 拓展
- 新增 MyButton 组件
- 新增 MyMenuItem 组件
- 新增 MyMenu 组件
- 新增 MyRouter 组件
- 新增 MyRouterOutlet 组件
- 新增 MyRouterOutletBuilder 组件

## 0.1.0

- 新增 MyApp.initialize 功能
