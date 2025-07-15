# Flutter自适应侧边栏实现指南

## 概述

本文档详细介绍如何在Flutter项目中实现一个优雅的自适应侧边栏组件，该组件能够根据屏幕尺寸自动切换显示模式：
- **小屏幕**：传统抽屉式导航（汉堡菜单）
- **中等屏幕**：收缩的图标式侧边栏
- **大屏幕**：完整的展开式侧边栏（含文字标签和额外内容）

## 核心依赖

首先在 `pubspec.yaml` 中添加必要的依赖：

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_adaptive_scaffold: ^0.1.7+1  # 核心自适应布局包
  fluentui_system_icons: ^1.1.221      # 图标库（可选）
  hooks_riverpod: ^2.4.9               # 状态管理（可选）
```

## 实现步骤

### 1. 创建自适应根脚手架

创建 `lib/widgets/adaptive_root_scaffold.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';

class AdaptiveRootScaffold extends StatelessWidget {
  const AdaptiveRootScaffold({
    super.key,
    required this.body,
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.sidebarTrailing,
  });

  final Widget body;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final Widget? sidebarTrailing;

  @override
  Widget build(BuildContext context) {
    // 定义导航目的地
    final destinations = [
      const NavigationDestination(
        icon: Icon(Icons.home),
        label: 'Home',
      ),
      const NavigationDestination(
        icon: Icon(Icons.settings),
        label: 'Settings',
      ),
      const NavigationDestination(
        icon: Icon(Icons.info),
        label: 'About',
      ),
    ];

    return _CustomAdaptiveScaffold(
      selectedIndex: selectedIndex,
      onSelectedIndexChange: onDestinationSelected ?? (_) {},
      destinations: destinations,
      sidebarTrailing: sidebarTrailing,
      body: body,
    );
  }
}
```

### 2. 实现核心自适应逻辑

继续在同一文件中添加：

```dart
class _CustomAdaptiveScaffold extends StatelessWidget {
  const _CustomAdaptiveScaffold({
    required this.selectedIndex,
    required this.onSelectedIndexChange,
    required this.destinations,
    required this.body,
    this.sidebarTrailing,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelectedIndexChange;
  final List<NavigationDestination> destinations;
  final Widget body;
  final Widget? sidebarTrailing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 小屏幕时显示抽屉
      drawer: Breakpoints.small.isActive(context)
          ? Drawer(
              width: (MediaQuery.sizeOf(context).width * 0.88).clamp(200.0, 304.0),
              child: NavigationRail(
                extended: true,
                selectedIndex: selectedIndex,
                destinations: destinations
                    .map((dest) => AdaptiveScaffold.toRailDestination(dest))
                    .toList(),
                onDestinationSelected: (index) {
                  Navigator.of(context).pop(); // 关闭抽屉
                  onSelectedIndexChange(index);
                },
              ),
            )
          : null,

      // 中大屏幕的自适应布局
      body: AdaptiveLayout(
        primaryNavigation: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig>{
            // 中等屏幕：收缩的侧边栏（仅图标）
            Breakpoints.medium: SlotLayout.from(
              key: const Key('primaryNavigation'),
              builder: (_) => AdaptiveScaffold.standardNavigationRail(
                selectedIndex: selectedIndex,
                destinations: destinations
                    .map((dest) => AdaptiveScaffold.toRailDestination(dest))
                    .toList(),
                onDestinationSelected: onSelectedIndexChange,
              ),
            ),
            // 大屏幕：展开的侧边栏（图标+文字+额外内容）
            Breakpoints.large: SlotLayout.from(
              key: const Key('primaryNavigationLarge'),
              builder: (_) => AdaptiveScaffold.standardNavigationRail(
                extended: true,
                selectedIndex: selectedIndex,
                destinations: destinations
                    .map((dest) => AdaptiveScaffold.toRailDestination(dest))
                    .toList(),
                onDestinationSelected: onSelectedIndexChange,
                trailing: sidebarTrailing, // 底部额外内容
              ),
            ),
          },
        ),
        body: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig>{
            Breakpoints.standard: SlotLayout.from(
              key: const Key('body'),
              builder: (context) => body,
            ),
          },
        ),
      ),
    );
  }
}
```

### 3. 创建侧边栏底部组件（可选）

创建 `lib/widgets/sidebar_bottom_content.dart`：

```dart
import 'package:flutter/material.dart';

class SidebarBottomContent extends StatefulWidget {
  const SidebarBottomContent({super.key});

  @override
  State<SidebarBottomContent> createState() => _SidebarBottomContentState();
}

class _SidebarBottomContentState extends State<SidebarBottomContent> {
  bool _showMore = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 展开/收缩按钮
          TextButton.icon(
            onPressed: () => setState(() => _showMore = !_showMore),
            icon: AnimatedRotation(
              turns: _showMore ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.expand_more),
            ),
            label: Text(_showMore ? 'Show Less' : 'Show More'),
          ),

          // 连接状态卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Connection', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.circle, color: Colors.green, size: 12),
                      const SizedBox(width: 8),
                      const Text('Connected'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 可展开的详细信息
          AnimatedCrossFade(
            crossFadeState: _showMore
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Traffic', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('↑ Upload:'),
                            const Text('1.2 MB/s'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('↓ Download:'),
                            const Text('5.8 MB/s'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### 4. 使用示例

在你的主页面中使用：

```dart
import 'package:flutter/material.dart';
import 'widgets/adaptive_root_scaffold.dart';
import 'widgets/sidebar_bottom_content.dart';

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const Center(child: Text('Home Page')),
    const Center(child: Text('Settings Page')),
    const Center(child: Text('About Page')),
  ];

  @override
  Widget build(BuildContext context) {
    return AdaptiveRootScaffold(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
      },
      sidebarTrailing: const Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SidebarBottomContent(),
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
}
```

## 断点说明

`flutter_adaptive_scaffold` 使用以下默认断点：

- **Breakpoints.small**: 宽度 < 600px（手机）
- **Breakpoints.medium**: 600px ≤ 宽度 < 840px（平板竖屏）
- **Breakpoints.large**: 宽度 ≥ 840px（平板横屏、桌面）

## 自定义断点

如需自定义断点，可以这样做：

```dart
// 自定义断点
final customBreakpoint = Breakpoint(
  beginWidth: 1200,
  endWidth: double.infinity,
);

// 在SlotLayout中使用
SlotLayout(
  config: <Breakpoint, SlotLayoutConfig>{
    customBreakpoint: SlotLayout.from(
      builder: (_) => YourCustomWidget(),
    ),
  },
)
```

## 注意事项

1. **性能优化**：大量导航项时考虑懒加载
2. **无障碍支持**：为所有导航项添加语义标签
3. **主题适配**：确保在不同主题下的视觉一致性
4. **状态管理**：复杂应用建议使用Riverpod或Bloc管理状态
5. **测试**：为不同屏幕尺寸编写响应式测试

## 高级功能扩展

### 1. 添加用户头像区域

```dart
class SidebarHeader extends StatelessWidget {
  const SidebarHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage('https://example.com/avatar.jpg'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('用户名', style: Theme.of(context).textTheme.titleSmall),
                Text('user@example.com',
                     style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### 2. 支持通知徽章

```dart
class BadgedNavigationDestination extends NavigationDestination {
  const BadgedNavigationDestination({
    required super.icon,
    required super.label,
    this.badgeCount = 0,
  });

  final int badgeCount;

  @override
  Widget get icon => Badge(
    isLabelVisible: badgeCount > 0,
    label: Text('$badgeCount'),
    child: super.icon,
  );
}
```

### 3. 响应式测试

```dart
// test/adaptive_sidebar_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdaptiveRootScaffold Tests', () {
    testWidgets('shows drawer on small screen', (tester) async {
      // 设置小屏幕尺寸
      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveRootScaffold(
            body: Container(),
          ),
        ),
      );

      // 验证抽屉存在
      expect(find.byType(Drawer), findsOneWidget);
    });

    testWidgets('shows sidebar on large screen', (tester) async {
      // 设置大屏幕尺寸
      tester.binding.window.physicalSizeTestValue = const Size(1200, 800);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveRootScaffold(
            body: Container(),
          ),
        ),
      );

      // 验证NavigationRail存在
      expect(find.byType(NavigationRail), findsOneWidget);
    });
  });
}
```

## 性能优化建议

### 1. 懒加载导航项

```dart
class LazyNavigationRail extends StatelessWidget {
  final List<NavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;

  const LazyNavigationRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: destinations.length,
      itemBuilder: (context, index) {
        final destination = destinations[index];
        final isSelected = index == selectedIndex;

        return ListTile(
          leading: destination.icon,
          title: Text(destination.label),
          selected: isSelected,
          onTap: () => onDestinationSelected?.call(index),
        );
      },
    );
  }
}
```

### 2. 状态缓存

```dart
class CachedAdaptiveScaffold extends StatefulWidget {
  // ... 其他属性

  @override
  State<CachedAdaptiveScaffold> createState() => _CachedAdaptiveScaffoldState();
}

class _CachedAdaptiveScaffoldState extends State<CachedAdaptiveScaffold>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用
    // ... 构建逻辑
  }
}
```

## 主题定制

### 1. 自定义导航栏主题

```dart
class ThemedAdaptiveScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: Colors.grey[100],
          selectedIconTheme: IconThemeData(color: Colors.blue),
          unselectedIconTheme: IconThemeData(color: Colors.grey),
          selectedLabelTextStyle: TextStyle(color: Colors.blue),
          unselectedLabelTextStyle: TextStyle(color: Colors.grey),
        ),
      ),
      child: AdaptiveRootScaffold(
        // ... 其他属性
      ),
    );
  }
}
```

### 2. 深色模式适配

```dart
NavigationRailThemeData _getNavigationRailTheme(bool isDark) {
  return NavigationRailThemeData(
    backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
    selectedIconTheme: IconThemeData(
      color: isDark ? Colors.lightBlue : Colors.blue,
    ),
    unselectedIconTheme: IconThemeData(
      color: isDark ? Colors.grey[400] : Colors.grey[600],
    ),
  );
}
```

## 常见问题解决

### 1. 状态不同步
确保在切换导航时正确更新selectedIndex：

```dart
void _onDestinationSelected(int index) {
  setState(() {
    _selectedIndex = index;
  });
  // 如果使用路由，同时更新路由
  context.go('/page$index');
}
```

### 2. 动画卡顿
使用RepaintBoundary优化重绘：

```dart
RepaintBoundary(
  child: AdaptiveLayout(
    // ... 布局配置
  ),
)
```

### 3. 内存泄漏
及时释放资源：

```dart
@override
void dispose() {
  _controller?.dispose();
  super.dispose();
}
```

## 总结

通过以上完整的实现指南，你可以：

1. **快速搭建**：使用基础代码快速实现自适应侧边栏
2. **深度定制**：根据需求添加高级功能和主题
3. **性能优化**：应用最佳实践确保流畅体验
4. **测试保障**：编写完整的测试用例
5. **问题解决**：参考常见问题的解决方案

这个自适应侧边栏组件将为你的Flutter应用提供专业级的导航体验！
