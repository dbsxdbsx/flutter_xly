# xly 包结构卫生待办（0.44+）

> **0.43.0** 已完成阶段 B（结构拆分 + 独立 library + `paths.dart` 子入口）。以下条目供 **0.44+** 领取。

## B — 结构卫生（0.43.0 已闭环）

- [x] 拆分 `lib/src/app/`（`models` + `my_app`，2026-05-20）
- [x] 拆分 `lib/src/float_panel/`（`models` / `service` / `box_controller` / `widgets`，2026-05-20）
- [x] 独立 library + 选择性 export：`lib/app.dart`、`lib/float_panel.dart`、`lib/paths.dart`；`xly.dart` 为 barrel（2026-05-20）

## C — 模块边界与命名（建议 0.44+）

- [ ] **通知三通道**：`MyTray` 气泡 vs `MyNotify` vs `MyToast` 兜底 — 文档划界 + 默认策略
- [ ] **命名统一**：`FloatPanel` / `SmartDockManager` 是否纳入 `My*` 前缀
- [ ] **巨石组件**：`MyTextEditor`、`MySelector`、`MyScaffold` 是否拆子包或降 export 粒度
- [ ] **Web 路径**：conditional export / 抽象路径接口
- [ ] **export 粒度**：更多子入口（如 `notify`、`tray`），减小全家桶 import（`paths.dart` 已在 0.43）

## 参考

- 0.42 计划审阅：Explore / Creator / Reviewer 结论（路径专版已落地）
- 路径详文：[`.doc/user_data_paths.md`](../.doc/user_data_paths.md)
