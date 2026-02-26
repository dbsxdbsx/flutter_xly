# MySelector 选择器使用指南

## 1. 简介

`MySelector` 是一个浮层式下拉选择器，在触发 Widget 附近弹出半透明毛玻璃面板，支持搜索、清除、自定义渲染、键盘导航等能力。

提供两种使用模式：

| 模式 | 适用场景 | 核心 API |
|------|---------|---------|
| **Controller 模式** | 同页面多个选择器、需要外部操控状态 | `MySelectorController<T>` |
| **命令式模式** | 一次性弹出、无需持久化状态 | `MySelector.show<T>(...)` |

---

## 2. Controller 模式（推荐）

### 2.1 声明 Controller

在 `GetxController` 或 `State` 的 `onInit` / `initState` 中初始化：

```dart
class MyPageController extends GetxController {
  late final MySelectorController<String> colorCtrl;

  @override
  void onInit() {
    super.onInit();
    colorCtrl = MySelectorController<String>(
      items: [
        MySelectorItem(value: 'red',   title: '红色'),
        MySelectorItem(value: 'green', title: '绿色'),
        MySelectorItem(value: 'blue',  title: '蓝色'),
      ],
      clearOption: MySelectorClearOption(label: '不选颜色'),
      onChanged: (item) => debugPrint('选中: ${item?.title}'),
    );
  }
}
```

### 2.2 在 UI 中使用

触发按钮与选中状态显示，配合 `Obx` 自动响应变化：

```dart
Builder(builder: (ctx) {
  return Obx(() => MyButton(
    text: controller.colorCtrl.selectedTitle ?? '选择颜色',
    onPressed: () => controller.colorCtrl.show(ctx),
  ));
})
```

> **为什么需要 `Builder`？**
> `show()` 需要触发按钮的 `BuildContext` 来定位浮层。`Builder` 提供一个属于该按钮所在位置的 context，确保浮层弹在按钮附近。

### 2.3 从外部修改选中状态

Controller 持有状态，可以从任意位置直接操控：

```dart
// 按 value 设置（自动查找对应 item）
colorCtrl.setValue('blue');

// 按完整 item 设置
colorCtrl.setItem(someItem);

// 清除
colorCtrl.clear();

// 读取当前状态
colorCtrl.selectedItem;   // MySelectorItem<T>?
colorCtrl.selectedValue;  // T?
colorCtrl.selectedTitle;  // String?
```

### 2.4 监听变化

两种方式，按场景选择：

```dart
// 方式一：onChanged 回调（在 Controller 构造时传入）
colorCtrl = MySelectorController<String>(
  items: [...],
  onChanged: (item) {
    if (item == null) {
      debugPrint('已清除');
    } else {
      debugPrint('选中: ${item.title}');
    }
  },
);

// 方式二：在 UI 中用 Obx 响应式读取
Obx(() => Text(controller.colorCtrl.selectedTitle ?? '未选'))
```

---

## 3. 命令式模式（底层 API）

适合临时弹出、不需要持久化状态的场景，直接 `await` 等待用户操作结果：

```dart
Future<void> showColorOnce(BuildContext ctx) async {
  final result = await MySelector.show<String>(
    triggerContext: ctx,
    items: [
      MySelectorItem(value: 'red',  title: '红色'),
      MySelectorItem(value: 'blue', title: '蓝色'),
    ],
  );

  // 便捷写法：result.changed 为 null 表示用户点外部关闭（未做选择）
  final changed = result.changed;
  if (changed != null) {
    final selectedValue = changed.value;  // T? （null = 清除）
    final selectedItem  = changed.item;   // MySelectorItem<T>?
    debugPrint('结果: $selectedValue');
  }
}
```

完整 `switch` 写法（适合需要区分所有状态的场景）：

```dart
switch (result) {
  case MySelectorDismissed():
    break; // 用户点外部或按 Escape，不做任何操作
  case MySelectorValueChanged(:final value, :final item):
    if (value == null) {
      // 用户主动清除
    } else {
      // 用户选中了 item
    }
}
```

---

## 4. 常用配置

### 4.1 搜索框

```dart
MySelectorController<String>(
  items: items,
  showSearch: true,
  searchHint: '搜索模型…',
  // 可选：自定义搜索逻辑（默认按 title/subtitle 模糊匹配）
  searchFilter: (item, query) => item.title.contains(query),
)
```

### 4.2 清除项（顶部"取消选择"入口）

```dart
MySelectorController<String>(
  items: items,
  clearOption: MySelectorClearOption(
    label: '不限国家',
    leading: Icon(Icons.public_off_outlined, size: 14),
    subtitle: '显示所有地区内容',
  ),
)
```

### 4.3 复选取消（再次点击已选项即取消）

```dart
MySelectorController<String>(
  items: items,
  allowReselect: true,  // 点击已选项 → 等同于清除
)
```

### 4.4 底部自定义区域

```dart
MySelectorController<String>(
  items: items,
  footerBuilder: (context, dismiss) => InkWell(
    onTap: () {
      dismiss(); // 关闭面板
      // ... 执行自定义操作
    },
    child: Padding(
      padding: EdgeInsets.all(12),
      child: Row(children: [
        Icon(Icons.add),
        SizedBox(width: 8),
        Text('添加更多选项'),
      ]),
    ),
  ),
)
```

### 4.5 自定义 Item 渲染

```dart
MySelectorController<int>(
  items: items,
  itemBuilder: (context, item, isSelected) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
      child: Row(children: [
        Text(item.title, style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        )),
        if (isSelected) Icon(Icons.check, color: Colors.blue),
      ]),
    );
  },
)
```

---

## 5. 列表项（MySelectorItem）

```dart
MySelectorItem<T>(
  value: 'key',        // 必填，T 类型，需正确实现 ==
  title: '显示名称',    // 必填
  subtitle: '副标题',   // 可选
  leading: Icon(...),  // 可选，左侧图标/头像/色块等
  badges: [...],       // 可选，标题右侧小徽章列表
  enabled: true,       // 可选，false = 禁用（灰色，不可点击）
)
```

---

## 6. 样式配置（MySelectorStyle）

```dart
MySelectorStyle(
  maxHeight: 360,           // 面板最大高度（设计稿像素，自动 .h 转换）
  panelWidth: 280,          // 面板宽度（不传则与触发按钮同宽，最小 220）
  borderRadius: 14,         // 圆角
  blurSigma: 28,            // 毛玻璃模糊强度
  selectedColor: Color(0xFF4F6BFE), // 选中色（指示条、文字、勾）
  shadowOpacity: 0.12,      // 投影透明度
  hoverColor: Color(0x0F000000),    // 鼠标悬停背景色
)
```

---

## 7. 弹出方向控制

```dart
MySelectorController<String>(
  items: items,
  showPanelAbove: true,   // 强制弹到触发按钮上方
  // showPanelAbove: false, // 强制弹到下方
  // showPanelAbove: null,  // 默认：根据可用空间自动判断
)
```

---

## 8. 键盘支持

面板弹出后自动支持：

| 按键 | 行为 |
|------|------|
| `↑` / `↓` | 高亮导航（从清除项开始） |
| `Enter` | 确认当前高亮项 |
| `Escape` | 关闭面板（等同于点外部，触发 `MySelectorDismissed`） |

开启搜索框时，面板弹出后自动聚焦搜索框，可直接键入过滤。
