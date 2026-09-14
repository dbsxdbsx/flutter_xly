# 桌面窗口启动：显隐、首帧出示、任务栏

> **面向对象**：xly 维护者与消费应用  
> **目的**：把「启动后窗口在不在」「第几帧才 show」「窗口可见时要不要任务栏」拆开  
> **相关**：`lib/src/app/desktop_window_launch.dart`、`MyApp.initialize`、`MyTray`、[splash_mechanism.md](splash_mechanism.md)

## 三件正交的事

| 策略 | 参数 | 默认 |
|---|---|---|
| 启动后窗口在不在 | `showWindowOnInit` | `true`（显示） |
| 若要显示，是否等 Flutter 首帧 | `deferShowUntilFirstFrame` | `null`：有 `splash` 则等首帧，否则立即显示 |
| 窗口可见时是否占任务栏 / Alt+Tab | `MyTray.hideTaskBarIcon`（无托盘时才看 `setSkipTaskbar`） | `false`（占任务栏） |

`showWindowOnInit: false` **不会**在首帧后再自动 `show()`。那是 `0.56` 叠层门闩误把防闪绑到这个开关上的旧行为，已拆开。

Windows 上任务栏按钮与 Alt+Tab 对普通顶层窗口绑死：藏任务栏 = 同时离开切换器。

## 合法组合

```text
showWindowOnInit: true                         → 默认 GUI，初始化阶段 show
showWindowOnInit: true + splash                → 等首帧再 show（防空窗）
showWindowOnInit: true, defer: true            → 无叠层也等首帧
showWindowOnInit: false + tray                 → 静默驻留，点托盘再 pop()
showWindowOnInit: false, 业务再 windowManager.show()  → 例如首次设置向导
```

关闭回托盘（`closeToTray`）、点托盘切换（`toggleOnClick`）是窗口起来之后的事，不改变启动策略。

## Windows 原生闪现

Flutter Windows runner 默认在首帧回调里 `this->Show()`。要让 Dart 真正管可见性：

```bash
dart run xly:win_setup
```

静默驻留：补丁 + `showWindowOnInit: false`。  
无空窗的正式 GUI：补丁 + `showWindowOnInit: true`（有 `splash` 时 defer 默认开）。

## 托盘状态

静默启动后若只藏窗、不走 `MyTray.hide()`，`isVisible` 仍默认 `true`，第一次点托盘会再 `hide()` 一次。库在 `stayHidden` 且已注册托盘时会自己 `hide()`。

第二次点快捷方式唤起已有实例时走 `MyTray.pop()`（有托盘），以遵守 `hideTaskBarIcon`。
