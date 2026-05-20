# xly 包结构卫生待办



> **0.47.0** 已闭环 Dir 大统一 + `MyPicker` / `MyUserDataDirSession`。后续仅保留可选增强。



## D — 模块边界与命名（0.45.0 已闭环）



- [x] **Selector 内部分片**：`lib/selector.dart` + `part`（overlay / panel / item_widgets）

- [x] **命名硬切**：`MyFloatPanel`、`MySmartDock` 为主名；旧 typedef 已删除

- [x] **减 barrel export**：`xly.dart` 不再导出 text_editor / scaffold / selector / smart_dock



## F — 路径与选择器（0.47.0 已闭环）



- [x] **Directory → Dir**：`MyUserDataDirStore` / `Validator` / `Validation`

- [x] **MyPicker**：`picker.dart`（`dir` / `file` / `files`）

- [x] **MyUserDataDirSession**：`prepare` / `apply`（paths 子入口）

- [x] **Setup 对话框**：库外；`.doc/user_data_picker.md` + example 参考



## E — 可选后续



- [ ] **GetStorage 键可配置**：`MyFloatPanel.configure(persistenceKeyPrefix: ...)`（需迁移说明）



## 参考



- [`.doc/notify_channels.md`](../.doc/notify_channels.md)

- [`.doc/user_data_paths.md`](../.doc/user_data_paths.md)

- [`.doc/user_data_picker.md`](../.doc/user_data_picker.md)

- [`.doc/float_panel_usage.md`](../.doc/float_panel_usage.md)


