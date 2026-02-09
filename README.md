# XLY 包

XLY 是一个 Flutter 懒人工具包，提供了一些常用的功能和组件。虽然目前仍在开发中，但已经可以在项目中使用许多实用功能。

## 功能（Features）

当前，这个包提供了以下功能：

1. 基于 GetX 的状态管理(不用再加入"get"包了)
2. 基于 ScreenUtil 的屏幕适配(不用再加入"flutter_screenutil"包了)
3. 基于 window_manager 的窗口管理(不用再加入"window_manager"包了)
4. 基于 screen_retriever 的屏幕信息获取(不用再加入"screen_retriever"包了)
5. 基于 GetStorage 的本地存储(不用再加入"get_storage"包了)
6. Toast 消息显示(内置实现，支持自定义动画和样式)
7. 导航辅助函数
8. 自定义按钮组件
9. 自定义菜单组件
10. 焦点管理(针对只能键盘或遥控操作的 App 很有用)
11. 自定义文本编辑器(支持下拉建议和样式自定义)
12. 自定义编辑框(支持步进调节和范围控制)
13. 列表组件(`MyList`和`MyCardList`)(支持拖拽重排序、滑动删除、加载更多等功能)
14. 卡片组件(`MyCard`)(支持 leading/trailing、点击事件、拖拽、滑动删除等)
15. 分组框组件(`MyGroupBox`)(带标题的分组容器，支持多种边框样式)
16. 列表底部状态组件(`MyEndOfListWidget`)(支持加载中、错误重试、到底提示等状态)
17. 增强图标按钮(`MyIcon`)(支持悬停效果、工具提示、自定义样式)
18. URL 启动器组件(`MyUrlLauncher`)(包装任意 Widget 使其可点击打开链接)
19. 跨平台工具类(支持文件操作、权限管理、窗口控制、细粒度平台检测等)
20. 开机自启动管理(支持桌面和 Android 平台)
21. 窗口停靠功能(支持停靠到屏幕四个角落，自动避开任务栏)
22. 边缘停靠功能(类似 QQ 的窗口边缘隐藏和鼠标悬停显示功能)
23. 智能边缘停靠机制(自动检测窗口拖拽到边缘并触发停靠)
24. 服务管理系统(确保服务在 ScreenUtil 初始化后注册，避免.sp 等扩展方法返回无限值)
25. 全局 UI 构建器(`appBuilder`)(支持在应用顶层添加自定义组件，如全局浮动按钮)
26. 全局浮动面板(`FloatPanel`)(一个可拖动、可停靠、可展开的浮动面板，支持智能联动)
27. 自适应侧边栏导航(`MyScaffold`)(M3 五层级：Compact/Medium/Expanded/Large/XLarge，支持分组标题、副标题、导航 Header)
28. 窗口比例调整控制(支持动态启用/禁用窗口固定比例调整功能)
29. 系统托盘管理(`MyTray`)(支持托盘图标、右键菜单、窗口最小化到托盘等功能)
30. 系统通知管理(`MyNotify`)(跨平台系统通知，支持即时通知、定时通知、多种通知类型)
31. 多点动态加载指示器(`MyLoadingDot`)(支持 fade/bounce/scale/wave 四种动画效果，自适应容器宽度)
32. 单实例管理(`SingleInstanceManager`)(确保应用只运行一个实例，支持激活已有实例)
33. 分段选项卡组件(`MyTabView`/`MySegmentedControl`)(macOS 风格 Tab 切换，支持选中态滑块滑动动画、compact/stretched 两种布局模式、顶部/底部位置、自定义样式和内容切换动画)

## 内置依赖包

使用本包后，您无需再单独导入以下包：

### 已重导出的包（可直接使用）

- `get: ^4.7.3` - GetX 状态管理
- `flutter_screenutil: ^5.9.3` - 屏幕适配
- `window_manager: ^0.5.1` - 窗口管理
- `screen_retriever: ^0.2.0` - 屏幕信息获取
- `get_storage: ^2.1.1` - 本地存储

### 内部使用的包（多数情况无需关心，本 xly 包有相应功能可直接使用）

- `lottie: ^3.1.2` - Lottie 动画
- `path_provider: ^2.1.2` - 路径管理
- `permission_handler: ^12.0.1` - 权限管理
- `autostart_settings: ^0.1.4` - 自启动设置（Android）
- `launch_at_startup: ^0.5.1` - 开机自启动（桌面）
- `package_info_plus: ^9.0.0` - 应用信息
- `flutter_inset_shadow: ^2.0.3` - 内阴影
- `url_launcher: ^6.2.5` - URL 启动器
- `path: ^1.8.0` - 路径操作
- `xml: ^6.5.0` - XML 解析
- `tray_manager: ^0.5.2` - 系统托盘管理
- `flutter_local_notifications: ^20.0.0` - 本地通知
- `timezone: ^0.10.0` - 时区处理

## 命令行工具

XLY 提供了便捷的命令行工具，可通过交互式菜单或直接执行子命令：

```bash
# 显示交互式菜单（推荐新手使用）
dart run xly

# 直接执行子命令
dart run xly generate icon "path/to/icon.png"
dart run xly rename all "应用名称"
dart run xly win_setup

# 或使用冒号语法直接调用
dart run xly:generate icon "path/to/icon.png"
```

> ⚠️ **非 ASCII 字符提示**：如果路径或名称包含非 ASCII 字符（如中文、日文等），建议使用 `dart run xly:<command>` 直接执行，而非通过交互式菜单输入，以避免终端编码问题。

## 应用图标生成

本包内置自研的图标生成工具，支持一键为所有平台生成应用图标。

```bash
# 从单个源图标生成所有平台的图标
dart run xly:generate icon "path/to/your/icon.png"

# 支持带空格的路径
dart run xly:generate icon "C:\My Images\app icon.png"
```

支持的平台：

- Android（多种密度的 mipmap 图标）
- iOS（包含所有尺寸规格，自动移除 alpha 通道）
- Windows（ICO 格式，包含多种尺寸）
- macOS（包含 Contents.json 配置）
- Linux（256x256 PNG）
- Web（包含 favicon 和 PWA 图标）

特性：

- 自动检测项目中存在的平台
- 支持 PNG、JPEG、JPG 格式输入
- 自动创建必要的目录结构
- 生成平台特定的配置文件
- 建议源图标尺寸：1024x1024 像素或更大

详细使用说明和注意事项请参考：[本地](tool/README.md) | [GitHub](https://github.com/dbsxdbsx/flutter_xly/blob/main/tool/README.md)

## 待办事项（TODOs）

- 静默启动？`  bool showWindowOnInit = true,` param? ✅ 已实现
- add `My` prefix for some of exported widgets, like `FloatButtonState`,etc?
- what the `ExampleService` used for, can it be removed?
- right menu 子菜单 issue
- MyToggleBtn?
- permission 功能？
- clear the Print and DebugPrint for avoid ruin user code?

## 注意事项（Notes）

### 关于 keyToRollBack 参数的行为优化

**回退键处理逻辑**：`keyToRollBack` 参数现在采用更智能的处理方式：

1. **优先处理弹层**：回退键首先尝试关闭当前打开的弹层（Dialog、BottomSheet、PopupMenu、Drawer 等）
2. **双击回退/退出**：只有在没有弹层可关闭时，才进入原有的双击回退/退出逻辑
3. **用户体验提升**：避免了"弹层打开时按回退键直接退出应用"的反直觉行为

**示例场景**：

```dart
// 设置回退键（可以是任意键）
keyToRollBack: LogicalKeyboardKey.escape,  // 或 backspace、f1 等

// 行为表现：
// 1. Dialog打开时按回退键 → 关闭Dialog
// 2. Drawer打开时按回退键 → 关闭Drawer
// 3. 无弹层时按回退键 → 显示"再按一次退出/返回"提示
// 4. 双击回退键 → 执行退出/返回操作
```

### 关于 navigatorKey 参数的移除

**重要变更**：从当前版本开始，我们移除了 `MyApp.initialize` 的 `navigatorKey` 参数。

**变更原因**：

- XLY 以 GetX 为路由/对话框基座，已提供无 Context 导航能力（`Get.toNamed`、`Get.back`、`Get.dialog`）
- 提供全局 BuildContext（`Get.context`/`Get.overlayContext`）以及全局 NavigatorKey（`Get.key`）
- 继续暴露 `navigatorKey` 只会增加使用者的心智负担，且绝大多数场景并不需要

**兼容性影响**：

- 这是一次不兼容变更（移除 API 参数）
- 如果你之前传递了 `navigatorKey`，请删除该参数
- 如果你的代码使用了自定义的全局 `navigatorKey` 来获取 context 或做原生 `showDialog`，请改为：
  - 使用 `Get.dialog` / `Get.back`，或
  - 使用 `Get.context` / `Get.overlayContext` 获取 context

**迁移指南**：

1. 删除 main.dart 中的自定义 `GlobalKey<NavigatorState>` 定义与传参
2. 将 `showDialog(context: xxx)` 替换为 `Get.dialog(...)`；或将 `xxx` 替换为 `Get.context ?? Get.overlayContext`
3. 如确需 NavigatorState，使用 `Get.key.currentState`

**FAQ**：

- Q: 我有第三方库要我"传入 navigatorKey"怎么办？
- A: 大多数库仅需 `navigatorObservers` 或支持 GetX 的 API。极少数需要直接操作 NavigatorState 的，可通过 `Get.key` 访问全局 NavigatorState；不需要在 `MyApp.initialize` 上传参数。

### MyTray 组件设计

- 系统托盘功能组件设计文档：[本地](.doc/my_tray_design.md) | [GitHub](https://github.com/dbsxdbsx/flutter_xly/blob/main/.doc/my_tray_design.md)
- 提供完整的托盘图标管理、窗口最小化到托盘等功能
- 遵循"无隐式消息"设计原则，只有用户明确操作时才显示反馈
- 仅在桌面平台（Windows/macOS/Linux）可用
- **智能默认图标**：`iconPath` 参数现在可选，为空时自动使用各平台的默认应用图标，图标缺失时提供详细错误信息和解决方案

#### Windows 托盘菜单关闭问题及解决方案

**已知问题**：在 Windows 平台上，托盘右键菜单弹出后，点击屏幕其他区域可能无法关闭菜单（参考：[tray_manager#63](https://github.com/leanflutter/tray_manager/issues/63)）

**解决方案**：XLY 包已内置修复，使用`bringAppToFront: true`参数调用`popUpContextMenu()`。虽然此参数已被标记为 deprecated，但它是目前最简单有效的解决方案。

**用户如何关闭菜单**：

- ✅ 点击任意菜单项（菜单自动关闭）
- ✅ 按 ESC 键（标准 Windows 行为）
- ✅ 再次右键托盘图标（新菜单替换旧菜单）
- ✅ 点击窗口区域（在应用了修复后可用）

**注意**：此修复已自动应用，开发者无需额外操作。如遇到菜单无法关闭的问题，可能是使用了较旧版本的 tray_manager 包，建议升级到最新版本。

### Flutter 桌面多窗口开发

- 多窗口开发完整指南：[本地](.doc/flutter_multi_window_guide.md) | [GitHub](https://github.com/dbsxdbsx/flutter_xly/blob/main/.doc/flutter_multi_window_guide.md)
- 详细分析了 Flutter 桌面多窗口的技术现状、实现方案对比、XLY 当前能力和推荐策略
- **当前状态**：Flutter 官方多窗口（单引擎多视图）仍在开发中，预计 2025 年下半年~2026 年稳定
- **推荐策略**：使用 XLY 现有的单窗口 + 模式切换能力，等待官方方案稳定后再集成

### MyNotify 系统通知组件

- 系统通知功能使用指南：[本地](.doc/my_notify_usage_guide.md) | [GitHub](https://github.com/dbsxdbsx/flutter_xly/blob/main/.doc/my_notify_usage_guide.md)
- 基于 `flutter_local_notifications` 包封装的跨平台通知管理器
- 支持即时通知和定时通知，多种通知类型（信息、警告、错误、成功）
- 自动处理权限管理和状态监控
- 支持所有平台：Android、iOS、macOS、Windows、Linux
- 与 MyTray 职责分离：MyTray 专注托盘管理，MyNotify 专注系统通知

### MyTextEditor 高级文本编辑器

- 详细使用指南：[本地](.doc/my_text_editor_usage_guide.md) | [GitHub](https://github.com/dbsxdbsx/flutter_xly/blob/main/.doc/my_text_editor_usage_guide.md)
- 支持智能下拉建议、键盘导航、自定义样式等高级特性
- 智能键盘导航：上下箭头键导航，Enter 选择，Escape 关闭
- 鼠标键盘协同：鼠标悬停与键盘导航状态智能同步
- 自动滚动系统：选中项自动滚动到可视区域，支持大量选项流畅导航
- 防抖动机制：选择选项后智能防止下拉列表闪烁
- 手动关闭记忆：用户主动关闭下拉列表后，输入新内容前不会自动重新打开

### MyLoadingDot 多点动态加载指示器

- 详细使用指南：[本地](.doc/my_loading_dot_usage_guide.md) | [GitHub](https://github.com/dbsxdbsx/flutter_xly/blob/main/.doc/my_loading_dot_usage_guide.md)
- 支持 fade/bounce/scale/wave 四种动画效果，适应不同使用场景
- 自适应容器宽度，智能调整点大小和间距，避免布局越界
- 单控制器驱动多点相位动画，性能优化，资源消耗低
- 提供`MyLoadingDot.typing()`工厂方法，专为聊天"正在输入"场景优化
- 支持随机化起始相位，避免多实例同步问题

### MyScaffold 响应式改进

- 所有内部尺寸属性已全面使用 ScreenUtil 响应式单位（.w/.h/.r/.sp）
- 包括边距、内边距、圆角、容器尺寸、图标大小、字体大小等
- 菜单项文本和徽章文本现在支持响应式字体缩放
- 提供更好的跨设备适配体验，在不同屏幕密度下保持一致的视觉效果

### 初始化顺序与配置覆盖

`MyApp.initialize`的配置应用顺序遵循以下核心原则：

1. **`MyApp.initialize`的直接参数**：方法调用时直接传入的配置，如`designSize`、`exitInfoText`等。
2. **`services`列表中的服务**：在`services`列表中注册的`GetxService`。
3. **路由**：通过`routes`参数配置的页面和控制器。

这种顺序意味着**服务（`services`）中加载的设置会覆盖`MyApp.initialize`方法中直接传入的同名参数**。例如，如果一个服务从本地存储中加载了持久化的主题设置，它将覆盖`MyApp.initialize`中设置的默认主题。

这是一个有意为之的设计，目的是为了让用户的个性化、持久化设置拥有更高的优先级，从而提供更符合直觉的用户体验。

### 单实例机制说明

XLY 包内置单实例管理功能，确保应用在同一台设备上只能运行一个实例。当尝试启动第二个实例时，会自动激活已有实例并退出新实例。

#### 配置参数

在`MyApp.initialize`中可配置以下单实例相关参数：

- `singleInstance`（默认：`true`）：是否启用单实例功能
- `singleInstanceKey`（默认：使用`appName`或`'XlyFlutterApp'`）：实例唯一标识符
- `singleInstanceActivateOnSecond`（默认：`true`）：检测到已有实例时是否激活它

#### 工作原理

- 使用 TCP 端口锁机制确保跨进程的实例检测
- 端口号通过稳定的字符串哈希算法生成（30000-39999 范围）
- 仅在桌面平台（Windows/macOS/Linux）生效，移动端和 Web 端自动跳过
- 当检测到已有实例时，会发送 HTTP 激活请求并自动退出当前实例

#### 注意事项

- 确保`singleInstanceKey`在不同版本间保持一致，避免多实例并存
- 激活已有实例时会自动显示窗口并获得焦点
- 单实例检查在其他初始化步骤之前进行，避免创建多余的窗口资源

### 窗口初始化参数说明

`MyApp.initialize` 中的窗口控制参数已重命名以提升语义清晰度：

- **`showWindowOnInit`**（默认：`true`）：是否在初始化完成后显示窗口

  - 仅在初始化时生效，后续可通过 `windowManager.show()/hide()` 控制
  - 设置为 `false` 可实现"后台启动"或"托盘优先启动"
  - 采用简化的控制逻辑，确保窗口状态与参数设置一致

- **`focusWindowOnInit`**（默认：`true`）：是否在初始化时让窗口获得焦点

  - **仅在 `showWindowOnInit: true` 时生效**，若窗口不显示则此参数无效
  - 设置为 `false` 可让窗口显示但不抢夺用户当前焦点（如用户正在其他应用中打字）
  - 后续可通过 `windowManager.focus()/blur()` 控制

- **`centerWindowOnInit`**（默认：`true`）：是否在初始化时将窗口居中显示
  - 仅在初始化时生效，后续可通过 `windowManager.center()` 或 `windowManager.setPosition()` 控制

**技术说明**：为解决 Windows runner 默认模板的首帧强制显示问题，xly 内部实现了多层校正机制，确保最终窗口状态与参数设置严格一致。如需完全根除短暂闪现，可使用本包提供的工具对 Windows runner 进行一键优化。

### 根除 Windows 启动闪现：静默启动补丁

**问题**：即使在 `MyApp.initialize` 中设置 `showWindowOnInit: false`，你的 Flutter Windows 应用在启动时可能仍会短暂闪现一个白屏或黑屏窗口。这是因为 Flutter 官方的 Windows runner 模板默认会在渲染第一帧后强制显示窗口。

**解决方案**：本包提供了一个安全的、非侵入式的一键补丁工具，用于注释掉你项目中 `windows/runner/flutter_window.cpp` 文件里的强制显示代码，将窗口显示时机完全交由 Dart 侧控制。

**如何使用**：

1.  打开终端，`cd` 到你的 Flutter 项目根目录。
2.  执行以下命令：

    ```bash
    dart run xly:win_setup
    ```

**这个工具会做什么**：

- **精确查找**：它会精确查找并注释掉 `flutter_window.cpp` 中导致问题的 `this->Show()` 和 `flutter_controller_->ForceRedraw()` 两行代码。
- **保持安全**：它不会删除或覆盖你的任何其他自定义代码。如果你的文件已被修改过，它会安全跳过。
- **自动备份**：默认情况下，它会为你创建一个 `flutter_window.cpp.bak` 备份文件。

**静默启动配置**：

要实现完美的静默启动（窗口不显示、无闪现），需要两步配合：

1. **运行补丁工具**（一次性）：`dart run xly:win_setup`
2. **设置初始化参数**（在 Dart 代码中）：

```dart
await MyApp.initialize(
  showWindowOnInit: false,  // 不自动显示窗口（静默启动只需这一个参数）
  // ... 其他参数
);
```

应用此补丁后，窗口显示时机完全由 Dart 侧控制，直到你通过 `windowManager.show()` 或 `MyTray.to.pop()` 等方式主动显示它，从而彻底告别启动闪现。这是一个**一劳永逸**的优化。

> **注意**：静默启动时 `focusWindowOnInit` 参数无效（因为窗口根本不显示）。若需要"显示窗口但不抢焦点"，请使用 `showWindowOnInit: true` + `focusWindowOnInit: false`。

**高级选项**：

```bash
# 在位于其他目录的项目上运行
dart run xly:win_setup --project-dir="C:/path/to/your/project"

# 演练模式，只看不改
dart run xly:win_setup --dry-run

# 同时生成 .clangd 配置文件（抑制 C++ IDE 中的 clangd 误报）
dart run xly:win_setup --clangd

# 跳过 .clangd 提示（用于 CI/CD 自动化）
dart run xly:win_setup --no-clangd
```

> **关于 .clangd**：如果你使用 clangd 作为 C++ 语言服务器（如在 VS Code 或 Neovim 中），可能会看到关于 Windows SDK 头文件的误报警告。使用 `--clangd` 选项可自动生成配置文件来抑制这些误报。对于不使用 clangd 的普通 Flutter 开发者，默认情况下会交互式询问，直接按 Enter 跳过即可。

## 使用示例（Examples）

### 初始化应用

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xly/xly.dart';

import 'pages/page1.dart';
import 'pages/page2.dart';
import 'pages/page3.dart';

void main() async {
  await MyApp.initialize(
    designSize: const Size(800, 600),

    // 服务配置 - 确保在ScreenUtil初始化后注册，避免.sp等扩展方法返回无限值
    services: [
      MyService<YourCustomService>(
        service: () => YourCustomService(),
        permanent: true,  // 永久服务
      ),
      MyService<AnotherService>(
        service: () => AnotherService(),
        fenix: true,      // 懒加载服务，支持自动重建
      ),
    ],

    splash: const MySplash(
      nextRoute: Routes.page1,
      lottieAssetPath: 'assets/animation/splash_loading.json',
      appTitle: 'My Awesome App',
      backgroundColor: Colors.blueGrey,
      splashDuration: Duration(seconds: 3),
      textColor: Colors.white,
      fontSize: 60,
      fontWeight: FontWeight.bold,
      lottieWidth: 250,
      spaceBetween: 30,
    ),
    routes: [
      MyRoute<Page1Controller>(
        path: Routes.page1,
        page: const Page1View(),
        controller: () => Page1Controller(),
      ),
      MyRoute<Page2Controller>(
        path: Routes.page2,
        page: const Page2View(),
        controller: () => Page2Controller(),
      ),
      MyRoute<Page3Controller>(
        path: Routes.page3,
        page: const Page3View(),
        controller: () => Page3Controller(),
      ),
    ],
    keyToRollBack: LogicalKeyboardKey.backspace,  // 全局回退键，优先处理弹层关闭
    exitInfoText: '自定义: 再按一次退出App',
    backInfoText: '自定义: 再按一次返回上一页',
    pageTransitionStyle: Transition.fade,
  );
}

class Routes {
  static const String page1 = '/page1';
  static const String page2 = '/page2';
  static const String page3 = '/page3';
}
```

### 服务管理系统

XLY 包提供了服务管理系统，确保 GetX 服务在 ScreenUtil 初始化后注册，避免在服务中使用`.sp`、`.w`等扩展方法时返回无限值的问题。

#### 基本用法

```dart
void main() async {
  await MyApp.initialize(
    designSize: const Size(800, 600),

    // 在services参数中注册服务
    services: [
      // 永久服务 - 应用启动时立即创建并保持到应用结束
      MyService<YourService>(
        service: () => YourService(),
        permanent: true,
      ),

      // 懒加载服务 - 首次使用时创建
      MyService<DataService>(
        service: () => DataService(),
        fenix: false,  // 默认值，服务被删除后不会自动重建
      ),

      // 凤凰服务 - 支持自动重建
      MyService<NetworkService>(
        service: () => NetworkService(),
        fenix: true,   // 服务被删除后会在下次使用时自动重建
      ),

      // 带标签的服务 - 支持同一类型的多个实例
      MyService<CacheService>(
        service: () => CacheService('user_cache'),
        tag: 'user',
        permanent: true,
      ),
      MyService<CacheService>(
        service: () => CacheService('app_cache'),
        tag: 'app',
        permanent: true,
      ),

      // 🆕 异步服务 - 需要异步初始化（如从数据库/网络加载配置）
      MyService<ChatService>(
        asyncService: () async => ChatService(),
        permanent: true,
      ),
    ],

    routes: [...],
  );
}
```

#### 异步服务支持（🆕）

> 📖 **完整指南**：[异步服务详细文档](.doc/async_service_guide.md) | [GitHub](https://github.com/dbsxdbsx/flutter_xly/blob/main/.doc/async_service_guide.md) - 包含设计模式详解、实际案例、FAQ 和最佳实践

从 v1.0.0 开始，`MyService` 支持异步服务初始化，适用于需要从数据库、网络或其他异步源加载配置的服务。

**快速决策**：

- **同步服务** (`service`)：轻量级、可惰性加载、字段可空
- **异步服务** (`asyncService`)：必须预先初始化、字段非空、类型安全

**基础示例**：

```dart
// 同步服务 - 轻量级
MyService<CacheService>(
  service: () => CacheService(),
  permanent: true,
)

// 异步服务 - 需要预先初始化
MyService<DatabaseService>(
  asyncService: DatabaseService.create,  // 静态工厂方法
  permanent: true,
)
```

**异步服务的静态工厂方法模式**：

```dart
class DatabaseService extends GetxService {
  static DatabaseService get to => Get.find();

  late Database db;  // 非空，预先初始化

  DatabaseService._();  // 私有构造函数

  // 静态工厂方法 - 在返回前完成异步初始化
  static Future<DatabaseService> create() async {
    final service = DatabaseService._();
    service.db = await openDatabase('app.db');
    return service;  // 返回时已完全可用
  }

  Future<List<User>> getUsers() async {
    return await db.query('users');  // 直接使用，无需检查
  }
}
```

**核心说明**：

- **非 workaround**：静态工厂方法是 GoF 设计模式，适应 GetX 的 `putAsync` 不等待 `onInit()` 的设计
- **顺序注册**：服务严格按照 `services` 参数中的顺序依次初始化，确保服务依赖关系正确处理
- **类型安全**：允许使用 `late` 字段，避免运行时空值检查

**适用场景**：数据库连接、网络配置加载、AI 引擎初始化、复杂多步异步操作等。

#### 自定义服务示例

```dart
class MyCustomService extends GetxService {
  static MyCustomService get to => Get.find();

  final counter = 0.obs;
  late GetStorage _storage;

  @override
  Future<void> onInit() async {
    super.onInit();
    // 在这里可以安全使用ScreenUtil扩展方法
    final fontSize = 16.sp;  // 不会返回无限值

    // 初始化GetStorage（MyApp.initialize已经调用了GetStorage.init()）
    _storage = GetStorage();
    counter.value = _storage.read('counter') ?? 0;
  }

  void increment() async {
    counter.value++;
    await _storage.write('counter', counter.value);
  }
}
```

#### 服务配置选项

- `permanent: true` - 永久服务，应用启动时立即创建并保持到应用结束
- `fenix: true` - 凤凰服务，支持自动重建（当服务被删除后，下次使用时会自动重新创建）
- `tag: 'custom_tag'` - 服务标签，支持同一类型的多个实例

#### 重要说明

1. **初始化时机**: 服务会在 ScreenUtil 初始化**之后**、runApp**之前**注册
2. **避免无限值**: 在服务的`onInit()`方法中可以安全使用`.sp`、`.w`等扩展方法
3. **向后兼容**: `services`参数是可选的，现有代码无需修改
4. **GetX 兼容**: 完全兼容 GetX 的所有服务管理功能

### 显示 Toast 消息

MyToast 提供了多种类型的消息提示：

```dart
// 1. 中间位置的状态提示（带图标）
MyToast.showOk('操作成功完成！');     // 绿色对勾图标
MyToast.showInfo('这是一条信息提示'); // 蓝色信息图标
MyToast.showWarn('请检查输入数据');   // 黄色警告图标
MyToast.showError('发生错误：无法连接服务器'); // 红色错误图标

// 2. 顶部通知栏样式
MyToast.showUpInfo('这是一条信息提示');  // 蓝色背景
MyToast.showUpWarn('这是一条警告消息');  // 黄色背景
MyToast.showUpError('这是一条错误消息');  // 红色背景

// 3. 底部通知栏样式
MyToast.showBottom(
  '这是一条底部提示消息',
  opacity: 0.9,               // 背景透明度
  backgroundColor: Colors.black, // 自定义背景色
  textColor: Colors.white,    // 自定义文字颜色
);

// 4. 基础 Toast（可自定义位置）
MyToast.show(
  '这是一条自定义Toast消息',
  position: ToastPosition.center,  // 显示位置：top/center/bottom
  duration: Duration(seconds: 2),  // 显示时长
  backgroundColor: Colors.black87.withOpacity(0.7),  // 背景颜色
  textStyle: TextStyle(fontSize: 16, color: Colors.white),  // 文本样式
  radius: 8.0,  // 圆角半径
  stackPreviousToasts: true,  // 是否堆叠显示
  forever: false,     // 是否永久显示
  animationDuration: Duration(milliseconds: 500),  // 动画时长
  animationCurve: Curves.easeOutCubic,  // 动画曲线
);

// 4.1 Toast显示模式对比
// 普通模式（默认）- 新Toast替换旧Toast
MyToast.show('第一条消息');
MyToast.show('第二条消息'); // 会替换第一条消息

// 连续堆叠模式 - 多条Toast同时显示
MyToast.show('第一条消息');
await Future.delayed(Duration(milliseconds: 500));
MyToast.show('第二条消息', stackPreviousToasts: true); // 与第一条同时显示
await Future.delayed(Duration(milliseconds: 500));
MyToast.show('第三条消息', stackPreviousToasts: true); // 三条消息堆叠显示

// 5. 加载提示
// 5.1 显示永久加载动画
MyToast.showSpinner(
  message: '加载中...',
  spinnerColor: Colors.blue,  // 加载动画颜色
  backgroundColor: Colors.black.withOpacity(0.8),
  textStyle: TextStyle(fontSize: 16, color: Colors.white),
);

// 5.2 自动关闭的加载动画
MyToast.showSpinner(
  message: '加载中...',
  duration: Duration(seconds: 3), // 3秒后自动关闭
);

// 5.3 加载完成后显示结果
await MyToast.showLoadingThenToast(
  loadingMessage: '正在加载数据...',
  task: (_) async {
    await Future.delayed(Duration(seconds: 1));
    return (true, '数据加载完成！'); // 返回(成功状态, 提示消息)
  },
  spinnerColor: Colors.blue,
  stackPreviousToasts: true,  // 是否堆叠显示结果消息
  // 可选：自定义成功/警告/错误回调
  onOk: (message) => MyToast.showBottom(message),
  onWarn: (message) => MyToast.showUpWarn(message),
  onError: (error) => MyToast.showUpError('错误：$error'),
);

// 5.4 支持动态更新加载消息（进度提示）
await MyToast.showLoadingThenToast(
  loadingMessage: '正在处理 0/10 ...',
  task: (updateMessage) async {
    for (var i = 0; i < 10; i++) {
      await Future.delayed(Duration(milliseconds: 300));
      updateMessage?.call('正在处理 ${i + 1}/10 ...');  // 动态更新消息
    }
    return (true, '处理完成！');
  },
);

// 6. 关闭所有显示的 Toast
MyToast.hideAll();
// 或延迟关闭
MyToast.hideAll(1000); // 1秒后关闭
```

#### Snackbar 说明（顶部/底部通知栏）

`MyToast.showUpInfo/showUpWarn/showUpError/showBottom` 基于 GetX 的 Snackbar 能力。自 Flutter 3.38.1 起，GetX 的 `overlayContext` 在对话框关闭后可能失效（参考 [getx#3425](https://github.com/jonataslaw/getx/issues/3425)）。本包已通过在 App 根部包裹永久 `Overlay` 解决此问题，现在可以在任意场景（包括 Dialog/BottomSheet 关闭回调）中安全调用。

Toast 特性：

- 支持多种预设样式：成功、信息、警告、错误
- 支持多个显示位置：顶部、中间、底部
- **支持两种显示模式**：
  - **普通模式**：新 Toast 替换旧 Toast（默认行为）
  - **堆叠模式**：多条 Toast 同时显示，形成视觉堆叠效果
- 支持自定义样式：背景色、文字样式、图标等
- 支持加载动画显示
- 支持异步任务加载提示
- 支持自动关闭和手动关闭
- 支持动画效果和自定义动画时长

### 使用多点动态加载指示器 (MyLoadingDot)

MyLoadingDot 提供了四种不同的动画效果，适用于各种加载场景：

```dart
// 1. 最简单的使用（默认fade动画）
MyLoadingDot()

// 2. "正在输入"场景（推荐）
Row(
  children: [
    MyLoadingDot.typing(
      size: 6.w,
      gap: 2.w,
      color: Colors.grey,
    ),
    SizedBox(width: 8.w),
    Text('AI 正在输入…'),
  ],
)

// 3. 不同动画类型
// 弹跳动画
MyLoadingDot(
  dotAnimation: MyLoadingDotAnimation.bounce,
  size: 8.w,
  gap: 3.w,
  color: Colors.blue,
)

// 缩放动画
MyLoadingDot(
  dotAnimation: MyLoadingDotAnimation.scale,
  size: 10.w,
  gap: 4.w,
  color: Colors.green,
)

// 波动动画
MyLoadingDot(
  dotAnimation: MyLoadingDotAnimation.wave,
  size: 8.w,
  gap: 3.w,
  color: Colors.purple,
)

// 4. 按钮加载状态
ElevatedButton(
  onPressed: isLoading ? null : _handleSubmit,
  child: isLoading
    ? MyLoadingDot(
        dotAnimation: MyLoadingDotAnimation.scale,
        size: 4.w,
        gap: 1.w,
        color: Colors.white,
        dotCount: 3,
      )
    : Text('提交'),
)

// 5. 自定义参数
MyLoadingDot(
  dotCount: 5,                                    // 5个点
  period: const Duration(milliseconds: 1400),     // 更慢的动画周期
  phaseShift: 0.2,                               // 整体相位偏移
  size: 8.w,
  gap: 2.w,
  color: Colors.blueGrey,
  randomizeStartPhase: false,                     // 禁用随机起始相位
)
```

MyLoadingDot 特性：

- **四种动画效果**：fade（淡入淡出）、bounce（弹跳）、scale（缩放）、wave（波动）
- **自适应布局**：自动适应容器宽度，智能调整点大小和间距
- **高性能**：单控制器驱动多点相位动画，资源消耗低
- **防同步**：支持随机化起始相位，避免多实例同步问题
- **灵活配置**：支持自定义点数量、大小、间距、颜色、动画周期等

### 使用系统托盘 (MyTray)

MyTray 提供跨平台的系统托盘功能：

#### 🎯 托盘图标一致性最佳实践

**推荐工作流**：使用图标生成工具确保托盘图标与应用图标完全一致

```bash
# 1. 一键生成所有平台图标（包括托盘图标资产）
dart run xly:generate icon "assets/app_icon.png"

# 2. 在代码中不指定 iconPath，自动使用一致图标
tray: MyTray(
  // iconPath: 留空，自动使用与应用图标一致的图标
  tooltip: "我的应用",
  // ...
),
```

**自动化优势**：

- ✅ **完美一致**：托盘图标与应用窗口图标使用相同源文件
- ✅ **跨启动方式稳定**：VSCode F5 调试和从应用目录运行表现完全相同
- ✅ **零配置**：无需手动管理图标文件和路径
- ✅ **自动资产管理**：自动更新 pubspec.yaml 和复制必要文件

**⚠️ Windows 用户注意**：更换图标后，托盘图标会立即更新，但任务栏/文件管理器中的应用图标可能因系统缓存而显示旧图标。建议重启系统以清除图标缓存。

#### 推荐方式：使用 tray 参数（简化配置）

```dart
// 1. 在 main.dart 中使用tray参数（推荐方式）
void main() async {
  await MyApp.initialize(
    designSize: const Size(800, 600),
    routes: [...],

    // 简化的托盘配置
    tray: MyTray(
      // iconPath: "assets/icon.png",  // 可选：为空时自动使用默认应用图标
      tooltip: "我的应用",              // 可选：悬停提示
      hideTaskBarIcon: true,          // 可选：托盘存在时是否隐藏任务栏图标（默认true）
      toggleOnClick: true,            // 可选：托盘左键点击是否切换显示/隐藏（默认true）
      menuItems: [                    // 可选：右键菜单
        MyTrayMenuItem(key: 'show', label: '显示', onTap: () => MyTray.to.pop()),
        MyTrayMenuItem.separator(),
        MyTrayMenuItem(key: 'settings', label: '设置', enabled: false), // 禁用项
        MyTrayMenuItem(key: 'exit', label: '退出', onTap: () => exit(0)),
      ],
    ),
  );
}

// 2. 使用托盘功能
final myTray = MyTray.to;
await myTray.notify("标题", "消息内容");
await myTray.setIcon("new_icon.png");  // 可选参数，为空时使用默认图标
await myTray.pop();  // 恢复窗口显示

// 3. 动态控制菜单项禁用状态
await myTray.setMenuItemEnabled('settings', true);   // 启用设置菜单

// 4. 运行时控制任务栏图标显示策略
await myTray.showTaskbarIcon();    // 显示任务栏图标（托盘+任务栏双入口）
await myTray.hideTaskbarIcon();    // 隐藏任务栏图标（纯托盘模式）
bool isHidden = myTray.hideTaskBarIcon;  // 获取当前策略状态
bool isEnabled = myTray.getMenuItemEnabled('settings'); // 查询状态
await myTray.toggleMenuItemEnabled('settings');      // 切换状态
```

#### 传统方式：使用 services 参数（向后兼容）

```dart
// 传统方式仍然支持，用于复杂场景或向后兼容
void main() async {
  await MyApp.initialize(
    designSize: const Size(800, 600),
    routes: [...],

    services: [
      MyService<MyTray>(
        service: () => MyTray(
          iconPath: "assets/icon.png",
          tooltip: "我的应用",
          menuItems: [...],
        ),
        permanent: true,
      ),
      // 其他服务...
    ],
  );
}
```

MyTray 特性：

- **简化配置**：推荐使用 `tray` 参数，无需了解 GetxService 概念
- **向后兼容**：传统的 `MyService<MyTray>` 方式仍然支持
- **🆕 自动图标一致性**：配合图标生成工具，托盘图标与应用图标完全一致，跨启动方式稳定
- **智能默认图标**：`iconPath` 可选，为空时自动查找默认应用图标
- **早期检测**：图标缺失时提供详细错误信息和解决方案
- **完全可选**：不需要托盘功能时完全不涉及，零影响
- **配置优先级**：如果同时提供 `tray` 参数和 `services` 中的 MyTray，`tray` 参数优先
- **🆕 智能托盘隐藏**：根据智能停靠状态自动选择隐藏模式，与智能停靠功能完美协作
- **🆕 原生禁用样式**：支持菜单项的启用/禁用状态，使用系统原生灰色样式和不可点击行为
- **🆕 任务栏图标策略控制**：hideTaskBarIcon 参数控制托盘存在时任务栏图标显示，支持运行时切换
- **🆕 托盘点击切换功能**：toggleOnClick 参数控制托盘左键点击行为，支持切换显示/隐藏或保持现状
- **🔌 完全独立**：MyTray 与智能停靠功能完全解耦，可单独使用或配合使用

#### 任务栏图标策略控制

MyTray 支持灵活的任务栏图标显示策略，允许用户选择"纯托盘模式"或"托盘+任务栏双入口模式"：

- **hideTaskBarIcon = true（默认）**：托盘存在时隐藏任务栏图标，提供干净的任务栏体验
- **hideTaskBarIcon = false**：托盘存在时保留任务栏图标，提供双入口访问方式
- **运行时切换**：支持通过 API 动态改变策略，无需重启应用
- **与智能停靠解耦**：任务栏图标显示策略不影响智能停靠的悬停唤醒等行为

```dart
// 初始化时配置策略
tray: MyTray(
  hideTaskBarIcon: false,  // 保留任务栏图标（双入口模式）
),

// 运行时切换策略
MyTray.to.showTaskbarIcon();    // 显示任务栏图标
MyTray.to.hideTaskbarIcon();    // 隐藏任务栏图标
bool isHidden = MyTray.to.hideTaskBarIcon;  // 获取当前策略
```

#### 托盘点击切换功能

MyTray 支持灵活的托盘左键点击行为控制，允许用户选择"切换语义"或"保持现状"：

- **toggleOnClick = true（默认）**：托盘左键点击执行切换语义
  - 普通模式：在 hide()和 pop()之间切换（隐藏到托盘 ↔ 恢复显示并聚焦）
  - 智能停靠模式：在"收起到隐藏位"和"无激活弹出到对齐位"之间切换
- **toggleOnClick = false**：托盘左键点击保持现状行为
  - 普通模式：始终执行 pop()（恢复显示并聚焦）
  - 智能停靠模式：始终执行 simulateHoverReveal()（无激活弹出，不会立即缩回）
- **运行时切换**：支持通过 API 动态改变行为，无需重启应用
- **智能停靠兼容**：保持"隐藏 → 显示不会立即缩回"的既有体验

```dart
// 初始化时配置行为
tray: MyTray(
  toggleOnClick: false,  // 保持现状行为（始终显示）
),

// 运行时切换行为
MyTray.to.setToggleOnClick(true);     // 开启切换语义
MyTray.to.setToggleOnClick(false);    // 关闭切换语义
MyTray.to.toggleToggleOnClick();      // 切换开关状态
bool isToggleMode = MyTray.to.getToggleOnClick();  // 获取当前状态
```

#### 智能托盘隐藏功能

MyTray 现在支持智能托盘隐藏，能够根据当前窗口状态智能决策隐藏行为：

- **普通模式**：窗口未处于智能停靠状态时，完全隐藏窗口 UI
- **智能停靠模式**：窗口处于智能停靠状态时，强制收起到隐藏位（保留悬停唤醒能力）
- **任务栏激活控制**：防止在智能停靠模式下意外激活系统任务栏
- **托盘左击（智能停靠隐藏下）**：左击托盘仅“模拟悬停弹出”，不激活不聚焦；用户首次把鼠标移入窗口后，再移出时会按常规自动收回
- **🆕 智能收起行为**：在智能停靠已展开状态下点击"隐藏到托盘"，会立即收起到边缘/角落隐藏位，同时保持鼠标悬停可再次弹出

```dart
// 智能托盘隐藏（自动选择模式）
MyTray.to.hide();  // 根据当前状态智能选择隐藏方式

// 托盘左击（智能停靠隐藏下）：仅模拟悬停弹出
// -> 无需代码，内置行为；如需手动触发：
await MouseTracker.simulateHoverReveal();

// 从托盘恢复（非智能停靠场景）
MyTray.to.pop();   // 恢复窗口显示
```

**详细文档**：

- [智能托盘用户指南](.doc/smart_tray_user_guide.md) | [GitHub](https://github.com/dbsxdbsx/flutter_xly/blob/main/.doc/smart_tray_user_guide.md) - 用户使用说明
- [智能托盘技术文档](.doc/smart_tray_technical.md) | [GitHub](https://github.com/dbsxdbsx/flutter_xly/blob/main/.doc/smart_tray_technical.md) - 开发者技术细节

### 使用系统通知 (MyNotify)

MyNotify 提供跨平台的系统通知功能：

```dart
// 1. 在 main.dart 中注册服务
void main() async {
  await MyApp.initialize(
    services: [
      MyService<MyNotify>(
        service: () => MyNotify(),
        permanent: true,
      ),
    ],
  );
}

// 2. 显示基础通知
final myNotify = MyNotify.to;
await myNotify.show("标题", "消息内容");

// 3. 显示不同类型的通知
await myNotify.show("信息", "这是一条信息通知", type: MyNotifyType.info);
await myNotify.show("警告", "这是一条警告通知", type: MyNotifyType.warning);
await myNotify.show("错误", "这是一条错误通知", type: MyNotifyType.error);
await myNotify.show("成功", "这是一条成功通知", type: MyNotifyType.success);

// 4. 定时通知
final scheduledTime = DateTime.now().add(Duration(seconds: 5));
await myNotify.schedule(
  "定时通知",
  "这是一条5秒后显示的通知",
  scheduledTime,
  type: MyNotifyType.info,
);

// 5. 权限管理
bool granted = await myNotify.requestPermissions();
bool hasPermission = myNotify.permissionGranted;
bool isInitialized = myNotify.isInitialized;

// 6. 通知管理
await myNotify.cancel(0);        // 取消指定ID的通知
await myNotify.cancelAll();      // 取消所有通知
```

MyNotify 特性：

- **跨平台支持**：Android、iOS、macOS、Windows、Linux
- **多种通知类型**：信息、警告、错误、成功，不同优先级和样式
- **定时通知**：支持指定时间显示通知
- **权限管理**：自动处理通知权限请求和状态监控
- **通知管理**：支持取消单个或所有通知，获取待处理和活跃通知
- **职责分离**：与 MyTray 分离，专注系统通知功能

### 使用自定义按钮

```dart
Widget buildCustomButton() {
  return MyButton(
    text: '点击我',
    onPressed: () => print('按钮被点击'),
    icon: Icons.star,
    shape: MyButtonShape.normal,
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
  );
}
```

### 使用菜单按钮

```dart
Widget buildMenuButton() {
  return MyMenuButton(
    icon: Icons.more_vert,
    iconSize: 30.0,
    iconColor: Colors.green,
    menuItems: [
      MyMenuItem(
        text: '选项A',
        icon: Icons.star,
        onTap: () => toast('选择了选项A'),
      ),
      MyMenuItem(
        text: '选项B',
        icon: Icons.favorite,
        onTap: () => toast('选择了选项B'),
      ),
    ],
  );
}
```

### 使用焦点管理

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('可聚焦的文本').setFocus(
      focusKey: 'focusable_text',
      onPressed: () => toast('文本被聚焦并点击'),
      opacity: true,
      focusedBorderColor: Colors.green,
      borderWidth: 2,
    );
  }
}
```

### 导航到新页面

```dart
goToPage(context, Routes.page2);
```

### 显示对话框

#### 🎯 选择指南：MyDialog vs MyDialogSheet

| 特性         | MyDialog                    | MyDialogSheet                    |
| ------------ | --------------------------- | -------------------------------- |
| **适用场景** | 标准确认/取消对话框         | 自定义布局面板                   |
| **返回值**   | `MyDialogChosen` 枚举       | 泛型 `T?`，可返回任意类型        |
| **按钮**     | 固定左右按钮模式            | 可选按钮，支持自定义             |
| **布局控制** | 基础主题配置                | 精细控制内边距、尺寸、标题居中等 |
| **风格**     | Material/Cupertino 标准样式 | 完全自定义样式                   |

**何时使用 MyDialog：**

- ✅ 简单的确认/取消操作
- ✅ 需要标准的用户选择结果（左/右/取消）
- ✅ 希望保持系统原生对话框风格

**何时使用 MyDialogSheet：**

- ✅ 需要复杂的自定义内容布局
- ✅ 需要精确控制对话框尺寸和内边距
- ✅ 需要返回自定义数据类型
- ✅ 底部弹出菜单（Action Sheet）

#### 基础用法

```dart
// 1. 简单确认对话框（默认可点击遮罩关闭）
final result = await MyDialog.show(
  content: const Text('确定要删除这个文件吗？'),
);

// 处理用户选择
switch (result) {
  case MyDialogChosen.left:
    print('用户点击了取消');
    break;
  case MyDialogChosen.right:
    print('用户点击了确定');
    break;
  case MyDialogChosen.canceled:
    print('用户点击了对话框外部或按了返回键');
    break;
}

// 2. 带回调的对话框
MyDialog.show(
  content: const Text('这是一个测试对话框'),
  onLeftButtonPressed: () => MyToast.show('选择了取消'),
  onRightButtonPressed: () => MyToast.show('选择了确定'),
);
```

#### 自定义样式

```dart
// 3. 完全自定义的对话框
MyDialog.show(
  title: '警告',
  content: const Text('此操作不可撤销，确定继续吗？'),
  leftButtonText: '我再想想',
  rightButtonText: '立即执行',
  backgroundColor: Colors.grey[100],
  titleColor: Colors.red,
  leftButtonColor: Colors.grey,
  rightButtonColor: Colors.red,
  borderRadius: 15.0,
  elevation: 8.0,
  barrierOpacity: 0.7,
);

// 4. 复杂内容的对话框
MyDialog.show(
  title: '用户信息',
  content: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const CircleAvatar(
        radius: 30,
        child: Icon(Icons.person, size: 30),
      ),
      const SizedBox(height: 16),
      const Text('张三'),
      const Text('高级开发工程师'),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () => MyToast.show('拨打电话'),
          ),
          IconButton(
            icon: const Icon(Icons.email),
            onPressed: () => MyToast.show('发送邮件'),
          ),
        ],
      ),
    ],
  ),
  leftButtonText: '关闭',
  rightButtonText: '编辑',
);
```

#### 严格模态（不允许点击遮罩关闭）

```dart
await MyDialog.show(
  title: '删除文件',
  content: const Text('此操作不可撤销，确定删除？'),
  rightButtonText: '删除',
  barrierDismissible: false, // 关键：禁止点击外部关闭
);
```

// 也可在 iOS 风格对话框中使用严格模态：
await MyDialog.showIos(
title: '提示',
content: const Text('这是 iOS 风格的对话框'),
barrierDismissible: false,
);

#### iOS 风格对话框

```dart
// 5. iOS风格对话框（适用于iOS平台或需要iOS风格的场景）
MyDialog.showIos(
  title: '提示',
  content: const Text('这是iOS风格的对话框'),
  leftButtonText: '取消',
  rightButtonText: '确定',
  leftButtonColor: CupertinoColors.systemGrey,
  rightButtonColor: CupertinoColors.systemBlue,
);
```

#### 实用示例

```dart
// 6. 退出确认对话框
Future<void> showExitConfirmDialog() async {
  final result = await MyDialog.show(
    title: '退出应用',
    content: const Text('确定要退出应用吗？'),
    leftButtonText: '取消',
    rightButtonText: '退出',
    rightButtonColor: Colors.red,
  );

  if (result == MyDialogChosen.right) {
    await MyApp.exit();
  }
}

// 7. 输入确认对话框
Future<void> showDeleteConfirmDialog(String fileName) async {
  final result = await MyDialog.show(
    title: '删除文件',
    content: Text('确定要删除文件 "$fileName" 吗？\n此操作不可撤销。'),
    leftButtonText: '取消',
    rightButtonText: '删除',
    rightButtonColor: Colors.red,
    titleColor: Colors.red,
  );

  if (result == MyDialogChosen.right) {
    // 执行删除操作
    MyToast.showSuccess('文件已删除');
  }
}
```

### 使用底部弹出菜单和中心对话框

#### 底部弹出菜单 (MyDialogSheet.showBottom)

> **设计说明**：`showBottom` 内部使用 Flutter 原生 `showModalBottomSheet` 而非 GetX 的 `Get.bottomSheet`，因为后者无法覆盖 Material 3 的 `maxWidth: 640` 硬编码默认值。始终启用 `isScrollControlled: true` 以突破 Flutter 默认的 9/16 高度上限，让调用方自由控制面板高度。高度支持两种指定方式（二选一，`heightRatio` 优先）：`heightRatio` 按屏幕比例指定（0.0~1.0），`designHeight` 按设计稿值指定（在 builder 内部通过 ScreenUtil 动态转换）。内容区域内置 `SingleChildScrollView` 安全网，防止极端窗口尺寸下内容溢出。

```dart
// 1. 简单底部菜单（designHeight 是设计稿值，无需自行 .h 转换）
MyDialogSheet.showBottom(
  child: const Text('这是一个简单的底部菜单'),
  designHeight: 200,
);

// 1.5 按屏幕比例指定高度（heightRatio 优先于 designHeight）
MyDialogSheet.showBottom(
  child: const Text('占屏幕 2/3 高度的底部菜单'),
  heightRatio: 2 / 3, // 屏幕高度的 2/3，自动 clamp 到 0.0~1.0
);

// 2. 自定义样式的底部菜单
MyDialogSheet.showBottom(
  child: Container(
    padding: EdgeInsets.all(20.w),
    child: Column(
      children: [
        Text('选择操作', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 20.h),
        ListTile(
          leading: const Icon(Icons.edit),
          title: const Text('编辑'),
          onTap: () {
            Get.back();
            MyToast.show('选择了编辑');
          },
        ),
        ListTile(
          leading: const Icon(Icons.share),
          title: const Text('分享'),
          onTap: () {
            Get.back();
            MyToast.show('选择了分享');
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete, color: Colors.red),
          title: const Text('删除', style: TextStyle(color: Colors.red)),
          onTap: () {
            Get.back();
            MyToast.show('选择了删除');
          },
        ),
      ],
    ),
  ),
  designHeight: 300,
  backgroundColor: Colors.white,
  designBorderRadius: 20,
);

// 3. 带返回值的底部菜单
Future<String?> showActionSheet() async {
  return await MyDialogSheet.showBottom<String>(
    child: Column(
      children: [
        ListTile(
          title: const Text('拍照'),
          onTap: () => Get.back(result: 'camera'),
        ),
        ListTile(
          title: const Text('从相册选择'),
          onTap: () => Get.back(result: 'gallery'),
        ),
        ListTile(
          title: const Text('取消'),
          onTap: () => Get.back(),
        ),
      ],
    ),
    designHeight: 200,
  );
}

// 使用示例
final action = await showActionSheet();
if (action != null) {
  MyToast.show('选择了: $action');
}

// 4. 自定义宽度比例（默认 0.85，即占窗口宽度 85%）
MyDialogSheet.showBottom(
  child: const Text('窄一点的底部菜单'),
  designHeight: 200,
  maxWidthRatio: 0.7, // 占窗口宽度的 70%
);
```

#### 中心对话框 (MyDialogSheet.showCenter)

```dart
// 4. 简单中心对话框
MyDialogSheet.showCenter(
  title: '设置',
  content: const Text('这是一个中心对话框'),
  onConfirm: () {
    MyToast.show('确认操作');
    Get.back();
  },
);

// 5. 复杂内容的中心对话框
MyDialogSheet.showCenter(
  title: '用户设置',
  content: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SwitchListTile(
        title: const Text('接收通知'),
        value: true,
        onChanged: (value) => MyToast.show('通知设置: $value'),
      ),
      SwitchListTile(
        title: const Text('自动更新'),
        value: false,
        onChanged: (value) => MyToast.show('自动更新: $value'),
      ),
      ListTile(
        leading: const Icon(Icons.language),
        title: const Text('语言设置'),
        trailing: const Text('中文'),
        onTap: () => MyToast.show('打开语言设置'),
      ),
    ],
  ),
  confirmText: '保存',
  exitText: '取消',
  onConfirm: () {
    MyToast.showSuccess('设置已保存');
    Get.back();
  },
  onExit: () {
    MyToast.show('取消设置');
    Get.back();
  },
);

// 6. 自定义样式的中心对话框
MyDialogSheet.showCenter(
  title: '重要提醒',
  titleFontSize: 20.sp,
  centerTitle: true,
  content: Container(
    padding: EdgeInsets.all(16.w),
    decoration: BoxDecoration(
      color: Colors.yellow[50],
      borderRadius: BorderRadius.circular(8.r),
      border: Border.all(color: Colors.orange),
    ),
    child: Row(
      children: [
        Icon(Icons.warning, color: Colors.orange, size: 24.sp),
        SizedBox(width: 12.w),
        const Expanded(
          child: Text('这是一个重要的系统提醒，请仔细阅读。'),
        ),
      ],
    ),
  ),
  contentPadding: EdgeInsets.all(20.w),
  confirmText: '我知道了',
  exitText: '稍后提醒',
);
```

### 右键菜单

```dart
Widget buildRightMenu() {
  return Text('这是一个测试右键菜单').showRightMenu(
    context: context,
    menuElements: [
      MyMenuItem(text: '选项A', onTap: () => toast('选择了选项A')),
      MyMenuItem(text: '选项B', onTap: () => toast('选择了选项B')),
    ],
  );
}
```

### 使用自定义文本编辑器

> 📖 **详细使用指南**：[MyTextEditor 使用指南](.doc/my_text_editor_usage_guide.md) | [GitHub](https://github.com/dbsxdbsx/flutter_xly/blob/main/.doc/my_text_editor_usage_guide.md) - 包含完整的 API 说明、高级用法和最佳实践

#### 基础用法

```dart
Widget buildBasicTextEditor() {
  final controller = TextEditingController();

  return MyTextEditor(
    textController: controller,
    label: '基础输入',
    hint: '请输入文本',
    clearable: true,
    onChanged: (value) => debugPrint('文本已更改: $value'),
  );
}
```

#### 数字输入框

```dart
Widget buildNumberEditor() {
  final numberController = TextEditingController();

  return MyTextEditor(
    textController: numberController,
    label: '数字输入',
    hint: '请输入数字',
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
  );
}
```

#### 多行文本输入

```dart
Widget buildMultilineEditor() {
  final multilineController = TextEditingController();

  return MyTextEditor(
    textController: multilineController,
    label: '多行输入',
    hint: '请输入多行文本',
    maxLines: 3,
    height: 100.h,
  );
}
```

#### 带下拉建议的输入框

```dart
Widget buildDropdownEditor() {
  final dropdownController = TextEditingController();

  return MyTextEditor(
    textController: dropdownController,
    label: '颜色选择',
    hint: '选择或输入颜色',
    maxShowDropDownItems: 6,
    showAllOnPopWithNonTyping : true, // 箭头点击显示全量候选
    // 不传表示自动决定方向（默认）
    getDropDownOptions: () async {
      // 模拟异步获取数据
      await Future.delayed(const Duration(milliseconds: 100));
      return ['红色', '蓝色', '绿色', '黄色', '紫色', '橙色'];
    },
    onOptionSelected: (option) {
      dropdownController.text = option;
      debugPrint('选择了: $option');
    },
    // 自定义选项前缀图标
    leadingBuilder: (option) => Container(
      width: 20.w,
      height: 20.w,
      decoration: BoxDecoration(
        color: _getColorFromName(option),
        shape: BoxShape.circle,
      ),
    ),
  );
}

Color _getColorFromName(String name) {
  switch (name) {
    case '红色': return Colors.red;
    case '蓝色': return Colors.blue;
    case '绿色': return Colors.green;
    case '黄色': return Colors.yellow;
    case '紫色': return Colors.purple;
    case '橙色': return Colors.orange;
    default: return Colors.grey;
  }
}

// 下拉列表显示在上方的示例
Widget buildTopDropdownEditor() {
  final countryController = TextEditingController();

  return MyTextEditor(
    textController: countryController,
    label: '国家选择',
    hint: '选择或输入国家',
    showListCandidateBelow: false, // 显示在上方
    getDropDownOptions: () async {
      return ['中国', '美国', '日本', '韩国', '英国', '法国'];
    },
    onOptionSelected: (option) {
      countryController.text = option;
      debugPrint('选择了: $option');
    },
  );
}
```

#### 自定义样式输入框

```dart
Widget buildStyledEditor() {
  final styledController = TextEditingController();

  return MyTextEditor(
    textController: styledController,
    label: '自定义样式输入框',
    hint: '自定义样式示例',
    clearable: true,
    onCleared: () => MyToast.showInfo('清除了输入内容'),
    // 自定义样式
    borderRadius: 50.r,
    borderWidth: 2,
    backgroundColor: Colors.blue[50],
    focusedBorderColor: Colors.blue,
    labelColor: Colors.blue[700],
    labelFontSize: 15.sp,
    textFontSize: 14.sp,
  );
}
```

#### 完整的控制器管理示例

```dart
class MyTextEditorExample extends GetView<MyTextEditorController> {
  const MyTextEditorExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MyTextEditor(
          textController: controller.basicController,
          label: '基础输入',
          hint: '请输入文本',
          clearable: true,
        ),
        SizedBox(height: 16.h),
        MyTextEditor(
          textController: controller.colorController,
          label: '颜色选择',
          hint: '选择或输入颜色',
          getDropDownOptions: controller.getColors,
          onOptionSelected: controller.onColorSelected,
          leadingBuilder: (option) => Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              color: controller.getColorFromName(option),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class MyTextEditorController extends GetxController {
  final basicController = TextEditingController();
  final colorController = TextEditingController();

  @override
  void onClose() {
    basicController.dispose();
    colorController.dispose();
    super.onClose();
  }

  void onColorSelected(String value) => colorController.text = value;

  Future<List<String>> getColors() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return ['红色', '蓝色', '绿色', '黄色', '紫色', '橙色'];
  }

  Color getColorFromName(String name) {
    switch (name) {
      case '红色': return Colors.red;
      case '蓝色': return Colors.blue;
      case '绿色': return Colors.green;
      case '黄色': return Colors.yellow;
      case '紫色': return Colors.purple;
      case '橙色': return Colors.orange;
      default: return Colors.grey;
    }
  }
}
```

#### MyTextEditor 主要特性

- **智能下拉导航**：支持键盘上下箭头导航，Enter 选择，Escape 关闭
- **鼠标键盘协同**：鼠标悬停与键盘导航状态智能同步
- **自动滚动**：选中项自动滚动到可视区域，支持大量选项流畅导航
- **防抖动机制**：选择选项后智能防止下拉列表闪烁
- **手动关闭记忆**：用户主动关闭下拉列表后，输入新内容前不会自动重新打开
- **灵活的下拉位置**：支持下拉列表显示在输入框上方或下方，适应不同布局需求
- **智能触发行为**：区分输入、焦点、箭头三种触发方式，支持箭头点击显示全量候选
- **丰富的自定义选项**：支持样式、颜色、字体、边框等全方位自定义
- **响应式设计**：所有尺寸属性支持 ScreenUtil 响应式单位

#### 使用注意事项

1. **控制器管理**：记得在控制器的`onClose()`方法中释放 TextEditingController
2. **响应式单位**：建议使用`.w`、`.h`、`.r`、`.sp`等响应式单位
3. **异步数据**：`getDropDownOptions`支持异步获取数据，适合网络请求场景
4. **键盘导航**：下拉列表支持完整的键盘导航，提升用户体验
5. **性能优化**：大量选项时使用`maxShowDropDownItems`限制显示数量

### 使用自定义编辑框

```dart
Widget buildEditBox() {
  return MySpinBox(
    label: '数量',
    initialValue: 0,
    min: 0,
    max: 100,
    step: 1.0,
    enableEdit: true,
    suffix: '个',
    onChanged: (value) => print('数值已更改: $value'),
    // 自定义样式
    labelFontSize: 15.0,
    centerTextFontSize: 12.0,
    spinIconSize: 13.0,
    spinButtonSize: 28.0,
  );
}
```

### 使用列表组件

#### MyList - 基础列表组件

```dart
Widget buildMyList() {
  final items = ['项目1', '项目2', '项目3', '项目4'];
  final scrollController = ScrollController();

  return MyList<String>(
    items: items,
    scrollController: scrollController,
    showScrollbar: true,
    isDraggable: true, // 启用拖拽重排序
    onCardReordered: (oldIndex, newIndex) {
      // 处理拖拽重排序
      if (oldIndex < newIndex) newIndex--;
      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
    },
    itemBuilder: (context, index) {
      return ListTile(
        title: Text(items[index]),
        key: ValueKey(items[index]), // 拖拽时需要key
      );
    },
    footer: Text('列表底部内容'), // 可选的底部组件
  );
}
```

#### MyCardList - 高级卡片列表组件

```dart
Widget buildMyCardList() {
  return MyCardList(
    itemCount: 10,
    showScrollbar: true,

    // 卡片内容构建器
    cardBody: (index) => Text('卡片内容 $index'),
    cardLeading: (index) => Icon(Icons.star),
    cardTrailing: (index) => Icon(Icons.arrow_forward_ios),

    // 交互事件
    onCardPressed: (index) => print('点击了卡片 $index'),
    onCardReordered: (oldIndex, newIndex) {
      print('拖拽: $oldIndex -> $newIndex');
    },
    onSwipeDelete: (index) => print('滑动删除卡片 $index'),
    onLoadMore: () async {
      // 加载更多数据
      await Future.delayed(Duration(seconds: 1));
    },

    // 卡片样式
    cardHeight: 60.0,
    cardColor: Colors.white,
    cardHoverColor: Colors.grey[100],
    cardElevation: 2.0,
    cardBorderRadius: BorderRadius.circular(8.0),

    // 底部组件
    footer: MyEndOfListWidget(
      isLoading: false,
      hasError: false,
      hasMoreData: false,
      onRetry: () => print('重试加载'),
    ),
  );
}
```

### 使用卡片组件

```dart
Widget buildMyCard() {
  return MyCard(
    // 核心内容
    child: Text('卡片主要内容'),
    leading: Icon(Icons.star),
    trailing: Icon(Icons.arrow_forward_ios),

    // 交互事件
    onPressed: () => print('卡片被点击'),

    // 拖拽和滑动删除
    isDraggable: true,
    enableSwipeToDelete: true,
    onSwipeDeleted: () => print('卡片被滑动删除'),

    // 样式自定义
    height: 60.0,
    cardColor: Colors.white,
    cardHoverColor: Colors.grey[100],
    cardSplashColor: Colors.blue[100],
    cardElevation: 2.0,
    cardBorderRadius: BorderRadius.circular(12.0),

    // 布局控制
    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    leadingAndBodySpacing: 12.0,
  );
}
```

### 使用分组框组件

```dart
Widget buildMyGroupBox() {
  return MyGroupBox(
    title: '设置选项',
    child: Column(
      children: [
        ListTile(title: Text('选项1')),
        ListTile(title: Text('选项2')),
        ListTile(title: Text('选项3')),
      ],
    ),

    // 样式自定义
    borderColor: Colors.blue,
    titleColor: Colors.blue,
    borderWidth: 1.5,
    borderRadius: 8.0,
    style: SectionBorderStyle.normal, // 或 SectionBorderStyle.inset
    titleStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
    ),
  );
}
```

### 使用列表底部状态组件

```dart
Widget buildEndOfListWidget() {
  return MyEndOfListWidget(
    isLoading: false,
    hasError: false,
    hasMoreData: false,
    onRetry: () => print('重试加载'),

    // 自定义文本
    loadingText: '正在加载更多...',
    errorText: '加载失败，请重试',
    deadLineText: '我是有底线的',
    subDeadLineText: '已经到底啦，休息一下吧',

    // 自定义样式
    icon: Icons.sentiment_satisfied_alt,
    dividerFontSize: 12,
    dividerColor: Colors.grey,
    textFontSize: 12,
    textColor: Colors.grey,

    // 是否用于Sliver列表
    useSliver: false,
  );
}
```

### 使用增强图标按钮

```dart
Widget buildMyIcon() {
  return MyIcon(
    icon: Icons.settings,
    iconColor: Colors.blue,
    size: 24.0,
    tooltip: '设置',
    onPressed: () => print('图标被点击'),

    // 悬停效果
    hoverShadowRadius: 20.0,
    hoverColor: Colors.blue.withOpacity(0.1),
    splashColor: Colors.blue.withOpacity(0.3),
  );
}
```

### 使用 URL 启动器组件

```dart
Widget buildUrlLauncher() {
  return MyUrlLauncher(
    url: 'https://www.example.com',
    child: Container(
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        '点击访问网站',
        style: TextStyle(color: Colors.white),
      ),
    ),
  );
}
```

### 使用平台工具类

```dart
// 通用平台类型判断
if (MyPlatform.isDesktop) {
  // 桌面平台特有操作
  await MyPlatform.showWindow();
} else if (MyPlatform.isMobile) {
  // 移动平台特有操作
  final hasPermission = await MyPlatform.requestPermission(
    Permission.storage,
  );
}

// 细粒度平台检测
if (MyPlatform.isWindows) {
  // Windows特有操作
  print('运行在Windows平台');
} else if (MyPlatform.isMacOS) {
  // macOS特有操作
  print('运行在macOS平台');
} else if (MyPlatform.isLinux) {
  // Linux特有操作
  print('运行在Linux平台');
} else if (MyPlatform.isAndroid) {
  // Android特有操作
  print('运行在Android平台');
} else if (MyPlatform.isIOS) {
  // iOS特有操作
  print('运行在iOS平台');
} else if (MyPlatform.isWeb) {
  // Web平台特有操作
  print('运行在Web平台');
}

// 获取平台名称
String platform = MyPlatform.platformName;
print('当前平台：$platform'); // 输出：当前平台：Windows

// 文件操作
final appDir = await MyPlatform.getAppDirectory();
final file = await MyPlatform.getFile('example.txt');
final assetFile = await MyPlatform.getFilePastedFromAssets('config.json');

// 延迟显示组件
Widget buildPingDisplay() {
  return MyPlatform.buildDelayDisplay(
    pingTimeFuture: Future.value(BigInt.from(150)),
    fontSize: 14.0,
  );
}
```

### 使用窗口停靠功能

窗口停靠功能允许您将应用窗口快速移动到屏幕的四个角落，并自动避开任务栏：

```dart
// 停靠窗口到左上角
final success = await MyApp.dockToCorner(WindowCorner.topLeft);
if (success) {
  print('窗口已停靠到左上角');
} else {
  print('停靠失败');
}

// 停靠窗口到右上角
await MyApp.dockToCorner(WindowCorner.topRight);

// 停靠窗口到左下角
await MyApp.dockToCorner(WindowCorner.bottomLeft);

// 停靠窗口到右下角
await MyApp.dockToCorner(WindowCorner.bottomRight);
```

窗口停靠功能特性：

- 🎯 **精确停靠**: 窗口会精确停靠到屏幕的四个角落
- 📏 **任务栏感知**: 自动检测任务栏位置，确保窗口不被遮挡
- 🔧 **跨平台兼容**: 支持 Windows、macOS、Linux 桌面平台
- ⚡ **简单易用**: 一行代码完成停靠操作
- 🛡️ **错误处理**: 内部处理所有异常，返回操作结果

### 使用边缘停靠功能（类似 QQ）

边缘停靠功能允许您将窗口停靠到屏幕边缘，大部分隐藏，只留一小部分可见，类似腾讯 QQ 的停靠行为：

```dart
// 启用左边缘停靠，可见宽度为8像素
final success = await MyApp.enableSimpleEdgeDocking(
  edge: WindowEdge.left,
  visibleWidth: 8.0,
);

if (success) {
  print('边缘停靠已启用');
}

// 启用其他边缘停靠
await MyApp.enableSimpleEdgeDocking(edge: WindowEdge.right);
await MyApp.enableSimpleEdgeDocking(edge: WindowEdge.top);
await MyApp.enableSimpleEdgeDocking(edge: WindowEdge.bottom);

// 手动切换停靠窗口的展开/收缩状态
await MyApp.toggleDockedWindow();

// 手动展开停靠的窗口
await MyApp.expandDockedWindow();

// 手动收缩窗口到停靠位置
await MyApp.collapseDockedWindow();

// 禁用边缘停靠功能
MyApp.disableEdgeDocking();
```

边缘停靠功能特性：

- 🎯 **智能停靠**: 窗口停靠到屏幕边缘，只留小部分可见
- 🖱️ **交互友好**: 点击可见部分可展开/收缩窗口
- 📏 **可调节**: 支持自定义可见宽度
- 🔧 **跨平台**: 支持 Windows、macOS、Linux 桌面平台
- ⚡ **简单控制**: 提供手动控制方法
- 🛡️ **安全可靠**: 内部异常处理，操作安全

### 使用智能停靠机制

智能停靠是一个更高级的功能，它会自动检测用户拖拽窗口的行为，当窗口的某部分被拖拽超出屏幕边界时，自动触发停靠。系统会智能判断是进行边缘停靠还是角落停靠：

```dart
// 启用智能停靠机制
await MyApp.setSmartEdgeDocking(
  enabled: true,
  visibleWidth: 8.0,      // 停靠时可见宽度
);

// 检查智能停靠状态
bool isEnabled = MyApp.isSmartDockingEnabled();

// 禁用智能停靠
await MyApp.setSmartEdgeDocking(enabled: false);
```

智能停靠特性：

- 🧠 **智能检测**: 自动检测窗口拖拽行为和位置
- 🎯 **边界触发**: 窗口部分超出屏幕边界时自动停靠
- 📐 **智能选择**: 自动判断边缘停靠或角落停靠
  - 窗口同时超出两个相邻边界时，触发**角落停靠**（如左上角）
  - 窗口只超出一个边界时，触发**边缘停靠**（如左边缘）
- 👁️ **可见区域优化**: 角落停靠时露出更大的可见区域，便于鼠标悬停
- ⏱️ **延迟触发**: 窗口停止移动后延迟触发，避免误操作
- 🔄 **动态切换**: 可以在不同边缘/角落间自由切换停靠
- 🛡️ **状态管理**: 自动管理停靠状态，避免冲突
- 🎭 **两步式行为**: 先对齐到目标位置，再根据鼠标位置智能隐藏/显示
- 🔌 **完全独立**: 智能停靠与 MyTray 托盘功能完全解耦，可单独使用
  - 仅使用智能停靠（不需要托盘）✅
  - 仅使用托盘（不需要智能停靠）✅
  - 两者同时使用时自动协调窗口状态 ✅

### 功能对比：`dockToCorner` vs 智能停靠

| 功能           | `dockToCorner`       | 智能停靠 (`setSmartEdgeDocking`) |
| -------------- | -------------------- | -------------------------------- |
| **触发方式**   | 手动调用 API         | 自动检测拖拽行为                 |
| **行为模式**   | 仅对齐到角落，不隐藏 | 先对齐，后根据鼠标智能隐藏       |
| **适用场景**   | 简单的窗口定位       | 类似 QQ 的智能停靠体验           |
| **鼠标交互**   | 无                   | 鼠标悬停显示，离开隐藏           |
| **使用复杂度** | 简单                 | 自动化，无需手动管理             |

```dart
// 简单对齐到角落（不隐藏）
await MyApp.dockToCorner(WindowCorner.topLeft);

// vs

// 智能停靠（自动检测 + 智能隐藏）
await MyApp.setSmartEdgeDocking(enabled: true);
```

**重要更新**：智能角落停靠行为已优化！现在当拖拽到屏幕角落时，窗口会：

1. 🎯 **先对齐到角落** - 与边缘停靠行为保持一致
2. 👁️ **再智能隐藏** - 鼠标离开时才隐藏到角落
3. 🔄 **鼠标交互** - 悬停显示完整窗口，离开后隐藏

这确保了角落停靠与边缘停靠具有一致的用户体验。

**最新优化**：Taskbar 智能对齐！现在智能停靠会自动检测任务栏位置：

- 🎯 **智能检测**: 自动检测任务栏在屏幕的哪个边缘（左、右、上、下）
- 📏 **外边缘对齐**: 当停靠边缘或角落的某个边缘有任务栏时，窗口会对齐到任务栏的外边缘而不是工作区域边缘
- 🔄 **保持兼容**: `dockToCorner`功能保持原有行为（对齐到工作区域内侧）
- 🖥️ **跨平台支持**: 支持不同操作系统的任务栏配置

这样可以避免窗口被任务栏遮挡，提供更好的用户体验。

注意：此功能仅在桌面平台（Windows、macOS、Linux）上可用。

### 窗口控制 API

XLY 包提供了一系列窗口控制 API，允许您动态管理窗口的各种行为特性：

#### 窗口标题控制

通过以下 API 动态设置 / 获取窗口标题。桌面平台会同步到原生窗口标题；非桌面平台将更新内部状态，并即时反映在 GetMaterialApp 的 title 上。

```dart
// 设置窗口标题（桌面端会调用 windowManager.setTitle）
await MyApp.setWindowTitle('我的新标题');

// 获取当前窗口标题（无标题时返回空字符串）
final current = MyApp.getWindowTitle();
```

特性：

- 即时生效：内部通过 Obx 监听全局标题状态，GetMaterialApp 的 title 会动态更新
- 跨平台可用：非桌面端也可安全调用（不触发原生 API）
- 初始化联动：如果在 MyApp.initialize 传入 appName，会作为初始标题

#### 窗口比例调整控制

控制窗口是否按固定比例调整大小：

```dart
// 启用窗口比例调整（窗口将保持初始宽高比）
await MyApp.setAspectRatioEnabled(true);

// 禁用窗口比例调整（窗口可以自由调整为任意比例）
await MyApp.setAspectRatioEnabled(false);

// 检查当前比例调整状态
bool isEnabled = MyApp.isAspectRatioEnabled();
```

**特性说明：**

- 🔒 **比例锁定**: 启用时窗口将保持初始设计尺寸的宽高比
- 🔓 **自由调整**: 禁用时窗口可以调整为任意比例
- ⚙️ **动态切换**: 可以在运行时动态启用或禁用
- 🎯 **智能计算**: 基于当前窗口尺寸自动计算并应用比例
- 🖥️ **桌面专用**: 仅在桌面平台（Windows、macOS、Linux）上可用

**初始化配置：**

您也可以在`MyApp.initialize()`中设置默认的比例调整行为：

```dart
await MyApp.initialize(
  designSize: const Size(900, 700),
  setAspectRatioEnabled: true,  // 默认启用比例调整
  // ... 其他配置
);
```

#### 其他窗口控制 API

```dart
// 窗口大小调整控制
await MyApp.setResizableEnabled(true);   // 允许调整窗口大小
bool canResize = MyApp.isResizableEnabled();

// 窗口拖动控制
await MyApp.setDraggableEnabled(true);   // 允许拖动窗口
bool canDrag = MyApp.isDraggableEnabled();

// 双击最大化控制
await MyApp.setDoubleClickMaximizeEnabled(true);  // 允许双击最大化
bool canDoubleClick = MyApp.isDoubleClickMaximizeEnabled();

// 全屏功能控制
await MyApp.setFullScreenEnabled(true);   // 启用全屏功能
bool canFullScreen = MyApp.isFullScreenEnabled();
await MyApp.toggleFullScreen();           // 切换全屏状态

// 标题栏显示控制
await MyApp.setTitleBarHidden(false);    // 显示标题栏
bool isHidden = MyApp.isTitleBarHidden();
```

#### 全屏功能详细说明

全屏功能让窗口占据整个屏幕，隐藏任务栏等系统 UI，提供沉浸式体验：

**基本使用**：

```dart
// 检查全屏功能是否可用
if (MyApp.isFullScreenEnabled()) {
  // 切换全屏状态
  await MyApp.toggleFullScreen();
}

// 或者直接切换（内部会自动检查）
await MyApp.toggleFullScreen();
```

**与智能停靠的交互**：

- ✅ **正常状态下**：全屏功能正常工作
- ❌ **智能停靠状态下**：全屏功能自动禁用，防止功能冲突
- 💡 **使用建议**：如需使用全屏功能，请先退出智能停靠模式

**全屏 vs 最大化的区别**：

- **最大化**：窗口占据工作区域，任务栏等系统 UI 仍然可见
- **全屏**：窗口占据整个屏幕，隐藏所有系统 UI，提供完全沉浸式体验

**注意事项**：

- 全屏功能仅在桌面平台（Windows、macOS、Linux）上可用
- 在智能停靠状态下会自动禁用，避免状态冲突
- 退出全屏后窗口会恢复到之前的状态

### 使用全局浮动面板

`FloatPanel` 是一个全新的全局浮动面板系统，提供拖拽、贴边、展开/收起等交互功能。通过统一的全局管理器 `FloatPanel.to`，你可以在任意位置控制面板的显示、按钮、状态和样式。

```dart
// main.dart
void main() async {
  await MyApp.initialize(
    // ... 其他配置
    // 全局浮动面板通过 floatPanel 参数自动挂载
    floatPanel: FloatPanel()
      ..configure(
        items: [
          FloatPanelIconBtn(
            icon: Icons.home,
            id: 'home',
            onTap: () {
              Get.toNamed('/home');
            },
          ),
          FloatPanelIconBtn(
            icon: Icons.settings,
            id: 'settings',
            onTap: () {
              Get.toNamed('/settings');
            },
          ),
          FloatPanelIconBtn(
            icon: Icons.exit_to_app,
            onTap: () async {
              await MyApp.exit();
            },
          ),
        ],
        // 可选：自定义样式和动画（全部有默认值）
        borderColor: Colors.grey,
        initialPanelIcon: Icons.menu,
        panelAnimDuration: 800,
        panelAnimCurve: Curves.easeInOut,
        dockAnimDuration: 200,
        dockAnimCurve: Curves.fastOutSlowIn,
      ),
  );
}
```

### 使用自启动管理

```dart
// 检查是否支持自启动功能
if (MyAutoStart.isSupported()) {
  // 启用开机自启动
  final success = await MyAutoStart.setAutoStart(
    true,
    // 可选：指定桌面平台的包名
    packageName: 'com.myapp.example',
  );

  if (success) {
    print('设置开机自启动成功');
  } else {
    print('设置开机自启动失败');
  }
}

// 禁用开机自启动
await MyAutoStart.setAutoStart(false);
```

注意：

- Web 平台不支持此功能
- Android 平台会打开系统设置页面
- 桌面平台需要提供正确的包名（可选）

## App 重命名功能

本包集成了应用重命名功能，支持一键重命名所有平台的应用名称：

```bash
# 为所有平台设置相同名称
dart run xly:rename all "新应用名称"

# 支持带空格的应用名
dart run xly:rename all "好人 平安"

# 为不同平台设置不同名称
dart run xly:rename android "Android版本" ios "iOS版本" windows "Windows版本"
```

### FloatPanel 多选禁用与常亮控制

- 新增“多选禁用”能力：可同时禁用多个带 id 的按钮（`disabledIds` 集合）
- 新增"常亮控制"能力：可让指定按钮保持高亮显示状态，且不影响启用/禁用（`highlightedIds` 集合）
- 示例采用“路由单选策略”：切换页面时清理历史禁用，仅禁用当前页对应按钮
- 如需跨页面保留多选禁用，只需去掉“清理历史禁用”的步骤

#### 常亮控制 API

```dart
// 设置按钮常亮（高亮显示）
FloatPanel.to.iconBtn('your_id').setHighlighted(true);

// 取消按钮常亮
FloatPanel.to.iconBtn('your_id').setHighlighted(false);

// 切换按钮常亮状态
FloatPanel.to.iconBtn('your_id').toggleHighlighted();

// 查询按钮是否常亮
bool isHighlighted = FloatPanel.to.iconBtn('your_id').isHighlighted;

// 清空所有常亮按钮
FloatPanel.to.highlightedIds.clear();
```

详细说明请见： [本地](.doc/float_panel_usage.md) | [GitHub](https://github.com/dbsxdbsx/flutter_xly/blob/main/.doc/float_panel_usage.md)

### 使用自适应侧边栏导航

`MyScaffold` 提供了遵循 Material 3 规范的五层级自适应导航体验，并包含智能导航系统：

#### 🎯 M3 五层级自适应布局

| 层级 | 宽度范围 | 导航形态 |
|------|---------|---------|
| **Compact** | < 600dp | 抽屉式导航或底部导航栏 |
| **Medium** | 600 ~ 840dp | 仅图标侧边栏（72dp），hover 显示 Tooltip |
| **Expanded** | 840 ~ 1200dp | 图标+文字侧边栏（256dp） |
| **Large** | 1200 ~ 1600dp | 完整导航抽屉（304dp），含分组标题、副标题、Header |
| **XLarge** | ≥ 1600dp | 宽导航抽屉（360dp），trailing 内嵌、间距更宽松 |

#### 🧭 智能导航功能

1. **自动路由同步** - 侧边栏选中状态与当前路由自动同步
2. **简化导航 API** - 只需指定`route`参数即可自动导航
3. **智能自动滚动** - 选中项自动滚动到可视区域
4. **可配置选项** - 灵活控制滚动条和自动滚动行为

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xly/xly.dart';

class NavigationController extends GetxController {
  var currentIndex = 0.obs;

  void switchToPage(int index) {
    currentIndex.value = index;
  }
}

class MyHomePage extends StatelessWidget {
  final controller = Get.put(NavigationController());

  final List<Widget> pages = [
    Center(child: Text('首页内容')),
    Center(child: Text('设置内容')),
    Center(child: Text('关于内容')),
  ];

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      appBar: AppBar(title: Text('我的应用')),
      // 智能导航配置
      alwaysShowScrollbar: false,    // 控制滚动条显示（默认false）
      autoScrollToSelected: true,    // 控制自动滚动（默认true）

      drawer: [
        // 基础用法：指定 route 自动导航
        MyAdaptiveNavigationItem(
          icon: Icon(Icons.home),
          label: '首页',
          subtitle: '数据概览',       // 仅 Large+ 层级显示
          group: '主要功能',          // 仅 Large+ 层级显示分组标题
          route: '/page1',
        ),
        MyAdaptiveNavigationItem(
          icon: Icon(Icons.settings),
          label: '设置',
          subtitle: '应用偏好配置',
          group: '主要功能',
          route: '/page2',
          badgeCount: 2,             // 可选的徽章数量
        ),
        // 自定义版本：需要特殊逻辑时使用 onTap
        MyAdaptiveNavigationItem(
          icon: Icon(Icons.info),
          label: '关于',
          group: '其他',
          route: '/page3',
          onTap: () {
            controller.switchToPage(2);
            Get.toNamed('/page3');
          },
        ),
      ],
      // 导航顶部 Header（Large+ 层级及 Compact 抽屉中显示）
      navigationHeader: Padding(
        padding: EdgeInsets.all(16),
        child: Row(children: [
          CircleAvatar(child: Icon(Icons.apps)),
          SizedBox(width: 12),
          Text('我的应用', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
      ),
      body: Obx(() => pages[controller.currentIndex.value]),

      // 断点配置（均可自定义，需严格递增）
      compactBreakpoint: 600.0,      // Compact / Medium 分界
      mediumBreakpoint: 840.0,       // Medium / Expanded 分界
      expandedBreakpoint: 1200.0,    // Expanded / Large 分界
      largeBreakpoint: 1600.0,       // Large / XLarge 分界
      useBottomNavigationOnSmall: false,
      drawerWidthRatio: 0.88,
    );
  }
}
```

**智能功能：**

- **自动路由同步**：无论通过什么方式导航，侧边栏状态都会自动同步
- **简化 API**：只需指定`route`参数，无需手写`onTap`回调
- **智能滚动**：选中项自动滚动到可视区域，确保始终可见
- **即时响应**：无延迟的界面更新和状态同步
- **分组与副标题**：Large+ 层级自动显示 `group` 分组标题和 `subtitle` 副标题
- **导航 Header**：支持自定义顶部区域（如 Logo、用户信息），Large+ 层级和 Compact 抽屉中展示
- **完全透明**：框架级功能，用户代码零改动

## 完整示例

对于一个完整的示例，请参考 Example 页面。该示例展示了如何综合使用 xly 包中的各种功能，包括按钮、菜单、焦点管理和导航等。Example 页面提供了更详细的代码实现和实际运行效果，可以帮助您更好地理解和使用 xly 包的各项功能。

您可以在项目的 `example` 目录下找到完整的示例代码。通过运行示例项目，您可以直观地体验 xly 包提供的各种组件和功能，并了解它们在实际应用中的使用方法。

## splash Json 动画资源

- [lottie 动画参考 1](https://lottiefiles.com/featured)
- [lottie 动画参考 2](https://iconscout.com/lottie-animations/)

## 注意事项

- 确保在使用 XLY 包的功能之前已经正确初始化了应用。
- 某些功能可能需要额外的设置或权限，请参考具体组件的文档。
- **调试日志**：XLY 包默认不会输出调试日志，避免污染您的项目日志。如需排查问题，可在 `MyApp.initialize()` 中设置 `enableDebugLogging: true` 来启用详细日志。

## 贡献

欢迎提交问题和拉取请求。对于重大更改，请先开启一个问题讨论您想要改的内容。

### 贡献者必读

如果您想为 XLY 包贡献代码，请务必阅读：

- [日志系统规范](.doc/contributor_logging_guide.md) - 了解如何正确使用 `XlyLogger` 进行日志输出

## 许可证

[MIT](https://choosealicense.com/licenses/mit/)
