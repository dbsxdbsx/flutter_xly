# MyToast.showScrim 作用域遮罩使用指南

## 概述

作用域遮罩（Scrim）是 Toast 家族中唯一的**阻塞型**成员：在异步任务执行期间，用半透明遮罩锁住一块表面的交互，提供进度反馈和取消入口，需手动关闭。

与普通 Toast 的语义对比：

| | 普通 Toast | Scrim |
|---|---|---|
| 生命周期 | 瞬时，自动消失 | 持续，`hideScrim()` 手动关闭 |
| 交互 | 非阻塞，不可交互 | 阻塞所属表面，可带取消按钮 |
| 覆盖范围 | 浮在最顶层 | 只盖住"最近的表面" |
| 用途 | 通知结果 | 锁定进行中的操作 |

## 核心设计：宿主模式（Host）

遮罩不是全屏浮层，而是由 `MyScrimHost` 宿主在**自己的表面内**渲染：

- 谁包了宿主，遮罩就正好盖住谁，随宿主形状裁剪（圆角天然正确）、随宿主销毁自动消失；
- 宿主按挂载顺序登记成栈，**最上层表面 = 栈尾**，因此不传 context 就能"只遮住上一级"，无需几何嗅探。

内置宿主（业务方通常不用手写）：

| 宿主位置 | 效果 |
|---|---|
| `MyDialogSheet.showCenter` | 遮罩盖住整个中心对话框表面 |
| `MyDialogSheet.showBottom` | 遮罩盖住底部 Sheet（含顶部圆角裁剪） |
| `MyApp` 根节点（`useToast` 时） | 兜底：无对话框时全屏遮罩；Toast 通知层始终在遮罩之上 |

自定义表面也可手动包裹：`MyScrimHost(child: yourSurface)`。

## 基础用法

```dart
// 显示：默认卡片 = 转圈 + 主消息 + 细节行 + 可选取消按钮
MyToast.showScrim(
  message: '处理中...',
  detail: '0/16',
  onCancel: () {          // 非空才显示取消按钮
    cancelTask();
    MyToast.hideScrim();
  },
);

// 任务推进时刷新文案
MyToast.updateScrim(detail: '3/16');

// 结束（务必放 finally，防泄漏）
MyToast.hideScrim();
```

## 完全自定义中央内容

`builder` 非空时接管中央卡片（居中与遮罩底色仍由宿主负责），此时
`message` / `detail` / `onCancel` 失效，内容刷新用自己的响应式状态驱动：

```dart
MyToast.showScrim(
  builder: (_) => Obx(() => MyProgressCard(
        title: '智选中...',
        progress: '${done.value}/${total.value}',
        onCancel: cancel,
      )),
);
```

## 定位规则

```dart
MyToast.showScrim(...)                  // 自动落在最上层宿主（最近挂载的表面）
MyToast.showScrim(context: context, ...) // 精确落在 context 最近的祖先宿主
```

`updateScrim` / `hideScrim` 作用于当前正在显示遮罩的最上层宿主；无遮罩时静默忽略。

## 深色卡片按钮样式：scrimButtonStyle

Material `TextButton` 默认 hover overlay 只有前景色 8% 透明度，在深色遮罩卡片上几乎不可见。`scrimButtonStyle()` 提供高对比版本（悬停/按下/聚焦时前景变纯白 + 白色半透明药丸底），默认取消按钮已启用，自定义卡片可复用：

```dart
TextButton(
  style: scrimButtonStyle(idleForeground: Colors.white60),
  onPressed: cancel,
  child: const Text('取消'),  // 不要显式指定颜色，否则悬停不变亮
)
```

## 实现要点与坑

- **防溢出**：中央卡片包在 `FittedBox(fit: scaleDown)` 里，宿主表面比卡片小时自动等比缩小，不会像素溢出。
- **边缘细边**：对话框表面采用"白底矩形 + 遮罩 + 内容合成单图层，再 `Clip.antiAliasWithSaveLayer` 一次裁圆角"。若自建宿主时在遮罩上再叠圆角/多层背景，同一边缘会被抗锯齿混合多次，在深色 barrier 上析出浅色细边。
- **对话框被外点关闭**：barrier 点击会 pop 对话框、宿主随之销毁，遮罩自动消失；任务侧需自行监听 pop（如 `PopScope`）取消任务。
- **演示**：`example` Page3「MyToast.showScrim - 作用域遮罩」三个入口（对话框内 / 底部 Sheet 内 / 全屏兜底）。

## 相关文件

- `lib/src/toast/scrim_host.dart` — `MyScrimHost` / `scrimButtonStyle` / 默认卡片
- `lib/src/toast/toast.dart` — `MyToast.showScrim` / `updateScrim` / `hideScrim` 门面
- `lib/src/dialogue/dialog_sheet.dart` — 对话框 / 底部 Sheet 的内置宿主与单图层表面
- `test/scrim_host_test.dart` — 宿主解析、取消回调、小表面缩放、对话框集成回归
