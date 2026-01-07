# Flutter 桌面多窗口开发指南

> 本文档详细分析 Flutter 桌面应用中多窗口的实现方案、当前限制、以及 XLY 包的推荐策略。
>
> 最后更新：2026年1月

---

## 📋 目录

- [使用场景](#使用场景)
- [技术现状分析](#技术现状分析)
- [实现方案对比](#实现方案对比)
- [XLY 包当前能力](#xly-包当前能力)
- [推荐策略](#推荐策略)
- [未来展望](#未来展望)

---

## 使用场景

### 典型的多窗口需求

开发**语音输入法**、**翻译工具**、**截图工具**、**启动器**等桌面应用时，通常需要以下多窗口布局：

| 窗口类型 | 触发方式 | 特点 |
|---------|---------|------|
| **悬浮录音窗口** | 全局热键 | 小尺寸、无边框、透明、置顶、不在任务栏显示 |
| **主设置窗口** | 托盘点击 | 标准窗口、有边框、正常尺寸 |

类似产品参考：Typeless、Wispr、讯飞语音输入法、Bob 翻译、Raycast、uTools 等。

### 为什么必须是独立窗口？

桌面端悬浮窗与移动端 Overlay 有本质区别：

```
┌─────────────────────────────────────────────────────────────────────┐
│                        移动端 Overlay（不适用于桌面悬浮窗）           │
├─────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────┐                        │
│  │              你的 App                    │                        │
│  │  ┌─────────────────────────────────┐    │                        │
│  │  │       Overlay / BottomSheet     │    │  ← 只能在 App 内部显示 │
│  │  └─────────────────────────────────┘    │                        │
│  └─────────────────────────────────────────┘                        │
├─────────────────────────────────────────────────────────────────────┤
│                        桌面端悬浮窗（必须是独立窗口）                  │
├─────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────┐  ← 语音输入悬浮窗      │
│  │       小悬浮窗（置顶、无边框）            │    必须在系统级别      │
│  └─────────────────────────────────────────┘    显示在所有应用上方   │
│  ┌─────────────────────────────────────────┐                        │
│  │          Word / VS Code / 浏览器         │  ← 其他应用            │
│  └─────────────────────────────────────────┘                        │
└─────────────────────────────────────────────────────────────────────┘
```

**Flutter 的 Overlay 无法满足桌面悬浮窗需求**，因为：
1. Overlay 只能在当前 App 窗口内显示
2. 系统级置顶需要操作系统窗口管理器支持
3. 热键触发时，App 主窗口可能处于隐藏状态

---

## 技术现状分析

### Flutter 官方多窗口支持状态

| 项目 | 状态 | 说明 |
|------|------|------|
| 开发团队 | Canonical（Ubuntu 团队） | 负责 Flutter 桌面多窗口开发 |
| 当前版本 | Flutter 3.38.x | 多窗口**尚未进入稳定版** |
| 架构设计 | **单引擎多视图** | 与第三方方案架构完全不同 |
| 预计稳定 | 2025 年下半年 ~ 2026年 | 官方未给出明确时间表 |

### 第三方方案：desktop_multi_window

| 项目 | 信息 |
|------|------|
| 仓库地址 | [MixinNetwork/flutter-plugins](https://github.com/MixinNetwork/flutter-plugins/tree/main/packages/desktop_multi_window) |
| 维护团队 | MixinNetwork（第三方公司） |
| 架构设计 | **多引擎**（每窗口独立 Flutter 引擎） |
| 状态 | 可用，但有明显限制 |

### 架构差异对比

```
┌─────────────────────────────────────────────────────────────────────┐
│                     两种架构的本质区别                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  desktop_multi_window（第三方 - 多引擎）                             │
│  ┌─────────┐   ┌─────────┐   ┌─────────┐                           │
│  │ 窗口 1  │   │ 窗口 2  │   │ 窗口 3  │                           │
│  │ Engine  │   │ Engine  │   │ Engine  │  ← 每个窗口独立引擎        │
│  │ 独立    │   │ 独立    │   │ 独立    │  ← 内存占用 ×N            │
│  └─────────┘   └─────────┘   └─────────┘  ← 数据隔离，需要 IPC      │
│                                                                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Flutter 官方多窗口（开发中 - 单引擎多视图）                          │
│  ┌─────────────────────────────────────────┐                        │
│  │           Single Flutter Engine          │  ← 单引擎             │
│  │  ┌───────┐  ┌───────┐  ┌───────┐        │                        │
│  │  │View 1 │  │View 2 │  │View 3 │        │  ← 多视图             │
│  │  │窗口 1 │  │窗口 2 │  │窗口 3 │        │  ← 共享内存 + 状态    │
│  │  └───────┘  └───────┘  └───────┘        │  ← 无需 IPC           │
│  └─────────────────────────────────────────┘                        │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 实现方案对比

### 方案一：单窗口 + 模式切换（推荐 - XLY 当前可行）

**原理**：使用单个窗口，通过动态修改窗口属性来切换不同的显示模式。

```dart
// 切换到悬浮模式（语音输入）
await windowManager.setSize(Size(400, 120));
await windowManager.setAsFrameless();
await windowManager.setAlwaysOnTop(true);
await windowManager.setSkipTaskbar(true);
await windowManager.show();

// 切换到标准模式（设置窗口）
await windowManager.setSize(Size(800, 600));
await windowManager.setTitleBarStyle(TitleBarStyle.normal);
await windowManager.setAlwaysOnTop(false);
await windowManager.setSkipTaskbar(false);
await windowManager.show();

// 隐藏到托盘
await windowManager.hide();
```

| 优点 | 缺点 |
|------|------|
| ✅ 实现简单 | ❌ 无法同时显示两个窗口 |
| ✅ 内存效率高 | ❌ 模式切换有短暂闪烁 |
| ✅ 状态共享无障碍 | ❌ 用户体验略逊于原生多窗口 |
| ✅ 无需额外依赖 | |

**适用场景**：
- 悬浮窗和设置窗口**不需要同时显示**
- 对内存占用敏感的应用
- 希望保持代码简单的项目

### 方案二：第三方多窗口（desktop_multi_window）

**原理**：使用第三方库创建多个独立窗口，每个窗口运行独立的 Flutter 引擎。

```yaml
# pubspec.yaml
dependencies:
  desktop_multi_window: ^0.2.3
```

```dart
// 创建悬浮录音窗口
final overlayWindow = await DesktopMultiWindow.createWindow(jsonEncode({
  'windowType': 'overlay',
}));
overlayWindow
  ..setFrame(Rect.fromLTWH(100, 100, 400, 120))
  ..setTitle('语音输入')
  ..show();

// 创建设置窗口
final settingsWindow = await DesktopMultiWindow.createWindow(jsonEncode({
  'windowType': 'settings',
}));
settingsWindow
  ..setFrame(Rect.fromLTWH(200, 200, 800, 600))
  ..setTitle('设置')
  ..show();

// 窗口间通信（需要 IPC）
DesktopMultiWindow.invokeMethod(windowId, 'updateData', jsonEncode(data));
```

| 优点 | 缺点 |
|------|------|
| ✅ 可同时显示多个窗口 | ❌ 内存占用高（引擎 × 窗口数） |
| ✅ 窗口完全独立 | ❌ 数据隔离，需要 IPC 通信 |
| ✅ 当前可用 | ❌ 需要原生代码配置子窗口插件 |
| | ❌ 未来需要迁移到官方方案 |

**适用场景**：
- **必须**同时显示多个窗口
- 对内存占用不敏感
- 接受未来代码迁移成本

### 方案三：等待 Flutter 官方多窗口（推荐的长期策略）

**原理**：等待 Flutter 官方的单引擎多视图方案稳定。

```dart
// 预期的官方 API（推测，非最终版）
import 'package:flutter/widgets.dart';

// 直接使用，无需额外依赖
final newView = await platformDispatcher.createView(
  initialSize: Size(400, 120),
);

// 所有窗口共享状态管理
Get.find<MyController>().someValue;  // 直接可用，无需 IPC
```

| 优点 | 缺点 |
|------|------|
| ✅ 官方支持，长期稳定 | ❌ 尚未发布稳定版 |
| ✅ 单引擎，内存效率高 | ❌ 具体发布时间不确定 |
| ✅ 状态直接共享 | |
| ✅ 无需额外依赖 | |

**适用场景**：
- 项目时间线允许等待
- 追求最佳架构和性能
- 不希望未来进行代码迁移

---

## XLY 包当前能力

### 已有的窗口管理功能

XLY 包目前基于 `window_manager` 提供了丰富的单窗口管理能力：

| 功能 | API | 说明 |
|------|-----|------|
| 窗口大小调整 | `MyApp.setResizableEnabled()` | 启用/禁用窗口大小调整 |
| 窗口拖动 | `MyApp.setDraggableEnabled()` | 启用/禁用窗口拖动 |
| 标题栏控制 | `MyApp.setTitleBarHidden()` | 显示/隐藏标题栏 |
| 宽高比锁定 | `MyApp.setAspectRatioEnabled()` | 启用/禁用宽高比锁定 |
| 全屏切换 | `MyApp.toggleFullScreen()` | 切换全屏状态 |
| 角落停靠 | `MyApp.dockToCorner()` | 窗口对齐到角落 |
| 智能停靠 | `MyApp.setSmartEdgeDocking()` | 类似 QQ 的智能停靠 |
| 系统托盘 | `MyTray` | 托盘图标和菜单 |
| 浮动面板 | `FloatPanel` | 应用内浮动面板 |

### 建议新增的窗口模式 API

```dart
/// 窗口模式枚举
enum XlyWindowMode {
  /// 悬浮模式：小尺寸、无边框、置顶、跳过任务栏
  overlay,

  /// 标准模式：正常窗口、有边框、显示在任务栏
  standard,

  /// 托盘模式：隐藏窗口，仅显示托盘图标
  tray,
}

/// 切换窗口模式
///
/// [mode] 目标窗口模式
/// [size] 可选的窗口大小（仅 overlay 和 standard 模式有效）
///
/// 示例：
/// ```dart
/// // 切换到悬浮模式
/// await MyApp.setWindowMode(XlyWindowMode.overlay, size: Size(400, 120));
///
/// // 切换到标准模式
/// await MyApp.setWindowMode(XlyWindowMode.standard, size: Size(800, 600));
///
/// // 隐藏到托盘
/// await MyApp.setWindowMode(XlyWindowMode.tray);
/// ```
static Future<void> setWindowMode(XlyWindowMode mode, {Size? size}) async {
  // 实现逻辑...
}
```

---

## 推荐策略

### 针对不同需求的建议

| 需求场景 | 推荐方案 | 说明 |
|----------|----------|------|
| 悬浮窗和设置窗口**不需要同时显示** | **单窗口模式切换** | 使用 XLY 现有能力即可 |
| **必须**同时显示多个窗口 | **desktop_multi_window** | 接受限制和迁移成本 |
| 项目时间充裕，追求最佳体验 | **等待官方多窗口** | 2025年下半年~2026年 |

### XLY 包的官方建议

1. **短期**（2025年上半年）
   - 提供窗口模式切换 API（`XlyWindowMode`）
   - 不集成第三方多窗口库
   - 文档说明当前限制和替代方案

2. **中期**（官方多窗口 Beta 后）
   - 评估官方 API 的稳定性
   - 设计兼容层抽象

3. **长期**（官方多窗口稳定后）
   - 集成官方多窗口支持
   - 提供简洁易用的封装 API

---

## 未来展望

### 理想的 XLY 多窗口 API（官方稳定后）

```dart
// 创建悬浮窗
final overlayWindow = await XlyWindow.create(
  type: XlyWindowType.overlay,
  size: Size(400, 120),
  // 自动设置：无边框、置顶、跳过任务栏
);

// 创建标准窗口
final settingsWindow = await XlyWindow.create(
  type: XlyWindowType.standard,
  size: Size(800, 600),
);

// 热键触发时
overlayWindow.show();

// 托盘点击时
settingsWindow.show();

// 状态共享（官方单引擎方案的优势）
// 无需 IPC，直接使用 GetX/Provider 等状态管理
Get.find<AppController>().updateData(...);
```

### 关注的官方进展

- [Flutter GitHub Issues - Multi-window](https://github.com/flutter/flutter/issues?q=multi+window)
- [Flutter 官方博客](https://medium.com/flutter)
- [Flutter 2025 路线图](https://docs.flutter.cn/posts/flutter-2025-roadmap)

---

## 参考资料

- [desktop_multi_window - GitHub](https://github.com/MixinNetwork/flutter-plugins/tree/main/packages/desktop_multi_window)
- [window_manager - pub.dev](https://pub.dev/packages/window_manager)
- [Flutter 2025 产品路线图](https://docs.flutter.cn/posts/flutter-2025-roadmap)
- [XLY Smart Dock 模块文档](../lib/src/smart_dock/README.md)

---

> **文档维护说明**：
> - 当 Flutter 官方多窗口支持进入稳定版后，请更新本文档
> - 如有新的第三方方案或最佳实践，请及时补充

