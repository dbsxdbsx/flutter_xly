# 异常处理与 Zone 决策

> **面向对象**：xly 包的使用者与贡献者
> **目的**：说明 xly 在异常处理 / Zone 边界上的设计决策、推荐姿势、踩坑场景与演进历史

## TL;DR（结论先行）

| 问 | 答 |
|---|---|
| 我什么都不写，xly 帮我做什么？ | 默认装好 `FlutterError.onError` + `PlatformDispatcher.instance.onError` 两个 root-level 异常 hook，把异常 sink 到 `XlyLogger.error` 打日志 |
| 我要把异常上报到 Sentry / Crashlytics 怎么办？ | 优先用 `MyApp.initialize(onError: (e, st) => ...)` 一行搞定；要更精细就自己包 `runZonedGuarded` 或者直接 `installErrorHandlers: false` 全部接管 |
| `enableZoneGuard` 默认值是？ | **0.38.2 起默认 `false`**（之前 0.37.0 ~ 0.38.1 默认 `true`）。理由见下方"演进历史"段 |
| 不想 xly 碰我的全局 hook | 传 `installErrorHandlers: false`，xly 完全不动 `FlutterError.onError` / `PlatformDispatcher.onError` |

## 一、Flutter 异常体系速览

Flutter 应用里的异常来源大致分四类，每一类有不同的捕获方式：

| 异常来源 | 举例 | 默认捕获机制 |
|---|---|---|
| Widget 构建/布局/绘制 | `RenderFlex overflowed`、`build` 里 throw | `FlutterError.onError`（默认值是 `FlutterError.presentError`，红屏 + 打印） |
| Framework 异步内部 | `Image.network` 加载失败 | 同上，被 framework 捕获后转交 `FlutterError.onError` |
| 用户业务异步——已 await / catchError | `await fetchUser()` 抛异常 | 普通 `try/catch` 即可 |
| 用户业务异步——孤儿 Future（无人 await、无人 catchError） | `Future.delayed(...).then((v) => throw X)` | 既不会被 `FlutterError.onError` 抓到，也没人 catchError → 直接 propagate 到 root |

**根本问题**：第四类"孤儿 Future"的异常默认会丢，需要额外的 root-level hook 才能兜底。

## 二、两种 root-level 兜底机制

Flutter 给了两种工具来抓"孤儿 Future"异常，**两者不必同时用**：

### 2.1 `runZonedGuarded`（老牌）

```dart
void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(const MyApp());
  }, (error, stack) {
    Sentry.captureException(error, stackTrace: stack);
  });
}
```

**优点**：能拦截 `print`、`Timer`、`Microtask`、`scheduleMicrotask` 等 Zone 内所有异步行为。

**缺点**：必须包整个 main，对 Zone 嵌套敏感——任何"binding 在 Zone A、runApp 在 Zone B"都会抛 `Zone mismatch`。

### 2.2 `PlatformDispatcher.instance.onError`（Flutter 3.3+ 推荐）

```dart
void main() {
  PlatformDispatcher.instance.onError = (error, stack) {
    Sentry.captureException(error, stackTrace: stack);
    return true; // 已处理
  };
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}
```

**优点**：root-level hook，不依赖任何 Zone，没有 Zone 嵌套陷阱；写法简单。

**缺点**：抓不到 `print` / `Timer` / `Microtask` 这类 Zone 才能拦截的行为（绝大多数业务用不到）。

**官方文档定位**：`PlatformDispatcher.onError` 是 `runZonedGuarded` 的轻量替代，覆盖度 ≈ 99% 业务场景，且没有 Zone 副作用。

## 三、xly 的设计决策

### 3.1 默认行为（0.38.2 起）

`MyApp.initialize` 默认会做两件事：

1. **`WidgetsFlutterBinding.ensureInitialized()` 在调用方 Zone 完成**
   保证 binding 跟 `runApp` 永远同 Zone，无论用户在外层有没有自己包 Zone。

2. **安装 root-level 异常 hook**（`installErrorHandlers: true`）
   - `FlutterError.onError`：仍然走 `presentError`（保留 debug 红屏行为），同时把异常 sink 出去
   - `PlatformDispatcher.instance.onError`：兜底所有未捕获异步异常，标记已处理

两个 hook 的 sink 默认走 `XlyLogger.error`；用户可通过 `onError` 参数把 sink 替换为自己的（Sentry / Crashlytics / 自定义日志）。

### 3.2 三个新参数

```dart
await MyApp.initialize(
  // ...原有参数...

  // 是否安装 root-level 异常 hook（默认 true）
  bool installErrorHandlers = true,

  // 自定义异常 sink（不传则走 XlyLogger.error）
  void Function(Object error, StackTrace stack)? onError,

  // ⚠️ 0.38.2 起默认 false（之前 0.37.0 起默认 true）
  bool enableZoneGuard = false,
);
```

### 3.3 检测策略——不抢用户既有 hook

`_installErrorHandlers` 在装 hook 之前会检测：

| Hook | 默认值 | 检测条件 | 已被外部设置时的行为 |
|---|---|---|---|
| `FlutterError.onError` | `FlutterError.presentError` | `!= FlutterError.presentError` 视为已被设置 | 跳过 + `XlyLogger.warning` |
| `PlatformDispatcher.instance.onError` | `null` | `!= null` 视为已被设置 | 跳过 + `XlyLogger.warning` |

这样，下面三种用户都能和谐共存：

| 用户类型 | 用户写法 | xly 行为 |
|---|---|---|
| A. 完全甩手掌柜 | 什么都不写 | 装两个 hook，默认 sink 到 XlyLogger |
| B. 想自定义 sink | `onError: (e, st) => Sentry.capture(...)` | 装两个 hook，sink 走用户的 callback |
| C. 完全自己接管 | 自己设 `FlutterError.onError = ...`，再调 initialize | xly 检测到已设置 → 跳过 + 打 warning |

## 四、推荐姿势（按场景）

### 4.1 普通用户：什么都不写

```dart
void main() => MyApp.initialize(
  designSize: const Size(800, 600),
  routes: routes,
);
```

xly 默认装好 `FlutterError.onError` + `PlatformDispatcher.onError`，所有未捕获异常都会走 `XlyLogger.error`。

### 4.2 接 Sentry / Crashlytics（推荐）

```dart
void main() => MyApp.initialize(
  designSize: const Size(800, 600),
  routes: routes,
  onError: (error, stack) =>
      FirebaseCrashlytics.instance.recordError(error, stack),
);
```

一行参数搞定，不需要包 `runZonedGuarded`，不需要手动设 `FlutterError.onError`。

### 4.3 自有日志/异常体系

```dart
void main() async {
  // 用户已有 AppLogger / 全局错误处理
  FlutterError.onError = (details) {
    AppLogger.error('Flutter', details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (e, st) {
    AppLogger.error('Async', e, st);
    return true;
  };

  await MyApp.initialize(
    designSize: const Size(800, 600),
    routes: routes,
    // 用户自己设过 hook，xly 会检测到并跳过；这里显式传 false 把意图写清楚
    installErrorHandlers: false,
  );
}
```

### 4.4 必须用 `runZonedGuarded`（要拦 print/Timer 等）

```dart
void main() => runZonedGuarded(
  () async => await MyApp.initialize(
    designSize: const Size(800, 600),
    routes: routes,
    installErrorHandlers: false, // 把控制权交回用户的 Zone
  ),
  (error, stack) => Sentry.captureException(error, stackTrace: stack),
);
```

xly 的 binding 已经在调用方 Zone 内初始化（即用户的 `runZonedGuarded` Zone），不会冲突。

## 五、踩坑场景与解析

### 5.1 `Zone mismatch.` —— 0.37.x 时代的经典翻车

**症状**：

```
Zone mismatch.
The Flutter bindings were initialized in a different zone than is now being used.
```

**根因**（0.37.0 ~ 0.38.1 默认行为）：

```dart
// 用户写法（很常见）：
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ← 在 root Zone 初始化 binding
  await MyApp.initialize(...);                // ← xly 内部 runZonedGuarded 包了 runApp
}                                              // ← runApp 在 xly 新建的 Zone 里 → mismatch
```

或者：

```dart
void main() {
  runZonedGuarded(() async {
    await MyApp.initialize(...);  // ← xly 又开了一层内部 Zone → 双重嵌套
  }, ...);
}
```

**0.38.2 修复**：

1. binding 提前到调用方 Zone 之外（在用户 Zone 中初始化）
2. 默认走 try/catch 路径，不再开内部 Zone
3. 即使用户显式开 `enableZoneGuard: true`，binding 也已经在外层 Zone 完成，不会 mismatch

### 5.2 "我自己设了 `FlutterError.onError`，但好像没生效"

**可能原因**：

- xly 版本 ≤ 0.38.1，且 `enableZoneGuard: true`：xly 的 Zone Guard 把异常吞了，没走 `FlutterError.onError`
- 0.38.2+：xly 检测到外部已设置时会跳过自动安装并打 warning，把日志开关开了应该能看到那条 warning

**排查步骤**：

```dart
await MyApp.initialize(
  enableDebugLogging: true, // ← 打开包内日志，看 xly 的 warning
  // ...
);
```

### 5.3 "传了 `onError` 但没收到初始化阶段的异常"

**这是预期行为**。`onError` 是 sink 给"运行时异步异常"的，不会被初始化阶段的同步异常触发：

- 初始化阶段（`MyApp.initialize` 内部）的异常 → `XlyLogger.error('MyApp 初始化失败')` + rethrow，让 main 看到
- 运行时异常（`runApp` 之后）→ 走 `FlutterError.onError` / `PlatformDispatcher.onError` → 走 `onError` sink

如果想兜底初始化阶段，自己在 main 里包 `try/catch`：

```dart
void main() async {
  try {
    await MyApp.initialize(
      onError: (e, st) => Sentry.capture(e, stackTrace: st),
    );
  } catch (e, st) {
    Sentry.capture(e, stackTrace: st); // 初始化失败的兜底
    rethrow;
  }
}
```

## 六、为什么不再默认开 Zone Guard——决策记录

`enableZoneGuard` 默认值在 0.37.0 设为 `true`，在 0.38.2 改回 `false`。决策依据：

### 6.1 库与应用的边界

`runZonedGuarded` 是一个**全局副作用**——它定义"整个进程之后所有异步行为跑在哪个 Zone 里"。这个决策应该是**应用 owner 的决定**，不是被引用库的默认行为。

参考主流 Flutter 库的做法：

```
GetX        ─ 不替用户开 runZonedGuarded
Provider    ─ 不替用户开
Riverpod    ─ 不替用户开
Bloc        ─ 不替用户开
go_router   ─ 不替用户开
```

Sentry / Firebase Crashlytics 给的也是"在 main 里手动包"的写法，不替用户包。xly 对齐这个生态惯例是最小惊讶原则。

### 6.2 Zone 嵌套必然带来 binding 一致性陷阱

Flutter 铁律：`WidgetsFlutterBinding.ensureInitialized()` 和 `runApp()` 必须同 Zone，否则 `Zone mismatch`。

只要库在内部新开 Zone 又在内部调 `ensureInitialized` 和 `runApp`，就会跟用户在外层做的任何 binding/Zone 操作冲突。这种"看似贴心、实际埋雷"的设计，会让用户在自己 main 里加任何错误处理时都踩坑——而且 `Zone mismatch` 的错误信息对绝大多数 Flutter 用户来说陌生，调试成本极高。

### 6.3 `PlatformDispatcher.onError` 是更现代的替代

Flutter 3.3+ 之后，`PlatformDispatcher.instance.onError` 已经能覆盖 `runZonedGuarded` 99% 的业务场景，且没有 Zone 副作用。官方文档现在也优先推荐它。继续依赖 `runZonedGuarded` 默认开是逆潮流的选择。

### 6.4 "少写代码" 的角度

| 用户类型 | 默认开 Zone Guard | 默认关 + 默认装 hook |
|---|---|---|
| 完全不关心异常处理 | 0 行 | 0 行 |
| 想看到默认日志兜底 | 0 行（但 zone 里抓） | 0 行（默认装好） |
| 想自定义 sink（Sentry 等） | **必须** 写 `enableZoneGuard: false` + `runZonedGuarded(...)` | 一行 `onError: ...` |
| 想完全接管 | **必须** 写 `enableZoneGuard: false` + 自己 `FlutterError.onError = ...` | 自己设 hook，xly 检测到自动跳过 |

默认关让两类高级用户都不需要多写"避开 xly"的代码。

### 6.5 拒绝"双方都开了，xly 自动静默"方案

讨论过让 xly 检测外层是否已经在 `runZonedGuarded` 内、是的话就不再嵌套。最终拒绝原因：

1. **识别不可靠**：用户的 Zone 没有 xly 标记，只能靠 `Zone.current != Zone.root` 模糊判断；测试 / Flutter Driver / 某些 plugin 包装下未必准
2. **诉求不对等**：用户开 Zone 是为了上报 Sentry，xly 开 Zone 是为了兜底初始化日志，复用对方的 sink 反而互相污染
3. **库越聪明，用户越难 debug**：库代码里有"环境检测、自动降级"的逻辑，会出现"同代码 A 项目能跑 B 不能跑"的诡异问题

库的最佳策略是**可预测**而不是**聪明**。

## 七、API 速查

### `MyApp.initialize` 异常处理相关参数

```dart
static Future<void> initialize({
  // ... 其他参数 ...

  /// 是否安装 root-level 异常 hook（默认 true）。
  ///
  /// 装的两个 hook：
  /// - FlutterError.onError ← Widget 树/framework 异步异常
  /// - PlatformDispatcher.instance.onError ← root-level 异步异常兜底
  ///
  /// 只在 hook 仍是默认值时安装，已被外部设置就跳过 + 打 warning。
  bool installErrorHandlers = true,

  /// 异常 sink。不传则走 XlyLogger.error。
  ///
  /// 例：
  ///   onError: (e, st) => Sentry.captureException(e, stackTrace: st)
  void Function(Object error, StackTrace stack)? onError,

  /// Zone 守护（默认 false，0.38.2 起）。
  ///
  /// 默认关原因见 .doc/error_handling.md 第六节。
  /// 仅在需要拦截 print/Timer/Microtask 等 Zone 内行为时才显式开。
  bool enableZoneGuard = false,

  // ... 其他参数 ...
});
```

### 行为矩阵

| 用户写法 | binding 在哪个 Zone | runApp 在哪个 Zone | hook 装载 | 异常 sink |
|---|---|---|---|---|
| `MyApp.initialize()` 默认 | 调用方（root） | 调用方（root） | xly 自动装 | `XlyLogger.error` |
| `MyApp.initialize(onError: f)` | 调用方（root） | 调用方（root） | xly 自动装 | 用户的 `f` |
| `MyApp.initialize(installErrorHandlers: false)` | 调用方（root） | 调用方（root） | 不装 | 用户自己 |
| `MyApp.initialize(enableZoneGuard: true)` | 调用方（root） | xly 内部 Zone | xly 自动装 | `XlyLogger.error` + Zone Guard |
| 外层包 `runZonedGuarded` | 用户 Zone | 用户 Zone | 视 `installErrorHandlers` | `FlutterError.onError` + 用户 Zone Guard |

## 八、版本演进

| 版本 | enableZoneGuard 默认 | 内部行为 | 备注 |
|---|---|---|---|
| 0.36 及以前 | `false`（无此参数） | 直接调 `initializeInCurrentZone` | 用户自己包 Zone |
| 0.37.0 | **`true`** | `runZonedGuarded` 包整个 init（含 binding 和 runApp） | 引入 Zone Guard 默认开；后续暴露 binding 嵌套问题 |
| 0.38.2 | **`false`** | binding 提前到 Zone 外；默认走 try/catch；新增 `installErrorHandlers` + `onError` | Behavior Change：见 CHANGELOG 0.38.2 |

## 九、参考

- Flutter 官方：[Handling errors in Flutter](https://docs.flutter.dev/testing/errors)
- `dart:ui` `PlatformDispatcher.onError`：Flutter 3.3 引入的 root-level 异步异常 hook
- 相关 issue 上下文：见 0.38.2 升级讨论（用户 main 中手动 `WidgetsFlutterBinding.ensureInitialized()` 触发 `Zone mismatch` 的真实案例）
