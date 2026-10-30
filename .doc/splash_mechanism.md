# MySplash / 启动叠层

> **面向对象**：xly 维护者与消费应用  
> **目的**：写清叠层什么时候揭开、三层初始化怎么排、动画时间点怎么推、每个兜底到点做什么，以及原生启动画面怎么接  
> **相关**：`lib/src/app/splash.dart`（画面）、`lib/src/app/splash_gate.dart`（门闩）、`lib/src/app/splash_animation.dart`（素材与时间点）、`lib/src/app/boot_trace.dart`（启动阶梯）、`lib/src/app/models.dart`（`MyBootstrapTask`）

## TL;DR

| 问 | 答 |
|---|---|
| `MySplash` 是路由吗？ | **不是。** 盖在 `GetMaterialApp` 最上层，`initialRoute` 就是业务首页。 |
| 什么时候揭开？ | blocking `bootstrap` 到终态 × 画面播完，然后淡出 `fadeOutDuration`（默认 200ms）。 |
| 「画面播完」指什么？ | 内置 Lottie 停到定格帧；`brandBuilder` 上报；静态脸过了 `minVisible`。 |
| 动画要写死时长吗？ | **不要。** 定格帧和「大动作做完」从素材推；推不准时用 `holdFrame` / `motionEndFrame` 按帧号指定。 |
| 重活放哪？ | 首屏要的放 `bootstrap`；会同步占住主线程的再标 `afterSplashMotion`；首屏用不到的放 `backgroundBootstrap`。 |
| 启动慢 / 失败？ | 8 秒还没好提示「启动比平时慢」；fatal 停在失败页，给「重新启动」（应用传 `onRestart`）和「退出」。 |
| 卡在哪一步？ | `enableBootTrace: true`，看 `+毫秒 步骤` 阶梯和 `boot.lag`。 |
| 外部意图直接进页面？ | `MyApp.skipSplashThisLaunch()`。 |

## 时序

```text
点图标
  → 原生启动画面（只放底色，见「原生启动画面」）
  → MyApp.initialize 开头开始预载 Lottie（和存储、窗口初始化并行）
  → runApp 前最多再等 preloadLimit（500ms）
  → 叠层第一帧：按动画真实宽高比留好位置
  → 第一帧真正上屏，动画起表，只播一遍到定格帧
  → 两帧提交后 blocking bootstrap 开始
       ├─ 普通任务：马上按顺序跑
       └─ 第一个标了 afterSplashMotion 的任务：等动画大动作做完
  → bootstrap 到终态 且 动画停在定格帧
  → 淡出 → isSplashFinished / waitUntilSplashFinished()
  → 首页画完一帧 → backgroundBootstrap（两步之间让一帧）→ isBackgroundReady
```

`services` 语义没改：仍在 `runApp` 前跑，会挡住第一帧。能挪的初始化请改走 `bootstrap`。

## 揭开公式

```text
揭开 = blocking bootstrap 到终态（ready / degraded） × 画面播完
画面播完 = 内置 Lottie 停在定格帧
         | brandBuilder 报 reportPresentationDone（brandAnimates: true）
         | 静态脸过了 minVisible
         | 兜底：素材加载失败 / brandTimeout（一直没开播）/ 播放看门狗（开播后一直没停到定格）
```

满足后先淡出，淡完才算离场。

- **fatal 不揭开**：叠层停在失败页。
- **blocking 超时**（`bootstrapTimeout`，默认 20 秒）：后面没有 fatal 任务时按 degraded 揭开；否则失败页写「启动初始化超时」，详情是「停在 <任务标签>」。
- **终态不回头**：超时揭开后还在跑的任务照常跑完，失败只记日志；首页已经可用之后的任何错误都不再盖失败页。
- **`isSplashFinished` 只会从 `false` 变 `true`**。跳过叠层之后才 fatal 的，它仍为 `true`，失败页照样盖上来：判断失败页要看 `splashPhase == MySplashPhase.fatal`。

消费方能读的状态：

| 读什么 | 什么时候变 |
|---|---|
| `MyApp.bootstrapReady`（Future）/ `isBootstrapReady` | blocking 到终态；fatal 时 Future 以错误完成 |
| `MyApp.isBootstrapSlow` | 超过 `bootstrapSlowAfter` 还没到终态 |
| `MyApp.waitUntilSplashFinished()` / `isSplashFinished` | 叠层第一次离场（淡出走完、被跳过、没有叠层） |
| `MyApp.splashPhase` | `running` → `ready` / `degraded` → `finished`，或 `fatal` |
| `MyApp.splashFatalMessage` / `splashFatalDetail` | fatal 时的总述，和「任务标签：错误第一行」 |
| `MyApp.backgroundReady`（Future）/ `isBackgroundReady` | 后台层跑完；blocking fatal 时 Future 以错误完成 |

叠层盖着时底下的首页已经挂上了，首页的 controller 要能在服务没齐时等 `MyApp.bootstrapReady`。

`nextRoute`、`splashDuration` 已废弃，不再参与揭开。无品牌脸传 `splash: null`（无叠层时视为已揭开，`bootstrap` 仍会跑）。

## 三层初始化

| 放哪 | 放什么 | 什么时候跑 | 失败 |
|---|---|---|---|
| `bootstrap` | 首屏离不开的：会话、配置、数据库 | 两帧提交后，按顺序 | 按 `severity`：fatal 停在失败页；degraded / optional 照常揭开 |
| `bootstrap` + `afterSplashMotion` | 首屏离不开、又会同步占住主线程的：大字典、建索引、首次解压 | 第一个标了的任务等动画大动作做完（最多 `motionGateLimit`） | 同上 |
| `backgroundBootstrap` | 首屏用不到的：预热缓存、清旧文件、拉非首屏数据 | 叠层揭开、首页画完一帧后（最多等 `backgroundBootstrapWaitLimit`），两步之间让一帧 | 只记日志 |

`bootstrap` 是顺序执行的：第一个标了 `afterSplashMotion` 的任务开始等，排在它后面的任务也跟着等。不占主线程的放前面。

```dart
await MyApp.initialize(
  splash: const MySplash(lottieAssetPath: 'assets/animation/splash.json'),
  bootstrap: [
    MyBootstrapTask.run(() => restoreSession(), debugLabel: 'session'),
    MyBootstrapTask.putAsync<Db>(() => Db.open(), debugLabel: 'db'),
    // 同步建索引会让动画掉帧：等大动作做完再跑。
    MyBootstrapTask.run(
      () => SearchIndex.build(),
      debugLabel: 'search-index',
      afterSplashMotion: true,
    ),
  ],
  backgroundBootstrap: [
    MyBootstrapTask.run(() => ImageCache.warmUp(), debugLabel: 'warm-cache'),
  ],
);
```

`debugLabel` 会出现在失败页详情和启动阶梯里，建议都写上。

### run 与 putAsync

`run<T>` 的返回类型由闭包推断，不会预先钉成 `void`。登记异步 GetX 服务用 `putAsync<T>`（可带 `permanent` / `tag`）。`runApp` 前的正式口继续用 `MyService<Foo>(asyncService: ...)`。

若先写成 `Future<void> Function() f = () => Get.putAsync(...)` 再 `run(f)`，GetX 仍会打 `Instance "void"`。任务结束后（含中途抛错）会检查无 tag 的 `void` / `dynamic`，抛 `MyBootstrapContractError`，门闩按 fatal 停住。GetX 注册键含 tag，公开 API 枚举不了，带 tag 的擦除登记检测不到；直接 `run(() => Get.putAsync(..., tag: ...))` 仍按真实类型推断。

`putAsync` 不等 `onInit()`：需要预先初始化时，工厂里做完再返回实例。详见 [异步服务指南](async_service_guide.md)。

## 启动动画

### 预载、留位置、起表

- `MyApp.initialize` 开头就按 `lottieAssetPath` 开始加载，组合和时间点都在后台 isolate 里解析，`runApp` 前最多等 `preloadLimit`。
- 素材从 `rootBundle` 读：别的包里的素材写完整路径 `packages/<包名>/…`；不支持自定义 `AssetBundle`，要用的话走 `brandBuilder` 自己画。
- 预载到了：叠层第一帧就按素材宽高比留好位置，直接开播。
- 没赶上：先按 `lottieWidth` × `lottieWidth`（给了 `lottieHeight` 就按它）留位置。载好后先画出第 0 帧，再起表。动画出现时标题不会被挤走。
- 起表等第一帧真正上屏（最多 `firstFrameLimit`）。原生启动画面还盖着时就起表，用户会错过动画开头。
- 只播一遍，停在定格帧，不循环。
- 标题只排一行，放不下时整行缩小。

### 两个时间点

[`MySplashAnimationTiming.fromLottieJson`](../lib/src/app/splash_animation.dart) 从素材推出两个 0~1 的进度：

1. **`motionEnd`（大动作做完）**
   - 取所有没隐藏的图层里，动画属性最晚的关键帧。
   - 只算图层在画面上那段时间：出现前就做完的不算，消失后的截到消失那帧。空层、相机带着别的图层动，不按自己的出入点截。
   - 预合成里的关键帧按 `st + t × sr` 换回主时间轴；带时间重映射或倒放的预合成，只看外层自己的关键帧。
   - 图层出现、消失这种一帧的跳变不算动作：主线程晚一点画出来，看不出卡。
   - 标了 `afterSplashMotion` 的任务从这里开始跑。
2. **`hold`（定格）**
   - 大动作做完那一刻还在画面上的内容图层（预合成、纯色、图片、形状、文字；隐藏层不算，遮罩源要算），就是最后的画面。
   - 其中最早消失的那层的前一帧就是定格。收尾几帧常是元素被收走、遮罩结束，停在最后一帧会露出半空的画面。
   - 中途一闪而过的图层不影响定格。
   - 播到这里才算播完。

示例素材 `example/assets/animation/splash_loading.json`（96 帧）推出来是 `motionEnd ≈ 63.44 帧`、`hold = 93 帧`：遮罩源在第 94 帧结束，主体随之消失，所以停在 93。

推不准的素材用帧号覆盖（帧号和 Lottie 编辑器里看到的一致）：

| 素材 | 推出来的问题 | 怎么办 |
|---|---|---|
| 用透明度淡出收尾 | 淡出本身算动作，定格落在淡完之后 | `holdFrame` 设在淡出开始前 |
| 时间重映射、倒放的预合成 | 里面的动作只按外层关键帧算 | `motionEndFrame` |
| 表达式驱动、没有关键帧 | 推不出动作 | 两个都指定 |
| dotLottie（zip） | 不读结构，整段播完 | 两个都指定 |

只给 `holdFrame` 时，`motionEnd` 不会晚于新的定格。

### 做素材的建议

- 第 0 帧只留底色，和原生启动画面一致，交接时看不出切换。
- 大动作放前面，后面留一段不动的定格：bootstrap 还没好时，用户看的就是这一格。
- 收尾要收走元素的话，放在定格之后；不要只靠透明度淡出收尾，否则要设 `holdFrame`。
- 体积尽量控制在两三百 KB 以内。解析在后台 isolate，但读文件和内嵌图片解码仍要时间。

## 兜底与默认值

| 参数 | 默认 | 到点做什么 |
|---|---|---|
| `MySplash.minVisible` | 300ms | 静态脸算播完，防止闪一帧 |
| `MySplash.preloadLimit` | 500ms | 不再等预载，先出第一帧 |
| `MySplash.firstFrameLimit` | 1s | 不再等第一帧上屏，动画起表 |
| `MySplash.brandTimeout` | 8s | 一直没开播（素材挂住）：算播完。开播后不再计时 |
| `MySplash.playLimit` | 10s | `brandBuilder` 开播后一直没报播完：算播完。内置 Lottie 按「播到定格的时长 + 2 秒」 |
| `MySplash.motionGateLimit` | 推导 | `afterSplashMotion` 不再等。不传时：预载到了按「大动作时长 + `firstFrameLimit` + 1 秒」，否则 5 秒；`Duration.zero` 不等 |
| `MySplash.fadeOutDuration` | 200ms | 淡出。画面没回报淡完时，淡出时长再加 1 秒直接揭开；`Duration.zero` 直接拿掉 |
| `MySplash.statusLineAfter` | 1.5s | 画面播完还没揭开：显示「正在启动…」；`null` 不显示 |
| `bootstrapSlowAfter` | 8s | 显示「启动比平时慢」（传了 `onRestart` 时带重启按钮），不揭开；`Duration.zero` 不提示 |
| `bootstrapTimeout` | 20s | 后面没有 fatal 任务：按 degraded 揭开；否则失败页；`Duration.zero` 不设 |
| `backgroundBootstrapWaitLimit` | 10s | 叠层还没揭开，后台层也开始 |
| 等两帧提交（内部） | 3s | 一直没有帧（息屏、首帧被推迟）：照常开始 bootstrap |

后五项是 `MyApp.initialize` 的参数，其余在 `MySplash` 上。

## 启动慢、失败、重启

- **启动慢**：一行提示；传了 `onRestart` 时带「重新启动」，不给「退出」。到终态后提示收起。
- **失败页**：一句总述（有没有 `onRestart` 措辞不同）+ 详情（`splashFatalDetail`，最多两行）+ 按钮。
- **`onRestart`**：`Future<bool> Function()`，由应用实现：桌面一般起新进程再退出，安卓重建 Activity 或重启进程。重启已经在进行就返回 `true`；返回 `false` 或抛错时提示「没能自动重启，请手动关掉再打开」。不传就只有「退出」。
- **「退出」**：调 `MyApp.exit()`。`showExitButton` 不传时 iOS 不显示（系统不允许应用自己退出），其余平台显示。
- **遥控 / 键盘**：
  - 按钮出现时抢到焦点，撤掉时把焦点还给原来的位置。
  - 确定、回车、空格、手柄 A 触发；左右键在按钮间移动。
  - 上下键吞掉，焦点不会漏到盖在下面的首页。
- **文案**：全部在 `MySplashTexts`，可整体替换。

## 自定义品牌区和说明区

### brandBuilder

```dart
splash: MySplash(
  brandAnimates: true,
  brandBuilder: (context, handle) => BrandAnimation(
    onStarted: handle.reportStarted,
    onMotionDone: handle.reportMotionDone,
    onSettled: handle.reportPresentationDone,
  ),
),
```

- 三个上报都幂等。只报 `reportPresentationDone` 时，前两个一并算作已发生；报了「大动作做完」也算开播。
- 不设 `brandAnimates` 时按静态脸处理（过 `minVisible` 算播完），不用上报。`brandAnimates` 只对 `brandBuilder` 有效。
- 自己画 Lottie 时可以用 `MySplashClip.load(path)` / `peek(path)` 拿同一份预载结果和时间点。

### captionBuilder

```dart
captionBuilder: (context, status) {
  if (status.isFatal) {
    return FailurePanel(
      detail: status.fatalDetail,
      onRestart: status.canRestart ? status.restart : null,
      onExit: status.canExit ? status.exit : null,
    );
  }
  if (status.isSlow) return const Text('还在准备数据…');
  if (status.isWaiting) return const Text('正在启动…');
  return const SizedBox.shrink();
},
```

替换后焦点要自己管：电视上失败页的按钮要能直接按确定。

## 跳过叠层

`MyApp.skipSplashThisLaunch()` 给外部意图用（通知、深链、投屏、打开文件直接进目标页），本进程内有效：

- `MyApp.initialize` 之前调用：叠层从一开始就不出现，也不预载动画；bootstrap 照常跑，`afterSplashMotion` 不用等。
- 盖着时调用：立刻拿掉，不淡出。
- 之后遇到 fatal，失败页仍会盖上来（`isSplashFinished` 保持 `true`，看 `splashPhase`）。

### 用户想关掉开屏动画

偏好由应用自己存，在 `MyApp.initialize` 之前要能读到（例如先 `MyStorage.ensureInitialized`）。读到「关」就先调 `MyApp.skipSplashThisLaunch()`，`splash` 照常传。不要改成传 `splash: null`：

| | 先调 `skipSplashThisLaunch()` | 传 `splash: null` |
|---|---|---|
| 动画和预载 | 不播，不预载 | 不播，不预载 |
| 启动失败 | 失败页照样盖上 | 没有失败页 |
| 桌面窗口 | 仍等首帧再出示 | 默认马上出示，可能先闪一下空白窗口 |

关掉之后首页直接出来，bootstrap 在下面接着跑，首页要能在服务没齐时等 `MyApp.bootstrapReady`。example 第一个 tab「启动测试」的「下次启动播放启动画面」就是这样做的。

## 启动阶梯（MyBootTrace）

- 打开：`MyApp.initialize(enableBootTrace: true)`，或在调用前设 `MyBootTrace.enabled = true`。默认关闭。
- 每一步一行 `+<毫秒> <步骤> <细节>`，毫秒从第一次打点算起。先走 `debugPrint('[XlyBoot] …')`（安卓即 logcat）：文件日志还没建好时也看得到。
- `MyBootTrace.attachSink(写应用日志)` 接上之后，之前缓冲的行（最多 64 行）按原顺序补写；更早的只在 `debugPrint` 里。
- 应用自己的步骤：`MyBootTrace.mark('home.first-data', '12 items')`。
- 卡顿探针：打开时主线程一次被占住 120ms 以上，记一行 `boot.lag <毫秒>ms after <最近一步>`。后台层跑完 3 秒后停，最长跑 60 秒。它只说明「这一步之后主线程被占住了」，具体是哪段代码要在可疑处加打点再看。

内置步骤：

| 步骤 | 含义 |
|---|---|
| `app.initialize` / `app.runApp` | 初始化开始 / 调 `runApp` |
| `splash.preload` / `splash.preload-late` | `runApp` 前动画已载好 / 没赶上 |
| `splash.clip` | 动画载好：时长、`motionEnd`、`hold` |
| `splash.frame-wait` / `splash.first-frames` | 开始等两帧 / 两帧已提交 |
| `splash.animation-start` / `splash.animation` | 开播 / 播到定格 |
| `bootstrap.start` / `bootstrap.task` | bootstrap 开始 / 开始跑某个任务 |
| `bootstrap.wait-motion` / `splash.motion-done` | 开始等大动作 / 大动作做完 |
| `bootstrap.ready` / `bootstrap.degraded` / `bootstrap.fatal` | blocking 终态 |
| `splash.presented` / `splash.dismiss` / `splash.gone` | 画面播完 / 开始淡出 / 离场 |
| `splash.ui-settled` / `background.task` / `background.done` | 首页画完一帧 / 后台任务 / 后台层跑完 |
| `splash.skip` | 本次启动跳过叠层 |
| `*-timeout`、`bootstrap.slow`、`bootstrap.error`、`splash.clip-failed`、`background.error` | 对应的兜底或失败 |

## 原生启动画面（包不代做工程文件）

引擎第一帧之前只能靠原生窗口，消费应用自己对齐。

Android：

- **系统启动画面只放底色**：Android 12+ 的 `windowSplashScreenAnimatedIcon` 指向一张透明图，`windowSplashScreenBackground` 等于 `MySplash.backgroundColor`。否则系统画面中间的图标和叠层第一帧对不上，会跳一下。
- **`LaunchTheme` 和 `NormalTheme` 的 `android:windowBackground` 用同一底色**：系统启动画面收起后、Flutter 第一帧之前看到的是 `NormalTheme`。
- **两份 `launch_background.xml` 都要改**：Flutter 模板生成 `drawable/` 和 `drawable-v21/` 各一份，API 21 以上用的是 v21 那份，只改一份等于没改。
- **`values-night/styles.xml`**：深色模式用它。要么和白天同色，要么删掉；否则深色模式下先闪另一种底色。
- **看交接效果用 profile / release 包**：debug 包第一帧慢得多，看到的空档不代表正式包。
- **息屏、锁屏时系统不给画面帧**：门闩最多等 3 秒就开始 bootstrap，但动画要等亮屏才走，由 `brandTimeout` 和播放看门狗兜底。
- **用 TextureView 承载 Flutter 的设备**（`RenderMode.texture`）第一帧上屏更晚；动画按「第一帧真正上屏」起表，不受影响。

Windows：需要无空窗时用 `showWindowOnInit: true`（有 `splash` 时 `deferShowUntilFirstFrame` 默认开启），并配合 `dart run xly:win_setup`。托盘静默驻留用 `showWindowOnInit: false`，不要和防闪共用这个开关。详见 [desktop_window_launch.md](desktop_window_launch.md)。

## 不要改错的部分

- Splash **不是** `GetPage`；揭开用 `isSplashFinished`，不要改回 `Get.offNamed`（换页会触发 SmartManagement）。
- 不要用循环 Lottie 填等待，也不要写固定时长（`splashDuration` 已废弃）。
- 不要让叠层等到首页数据齐了再揭开：首页自己画 skeleton。
- 会同步占住主线程的 bootstrap 任务要标 `afterSplashMotion`，否则动画掉帧。
- 判断失败页看 `splashPhase`，不要只看 `isSplashFinished`。
- 画面在拆树（`dispose`）时不写 Rx、不挪焦点，推到拆树之后再做；新增上报口也要守住这一条，否则父级 `Obx` 会报 locked tree。
- `MySplash` 尺寸参数是设计稿值，`build` 里做一次 ScreenUtil 换算，调用方不要再套 `.w` / `.sp`。

## 做不到、也不承诺

- Flutter 第一帧和纯原生 Activity 一样快（引擎税去不掉）。
- 把 Lottie 画进 Android 系统启动画面或 Windows 原生窗口。
- 取消已经在跑的 bootstrap 任务：超时揭开后它们照常跑完，失败只记日志。
- 推出表达式驱动、或用透明度淡出收尾的素材的定格帧：用 `holdFrame` 指定。
