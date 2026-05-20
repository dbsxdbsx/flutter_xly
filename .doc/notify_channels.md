# 通知与反馈三通道

> xly 中「让用户看到一条消息」有三条独立通道，**不要混用或层层转发**。详述 Windows Toast 见 [my_notify_usage_guide.md](my_notify_usage_guide.md)。

## 一句话策略

**应用在前台、需要即时 UI 反馈 → `MyToast`；应用在后台或需要进系统通知中心 → `MyNotify`；托盘只管图标与窗口显隐 → `MyTray`（不发送任何通知）。**

## 三通道对照

| 通道 | 类型 | 典型场景 | 是否需注册服务 |
|------|------|----------|----------------|
| **MyToast** | 应用内 Overlay | 按钮点击反馈、表单校验、权限被拒提示、Notify 失败兜底 | 否 |
| **MyNotify** | 系统通知（`flutter_local_notifications`） | 后台提醒、下载完成、定时任务、最小化到托盘后的系统级提示 | 是（`MyService<MyNotify>`） |
| **MyTray** | 托盘图标 / 菜单 / 窗口隐藏恢复 | 最小化到托盘、右键菜单、任务栏策略 | 是（`MyService<MyTray>`） |

## 决策树

```text
用户正在看应用窗口？
├─ 是 → 需要阻塞式强提示？
│      ├─ 是 → MyDialog / MyDialogSheet（对话框，非本文三通道）
│      └─ 否 → MyToast
└─ 否 → 需要出现在系统通知中心 / 锁屏？
       ├─ 是 → MyNotify.show(...)
       └─ 否（仅托盘区交互）→ 不要发明第四通道；恢复窗口用 MyTray.pop()
```

## 与历史 API 的关系

- **`MyTray.notify()` / `showNotification()` 已移除**（0.42 前后职责分离）。README / 旧示例若仍写 `myTray.notify`，请改为 `MyNotify.to.show(...)`。
- **`MyTrayNotificationType` 已移除**（无对应实现）。
- **Windows**：`MyNotify` 构造参数 `fallbackPolicy`（默认 `windowsOnly`）在 Toast API 成功但不弹横幅等场景下，可自动 fallback 到 `MyToast`；不要在业务里再套一层「失败再 Toast」除非关闭 fallback。

## 推荐组合（桌面 + 托盘）

```dart
// main：分别注册
MyService<MyTray>(service: () => MyTray(...)),
MyService<MyNotify>(service: () => MyNotify(), permanent: true),

// 隐藏到托盘时：系统通知（非 myTray.notify）
await MyTray.to.hide();
await MyNotify.to.show('已最小化', '点击托盘图标可恢复');

// 应用内操作反馈
MyToast.showInfo('设置已保存');
```

## 平台说明

| 平台 | MyNotify | MyToast | MyTray |
|------|----------|---------|--------|
| Windows / macOS / Linux | 支持 | 支持 | 支持 |
| Android / iOS | 支持（权限见 guide） | 支持 | 不适用 |
| Web | 视插件支持而定 | 支持 | 不适用 |

## 相关文档

- [my_notify_usage_guide.md](my_notify_usage_guide.md) — 权限、Windows 专注助手、fallback
- [my_tray_design.md](my_tray_design.md) — 托盘架构（不含通知）
- [example/lib/pages/page8.dart](../example/lib/pages/page8.dart) — MyNotify 演示
- [example/lib/pages/page9.dart](../example/lib/pages/page9.dart) — MyTray 演示
