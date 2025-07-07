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
