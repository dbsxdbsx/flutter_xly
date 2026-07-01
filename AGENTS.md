# AGENTS.md - xly

> 项目级 AI agent onboarding 入口（[Agentic AI Foundation 开放标准](https://github.com/agentic-ai-foundation/agentsmd)）。
> 本文件只记录仓库内可共享的事实、约定与索引；个人 Cursor Rules / Skills 不写入此处。
> 最近更新：2026-07-01（0.52 MySelector placement / panel width autosize）。

## 1. Project Identity

- **类型**：Flutter **package**（`xly`），非独立上架应用；消费者通过 `pubspec` 依赖，示例见 `example/`。
- **主语言 / 框架**：Dart 3.5+、Flutter 3.7+；GetX、window_manager、flutter_screenutil 等（部分在 `lib/xly.dart` 再导出）。
- **阶段**：Beta（持续发版，`CHANGELOG.md` 跟踪）。
- **仓库**：<https://github.com/dbsxdbsx/flutter_xly>
- **当前版本**：`pubspec.yaml` → `0.52.0`（**0.52** `MySelector` 新增 `placement` / 面板宽度不传即自适应、传值即固定；**0.51** `MyTray.closeToTray` 关闭即隐藏 + Alt+Tab 修复；**0.50** `MyCard.subtitle` / `MySmartDock.wake`；见 `CHANGELOG`）。

## 2. Project Map

```text
xly/
├── lib/
│   ├── xly.dart              # barrel：含 MyPaths / MyUserDataDir*；不含 picker 与大型可选 UI
│   ├── app.dart              # MyApp.initialize、路由、窗口（可选子入口）
│   ├── float_panel.dart      # MyFloatPanel（可选子入口）
│   ├── paths.dart            # MyPaths、DirStore/Validator/Session（可选；Web 为桩）
│   ├── picker.dart           # MyPicker.dir/file/files（可选；Web 为桩）
│   ├── notify.dart / tray.dart / text_editor.dart / scaffold.dart / selector.dart / smart_dock.dart
│   └── src/
│       ├── app/              # app.dart 的 part：models + my_app
│       ├── platform.dart     # MyPlatform：平台检测、权限、窗口
│       ├── paths/            # MyPaths、DirStore、DirValidator、Session
│       ├── picker/           # MyPicker（file_selector）
│       ├── tray/             # MyTray
│       ├── notify/           # MyNotify（含 Windows Toast 身份）
│       └── …                 # toast、selector、tab_view、smart_dock 等
├── example/                  # 演示应用（含 Page14Paths）
├── test/                     # 包级单元测试（含 my_paths_test.dart）
├── bin/                      # CLI：xly、generate、rename、win_setup
├── tool/                     # 图标生成等内部工具
├── .doc/                     # 长期知识（按主题拆分，见 §6）
└── user_code/                # 草稿消费代码；analysis_options 已 exclude
```

关键入口：

- 对外 API：`lib/xly.dart`（常用全家桶，**含**路径 API）；`picker` 与大型 UI / 智能停靠需子入口（见 `README.md` 包入口表）
- 路径：`lib/src/paths/my_paths.dart`、`.doc/user_data_paths.md`
- 平台：`lib/src/platform.dart`
- 示例：`example/lib/main.dart`（`MyRoutes.page14Paths`）
- 测试：`flutter test`；路径：`flutter test test/my_paths_test.dart`

语义索引：

- 改 **路径 API** → `lib/src/paths/`、[`.doc/user_data_paths.md`](.doc/user_data_paths.md)
- 改 **系统选文件/夹 / Bootstrap 编排** → `lib/picker.dart`、`lib/src/picker/`、[`.doc/user_data_picker.md`](.doc/user_data_picker.md)
- 改 **MySelector 浮层选择器** → `lib/selector.dart`、`lib/src/selector/`、[`.doc/my_selector_usage.md`](.doc/my_selector_usage.md)
- 改 **MyApp 启动 / Zone / 异常** → `lib/app.dart`、`lib/src/app/`、`.doc/error_handling.md`
- 改 **Windows 通知** → `lib/src/notify/`、`.doc/my_notify_usage_guide.md`
- 改 **CLI** → `bin/`、`tool/`

`analysis_options.yaml` 排除：`lib/xly.dart`、`user_code/**`。

## 3. Working Commands

| 任务 | 命令 | 备注 |
|------|------|------|
| 安装依赖 | `flutter pub get` | 根目录；`example/` 需单独 `pub get` 若跑示例 |
| 全量测试 | `flutter test` | |
| 路径测试 | `flutter test test/my_paths_test.dart` | |
| 静态分析 | `flutter analyze` | |
| 跑示例 | `cd example && flutter run` | 桌面需对应平台工程 |

## 4. Project-specific Norms

### 4.1 公开 API 命名（`My` / `Xly` / 无前缀）

| 前缀 | 用途 | 示例 |
|------|------|------|
| **My** | 对外 Service / Manager / 门面 Widget | `MyPaths`、`MyFloatPanel`、`MySmartDock`、`MySelector` |
| **Xly** | 库内部或横切 | `XlyLogger`、`XlyFocusController` |
| **无前缀** | 通用值类型、枚举、样式配置 | `WindowCorner`、`PanelShape`、`MySelectorItem` |

- **子入口文件名**：功能 `snake_case`，**不加** `my_`（如 `float_panel.dart`，非 `my_float_panel.dart`）。
- **0.45+**：`FloatPanel` / `SmartDockManager` 等旧主名已删除，公开 API 类型一律 `My*`。
- **`MyApp.initialize` 命名参数**：语义短名、**不加** `my` 前缀；类型承载 `My*`（如 `MyTray? tray`、`MyFloatPanel? floatPanel`）。局部变量可用 `tray` / `notify` 等，与 `MyTray.to` 并用时不必写成 `myTray`。
- **持久化 / 存储键**：用 **`_xly_<feature>`** 命名空间（如 `_xly_float_panel`），**不用** `my_` 前缀，避免与业务自建 GetStorage 键冲突；与 Dart 类名 `My*` 无关。

### 4.2 路径（`MyPaths` · app / userData）

| 轨 | 典型 API | 含义 |
|----|----------|------|
| **app** | `appDir`、`appDirFile`、`copyAssetToAppDir` | 程序侧资源根：exe 旁 / 移动 Documents fallback（非安装向导） |
| **userData** | `setUserDataDir`、`userDataDir`、`userDataDirFile` | 配置、日志、业务数据 |
| **Bootstrap** | `MyUserDataDirStore` | 桌面可选：AppSupport 下 `user_data_dir.json` 指针 |
| **系统选择** | `MyPicker.dir` / `file` / `files` | `picker.dart`；非 `MySelector`、非 `MyPaths` |

**后缀**：自有 API 用 `Dir`（不用 `Directory`）；`Dir` → 目录 `String`；`DirFile` → 该目录下的 `Future<File>`（如 `appDirFile`、`userDataDirFile`）。`MyPicker.dir()` ≠ `MyPaths.userDataDir`。

**日常**：优先 `MyUserDataDirSession.prepare`；进阶再用手动三步 `appDirFile` → `Store.load` + `setUserDataDir` → `userDataDirFile`。

详文：[`.doc/user_data_paths.md`](.doc/user_data_paths.md)。

### 4.3 其它约定

- `app` / `float_panel` 为独立 library（`lib/app.dart`、`lib/float_panel.dart`），非 `xly.dart` 的 part。
- `MyPlatform` **不含**路径方法。
- `MyApp.initialize` 默认 `enableZoneGuard: false`（见 `.doc/error_handling.md`）。

## 5. Active Context

- **最近完成**：0.52 `MySelector` 新增 `MyPanelPlacement` / `placement`，默认首选向下且按内容高度判断翻转；面板宽度改为不传即完全自适应、传值即固定，`panelWidth` 不再内部 `.w`。见 `CHANGELOG` 与 [`.doc/my_selector_usage.md`](.doc/my_selector_usage.md)。
- **上一轮**：0.51 新增 `MyTray.closeToTray`（关闭即隐藏）并修复 Alt+Tab / 任务栏可见性绑定；0.50 `MyCard.subtitle` / `MySmartDock.wake()`。
- **上一版**：0.45.0 — 阶段 D；0.42.0 — `MyPaths` 双轨。
- **后续**：见 [`.issue/xly-package-hygiene-backlog.md`](.issue/xly-package-hygiene-backlog.md)（可选：可配置持久化键前缀）。

> **公开仓库纪律**：`AGENTS.md` / `README` / `CHANGELOG` / `.doc/` 中**禁止**写入未开源消费者项目名、内部路径或私有仓库线索。

## 6. Knowledge Index

- [`.doc/user_data_paths.md`](.doc/user_data_paths.md) — **路径 API**（双轨、两层目录、`prepare` 流程图、何时用哪套能力）
- [`.doc/user_data_picker.md`](.doc/user_data_picker.md) — **MyPicker / Session**（端到端流程图、API 速查、集成示例）
- [`.doc/my_selector_usage.md`](.doc/my_selector_usage.md) — **MySelector**（item / style / placement / 键盘与搜索用法）
- [`.doc/notify_channels.md`](.doc/notify_channels.md) — **MyToast / MyNotify / MyTray 三通道**
- [`.issue/xly-package-hygiene-backlog.md`](.issue/xly-package-hygiene-backlog.md) — 可选增强待办
- [`.doc/error_handling.md`](.doc/error_handling.md)
- [`.doc/my_notify_usage_guide.md`](.doc/my_notify_usage_guide.md)
- 其余见 `README.md` 内链

## 7. Subprojects & repo boundaries

- **Workspace**：根包 `xly` + `example/` 独立 `pubspec`。
- **嵌套 AGENTS.md**：无。
