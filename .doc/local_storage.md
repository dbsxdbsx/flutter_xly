# 本地 KV 存储（MyStorage）

> 桌面端不要用无参 `GetStorage()`。默认容器会写成用户「文档」目录的 `GetStorage.gs`，本机所有同样用法的 Flutter 应用共享这一文件；每次 `write` 整文件回刷，`erase()` 会清空别人的键。

## 怎么用

`MyApp.initialize` 会按下面顺序决定容器名，并 `init` 该容器：

1. 显式参数 `storageContainer`
2. `appName`（经文件名消毒）
3. `package_info` 的 `packageName`
4. 兜底 `XlyFlutterApp`

```dart
await MyApp.initialize(
  appName: '我的应用',
  storageContainer: 'my_app', // 可选；建议稳定英文 id
  // ...
);

final box = MyStorage.box;
await box.write('theme.dark', true);
```

`MyFloatPanel` 的位置 / 展开态写在同一命名容器，键前缀 `_xly_float_panel`。升级后首次启动会把默认盒里已有的 `_xly_*` 键迁过来，并只删除这些键。

## 不要做什么

| 禁止 | 原因 |
|------|------|
| `GetStorage()` / `GetStorage.init()` | 桌面端写回共享 `GetStorage.gs` |
| `storageContainer: 'GetStorage'` | 同上，解析时会被拒绝并回退 |
| 对默认容器 `erase()` | 清空本机所有共享应用的数据 |
| 把 API Token 写进 GetStorage | 明文 JSON，且历史上曾和其它应用挤在同一文件 |

业务若仍必须用 GetStorage，用自己的容器名：`GetStorage.init('your_app')` + `GetStorage('your_app')`。更稳妥的是 Hive、应用数据目录 JSON，或系统密钥环。

## 兼容

`initializeGetStorage: true`（默认）仍会 `init` 默认盒，以免旧代码在 `MyApp.initialize` 之后立刻 `GetStorage()` 读到未加载的空盒。xly 自身不再往默认盒写入。新代码请改用 `MyStorage.box`。
