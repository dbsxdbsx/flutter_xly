# MyTray 设计文档

## 概述

MyTray 是 xly_flutter_package 中的系统托盘功能模块，作为全局服务提供完整的桌面应用托盘解决方案。

## 最新设计方案（2025-07-17）

### 设计理念
- **完全可选**: 不需要托盘功能时完全不涉及
- **简洁强制**: 只有iconPath是必需的，其他都可选
- **全局服务**: 继承GetxService，享受全局生命周期管理
- **统一访问**: 通过MyTray.to进行所有操作
- **职责分离**: MyApp专注应用框架，MyTray专注托盘功能

### 核心API设计

#### MyTray类签名
```dart
class MyTray extends GetxService with TrayListener, WindowListener {
  final String iconPath;           // 必需：托盘图标路径
  final String? tooltip;           // 可选：悬停提示，默认不显示
  final List<MyTrayMenuItem>? menuItems; // 可选：右键菜单，默认无菜单

  MyTray({
    required this.iconPath,
    this.tooltip,
    this.menuItems,
  });

  static MyTray get to => Get.find();
}
```

#### 推荐初始化方式：使用tray参数
```dart
void main() async {
  await MyApp.initialize(
    designSize: const Size(800, 600),
    routes: [...],

    // 推荐：使用tray参数（简化配置）
    tray: MyTray(
      iconPath: "assets/icon.png",  // 可选，为空时自动使用默认图标
      tooltip: "My App",
      menuItems: [
        MyTrayMenuItem(key: 'show', label: '显示', onTap: () => MyTray.to.pop()),
        MyTrayMenuItem.separator(),
        MyTrayMenuItem(key: 'settings', label: '设置', enabled: false), // 禁用项
        MyTrayMenuItem(key: 'exit', label: '退出', onTap: () => exit(0)),
      ],
    ),
  );
}
```

#### 传统初始化方式：使用services参数（向后兼容）
```dart
void main() async {
  await MyApp.initialize(
    designSize: const Size(800, 600),
    routes: [...],

    services: [
      // 最简使用
      MyService<MyTray>(
        service: () => MyTray(iconPath: "assets/icon.png"),
        permanent: true,
      ),

      // 完整配置
      MyService<MyTray>(
        service: () => MyTray(
          iconPath: "assets/icon.png",
          tooltip: "My App",
          menuItems: [
            MyTrayMenuItem(label: '显示', onTap: () => MyTray.to.pop()),
            MyTrayMenuItem.separator(),
            MyTrayMenuItem(label: '退出', onTap: () => exit(0)),
          ],
        ),
        permanent: true,
      ),
    ],
  );
}
```

#### 运行时操作
```dart
final tray = MyTray.to;

// 基础操作
tray.hide();                    // 隐藏窗口到托盘
tray.pop();                     // 从托盘恢复窗口
tray.notify("标题", "消息");      // 显示通知

// 动态配置
tray.setTooltip("新提示");       // 更新提示文本
tray.setContextMenu([...]);     // 更新右键菜单
tray.setIcon("new_icon.png");   // 动态设置图标

// 菜单项禁用状态控制
tray.setMenuItemEnabled('settings', true);   // 启用设置菜单
bool isEnabled = tray.getMenuItemEnabled('settings'); // 查询状态
tray.toggleMenuItemEnabled('settings');      // 切换状态

// 托盘点击行为控制
tray.setToggleOnClick(true);              // 开启切换语义
bool isToggleMode = tray.getToggleOnClick(); // 查询当前状态
tray.toggleToggleOnClick();               // 切换开关状态
```

### 默认行为
- **tooltip**: 不显示（`null`）
- **menuItems**: 无菜单（`null`）
- **hideTaskBarIcon**: 隐藏任务栏图标（`true`）
- **toggleOnClick**: 开启切换语义（`true`）
- **图标验证**: 构造时检查文件存在性，不存在则抛异常
- **平台检查**: 非桌面平台自动跳过初始化
- **生命周期**: 随应用启动/关闭自动管理

### 与MyApp.initialize的关系
- **MyApp.initialize**: 完全不涉及托盘逻辑，只负责服务注册
- **职责分离**: MyApp专注应用框架，MyTray专注托盘功能
- **可选性**: 不注册MyTray服务，应用完全正常运行

## 核心功能

### 基础功能
- 托盘图标显示和管理
- 窗口最小化到托盘
- 从托盘恢复窗口
- 托盘右键菜单
- 托盘通知消息

### 高级功能
- 动态图标切换
- 自定义托盘菜单
- 动态图标和提示更新
- 菜单项启用/禁用状态控制（原生灰色样式）
- 平台特定行为适配

## 架构设计

### 类结构
```
MyTray (GetxService)  ← 改为继承GetxService
├── TrayListener (mixin)
├── WindowListener (mixin)
└── 状态管理 (Rx变量)
```

### 核心组件
- `MyTray`: 主要的托盘管理器类（GetxService）
- `MyTrayMenuItem`: 托盘菜单项配置（支持key、enabled等属性）
- `MyTrayNotification`: 通知消息处理
- ~~`MyTrayIconConfig`: 图标配置选项~~（已移除，简化设计）
- ~~`MyTrayWrapper`: 托盘包装器组件~~（已移除，不再需要）

### 架构清理说明
**重要变更**：已完全移除 `MyApp.initialize` 中的托盘相关参数：
- ~~`enableTray`~~（已移除）
- ~~`trayIcon`~~（已移除）
- ~~`trayTooltip`~~（已移除）
- ~~`MyTrayWrapper`~~（已删除文件）

**唯一初始化方式**：现在托盘功能完全通过 `MyService<MyTray>` 管理，避免了架构重复和参数冲突。

### 枚举定义
```dart
enum MyTrayNotificationType {
  info,
  warning,
  error,
  success,
}
```

## 设计原则

### 消息显示策略
1. **隐式操作**：系统自动触发的操作（如窗口事件监听）**绝不显示消息**
2. **显式操作**：用户明确点击按钮触发的操作，**由调用方决定是否显示消息**
3. **示例演示**：在 example 中演示如何在用户操作时显示适当的反馈消息

### 图标管理策略
1. **显式指定**：用户必须明确指定图标路径，不提供自动检测
2. **平台适配**：Windows 使用 .ico 格式，其他平台使用 .png 格式
3. **动态切换**：支持运行时通过setIcon方法动态更换图标

### 实现细节
- `MyTray.hide()` 方法本身不显示任何消息
- 消息显示完全由调用方控制
- 图标路径必须由用户显式指定
- 在 example 中展示最佳实践：用户明确操作时显示托盘气泡通知

## 集成方案

### Example 使用示例

#### 基础使用
```dart
// 在 main.dart 中 - 最简单的配置
await MyApp.initialize(
  appName: "示例App",
  services: [
    MyService<MyTray>(
      service: () => MyTray(iconPath: "assets/tray_icon.png"),
    ),
  ],
);

// 在页面中使用
final myTray = MyTray.to;

// 隐藏到托盘按钮 - 明确显示消息
MyButton(
  text: "隐藏到托盘",
  onPressed: () {
    myTray.hide();
    // 用户明确操作时显示托盘气泡通知
    myTray.notify("已隐藏到托盘", "点击托盘图标可恢复窗口");
  },
);

// 静默隐藏（不显示消息）
MyButton(
  text: "静默隐藏",
  onPressed: () => myTray.hide(), // 不显示任何消息
);
```

#### 完整配置
```dart
// 带tooltip和菜单的完整配置
await MyApp.initialize(
  appName: "示例App",
  services: [
    MyService<MyTray>(
      service: () => MyTray(
        iconPath: "assets/tray_icon.png",
        tooltip: "我的应用",
        menuItems: [
          MyTrayMenuItem(key: 'show', label: '显示主窗口', onTap: () => MyTray.to.pop()),
          MyTrayMenuItem.separator(),
          MyTrayMenuItem(key: 'settings', label: '设置', enabled: false), // 禁用项示例
          MyTrayMenuItem(key: 'exit', label: '退出应用', onTap: () => exit(0)),
        ],
      ),
    ),
  ],
);

// 动态更换图标
final myTray = MyTray.to;
myTray.setIcon("assets/tray_busy.png");  // 切换到忙碌图标
myTray.setIcon("assets/tray_normal.png"); // 切换回正常图标
```

## 菜单项禁用功能

### 功能概述
MyTray 支持菜单项的启用/禁用状态控制，使用系统原生的禁用样式和行为。

### 实现原理
- **原生支持**：通过 `tray_manager` 重导出的 `menu_base` 包，使用 `MenuItem.disabled` 属性
- **系统样式**：禁用项显示为系统标准的灰色样式，在系统层面不可点击
- **跨平台**：Windows/macOS 完全支持，Linux 依桌面环境而定

### 基础用法

#### 静态禁用
```dart
MyTrayMenuItem(
  key: 'settings',        // 推荐提供稳定的key
  label: '设置',
  enabled: false,         // 设置为禁用状态
  onTap: () => openSettings(),
),
```

#### 动态控制
```dart
final myTray = MyTray.to;

// 查询状态
bool isEnabled = myTray.getMenuItemEnabled('settings');

// 设置状态
await myTray.setMenuItemEnabled('settings', true);   // 启用
await myTray.setMenuItemEnabled('settings', false);  // 禁用

// 切换状态
await myTray.toggleMenuItemEnabled('settings');
```

### 完整示例
```dart
// 初始化时设置菜单
MyTray(
  menuItems: [
    MyTrayMenuItem(key: 'show', label: '显示窗口', onTap: () => MyTray.to.pop()),
    MyTrayMenuItem.separator(),
    MyTrayMenuItem(key: 'sync', label: '同步数据', enabled: false), // 初始禁用
    MyTrayMenuItem(key: 'settings', label: '设置', onTap: () => openSettings()),
    MyTrayMenuItem.separator(),
    MyTrayMenuItem(key: 'exit', label: '退出', onTap: () => exit(0)),
  ],
),

// 运行时根据状态动态启用/禁用
void onSyncStatusChanged(bool canSync) async {
  await MyTray.to.setMenuItemEnabled('sync', canSync);
}
```

### 注意事项
- **key 的重要性**：推荐为每个菜单项提供唯一的 `key`，便于后续查找和修改
- **子菜单支持**：子菜单项同样支持禁用功能
- **平台差异**：Linux 下的视觉效果可能因桌面环境而异
- **性能考虑**：动态修改会重建整个菜单，频繁操作时需注意性能

## 图标管理

### 图标要求
- **Windows**: 推荐使用 `.ico` 格式，支持多尺寸
- **macOS**: 推荐使用 `.png` 格式，系统会自动处理模板图标
- **Linux**: 推荐使用 `.png` 格式
- **路径**: 必须是相对于项目根目录的有效路径
- **尺寸**: 32x32像素

### 动态图标切换
```dart
final myTray = MyTray.to;

// 根据应用状态动态切换图标
myTray.setIcon("assets/tray_normal.png");   // 正常状态
myTray.setIcon("assets/tray_warning.png");  // 警告状态
myTray.setIcon("assets/tray_error.png");    // 错误状态
myTray.setIcon("assets/tray_busy.png");     // 忙碌状态
```

## 平台兼容性
- **Windows**: 完整支持所有功能，使用 .ico 格式图标
- **macOS**: 支持基本功能，遵循 macOS 设计规范，使用 .png 格式图标
- **Linux**: 支持基本功能，使用 .png 格式图标
- **移动端**: 优雅降级（不支持托盘时不报错）

## 已知问题与限制

### Windows平台菜单问题
- **问题描述**：在Windows平台上，右键菜单在点击菜单项后可能不会自动关闭
- **相关Issue**：[tray_manager#63](https://github.com/leanflutter/tray_manager/issues/63)
- **临时解决方案**：MyTray组件实现了一个workaround，通过重置菜单来强制关闭
- **影响**：可能会有轻微的视觉闪烁，但确保菜单能正确关闭
- **状态**：等待tray_manager官方修复

### 图标格式要求
- **Windows**：推荐使用 `.ico` 格式，支持多尺寸
- **macOS**：推荐使用 `.png` 格式，系统会自动处理模板图标
- **Linux**：推荐使用 `.png` 格式

### 通知功能限制
- 当前实现使用 `setToolTip` 方式显示通知
- 真正的系统通知需要额外的通知权限和API

## 实现计划

### 阶段1: 基础架构
1. 添加 `tray_manager` 依赖
2. 创建基础文件结构
3. 实现 `MyTray` 核心功能（继承GetxService）

### 阶段2: 功能完善
1. 实现托盘菜单系统
2. 实现通知功能
3. 集成窗口管理
4. 添加动态图标切换

### 阶段3: 集成与示例
1. 集成到 `MyApp` 初始化流程
2. 创建 example 使用示例
3. 添加文档和测试
4. 更新 README 和 CHANGELOG

---

## 最新设计方案总结（2025-07-17）

### 核心变更
1. **继承GetxService**: MyTray改为继承GetxService而非GetxController，确保全局生命周期管理
2. **简化构造函数**: 只保留iconPath（可选）、tooltip（可选）、menuItems（可选）三个参数
3. **移除复杂配置**: 删除MyTrayIconConfig和MyTrayWrapper，简化API设计
4. **职责分离**: MyApp.initialize只负责服务注册，不涉及托盘具体逻辑
5. **架构清理**: 完全移除MyApp.initialize中的enableTray、trayIcon、trayTooltip参数，避免重复配置

### 设计优势
- **完全可选**: 不需要托盘时完全不涉及，零影响
- **架构清晰**: 唯一初始化方式，避免参数重复和配置冲突
- **简洁易用**: iconPath可选（自动使用默认图标），其他参数都有合理默认值
- **使用体验**: 一行注册，MyTray.to全功能访问
- **生命周期**: 作为GetxService自动管理，永不被意外释放

### 最终API
```dart
// 初始化（唯一方式）
MyService<MyTray>(
  service: () => MyTray(
    // iconPath: "assets/icon.png",  // 可选：为空时自动使用默认应用图标
    tooltip: "我的应用",              // 可选：悬停提示
    menuItems: [                    // 可选：右键菜单
      MyTrayMenuItem(label: '显示', onTap: () => MyTray.to.pop()),
      MyTrayMenuItem.separator(),
      MyTrayMenuItem(label: '退出', onTap: () => exit(0)),
    ],
  ),
);

// 使用
MyTray.to.hide();
MyTray.to.pop();
MyTray.to.notify("标题", "消息");
MyTray.to.setIcon("new_icon.png");
MyTray.to.setMenuItemEnabled("settings", true);
```

**架构优势**：
- ✅ 唯一初始化方式，避免配置冲突
- ✅ 完全可选，不需要时零影响
- ✅ 参数简洁，智能默认值
- ✅ 架构清晰，职责单一

这个设计达到了最佳平衡：简洁易用、功能强大、架构清晰、生态一致。
