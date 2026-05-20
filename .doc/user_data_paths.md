# 安装目录与用户数据目录

> **命名约定（`My` / `Xly` / 无前缀）与三条路径的定义见 [`AGENTS.md` §4](../AGENTS.md#4-project-specific-norms)。**  
> 本文只写 API 用法与集成步骤。

## 三条路径（速查）

| 层级 | API |
|------|-----|
| 安装目录 | `MyPlatform.installDirectory`、`getAppDirectory()`（桌面） |
| Bootstrap | `MyUserDataDirectoryStore` → `ApplicationSupport` 下 JSON |
| 用户数据 | `MyUserDataPaths.setRoot` / `requireRoot` |

## 读写文件

```dart
// 安装目录旁（便携资源、与旧 getFile 行为一致）
await MyPlatform.getFile('tray.ico');

// 用户数据目录（须先 setRoot）
MyUserDataPaths.setRoot(dataDir);
await MyPlatform.getUserDataFile('config.json');
// 或
await MyPlatform.resolveFile('config.json', root: MyFileRoot.userData);
```

## 桌面首次启动建议流程

1. `MyUserDataDirectoryStore.defaultInstance.load()`
2. 若无：UI 选目录 → `MyUserDataDirectoryValidator` → `save` + `MyUserDataPaths.setRoot`
3. `MyUserDataFilesMigrator.migrateFromInstallDirectory(userDataRoot: ..., fileNames: [...])`

## Bootstrap 自定义

默认文件 `user_data_directory.json`、字段 `userDataDirectory`。

若应用已有自己的指针文件名/JSON 字段，构造时覆盖即可：

```dart
const MyUserDataDirectoryStore(
  bootstrapFileName: 'my_app_data_pointer.json',
  jsonPathKey: 'dataRoot',
);
```

## 测试

```bash
flutter test test/user_data_paths_test.dart
```
