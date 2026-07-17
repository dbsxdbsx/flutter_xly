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



## G — 退出与托盘可靠性（0.53.0+ 进行中）

- [x] **安全退出态**：`MyTray.beginExit()` / `isExiting`，保留图标禁用交互
- [x] **桌面退出不卡**：`MyApp.exit()` 限时 + `exit(0)` 硬退出
- [x] **初始化/销毁竞态**：`destroy()` 等待 `_initializeFuture`
- [x] **关闭拦截所有权**：`_ownsPreventClose` 追踪
- [x] **退出时隐藏窗口**：`MyApp.exit()` 首步 `windowManager.hide()`（0.55）
- [x] **单向状态机**：`beginExit` 不回退，共享 Future 幂等（0.55）
- [ ] **退出竞态单元测试**：`beginExit`/`destroy`/`onWindowClose` 并发序列验证
- [ ] **移动端 MyTray guard**：非桌面平台注册时跳过插件调用（当前由 `!MyPlatform.isDesktop` 在初始化时短路，但构造和 GetX 注册仍发生）

## H — 统一菜单系统（0.54.0 已闭环）

- [x] **MyMenu 渲染核心**：右键/锚定/MenuButton 共享
- [x] **MyMenuAnchor**：挂接任意控件
- [x] **田字格定位**：`MyMenuAnchorOrigin.center`
- [x] **reveal 动画**：`MyMenuPopStyle.reveal`
- [ ] **菜单 widget 测试**：覆盖定位象限、子菜单、禁用项

## I — 托盘菜单方向（Unreleased）

- [x] **TrayPopupHelper FFI**：`SHAppBarMessage` + 动态对齐标志
- [ ] **非 Windows 平台回退验证**：macOS/Linux 弹出位置确认

## E — 可选后续



- [ ] **GetStorage 键可配置**：`MyFloatPanel.configure(persistenceKeyPrefix: ...)`（需迁移说明）

- [ ] **发布前 dry-run 清单**：`dart pub publish --dry-run` 扫描、tracked-files 隐私审计



## 参考



- [`.doc/notify_channels.md`](../.doc/notify_channels.md)

- [`.doc/user_data_paths.md`](../.doc/user_data_paths.md)

- [`.doc/user_data_picker.md`](../.doc/user_data_picker.md)

- [`.doc/float_panel_usage.md`](../.doc/float_panel_usage.md)


