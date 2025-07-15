# 自适应侧边栏使用指南

## 概述

xly包现在提供了一个优雅的自适应侧边栏组件`MyScaffold`，该组件能够根据屏幕尺寸自动切换显示模式：

- **小屏幕**：传统抽屉式导航（汉堡菜单）或底部导航栏
- **中等屏幕**：收缩的图标式侧边栏
- **大屏幕**：完整的展开式侧边栏（含文字标签和额外内容）

## 基本使用

### 1. 导入依赖

```dart
import 'package:xly/xly.dart';
```

### 2. 简单使用（推荐方式）

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      appBar: AppBar(title: Text('My App')),
      drawer: [
        AdaptiveNavigationItem(
          icon: Icon(Icons.home),
          label: '首页',
          onTap: () => controller.switchToPage(0),
        ),
        AdaptiveNavigationItem(
          icon: Icon(Icons.settings),
          label: '设置',
          badgeCount: 3, // 可选的徽章数量
          onTap: () => controller.switchToPage(1),
        ),
        AdaptiveNavigationItem(
          icon: Icon(Icons.info),
          label: '关于',
          onTap: () => controller.switchToPage(2),
        ),
      ],
      body: Obx(() => pages[controller.currentIndex]),
    );
  }
}
```

### 3. 创建导航项（详细配置）

```dart
final List<AdaptiveNavigationItem> navigationItems = [
  AdaptiveNavigationItem(
    icon: const Icon(Icons.home),
    selectedIcon: const Icon(Icons.home_filled), // 可选的选中图标
    label: '首页',
    onTap: () => debugPrint('首页被点击'),
  ),
  AdaptiveNavigationItem(
    icon: const Icon(Icons.settings),
    label: '设置',
    badgeCount: 3, // 可选的徽章数量
    onTap: () => debugPrint('设置被点击'),
  ),
  AdaptiveNavigationItem(
    icon: const Icon(Icons.info),
    label: '关于',
    onTap: () => debugPrint('关于被点击'),
  ),
];
```

### 3. 使用AdaptiveRootScaffold

```dart
class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int selectedIndex = 0;

  final List<Widget> pages = [
    const HomePage(),
    const SettingsPage(),
    const AboutPage(),
  ];

  @override
  Widget build(BuildContext context) {
    // 为每个导航项添加页面切换逻辑
    final itemsWithNavigation = navigationItems.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;

      return AdaptiveNavigationItem(
        icon: item.icon,
        label: item.label,
        badgeCount: item.badgeCount,
        onTap: () {
          setState(() {
            selectedIndex = index;
          });
          // 执行原有的onTap回调
          if (item.onTap != null) {
            item.onTap!();
          }
        },
      );
    }).toList();

    return MyScaffold(
      drawer: itemsWithNavigation,
      body: pages[selectedIndex],
    );
  }
}
```

### 4. 使用状态管理（GetX示例）

```dart
class NavigationController extends GetxController {
  var currentIndex = 0.obs;

  void switchToPage(int index) {
    currentIndex.value = index;
  }
}

class MyHomePage extends StatelessWidget {
  final NavigationController controller = Get.put(NavigationController());

  final List<Widget> pages = [
    const HomePage(),
    const SettingsPage(),
    const AboutPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      appBar: AppBar(title: Text('我的应用')),
      drawer: [
        AdaptiveNavigationItem(
          icon: Icon(Icons.home),
          selectedIcon: Icon(Icons.home_filled),
          label: '首页',
          onTap: () => controller.switchToPage(0),
        ),
        AdaptiveNavigationItem(
          icon: Icon(Icons.settings),
          label: '设置',
          onTap: () => controller.switchToPage(1),
        ),
        AdaptiveNavigationItem(
          icon: Icon(Icons.info),
          label: '关于',
          onTap: () => controller.switchToPage(2),
        ),
      ],
      body: Obx(() => pages[controller.currentIndex.value]),
    );
  }
}
```

## 高级配置

### 1. 添加侧边栏底部内容

```dart
MyScaffold(
  // ... 其他参数
  sidebarTrailing: const Expanded(
    child: Align(
      alignment: Alignment.bottomCenter,
      child: Text('版本 1.0.0'),
    ),
  ),
)
```

### 2. 配置小屏幕导航

```dart
MyScaffold(
  // ... 其他参数
  useBottomNavigationOnSmall: true, // 小屏幕使用底部导航栏而不是抽屉
)
```

### 3. 自定义断点

```dart
MyScaffold(
  // ... 其他参数
  smallBreakpoint: 480.0,  // 自定义小屏幕断点
  largeBreakpoint: 1024.0, // 自定义大屏幕断点
)
```

## API变更说明

### 新API（推荐）

```dart
MyScaffold(
  appBar: AppBar(title: Text('My App')),
  drawer: [...], // 导航项列表
  body: widget,  // 主体内容
)
```

### 旧API（已废弃，但仍支持）

```dart
MyScaffold(
  items: [...],  // 已废弃，请使用drawer
  pages: [...],  // 已废弃，请在body中处理页面切换
  body: widget,
)
```

## 特性说明

### 响应式布局

- **小屏幕 (< 600px)**：显示汉堡菜单或底部导航栏
- **中等屏幕 (600px - 840px)**：显示收缩的图标式侧边栏
- **大屏幕 (> 840px)**：显示完整的展开式侧边栏

### 自动适配

组件会根据屏幕尺寸自动选择最合适的导航模式，无需手动处理不同屏幕尺寸的适配逻辑。

### 平滑过渡

在不同布局模式之间切换时，组件提供平滑的动画过渡效果。

## 注意事项

1. **导航项数量**：建议导航项数量不超过7个，以保证良好的用户体验
2. **图标选择**：建议使用Material Design图标，确保在不同平台上的一致性
3. **标签文本**：保持标签文本简洁，避免过长的文本影响布局
4. **徽章使用**：徽章数量建议不超过99，超过时显示为"99+"
5. **向后兼容**：旧的`items`和`pages`参数仍然支持，但建议迁移到新API

## 迁移指南

如果你正在使用旧的API，可以按以下步骤迁移：

### 步骤1：替换参数名

```dart
// 旧代码
MyScaffold(
  items: [...],
  pages: [...],
)

// 新代码
MyScaffold(
  drawer: [...],
  body: YourBodyWidget(),
)
```

### 步骤2：处理页面切换

```dart
// 旧代码：pages参数自动处理页面切换
MyScaffold(
  items: items,
  pages: [Page1(), Page2(), Page3()],
)

// 新代码：在body中使用状态管理
class MyController extends GetxController {
  var currentIndex = 0.obs;
}

MyScaffold(
  drawer: [
    AdaptiveNavigationItem(
      icon: Icon(Icons.home),
      label: '首页',
      onTap: () => controller.currentIndex.value = 0,
    ),
    // ...
  ],
  body: Obx(() => pages[controller.currentIndex.value]),
)
```

这个自适应侧边栏为你的Flutter应用提供了专业级的导航体验，能够在不同设备上提供一致且优雅的用户界面。
