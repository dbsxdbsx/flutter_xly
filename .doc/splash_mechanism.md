# MySplash / 启动叠层

> **面向对象**：xly 维护者与消费应用  
> **目的**：写清叠层门闩、`bootstrap` 时序，以及 `MyBootstrapTask.run` / `putAsync` 的职责划分  
> **相关**：`lib/src/splash.dart`、`lib/src/app/splash_gate.dart`、`lib/src/app/models.dart`

## TL;DR

| 问 | 答 |
|---|---|
| `MySplash` 是路由吗？ | **不是。** 盖在 `GetMaterialApp` 上，`initialRoute` 已是业务首页。 |
| 重活何时跑？ | 旧 `services` 仍在 `runApp` 前。新工作放 `bootstrap`：首帧提交后再跑。 |
| 何时揭开？ | blocking 到终态，且（有 Lottie）只播一圈，或（静态脸）过了 `minVisible`。 |
| 要绑 GetX 路由吗？ | **不要。** 揭开看 `isSplashFinished`，不要 `Get.offNamed`。 |
| 在 bootstrap 里登记 GetX 服务？ | `MyBootstrapTask.putAsync`。普通工作用 `MyBootstrapTask.run`。 |

## 时序

```text
点图标
  → 原生静帧（各平台自己画，底色对齐叠层第一帧）
  → runApp 尽快画出 MySplash
  → 两帧提交后跑 bootstrap
  → blocking 结束（失败 / 超时按等级处理）且品牌一圈完
  → 揭开首页壳
  → 首页自己 skeleton / shimmer
```

`services` 语义没改：仍会挡住第一帧。能挪的初始化请改走 `bootstrap`。

不要：

- 在 `runApp` 前 `await` 完整业务服务表。
- 用循环 Lottie 填等待（库已 `repeat: false`）。
- 把 Splash 做成 GetX 第一页再 `offNamed`（换页会触发 SmartManagement）。
- 让叠层等到首页数据齐了再揭开。

## 揭开公式

`MySplashGate.canDismiss`：

1. `fatal` 不揭开，叠层留错误态。
2. blocking 必须到终态（成功 / degraded / optional / 超时且无未决 fatal）。
3. 有 Lottie：等 `completed`，或 `brandTimeout`，或资源失败。
4. 静态品牌脸：等 `minVisible`（默认 300ms），防闪一帧。

消费方观察 `MyApp.isSplashFinished` / `isBootstrapReady` / `splashPhase`，首页数据层 `await MyApp.bootstrapReady`。

`nextRoute`、`splashDuration` 已废弃，不再参与揭开。无品牌脸传 `splash: null`（无叠层时视为已揭开，`bootstrap` 仍会跑）。

## 在 bootstrap 里跑什么

```dart
bootstrap: [
  MyBootstrapTask.run(() async {
    await restoreSession();
  }),
  MyBootstrapTask.putAsync<Foo>(() => Foo().init()),
],
```

`run<T>` 的返回类型由闭包推断，不会预先钉成 `void`。登记异步 GetX 服务用 `putAsync<T>`（可带 `permanent` / `tag`）。`runApp` 前的正式口继续用 `MyService<Foo>(asyncService: ...)`。

若先写成 `Future<void> Function() f = () => Get.putAsync(...)` 再 `run(f)`，GetX 仍会打 `Instance "void"`。任务结束后（含中途抛错）会检查无 tag 的 `void` / `dynamic`，抛 `MyBootstrapContractError`，门闩按 fatal 停住。GetX 注册键含 tag，公开 API 枚举不了，带 tag 的擦除登记检测不到；直接 `run(() => Get.putAsync(..., tag: ...))` 仍按真实类型推断。

`putAsync` 不等 `onInit()`：需要预先初始化时，工厂里做完再返回实例。详见 [异步服务指南](async_service_guide.md)。

## 原生静帧（包不代做工程文件）

引擎第一帧之前只能靠原生窗。消费应用自己对齐：

- Android：`LaunchTheme.windowBackground` / Android 12+ `windowSplashScreenBackground` 与 `MySplash.backgroundColor` 一致。
- Windows：需要无空窗时用现有 `showWindowOnInit: false`，库在首帧后再 `show()`。

## 不要改错的部分

- Splash **不是** `GetPage`。
- 揭开用 `isSplashFinished`，不要改回 `Get.offNamed`。
- 叠层盖住时底下首页可以已经挂上；controller 须能在服务未齐时安全等待。
- `MySplash` 尺寸在 `build` 里做 ScreenUtil，调用方仍传设计稿值。

## 做不到、也不承诺

- Flutter 第一帧和纯 Kotlin Activity 一样快（引擎税去不掉）。
- 把完整 Lottie Widget 画进 Android 系统 Splash / Windows 原生窗。
