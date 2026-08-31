# MySplash / 启动叠层：现状与改良方向

> **面向对象**：xly 维护者与准备改启动流程的消费应用  
> **目的**：写清当前 `splash:` 配置的问题、跨平台应达成的机制，以及建议的 API / 时序改动。  
> **状态**：只记录方向，本轮不改代码。

## TL;DR

| 问 | 答 |
|---|---|
| 现在 `MySplash` 是路由吗？ | **不是**。它是盖在 `GetMaterialApp` 上的叠层，`initialRoute` 已是业务首页。叠层这一摆法应保留。 |
| 现在初始化发生在哪？ | **`runApp` 之前**把 `services` 全部 `await` 完。Splash 只是事后用 Timer 揭开的装饰。 |
| 这和较好的安卓 / 跨平台做法一致吗？ | **不一致。** 引擎第一帧被服务堵住；用户先看原生空窗，再看一段与初始化无关的定时动画。 |
| 目标机制要绑 GetX 路由吗？ | **不要。** 叠层 + 一个 `Rx`/`bool` 揭开即可。GetX 继续管业务路由，不要把 Splash 做成 `/splash` 再 `offNamed`。 |
| 跨平台要不要同一套？ | **要。** Flutter 叠层在 Windows / Android / 其它桌面端长得一样；各平台只负责「引擎第一帧之前」的静帧对齐。 |

## 1. 当前实现（事实）

```text
MyApp.initialize
  → await ScreenUtil / GetStorage / 单实例 / 窗口
  → await 全部 services.registerService()     ← 挡在 runApp 前
  → runApp
  → GetMaterialApp(initialRoute = routes.first)
  → Stack 顶层盖 MySplash
  → Timer(splashDuration) → isSplashFinished = true
  → 揭开底下已经建好的首页
```

`MySplash` 本身：

- 用 Lottie + 标题，尺寸按设计稿在 `build` 里再 `.w` / `.sp`（尺寸契约例外，合理）。
- **默认循环播放** Lottie（未设 `repeat: false`）。
- 离场只看 **`splashDuration` Timer**，不看动画是否播完，也不看服务是否刚结束（服务早已结束）。
- `nextRoute` 仍在参数里，`Get.offNamed` 已注释掉，导航语义是死的。

叠层揭开用 `MyApp.isSplashFinished`（`RxBool`）。这不是 GetX **路由**绑定，只是 GetX **状态**，可以保留。

## 2. 和「较好做法」差在哪

冷启动在所有平台都有两段：

```text
A. 引擎第一帧之前     只能靠原生窗 / 系统 Splash（静帧）
B. 第一帧之后         才能画 Flutter 叠层，并在背后做重活
```

| 层级 | 当前 xly | 建议 |
|------|----------|------|
| A. 原生静帧 | 文档几乎没要求消费应用对齐 `windowBackground` / 桌面先藏窗 | 文档约定：底色 + 可选 Logo 与叠层第一帧对齐 |
| B. 第一帧何时出现 | 被 `services` 整表堵住 | `runApp` 尽快；服务在叠层**可见之后**再跑 |
| Splash 职责 | 定时装饰（init 已做完） | 「App 已有反应」的脸；必要 init 的挡板；**不是**首页数据的挡板 |
| 离场条件 | 固定 Timer | 必要 init 结束，且（若有品牌动画）**只播一圈** |
| 进首页之后 | 首页已在叠层下建好 | 保持；首页自己 skeleton / shimmer 收未完成的业务加载 |
| 与 GetX 路由 | 未做成路由（好） | 继续不要做成路由 |

传统 Java / Kotlin 也不能在点图标的第 0 毫秒跑 Activity 里的 Lottie；大家能立刻出示的都是主题静帧。Flutter 多付一笔引擎税，所以 **A 段必须有品牌静帧，B 段必须尽快出叠层**。xly 现在把重活放在 A/B 交界之前，等于把引擎税和业务税叠在原生空窗上。

Windows 上若窗口在 init 后才 `show()`，空窗不明显，问题被桌面节奏遮住。Android 真机（尤其是电视类弱设备）会把这段拉得很长。跨平台一致，指的是**机制一致**，不是「Windows 碰巧看不出来就可以维持现状」。

## 3. 目标时序（跨平台同一套）

```text
点图标
  → 原生静帧（各平台自己画，脸和 Flutter 叠层第一帧对齐）
  → runApp，尽快画出 MySplash 叠层
  → 叠层可见后，再跑 services / 其它重活
  → 必要 init 结束，并且品牌 Lottie 只播一圈（或无动画则立刻）
  → 揭开首页壳
  → 首页用 skeleton / shimmer 继续业务加载（CMS、列表等）
```

不要：

- 在 `runApp` 前 `await` 完整服务表。
- 用循环 Lottie 填等待。
- 把 Splash 做成 GetX 第一页再 `Get.offNamed`（换页会触发 SmartManagement，消费应用已多次踩过）。
- 让 Splash 等到首页数据齐了再揭开。
- 用「数小时内从后台回来就整段去掉品牌」这类过宽策略；最多给「刚切走几秒又回来」一条短窗口。

## 4. 建议改的 API（尚未实现）

按优先级，均可向后兼容地分步做：

1. **拆开 `services` 的注册时机**  
   - `runApp` 前只留：binding、ScreenUtil 尺寸、单实例、窗口句柄（桌面）、真正影响第一帧的东西。  
   - 新增例如 `servicesAfterFirstFrame` / `bootstrap`，在 `isSplashFinished == false` 且第一帧已出之后再 `await`。  
   - 旧的 `services` 若不能立刻改语义，至少在文档里标成「会推迟第一帧」，并提供新参数。

2. **离场条件改成「init × 动画」**  
   - `splashDuration` 降级为「无 Lottie 时的保底」，有 Lottie 时 `repeat: false`，`AnimationStatus.completed` 作为品牌段结束。  
   - 揭开：`bootstrapDone && (!showBrand || animationDone)`。  
   - 删掉或废弃只靠 Timer、且与片长无关的默认 2.5s。

3. **Lottie 默认不循环**  
   - `repeat: false`；加载失败则视为动画已结束，避免永远揭不开。

4. **收掉死参数**  
   - `nextRoute` 已无导航作用，标明 deprecated 或删除。  
   - 需要「无 Splash」时用 `splash: null`，不要假装还在路由跳转。

5. **给消费应用写清原生静帧清单**（包不必代做各平台工程文件）  
   - Android：`LaunchTheme.windowBackground` / Android 12+ `windowSplashScreenBackground` 与叠层底色一致；需要「第 0 毫秒有字」时用图层 + 位图，不要指望系统圆形图标演完整 Lottie。  
   - Windows：需要无空窗时配合现有 `showWindowOnInit: false` + `win_setup`，第一帧再 `show()`。  
   - 包侧可提供「建议底色 / 建议 Logo 边距」常量，方便对齐。

6. **可选：`onSplashVisible` 回调**  
   - 第一帧叠层 build 之后打一次，供消费应用启动自己的 bootstrap，而不必把重活塞进 `services` 列表。

## 5. 不要改错的部分

这些是现在就已经对的，改的时候不要退回去：

- Splash **不是** `GetPage`，首页才是 `initialRoute`。
- 揭开用 `isSplashFinished`，不要改回 `Get.offNamed`。
- 叠层盖住时底下首页可以已经挂上（controller 须能在服务未齐时安全等待）。
- `MySplash` 尺寸在 `build` 里做 ScreenUtil，调用方仍传设计稿值。

## 6. 和「完美」的距离

按上面做完，消费应用可以达到：

- 各平台同一套 Flutter 叠层脸与离场规则；
- 点开后尽快看到品牌（引擎税仍在，用原生静帧盖住）；
- 动画不滚第二圈；
- 进首页壳不必等齐业务数据。

做不到、也不该承诺的：

- Flutter 第一帧和纯 Kotlin Activity 一样快（引擎税去不掉）；
- 把完整 Lottie Widget 画进 Android 系统 Splash / Windows 原生窗（那是另一套实现，包不该代做）。
