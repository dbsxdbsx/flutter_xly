# xly 包结构卫生待办（0.45+）

> **0.44.0** 已完成阶段 C（通知文档、子入口、命名别名、巨石拆分、Web 路径桩）。以下供后续可选优化。

## C — 模块边界与命名（0.44.0 已闭环）

- [x] **通知三通道**：`.doc/notify_channels.md` + 移除过时 `myTray.notify` 文档 / `MyTrayNotificationType`
- [x] **命名统一**：`MyFloatPanel` / `MySmartDock` 等 typedef 别名（非 breaking 硬改名）
- [x] **巨石组件**：`text_editor`、`scaffold` 拆为 `library` + `part`；`selector` 已有多文件，新增 `selector.dart` 子入口
- [x] **Web 路径**：`paths.dart` conditional export → `my_paths_web.dart` 桩
- [x] **export 粒度**：`notify` / `tray` / `text_editor` / `scaffold` / `selector` / `smart_dock` 子入口

## D — 可选后续（0.45+）

- [ ] **Selector 内部分片**：`widget.dart`（~1000 行）拆为 `part`（overlay / panel），需改为 `library` + `part`
- [ ] **命名硬切**：若 typedef 推广充分，再评估 `FloatPanel` → `MyFloatPanel` 主名（breaking）
- [ ] **减 barrel export**：从 `xly.dart` 移出低频模块（单独 major 版本）

## 参考

- [`.doc/notify_channels.md`](../.doc/notify_channels.md)
- [`.doc/user_data_paths.md`](../.doc/user_data_paths.md)
