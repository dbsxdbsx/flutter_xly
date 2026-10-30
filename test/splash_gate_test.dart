import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xly/xly.dart';

class _LateProbe extends GetxService {
  Future<_LateProbe> init() async => this;
}

void main() {
  setUp(MyApp.debugResetSplashGate);
  tearDown(() {
    MyApp.debugResetSplashGate();
    Get.reset();
  });

  MySplashGate attachGate({
    bool overlay = true,
    bool lottie = false,
    bool staticBrand = true,
    Duration minVisible = Duration.zero,
    Duration brandTimeout = Duration.zero,
    Duration playLimit = const Duration(seconds: 10),
    Duration frameWaitLimit = const Duration(seconds: 3),
    Duration bootstrapTimeout = Duration.zero,
    Duration bootstrapSlowAfter = Duration.zero,
    Duration motionGateLimit = const Duration(seconds: 5),
    Duration fadeOutDuration = const Duration(milliseconds: 200),
    Duration backgroundWaitLimit = const Duration(seconds: 10),
    List<MyBootstrapTask>? tasks,
    List<MyBootstrapTask>? backgroundTasks,
  }) {
    final gate = MySplashGate(
      hasOverlay: overlay,
      hasBrandLottie: lottie,
      hasStaticBrandFace: staticBrand,
      minVisible: minVisible,
      brandTimeout: brandTimeout,
      playLimit: playLimit,
      frameWaitLimit: frameWaitLimit,
      bootstrapTimeout: bootstrapTimeout,
      bootstrapSlowAfter: bootstrapSlowAfter,
      motionGateLimit: motionGateLimit,
      fadeOutDuration: fadeOutDuration,
      backgroundWaitLimit: backgroundWaitLimit,
      tasks: tasks,
      backgroundTasks: backgroundTasks,
    );
    gate.attachToApp();
    return gate;
  }

  testWidgets('等首帧时每一帧都主动请求，静态界面也不会卡住', (tester) async {
    await tester.pumpWidget(const SizedBox());
    var ran = false;
    final gate = attachGate(
      overlay: false,
      staticBrand: false,
      tasks: [
        MyBootstrapTask.run(() async {
          ran = true;
        }),
      ],
    );

    final start = gate.startAfterFirstFrame();
    for (var frame = 0; frame < 8 && !ran; frame++) {
      expect(
        tester.binding.hasScheduledFrame,
        isTrue,
        reason: '第 ${frame + 1} 帧没人请求，画面不动时会一直等下去',
      );
      await tester.pump();
    }
    await start;

    expect(ran, isTrue);
    expect(MyApp.isBootstrapReady.value, isTrue);
  });

  testWidgets('无叠层时 attach 即视为揭开，bootstrap 仍会跑', (tester) async {
    var ran = false;
    final gate = attachGate(
      overlay: false,
      lottie: false,
      staticBrand: false,
      tasks: [
        MyBootstrapTask.run(() async {
          ran = true;
        }),
      ],
    );

    expect(MyApp.isSplashFinished.value, isTrue);
    expect(MyApp.isBootstrapReady.value, isFalse);

    await gate.debugOnFirstFrameSubmitted();
    await tester.pump();

    expect(ran, isTrue);
    expect(MyApp.isBootstrapReady.value, isTrue);
    expect(MyApp.splashPhase.value, MySplashPhase.finished);
    await MyApp.bootstrapReady;
  });

  testWidgets('有 Lottie 时 bootstrap 先结束也不揭开', (tester) async {
    final gate = attachGate(lottie: true, staticBrand: false);

    await gate.debugOnFirstFrameSubmitted();
    await tester.pump();

    expect(MyApp.isBootstrapReady.value, isTrue);
    expect(MyApp.isSplashFinished.value, isFalse);

    MyApp.reportBrandAnimationDone();
    expect(MyApp.isSplashFinished.value, isTrue);
    expect(MyApp.splashPhase.value, MySplashPhase.finished);
  });

  testWidgets('动画先结束时等 bootstrap', (tester) async {
    final started = Completer<void>();
    final release = Completer<void>();
    final gate = attachGate(
      lottie: true,
      staticBrand: false,
      tasks: [
        MyBootstrapTask.run(() async {
          started.complete();
          await release.future;
        }),
      ],
    );

    final bootstrap = gate.debugOnFirstFrameSubmitted();
    await tester.pump();
    await started.future;
    MyApp.reportBrandAnimationDone();
    expect(MyApp.isSplashFinished.value, isFalse);

    release.complete();
    await bootstrap;
    await tester.pump();

    expect(MyApp.isSplashFinished.value, isTrue);
  });

  testWidgets('静态品牌脸未到 minVisible 不揭开', (tester) async {
    final gate = attachGate(
      lottie: false,
      staticBrand: true,
      minVisible: const Duration(milliseconds: 40),
    );

    await gate.debugOnFirstFrameSubmitted();
    expect(MyApp.isSplashFinished.value, isFalse);

    await tester.pump(const Duration(milliseconds: 50));
    expect(MyApp.isSplashFinished.value, isTrue);
  });

  testWidgets('brandTimeout 视为动画结束', (tester) async {
    final gate = attachGate(
      lottie: true,
      staticBrand: false,
      brandTimeout: const Duration(milliseconds: 20),
    );

    await gate.debugOnFirstFrameSubmitted();
    expect(MyApp.isSplashFinished.value, isFalse);

    await tester.pump(const Duration(milliseconds: 30));
    expect(MyApp.isSplashFinished.value, isTrue);
  });

  testWidgets('fatal 任务不揭开且 bootstrapReady 失败', (tester) async {
    final gate = attachGate(
      lottie: false,
      staticBrand: true,
      minVisible: Duration.zero,
      tasks: [
        MyBootstrapTask.run(
          () async => throw StateError('boom'),
          severity: MyBootstrapSeverity.fatal,
          debugLabel: 'fatal-task',
        ),
      ],
    );

    final ready = expectLater(MyApp.bootstrapReady, throwsA(isA<StateError>()));
    await gate.debugOnFirstFrameSubmitted();
    await tester.pump();
    await ready;

    expect(MyApp.splashPhase.value, MySplashPhase.fatal);
    expect(MyApp.isSplashFinished.value, isFalse);
    expect(MyApp.isBootstrapReady.value, isFalse);
  });

  testWidgets('degraded 失败仍揭开', (tester) async {
    final gate = attachGate(
      lottie: false,
      staticBrand: true,
      minVisible: Duration.zero,
      tasks: [
        MyBootstrapTask.run(
          () async => throw StateError('soft'),
          severity: MyBootstrapSeverity.degraded,
        ),
      ],
    );

    await gate.debugOnFirstFrameSubmitted();
    await tester.pump();

    expect(MyApp.splashPhase.value, MySplashPhase.finished);
    expect(MyApp.isSplashFinished.value, isTrue);
    expect(MyApp.isBootstrapReady.value, isTrue);
    await MyApp.bootstrapReady;
  });

  testWidgets('optional 失败仍是 ready', (tester) async {
    final gate = attachGate(
      lottie: false,
      staticBrand: true,
      minVisible: Duration.zero,
      tasks: [
        MyBootstrapTask.run(
          () async => throw StateError('skip'),
          severity: MyBootstrapSeverity.optional,
        ),
      ],
    );

    await gate.debugOnFirstFrameSubmitted();
    await tester.pump();

    expect(MyApp.isSplashFinished.value, isTrue);
    expect(MyApp.isBootstrapReady.value, isTrue);
  });

  testWidgets('静态品牌脸挂着时过了 minVisible 先淡出，淡完才揭开', (tester) async {
    final gate = attachGate(
      lottie: false,
      staticBrand: true,
      minVisible: const Duration(milliseconds: 20),
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(800, 600),
        builder: (_, __) => const MaterialApp(
          home: MySplash(appTitle: 'Hi'),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(MySplash.overlayKey), findsOneWidget);

    final gone = MyApp.waitUntilSplashFinished();
    var goneDone = false;
    unawaited(gone.then((_) => goneDone = true));

    await gate.debugOnFirstFrameSubmitted();
    expect(MyApp.isSplashFinished.value, isFalse);
    await tester.pump(const Duration(milliseconds: 30));
    expect(gate.isDismissing, isTrue);
    expect(MyApp.isSplashFinished.value, isFalse);
    expect(MyApp.splashPhase.value, MySplashPhase.ready);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(MyApp.isSplashFinished.value, isTrue);
    expect(MyApp.splashPhase.value, MySplashPhase.finished);
    expect(goneDone, isTrue);
  });

  testWidgets('标了 afterSplashMotion 的任务等动画大动作做完再跑', (tester) async {
    final order = <String>[];
    final gate = attachGate(
      lottie: true,
      staticBrand: false,
      tasks: [
        MyBootstrapTask.run(() async => order.add('early')),
        MyBootstrapTask.run(
          () async => order.add('heavy'),
          afterSplashMotion: true,
        ),
        MyBootstrapTask.run(() async => order.add('after')),
      ],
    );

    final bootstrap = gate.debugOnFirstFrameSubmitted();
    await tester.pump();
    expect(order, ['early']);
    expect(MyApp.isBootstrapReady.value, isFalse);

    gate.handle.reportMotionDone();
    await bootstrap;
    expect(order, ['early', 'heavy', 'after']);
    expect(MyApp.isBootstrapReady.value, isTrue);
    expect(MyApp.isSplashFinished.value, isFalse, reason: '还没停到定格帧');

    gate.handle.reportPresentationDone();
    expect(MyApp.isSplashFinished.value, isTrue);
  });

  testWidgets('动画迟迟不报大动作做完时，到 motionGateLimit 照常往下跑', (tester) async {
    var heavy = false;
    final gate = attachGate(
      lottie: true,
      staticBrand: false,
      motionGateLimit: const Duration(milliseconds: 50),
      tasks: [
        MyBootstrapTask.run(() async => heavy = true, afterSplashMotion: true),
      ],
    );

    final bootstrap = gate.debugOnFirstFrameSubmitted();
    await tester.pump(const Duration(milliseconds: 40));
    expect(heavy, isFalse);
    await tester.pump(const Duration(milliseconds: 20));
    await bootstrap;
    expect(heavy, isTrue);
  });

  testWidgets('静态品牌脸没有大动作，afterSplashMotion 不用等', (tester) async {
    var heavy = false;
    final gate = attachGate(
      tasks: [
        MyBootstrapTask.run(() async => heavy = true, afterSplashMotion: true),
      ],
    );

    await gate.debugOnFirstFrameSubmitted();
    expect(heavy, isTrue);
  });

  testWidgets('开播之后 brandTimeout 不再截断长动画', (tester) async {
    final gate = attachGate(
      lottie: true,
      staticBrand: false,
      brandTimeout: const Duration(milliseconds: 20),
    );

    gate.handle.reportStarted();
    await gate.debugOnFirstFrameSubmitted();
    await tester.pump(const Duration(milliseconds: 40));
    expect(MyApp.isSplashFinished.value, isFalse);

    gate.handle.reportPresentationDone();
    expect(MyApp.isSplashFinished.value, isTrue);
  });

  testWidgets('bootstrap 超过 bootstrapSlowAfter 只提示慢，不揭开', (tester) async {
    final release = Completer<void>();
    final gate = attachGate(
      bootstrapSlowAfter: const Duration(milliseconds: 30),
      tasks: [
        MyBootstrapTask.run(() => release.future, debugLabel: 'sync-db'),
      ],
    );

    final bootstrap = gate.debugOnFirstFrameSubmitted();
    await tester.pump(const Duration(milliseconds: 20));
    expect(MyApp.isBootstrapSlow.value, isFalse);
    await tester.pump(const Duration(milliseconds: 20));
    expect(MyApp.isBootstrapSlow.value, isTrue);
    expect(MyApp.isSplashFinished.value, isFalse);

    release.complete();
    await bootstrap;
    expect(MyApp.isBootstrapSlow.value, isFalse);
    expect(MyApp.isSplashFinished.value, isTrue);
  });

  testWidgets('fatal 详情带出错任务的标签和错误第一行', (tester) async {
    final gate = attachGate(
      tasks: [
        MyBootstrapTask.run(
          () async => throw StateError('boom\nat line 2'),
          severity: MyBootstrapSeverity.fatal,
          debugLabel: 'load-config',
        ),
      ],
    );

    final ready = expectLater(MyApp.bootstrapReady, throwsA(isA<StateError>()));
    await gate.debugOnFirstFrameSubmitted();
    await ready;

    expect(MyApp.splashFatalMessage, '启动初始化失败');
    expect(MyApp.splashFatalDetail, 'load-config：Bad state: boom');
    expect(gate.fatalDetail, MyApp.splashFatalDetail);
  });

  testWidgets('后台层等揭开后再跑，失败只记日志', (tester) async {
    final order = <String>[];
    final gate = attachGate(
      tasks: [MyBootstrapTask.run(() async => order.add('blocking'))],
      backgroundTasks: [
        MyBootstrapTask.run(
          () async {
            order.add('bg-fail');
            throw StateError('warm cache');
          },
          debugLabel: 'warm-cache',
        ),
        MyBootstrapTask.run(() async => order.add('bg-ok')),
      ],
    );

    await gate.debugOnFirstFrameSubmitted();
    expect(MyApp.isSplashFinished.value, isTrue);
    expect(order, ['blocking'], reason: '首页还没画完一帧，后台层不能开始');
    expect(MyApp.isBackgroundReady.value, isFalse);

    // 不带时长的 pump 不推进假时钟，两步之间让出用的零延时 Timer 要靠 elapse。
    for (var i = 0; i < 6 && !MyApp.isBackgroundReady.value; i++) {
      await tester.pump(Duration.zero);
    }
    expect(MyApp.isBackgroundReady.value, isTrue);
    await MyApp.backgroundReady;

    expect(order, ['blocking', 'bg-fail', 'bg-ok']);
    expect(MyApp.isBackgroundReady.value, isTrue);
    expect(MyApp.splashPhase.value, MySplashPhase.finished);
  });

  testWidgets('blocking fatal 时后台层不跑，backgroundReady 以错误完成', (tester) async {
    var ran = false;
    final gate = attachGate(
      tasks: [
        MyBootstrapTask.run(
          () async => throw StateError('boom'),
          severity: MyBootstrapSeverity.fatal,
        ),
      ],
      backgroundTasks: [MyBootstrapTask.run(() async => ran = true)],
    );

    final background =
        expectLater(MyApp.backgroundReady, throwsA(isA<StateError>()));
    await gate.debugOnFirstFrameSubmitted();
    await tester.pump();
    await background;
    expect(ran, isFalse);
  });

  testWidgets('initialize 前要求跳过时叠层从一开始就不出现', (tester) async {
    MyApp.skipSplashThisLaunch();
    var ran = false;
    final gate = attachGate(
      lottie: true,
      staticBrand: false,
      tasks: [
        MyBootstrapTask.run(() async => ran = true, afterSplashMotion: true),
      ],
    );

    expect(MyApp.isSplashFinished.value, isTrue);
    await MyApp.waitUntilSplashFinished();

    await gate.debugOnFirstFrameSubmitted();
    expect(ran, isTrue, reason: '跳过时没有动画，动作闸门不用等');
    expect(MyApp.isBootstrapReady.value, isTrue);
    expect(MyApp.splashPhase.value, MySplashPhase.finished);
  });

  testWidgets('盖着时要求跳过：立刻拿掉、不淡出', (tester) async {
    final release = Completer<void>();
    final gate = attachGate(
      lottie: true,
      staticBrand: false,
      tasks: [MyBootstrapTask.run(() => release.future)],
    );

    final bootstrap = gate.debugOnFirstFrameSubmitted();
    await tester.pump();
    expect(MyApp.isSplashFinished.value, isFalse);

    MyApp.skipSplashThisLaunch();
    expect(MyApp.isSplashFinished.value, isTrue);
    expect(gate.isDismissing, isFalse);

    release.complete();
    await bootstrap;
    expect(MyApp.isBootstrapReady.value, isTrue);
  });

  testWidgets('跳过之后遇到 fatal：已离场不回头，phase 变 fatal 让失败页盖上', (tester) async {
    MyApp.skipSplashThisLaunch();
    final gate = attachGate(
      tasks: [
        MyBootstrapTask.run(
          () async => throw StateError('boom'),
          severity: MyBootstrapSeverity.fatal,
        ),
      ],
    );
    expect(MyApp.isSplashFinished.value, isTrue);

    final ready = expectLater(MyApp.bootstrapReady, throwsA(isA<StateError>()));
    await gate.debugOnFirstFrameSubmitted();
    await ready;

    expect(MyApp.splashPhase.value, MySplashPhase.fatal);
    expect(MyApp.isSplashFinished.value, isTrue);
    expect(gate.isFinished, isTrue);
  });

  testWidgets('自定义品牌区开播后一直不报播完，到 playLimit 按播完处理', (tester) async {
    final gate = attachGate(
      lottie: true,
      staticBrand: false,
      brandTimeout: const Duration(milliseconds: 30),
      playLimit: const Duration(milliseconds: 100),
    );
    await gate.debugOnFirstFrameSubmitted();
    gate.handle.reportStarted();

    await tester.pump(const Duration(milliseconds: 50));
    expect(MyApp.isSplashFinished.value, isFalse,
        reason: '开播后 brandTimeout 已作废');
    await tester.pump(const Duration(milliseconds: 60));
    expect(MyApp.isSplashFinished.value, isTrue);
  });

  testWidgets('只报了大动作做完也算开播，同样换成 playLimit 计时', (tester) async {
    final gate = attachGate(
      lottie: true,
      staticBrand: false,
      brandTimeout: const Duration(milliseconds: 30),
      playLimit: const Duration(milliseconds: 100),
    );
    await gate.debugOnFirstFrameSubmitted();
    gate.handle.reportMotionDone();

    await tester.pump(const Duration(milliseconds: 50));
    expect(MyApp.isSplashFinished.value, isFalse);
    await tester.pump(const Duration(milliseconds: 60));
    expect(MyApp.isSplashFinished.value, isTrue);
  });

  testWidgets('一直没有帧（息屏）时，到 frameWaitLimit 也开始 bootstrap', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    var ran = false;
    final gate = attachGate(
      overlay: false,
      staticBrand: false,
      frameWaitLimit: const Duration(milliseconds: 100),
      tasks: [MyBootstrapTask.run(() async => ran = true)],
    );

    final start = gate.startAfterFirstFrame();
    await tester.pump(const Duration(milliseconds: 60));
    expect(ran, isFalse);
    await tester.pump(const Duration(milliseconds: 60));
    await start;
    expect(ran, isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets('bootstrap 超时按 degraded 揭开后，迟到的契约错误只记日志', (tester) async {
    final release = Completer<void>();
    Future<void> registerLate() async {
      await release.future;
      await Get.putAsync<void>(() => _LateProbe().init());
    }

    final gate = attachGate(
      bootstrapTimeout: const Duration(milliseconds: 50),
      tasks: [MyBootstrapTask.run(registerLate, debugLabel: 'late-service')],
    );

    final bootstrap = gate.debugOnFirstFrameSubmitted();
    await tester.pump(const Duration(milliseconds: 60));
    await bootstrap;
    expect(MyApp.isSplashFinished.value, isTrue);
    expect(MyApp.isBootstrapReady.value, isTrue);

    release.complete();
    await tester.pump();
    await tester.pump();

    expect(MyApp.splashPhase.value, MySplashPhase.finished);
    expect(MyApp.isBootstrapReady.value, isTrue);
    expect(MyApp.splashFatalDetail, isNull);
    expect(Get.isRegistered<void>(), isFalse);
  });

  testWidgets('二次 attach 会重置上一次已揭开的状态', (tester) async {
    final first =
        attachGate(lottie: false, staticBrand: true, minVisible: Duration.zero);
    await first.debugOnFirstFrameSubmitted();
    await tester.pump();
    expect(MyApp.isSplashFinished.value, isTrue);

    final second = attachGate(lottie: true, staticBrand: false);
    expect(MyApp.isSplashFinished.value, isFalse);
    expect(MyApp.splashPhase.value, MySplashPhase.running);
    expect(second.isFinished, isFalse);
  });
}
