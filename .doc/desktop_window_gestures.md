# 桌面端窗口拖拽与双击最大化

`MyApp` 在无系统标题栏时，用一层盖住整窗的手势来做两件事：拖动窗口、双击空白处最大化。这两件事必须和页面里的按钮、输入框共存，否则连点加减、双击选词都会被窗口层吃掉。

## 为什么不能在外层挂 `onDoubleTap`

`GestureDetector.onDoubleTap` 会注册 `DoubleTapGestureRecognizer`。它进入**每一次点击**的手势竞技场，并在首次抬手时 hold：

- 单击要等约 `kDoubleTapTimeout`（300ms）才落地
- 双击时内层 `onTap` / `onTapDown` 可能触发 0 次
- 连点 `MySpinBox` 加减、双击 `TextField` 选词，都会变成窗口最大化

空回调 `onDoubleTap: () {}` 同样会注册识别器，不能用来「只挡窗口、不挡内容」。

## 现行做法

```text
Listener（只观察指针，不进竞技场）
  └── RawGestureDetector + MyWindowDragGestureRecognizer（仅桌面拖窗）
        └── 页面内容
```

1. **双击判定只在 Listener 层做**，用两次鼠标 DOWN/UP 的时间与距离，对照 `kDoubleTapTimeout` / `kDoubleTapSlop`。
2. 第二次 DOWN 时立刻 `classifyDesktopHit`，避免内层回调改树后，UP 时把交互区误判成空白。
3. 分类结果：

| 命中 | 含义 | 窗口最大化 |
|------|------|------------|
| `editable` | `RenderEditable`（`TextField` / `MyTextEditor` / `MySpinBox` 数字区） | 否，留给选词 / 获焦 |
| `interactive` | 带 tap 语义的 `GestureDetector` / `InkWell`，或 `MyDoubleClickConsumeZone` | 否，连点留给控件 |
| `background` | 空白、只有滚动/拖拽语义的区域 | 是 |

`Scrollable` 也会挂 `RenderSemanticsGestureHandler`，但 `onTap == null`，仍算空白——列表空隙可以双击最大化。

## 硬约束

改桌面端点击或窗口交互时：

1. `CustomDragArea` **永远不得**注册 `DoubleTapGestureRecognizer`（包括空回调）。
2. 整窗拖拽必须用 `MyWindowDragGestureRecognizer`（鼠标 12px 阈值 + `onlyAcceptDragOnThreshold`），不得退回裸 `PanGestureRecognizer`。鼠标默认 slop 只有 2px，手抖会触发 `startDragging()`，这一击的 UP 不再回到 Flutter，双击最大化会彻底失效。
3. 疑似第二击时不得启动窗口拖拽（`_isSuspectedSecondTap`）。
4. 不要把「所有 `Listener`」都当成交互区：窗口层自己就是 `Listener`，那样整窗都无法最大化。

## 什么时候需要 `MyDoubleClickConsumeZone`

自动检测已覆盖：

- `GestureDetector` / `InkWell` / `ElevatedButton` 等带 `onTap` 或 `onTapDown` 的控件
- `TextField` 等 `RenderEditable`
- `MySpinBox`、`MyTextEditor`（整控件额外标了消费区，连装饰边框也不穿透）

只在自动检测覆盖不到时才包一层，例如**只用 `Listener` 处理指针、没有 tap 语义**的自定义控件：

```dart
MyDoubleClickConsumeZone(
  child: Listener(
    onPointerDown: (_) { /* 业务点击 */ },
    child: const CustomKnob(),
  ),
)
```

不要把整页包进消费区，否则空白处也无法双击最大化。

也不要把整页包进 `GestureDetector(onTap: …)` 或 `GestureDetector(onSecondaryTapDown: …)`：Flutter 只要存在 `TapGestureRecognizer` 就会填上 tap 语义，分类会把整页当成交互区。右键菜单请用 `showRightMenu`（内部是 `Listener`，不进 tap 语义）。

子组件自己要拖拽（长按排序、`Draggable`、自绘滑块等）时，用 `MyWindowDragExcludeZone`（或等价的 `MyDragProtectedArea`）包住它：在区内按下的 pointer，窗口拖拽识别器在 `isPointerAllowed` 就拒绝追踪，子组件独自走竞技场。它不改全局开关、不触发重建，也不管双击分类。可拖 `MyCard` 已自动套上。

为什么不能靠「谁先过阈值」：窗口层鼠标 12px 就认，`ReorderableDelayedDragStartListener` 要等约 500ms，用户按住就拖时窗口层必赢。`ReorderableDragStartListener`（立即拖的手柄）1px 就认，本来就不会漏。

可拖 `MyCard` 按下时按 pointer 种类挑识别器：鼠标（触控板按下拖动也按 mouse 上报）用 `ImmediateMultiDragGestureRecognizer`，按下即拖；触屏、触控笔仍用长按约 500ms 的识别器，时限内滑开只算滚动。鼠标拖不动列表（桌面默认 `ScrollBehavior.dragDevices` 不含 mouse），所以按下即拖不会和滚动抢。两种情况都套着排除区，拖卡片不会搬窗口。

`CustomDragArea` 在桌面端恒挂 `RawGestureDetector`，`draggable` 只在识别器内部判断。不要再按开关增删这一层：`Listener` 的 child 类型一变，整棵 App 子树（含 Navigator）会卸载重挂。

## 相关测试

- `test/desktop_window_gestures_test.dart` — 命中分类、连点不最大化、单击零延迟
- `test/window_drag_gesture_recognizer_test.dart` — 鼠标手抖不触发拖窗
- `test/window_drag_reorder_conflict_test.dart` — 可拖卡片不漏成拖窗、鼠标按下即拖 / 触屏仍长按、单击仍触发 `onPressed`、标题栏仍可拖、开关不重挂子树
