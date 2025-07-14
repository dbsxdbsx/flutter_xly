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
- 新增 `AdaptiveNavigationItem` 类用于定义导航项

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
