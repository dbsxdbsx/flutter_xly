# FloatPanel 使用指南

## 1. 简介（Introduction）

FloatPanel 是一个全局浮动面板组件，提供拖拽、贴边、展开/收起等交互功能。通过统一的全局管理器 FloatPanel.to，你可以在任意位置控制面板的显示、按钮、状态和样式。

特点：
- **统一初始化**：仅在 MyApp.initialize 中配置一次，全局生效
- **智能联动**：基于 id 的按钮状态自动联动，支持多入口导航一致性
- **私有渲染**：面板组件为库私有，确保一致的使用体验
- **悬停高亮**：默认红色悬停效果，可自定义
- **禁用样式定制**：支持多种禁用按钮的视觉样式

## 2. 基础用法

### 2.1 全局初始化（新方式）

在 MyApp.initialize 中传入 floatPanel 参数，使用 items 配置：

```dart
await MyApp.initialize(
  // ... 其他参数

  floatPanel: FloatPanel()
    ..configure(
      items: [
        FloatPanelIconBtn(
          icon: Icons.filter_1,
          id: 'page1', // 用于状态联动
          onTap: () => Get.toNamed('/page1'),
        ),
        FloatPanelIconBtn(
          icon: Icons.filter_2,
          id: 'page2',
          onTap: () => Get.toNamed('/page2'),
        ),
        FloatPanelIconBtn(
          icon: Icons.filter_3,
          id: 'page3',
          onTap: () => Get.toNamed('/page3'),
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
```

### 2.4 多选禁用与路由单选策略（重要）

从当前版本开始，FloatPanel 支持“多选禁用”能力（即可同时禁用多个带 id 的按钮），并在示例工程中采用“路由单选策略”：
- 切换页面时，先清空历史禁用集合，再仅禁用“当前页面”对应的按钮；
- 这样可以避免历史禁用状态残留，保证导航体验一致；
- 如果需要跨页面保留多选禁用，只需去掉清空集合的步骤即可。

示例中的全局路由回调（片段）：
```dart
if (current == id || current == '/$id') {
  fp.iconBtns.enableAll();       // 清理历史禁用
  fp.iconBtn(id).setEnabled(false); // 仅禁用当前页面对应按钮
  break;
}
```

### 2.2 状态联动（自动）

框架会自动监听路由变化，当路由与按钮的 id 匹配时，对应按钮会自动进入禁用/高亮状态：

```dart
// 无需额外代码，路由变化时自动联动
// 例如：导航到 '/page1' 时，id 为 'page1' 的按钮自动禁用
```

### 2.3 手动状态控制（可选）

如需在特定场景下手动控制状态：

```dart
// 设置禁用联动
FloatPanel.to.iconBtn('page1').setEnabled(false);

// 切换禁用联动（如果当前是page1则清空，否则设为page1）
FloatPanel.to.iconBtn('page1').toggleEnabled();

// 启用全部（清空禁用联动）
FloatPanel.to.iconBtns.enableAll();

```

## 3. API 参考

### 3.1 FloatPanel（全局管理器）

#### 静态访问
```dart
FloatPanel.to // 获取全局实例
```

#### 主要方法
```dart
// 配置面板内容
void configure({
  List<FloatPanelIconBtn>? items,
  bool? visible,
  // 新增可选配置（全部有默认值）
  Color? borderColor,           // 边框颜色，默认 Color(0xFF333333)
  IconData? initialPanelIcon,   // 初始手柄图标，默认 Icons.add
  int? panelAnimDuration,       // 展开收起动画时长(ms)，默认 600
  Curve? panelAnimCurve,        // 展开收起动画曲线，默认 Curves.fastLinearToSlowEaseIn
  int? dockAnimDuration,        // 贴边动画时长(ms)，默认 300
  Curve? dockAnimCurve,         // 贴边动画曲线，默认 Curves.fastLinearToSlowEaseIn
});

// 单个图标按钮控制（链式句柄）
FloatPanelIconBtnCtrl iconBtn(String id);

// 所有图标按钮集合控制（链式句柄）
FloatPanelIconBtnsCtrl get iconBtns;

// 便捷方法
bool isDisabled(String id);

// 显示控制
void show();
void hide();
void toggle();
```

### 3.2 FloatPanelIconBtnCtrl（单个按钮句柄）

```dart
// 设置启用状态
FloatPanelIconBtnCtrl setEnabled(bool value);

// 切换启用状态
FloatPanelIconBtnCtrl toggleEnabled();

// 查询当前是否启用
### 3.x 多选禁用API（新增）

新增 disabledIds 机制与相关 API：
```dart
// RxSet<String>：当前禁用联动的 id 集合
FloatPanel.to.disabledIds;
FloatPanel.to.disabledIdsRx;      // 监听集合变化

// 判断某个 id 是否被禁用
FloatPanel.to.isDisabled('page1');

// 集合级控制：启用全部（清空禁用集合）
FloatPanel.to.iconBtns.enableAll();

// 单个按钮链式控制：加入/移除禁用集合
FloatPanel.to.iconBtn('page1').setEnabled(false); // 加入禁用集合
FloatPanel.to.iconBtn('page1').setEnabled(true);  // 从禁用集合移除
```

bool get isEnabled;
```

### 3.3 FloatPanelIconBtnsCtrl（集合句柄）

```dart
// 启用全部（清空所有禁用联动）
void enableAll();

// 设置指定按钮的启用状态
void setEnabled(String id, bool value);

// 切换指定按钮的启用状态
void toggleEnabled(String id);
```

#### 样式属性（响应式）
```dart
final RxDouble panelWidth;           // 面板宽度
final Rx<Color> backgroundColor;     // 背景色
final Rx<PanelShape> panelShape;     // 形状：rectangle/rounded
final Rx<BorderRadius> borderRadius; // 圆角
final Rx<DockType> dockType;         // 停靠类型：inside/outside
final Rx<Color> panelButtonColor;    // 面板按钮颜色
final Rx<Color> customButtonColor;   // 自定义按钮颜色
final RxBool dockActivate;           // 是否启用停靠
final Rx<Color> handleFocusColor;    // 顶部handle按钮悬停色（默认蓝色）
final Rx<Color> focusColor;          // 其他功能按钮悬停色（默认红色）
final Rx<DisabledStyle> disabledStyle; // 禁用样式配置

// 新增可配置属性
final Rx<Color> borderColor;         // 边框颜色（默认 Color(0xFF333333)）
final Rx<IconData> initialPanelIcon; // 初始手柄图标（默认 Icons.add）
final RxInt panelAnimDuration;       // 展开收起动画时长（默认 600ms）
final Rx<Curve> panelAnimCurve;      // 展开收起动画曲线（默认 fastLinearToSlowEaseIn）
final RxInt dockAnimDuration;        // 贴边动画时长（默认 300ms）
final Rx<Curve> dockAnimCurve;       // 贴边动画曲线（默认 fastLinearToSlowEaseIn）
```

### 3.2 FloatPanelIconBtn

按钮定义模型：

```dart
class FloatPanelIconBtn {
  final IconData icon;        // 按钮图标
  final String? id;           // 联动标识（可选）
  final VoidCallback? onTap;  // 点击回调（可选）
  final String? tooltip;      // 工具提示（可选）
  final bool? disabled;       // 显式禁用（可选）

  const FloatPanelIconBtn({
    required this.icon,
    this.id,
    this.onTap,
    this.tooltip,
    this.disabled,
  });
}
```

### 3.3 联动规则

状态联动的核心规则：

- **仅声明了 `id` 的按钮参与联动**：未设置 `id` 的按钮完全不受状态变化影响
- **自动路由联动**：当路由变化时，框架自动检测当前路由是否与某个按钮的 `id` 匹配，匹配则自动调用 `iconBtn(id).setEnabled(false)`
- **手动联动**：任意位置可调用 `FloatPanel.to.iconBtn(id).setEnabled(false)` 设置当前禁用联动的 id
- **优先级**：显式设置的 `disabled: true` 优先于联动状态

```dart
// 示例：只有前两个按钮参与联动，第三个按钮独立
FloatPanel()..configure(items: [
  FloatPanelIconBtn(icon: Icons.home, id: 'home', onTap: () => Get.toNamed('/home')),
  FloatPanelIconBtn(icon: Icons.settings, id: 'settings', onTap: () => Get.toNamed('/settings')),
  FloatPanelIconBtn(icon: Icons.help, onTap: () => showHelpDialog()), // 无id，不参与联动
]);
```

### 3.4 DisabledStyle（禁用样式配置）

禁用按钮的视觉样式配置：

```dart
// 预定义样式
const DisabledStyle.defaultX()    // 默认：黄色X覆盖
const DisabledStyle.dimOnly()     // 仅变暗，无覆盖
DisabledStyle.custom(builder)     // 自定义覆盖Widget

// 使用示例
FloatPanel.to.disabledStyle.value = const DisabledStyle.defaultX();
FloatPanel.to.disabledStyle.value = const DisabledStyle.dimOnly();
FloatPanel.to.disabledStyle.value = DisabledStyle.custom((iconSize) {
  return Icon(Icons.warning_amber, color: Colors.redAccent, size: iconSize * 0.9);
});
```

## 4. 高级用法

### 4.1 动态样式调整

```dart
// 修改面板样式
FloatPanel.to.panelWidth.value = 80.0;
FloatPanel.to.backgroundColor.value = Colors.blue;
FloatPanel.to.handleFocusColor.value = Colors.cyan; // 顶部handle按钮悬停颜色
FloatPanel.to.focusColor.value = Colors.green; // 其他功能按钮悬停颜色

// 修改形状和停靠
FloatPanel.to.panelShape.value = PanelShape.rounded;
FloatPanel.to.dockType.value = DockType.inside;
```

### 4.2 禁用样式定制与即时更新

禁用样式支持即时切换，无需鼠标重新悬停即可看到变化：

```dart
// 恢复默认禁用样式（黄色X）
FloatPanel.to.disabledStyle.value = const DisabledStyle.defaultX();

// 仅变暗样式（无覆盖图标）
FloatPanel.to.disabledStyle.value = const DisabledStyle.dimOnly();

// 自定义覆盖样式
FloatPanel.to.disabledStyle.value = DisabledStyle.custom((iconSize) {
  return Container(
    width: iconSize,
    height: iconSize,
    decoration: BoxDecoration(
      color: Colors.red.withOpacity(0.8),
      shape: BoxShape.circle,
    ),
    child: Icon(Icons.block, color: Colors.white, size: iconSize * 0.6),
  );
});
```

**技术说明：** 禁用按钮会自动订阅 `disabledStyle` 的变化，样式切换后立即重新渲染，提供流畅的用户体验。

### 4.3 条件显示/隐藏

```dart
// 在某些页面隐藏面板
class SpecialPageController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    FloatPanel.to.hide(); // 隐藏全局面板
  }

  @override
  void onClose() {
    FloatPanel.to.show(); // 离开时恢复显示
    super.onClose();
  }
}
```

### 4.4 混合使用场景

结合自动联动和手动控制：

```dart
// 场景：导航按钮 + 功能按钮混合
FloatPanel()..configure(items: [
  // 导航按钮：参与自动联动
  FloatPanelIconBtn(icon: Icons.home, id: 'home', onTap: () => Get.toNamed('/home')),
  FloatPanelIconBtn(icon: Icons.settings, id: 'settings', onTap: () => Get.toNamed('/settings')),

  // 功能按钮：不参与联动，独立控制（示例：执行自定义逻辑）
  FloatPanelIconBtn(
    icon: Icons.refresh,
    onTap: () async {
      // TODO: 在此处执行你的刷新逻辑，例如调用控制器方法
      // await controller.refreshData();
      MyToast.showSuccess('刷新完成');
    },
### 5.3 批量禁用演示（Page11）

示例中提供了“禁用全部浮动面板按钮”的入口，用于演示多选禁用：
```dart
for (final item in FloatPanel.to.items) {
  final id = item.id;
  if (id != null) {
    FloatPanel.to.iconBtn(id).setEnabled(false);
  }
}
```
提示：切换到其他页面时，示例的路由回调会重置为“当前页单选禁用”，以保证一致导航体验。

  ),

  // 条件禁用按钮（示例：根据业务条件禁用）
  FloatPanelIconBtn(
    icon: Icons.upload,
    disabled: !hasDataToUpload, // 显式禁用优先于联动
    onTap: () {
      // TODO: 在此处执行你的上传逻辑，例如调用控制器方法
      // controller.uploadData();
      MyToast.showInfo('开始上传');
    },
  ),
]);
```

### 4.5 特殊状态处理

```dart
// 在某些业务场景下手动控制状态
class BusinessController extends GetxController {
  void onSpecialAction() {
    // 临时启用全部（清空所有禁用联动）
    FloatPanel.to.iconBtns.enableAll();

    // 执行业务逻辑
    performCriticalOperation();

    // 恢复当前页面状态
    final currentRoute = Get.currentRoute;
    if (currentRoute == '/home') {
      FloatPanel.to.iconBtn('home').setEnabled(false);
    }
  }
}
```

## 5. 实际应用示例

### 5.1 页面导航面板（新方式）

```dart
// 全局初始化：三个页面导航，自动联动
floatPanel: FloatPanel()
  ..configure(
    items: [
      FloatPanelIconBtn(
        icon: Icons.filter_1,
        id: 'page1', // 与路由 '/page1' 自动匹配
        onTap: () => Get.toNamed('/page1'),
      ),
      FloatPanelIconBtn(
        icon: Icons.filter_2,
        id: 'page2',
        onTap: () => Get.toNamed('/page2'),
      ),
      FloatPanelIconBtn(
        icon: Icons.filter_3,
        id: 'page3',
        onTap: () => Get.toNamed('/page3'),
      ),
    ],
  ),

// 页面控制器：无需额外配置，自动联动
class Page2Controller extends GetxController {
  @override
  void onReady() {
    super.onReady();
    // 框架会自动检测路由变化并设置对应按钮为禁用状态
    // 无需手动配置 buttonStateProvider
  }
}
```

### 5.2 样式切换演示页

```dart
class StyleDemoController extends GetxController {
  // 禁用样式切换
  void switchToDefaultStyle() {
    FloatPanel.to.disabledStyle.value = const DisabledStyle.defaultX();
    MyToast.showSuccess('已切换为默认禁用样式：黄色X');
  }

  void switchToDimStyle() {
    FloatPanel.to.disabledStyle.value = const DisabledStyle.dimOnly();
    MyToast.showSuccess('已切换为仅变暗禁用样式');
  }

  void switchToCustomStyle() {
    FloatPanel.to.disabledStyle.value = DisabledStyle.custom((iconSize) {
      return Icon(Icons.warning_amber, color: Colors.redAccent, size: iconSize * 0.9);
    });
    MyToast.showSuccess('已切换为自定义禁用样式：红色警告');
  }
}
```

## 6. 注意事项

### 6.1 使用约束
- **唯一初始化**：只能在 MyApp.initialize 中初始化，不支持页面内直接创建面板组件
- **全局单例**：FloatPanel.to 为全局单例，所有页面共享同一个实例
- **自动联动**：框架会自动处理路由变化的状态联动，无需手动配置

### 6.2 性能建议
- 避免在 build 方法中调用 FloatPanel.to.configure
- 自定义禁用样式时，避免复杂的 Widget 构建
- 大量按钮时，合理使用 id 以避免不必要的状态计算

### 6.3 ID 命名建议
- 使用简洁明确的 id：'home', 'settings', 'profile'
- 与路由名保持一致：id='page1' 对应路由 '/page1'
- 避免使用特殊字符和空格

### 6.4 层级说明
- 面板渲染在页面内容之上，但在 splash 启动屏之下
- 不会被页面内容遮挡，始终保持在顶层可见

## 7. 最佳实践

1. 仅为需要联动的按钮设置 id，其它按钮保持独立（不设置 id）
2. id 命名与路由保持一致，便于自动联动
3. 在复杂业务场景中，优先使用 `FloatPanel.to.iconBtn(id).setEnabled(false)` 进行显式联动
4. 自定义禁用样式时，保持渲染简单，避免过度堆叠导致性能问题

## 8. 常见问题

**Q: 按钮状态不联动？**
A: 检查按钮是否设置了 `id`，且 `id` 与当前路由匹配（如 id='page1' 对应路由 '/page1'）。

**Q: 如何让某个按钮不参与联动？**
A: 不为该按钮设置 `id` 即可，它将保持独立状态。

**Q: 如何手动控制按钮状态？**
A: 使用 `FloatPanel.to.iconBtn('id').setEnabled(false)` 禁用或 `FloatPanel.to.iconBtns.enableAll()` 启用全部。

**Q: 禁用样式不生效？**
A: 确保按钮处于禁用状态（当前活跃或显式 disabled: true），并检查 disabledStyle 配置。

**Q: 如何修改悬停时的高亮颜色？**
A: 顶部handle按钮使用 `FloatPanel.to.handleFocusColor.value = Colors.yourColor`，其他功能按钮使用 `FloatPanel.to.focusColor.value = Colors.yourColor`。

**Q: 如何自定义禁用按钮的外观？**
A: 使用 `FloatPanel.to.disabledStyle.value = DisabledStyle.custom(builder)` 设置自定义覆盖Widget。

**Q: 面板在某些页面不显示？**
A: 检查是否调用了 `FloatPanel.to.hide()`，使用 `FloatPanel.to.show()` 恢复显示。

**Q: 可以在页面内创建独立的浮动面板吗？**
A: 不可以。面板组件为库私有，只能通过全局管理器使用，确保一致的用户体验。

**Q: 禁用样式会影响性能吗？**
A: 预定义样式（defaultX、dimOnly）性能开销很小。自定义样式的性能取决于 builder 函数的复杂度，建议避免复杂的 Widget 构建。
