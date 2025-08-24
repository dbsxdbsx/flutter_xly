
## 0.18.0 - 2025-08-24

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
- 文本编辑器(MyTextEditor)下拉组件行为调整：移除了内部基于“最大可见项数”的滚动估算逻辑，统一改为使用实际可视区域与maxScrollExtent进行对齐滚动，避免滚动抖动与边界错位。

### Enhanced
- 下拉位置控制重构：当 dropdownShowBelow 为 false 时，通过位移统一在输入框上方展示。
- 自动滚动策略优化：选中项若超出可视区，上下对齐滚动以确保完整可见，动画更顺滑（150ms easeOut）。
- 结构清理：去除控制器中未使用的 _maxVisibleItems 字段与相关参数，API 更简洁。

### Documentation
- 智能托盘文档增强：
  - 补充“托盘左击（智能停靠隐藏下）仅模拟悬停弹出”的交互语义与示意流程图。
  - README 与 .doc/smart_tray_* 文档同步更新使用说明与最佳实践。



## 0.17.2 - 2025-08-08 [321935b]

### Enhanced
- **MyTextEditor下拉导航优化**：进一步完善键盘导航和用户交互体验
  - 优化键盘导航逻辑，提升选项选择的响应性和准确性
  - 改进鼠标与键盘交互的协调性，确保状态同步更加流畅
  - 完善下拉列表的显示和隐藏机制，减少不必要的重绘
  - 优化选项过滤和搜索性能，支持更大数据集的流畅操作

### Documentation
- **MyTextEditor使用指南更新**：补充最新功能说明和使用示例
  - 更新API文档，反映最新的功能改进和参数变化
  - 完善使用示例，包含更多实际应用场景
  - 优化参数说明和最佳实践建议

## 0.17.1 - 2025-08-07 [b014823]

### Enhanced
- **MyTextEditor文档全面完善**：大幅提升开发者使用体验和文档质量
  - 扩展README.md使用示例：从基础用法扩展为包含多种场景的完整示例集合
  - 创建专门使用指南：新增`.doc/my_text_editor_usage_guide.md`详细使用指南
  - 完整API文档：涵盖所有重要参数、使用场景和最佳实践
  - 参数速查表：提供便于开发者快速查找的参数对照表
  - 实用示例集合：包含基础用法、下拉建议、自定义样式、控制器管理等完整示例
  - 最佳实践指导：提供性能优化建议、常见问题解答和错误处理方案

## 0.17.0 - 2025-08-07 [7fa3910]

### Enhanced
- **MyTextEditor下拉导航系统全面升级**：完善键盘导航和用户交互体验
  - 智能键盘导航：支持上下箭头键精确导航，Enter键选择，Escape键关闭
  - 鼠标键盘协同：鼠标悬停与键盘导航状态智能同步，无缝切换
  - 智能滚动系统：选中项自动滚动到可视区域，支持大量选项的流畅导航
  - 防抖动机制：选择选项后智能防止下拉列表闪烁，提升交互流畅度
  - 手动关闭记忆：用户主动关闭下拉列表后，输入新内容前不会自动重新打开

### Fixed
- **下拉列表交互问题修复**：解决多种边界情况和用户体验问题
  - 修复键盘导航时焦点丢失问题，确保导航连续性
  - 修复选项选择后下拉列表意外重新打开的问题
  - 修复Escape键行为：优先关闭下拉列表，再让编辑器失去焦点
  - 修复大量选项时的显示和滚动问题，支持完整选项列表展示

## 0.16.0 - 2025-08-01

### Added
- **智能导航系统**：为MyScaffold添加完整的智能导航解决方案
  - 自动路由同步：侧边栏选中状态与当前路由自动同步，无论通过什么方式导航
  - 简化导航API：只需指定route参数即可自动导航，无需手写onTap回调
  - 智能自动滚动：当侧边栏有很多菜单项时，选中项自动滚动到可视区域
  - 可配置滚动条：alwaysShowScrollbar参数控制滚动条显示行为
  - 可配置自动滚动：autoScrollToSelected参数控制自动滚动功能

### Enhanced
- **MyAdaptiveNavigationItem增强**：添加route参数支持自动导航
  - 优先使用自定义onTap，如果没有则使用route自动导航
  - 完全向后兼容，现有代码无需修改
  - 大幅简化用户代码，提升开发效率

- **导航体验优化**：移除所有不必要的延迟，提升响应速度
  - 即时的界面更新和状态同步
  - 优化路由监听机制，100ms高频检查确保及时响应
  - 平滑的300ms滚动动画，使用ScreenUtil响应式尺寸计算

### Fixed
- **SpinBox组件命名统一**：将"自定义编辑框"统一为标准命名
  - 修复页面导航按钮使用Get.toNamed而非Get.back，确保精确导航
  - 统一所有页面的导航按钮风格，提供一致的用户体验

## 0.15.0 - 2025-08-01

### Added
- **MyTray简化配置**：在MyApp.initialize中添加tray参数，提供更简洁的配置方式
  - 新增tray参数支持，可直接传入MyTray实例进行配置
  - 保持向后兼容，传统MyService<MyTray>方式仍然支持
  - 更新文档和示例，展示新的简化使用方式

### Enhanced
- **MyScaffold响应式单位支持**：全面支持ScreenUtil响应式单位
  - 所有内部尺寸属性使用.w/.h/.r/.sp响应式单位
  - 包括边距、内边距、圆角、容器尺寸、图标大小等
  - 菜单项文本和徽章文本支持响应式字体缩放(.sp)
  - 提供更好的跨设备适配体验

- **智能停靠状态下功能冲突防护**：在智能停靠状态下自动禁用可能冲突的窗口功能
  - 双击最大化功能在智能停靠状态下自动禁用，防止破坏停靠布局
  - 全屏功能在智能停靠状态下自动禁用，避免状态冲突
  - UI按钮智能显示禁用状态和原因，提供友好的用户反馈
  - 操作时显示明确提示，告知用户如何恢复功能（先关闭智能停靠）

- **全屏功能支持**：新增完整的全屏功能API和UI控制
  - 新增 `MyApp.isFullScreenEnabled()` 检查全屏功能可用性
  - 新增 `MyApp.setFullScreenEnabled()` 控制全屏功能启用状态
  - 新增 `MyApp.toggleFullScreen()` 切换全屏状态
  - 全屏功能与智能停靠智能交互，避免功能冲突

### Changed
- **命名一致性改进**：重命名AdaptiveNavigationItem为MyAdaptiveNavigationItem
  - 保持与其他My系列组件的命名一致性
  - 更新所有相关文档和示例代码

- **组件命名统一**：将SpinBox相关术语统一更新为"自定义编辑框"
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
- **CHANGELOG的git提交**：[1dfae6d]

### Enhanced
- **智能停靠状态下功能冲突防护**：在智能停靠状态下自动禁用可能冲突的窗口功能
  - 双击最大化功能在智能停靠状态下自动禁用，防止破坏停靠布局
  - 全屏功能在智能停靠状态下自动禁用，避免状态冲突
  - UI按钮智能显示禁用状态和原因，提供友好的用户反馈
  - 操作时显示明确提示，告知用户如何恢复功能（先关闭智能停靠）

### Added
- **全屏功能支持**：新增完整的全屏功能API和UI控制
  - 新增 `MyApp.isFullScreenEnabled()` 检查全屏功能可用性
  - 新增 `MyApp.setFullScreenEnabled()` 控制全屏功能启用状态
  - 新增 `MyApp.toggleFullScreen()` 切换全屏状态
  - 全屏功能与智能停靠智能交互，避免功能冲突

### Improved
- **概念澄清和命名优化**：修正全屏和最大化功能的概念混淆
  - 重命名 `isDoubleClickFullScreenEnabled()` → `isDoubleClickMaximizeEnabled()`
  - 重命名 `setDoubleClickFullScreenEnabled()` → `setDoubleClickMaximizeEnabled()`
  - 明确区分：最大化（占据工作区域，任务栏可见）vs 全屏（占据整个屏幕，隐藏系统UI）
  - 移除不必要的F11快捷键，保持应用简洁性

### Documentation
- **智能托盘技术文档**：新增 `.doc/smart_tray_technical.md` 详细技术实现说明
- **智能托盘用户指南**：新增 `.doc/smart_tray_user_guide.md` 用户使用指南
- **全屏功能文档**：在README.md中添加全屏功能的详细使用说明
  - 基本API使用方法
  - 与智能停靠的交互说明
  - 全屏vs最大化的区别说明
  - 注意事项和最佳实践

### Technical
- **智能托盘隐藏机制**：完善智能停靠状态下的托盘隐藏逻辑
  - 智能停靠激活时自动进入托盘模式，隐藏任务栏图标
  - 窗口焦点管理：获得焦点时保持任务栏隐藏状态
  - 退出智能停靠时自动恢复任务栏显示
- **状态管理优化**：改进GetX响应式状态管理，修复UI更新问题

## 0.14.2 - 2025-07-28 [3c6360c]

### Enhanced
- **简化MyTray配置**：在 `MyApp.initialize` 中添加 `tray` 参数，提供更简洁的托盘配置方式
  - 新增 `tray: MyTray(...)` 参数，无需了解GetxService概念
  - 保持向后兼容：传统的 `MyService<MyTray>` 方式仍然支持
  - 配置优先级：如果同时提供 `tray` 参数和 `services` 中的MyTray，`tray` 参数优先
- **用户体验改进**：降低新手使用门槛，与其他功能（如splash、theme等）的配置方式保持一致

### Documentation
- 更新README.md，展示新的简化配置方式，同时保留传统方式说明
- 更新.doc/my_tray_design.md，添加推荐和传统两种初始化方式的对比
- 更新example项目，使用新的简化配置方式

### Fixed
- 移除example/page9.dart中的"恢复窗口"按钮，简化界面

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
- **API简化**：`MyTray.setIcon()` 方法的参数现在可选，为空时使用默认应用图标
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
- 新增示例页面8 (page8.dart)，展示托盘和通知功能的完整使用示例
- 新增托盘图标资源 (example/assets/icons/tray.ico)，为示例应用提供托盘图标

### Enhanced
- 完善 `MyApp` 类，新增对托盘和通知服务的支持
- 优化示例应用的服务注册，展示托盘和通知功能的集成方式
- 改进README文档，新增托盘和通知功能的详细介绍和使用示例
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
- 新增MyScaffold的leading参数支持，允许自定义左侧组件
- 新增MyScaffold的trailing参数支持，允许自定义右侧组件
- 新增示例服务类ExampleService，展示服务层架构

### Enhanced
- 完善MyScaffold自适应侧边栏功能，优化不同屏幕尺寸下的表现
- 改进MyScaffold在mini模式下的汉堡菜单图标显示逻辑
- 优化示例页面的导航和布局，提升用户体验
- 改进平台信息显示组件，增加更多系统信息展示
- 完善README文档，新增自适应侧边栏相关文档链接

### Fixed
- 修复智能隐藏dock功能的拖拽动画问题：增加拖拽完成检测，避免拖拽过程中过早触发对齐动画
- 重大简化：智能隐藏dock功能现在直接对齐到真正的屏幕边缘/角落，完全忽略任务栏
- 确保智能隐藏dock功能的拖拽对齐和鼠标悬停弹出位置一致性

### Documentation
- 新增智能隐藏dock功能修复总结文档 (.doc/smart_dock_fix_summary.md)

## 0.13.0 - 2025-07-15

### Added
- 新增自适应侧边栏实现指南文档 (.doc/adaptive_sidebar_implementation_guide.md)
- 新增自适应侧边栏使用文档 (.doc/adaptive_sidebar_usage.md)
- 新增MyScaffold的leading参数支持，允许自定义左侧组件
- 新增MyScaffold的trailing参数支持，允许自定义右侧组件
- 新增示例服务类ExampleService，展示服务层架构

### Enhanced
- 完善MyScaffold自适应侧边栏功能，优化不同屏幕尺寸下的表现
- 改进MyScaffold在mini模式下的汉堡菜单图标显示逻辑
- 优化示例页面的导航和布局，提升用户体验
- 改进平台信息显示组件，增加更多系统信息展示
- 完善README文档，新增自适应侧边栏相关文档链接

### Fixed
- 修复MyScaffold在不同模式切换时的UI一致性问题
- 解决示例页面在不同屏幕尺寸下的布局适配问题

## 0.12.0 - 2025-07-14

### Added
- 新增智能停靠系统重构，将原有单一文件拆分为模块化架构
- 新增 `DockDetector` 类，专门负责检测窗口是否接近屏幕边缘
- 新增 `MouseTracker` 类，处理鼠标位置追踪和悬停检测
- 新增 `NativeWindowHelper` 类，封装原生窗口操作API
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
- 更新主README文档中的智能停靠功能说明
- 完善代码注释，提升代码可读性

## 0.11.0 - 2025-07-12

### Added
- 新增细粒度平台检测功能到MyPlatform类
- 新增 `MyPlatform.isWeb` - 检测Web平台
- 新增 `MyPlatform.isWindows` - 检测Windows平台
- 新增 `MyPlatform.isMacOS` - 检测macOS平台
- 新增 `MyPlatform.isLinux` - 检测Linux平台
- 新增 `MyPlatform.isAndroid` - 检测Android平台
- 新增 `MyPlatform.isIOS` - 检测iOS平台
- 新增 `MyPlatform.isFuchsia` - 检测Fuchsia平台
- 新增 `MyPlatform.platformName` - 获取当前平台友好名称
- 在示例应用中新增平台信息显示组件，位于自适应侧边栏底部

### Enhanced
- 完善平台检测功能的单元测试覆盖
- 更新README文档，展示细粒度平台检测的使用方法
- 优化示例应用的平台信息展示，采用类似系统信息面板的设计风格

### Documentation
- 更新功能列表，强调跨平台工具类支持细粒度平台检测
- 新增完整的平台检测使用示例和API说明

## 0.10.3 - 2025-07-12

### Fixed
- 修正README中平台检测方法的错误调用方式
- 将 `MyPlatform.isDesktopOs()` 更正为 `MyPlatform.isDesktop`
- 将 `MyPlatform.isMobileOs()` 更正为 `MyPlatform.isMobile`
- 确保文档示例与实际API保持一致

## 0.10.2 - 2025-07-12

### Documentation
- 改进Toast功能文档说明，明确区分普通模式和堆叠模式的差异
- 修正README中Toast参数名称不一致问题（`stackToasts` → `stackPreviousToasts`）
- 新增Toast显示模式对比示例，帮助用户理解"连续显示Toast"的实现原理
- 优化Toast特性列表，突出显示两种显示模式的区别和使用场景

## 0.10.1 - 2025-07-09

### Added
- 新增窗口比例调整控制功能：`MyApp.setAspectRatioEnabled()` 和 `MyApp.isAspectRatioEnabled()`
- 在 `MyApp.initialize()` 中新增 `setAspectRatioEnabled` 参数，默认值为 `true`
- 支持动态启用/禁用窗口固定比例调整，提供更灵活的窗口管理体验

### Enhanced
- 更新功能列表，新增"窗口比例调整控制"功能说明
- 在示例页面1中新增窗口比例调整切换按钮，方便用户测试该功能
- 优化窗口控制按钮布局，将原来的3个按钮重新排列为2行，提升界面美观性

### Documentation
- 更新 README.md，新增窗口控制API部分，详细介绍窗口比例调整功能
- 为窗口比例调整功能提供完整的使用示例和特性说明

## 0.10.0 - 2025-07-09

### Added
- 新增自适应侧边栏导航组件 `MyScaffold`
- 根据屏幕尺寸自动切换显示模式：小屏幕使用抽屉或底部导航，中屏幕使用收缩侧边栏，大屏幕使用展开侧边栏
- 支持类似传统Flutter Scaffold的API设计，提供 `drawer`、`body`、`appBar` 等参数
- 支持自定义断点宽度、抽屉宽度比例等配置选项
- 支持导航项徽章显示和侧边栏底部额外内容
- 新增 `MyAdaptiveNavigationItem` 类用于定义导航项

### Enhanced
- 更新功能列表，新增"自适应侧边栏导航"功能说明
- 优化示例项目，展示自适应导航的使用方式
- 改进 `MyList` 组件的GlobalKey重复问题处理

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
- 更新功能列表，将"基于shared_preferences的本地存储"改为"基于GetStorage的本地存储"
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
- 添加鼠标悬停显示/离开隐藏的交互逻辑，类似QQ的停靠体验
- 新增 `setSmartEdgeDocking()` 方法，用于启用/禁用智能停靠
- 新增 `enableSimpleEdgeDocking()` 方法，支持手动边缘停靠
- 新增窗口展开/收缩控制方法：`toggleDockedWindow()`、`expandDockedWindow()`、`collapseDockedWindow()`

### Enhanced
- 优化动画系统，防止重复动画执行，提升性能
- 改进窗口停靠的用户体验，支持智能判断停靠类型
- 完善README文档，添加详细的智能停靠使用说明和功能对比表

### Fixed
- 修复动画过程中可能出现的重复执行问题
- 优化智能隐藏监听的启动和停止逻辑

## 0.8.0 - 2025-07-02

### Added
- 新增 `appBuilder` 参数，允许在 `MyXlyApp` 顶层注入全局UI组件。
- 新增 `MyFloatBar` 组件，一个可拖拽的浮动操作栏，可结合 `appBuilder` 使用。

## 0.7.0 (2025-07-01)

- **重构**：优化 `MyApp.initialize` 初始化逻辑，确立了“直接参数 -> 服务 -> 路由”的配置应用顺序，解决了因UI依赖（如 `flutter_screenutil`）初始化时机不当而导致的 `LateInitializationError`。
- **增强**：新增窗口可调整大小（`resizable`）的持久化设置，使其行为与现有的 `draggable` 设置一致，提升了用户体验。
- **文档**：在 `README.md` 中详细说明了新的初始化顺序和配置覆盖机制。
- **清理**：移除了代码中用于调试的 `debugPrint` 语句。

## 0.6.0 (2025-06-16)

- 新增窗口停靠功能：`MyApp.dockToCorner()`方法，支持窗口停靠到屏幕四个角落
- 新增`WindowCorner`枚举，定义窗口停靠位置（topLeft、topRight、bottomLeft、bottomRight）
- 集成`screen_retriever`依赖，用于获取屏幕信息和工作区域
- 窗口停靠功能自动检测任务栏位置，确保窗口不被遮挡
- 支持Windows、macOS、Linux桌面平台的窗口停靠
- 更新README.md，添加窗口停靠功能的详细文档和使用示例
- 在示例页面添加窗口停靠测试按钮，方便功能验证
- 将`window_manager`和`screen_retriever`移至已重导出包列表

## 0.5.3

- 修复所有60个诊断消息（错误、警告、信息、提示）
- 将所有弃用的`withOpacity()`替换为`withValues(alpha: ...)`
- 修复弃用的颜色API（alpha、red、green、blue）
- 替换弃用的`addScopedWillPopCallback`为`addLocalHistoryEntry`
- 修复弃用的`dialogBackgroundColor`API
- 将所有`print`语句替换为`debugPrint`
- 移除未使用的代码元素和变量
- 修复私有类型在公共API中使用的问题
- 解决Windows平台CMake构建错误

## 0.5.2

- 修复README.md中底部菜单示例代码错误，将`MyBottomMenu.show()`更正为`MyDialogSheet.showBottom()`

## 0.5.1

- 修复`flutter_inset_box_shadow`依赖问题，更新为`flutter_inset_shadow`[git: 00fdbe0]

## 0.4.0

* 新增MyBottomMenu组件
* 新增MyEndOfListWidget组件
* 新增MyGroupBox组件
* 新增MyList和MyCardList组件
* 新增MyCard组件
* 给菜单组件新增阴影效果

## 0.3.0

* 新增Splash页面
* 新增MyDialog组件
* 新增通过Key返回上一页或退出App功能
* 新增MyApp.exit功能
* 其他细节优化


## 0.2.0

* 新增Focus拓展
* 新增MyButton组件
* 新增MyMenuItem组件
* 新增MyMenu组件
* 新增MyRouter组件
* 新增MyRouterOutlet组件
* 新增MyRouterOutletBuilder组件

## 0.1.0

* 新增MyApp.initialize功能
