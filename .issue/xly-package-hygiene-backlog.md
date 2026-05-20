# xly 包结构卫生待办（0.43+）

> 0.42 已完成路径 API（`MyPaths`）专版。以下条目**不在 0.42 范围**，供后续版本按优先级领取。

## B — 结构卫生（建议 0.43）

- [x] 拆分 `lib/src/app/` part（`models` / `my_app` + `MyAppWindowApi` / `MyAppDocking` mixin，2026-05-20）
- [x] 拆分 `lib/src/float_panel/` part（`models` / `service` / `box_controller` / `widgets`，2026-05-20）
- [x] 独立 library + 选择性 export：`lib/app.dart`、`lib/float_panel.dart`、`lib/paths.dart`；`xly.dart` 为 barrel（2026-05-20）

## C — 模块边界与命名（建议 0.44+）

- [ ] **通知三通道**：`MyTray` 气泡 vs `MyNotify` vs `MyToast` 兜底 — 文档划界 + 默认策略
- [ ] **命名统一**：`FloatPanel` / `SmartDockManager` 是否纳入 `My*` 前缀
- [ ] **巨石组件**：`MyTextEditor`、`MySelector`、`MyScaffold` 是否拆子包或降 export 粒度
- [ ] **Web 路径**：conditional export / 抽象路径接口
- [ ] **export 粒度**：`xly/paths.dart` 子入口，减小全家桶 import

## 参考

- 0.42 计划审阅：Explore / Creator / Reviewer 结论（路径专版已落地）
- 路径详文：[`.doc/user_data_paths.md`](../.doc/user_data_paths.md)
