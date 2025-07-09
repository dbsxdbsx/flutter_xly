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
