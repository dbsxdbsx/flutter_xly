# AGENTS.md - xly

> 项目级 AI agent onboarding 入口（[Agentic AI Foundation 开放标准](https://github.com/agentic-ai-foundation/agentsmd)）。
> 本文件只记录仓库内可共享的事实、约定与索引；个人 Cursor Rules / Skills 不写入此处。
> 最近更新：2026-05-20。

## 1. Project Identity

- **类型**：Flutter **package**（`xly`），非独立上架应用；消费者通过 `pubspec` 依赖，示例见 `example/`。
- **主语言 / 框架**：Dart 3.5+、Flutter 3.7+；GetX、window_manager、flutter_screenutil 等（部分在 `lib/xly.dart` 再导出）。
- **阶段**：Beta（持续发版，`CHANGELOG.md` 跟踪）。
- **仓库**：<https://github.com/dbsxdbsx/flutter_xly>
- **当前版本**：`pubspec.yaml` → `0.42.0`（`MyPaths` 路径门面）。

## 2. Project Map

```text
xly/
├── lib/
│   ├── xly.dart              # 唯一 library 入口：export + part(app, float_panel)
│   └── src/
│       ├── app/              # part：MyApp.initialize、路由、窗口（models + mixins）
│       ├── platform.dart     # MyPlatform：平台检测、权限、窗口
│       ├── paths/            # MyPaths、Store、Validator、Migrator
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

- 对外 API：`lib/xly.dart`
- 路径：`lib/src/paths/my_paths.dart`、`.doc/user_data_paths.md`
- 平台：`lib/src/platform.dart`
- 示例：`example/lib/main.dart`（`MyRoutes.page14Paths`）
- 测试：`flutter test`；路径：`flutter test test/my_paths_test.dart`

语义索引：

- 改 **路径 API** → `lib/src/paths/`、[`.doc/user_data_paths.md`](.doc/user_data_paths.md)
- 改 **MyApp 启动 / Zone / 异常** → `lib/src/app.dart`（part）、`.doc/error_handling.md`
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
| **My** | 对外 API | `MyPaths`、`MyPlatform`、`MyTray` |
| **Xly** | 库内部或横切 | `XlyLogger`、`XlyFocusController` |
| **无前缀** | 通用值类型 | `WindowCorner` |

### 4.2 路径（`MyPaths` · install / userData）

| 轨 | 典型 API | 含义 |
|----|----------|------|
| **install** | `installDir`、`installFile`、`copyAssetToInstallDir` | exe 旁 / 移动 Documents fallback |
| **userData** | `setUserDataDir`、`userDataDir`、`userDataFile` | 配置、日志、业务数据 |
| **Bootstrap** | `MyUserDataDirectoryStore` | 桌面可选：AppSupport 下 JSON 指针 |

**后缀**：`Dir` → 目录 `String`；`File` → `Future<File>`。无 `*FilePath`、无 `MyFileRoot`。

**80% 四步**：`installFile` → `setUserDataDir` → `userDataFile` → 可选 Store / `migrateFromInstallDir`。

详文：[`.doc/user_data_paths.md`](.doc/user_data_paths.md)。

### 4.3 其它约定

- 仅 `lib/src/app.dart`、`lib/src/float_panel.dart` 为 `part of '../xly.dart'`。
- `MyPlatform` **不含**路径方法。
- `MyApp.initialize` 默认 `enableZoneGuard: false`（见 `.doc/error_handling.md`）。

## 5. Active Context

- **最近完成**：0.42.0 — `MyPaths` 破坏性路径收敛；文档与 example `Page14Paths`。
- **后续**：见 [`.issue/xly-package-hygiene-backlog.md`](.issue/xly-package-hygiene-backlog.md)（app/float_panel 拆分、通知边界等）。

> **公开仓库纪律**：`AGENTS.md` / `README` / `CHANGELOG` / `.doc/` 中**禁止**写入未开源消费者项目名、内部路径或私有仓库线索。

## 6. Knowledge Index

- [`.doc/user_data_paths.md`](.doc/user_data_paths.md) — **路径 API 唯一详文**
- [`.issue/xly-package-hygiene-backlog.md`](.issue/xly-package-hygiene-backlog.md) — 0.43+ 结构待办
- [`.doc/error_handling.md`](.doc/error_handling.md)
- [`.doc/my_notify_usage_guide.md`](.doc/my_notify_usage_guide.md)
- 其余见 `README.md` 内链

## 7. Subprojects & repo boundaries

- **Workspace**：根包 `xly` + `example/` 独立 `pubspec`。
- **嵌套 AGENTS.md**：无。
