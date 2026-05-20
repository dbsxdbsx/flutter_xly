# 安装目录与用户数据目录（MyPaths）

> 命名约定摘要见 [`AGENTS.md` §4.2](../AGENTS.md#42-路径install--bootstrap--userdata)。本文是路径 API 的**完整说明**。

## 命名：Dir 与 File

| 后缀 | 返回 | 含义 |
|------|------|------|
| `Dir` | `String`（目录路径） | 文件夹根或子目录（如 `userDataLogsDir`） |
| `File` | `Future<File>` | `dart:io` 文件；参数为**相对路径** |
| `…To…Dir` | `Future<File>` | 如 `copyAssetToInstallDir`：`Dir` 表示落到哪条轨，返回值仍是文件 |

需要文件路径字符串：`(await MyPaths.userDataFile('a.json')).path`。

**不提供** `*FilePath()` 公开方法。Web 目标请 `import 'package:xly/paths.dart'`：自动选用 `MyPaths` 桩实现（全部 API 抛 `UnsupportedError`）；`MyUserDataDirectoryStore` 等仍依赖 `dart:io`，Web 勿 import。

## 两条轨

| 轨 | API 前缀 | 用途 |
|----|----------|------|
| **install** | `installDir` / `installFile` / `copyAssetToInstallDir` | exe 旁资源、托盘图标、从 assets 落到安装侧 |
| **userData** | `setUserDataDir` / `userDataDir` / `userDataFile` / … | 配置、日志、业务 JSON |

- **便携应用**：只用 `install*`。
- **桌面、数据与 exe 分离**：`setUserDataDir` + `userData*`；可选 `MyUserDataDirectoryStore` 记住目录（Bootstrap 指针，在 AppSupport 下 JSON）。

### `installDir` 跨平台

- **桌面**：exe 所在目录（同步）。
- **移动**：Documents 作可写资源 fallback（无 exe 旁「安装目录」语义，行为等同旧 `getAppDirectory` 移动侧）。
- **Web**：`UnsupportedError`。

## 公开 API（MyPaths）

| API | 返回 | 说明 |
|-----|------|------|
| `installDir` | `String` | install 轨根目录 |
| `installFile(relativePath, {androidPreferExternal})` | `Future<File>` | install 轨下文件 |
| `setUserDataDir(path, {clearCache})` | `void` | 设置 userData 根 |
| `userDataDir` | `String` | 已设置的根；未设置抛 `StateError` |
| `isUserDataDirSet` | `bool` | 是否已设置 |
| `userDataFile(relativePath)` | `Future<File>` | userData 轨下文件 |
| `userDataLogsDir()` | `Future<String>` | `logs/` 子目录 |
| `copyAssetToInstallDir` / `copyAssetToUserDataDir` | `Future<File>` | 从 `assets/` 复制（目标不存在时写入） |
| `atomicWriteString(file, content)` | `Future<void>` | 原子写 |

`relativePath`：可为 `'config.json'` 或 `'logs/app.log'`；禁止 `..` 与绝对路径。

## 日常四步

```dart
final ico = await MyPaths.installFile('tray.ico');

final saved = await MyUserDataDirectoryStore.defaultInstance.load();
MyPaths.setUserDataDir(saved ?? userPickedDir);

final config = await MyPaths.userDataFile('config.json');

await MyUserDataFilesMigrator.migrateFromInstallDir(
  userDataRoot: MyPaths.userDataDir,
  fileNames: const ['config.json'],
);
```

## Bootstrap（桌面可选）

默认文件 `user_data_directory.json`、字段 `userDataDirectory`：

```dart
const MyUserDataDirectoryStore(
  bootstrapFileName: 'my_app_data_pointer.json',
  jsonPathKey: 'dataRoot',
);
```

流程：`Store.load()` → 无则 UI 选目录 → `MyUserDataDirectoryValidator.evaluate` → `Store.save` + `setUserDataDir`。

## 0.41 → 0.42 迁移

| 0.41 | 0.42 |
|------|------|
| `MyPlatform.installDirectory` / `getAppDirectory()` | `MyPaths.installDir` |
| `MyPlatform.getFile(name)` | `MyPaths.installFile(name)` |
| `MyPlatform.getFilePath(name)` | `(await MyPaths.installFile(name)).path` |
| `MyUserDataPaths.setRoot(p)` | `MyPaths.setUserDataDir(p)` |
| `MyUserDataPaths.requireRoot()` | `MyPaths.userDataDir` |
| `MyUserDataPaths.file('a')` | `MyPaths.userDataFile('a')` |
| `MyPlatform.getUserDataFile('a')` | `MyPaths.userDataFile('a')` |
| `MyUserDataPaths.logsDirectory()` | `MyPaths.userDataLogsDir()` |
| `getFilePastedFromAssets(name)` | `MyPaths.copyAssetToInstallDir(name)` |
| `getFilePastedFromAssets(name, _, userData)` | `MyPaths.copyAssetToUserDataDir(name)` |
| `MyFileRoot` / `resolveFile` | 删除；用 `installFile` / `userDataFile` |
| `migrateFromInstallDirectory` | `migrateFromInstallDir` |

`MyPlatform` 仅保留平台检测、权限、窗口；路径一律 `MyPaths`。

## 测试

```bash
flutter test test/my_paths_test.dart
```
