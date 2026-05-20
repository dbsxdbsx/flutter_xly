# AGENTS.md - xly

> 项目级 AI agent onboarding 入口（[Agentic AI Foundation 开放标准](https://github.com/agentic-ai-foundation/agentsmd)）。
> 本文件只记录仓库内可共享的事实、约定与索引；个人 Cursor Rules / Skills 不写入此处。
> 最近更新：2026-05-20。

## 1. Project Identity

- **类型**：Flutter **package**（`xly`），非独立上架应用；消费者通过 `pubspec` 依赖，示例见 `example/`。
- **主语言 / 框架**：Dart 3.5+、Flutter 3.7+；GetX、window_manager、flutter_screenutil 等（部分在 `lib/xly.dart` 再导出）。
- **阶段**：Beta（持续发版，`CHANGELOG.md` 跟踪）。
- **仓库**：<https://github.com/dbsxdbsx/flutter_xly>
- **当前版本**：`pubspec.yaml` → `0.41.0`（含安装目录 / 用户数据目录分层 API）。

## 2. Project Map

```text
xly/
├── lib/
│   ├── xly.dart              # 唯一 library 入口：export + part(app, float_panel)
│   └── src/
│       ├── app.dart          # part：MyApp.initialize、路由、窗口
│       ├── platform.dart     # MyPlatform：平台检测、安装目录、resolveFile
│       ├── paths/            # MyUserDataPaths、Store、Validator、Migrator
│       ├── tray/             # MyTray
│       ├── notify/           # MyNotify（含 Windows Toast 身份）
│       └── …                 # toast、selector、tab_view、smart_dock 等
├── example/                  # 演示应用（多页 widget 示例）
├── test/                     # 包级单元测试（含 user_data_paths_test.dart）
├── bin/                      # CLI：xly、generate、rename、win_setup
├── tool/                     # 图标生成等内部工具
├── .doc/                     # 长期知识（按主题拆分，见 §6）
└── user_code/                # 草稿消费代码；analysis_options 已 exclude
```

关键入口：

- 对外 API：`lib/xly.dart`
- 平台与路径：`lib/src/platform.dart`、`lib/src/paths/`
- 示例应用：`example/lib/main.dart`
- 测试：`flutter test`；路径专题：`flutter test test/user_data_paths_test.dart`

语义索引：

- 改 **对外 Widget / 服务 API** → `lib/src/<模块>/`，并在 `lib/xly.dart` 增加 export。
- 改 **MyApp 启动 / Zone / 异常** → `lib/src/app.dart`（part）、`.doc/error_handling.md`。
- 改 **路径 / 安装目录 vs 用户数据** → `lib/src/paths/`、§4 命名约定、`.doc/user_data_paths.md`。
- 改 **Windows 通知** → `lib/src/notify/`、`.doc/my_notify_usage_guide.md`。
- 改 **CLI** → `bin/`、`tool/`。

`analysis_options.yaml` 排除：`lib/xly.dart`、`user_code/**`。

## 3. Working Commands

| 任务 | 命令 | 备注 |
|------|------|------|
| 安装依赖 | `flutter pub get` | 根目录；`example/` 需单独 `pub get` 若跑示例 |
| 清理 | `flutter clean && flutter pub get` 或 `just clean` | 有 `justfile` 时 |
| 全量测试 | `flutter test` | |
| 路径模块测试 | `flutter test test/user_data_paths_test.dart` | 不依赖 example |
| 静态分析 | `flutter analyze` | |
| 跑示例 | `cd example && flutter run` | 桌面需对应平台工程 |
| CLI | `dart run xly` / `dart run xly:generate` 等 | 在**消费者应用**目录执行 |

## 4. Project-specific Norms

### 4.1 公开 API 命名（`My` / `Xly` / 无前缀）

| 前缀 | 用途 | 示例 |
|------|------|------|
| **My** | 对外 API：用户 `import 'package:xly/xly.dart'` 后直接使用的类、Widget、静态工具 | `MyPlatform`、`MyUserDataPaths`、`MyDialog`、`MyTray` |
| **Xly** | 库内部或横切能力；一般不作为业务首选入口 | `XlyLogger`（库内日志）、`XlyFocusController`（历史命名） |
| **无前缀** | 与 `WindowCorner` 同类的通用枚举/值类型；与 `My*` API 搭配 | `WindowCorner`、`MyFileRoot`（配合 `MyPlatform.resolveFile`） |

新增对外类型时**优先 `My*`**；仅当明确为内部实现细节时用 `Xly*` 或放在 `src/` 不 export。

### 4.2 三条路径（Install / Bootstrap / UserData）

桌面工具类应用必须区分，**不可**用一个「App 目录」混写配置与 exe：

| 概念 | API | 含义 |
|------|-----|------|
| **安装目录** | `MyPlatform.installDirectory`（同步）；`getAppDirectory()` 桌面同义 | exe / DLL / 托盘图标旁；`getFile` 默认根 |
| **Bootstrap 指针** | `MyUserDataDirectoryStore` + `getApplicationSupportDirectory()` | 仅存 JSON 指针，指向真实数据盘 |
| **用户数据根** | `MyUserDataPaths.setRoot` / `requireRoot` / `resetCache` | 配置、日志、业务 JSON；须先 `setRoot` 再读写 |

- `setRoot`：启动或用户选目录后**写入**内存根（默认 `clearCache: true`）。
- `requireRoot`：业务读写前**读取**根；未配置则 `StateError`（禁止静默回落到安装目录）。
- `resetCache`：根变更后清空 `MyUserDataPaths` 内文件路径缓存。

读写文件：显式 `MyFileRoot.install` / `MyFileRoot.userData` 或 `getUserDataFile`；详见 [`.doc/user_data_paths.md`](.doc/user_data_paths.md)。

`getAppDirectory()` **保留、不删除**；文档与注释标明桌面端 = 安装目录，**不是**用户数据目录。

### 4.3 其它约定

- 仅 `lib/src/app.dart`、`lib/src/float_panel.dart` 为 `part of '../xly.dart'`；其余模块独立文件 + export。
- GetX：服务 `GetxService` + `.to`；路由 `MyRoute` + `Get.toNamed`。
- `MyApp.initialize` 默认 `enableZoneGuard: false`（见 `.doc/error_handling.md`）。
- 非 ASCII 路径的 CLI：用 `dart run xly:<command>`，避免 Windows 终端编码问题。
- **不要**在未协商下恢复 `pubspec.yaml` 里已注释的 Windows native plugin 块（path override 消费者兼容，见 pubspec 注释）。

### 4.4 路径相关类型一览（没有 `MyFile` 类）

| 类型 | 职责 | 日常要不要记 |
|------|------|----------------|
| **`MyPlatform`** | 平台检测、窗口、**安装目录**下文件（`installDirectory`、`getFile`） | 要；老代码已大量用它 |
| **`MyFileRoot`** | 枚举：文件相对 **install** 还是 **userData**；给 `resolveFile` 用 | 需要统一入口时再用 |
| **`MyUserDataPaths`** | 内存里的**用户数据根**：`setRoot` / `requireRoot` / `file` / `logsDirectory` | 要；配置/日志都走它 |
| **`MyUserDataDirectoryStore`** | AppSupport 里 JSON **指针**（下次启动找回数据盘） | 桌面「可选数据目录」才要 |
| **`MyUserDataDirectoryValidator`** | 目录存在、可写、风险提示 | 配合 Store，首次选目录 |
| **`MyUserDataFilesMigrator`** | 把安装目录旁旧 json **迁**到用户数据目录 | 升级/迁移一次 |

**80% 用法（记这 4 步即可）**：`MyPlatform.installDirectory` → `MyUserDataPaths.setRoot` → `MyUserDataPaths.file('config.json')`（或 `MyPlatform.getUserDataFile`）→ 可选 `Store` + `Migrator`。

`resolveFile` / `MyFileRoot` 是统一底层；`getFile` / `getUserDataFile` 是语法糖，业务里二选一风格即可。

## 5. Active Context

- **进行中**：0.41.0 路径分层 API 已进库；待在消费者应用中推广「安装目录 vs 用户数据目录」分离用法。
- **最近变更**：CHANGELOG `0.41.0` — `installDirectory`、`MyUserDataPaths`、`MyFileRoot`、`MyUserDataDirectoryStore` 等。
- **阻塞**：无。
- **下一步**：在 example 或文档中补一段最小集成示例；bootstrap 文件名可通过 `MyUserDataDirectoryStore(...)` 构造参数自定义。

> **公开仓库纪律**：`AGENTS.md` / `README` / `CHANGELOG` / `.doc/` 等会提交到 GitHub 的文件中，**禁止**写入任何未开源的消费者项目名、内部路径或私有仓库线索。

## 6. Knowledge Index

- [`.doc/user_data_paths.md`](.doc/user_data_paths.md) — 路径 API 用法、迁移流程、Bootstrap 字段自定义（**命名约定在本文 §4**）
- [`.doc/error_handling.md`](.doc/error_handling.md) — Zone Guard、`installErrorHandlers`、库 vs 应用边界
- [`.doc/my_notify_usage_guide.md`](.doc/my_notify_usage_guide.md) — Windows Toast、权限与专注助手诊断
- [`.doc/contributor_logging_guide.md`](.doc/contributor_logging_guide.md) — `XlyLogger` 使用规范
- [`.doc/float_panel_usage.md`](.doc/float_panel_usage.md) — FloatPanel 配置与行为
- [`.doc/my_tray_design.md`](.doc/my_tray_design.md) — 系统托盘设计
- [`.doc/async_service_guide.md`](.doc/async_service_guide.md) — 异步服务 / GetX 服务模式
- [`.doc/my_selector_usage.md`](.doc/my_selector_usage.md) — MySelector
- [`.doc/my_text_editor_usage_guide.md`](.doc/my_text_editor_usage_guide.md) — MyTextEditor
- [`.doc/smart_tray_user_guide.md`](.doc/smart_tray_user_guide.md) / [`.doc/smart_tray_technical.md`](.doc/smart_tray_technical.md) — 智能托盘
- [`.doc/flutter_multi_window_guide.md`](.doc/flutter_multi_window_guide.md) — 多窗口
- [`.doc/adaptive_sidebar_usage.md`](.doc/adaptive_sidebar_usage.md) — 自适应侧栏

更多专题见 `README.md` 内链；历史摘要类文档不重复列入除非仍被引用。

## 7. Subprojects & repo boundaries

- **Git submodule**：无。
- **Workspace / 多包**：根包 `xly` + `example/` 独立 `pubspec`（示例应用，非 publish 包）。
- **嵌套 AGENTS.md**：无（仅根目录本文）。
- **待确认嵌套仓库**：无。
